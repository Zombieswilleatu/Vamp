/// @description Initialize idle state variables and behavior
function npc_idle_init(inst) {
    with (inst) {
        // Create array of all 8 logical directions
        idle_directions = [
            "up",
            "upright",
            "right",
            "downright",
            "down",
            "downleft",
            "left",
            "upleft"
        ];
        
        // Create mapping for visual representation
        idle_direction_to_sprite = {
            "up": "up",
            "upright": "up",    // Map diagonal to nearest cardinal
            "right": "right",
            "downright": "right", // Map diagonal to nearest cardinal
            "down": "down",
            "downleft": "down",  // Map diagonal to nearest cardinal
            "left": "left",
            "upleft": "left"    // Map diagonal to nearest cardinal
        };
        
        // Randomize the order of directions
        var n = array_length(idle_directions);
        for (var i = n - 1; i > 0; i--) {
            var j = irandom(i);
            var temp = idle_directions[i];
            idle_directions[i] = idle_directions[j];
            idle_directions[j] = temp;
        }
        
        // Initialize idle-specific variables
        idle_direction_index = 0;  // Current index in the shuffled directions
        idle_look_timer = 0;       // Timer for current direction
        idle_look_duration = room_speed * 0.375;  // Time per direction (3 seconds / 8 directions)
        idle_initialized = true;
        override_animation = true;  // Take control of animation
        
        // Set initial direction immediately
        var initial_direction = idle_directions[0];
        var initial_sprite_direction = idle_direction_to_sprite[$ initial_direction];
        
        facing_direction = initial_direction;
        desired_facing_direction = initial_direction;
        current_sprite_direction = initial_sprite_direction;
        
        // Force initial sprite update
        image_speed = 0;
        image_index = get_idle_frame(initial_sprite_direction);
        force_sprite_update = true;
        
        show_debug_message("Idle state initialized with randomized directions: " + 
            string_join_ext(", ", idle_directions));
        show_debug_message("Initial idle direction: " + initial_direction + 
            " (showing sprite for " + initial_sprite_direction + ")");
    }
}

/// @description Update idle state behavior
function npc_idle_update(inst) {
    with (inst) {
        // Increment look timer
        idle_look_timer++;
        
        // Time to switch to next direction?
        if (idle_look_timer >= idle_look_duration) {
            idle_look_timer = 0;
            
            if (idle_direction_index >= array_length(idle_directions)) {
                idle_direction_index = 0;  // Loop back to start if needed
            }
            
            // Get the next logical direction
            var logical_direction = idle_directions[idle_direction_index];
            
            // Get the mapped sprite direction
            var sprite_direction = idle_direction_to_sprite[$ logical_direction];
            
            // Set all direction variables
            facing_direction = logical_direction;
            desired_facing_direction = logical_direction;
            current_sprite_direction = sprite_direction;
            
            show_debug_message("Idle: Looking " + logical_direction + 
                " (Direction " + string(idle_direction_index + 1) + " of 8, showing sprite for " + 
                sprite_direction + ")");
            
            // Force animation update
            image_speed = 0;
            image_index = get_idle_frame(sprite_direction);
            
            // Move to next direction
            idle_direction_index++;
        } else {
            // Important: Keep reinforcing the current sprite between direction changes
            if (variable_instance_exists(id, "current_sprite_direction")) {
                image_speed = 0;
                image_index = get_idle_frame(current_sprite_direction);
            }
        }
    }
}