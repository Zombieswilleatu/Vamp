// obj_daycycle_draw
// Get the camera view dimensions
var view_w = camera_get_view_width(view_camera[0]);
var view_h = camera_get_view_height(view_camera[0]);

// Check if the surface exists, recreate if not or if dimensions have changed
if (!surface_exists(surf) || surface_get_width(surf) != view_w || surface_get_height(surf) != view_h) {
    if (surface_exists(surf)) surface_free(surf);  // Free the old surface
    surf = surface_create(view_w, view_h);
}

// Set the surface target
surface_set_target(surf);
draw_clear_alpha(c_black, 0);  // Clear surface

// Draw the color fade based on the day/night cycle
draw_set_color(current_light_color);
draw_set_alpha(current_light_intensity);  // Using current light intensity to handle day/night cycle
draw_rectangle(0, 0, view_w, view_h, false);

// Set blend mode to subtract for lighting
gpu_set_blendmode(bm_subtract);

// Define light source based on player's position and camera view offset
var light_source_x = global.player_x - camera_get_view_x(view_camera[0]) + (obj_player.sprite_width / 2) - obj_player.sprite_xoffset;
var light_source_y = global.player_y - camera_get_view_y(view_camera[0]) + (obj_player.sprite_height / 2) - obj_player.sprite_yoffset;

// Gradient settings
var light_radius = global.night_vision_radius * 1.2;  // Increase radius by 20%
var num_layers = 6;  // Increase number of layers to 6 (one extra dimmer circle)
var layer_step = light_radius / num_layers;  // Radius step between layers

// Fixed alpha value to ensure the gradient is always visible
var base_alpha = 0.8;  // Set a fixed alpha to ensure consistent visibility of the gradient

// Draw the gradient light circle
for (var i = 0; i < num_layers; i++) {
    var current_alpha = base_alpha * ((num_layers - i) / num_layers);  // Alpha decreases towards the edges
    var current_radius = light_radius - (i * layer_step);  // Smaller radius as layers get closer to the center
    
    draw_set_alpha(current_alpha);
    draw_set_color(c_white);
    draw_circle(light_source_x, light_source_y, current_radius, false);
}

// Reset blend mode and alpha
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);

// Reset the surface
surface_reset_target();

// Draw the surface at the camera view position
draw_surface(surf, camera_get_view_x(view_camera[0]), camera_get_view_y(view_camera[0]));
