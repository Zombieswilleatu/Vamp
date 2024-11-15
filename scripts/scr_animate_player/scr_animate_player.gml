function scr_animate_player(obj) {
    with (obj) {
        if (is_moving) {
            // If moving, animate through the current animation frames
            if (image_index < current_anim_start || image_index > current_anim_end) {
                image_index = current_anim_start; // Start the animation for the current direction
            } else {
                image_index += 0.2; // Move to the next frame (adjust speed as needed)
                if (image_index > current_anim_end) {
                    image_index = current_anim_start; // Loop the animation
                }
            }
        } else {
            // If not moving, use the first frame of the last direction's animation
            switch (last_direction) {
                case "right":
                    image_index = ANIM_WALK_RIGHT_START;
                    break;
                case "left":
                    image_index = ANIM_WALK_LEFT_START;
                    break;
                case "up":
                    image_index = ANIM_WALK_UP_START;
                    break;
                case "down":
                    image_index = ANIM_WALK_DOWN_START;
                    break;
            }
        }
    }
}
