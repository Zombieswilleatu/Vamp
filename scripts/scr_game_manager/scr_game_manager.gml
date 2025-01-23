// In a script file called scr_game_manager

/// @desc Initialize all global variables and systems
function initialize_globals() {
    // Window setup
    window_set_fullscreen(true);
    
    // Core globals - check if they exist first
    if (!variable_global_exists("cell_size"))             global.cell_size = 32;
    if (!variable_global_exists("current_frame"))         global.current_frame = 0;
    if (!variable_global_exists("update_frame"))          global.update_frame = 0;
    if (!variable_global_exists("FRAME_UPDATE_INTERVAL")) global.FRAME_UPDATE_INTERVAL = 30;
    if (!variable_global_exists("fps"))                   global.fps = 0;
    if (!variable_global_exists("debug_mode"))            global.debug_mode = false;
    
    // Initialize debug logging
    __init_debug_log("Global variables initialized");
}

/// @desc Debug logging with system identification
/// @param {String} message Message to log
function __init_debug_log(message) {
    if (global.debug_mode) {
        show_debug_message("[Init] " + string(message));
    }
}

/// @desc Initialization sequence for all game systems
/// @returns {Bool} Whether initialization was successful
function initialize_game_systems() {
    var tilemap_id = layer_tilemap_get_id("Tile_unwalkable");
    if (tilemap_id == -1) {
        __init_debug_log("ERROR: Could not find tilemap 'Tile_unwalkable'");
        return false;
    }
    
    // Step 1: Initialize Pathfinding System
    if (!pathfinding_system_init(global.cell_size)) {
        __init_debug_log("ERROR: Failed to initialize pathfinding system");
        return false;
    }
    __init_debug_log("Pathfinding system initialized");
    
    // Step 2: Create Navigation Grid
    if (!pathfinding_create_grid(tilemap_id, 1)) {
        __init_debug_log("ERROR: Failed to create navigation grid");
        return false;
    }
    __init_debug_log("Navigation grid created");
    
    // Step 3: Initialize Search System
    if (!search_system_init()) {
        __init_debug_log("ERROR: Failed to initialize search system");
        return false;
    }
    __init_debug_log("Search system initialized");
    
    // Step 4: Initialize camera system
    initialize_camera_system();
    __init_debug_log("Camera system initialized");
    
    // Step 5: Activate and initialize entities
instance_activate_object(obj_villager_1);
with (obj_villager_1) {
    npc_search_init(id);
}
__init_debug_log("Entities activated and initialized");

return true;
}