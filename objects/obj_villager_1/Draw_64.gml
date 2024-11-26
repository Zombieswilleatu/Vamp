// Draw GUI Event
event_inherited();

if (!variable_instance_exists(id, "init_complete") || !init_complete) {
    exit;
}

var gui_width = display_get_gui_width();
var debug_x = gui_width - 200; // Increased from 150
var line_height = 15;

// Background
draw_set_color(c_black);
draw_set_alpha(0.7);
draw_rectangle(debug_x, 0, gui_width - 10, 145, false); // Adjust height as needed

// Text
draw_set_color(c_white);
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// Gather debug information dynamically
var debug_info = [
    "State: " + string(npc_state),
    "Path Length: " + string(array_length(current_path)),
    "Current Path Index: " + string(current_path_index),
    "Position: " + string(x) + ", " + string(y),
    "Facing: " + facing_direction,
    "FPS: " + string(fps_real), // Frame rate
    "Grid Initialized: " + string(global.grid.initialized),
    "Walkable: " + string(global.pathfinding.nodes[floor(x / global.cell_size)][floor(y / global.cell_size)].walkable)
];

// Display the debug information
for (var i = 0; i < array_length(debug_info); i++) {
    draw_text(debug_x + 10, 10 + (i * line_height), debug_info[i]);
}
