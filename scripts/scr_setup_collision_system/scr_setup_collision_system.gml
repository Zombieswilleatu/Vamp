function scr_setup_collision_system() {
    show_debug_message("=== Starting Collision System Setup ===");

    // Define cell size constant if not already defined
    if (!variable_global_exists("CELL_SIZE")) {
        global.CELL_SIZE = 32;
    }

    // Check nav_grid
    if (!variable_global_exists("nav_grid")) {
        show_debug_message("ERROR: global.nav_grid is not set!");
        return;
    }

    var width = ds_grid_width(global.nav_grid);
    var height = ds_grid_height(global.nav_grid);

    // Clean up any existing collision objects
    with(obj_collision) {
        instance_destroy();
    }

    // Store collision constants if not already defined
    if (!variable_global_exists("COLLISION_NONE")) {
        global.COLLISION_NONE = 0;
        global.COLLISION_SOLID = 1;
        global.COLLISION_ENTITY = 2;
    }

    // Create or clear collision grid
    if (!variable_global_exists("collision_grid")) {
        global.collision_grid = ds_grid_create(width, height);
    } else {
        ds_grid_clear(global.collision_grid, 0);
    }

    // Create collision objects based on nav_grid values
    for (var i = 0; i < width; i++) {
        for (var j = 0; j < height; j++) {
            var nav_value = ds_grid_get(global.nav_grid, i, j);
            var collision_value = 0;
            
            switch(nav_value) {
                case global.UNWALKABLE:
                    collision_value = global.COLLISION_SOLID;
                    var inst = instance_create_layer(
                        i * global.CELL_SIZE, 
                        j * global.CELL_SIZE, 
                        "Tile_unwalkable", 
                        obj_collision
                    );
                    if (inst != noone) {
                        with(inst) {
                            solid = true;
                            visible = false;
                        }
                    }
                    break;
                    
                case global.ENTITY_PRESENT:
                    collision_value = global.COLLISION_ENTITY;
                    break;
                    
                case global.WALKABLE:
                    collision_value = global.COLLISION_NONE;
                    break;
            }
            
            ds_grid_set(global.collision_grid, i, j, collision_value);
        }
    }

    show_debug_message("=== Collision System Setup Complete ===");
}

// Helper function to check if a point is within the grid
function point_in_grid(grid_x, grid_y) {
    if (!variable_global_exists("collision_grid")) return false;
    
    var width = ds_grid_width(global.collision_grid);
    var height = ds_grid_height(global.collision_grid);
    
    return (grid_x >= 0 && grid_x < width && grid_y >= 0 && grid_y < height);
}

// Helper function to dump collision grid state if needed for debugging
function debug_dump_collision_grid() {
    if (!variable_global_exists("collision_grid")) {
        show_debug_message("ERROR: Collision grid doesn't exist!");
        return;
    }

    var width = ds_grid_width(global.collision_grid);
    var height = ds_grid_height(global.collision_grid);
    var grid_string = "Collision Grid State:\n";

    for (var j = 0; j < height; j++) {
        var row = "";
        for (var i = 0; i < width; i++) {
            row += string(ds_grid_get(global.collision_grid, i, j));
        }
        grid_string += row + "\n";
    }

    show_debug_message(grid_string);
}