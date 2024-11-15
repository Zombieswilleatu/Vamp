// Alarm[0] Event in obj_game_manager

if (global.grid.initialized) {
    show_debug_message("Activating NPCs...");
    instance_activate_object(obj_villager_1);
    show_debug_message("NPCs activated");
} else {
    show_debug_message("Still waiting for grid initialization...");
    alarm[0] = 1; // Re-check in the next step
}