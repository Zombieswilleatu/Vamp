//pathfinding_utils

// Path cache system for storing and reusing successful paths

#macro PATH_CACHE_SIZE 20        // Maximum number of paths to store
#macro PATH_CACHE_TOLERANCE 64   // How close start/end points need to be to reuse a path
#macro PATH_CACHE_LIFETIME 300   // How many frames before a cached path expires

// Path caching system initialization
function init_path_cache() {
    if (!variable_global_exists("path_cache")) {
        global.path_cache = [];
    }
}

/// @function find_cached_path(start_x, start_y, end_x, end_y)
/// @description Find a cached path that matches the given start and end points within tolerance
/// @param {Real} start_x Starting X coordinate
/// @param {Real} start_y Starting Y coordinate
/// @param {Real} end_x Ending X coordinate
/// @param {Real} end_y Ending Y coordinate
/// @returns {Array<Struct>} Cached path or undefined if no match found
function find_cached_path(start_x, start_y, end_x, end_y) {
    init_path_cache();
    
    var cache_time = get_timer();
    var best_path = undefined;
    var best_success_rate = 0;
    
    // Clean expired paths while searching
    var valid_paths = [];
    
    for (var i = 0; i < array_length(global.path_cache); i++) {
        var cache_entry = global.path_cache[i];
        
        // Remove expired paths
        if (cache_time - cache_entry.timestamp > PATH_CACHE_LIFETIME * 16667) { // Convert frames to microseconds
            continue;
        }
        
        array_push(valid_paths, cache_entry);
        
        // Check if this path matches our criteria
        if (point_distance(start_x, start_y, cache_entry.start_x, cache_entry.start_y) <= PATH_CACHE_TOLERANCE &&
            point_distance(end_x, end_y, cache_entry.end_x, cache_entry.end_y) <= PATH_CACHE_TOLERANCE) {
            
            // Calculate success rate
            var success_rate = cache_entry.success_count / (cache_entry.success_count + cache_entry.failure_count);
            
            // Update best path if this one has a better success rate
            if (success_rate > best_success_rate) {
                best_success_rate = success_rate;
                best_path = cache_entry.path;
            }
        }
    }
    
    // Update cache with only valid paths
    global.path_cache = valid_paths;
    
    return best_path;
}

/// @function cache_path(start_x, start_y, end_x, end_y, path)
/// @description Store a successful path in the cache
/// @param {Real} start_x Starting X coordinate
/// @param {Real} start_y Starting Y coordinate
/// @param {Real} end_x Ending X coordinate
/// @param {Real} end_y Ending Y coordinate
/// @param {Array<Struct>} path The path to cache
function cache_path(start_x, start_y, end_x, end_y, path) {
    init_path_cache();
    
    // Create new cache entry
    var cache_entry = {
        start_x: start_x,
        start_y: start_y,
        end_x: end_x,
        end_y: end_y,
        path: path,
        timestamp: get_timer(),
        success_count: 1,
        failure_count: 0
    };
    
    // Remove oldest entry if cache is full
    if (array_length(global.path_cache) >= PATH_CACHE_SIZE) {
        array_delete(global.path_cache, 0, 1);
    }
    
    array_push(global.path_cache, cache_entry);
}

/// @function increment_path_cache_success(start_x, start_y, end_x, end_y)
/// @description Increment the success counter for a cached path
/// @param {Real} start_x Starting X coordinate
/// @param {Real} start_y Starting Y coordinate
/// @param {Real} end_x Ending X coordinate
/// @param {Real} end_y Ending Y coordinate
function increment_path_cache_success(start_x, start_y, end_x, end_y) {
    init_path_cache();
    
    for (var i = 0; i < array_length(global.path_cache); i++) {
        var cache_entry = global.path_cache[i];
        
        if (point_distance(start_x, start_y, cache_entry.start_x, cache_entry.start_y) <= PATH_CACHE_TOLERANCE &&
            point_distance(end_x, end_y, cache_entry.end_x, cache_entry.end_y) <= PATH_CACHE_TOLERANCE) {
            cache_entry.success_count++;
            return;
        }
    }
}

