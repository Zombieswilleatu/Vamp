// Draw GUI Event
event_inherited();
if (!variable_instance_exists(id, "initialized") || !initialized) exit;

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

// Only include variables that are currently initialized
var debug_info = [
   "State: " + string(npc_state),
   //"Search State: " + string(search_state),
   //"Sector: " + string(current_sector.x) + "," + string(current_sector.y),
   //"Search Points: " + string(array_length(search_points)),
   //"Current Point: " + string(current_search_point),
   "Moving: " + string(is_moving),
   "Path Started: " + string(path_started),
   "Det Level: " + string(detection_level),
   "FPS: " + string(fps_real) // Add the frame rate
];

for (var i = 0; i < array_length(debug_info); i++) {
   draw_text(debug_x + 10, 10 + (i * line_height), debug_info[i]);
}
