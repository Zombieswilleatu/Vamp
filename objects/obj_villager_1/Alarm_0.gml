if (!variable_global_exists("cell_size") || !variable_global_exists("nav_grid")) {
    show_debug_message("Alarm[0] - Waiting for core initialization...");
    alarm[0] = 60;
    exit;
}

show_debug_message("Alarm[0] - All checks passed, initializing villager");
create_detection_variables(); // Ensure detection variables are initialized first
create_debug_variables();     // Then debug variables
create_villager_variables();
initialized = true;
show_debug_message("Villager fully initialized - ID: " + string(id));
alarm[1] = 1;
