// Inherit from parent first
event_inherited();

// Save current position
var previous_x = x;
var previous_y = y;

// Handle player movement based on input (Arrows OR WASD)
var h_input = (keyboard_check(vk_right) || keyboard_check(ord("D"))) - (keyboard_check(vk_left) || keyboard_check(ord("A")));
var v_input = (keyboard_check(vk_down) || keyboard_check(ord("S"))) - (keyboard_check(vk_up) || keyboard_check(ord("W")));

// Calculate intended movement
var intended_hspeed = 0;
var intended_vspeed = 0;

if (h_input != 0 || v_input != 0) {
    // Normalize diagonal movement
    var len = sqrt(h_input * h_input + v_input * v_input);
    intended_hspeed = (h_input / len) * move_speed;
    intended_vspeed = (v_input / len) * move_speed;
    is_moving = true;

    // Animation direction handling remains the same
    if (abs(h_input) > abs(v_input)) {
        if (h_input > 0) {
            current_anim_start = ANIM_WALK_RIGHT_START;
            current_anim_end = ANIM_WALK_RIGHT_END;
            last_direction = "right";
        } else {
            current_anim_start = ANIM_WALK_LEFT_START;
            current_anim_end = ANIM_WALK_LEFT_END;
            last_direction = "left";
        }
    } else {
        if (v_input > 0) {
            current_anim_start = ANIM_WALK_DOWN_START;
            current_anim_end = ANIM_WALK_DOWN_END;
            last_direction = "down";
        } else {
            current_anim_start = ANIM_WALK_UP_START;
            current_anim_end = ANIM_WALK_UP_END;
            last_direction = "up";
        }
    }
} else {
    is_moving = false;
    // Idle animation handling remains the same
    switch(last_direction) {
        case "down":
            current_anim_start = ANIM_WALK_DOWN_START;
            current_anim_end = ANIM_WALK_DOWN_START;
            break;
        case "up":
            current_anim_start = ANIM_WALK_UP_START;
            current_anim_end = ANIM_WALK_UP_START;
            break;
        case "left":
            current_anim_start = ANIM_WALK_LEFT_START;
            current_anim_end = ANIM_WALK_LEFT_START;
            break;
        case "right":
            current_anim_start = ANIM_WALK_RIGHT_START;
            current_anim_end = ANIM_WALK_RIGHT_START;
            break;
    }
}

// Movement and collision handling
if (is_moving) {
    // Try full movement first
    var can_move = !place_meeting(x + intended_hspeed, y + intended_vspeed, obj_collision);

    if (can_move) {
        x += intended_hspeed;
        y += intended_vspeed;
    } else {
        // Try horizontal movement
        if (!place_meeting(x + intended_hspeed, y, obj_collision)) {
            x += intended_hspeed;
        }

        // Try vertical movement
        if (!place_meeting(x, y + intended_vspeed, obj_collision)) {
            y += intended_vspeed;
        }
    }

    // Handle NPC collisions with smoother separation
    if (place_meeting(x, y, obj_villager_1)) {
        var inst = instance_place(x, y, obj_villager_1);
        if (inst != noone) {
            var dir = point_direction(inst.x, inst.y, x, y);
            var push_amount = 2; // Adjust this value as needed
            x = previous_x + lengthdir_x(push_amount, dir);
            y = previous_y + lengthdir_y(push_amount, dir);
        }
    }
}

// Handle animation
if (is_moving) {
    image_index += image_speed;
    if (image_index >= current_anim_end || image_index < current_anim_start) {
        image_index = current_anim_start;
    }
} else {
    image_index = current_anim_start;
}

// Room boundary constraints adjusting for center origin
var half_width = sprite_width / 2;
var half_height = sprite_height / 2;
x = clamp(x, half_width, room_width - half_width);
y = clamp(y, half_height, room_height - half_height);
