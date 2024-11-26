// ESC to quit game
if (keyboard_check_pressed(vk_escape)) {
    game_end();
}

// Increment the frame counter
global.current_frame += 1;

// Get current camera
var cam = view_camera[0];

// Get current camera size and position
var cam_w = camera_get_view_width(cam);
var cam_h = camera_get_view_height(cam);
var cam_x = camera_get_view_x(cam);
var cam_y = camera_get_view_y(cam);

// Zoom in with plus key
if (keyboard_check_pressed(vk_add)) {
    var new_width = cam_w * 0.9;
    var new_height = cam_h * 0.9;
    var new_x = cam_x + (cam_w - new_width) / 2;
    var new_y = cam_y + (cam_h - new_height) / 2;

    camera_set_view_size(cam, new_width, new_height);
    camera_set_view_pos(cam, new_x, new_y);
}

// Zoom out with minus key
if (keyboard_check_pressed(vk_subtract)) {
    var new_width = cam_w * 1.1;
    var new_height = cam_h * 1.1;
    var new_x = cam_x - (new_width - cam_w) / 2;
    var new_y = cam_y - (new_height - cam_h) / 2;

    camera_set_view_size(cam, new_width, new_height);
    camera_set_view_pos(cam, new_x, new_y);
}

// Update FPS using fps_real
global.fps = fps_real;

// Debug FPS Warning
if (fps_real < 60) {
    show_debug_message("FPS Warning: " + string(fps_real) + " at Frame: " + string(global.current_frame));
}
