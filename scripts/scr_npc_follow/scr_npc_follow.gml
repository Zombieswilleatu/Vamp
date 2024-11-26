function scr_npc_follow() {
    if (!variable_instance_exists(self, "initialized") || !initialized) {
        show_debug_message("[NPC " + string(id) + "] Not initialized");
        return;
    }
    
    var MAX_PATHFIND_DISTANCE = 1600;
    var PATH_CORRIDOR_WIDTH = 8;
    var LOOK_AHEAD_POINTS = 2; // New: Look ahead in path to prevent backtracking
    
    var my_center = get_entity_center(self);
    var player_center = get_entity_center(obj_player);
    var dist_to_player = point_distance(x, y, obj_player.x, obj_player.y);
    
    if (!variable_instance_exists(self, "path_update_timer")) {
        path_update_timer = irandom(global.PATH_UPDATE_INTERVAL - 1);
        current_path = [];
        current_path_index = 0;
        last_valid_path = [];
    }
    
    path_update_timer++;
    if (path_update_timer >= global.PATH_UPDATE_INTERVAL) {
        path_update_timer = 0;
        
        if (dist_to_player <= MAX_PATHFIND_DISTANCE) {
            var new_path = find_path(my_center.x, my_center.y, player_center.x, player_center.y, self);
            if (array_length(new_path) > 0) {
                // New: Only update path if it's significantly different
                var should_update = true;
                if (array_length(current_path) > 0) {
                    var current_target = current_path[array_length(current_path) - 1];
                    var new_target = new_path[array_length(new_path) - 1];
                    var target_diff = point_distance(current_target.x, current_target.y, new_target.x, new_target.y);
                    should_update = target_diff > PATH_CORRIDOR_WIDTH * 2;
                }
                
                if (should_update) {
                    current_path = new_path;
                    current_path_index = 0;
                    last_valid_path = new_path;
                }
            }
        }
    }
    
    if (array_length(current_path) > 0 && current_path_index < array_length(current_path)) {
        // New: Look ahead in path to find best target point
        var best_target = current_path[current_path_index];
        var best_index = current_path_index;
        
        for (var i = 0; i < LOOK_AHEAD_POINTS && current_path_index + i < array_length(current_path); i++) {
            var test_point = current_path[current_path_index + i];
            if (!collision_line(my_center.x, my_center.y, test_point.x, test_point.y, obj_collision, false, true)) {
                best_target = test_point;
                best_index = current_path_index + i;
            } else {
                break;
            }
        }
        
        var dist_to_target = point_distance(my_center.x, my_center.y, best_target.x, best_target.y);
        
        // Calculate movement
        var dir = point_direction(my_center.x, my_center.y, best_target.x, best_target.y);
        var current_speed = move_speed;
        
        // Smoother speed adjustment
        if (dist_to_target < PATH_CORRIDOR_WIDTH * 2) {
            current_speed *= (dist_to_target / (PATH_CORRIDOR_WIDTH * 2));
            current_speed = max(1, current_speed);
        }
        
        var move_h = lengthdir_x(current_speed, dir);
        var move_v = lengthdir_y(current_speed, dir);
        
        if (place_meeting(x + move_h, y + move_v, obj_collision)) {
            var slide_result = slide_around_obstacle_improved(x, y, current_speed, dir);
            move_h = slide_result.x - x;
            move_v = slide_result.y - y;
        }
        
        x += move_h;
        y += move_v;
        
        // Update path index if we've reached current target
        if (dist_to_target <= PATH_CORRIDOR_WIDTH) {
            current_path_index = best_index + 1;
        }
    }
}

function slide_around_obstacle_improved(current_x, current_y, move_speed, original_dir) {
    // Fixed array syntax for GameMaker
    var test_angles = [-15, 15, -30, 30, -45, 45, -60, 60, -90, 90];
    
    // Try slight deviations first
    for (var i = 0; i < array_length(test_angles); i++) {
        var test_dir = (original_dir + test_angles[i]) % 360;
        var test_h = lengthdir_x(move_speed, test_dir);
        var test_v = lengthdir_y(move_speed, test_dir);
        
        if (!place_meeting(current_x + test_h, current_y + test_v, obj_collision)) {
            return {
                x: current_x + test_h,
                y: current_y + test_v
            };
        }
    }
    
    // Try cardinal directions as fallback
    var cardinal_dirs = [0, 90, 270, 180];
    for (var i = 0; i < array_length(cardinal_dirs); i++) {
        var test_dir = cardinal_dirs[i];
        var test_h = lengthdir_x(move_speed, test_dir);
        var test_v = lengthdir_y(move_speed, test_dir);
        
        if (!place_meeting(current_x + test_h, current_y + test_v, obj_collision)) {
            return {
                x: current_x + test_h,
                y: current_y + test_v
            };
        }
    }
    
    return {
        x: current_x,
        y: current_y
    };
}