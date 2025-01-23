//////////////////////////////////////////////////////////////////////////
// scr_npc_search
// REQUIRES: scr_handle_npc_collision, scr_npc_follow (for shared functions)
//////////////////////////////////////////////////////////////////////////

#macro SEARCH_MOVE_SPEED 2.5
#macro SEARCH_AREA_SIZE 64            // Size of area considered "searched" when visited
#macro MIN_SEARCH_DISTANCE 128        // Minimum distance to consider for a new search area
#macro MAX_SEARCH_ATTEMPTS 5          // Max attempts to find valid search location
#macro EMERGENCY_UNSTUCK_TIME 180     // 3 seconds at 60fps
#macro VELOCITY_THRESHOLD 0.1         // Minimum velocity to be considered "moving"
#macro EMERGENCY_JUMP_DISTANCE 64     // How far to try moving when emergency unstuck triggers
#macro EMERGENCY_UNSTUCK_COOLDOWN 180 // 3-second cooldown after an emergency unstuck
#macro POST_UNSTUCK_SPEED_MULTIPLIER 0.7 // Reduce speed temporarily after unstuck
#macro MAX_WAYPOINT_FAILURES 3        // Max attempts to reach first waypoint before emergency
#macro WAYPOINT_PROGRESS_THRESHOLD 32 // Distance to consider "progress" toward waypoint

/// @desc Initialize the search system
/// @returns {Bool} True if initialization successful
function search_system_init() {
    show_debug_message("Initializing search system...");
    
    // Create global search grid if it doesn't exist
    if (!variable_global_exists("search_grid")) {
        var room_grid_w = ceil(room_width / SEARCH_AREA_SIZE);
        var room_grid_h = ceil(room_height / SEARCH_AREA_SIZE);
        global.search_grid = ds_grid_create(room_grid_w, room_grid_h);
        ds_grid_clear(global.search_grid, 0); // 0 = unsearched
    }
    
    return true;
}

/// @desc Initialize NPC search behavior
/// @param {Id.Instance} inst  Instance to initialize
function npc_search_init(inst) {
    var temp_priority = (argument_count > 1) ? argument[1] : 0;
    
    with (inst) {
        // Core search variables
        search_initialized       = true;
        search_path             = [];
        search_path_index       = 0;
        search_priority         = temp_priority;
        
        // Search state
        search_needs_path       = true;
        search_has_valid_path   = false;
        // NOTE: If you truly want to force zero for fresh target, uncomment these:
        // search_target_x = 0;
        // search_target_y = 0;
        
        // Movement state and physics
        search_move_speed       = SEARCH_MOVE_SPEED;
        search_current_direction= 0;
        vx                      = 0;
        vy                      = 0;
        
        // Stuck detection
        stuck_timer             = 0;
        emergency_stuck_timer   = 0;
        deadlock_timer          = 0;
        last_position_x         = x;
        last_position_y         = y;
        
        // Unstuck management variables
        emergency_unstuck_cooldown = 0;
        post_unstuck_timer      = 0;
        unstuck_attempts        = 0;
        last_unstuck_x          = x;
        last_unstuck_y          = y;
        pathfinding_delay_timer = 0;
        
        // Waypoint failure tracking
        waypoint_failure_count  = 0;
        last_path_attempt_x     = x;
        last_path_attempt_y     = y;
        
        // For animation system
        search_last_move_x      = 0;
        search_last_move_y      = 0;
        
        // Path variables (the pathfinding system references these)
        search_path             = [];
        follow_path             = [];  // <--- Often re-used by your pathfinding code
        follow_path_index       = 0;
        follow_has_valid_path   = false;
        
        // Initialize temp variables needed by pathfinding
        temp_current_x          = x;
        temp_current_y          = y;
        temp_target_x           = x;
        temp_target_y           = y;
        
        // Target tracking
        target_x                = x;
        target_y                = y;
        path_target_x           = x;
        path_target_y           = y;
        last_valid_target_x     = x;
        last_valid_target_y     = y;
        
        show_debug_message("NPC_SEARCH: Initialized search behavior for instance " + string(id));
    }
}