/// @function increment_path_cache_failure(start_x, start_y, end_x, end_y)
/// @description Increment the failure counter for a cached path
/// @param {Real} start_x Starting X coordinate
/// @param {Real} start_y Starting Y coordinate
/// @param {Real} end_x Ending X coordinate
/// @param {Real} end_y Ending Y coordinate
function increment_path_cache_failure(start_x, start_y, end_x, end_y) {
    init_path_cache();
    
    for (var i = 0; i < array_length(global.path_cache); i++) {
        var cache_entry = global.path_cache[i];
        
        if (point_distance(start_x, start_y, cache_entry.start_x, cache_entry.start_y) <= PATH_CACHE_TOLERANCE &&
            point_distance(end_x, end_y, cache_entry.end_x, cache_entry.end_y) <= PATH_CACHE_TOLERANCE) {
            cache_entry.failure_count++;
            return;
        }
    }
}

/// @function clear_path_cache()
/// @description Clear all cached paths
function clear_path_cache() {
    init_path_cache();
    global.path_cache = [];
}

/// @function request_pathfinding(entity, start_x, start_y, end_x, end_y)
/// @description Queue a pathfinding request for processing
function request_pathfinding(entity, start_x, start_y, end_x, end_y) {
    var pfs = global.PathfindingSystem;
    
    var request = {
        entity: entity,
        start_x: start_x,
        start_y: start_y,
        end_x: end_x,
        end_y: end_y,
        request_time: get_timer()
    };
    
    ds_queue_enqueue(pfs.path_requests, request);
    show_debug_message("PF: Queued pathfinding request for entity " + string(entity));
}

