/// Alarm[0] - Check for grid initialization
// This alarm handles the initial grid check and full initialization

// Check for required global variables
if (!variable_global_exists("path_grid") ||
    global.path_grid == undefined) {
    show_debug_message("Still waiting for grid initialization...");
    alarm[0] = 1;
    exit;
}

// If we get here, grids are ready - do full initialization
if (!initialized) {
    // Create path if it doesn't exist
    if (!path_exists(my_path)) {
        my_path = path_add();
    }

    // Initialize variables
    create_villager_variables();
    create_debug_variables();
    create_detection_variables(); // Ensure this function exists

    // Mark as initialized
    initialized = true;
    show_debug_message("Villager fully initialized after grid check!");
    
    // Start region check or other necessary processes
    alarm[1] = 1;
}