/// @desc Find a valid unsearched location
/// @param {Id.Instance} inst Instance to check for
/// @returns {Struct} Object containing x,y or undefined if no valid location found
function find_unsearched_location(inst) {
    with (inst) {
        var current_x = x;
        var current_y = y;
        var attempts = 0;
        var max_attempts = MAX_SEARCH_ATTEMPTS * 2; // Double attempts for better distribution
        
        // Gather other searching entities
        var other_searchers = [];
        with(obj_entity_root) {
            if (id != other.id && variable_instance_exists(id, "search_initialized")) {
                array_push(other_searchers, {
                    x: x,
                    y: y,
                    target_x: variable_instance_exists(id, "search_target_x") ? search_target_x : x,
                    target_y: variable_instance_exists(id, "search_target_y") ? search_target_y : y
                });
            }
        }
        
        // Try random points around the room
        while (attempts < max_attempts) {
            var test_x = irandom_range(0, room_width);
            var test_y = irandom_range(0, room_height);
            
            // Adjust search area based on # of searchers
            var min_search_distance = MIN_SEARCH_DISTANCE * (1 + array_length(other_searchers) * 0.2);
            
            // Convert to grid coords
            var grid_x = floor(test_x / SEARCH_AREA_SIZE);
            var grid_y = floor(test_y / SEARCH_AREA_SIZE);
            
            // Check if position is valid + unsearched
            if (grid_x >= 0 && grid_x < ds_grid_width(global.search_grid) &&
                grid_y >= 0 && grid_y < ds_grid_height(global.search_grid)) {
                
                if (global.search_grid[# grid_x, grid_y] == 0) {
                    var dist = point_distance(current_x, current_y, test_x, test_y);
                    
                    // Check distance from other searchers
                    var too_close = false;
                    for (var i = 0; i < array_length(other_searchers); i++) {
                        var os = other_searchers[i];
                        
                        var dist_to_searcher = point_distance(test_x, test_y, os.x, os.y);
                        var dist_to_target   = point_distance(test_x, test_y, os.target_x, os.target_y);
                        
                        if (dist_to_searcher < min_search_distance * 0.75 ||
                            dist_to_target < min_search_distance * 0.75) {
                            too_close = true;
                            break;
                        }
                    }
                    
                    if (!too_close && dist >= min_search_distance &&
                        !place_meeting(test_x, test_y, obj_collision)) {
                        return {
                            x: test_x,
                            y: test_y,
                            grid_x: grid_x,
                            grid_y: grid_y
                        };
                    }
                }
            }
            attempts++;
        }
        
        // If we fail, lower requirements a bit
        attempts = 0;
        while (attempts < MAX_SEARCH_ATTEMPTS) {
            var test_x = irandom_range(0, room_width);
            var test_y = irandom_range(0, room_height);
            var grid_x = floor(test_x / SEARCH_AREA_SIZE);
            var grid_y = floor(test_y / SEARCH_AREA_SIZE);
            
            if (grid_x >= 0 && grid_x < ds_grid_width(global.search_grid) &&
                grid_y >= 0 && grid_y < ds_grid_height(global.search_grid)) {
                if (global.search_grid[# grid_x, grid_y] == 0 && 
                    !place_meeting(test_x, test_y, obj_collision)) {
                    return {
                        x: test_x,
                        y: test_y,
                        grid_x: grid_x,
                        grid_y: grid_y
                    };
                }
            }
            attempts++;
        }
        
        // Nothing found
        return undefined;
    }
}

/// @desc Mark an area as searched
/// @param {Real} grid_x Grid X coord
/// @param {Real} grid_y Grid Y coord
function mark_area_searched(grid_x, grid_y) {
    if (grid_x >= 0 && grid_x < ds_grid_width(global.search_grid) &&
        grid_y >= 0 && grid_y < ds_grid_height(global.search_grid)) {
        global.search_grid[# grid_x, grid_y] = 1; // 1 = searched
    }
}

/// @desc Update NPC search behavior
function npc_search_update(inst) {
    with (inst) {
        // Initialize search_idle_active if it doesn't exist
        if (!variable_instance_exists(id, "search_idle_active")) {
            search_idle_active = false;
        }
        
        // If not already set, define search_fresh_start
        if (!variable_instance_exists(id, "search_fresh_start")) {
            search_fresh_start = false;
        }
        
        // If we never ran npc_search_init(), do it now
        if (!variable_instance_exists(id, "search_initialized")) {
            show_debug_message("NPC_SEARCH: Not initialized, calling npc_search_init().");
            npc_search_init(id);
            return;
        }
        
        // Handle a 'fresh start' scenario
        if (search_fresh_start) {
            show_debug_message("NPC_SEARCH: Fresh start after returning from follow. Resetting timers.");
            stuck_timer             = 0;
            emergency_stuck_timer   = 0;
            waypoint_failure_count  = 0;
            last_position_x         = x;
            last_position_y         = y;
            search_fresh_start      = false;
        }
        
        // Check movement vs. last position to detect being stuck
        var move_threshold = 1;
        var dist_moved     = point_distance(last_position_x, last_position_y, x, y);
        
        // Debug: prints out the movement + velocity
        show_debug_message("dist_moved=" + string(dist_moved) + 
                           " stuck_timer=" + string(stuck_timer) + 
                           " vx=" + string(vx) + 
                           " vy=" + string(vy));
        
        // Handle minor stuck logic
        if (dist_moved < move_threshold) {
            if (emergency_unstuck_cooldown <= 0) {
                stuck_timer++;
                
                // Force a new path if stuck for > 60 frames
                if (stuck_timer > 60) {
                    follow_has_valid_path = false;
                    stuck_timer = 0;
                    show_debug_message("NPC_SEARCH: Forcing new path due to being stuck.");
                }
                
                // If velocity is also near-zero, check emergency logic
                var current_speed = point_distance(0, 0, vx, vy);
                if (current_speed < VELOCITY_THRESHOLD) {
                    emergency_stuck_timer++;
                    if (emergency_stuck_timer >= EMERGENCY_UNSTUCK_TIME) {
                        show_debug_message("EMERGENCY UNSTUCK: Attempting procedure!");
                        if (emergency_unstuck(id)) {
                            follow_has_valid_path = false;
                            follow_path           = [];
                            follow_path_index     = 0;
                            waypoint_failure_count= 0;
                            emergency_unstuck_cooldown = EMERGENCY_UNSTUCK_COOLDOWN;
                            last_unstuck_x        = x;
                            last_unstuck_y        = y;
                            stuck_timer           = 0;
                            emergency_stuck_timer = 0;
                            deadlock_timer        = 0;
                            pathfinding_delay_timer = 15;
                        }
                    }
                }
            }
        } else {
            // If we did move, reset or reduce stuck timers
            if (emergency_unstuck_cooldown <= 0) {
                stuck_timer             = max(0, stuck_timer - 0.5);
                emergency_stuck_timer   = max(0, emergency_stuck_timer - 2);
            }
        }
        
        // Update last known position
        last_position_x = x;
        last_position_y = y;
        
        // Mark current area as searched
        var current_grid_x = floor(x / SEARCH_AREA_SIZE);
        var current_grid_y = floor(y / SEARCH_AREA_SIZE);
        mark_area_searched(current_grid_x, current_grid_y);
        
        // Check for other searching NPCs + potential deadlock
        var nearby_searchers   = 0;
        var deadlock_detected  = false;
        
        with(obj_entity_root) {
            if (id != other.id && variable_instance_exists(id, "search_initialized")) {
                var dist = point_distance(x, y, other.x, other.y);
                if (dist < SEARCH_AREA_SIZE * 1.5) {
                    nearby_searchers++;
                    // If both are stuck, it's a deadlock
                    if (variable_instance_exists(id, "stuck_timer") && stuck_timer > 30 && id.stuck_timer > 30) {
                        deadlock_detected = true;
                    }
                }
            }
        }
        
        if (deadlock_detected && emergency_unstuck_cooldown <= 0) {
            deadlock_timer++;
            if (deadlock_timer > 45) {
                // Try jump out of the cluster
                var escape_angle = irandom(359);
                var escape_dist  = SEARCH_AREA_SIZE * 0.75;
                var escape_x     = x + lengthdir_x(escape_dist, escape_angle);
                var escape_y     = y + lengthdir_y(escape_dist, escape_angle);
                var attempts     = 8;
                
                while (attempts > 0 && place_meeting(escape_x, escape_y, obj_collision)) {
                    escape_angle = (escape_angle + 45) % 360;
                    escape_x     = x + lengthdir_x(escape_dist, escape_angle);
                    escape_y     = y + lengthdir_y(escape_dist, escape_angle);
                    attempts--;
                }
                
                if (!place_meeting(escape_x, escape_y, obj_collision)) {
                    temp_current_x = bbox_left + (bbox_right - bbox_left) * 0.5;
                    temp_current_y = bbox_top + (bbox_bottom - bbox_top) * 0.5;
                    temp_target_x  = escape_x;
                    temp_target_y  = escape_y;
                    request_pathfinding(id, temp_current_x, temp_current_y, temp_target_x, temp_target_y);
                    follow_path_index    = 0;
                    deadlock_timer       = 0;
                    stuck_timer          = 0;
                    waypoint_failure_count = 0;
                }
            }
        } else {
            deadlock_timer = max(0, deadlock_timer - 1);
        }
        
        // Adjust speed if multiple searchers are near
        if (nearby_searchers > 2) {
            search_move_speed = SEARCH_MOVE_SPEED * (0.8 - (nearby_searchers * 0.1));
            search_move_speed = max(search_move_speed, SEARCH_MOVE_SPEED * 0.4);
        } else if (emergency_unstuck_cooldown <= 0) {
            search_move_speed = SEARCH_MOVE_SPEED;
        }
        
        // If no path or we reached old search target, request new location
        if (pathfinding_delay_timer > 0) {
            pathfinding_delay_timer--;
        } else if (!search_idle_active && // Only proceed if not in idle
                  (!follow_has_valid_path ||
                   (array_length(follow_path) > 0 && follow_path_index >= array_length(follow_path))) &&
                   emergency_unstuck_cooldown <= 0) {
            
            // Only enter idle if we successfully completed our path
            if (follow_has_valid_path && 
                array_length(follow_path) > 0 && 
                follow_path_index >= array_length(follow_path)) {
                search_idle_active = true;
                idle_state_timer = 0;
                idle_initialized = false;
                vx = 0;
                vy = 0;
                show_debug_message("Path complete - entering search-idle state");
                return;
            }
            
            var new_location = find_unsearched_location(id);
            if (new_location != undefined) {
                search_target_x   = new_location.x;
                search_target_y   = new_location.y;
                
                temp_current_x    = bbox_left + (bbox_right - bbox_left) * 0.5;
                temp_current_y    = bbox_top + (bbox_bottom - bbox_top) * 0.5;
                temp_target_x     = search_target_x;
                temp_target_y     = search_target_y;
                
                target_x          = search_target_x;
                target_y          = search_target_y;
                
                request_pathfinding(id, temp_current_x, temp_current_y, temp_target_x, temp_target_y);
                follow_path_index = 0;
                waypoint_failure_count = 0;
                last_path_attempt_x = x;
                last_path_attempt_y = y;
                
                show_debug_message("NPC_SEARCH: Requested new path to: " + 
                                   string(search_target_x) + "," + string(search_target_y));
            }
        }
        
        // Move along path if valid and not in idle
        if (!search_idle_active && 
            follow_has_valid_path && 
            array_length(follow_path) > 0 && 
            emergency_unstuck_cooldown <= 0) {
            
            // Current NPC center
            var _current_point = {
                x: bbox_left + (bbox_right - bbox_left) * 0.5,
                y: bbox_top + (bbox_bottom - bbox_top) * 0.5
            };
            
            if (follow_path_index < 0) follow_path_index = 0;
            
            // Next waypoint
            var _waypoint = follow_path[follow_path_index];
            if (_waypoint != undefined) {
                var _dist_to_waypoint = point_distance(_current_point.x, _current_point.y,
                                                       _waypoint.x, _waypoint.y);
                var current_speed = point_distance(0, 0, vx, vy);
                
                // Check if we're failing to reach the first waypoint
                if (follow_path_index == 0 && current_speed > 0) {
                    var dist_from_last_attempt = point_distance(_waypoint.x, _waypoint.y,
                                                                last_path_attempt_x, last_path_attempt_y);
                    if (dist_from_last_attempt < WAYPOINT_PROGRESS_THRESHOLD && stuck_timer > 30) {
                        waypoint_failure_count++;
                        show_debug_message("Waypoint failure count: " + string(waypoint_failure_count));
                        
                        if (waypoint_failure_count >= MAX_WAYPOINT_FAILURES) {
                            show_debug_message("EMERGENCY UNSTUCK: Failed to reach first waypoint " + 
                                               string(MAX_WAYPOINT_FAILURES) + " times!");
                            if (emergency_unstuck(id)) {
                                follow_has_valid_path = false;
                                follow_path = [];
                                follow_path_index = 0;
                                emergency_unstuck_cooldown = EMERGENCY_UNSTUCK_COOLDOWN;
                                last_unstuck_x = x;
                                last_unstuck_y = y;
                                stuck_timer = 0;
                                emergency_stuck_timer = 0;
                                deadlock_timer = 0;
                                waypoint_failure_count = 0;
                                pathfinding_delay_timer = 15;
                                return;
                            }
                        }
                    }
                    last_path_attempt_x = _waypoint.x;
                    last_path_attempt_y = _waypoint.y;
                }
                
                // If we're close to the current waypoint, move on
                var waypoint_reach_dist = 8 + (nearby_searchers * 2);
                if (_dist_to_waypoint <= waypoint_reach_dist) {
                    follow_path_index++;
                    waypoint_failure_count = 0;
                    
                    // Check if we're done with the path
                    if (follow_path_index >= array_length(follow_path)) {
                        follow_has_valid_path = false;
                        vx = 0;
                        vy = 0;
                        // Enter idle state when path is complete
                        search_idle_active = true;
                        idle_state_timer = 0;
                        idle_initialized = false;
                        show_debug_message("Path complete - entering search-idle state");
                        return;
                    }
                    _waypoint = follow_path[follow_path_index];
                }
                
                // Calculate direction from our position to the next waypoint
                var _move_dir  = point_direction(_current_point.x, _current_point.y,
                                                 _waypoint.x, _waypoint.y);
                var target_vx  = lengthdir_x(search_move_speed, _move_dir);
                var target_vy  = lengthdir_y(search_move_speed, _move_dir);
                
                // The blending factor smooths out velocity changes,
                // causing 'weird' partial velocities if repeated many times
                var blend_factor = 0.2;
                if (stuck_timer > 30)  blend_factor = 0.5;
                if (nearby_searchers > 2) blend_factor *= 0.75;
                
                vx = lerp(vx, target_vx, blend_factor);
                vy = lerp(vy, target_vy, blend_factor);
                
                search_current_direction = _move_dir;
                search_last_move_x       = vx;
                search_last_move_y       = vy;
                
                // Actually apply the velocity to movement
                try_move_along_path(id);
            } else {
                // If the waypoint is undefined, reset
                follow_has_valid_path = false;
                vx = 0;
                vy = 0;
                show_debug_message("Invalid path or waypoint, resetting path.");
            }
        }
    }
}

/// @desc Emergency unstuck procedure for completely stuck entities
/// @param {Id.Instance} inst Instance to unstuck
function emergency_unstuck(inst) {
    with (inst) {
        // Try 8 directions (cardinal + diagonals)
        var angles   = [0, 45, 90, 135, 180, 225, 270, 315];
        var base_dist= EMERGENCY_JUMP_DISTANCE;
        
        // Try slightly varying distances
        var distances = [1.0, 0.75, 1.25, 0.5];
        var steps     = 8; // # movement steps to take incrementally
        
        for (var d = 0; d < array_length(distances); d++) {
            var test_dist = base_dist * distances[d];
            
            // Shuffle angles for randomness
            array_shuffle(angles);
            
            for (var i = 0; i < array_length(angles); i++) {
                var test_x = x + lengthdir_x(test_dist, angles[i]);
                var test_y = y + lengthdir_y(test_dist, angles[i]);
                
                // Check collisions
                if (!place_meeting(test_x, test_y, obj_collision)) {
                    
                    // Check for other entities
                    var entity_found = false;
                    with(obj_entity_root) {
                        if (id != other.id) {
                            var dist = point_distance(x, y, test_x, test_y);
                            // If too close, skip
                            if (dist < SEARCH_AREA_SIZE) {
                                entity_found = true;
                                break;
                            }
                        }
                    }
                    
                    if (!entity_found) {
                        // Step movement to avoid large collisions
                        var move_dir = point_direction(x, y, test_x, test_y);
                        var step_x   = (test_x - x) / steps;
                        var step_y   = (test_y - y) / steps;
                        
                        for (var step = 0; step < steps; step++) {
                            x += step_x;
                            y += step_y;
                            
                            // Update velocity for animation
                            vx = lengthdir_x(search_move_speed, move_dir);
                            vy = lengthdir_y(search_move_speed, move_dir);
                            
                            search_current_direction = move_dir;
                            search_last_move_x       = vx;
                            search_last_move_y       = vy;
                            
                            // Attempt step collisions if relevant
                            try_move_along_path(id);
                        }
                        
                        show_debug_message("EMERGENCY UNSTUCK: Moved entity to new position at angle " + 
                                           string(angles[i]) + ", dist " + string(test_dist));
                        return true;
                    }
                }
            }
        }
        
        show_debug_message("EMERGENCY UNSTUCK: Failed to find valid position!");
        return false;
    }
}
