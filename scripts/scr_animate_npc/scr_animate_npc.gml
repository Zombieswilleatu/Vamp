function scr_animate_npc(obj) {
    with (obj) {
        if (abs(hspeed) > 0.1 || abs(vspeed) > 0.1) {
            is_moving = true;
            
            // Update last_direction if it doesn't match facing_direction
            if (last_direction != facing_direction) {
                last_direction = facing_direction;
            }
            
            // Handle walking animations based on facing_direction
            switch (facing_direction) {
                case "right":
                    current_anim_start = ANIM_WALK_RIGHT_START;
                    current_anim_end = ANIM_WALK_RIGHT_END;
                    break;
                case "left":
                    current_anim_start = ANIM_WALK_LEFT_START;
                    current_anim_end = ANIM_WALK_LEFT_END;
                    break;
                case "up":
                    current_anim_start = ANIM_WALK_UP_START;
                    current_anim_end = ANIM_WALK_UP_END;
                    break;
                case "down":
                    current_anim_start = ANIM_WALK_DOWN_START;
                    current_anim_end = ANIM_WALK_DOWN_END;
                    break;
            }

            // Set constant animation speed
            image_speed = 0.3;
            
            // If we're outside the current animation range, reset to start
            if (floor(image_index) < current_anim_start || floor(image_index) > current_anim_end) {
                image_index = current_anim_start;
            }
            
            // Let GameMaker handle the animation cycling
            if (image_index >= current_anim_end) {
                image_index = current_anim_start;
            }

            //show_debug_message("Before Frame Change | Frame: " + string(image_index));

        } else {
            is_moving = false;
            // Use facing_direction for idle frames
            switch (facing_direction) {
                case "right": image_index = ANIM_WALK_RIGHT_START; break;
                case "left": image_index = ANIM_WALK_LEFT_START; break;
                case "up": image_index = ANIM_WALK_UP_START; break;
                case "down": image_index = ANIM_WALK_DOWN_START; break;
            }
            image_speed = 0;
        }
        
        //show_debug_message("After Frame Change | Frame: " + string(image_index));
    }
}