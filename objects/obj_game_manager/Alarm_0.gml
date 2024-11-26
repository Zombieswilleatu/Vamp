// Also let's modify the alarm[0] event to include more debugging
if (global.grid.initialized) {
    show_debug_message("Activating NPCs... Grid is initialized");
    instance_activate_object(obj_villager_1);
    show_debug_message("NPCs activated");
} else {
    show_debug_message("Still waiting for grid initialization... Current state: " + string(global.grid.initialized));
    alarm[0] = 1; // Re-check in the next step
}