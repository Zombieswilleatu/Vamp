// Helper function for idle frame selection
function get_idle_frame(direction) {
    var frame = ANIM_WALK_DOWN_START; // Default value
    
    switch (direction) {
        case "right":
            frame = ANIM_WALK_RIGHT_START;
            break;
        case "left":
            frame = ANIM_WALK_LEFT_START;
            break;
        case "up":
            frame = ANIM_WALK_UP_START;
            break;
        case "down":
            frame = ANIM_WALK_DOWN_START;
            break;
    }
    
    return frame;
}

function scr_npc_animation(move_h, move_v) {
    // If we're in any idle state, don't run normal animation logic
    if ((npc_state == "idle" && idle_initialized) || 
        (npc_state == "search" && search_idle_active && idle_initialized)) {
        return; // Let the idle state handle animations
    }
    
    // Initialize instance variables if they don't exist
    if (!variable_instance_exists(id, "direction_change_timer")) {
        direction_change_timer = 0;
    }
    if (!variable_instance_exists(id, "desired_facing_direction")) {
        desired_facing_direction = facing_direction; 
    }
    if (!variable_instance_exists(id, "prev_x")) {
        prev_x = x;
        prev_y = y;
    }
    if (!variable_instance_exists(id, "actual_velocity")) {
        actual_velocity = 0;
    }
    if (!variable_instance_exists(id, "base_animation_speed")) {
        base_animation_speed = 0.4; // Store base animation speed as instance variable
    }
    
    // Calculate actual movement velocity based on position change
    var dx = x - prev_x;
    var dy = y - prev_y;
    actual_velocity = point_distance(0, 0, dx, dy);
    
    // Calculate normalized velocity (0 to 1 range)
    var max_expected_velocity = 4; // Adjust based on your game's movement speed
    var normalized_velocity = clamp(actual_velocity / max_expected_velocity, 0, 1);
    
    // Update previous position
    prev_x = x;
    prev_y = y;
    
    // Determine if we're actually moving (using both input and actual velocity)
    var has_movement_input = (abs(move_h) > 0.1) || (abs(move_v) > 0.1);
    var is_actually_moving = actual_velocity > 0.1; // Adjust threshold as needed
    var is_effectively_moving = has_movement_input && is_actually_moving;
    
    if (has_movement_input) {
        // Figure out the "ideal" or "desired" direction
        var abs_h = abs(move_h);
        var abs_v = abs(move_v);
        
        if (abs_h > abs_v) {
            desired_facing_direction = (move_h > 0) ? "right" : "left";
        } else {
            desired_facing_direction = (move_v > 0) ? "down" : "up";
        }
        
        // Handle direction changes with timer
        if (facing_direction != desired_facing_direction) {
            direction_change_timer++;
            
            if (direction_change_timer >= 5) {
                facing_direction = desired_facing_direction;
                direction_change_timer = 0;
            }
        } else {
            direction_change_timer = 0;
        }
        
        // Animation handling based on actual movement
        if (is_effectively_moving) {
            // Character is actually moving - play walk animation
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
            
            // Scale animation speed based on velocity
            var min_speed_multiplier = 0.3; // Animation won't go slower than 30% of base speed
            var speed_multiplier = min_speed_multiplier + ((1 - min_speed_multiplier) * normalized_velocity);
            image_speed = base_animation_speed * speed_multiplier;
            
        } else {
            // Has input but not actually moving - use idle
            image_speed = 0;
            image_index = get_idle_frame(facing_direction);
        }
    } else {
        // No movement input - idle state
        direction_change_timer = 0;
        image_speed = 0;
        image_index = get_idle_frame(facing_direction);
    }
}