/// @function process_pathfinding_queue()
/// @description Process queued pathfinding requests
function process_pathfinding_queue() {
    var pfs = global.PathfindingSystem;
    
    // Reset request counter if enough time has passed (simulating one frame at ~60fps)
    if (get_timer() - pfs.frame_start_time > 16667) {
        pfs.requests_this_frame = 0;
        pfs.frame_start_time = get_timer();
    }
    
    // Process up to max_requests_per_frame
    while (!ds_queue_empty(pfs.path_requests) && 
           pfs.requests_this_frame < pfs.max_requests_per_frame) {
           
        var request = ds_queue_dequeue(pfs.path_requests);
        
        // Process the request
        with (request.entity) {
            var path = pathfinding_find_path(
                temp_current_x, temp_current_y,  // NPC's current position
                temp_target_x, temp_target_y,    // Target position
                id
            );
            
            show_debug_message("PF: Processing queued request. Path length: " + string(array_length(path)));
            
            // Handle the result
            if (array_length(path) > 0) {
                // Smooth the path
                path = smooth_path(path);
                
                // Store the smoothed path
                follow_last_valid_path = path;
                
                // Check path orientation
                var fp = path[0];
                var lp = path[array_length(path) - 1];
                
                var dist_fp_to_npc = point_distance(fp.x, fp.y, temp_current_x, temp_current_y);
                var dist_lp_to_npc = point_distance(lp.x, lp.y, temp_current_x, temp_current_y);
                
                // If the last point is actually closer to the NPC than the first,
                // we consider the path reversed and flip it
                if (dist_lp_to_npc < dist_fp_to_npc) {
                    show_debug_message("PF: Queue processor reversing path direction");
                    
                    // 1) Reverse the path
                    var reversed_path = [];
                    for (var r = array_length(path) - 1; r >= 0; r--) {
                        array_push(reversed_path, path[r]);
                    }
                    
                    // 2) Find which waypoint in the reversed path is nearest to the NPC
                    //    so we can continue from there instead of jumping to reversed_path[0]
                    var best_idx = 0;
                    var best_dist = 9999999;
                    for (var i = 0; i < array_length(reversed_path); i++) {
                        var test_dist = point_distance(
                            reversed_path[i].x,
                            reversed_path[i].y,
                            temp_current_x,
                            temp_current_y
                        );
                        if (test_dist < best_dist) {
                            best_dist = test_dist;
                            best_idx = i;
                        }
                    }
                    
                    // 3) Replace the old path with this reversed version
                    path = reversed_path;
                    follow_last_valid_path = reversed_path;
                    
                    // 4) We'll set follow_path_index to that best_idx
                    //    so we don't snap to [0] in the new array
                    follow_path_index = best_idx;
                } else {
                    // If we didn't flip, start from 0 by default
                    follow_path_index = 0;
                }
                
                // Optionally find a better best_index if we're already moving
                var current_speed = point_distance(0, 0, vx, vy);
                if (current_speed > 0.1) {
                    var move_dir = point_direction(0, 0, vx, vy);
                    var path_start_dir = point_direction(temp_current_x, temp_current_y, path[follow_path_index].x, path[follow_path_index].y);
                    var dir_diff = abs(angle_difference(move_dir, path_start_dir));
                    
                    if (dir_diff > 90 && dir_diff < 150) {
                        var check_points = min(2, array_length(path) - 1);
                        for (var c = follow_path_index + 1; c <= follow_path_index + check_points; c++) {
                            if (c >= array_length(path)) break;
                            
                            var point_dir = point_direction(temp_current_x, temp_current_y, path[c].x, path[c].y);
                            var new_diff = abs(angle_difference(move_dir, point_dir));
                            if (new_diff < dir_diff - 30) {
                                follow_path_index = c;
                                dir_diff = new_diff;
                            }
                        }
                    }
                }
                
                // Make sure we don't start at the very last point
                if (follow_path_index >= array_length(path) - 1) {
                    follow_path_index = array_length(path) - 2;
                }
                
                // Cache the path for later
                cache_path(temp_current_x, temp_current_y, temp_target_x, temp_target_y, path);
                
                // Finalize
                follow_path = path;
                follow_has_valid_path = true;
                
                path_target_x = temp_target_x;
                path_target_y = temp_target_y;
                last_valid_target_x = temp_target_x;
                last_valid_target_y = temp_target_y;
                
            } else {
                // No path found
                follow_has_valid_path = false;
                if (point_distance(x, y, temp_target_x, temp_target_y) > 200) {
                    npc_follow_try_fallback(id, x, y, last_valid_target_x, last_valid_target_y);
                }
            }
        }
        
        pfs.requests_this_frame++;
    }
}

/// @desc Smooths a path by removing unnecessary waypoints
/// @param {Array} path The path to smooth
function smooth_path(path) {
    if (array_length(path) <= 2) return path;
    
    var smoothed_path = [];
    array_push(smoothed_path, path[0]);
    
    var i = 0;
    var MAX_SEGMENT_LENGTH = 128; // Don't create segments longer than this
    
    while (i < array_length(path) - 1) {
        var current = path[i];
        
        // Look ahead for furthest visible point
        var furthest_visible = i + 1;
        for (var j = i + 2; j < array_length(path); j++) {
            // Don't skip too many points at once
            if (point_distance(current.x, current.y, path[j].x, path[j].y) > MAX_SEGMENT_LENGTH) {
                break;
            }
            
            if (!collision_line(current.x, current.y, 
                              path[j].x, path[j].y, 
                              obj_collision, false, true)) {
                furthest_visible = j;
            } else {
                break;
            }
        }
        
        // If we're skipping more than a few points, add some intermediate ones
        var points_skipped = furthest_visible - i;
        if (points_skipped > 3) {
            // Add some intermediate points
            var mid_point = i + floor(points_skipped / 2);
            array_push(smoothed_path, path[mid_point]);
        }
        
        array_push(smoothed_path, path[furthest_visible]);
        i = furthest_visible;
    }
    
    return smoothed_path;
}

