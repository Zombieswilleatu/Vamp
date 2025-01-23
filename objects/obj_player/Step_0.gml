// Player Step Event
event_inherited();

// Input handling
var h_input = (keyboard_check(vk_right) || keyboard_check(ord("D"))) - (keyboard_check(vk_left) || keyboard_check(ord("A")));
var v_input = (keyboard_check(vk_down) || keyboard_check(ord("S"))) - (keyboard_check(vk_up) || keyboard_check(ord("W")));

// Movement calculation
var intended_dir = 0;
is_moving = (h_input != 0 || v_input != 0);

if (is_moving) {
    // Calculate movement direction and normalize
    intended_dir = point_direction(0, 0, h_input, v_input);
    dir = intended_dir;
    
    // Animation handling based on primary movement direction
    if (abs(h_input) > abs(v_input)) {
        // Horizontal movement dominates
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
        // Vertical movement dominates
        if (v_input < 0) { // Up movement
            current_anim_start = ANIM_WALK_UP_START;
            current_anim_end = ANIM_WALK_UP_END;
            last_direction = "up";
        } else { // Down movement
            current_anim_start = ANIM_WALK_DOWN_START;
            current_anim_end = ANIM_WALK_DOWN_END;
            last_direction = "down";
        }
    }
    
    // Calculate base movement
    var move_speed_adjusted = move_speed;
    if (h_input != 0 && v_input != 0) {
        // Normalize diagonal movement
        move_speed_adjusted *= 0.7071; // approximately 1/sqrt(2)
    }
    
    var move_x = h_input * move_speed_adjusted;
    var move_y = v_input * move_speed_adjusted;
    
    // Store current position for potential rollback
    var previous_x = x;
    var previous_y = y;
    
    // Wall collision handling
    if (!place_meeting(x + move_x, y + move_y, obj_collision)) {
        // Full movement possible
        x += move_x;
        y += move_y;
    } else {
        // Try horizontal then vertical movement
        if (!place_meeting(x + move_x, y, obj_collision)) {
            x += move_x;
        }
        if (!place_meeting(x, y + move_y, obj_collision)) {
            y += move_y;
        }
    }
    
    // NPC collision handling with gentle pushing
    var push_range = 32; // Detection range for NPCs
    var push_strength = 2; // How strongly to push NPCs
    
    with (obj_entity_root) {
        if (id != other.id) {
            var dist = point_distance(x, y, other.x, other.y);
            if (dist < push_range) {
                // Calculate push direction
                var push_dir = point_direction(other.x, other.y, x, y);
                var push_amount = (push_range - dist) / push_range * push_strength;
                
                // Move NPC away from player
                x += lengthdir_x(push_amount, push_dir);
                y += lengthdir_y(push_amount, push_dir);
                
                // Slightly adjust player position in opposite direction
                other.x -= lengthdir_x(push_amount * 0.2, push_dir);
                other.y -= lengthdir_y(push_amount * 0.2, push_dir);
            }
        }
    }
    
} else {
    // Idle animation handling
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

// Animation update
if (is_moving) {
    image_index += image_speed;
    if (image_index >= current_anim_end || image_index < current_anim_start) {
        image_index = current_anim_start;
    }
} else {
    image_index = current_anim_start;
}

// Room boundary constraints
var half_width = sprite_width / 2;
var half_height = sprite_height / 2;
x = clamp(x, half_width, room_width - half_width);
y = clamp(y, half_height, room_height - half_height);