// Draw Event of obj_villager_1

draw_self(); // Draw the NPC sprite

// Visualize the path and unwalkable tiles when TAB is pressed
if (keyboard_check(vk_tab)) {
    // Draw the path
    if (variable_instance_exists(id, "path_points") && array_length(path_points) > 1) {
        draw_set_color(c_aqua);
        draw_set_alpha(0.8);
        for (var i = 0; i < array_length(path_points) - 1; i++) {
            var point_current = path_points[i];
            var point_next = path_points[i + 1];
            draw_line_width(point_current.x, point_current.y, point_next.x, point_next.y, 2);
        }
        draw_set_alpha(1);
        draw_set_color(c_white);
    }

    // Draw only unwalkable (blocked) cells
    var cell_count_x = ceil(room_width / global.cell_size);
    var cell_count_y = ceil(room_height / global.cell_size);

    draw_set_color(c_red);
    for (var cell_x = 0; cell_x < cell_count_x; cell_x++) {
        for (var cell_y = 0; cell_y < cell_count_y; cell_y++) {
            // Check if the cell is blocked
            if (mp_grid_get_cell(global.path_grid, cell_x, cell_y) == 1) {
                var draw_x = cell_x * global.cell_size;
                var draw_y = cell_y * global.cell_size;
                draw_rectangle(draw_x, draw_y, draw_x + global.cell_size, draw_y + global.cell_size, false);
            }
        }
    }

    // Reset drawing settings
    draw_set_alpha(1);
    draw_set_color(c_white);
}
