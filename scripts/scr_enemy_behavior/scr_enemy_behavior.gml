/// @description Main controller for NPC states (idle/search/follow).
function scr_enemy_behavior() {
    // Increase state timer every step - ALWAYS increment regardless of sub-state
    state_timer++;
    
    switch (npc_state) {
        case "idle": {
            // Define idle duration (3 seconds)
            var idle_duration = room_speed * 3;
            
            // Initialize idle state if needed
            if (!idle_initialized) {
                show_debug_message("=== INITIALIZING IDLE STATE ===");
                npc_idle_init(id);
            }
            
            if (state_timer >= idle_duration) {
                show_debug_message("=== TRANSITIONING FROM IDLE TO SEARCH ===");
                
                // 1) Clean up old (idle) state variables
                cleanup_state_variables(id, "idle");
                
                // 2) Change state
                npc_state = "search";
                state_timer = 0;
                
                // 3) Initialize new (search) state
                npc_search_init(id, global.priority);
                
                // Update initialization flags
                search_initialized = true;
                follow_initialized = false;
                idle_initialized = false;
            } else {
                // Handle idle-specific looking behavior
                npc_idle_update(id);
            }
            break;
        }
        
        case "search": {
            // Make sure idle_state_timer exists
            if (!variable_instance_exists(id, "idle_state_timer")) {
                idle_state_timer = 0;
            }
            
            // If search_idle_active doesn't exist, initialize it
            if (!variable_instance_exists(id, "search_idle_active")) {
                search_idle_active = false;
            }
            
            // Handle the search-idle sub-state
            if (search_idle_active) {
                // Only initialize idle if we haven't already
                if (!idle_initialized) {
                    show_debug_message("=== INITIALIZING SEARCH-IDLE STATE ===");
                    idle_state_timer = 0;  // Reset timer when initializing
                    npc_idle_init(id);
                }
                
                // Let idle state run for full 3 seconds
                if (idle_state_timer >= room_speed * 3) {
                    show_debug_message("=== ENDING SEARCH-IDLE, RESUMING SEARCH ===");
                    cleanup_state_variables(id, "idle");
                    search_idle_active = false;
                    idle_initialized = false;
                    idle_state_timer = 0;
                } else {
                    // Update idle behavior and increment its timer
                    npc_idle_update(id);
                    idle_state_timer++;
                    show_debug_message("Idle timer: " + string(idle_state_timer) + "/" + string(room_speed * 3));
                }
            } else {
                // Continue handling search logic if not in idle
                npc_search_update(id);
            }
            
            // Check for follow transition AFTER handling sub-states
            // This ensures the timer keeps running during search-idle
            if (state_timer >= room_speed * 20) {
                show_debug_message("=== TRANSITIONING FROM SEARCH TO FOLLOW ===");
                show_debug_message("State timer at transition: " + string(state_timer));

                // 1) Clean up old (search) state variables
                cleanup_state_variables(id, "search");

                // 2) Change state
                npc_state = "follow";
                state_timer = 0;

                // 3) Initialize new (follow) state
                npc_follow_init(id);

                // Update initialization flags
                follow_initialized = true;
                search_initialized = false;
                idle_initialized = false;
            }
            break;
        }
        
        case "follow": {
            // After 20 seconds, switch to 'idle'
            if (state_timer >= room_speed * 20) {
                show_debug_message("=== TRANSITIONING FROM FOLLOW TO IDLE ===");

                // 1) Clean up old (follow) state variables
                cleanup_state_variables(id, "follow");

                // 2) Change state to 'idle'
                npc_state = "idle";
                state_timer = 0;

                // Update initialization flags
                follow_initialized = false;
                search_initialized = false;
                idle_initialized = false;
            } else {
                // Continue handling follow logic
                npc_follow_update(id);
            }
            break;
        }
    }
}

/// @description Dumps all instance variables for debugging
function debug_dump_instance_vars(inst) {
    with (inst) {
        show_debug_message("=== INSTANCE VARIABLE DUMP ===");
        show_debug_message("Instance ID: " + string(id));

        // Grab all variable names from this instance
        var all_vars = variable_instance_get_names(id);

        // Sort them for readability
        array_sort(all_vars, true);

        // Print each variable's name and value
        for (var i = 0; i < array_length(all_vars); i++) {
            var var_name = all_vars[i];
            var val = variable_instance_get(id, var_name);

            var val_str;
            if (is_array(val)) {
                val_str = "Array[" + string(array_length(val)) + "]";
            } else if (is_struct(val)) {
                val_str = "Struct";
            } else {
                val_str = string(val);
            }

            show_debug_message(var_name + " = " + val_str);
        }

        show_debug_message("=== END VARIABLE DUMP ===");
    }
}