function angle_lerp(start_angle, end_angle, amount) {
    var diff = angle_difference(start_angle, end_angle);
    return start_angle + diff * amount;
}

function __pf_predict_future_position(entity, look_ahead_time) {
    // Predict where the entity will be in X steps based on current velocity
    return {
        x: entity.x + (entity.hspeed * look_ahead_time),
        y: entity.y + (entity.vspeed * look_ahead_time)
    };
}

function __pf_get_future_target_point(path, current_target_index, look_ahead_points) {
    // Look ahead in the path to find a better target point
    var future_index = min(current_target_index + look_ahead_points, array_length(path) - 1);
    return path[future_index];
}

function __pf_should_recalculate_path(entity, path, current_target_index) {
    if (array_length(path) == 0) return true;
    
    // Get predicted position
    var future_pos = __pf_predict_future_position(entity, 10); // Look ahead 10 steps
    var future_target = __pf_get_future_target_point(path, current_target_index, 2); // Look ahead 2 points
    
    // Check if predicted position is too far from path
    var max_deviation = GRID_CELL_SIZE * 1.5; // Allow some deviation
    var current_point = path[current_target_index];
    
    // Calculate deviation from current path segment
    var deviation = abs(point_distance(
        future_pos.x, future_pos.y,
        current_point.x, current_point.y
    ));
    
    // Also check if we're moving away from our target
    var moving_away = dot_product(
        entity.hspeed, entity.vspeed,
        future_target.x - entity.x, future_target.y - entity.y
    ) < 0;
    
    return (deviation > max_deviation) || moving_away;
}

function npc_follow_try_fallback(entity_id, current_x, current_y, target_x, target_y) {
    with (entity_id) {
        // Try to move directly towards target if close enough
        var dist_to_target = point_distance(current_x, current_y, target_x, target_y);
        
        if (dist_to_target < GRID_CELL_SIZE * 3) {
            // Try direct movement if close
            var dir = point_direction(current_x, current_y, target_x, target_y);
            var test_x = current_x + lengthdir_x(GRID_CELL_SIZE, dir);
            var test_y = current_y + lengthdir_y(GRID_CELL_SIZE, dir);
            
            // Check if direct path is clear
            if (!place_meeting(test_x, test_y, obj_collision)) {
                move_towards_point(target_x, target_y, move_speed);
                return true;
            }
        }
        
        // Try to find a clear direction
        var found_direction = false;
        for (var angle = 0; angle < 360; angle += 45) {
            var test_dist = GRID_CELL_SIZE;
            var test_x = current_x + lengthdir_x(test_dist, angle);
            var test_y = current_y + lengthdir_y(test_dist, angle);
            
            if (!place_meeting(test_x, test_y, obj_collision)) {
                // Found a clear direction - move that way
                move_towards_point(test_x, test_y, move_speed);
                found_direction = true;
                break;
            }
        }
        
        // If all else fails, try to move away from obstacles
        if (!found_direction) {
            var push_x = 0;
            var push_y = 0;
            
            // Check all directions for obstacles
            for (var angle = 0; angle < 360; angle += 45) {
                var check_x = current_x + lengthdir_x(GRID_CELL_SIZE * 0.5, angle);
                var check_y = current_y + lengthdir_y(GRID_CELL_SIZE * 0.5, angle);
                
                if (place_meeting(check_x, check_y, obj_collision)) {
                    // Add a small push away from this obstacle
                    push_x -= lengthdir_x(1, angle);
                    push_y -= lengthdir_y(1, angle);
                }
            }
            
            if (push_x != 0 || push_y != 0) {
                // Normalize and apply push
                var push_len = point_distance(0, 0, push_x, push_y);
                if (push_len > 0) {
                    push_x = (push_x / push_len) * move_speed;
                    push_y = (push_y / push_len) * move_speed;
                    hspeed = push_x;
                    vspeed = push_y;
                }
            }
        }
        
        return found_direction;
    }
}