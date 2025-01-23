

function scr_handle_stuck(inst) {
    if (!variable_instance_exists(inst, "stuck_initialized")) {
        inst.stuck_initialized = true;
        inst.is_stuck = false;
        inst.original_mask = inst.mask_index;
        inst.stuck_attempts = 0;
        inst.last_unstuck_pos = { x: inst.x, y: inst.y };
        inst.last_unstuck_time = current_time;
    }

    with (inst) {
        if (place_meeting(x, y, obj_collision)) {
            is_stuck = true; // Mark entity as stuck
            mask_index = -1; // Disable mask for collision tests
            stuck_attempts++;

            var base_distance = sprite_get_width(sprite_index);
            var escape_distance = min(base_distance * (1 + stuck_attempts * 0.5), base_distance * 4);
            var angle_step = max(5, 360 / (8 + stuck_attempts * 2));
            var escaped = false;

            // Attempt to escape by nudging the entity
            for (var angle = 0; angle < 360; angle += angle_step) {
                var test_x = x + lengthdir_x(escape_distance, angle);
                var test_y = y + lengthdir_y(escape_distance, angle);

                var buffer = sprite_get_width(sprite_index) * 0.5;
                if (!collision_rectangle(
                    test_x - buffer, test_y - buffer,
                    test_x + buffer, test_y + buffer,
                    obj_collision, false, true
                )) {
                    var old_x = x;
                    var old_y = y;

                    x = test_x;
                    y = test_y;

                    if (!place_meeting(x, y, obj_collision)) {
                        escaped = true;
                        last_unstuck_pos.x = x;
                        last_unstuck_pos.y = y;
                        last_unstuck_time = current_time;
                        is_stuck = false;
                        mask_index = original_mask;
                        stuck_attempts = 0;

                        // Reset relevant variables
                        if (variable_instance_exists(id, "hspeed")) hspeed = 0;
                        if (variable_instance_exists(id, "vspeed")) vspeed = 0;
                        if (variable_instance_exists(id, "path_timer")) path_timer = 0;
                        if (variable_instance_exists(id, "fallback_mode")) fallback_mode = true;

                        break;
                    } else {
                        x = old_x;
                        y = old_y;
                    }
                }
            }

            // If escape fails after multiple attempts or a long time, teleport to a safe spot
            if (!escaped && (
                stuck_attempts > 15 || 
                (current_time - last_unstuck_time > 5000 && 
                 point_distance(x, y, last_unstuck_pos.x, last_unstuck_pos.y) < base_distance)
            )) {
                var search_dist = base_distance * 8;
                var found_safe_spot = false;

                for (var r = base_distance; r <= search_dist; r += base_distance) {
                    for (var a = 0; a < 360; a += 30) {
                        var test_x = last_unstuck_pos.x + lengthdir_x(r, a);
                        var test_y = last_unstuck_pos.y + lengthdir_y(r, a);

                        if (!collision_rectangle(
                            test_x - buffer, test_y - buffer,
                            test_x + buffer, test_y + buffer,
                            obj_collision, false, true
                        )) {
                            x = test_x;
                            y = test_y;
                            found_safe_spot = true;
                            break;
                        }
                    }
                    if (found_safe_spot) break;
                }

                // If no safe spot found, reset to last unstuck position
                if (!found_safe_spot) {
                    x = last_unstuck_pos.x;
                    y = last_unstuck_pos.y;
                }

                is_stuck = false;
                mask_index = original_mask;
                stuck_attempts = 0;

                if (variable_instance_exists(id, "hspeed")) hspeed = 0;
                if (variable_instance_exists(id, "vspeed")) vspeed = 0;
            }

            // Signal to avoidance that this entity is stuck
            return true; // Signal that the entity was unstuck
        } else if (is_stuck) {
            // Reset stuck state
            is_stuck = false;
            mask_index = original_mask;
            stuck_attempts = 0;
        }
    }

    return false;
}
