// Create a new script asset called "scr_camera_system"

function initialize_camera_system() {
    // Camera zoom variables
    global.camera_zoom = 1.0;
    global.target_zoom = 1.0;
    global.min_zoom = 0.5;
    global.max_zoom = 2.0;
    global.zoom_speed = 0.1;
    global.zoom_increment = 0.1;
    
    // Get the camera
    global.camera = view_camera[0];
    
    // Store base dimensions
    if (view_enabled && view_visible[0]) {
        global.base_width = camera_get_view_width(global.camera);
        global.base_height = camera_get_view_height(global.camera);
        show_debug_message("Camera initialized with dimensions: " + 
                          string(global.base_width) + "x" + 
                          string(global.base_height));
    } else {
        // Enable the view if it's not already enabled
        view_enabled = true;
        view_visible[0] = true;
        
        // Set initial camera properties
        global.base_width = room_width/2;
        global.base_height = room_height/2;
        
        camera_set_view_size(global.camera, global.base_width, global.base_height);
        camera_set_view_pos(global.camera, 
                          room_width/2 - global.base_width/2,
                          room_height/2 - global.base_height/2);
                          
        show_debug_message("View enabled and camera initialized with default dimensions");
    }
    
    show_debug_message("Camera system initialization successful");
}

function update_camera_zoom() {
    // Zoom controls (plus and minus keys)
    if (keyboard_check_pressed(vk_add) || keyboard_check_pressed(187)) {
        global.target_zoom = min(global.target_zoom + global.zoom_increment, global.max_zoom);
    }
    if (keyboard_check_pressed(vk_subtract) || keyboard_check_pressed(189)) {
        global.target_zoom = max(global.target_zoom - global.zoom_increment, global.min_zoom);
    }
    
    // Smooth zoom transition
    if (global.camera_zoom != global.target_zoom) {
        global.camera_zoom = lerp(global.camera_zoom, global.target_zoom, global.zoom_speed);
        
        // Get current camera position
        var cam_x = camera_get_view_x(global.camera);
        var cam_y = camera_get_view_y(global.camera);
        
        // Calculate new dimensions
        var new_width = global.base_width / global.camera_zoom;
        var new_height = global.base_height / global.camera_zoom;
        
        // Get current center point
        var center_x = cam_x + camera_get_view_width(global.camera) / 2;
        var center_y = cam_y + camera_get_view_height(global.camera) / 2;
        
        // Calculate new camera position (keeping the same center point)
        var new_x = center_x - new_width / 2;
        var new_y = center_y - new_height / 2;
        
        // Update camera
        camera_set_view_size(global.camera, new_width, new_height);
        camera_set_view_pos(global.camera, new_x, new_y);
    }
}