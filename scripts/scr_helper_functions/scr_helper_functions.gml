// Helper function to check rectangle collision
function rectangle_rectangle_collision(left1, top1, right1, bottom1, left2, top2, right2, bottom2) {
    return !(left1 >= right2 || right1 <= left2 || top1 >= bottom2 || bottom1 <= top2);
}

// Helper function to get the overlapping rectangle
function get_overlap_rectangle(left1, top1, right1, bottom1, left2, top2, right2, bottom2) {
    var overlap_left = max(left1, left2);
    var overlap_top = max(top1, top2);
    var overlap_right = min(right1, right2);
    var overlap_bottom = min(bottom1, bottom2);
    return {
        left: overlap_left,
        top: overlap_top,
        right: overlap_right,
        bottom: overlap_bottom
    };
}

// Approach function to smoothly adjust values
function approach(current, target, amount) {
    if (abs(target - current) <= amount) {
        return target;
    } else {
        return current + sign(target - current) * amount;
    }
}

function log_npc_debug(npc_id, state_name, details = "") {
    var msg = "[NPC:" + string(npc_id) + "] " + state_name;
    if (details != "") {
        msg += " - " + details;
    }
    show_debug_message(msg);
}

function is_position_valid(check_x, check_y, inst) {
    with(inst) {
        var x_offset = check_x - x;
        var y_offset = check_y - y;
        
        return !collision_rectangle(
            bbox_left + x_offset,
            bbox_top + y_offset,
            bbox_right + x_offset,
            bbox_bottom + y_offset,
            obj_collision,
            true,
            true
        );
    }
}

function find_escape_direction(from_x, from_y, search_dist = 32, inst) {
    var best_dist = 0;
    var best_angle = -1;
    
    for(var angle = 0; angle < 360; angle += 45) {
        var test_x = from_x + lengthdir_x(search_dist, angle);
        var test_y = from_y + lengthdir_y(search_dist, angle);
        
        if (is_position_valid(test_x, test_y, inst)) {
            var nearest_wall = instance_nearest(test_x, test_y, obj_collision);
            if (nearest_wall != noone) {
                var wall_dist = point_distance(test_x, test_y, nearest_wall.x, nearest_wall.y);
                if (wall_dist > best_dist) {
                    best_dist = wall_dist;
                    best_angle = angle;
                }
            }
        }
    }
    
    return best_angle;
}

function find_closest_valid_point(start_x, start_y, target_x, target_y, max_search_radius = 320, inst) {
    var best_point = { x: start_x, y: start_y };
    var best_dist = point_distance(best_point.x, best_point.y, target_x, target_y);
    var cell_size = 32;
    var my_path = path_add();
    
    for(var radius = cell_size; radius <= max_search_radius; radius += cell_size) {
        for(var angle = 0; angle < 360; angle += 15) {
            var test_x = target_x + lengthdir_x(radius, angle);
            var test_y = target_y + lengthdir_y(radius, angle);
            
            if (mp_grid_path(global.path_grid, my_path, start_x, start_y, test_x, test_y, true)) {
                var dist = point_distance(test_x, test_y, target_x, target_y);
                if (dist < best_dist) {
                    best_dist = dist;
                    best_point.x = test_x;
                    best_point.y = test_y;
                }
            }
        }
        
        if (best_point.x != start_x || best_point.y != start_y) break;
    }
    
    path_delete(my_path);
    return best_point;
}
