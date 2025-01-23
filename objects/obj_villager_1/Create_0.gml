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
npc_state = "search";  // Starting state
state_timer = 0;       // For state timing
facing_direction = "down";
current_anim_frame = 0;
anim_speed = 0.2;

// Movement variables
push_x = 0;
push_y = 0;
move_speed = SEARCH_MOVE_SPEED;

// Set up initial sprite
sprite_index = sprite_index;
image_speed = 0;
image_index = ANIM_WALK_DOWN_START;

// Initialize search behavior with generated priority
npc_search_init(id, global.priority);

// Initialize required variables for state machine
follow_last_move_x = 0;
follow_last_move_y = 0;
search_last_move_x = 0;
search_last_move_y = 0;
search_initialized = true;
follow_initialized = false; // **Set to false initially**

path_priority = 0; // Ensure path_priority exists

// Mark initialization complete
initialized = true;
show_debug_message("------ VILLAGER CREATE END ------");
