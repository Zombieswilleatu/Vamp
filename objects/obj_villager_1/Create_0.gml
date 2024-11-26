event_inherited();  // Inherit from obj_entity_root
show_debug_message("Villager Create Event Starting - Object ID: " + string(id));

// Initialize basic variables
initialized = false;
create_villager_variables();

// Delay full initialization check
alarm[0] = 2;  // First alarm checks for all required globals