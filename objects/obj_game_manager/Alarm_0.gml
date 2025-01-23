/// @desc Alarm[0] Event of obj_game_manager
if (!initialize_game_systems()) {
    __init_debug_log("Initialization failed. Retrying...");
    alarm[0] = 1;
}