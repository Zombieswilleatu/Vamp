// Alarm 0 Event for obj_villager_1
if (!variable_global_exists("cell_size") || 
    !variable_global_exists("grid") || 
    !variable_global_exists("navigation_grid") ||
    !variable_global_exists("zone_maps") ||
    !global.grid.initialized || 
    global.navigation_grid == undefined) {
    
    show_debug_message("Waiting for initialization... Cell size exists: " + 
                      string(variable_global_exists("cell_size")) +
                      ", Grid exists: " + string(variable_global_exists("grid")));
    alarm[0] = 60; // Increased retry delay
    exit;
}

if (!initialized) {
    create_villager_variables();
    create_debug_variables();
    create_detection_variables();
    initialized = true;
    show_debug_message("Villager fully initialized!");
    alarm[1] = 1;
}