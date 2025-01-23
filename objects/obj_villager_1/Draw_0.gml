// Draw Event
draw_self();

// Detection eye drawing function
function draw_detection_eye() {
    var eye_x = x;
    var eye_y = y - 32;
    
    // Calculate eye openness based on detection level
    var eye_openness = 1;
    if (variable_instance_exists(id, "detection_level")) {
        eye_openness = detection_level / 100;
    }
    
    // Determine eye color based on detection state
    var eye_color = c_green;  // Safe by default
    if (variable_instance_exists(id, "fully_detected") && fully_detected) {
        eye_color = c_red;    // Detected
    } else if (variable_instance_exists(id, "detection_level") && detection_level > 0) {
        eye_color = c_yellow; // In process of detecting
    }
    
    // Draw the eye
    draw_set_color(eye_color);
    
    // More dramatic eye using wider ASCII characters
    if (eye_openness < 0.1) {
        // Nearly closed eye
        draw_text(eye_x - 20, eye_y, "━━━⦿━━━");
    } else {
        // Top of eye
        draw_text(eye_x - 20, eye_y - 8, "╭⎯⎯●⎯⎯╮");
        
        // Middle part with pupil
        var pupil = eye_openness > 0.3 ? "◉" : "○";
        draw_text(eye_x - 20, eye_y, "│ " + pupil + " │");
        
        // Bottom of eye
        draw_text(eye_x - 20, eye_y + 8, "╰⎯⎯●⎯⎯╯");
    }
    
    // Draw state and detection info
    if (variable_instance_exists(id, "npc_state") || 
        (variable_instance_exists(id, "detection_level") && detection_level > 0)) {
        
        draw_set_halign(fa_center);
        var state_text = "";
        
        if (variable_instance_exists(id, "npc_state")) {
            state_text = string_upper(npc_state);
        }
        
        if (variable_instance_exists(id, "detection_level") && detection_level > 0) {
            state_text += " " + string(floor(detection_level)) + "%";
        }
        
        // Draw state text with outline for better visibility
        var text_y = eye_y + 20;
        draw_set_color(c_black);
        draw_text(eye_x - 1, text_y, state_text);
        draw_text(eye_x + 1, text_y, state_text);
        draw_text(eye_x, text_y - 1, state_text);
        draw_text(eye_x, text_y + 1, state_text);
        draw_set_color(eye_color);
        draw_text(eye_x, text_y, state_text);
        
        draw_set_halign(fa_left);
    }
}

// Main drawing logic
if (keyboard_check(vk_tab)) {
    // Store original drawing settings
    var original_alpha = draw_get_alpha();
    var original_color = draw_get_color();
    var original_font = draw_get_font();
    var original_halign = draw_get_halign();
    var original_valign = draw_get_valign();

    // Draw detection eye
    draw_detection_eye();

    // Draw debug info box
    var info_x = x + 40;
    var info_y = y - 40;
    draw_set_color(c_black);
    draw_set_alpha(0.8);
    draw_rectangle(info_x, info_y, info_x + 120, info_y + 60, false);
    
    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    
    // Debug info
    var state_text = "State: " + string(variable_instance_exists(id, "npc_state") ? npc_state : "unknown");
    var detect_text = "Detection: " + string(variable_instance_exists(id, "detection_level") ? string(floor(detection_level)) + "%" : "0%");
    var vision_text = "Vision: " + string(variable_instance_exists(id, "vision_angle") ? string(vision_angle) + "°" : "N/A");
    
    draw_text(info_x + 5, info_y + 5, state_text);
    draw_text(info_x + 5, info_y + 25, detect_text);
    draw_text(info_x + 5, info_y + 45, vision_text);

    // Draw current follow path if it exists and is valid
    if (variable_instance_exists(id, "follow_path") && 
        variable_instance_exists(id, "follow_has_valid_path") &&
        follow_has_valid_path && 
        array_length(follow_path) > 0) {
        
        draw_set_color(c_lime);
        draw_set_alpha(0.8);
        
        // Draw path segments
        for (var i = 0; i < array_length(follow_path) - 1; i++) {
            var start_point = follow_path[i];
            var end_point = follow_path[i + 1];
            
            // Draw line segment
            draw_line_width(
                start_point.x, 
                start_point.y, 
                end_point.x, 
                end_point.y, 
                2
            );
        }
        
        // Draw current target waypoint if we have a follow_path_index
        if (variable_instance_exists(id, "follow_path_index") && 
            follow_path_index < array_length(follow_path)) {
            draw_set_color(c_fuchsia);
            var current_point = follow_path[follow_path_index];
            draw_circle(current_point.x, current_point.y, 6, true);
        }
    }

    // Reset drawing settings
    draw_set_alpha(original_alpha);
    draw_set_color(original_color);
    draw_set_font(original_font);
    draw_set_halign(original_halign);
    draw_set_valign(original_valign);
} else {
    // Just draw the detection eye in normal gameplay
    draw_detection_eye();
}