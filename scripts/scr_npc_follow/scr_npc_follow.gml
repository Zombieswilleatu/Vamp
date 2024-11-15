function scr_npc_follow() {
    if (!instance_exists(obj_player)) return;
    
    if (!variable_instance_exists(id, "init_complete")) {
        move_speed = 2;
        hspeed = 0;
        vspeed = 0;
        facing_direction = "down";
        last_direction = "down";
        my_path = path_add();
        path_set_kind(my_path, 1);
        path_set_precision(my_path, 8);
        direction_change_timer = 0;
        path_timer = 45;
        cell_size = 32;
        min_follow_dist = cell_size;
        max_follow_dist = cell_size * 3;
        stuck_timer = 0;
        last_valid_x = x;
        last_valid_y = y;
        current_path_index = 1;
        fallback_mode = false;
        fallback_timer = 0;
        path_failed_count = 0;
        push_x = 0;
        push_y = 0;
        path_offset_angle = irandom(360);
        separation_force = {x: 0, y: 0};
        personal_space = cell_size * 2;
        actual_movement_x = 0;
        actual_movement_y = 0;
        last_real_x = x;
        last_real_y = y;
        no_movement_timer = 0;
        cluster_escape_cooldown = 0;
        player_chase_dist = cell_size * 6;
        path_randomness = irandom_range(20, 40);
        zone_map_index = irandom(4);
        init_complete = true;
    }

    actual_movement_x = abs(x - last_real_x);
    actual_movement_y = abs(y - last_real_y);
    last_real_x = x;
    last_real_y = y;

    if (actual_movement_x > 0.1 || actual_movement_y > 0.1) {
        no_movement_timer = 0;
    } else {
        no_movement_timer++;
    }

    var player_nearby = (point_distance(x, y, obj_player.x, obj_player.y) < player_chase_dist);

    var touching_entities = 0;
    var total_push_x = 0;
    var total_push_y = 0;
    
    with(obj_entity_root) {
        if(id != other.id && distance_to_object(other) < other.sprite_width * 0.75) {
            touching_entities++;
            var push_dir = point_direction(other.x, other.y, x, y);
            total_push_x += lengthdir_x(1, push_dir);
            total_push_y += lengthdir_y(1, push_dir);
        }
    }

    if (touching_entities > 0 && no_movement_timer > 30 && cluster_escape_cooldown <= 0 && !player_nearby) {
        var escape_angle = 0;
        if (touching_entities > 1) {
            escape_angle = point_direction(0, 0, -total_push_x, -total_push_y);
        } else {
            escape_angle = irandom(360);
        }
        
        var escape_dist = sprite_width * (1 + touching_entities);
        var escape_x = x + lengthdir_x(escape_dist, escape_angle);
        var escape_y = y + lengthdir_y(escape_dist, escape_angle);
        
        if (is_position_valid(escape_x, escape_y, id)) {
            x = escape_x;
            y = escape_y;
            hspeed = 0;
            vspeed = 0;
            cluster_escape_cooldown = 60;
            no_movement_timer = 0;
            path_timer = 0;
            fallback_mode = true;
            fallback_timer = 30;
        } else {
            mask_index = -1;
            if(scr_handle_stuck(id)) {
                return;
            }
            mask_index = original_mask;
        }
    }
    
    if (cluster_escape_cooldown > 0) cluster_escape_cooldown--;

    separation_force.x = 0;
    separation_force.y = 0;
    var force_multiplier = player_nearby ? 2 : 3;
    
    with(obj_entity_root) {
        if(id != other.id) {
            var dist = point_distance(x, y, other.x, other.y);
            if(dist < other.personal_space && dist > 0) {
                var separation_strength = (other.personal_space - dist) / other.personal_space;
                separation_strength *= force_multiplier;
                var angle = point_direction(x, y, other.x, other.y);
                other.separation_force.x += lengthdir_x(separation_strength * other.move_speed * 2.5, angle);
                other.separation_force.y += lengthdir_y(separation_strength * other.move_speed * 2.5, angle);
            }
        }
    }

    scr_handle_npc_collision(id);
    
    var next_x = x + hspeed + push_x + separation_force.x;
    var next_y = y + vspeed + push_y + separation_force.y;
    
    if (is_position_valid(next_x, next_y, id)) {
        x = next_x;
        y = next_y;
        last_valid_x = x;
        last_valid_y = y;
        stuck_timer = 0;
    } else {
        if (is_position_valid(next_x, y, id)) {
            x = next_x;
            last_valid_x = x;
        } else {
            hspeed = 0;
            push_x = 0;
        }
        
        if (is_position_valid(x, next_y, id)) {
            y = next_y;
            last_valid_y = y;
        } else {
            vspeed = 0;
            push_y = 0;
        }
        
        stuck_timer++;
        if (stuck_timer > 15) {
            fallback_mode = true;
            fallback_timer = 30;
            stuck_timer = 0;
            path_offset_angle = (path_offset_angle + 120) % 360;
        }
    }
    
    var my_center_x = (bbox_left + bbox_right) / 2;
    var my_center_y = (bbox_top + bbox_bottom) / 2;
    var target_center_x = (obj_player.bbox_left + obj_player.bbox_right) / 2;
    var target_center_y = (obj_player.bbox_top + obj_player.bbox_bottom) / 2;
    var dist_to_player = point_distance(my_center_x, my_center_y, target_center_x, target_center_y);
    
    if (!fallback_mode) {
        if (--path_timer <= 0 || dist_to_player > max_follow_dist * 1.5) {
            path_timer = 45;
            
            if (dist_to_player > min_follow_dist) {
                path_clear_points(my_path);
                
                path_offset_angle += random_range(-path_randomness, path_randomness);
                var offset_dist = min(cell_size * (1 + touching_entities), dist_to_player * 0.3);
                var target_x = target_center_x + lengthdir_x(offset_dist, path_offset_angle);
                var target_y = target_center_y + lengthdir_y(offset_dist, path_offset_angle);
                
                // Apply zone weight to target position with bounds checking
                if (array_length(global.zone_maps) > zone_map_index) {
                    var grid_x = clamp(floor(target_x/cell_size), 0, array_length(global.zone_maps[zone_map_index]) - 1);
                    var grid_y = clamp(floor(target_y/cell_size), 0, array_length(global.zone_maps[zone_map_index][0]) - 1);
                    var weight = global.zone_maps[zone_map_index][grid_x][grid_y];
                    target_x = target_center_x + lengthdir_x(offset_dist * weight, path_offset_angle);
                    target_y = target_center_y + lengthdir_y(offset_dist * weight, path_offset_angle);
                }
                
                if(!mp_grid_path(global.path_grid, my_path, my_center_x, my_center_y, target_x, target_y, true)) {
                    mp_grid_path(global.path_grid, my_path, my_center_x, my_center_y, target_center_x, target_center_y, true);
                }
                
                current_path_index = 1;
            }
        }
        
        if (path_exists(my_path) && path_get_number(my_path) > 1 && current_path_index < path_get_number(my_path)) {
            var next_point_x = path_get_point_x(my_path, current_path_index);
            var next_point_y = path_get_point_y(my_path, current_path_index);
            var move_dir = point_direction(my_center_x, my_center_y, next_point_x, next_point_y);
            
            var crowd_factor = max(0.5, 1 - (touching_entities * 0.15));
            var desired_speed = move_speed * crowd_factor * (1 - min(0.5, point_distance(x, y, next_point_x, next_point_y) / cell_size));
            
            hspeed = lerp(hspeed, lengthdir_x(desired_speed, move_dir), 0.2);
            vspeed = lerp(vspeed, lengthdir_y(desired_speed, move_dir), 0.2);
            
            if (point_distance(x, y, next_point_x, next_point_y) < cell_size / 2) {
                current_path_index++;
            }
        }
    } else {
        if (--fallback_timer <= 0) {
            fallback_mode = false;
            path_timer = 0;
        } else {
            var escape_dir = find_escape_direction(x, y, cell_size, id);
            if (escape_dir >= 0) {
                hspeed = lerp(hspeed, lengthdir_x(move_speed * 1.25, escape_dir), 0.2);
                vspeed = lerp(vspeed, lengthdir_y(move_speed * 1.25, escape_dir), 0.2);
            } else {
                hspeed = lerp(hspeed, 0, 0.2);
                vspeed = lerp(vspeed, 0, 0.2);
            }
        }
    }
    
    if (--direction_change_timer <= 0) {
        direction_change_timer = 20;
        if (abs(hspeed) > abs(vspeed)) {
            facing_direction = (hspeed > 0) ? "right" : "left";
        } else {
            facing_direction = (vspeed > 0) ? "down" : "up";
        }
        last_direction = facing_direction;
    }
}