/// @description Main controller for NPC states (search/follow).

function scr_enemy_behavior() {
    // Increase state timer every step
    state_timer++;

    switch (npc_state) {
        case "search": {
            // After 10 seconds (room_speed * 10), switch to 'follow'
            if (state_timer >= room_speed * 20) {
                show_debug_message("=== BEFORE TRANSITION TO SEARCH->FOLLOW ===");
                debug_dump_instance_vars(id);

                // 1) Clean up old (search) state variables BEFORE changing state
                cleanup_state_variables(id, "search");

                // 2) Change state
                npc_state = "follow";
                state_timer = 0;

                // 3) Initialize new (follow) state
                npc_follow_init(id);

                show_debug_message("Auto-transitioning to follow state after 10 seconds");
                show_debug_message("=== AFTER TRANSITION TO SEARCH->FOLLOW ===");
                debug_dump_instance_vars(id);
            } else {
                // Continue handling search logic
                npc_search_update(id);
            }
            break;
        }

        case "follow": {
            // After 10 seconds (room_speed * 10), switch to 'search'
            if (state_timer >= room_speed * 20) {
                show_debug_message("=== BEFORE TRANSITION TO FOLLOW->SEARCH ===");
                debug_dump_instance_vars(id);

                // 1) Clean up old (follow) state variables BEFORE changing state
                cleanup_state_variables(id, "follow");

                // 2) Change state
                npc_state = "search";
                state_timer = 0;

                // 3) Initialize new (search) state
                npc_search_init(id, global.priority);

                show_debug_message("Auto-transitioning to search state after 10 seconds");
                show_debug_message("=== AFTER TRANSITION TO FOLLOW->SEARCH ===");
                debug_dump_instance_vars(id);
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
        // 1) Identify variables to PRESERVE (these remain across states).
        //--------------------------------------------------------------------------------
        var preserve_map = {
            // Basic persistent attributes
            "x": x,
            "y": y,
            "npc_state": npc_state,
            "state_timer": state_timer,
            "initialized": initialized,

            // Animation
            "anim_speed": anim_speed,
            "base_animation_speed": base_animation_speed,
            "current_anim_frame": current_anim_frame,
            "facing_direction": facing_direction,
            "desired_facing_direction": desired_facing_direction,

            // Debug / visuals
            "draw_detection_eye": draw_detection_eye,

            // Movement / path
            "prev_x": x,
            "prev_y": y,
            "path_priority": path_priority,
            "last_valid_target_x": last_valid_target_x,
            "last_valid_target_y": last_valid_target_y,
            "path_target_x": path_target_x,
            "path_target_y": path_target_y,
            "target_x": target_x,
            "target_y": target_y,

            // If you want to preserve velocity/acceleration:
            "actual_velocity": actual_velocity
        };

        //--------------------------------------------------------------------------------
        // 2) Clean up all variables that start with "search_" or "follow_" from OLD state.
        //--------------------------------------------------------------------------------
        for (var i = 0; i < array_length(all_vars); i++) {
            var var_name = all_vars[i];
            // If it's a "search_" or "follow_" variable, reset it
            if (string_pos("search_", var_name) == 1 || string_pos("follow_", var_name) == 1) {
                // only reset if it matches the leaving state prefix or is definitely state-specific
                if ((leaving_state == "search" && string_pos("search_", var_name) == 1)
                 || (leaving_state == "follow" && string_pos("follow_", var_name) == 1)) {
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
        // You can adjust these defaults to suit your NPC’s needs
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

        //--------------------------------------------------------------------------------
        // 5) Final Debug
        //--------------------------------------------------------------------------------
        all_vars = variable_instance_get_names(id);
        show_debug_message("Total variables after cleanup: " + string(array_length(all_vars)));
        show_debug_message("=== CLEANUP COMPLETE ===");
    }
}