/// @description Cleans up variables from the state we are leaving
function cleanup_state_variables(inst, leaving_state) {
    with (inst) {
        show_debug_message("=== STARTING CLEANUP OF " + string(leaving_state) + " STATE ===");

        var all_vars = variable_instance_get_names(id);
        show_debug_message("Total variables before cleanup: " + string(array_length(all_vars)));

        //--------------------------------------------------------------------------------
        // 1) Build preserve map with safe fallbacks
        //--------------------------------------------------------------------------------
        var preserve_map = {};
        
        // Basic persistent attributes
        preserve_map[$ "x"] = variable_instance_exists(id, "x") ? x : 0;
        preserve_map[$ "y"] = variable_instance_exists(id, "y") ? y : 0;
        preserve_map[$ "npc_state"] = variable_instance_exists(id, "npc_state") ? npc_state : "idle";
        preserve_map[$ "state_timer"] = variable_instance_exists(id, "state_timer") ? state_timer : 0;
        preserve_map[$ "initialized"] = variable_instance_exists(id, "initialized") ? initialized : false;
		preserve_map[$ "idle_state_timer"] = variable_instance_exists(id, "idle_state_timer") ? idle_state_timer : 0;

        // Animation
        preserve_map[$ "anim_speed"] = variable_instance_exists(id, "anim_speed") ? anim_speed : 0.2;
        preserve_map[$ "base_animation_speed"] = variable_instance_exists(id, "base_animation_speed") ? base_animation_speed : 0.2;
        preserve_map[$ "current_anim_frame"] = variable_instance_exists(id, "current_anim_frame") ? current_anim_frame : 0;
        preserve_map[$ "facing_direction"] = variable_instance_exists(id, "facing_direction") ? facing_direction : "down";
        preserve_map[$ "desired_facing_direction"] = variable_instance_exists(id, "desired_facing_direction") ? desired_facing_direction : "down";

        // Debug / visuals
        preserve_map[$ "draw_detection_eye"] = variable_instance_exists(id, "draw_detection_eye") ? draw_detection_eye : true;

        // Movement / path
        preserve_map[$ "prev_x"] = variable_instance_exists(id, "prev_x") ? prev_x : x;
        preserve_map[$ "prev_y"] = variable_instance_exists(id, "prev_y") ? prev_y : y;
        preserve_map[$ "path_priority"] = variable_instance_exists(id, "path_priority") ? path_priority : 0;
        preserve_map[$ "last_valid_target_x"] = variable_instance_exists(id, "last_valid_target_x") ? last_valid_target_x : x;
        preserve_map[$ "last_valid_target_y"] = variable_instance_exists(id, "last_valid_target_y") ? last_valid_target_y : y;
        preserve_map[$ "path_target_x"] = variable_instance_exists(id, "path_target_x") ? path_target_x : x;
        preserve_map[$ "path_target_y"] = variable_instance_exists(id, "path_target_y") ? path_target_y : y;
        preserve_map[$ "target_x"] = variable_instance_exists(id, "target_x") ? target_x : x;
        preserve_map[$ "target_y"] = variable_instance_exists(id, "target_y") ? target_y : y;
        preserve_map[$ "actual_velocity"] = variable_instance_exists(id, "actual_velocity") ? actual_velocity : 0;

        //--------------------------------------------------------------------------------
        // 2) Clean up all variables that start with "search_", "follow_", or "idle_" from OLD state.
        //--------------------------------------------------------------------------------
        for (var i = 0; i < array_length(all_vars); i++) {
            var var_name = all_vars[i];
            // If it's a "search_", "follow_", or "idle_" variable, reset it
            if (string_pos("search_", var_name) == 1 || 
                string_pos("follow_", var_name) == 1 ||
                string_pos("idle_", var_name) == 1) {
                // Only reset if it matches the leaving state prefix or is definitely state-specific
                if ((leaving_state == "search" && string_pos("search_", var_name) == 1) ||
                    (leaving_state == "follow" && string_pos("follow_", var_name) == 1) ||
                    (leaving_state == "idle" && string_pos("idle_", var_name) == 1)) {
                    
                    // Clear arrays or set to zero
                    if (is_array(variable_instance_get(id, var_name))) {
                        variable_instance_set(id, var_name, []);
                    } else {
                        variable_instance_set(id, var_name, 0);
                    }
                    show_debug_message("Reset state var: " + var_name);
                }
            }
        }

        //--------------------------------------------------------------------------------
        // 3) Set default (safe) values for frequently used generic variables
        //--------------------------------------------------------------------------------
        var defaults = {
            vx: 0,
            vy: 0,
            move_speed: 2.5,
            push_x: 0,
            push_y: 0,
            pathfinding_cooldown: 0,
            pathfinding_delay_timer: 0,
            path_retry_timer: 0,
            stuck_timer: 0,
            stuck_counter: 0,
            emergency_stuck_timer: 0,
            emergency_unstuck_cooldown: 0,
            consecutive_failures: 0,
            path_fail_counter: 0,
            waypoint_failure_count: 0,
            unstuck_attempts: 0,
            blocked_path_timer: 0,
            deadlock_timer: 0,
            post_unstuck_timer: 0,
            temp_current_x: x,
            temp_current_y: y,
            temp_target_x: path_target_x,
            temp_target_y: path_target_y,
            last_position_x: x,
            last_position_y: y,
            last_unstuck_x: x,
            last_unstuck_y: y,
            last_path_attempt_x: x,
            last_path_attempt_y: y,
            last_pathfind_time: 0
        };

        var default_names = variable_struct_get_names(defaults);
        for (var d = 0; d < array_length(default_names); d++) {
            var d_name = default_names[d];
            variable_instance_set(id, d_name, defaults[$ d_name]);
            show_debug_message("Set default var: " + d_name + " to " + string(defaults[$ d_name]));
        }

        //--------------------------------------------------------------------------------
        // 4) Restore the PRESERVED variables
        //--------------------------------------------------------------------------------
        var preserve_names = variable_struct_get_names(preserve_map);
        for (var p = 0; p < array_length(preserve_names); p++) {
            var p_name = preserve_names[p];
            variable_instance_set(id, p_name, preserve_map[$ p_name]);
            show_debug_message("Preserved var: " + p_name + " as " + string(preserve_map[$ p_name]));
        }

        show_debug_message("=== CLEANUP COMPLETE ===");
    }
}

