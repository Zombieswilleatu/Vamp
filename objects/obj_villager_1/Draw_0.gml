// Draw Event of obj_villager_1
draw_self(); // Draw the NPC sprite

// Visualize the new pathfinding system when TAB is pressed
if (keyboard_check(vk_tab)) {
    // Draw the current path
    if (variable_instance_exists(id, "current_path") && array_length(current_path) > 1) {
        draw_set_color(c_lime);
        draw_set_alpha(0.8);
        
        // Draw path lines and nodes
        for (var i = 1; i < array_length(current_path); i++) {
            var prev = current_path[i - 1];
            var curr = current_path[i];
            draw_line_width(prev.x, prev.y, curr.x, curr.y, 2); // Connect path points
            draw_circle(curr.x, curr.y, 3, false); // Node points
        }
        
        // Highlight the current target node
        if (current_path_index < array_length(current_path)) {
            draw_set_color(c_yellow);
            var target = current_path[current_path_index];
            draw_circle(target.x, target.y, 5, false);
        }
    }

    // Draw cells from the new navigation grid
    if (variable_global_exists("pathfinding") && 
        variable_global_exists("grid") && 
        global.pathfinding != undefined && 
        array_length(global.pathfinding.nodes) > 0) {
        
        draw_set_color(c_purple);
        draw_set_alpha(0.2);
        
        for (var i = 0; i < global.grid.width; i++) {
            for (var j = 0; j < global.grid.height; j++) {
                if (!global.pathfinding.nodes[i][j].walkable) {
                    var draw_x = i * global.cell_size;
                    var draw_y = j * global.cell_size;
                    draw_rectangle(draw_x, draw_y, draw_x + global.cell_size, draw_y + global.cell_size, true);
                }
            }
        }

        // Debug NPC position in grid
        draw_set_color(c_white);
        draw_set_alpha(1);

        var debug_x = x - 50;
        var debug_y = y - 40;

        var current_grid_x = floor(x / global.cell_size);
        var current_grid_y = floor(y / global.cell_size);

        draw_text(debug_x, debug_y, "Grid Pos: " + string(current_grid_x) + "," + string(current_grid_y));
        draw_text(debug_x, debug_y + 15, "Path Length: " + string(array_length(current_path)));
        if (variable_instance_exists(id, "fallback_mode")) {
            draw_text(debug_x, debug_y + 30, "Mode: " + (fallback_mode ? "Fallback" : "Normal"));
        }
    }
}

// Reset draw properties
draw_set_alpha(1);
draw_set_color(c_white);
