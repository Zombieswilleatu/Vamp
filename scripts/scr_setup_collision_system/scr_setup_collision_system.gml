function scr_setup_collision_system() {
    show_debug_message("Setting up collision system...");

    for (var i = 0; i < global.grid.width; i++) {
        for (var j = 0; j < global.grid.height; j++) {
            if (global.navigation_grid[i][j] == 0) { // 0 = unwalkable
                var collision_x = i * global.cell_size;
                var collision_y = j * global.cell_size;

                instance_create_layer(
                    collision_x, collision_y, 
                    "Instances", obj_collision
                );
            }
        }
    }

    show_debug_message("Collision system setup complete.");
}
