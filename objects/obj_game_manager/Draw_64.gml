// Ensure text color and opacity
draw_set_color(c_white);
draw_set_alpha(1);

// Calculate position for top-right corner
var text_width = string_width("FPS: " + string(global.fps)); // Calculate text width
var x_pos = display_get_gui_width() - text_width - 10;       // Right-aligned with 10px padding
var y_pos = 10;                                             // 10px padding from the top

// Draw the FPS text
draw_text(x_pos, y_pos, "FPS: " + string(global.fps));


