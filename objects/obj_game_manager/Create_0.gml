// Create Event of obj_game_manager

function initialize_game_systems() {
    show_debug_message("Starting game initialization...");
    window_set_fullscreen(true);

    // Initialize global variables safely
    if (!variable_global_exists("current_frame")) {
        global.current_frame = 0; // Frame counter
    }
    if (!variable_global_exists("PATH_UPDATE_INTERVAL")) {
        global.PATH_UPDATE_INTERVAL = 30; // Path update interval
    }
    if (!variable_global_exists("fps")) {
        global.fps = 0; // Frames per second tracker
    }

    // Initialize global grid
    if (!variable_global_exists("grid")) {
        show_debug_message("Creating new grid global variable");
        global.grid = {
            initialized: false,
            width: 0,
            height: 0
        };
    }

    show_debug_message("Grid initialization state: " + string(global.grid.initialized));

    // Global variables for navigation
    global.cell_size = 32;
    global.sector_size = 128;
    global.failed_sectors = [];
    global.global_searched_sectors = ds_grid_create(
        ceil(room_width / global.sector_size),
        ceil(room_height / global.sector_size)
    );
    ds_grid_clear(global.global_searched_sectors, false);

    // Navigation grid setup
    var tilemap_id = layer_tilemap_get_id("Tile_unwalkable");
    if (tilemap_id != -1) {
        show_debug_message("Tilemap 'Tile_unwalkable' found.");
        global.navigation_grid = create_navigation_grid(tilemap_id);

        if (global.navigation_grid != undefined && array_length(global.navigation_grid) > 0) {
            global.grid.width = array_length(global.navigation_grid);
            global.grid.height = array_length(global.navigation_grid[0]);
            show_debug_message("Navigation grid created: " + string(global.grid.width) + " x " + string(global.grid.height));

            // Initialize pathfinding system
            scr_initialize_pathfinding();

            create_zone_weights();
            show_debug_message("Zone weights created");

            global.grid.initialized = true;
        }
    } else {
        show_debug_message("ERROR: Tilemap 'Tile_unwalkable' not found.");
        global.navigation_grid = [];
    }

    initialize_camera_system();
    instance_deactivate_object(obj_villager_1);
    show_debug_message("Game initialization complete!");

    alarm[0] = 1; // Initial timer setup
}

function create_navigation_grid(tilemap_id) {
    var tilemap_width = tilemap_get_width(tilemap_id);
    var tilemap_height = tilemap_get_height(tilemap_id);
    var nav_grid = array_create(tilemap_width);

    for (var i = 0; i < tilemap_width; i++) {
        nav_grid[i] = array_create(tilemap_height);
        for (var j = 0; j < tilemap_height; j++) {
            var tile_data = tilemap_get(tilemap_id, i, j);
            if (tile_data != 0) {
                // Tile exists (unwalkable)
                nav_grid[i][j] = 0;
            } else {
                // No tile (walkable)
                nav_grid[i][j] = 1;
            }
        }
    }
    return nav_grid;
}

function create_zone_weights() {
    global.zone_maps = [];
    for (var map_index = 0; map_index < 5; map_index++) {
        var weight_map = array_create(global.grid.width);
        for (var i = 0; i < global.grid.width; i++) {
            weight_map[i] = array_create(global.grid.height, 1.0);
        }
        array_push(global.zone_maps, weight_map);
    }
}

initialize_game_systems();

if (!variable_global_exists("fps")) {
    global.fps = 0;
}
