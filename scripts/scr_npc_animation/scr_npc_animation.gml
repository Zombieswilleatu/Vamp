function get_idle_frame(direction) {
    switch (direction) {
        case "right":
            return ANIM_WALK_RIGHT_START;
        case "left":
            return ANIM_WALK_LEFT_START;
        case "up":
            return ANIM_WALK_UP_START;
        case "down":
            return ANIM_WALK_DOWN_START;
        default:
            return ANIM_WALK_DOWN_START;
    }
}

function scr_npc_animation(move_h, move_v) {
    var is_moving = (abs(move_h) > 0.1) || (abs(move_v) > 0.1);
    
    if (is_moving) {
        if (abs(move_h) > abs(move_v)) {
            facing_direction = (move_h > 0) ? "right" : "left";
        } else {
            facing_direction = (move_v > 0) ? "down" : "up";
        }
        
        image_speed = 0.6;
        
        switch (facing_direction) {
            case "right":
                if (image_index < ANIM_WALK_RIGHT_START || image_index >= ANIM_WALK_RIGHT_END) {
                    image_index = ANIM_WALK_RIGHT_START;
                }
                break;
            case "left":
                if (image_index < ANIM_WALK_LEFT_START || image_index >= ANIM_WALK_LEFT_END) {
                    image_index = ANIM_WALK_LEFT_START;
                }
                break;
            case "up":
                if (image_index < ANIM_WALK_UP_START || image_index >= ANIM_WALK_UP_END) {
                    image_index = ANIM_WALK_UP_START;
                }
                break;
            case "down":
                if (image_index < ANIM_WALK_DOWN_START || image_index >= ANIM_WALK_DOWN_END) {
                    image_index = ANIM_WALK_DOWN_START;
                }
                break;
        }
    } else {
        image_speed = 0;
        image_index = get_idle_frame(facing_direction);
    }
}