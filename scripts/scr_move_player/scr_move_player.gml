function scr_move_player(obj) { 
    with (obj) {
        var hmove = 0;
        var vmove = 0;

        // Input handling
        if (keyboard_check(vk_right) || keyboard_check(ord("D"))) hmove += 1;
        if (keyboard_check(vk_left)  || keyboard_check(ord("A"))) hmove -= 1;
        if (keyboard_check(vk_down)  || keyboard_check(ord("S"))) vmove += 1;
        if (keyboard_check(vk_up)    || keyboard_check(ord("W"))) vmove -= 1;

        // Movement amounts
        var move_x = hmove * move_speed;
        var move_y = vmove * move_speed;

        // Horizontal Movement with sprite-based collision
        if (move_x != 0) {
            if (!place_meeting(x + move_x, y, obj_collision_root)) {
                x += move_x;
            } else {
                while (!place_meeting(x + sign(move_x), y, obj_collision_root)) {
                    x += sign(move_x);
                }
            }
        }

        // Vertical Movement with sprite-based collision
        if (move_y != 0) {
            if (!place_meeting(x, y + move_y, obj_collision_root)) {
                y += move_y;
            } else {
                while (!place_meeting(x, y + sign(move_y), obj_collision_root)) {
                    y += sign(move_y);
                }
            }
        }

        // Determine if the player is moving
        is_moving = (move_x != 0 || move_y != 0);

        // === Animation Handling ===
        if (is_moving) {
            if (image_index < current_anim_start || image_index > current_anim_end) {
                image_index = current_anim_start;
            }

            // Adjust the animation speed (smaller number = slower animation)
            image_index += 0.05; // Adjust this number as needed
            if (image_index > current_anim_end) {
                image_index = current_anim_start;
            }
        } else {
            // Idle animations when not moving
            switch (last_direction) {
                case "right": image_index = ANIM_WALK_RIGHT_START; break;
                case "left":  image_index = ANIM_WALK_LEFT_START;  break;
                case "up":    image_index = ANIM_WALK_UP_START;    break;
                case "down":  image_index = ANIM_WALK_DOWN_START;  break;
            }
        }

        // Update direction and animation based on movement
        if (abs(hmove) > abs(vmove)) {
            // Moving horizontally
            if (hmove > 0) {
                current_anim_start = ANIM_WALK_RIGHT_START;
                current_anim_end   = ANIM_WALK_RIGHT_END;
                last_direction = "right";
            } else if (hmove < 0) {
                current_anim_start = ANIM_WALK_LEFT_START;
                current_anim_end   = ANIM_WALK_LEFT_END;
                last_direction = "left";
            }
        } else if (abs(vmove) > 0) {
            // Moving vertically
            if (vmove < 0) {
                current_anim_start = ANIM_WALK_UP_START;
                current_anim_end   = ANIM_WALK_UP_END;
                last_direction = "up";
            } else {
                current_anim_start = ANIM_WALK_DOWN_START;
                current_anim_end   = ANIM_WALK_DOWN_END;
                last_direction = "down";
            }
        }
    }
}
