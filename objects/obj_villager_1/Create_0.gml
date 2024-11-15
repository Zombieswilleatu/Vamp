// Create Event for obj_villager_1
event_inherited();  // Inherit from obj_entity_root
show_debug_message("Villager Create Event Starting - Object ID: " + string(id));

// Initialize basic variables
initialized = false;
npc_state = "search";  // Start in search mode
debug_enabled = true;
show_path_debug = true;

// Initialize my_path to noone
my_path = noone;  // This ensures my_path exists before we use it

// Check for required global grids
if (!variable_global_exists("astar_grid") || 
    !variable_global_exists("path_grid") ||
    global.astar_grid == undefined || 
    global.path_grid == undefined) {
    show_debug_message("Waiting for grid initialization...");
    alarm[0] = 1;
    exit;
}

// Start initialization sequence
alarm[0] = 1;
