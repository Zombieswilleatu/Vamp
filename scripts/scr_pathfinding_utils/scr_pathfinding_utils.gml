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

// Optimized pathfinding queue processing
function process_pathfinding_queue() {
    var pfs = global.PathfindingSystem;
    
    // More lenient frame time check (25ms instead of 16.6ms)
    if (get_timer() - pfs.frame_start_time > 25000) {
        pfs.requests_this_frame = 0;
        pfs.frame_start_time = get_timer();
    }
    
    // Increase max requests per frame
    pfs.max_requests_per_frame = 5;  // Up from default
    
    // Process queue with priority for closer entities
    var request_array = [];
    while (!ds_queue_empty(pfs.path_requests)) {
        array_push(request_array, ds_queue_dequeue(pfs.path_requests));
    }
    
    // Sort by distance to target (closer first)
    array_sort(request_array, function(a, b) {
        var dist_a = point_distance(a.start_x, a.start_y, a.end_x, a.end_y);
        var dist_b = point_distance(b.start_x, b.start_y, b.end_x, b.end_y);
        return dist_a - dist_b;
    });
    
    // Process sorted requests
    var processed = 0;
    for (var i = 0; i < array_length(request_array); i++) {
        if (processed >= pfs.max_requests_per_frame) {
            // Re-queue remaining requests
            for (var j = i; j < array_length(request_array); j++) {
                ds_queue_enqueue(pfs.path_requests, request_array[j]);
            }
            break;
        }
        
        var request = request_array[i];
        
        with (request.entity) {
            // Skip if too close
            if (point_distance(temp_current_x, temp_current_y, temp_target_x, temp_target_y) < 32) {
                follow_has_valid_path = true;
                follow_path = [{x: temp_target_x, y: temp_target_y}];
                follow_path_index = 0;
                continue;
            }
            
            // Try cached path first
            var cached_path = find_cached_path(temp_current_x, temp_current_y, temp_target_x, temp_target_y);
            if (cached_path != undefined) {
                follow_path = cached_path;
                follow_has_valid_path = true;
                follow_path_index = 0;
                increment_path_cache_success(temp_current_x, temp_current_y, temp_target_x, temp_target_y);
                continue;
            }
            
            // Regular pathfinding
            var path = pathfinding_find_path(
                temp_current_x, temp_current_y,
                temp_target_x, temp_target_y,
                id
            );
            
            if (array_length(path) > 0) {
                path = smooth_path(path);
                follow_last_valid_path = path;
                follow_path = path;
                follow_has_valid_path = true;
                follow_path_index = 0;
                cache_path(temp_current_x, temp_current_y, temp_target_x, temp_target_y, path);
            } else {
                follow_has_valid_path = false;
                if (point_distance(x, y, temp_target_x, temp_target_y) > 200) {
                    npc_follow_try_fallback(id, x, y, last_valid_target_x, last_valid_target_y);
                }
            }
        }
        processed++;
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