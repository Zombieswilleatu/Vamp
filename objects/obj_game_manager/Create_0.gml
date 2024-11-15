function initialize_game_systems() {
    show_debug_message("Starting game initialization...");
    
    window_set_fullscreen(true);

    global.cell_size = 32;
    global.sector_size = 128;
    global.failed_sectors = [];
    
    global.grid = {
        initialized: false,
        width: 0,
        height: 0
    };
    
    global.global_searched_sectors = ds_grid_create(
        ceil(room_width / global.sector_size),
        ceil(room_height / global.sector_size)
    );
    ds_grid_clear(global.global_searched_sectors, false);
    
    var tilemap_id = layer_tilemap_get_id("Tile_unwalkable");
    if (tilemap_id != -1) {
        show_debug_message("Tilemap 'Tile_unwalkable' found.");
        global.astar_grid = create_astar_grid(tilemap_id);
        
        if (global.astar_grid != undefined && array_length(global.astar_grid) > 0) {
            global.grid.width = array_length(global.astar_grid);
            global.grid.height = array_length(global.astar_grid[0]);
            show_debug_message("A* grid created: " + string(global.grid.width) + " x " + string(global.grid.height));
            
            global.path_grid = mp_grid_create(0, 0, global.grid.width * 2, global.grid.height * 2, global.cell_size / 2, global.cell_size / 2);
            
            var buffer_size = 8;
            
            for (var i = 0; i < global.grid.width; i++) {
                for (var j = 0; j < global.grid.height; j++) {
                    if (global.astar_grid[i][j] == 1) {
                        var collision_obj = instance_create_layer(
                            i * global.cell_size,
                            j * global.cell_size,
                            "Instances",
                            obj_collision
                        );
                        
                        with(collision_obj) {
                            image_xscale = 1;
                            image_yscale = 1;
                            visible = true;
                        }
                        
                        var x1 = max(0, i * global.cell_size - buffer_size);
                        var y1 = max(0, j * global.cell_size - buffer_size);
                        var x2 = min(room_width, (i + 1) * global.cell_size + buffer_size);
                        var y2 = min(room_height, (j + 1) * global.cell_size + buffer_size);
                        
                        mp_grid_add_rectangle(global.path_grid, x1, y1, x2, y2);
                    }
                }
            }
            
            global.collision_grid = ds_grid_create(global.grid.width, global.grid.height);
            with(obj_collision) {
                var grid_x = x div global.cell_size;
                var grid_y = y div global.cell_size;
                ds_grid_set(global.collision_grid, grid_x, grid_y, id);
            }
            
            global.grid.initialized = true;
        }
    } else {
        show_debug_message("ERROR: Tilemap 'Tile_unwalkable' not found.");
        global.astar_grid = [];
    }

    initialize_camera_system();
    instance_deactivate_object(obj_villager_1);

    create_zone_weights();
    
    show_debug_message("Game initialization complete!");
    show_debug_message("- Room size: " + string(room_width) + "x" + string(room_height));
    show_debug_message("- Grid size: " + string(global.grid.width) + "x" + string(global.grid.height));
    show_debug_message("- Collision objects: " + string(instance_number(obj_collision)));

    alarm[0] = 1;
}

function create_zone_weights() {
    global.zone_maps = [];
    
    for(var map_index = 0; map_index < 5; map_index++) {
        var weight_map = array_create(global.grid.width);
        for(var i = 0; i < global.grid.width; i++) {
            weight_map[i] = array_create(global.grid.height, 1.0);
        }
        
        var num_zones = irandom_range(3, 5);
        for(var z = 0; z < num_zones; z++) {
            var center_x = irandom(global.grid.width);
            var center_y = irandom(global.grid.height);
            var radius = irandom_range(5, 15);
            var weight = random_range(0.2, 3.0);
            
            for(var i = -radius; i <= radius; i++) {
                for(var j = -radius; j <= radius; j++) {
                    var check_x = center_x + i;
                    var check_y = center_y + j;
                    
                    if(check_x >= 0 && check_x < global.grid.width && 
                       check_y >= 0 && check_y < global.grid.height) {
                        var dist = point_distance(center_x, center_y, check_x, check_y);
                        if(dist <= radius) {
                            var fade = 1 - (dist / radius);
                            weight_map[check_x][check_y] *= 1 + (weight - 1) * fade;
                        }
                    }
                }
            }
        }
        
        array_push(global.zone_maps, weight_map);
    }
}

initialize_game_systems();

if (!variable_global_exists("frame_counter")) {
    global.frame_counter = 0;
}