/// @desc CREATE EVENT
show_debug_message("------ VILLAGER CREATE START ------");
// Create a global priority tracking system if it doesn't exist
if (!variable_global_exists("used_priorities")) {
    global.used_priorities = ds_list_create();
}

// Generate unique priority in 1.0-1.9 range
global.priority = -1;
var attempts = 0;
var max_attempts = 100;
while (global.priority == -1 && attempts < max_attempts) {
    var test_priority = 1 + (random(0.9));
    test_priority = round(test_priority * 10) / 10;
    
    var priority_found = false;
    for (var i = 0; i < ds_list_size(global.used_priorities); i++) {
        if (global.used_priorities[| i] == test_priority) {
            priority_found = true;
            break;
        }
    }
    
    if (!priority_found) {
        global.priority = test_priority;
        ds_list_add(global.used_priorities, global.priority);
        show_debug_message("Generated unique priority: " + string(global.priority));
    }
    
    attempts++;
}

if (global.priority == -1) {
    global.priority = 1.0;
    show_debug_message("WARNING: Could not generate unique priority, using fallback: " + string(global.priority));
}

// Core variables
initialized = false;
npc_state = "idle";  // Start in 'idle' state
state_timer = 0;     // For state timing

// Animation variables
facing_direction = "down";
current_anim_frame = 0;
anim_speed = 0;  // Start with 0 animation speed for idle
base_animation_speed = 0.4;
desired_facing_direction = "down";
force_sprite_update = true;  // New flag to force sprite updates

// Movement and physics variables
push_x = 0;
push_y = 0;
move_speed = SEARCH_MOVE_SPEED;
actual_velocity = 0;

// Position tracking
prev_x = x;
prev_y = y;
path_target_x = x;
path_target_y = y;
target_x = x;
target_y = y;
last_valid_target_x = x;
last_valid_target_y = y;

// Path and priority
path_priority = 0;

// Debug/Visual settings
draw_detection_eye = true;

// State initialization flags
search_initialized = false;
follow_initialized = false;
idle_initialized = false;
search_idle_active = false;  // Added this flag

// Movement history
follow_last_move_x = 0;
follow_last_move_y = 0;
search_last_move_x = 0;
search_last_move_y = 0;

// Set up initial sprite
sprite_index = sprite_index;
image_speed = 0;
image_index = ANIM_WALK_DOWN_START;

// Animation control variables
current_sprite_direction = "down";
override_animation = false;

// Mark initialization complete
initialized = true;
show_debug_message("------ VILLAGER CREATE END ------");