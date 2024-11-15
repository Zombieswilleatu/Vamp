function draw_npc_debug_gui() {
    // Save old drawing settings
    var old_color = draw_get_color();
    var old_alpha = draw_get_alpha();
    var old_halign = draw_get_halign();
    var old_valign = draw_get_valign();
    
    // Set up text properties
    draw_set_font(-1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(1);
    
    var padding = 5;
    var line_height = 15;
    var y_pos = 10;
    var margin_from_edge = 10;
    var x_pos = display_get_gui_width() - 200 - margin_from_edge;
    var text_color = c_white;
    var background_alpha = 0.7;
    
    // Create the debug text
    var debug_text = "";
    debug_text += "NPC ID: " + string(id) + "\n";
    debug_text += "Main State: " + string(npc_state) + "\n";
    debug_text += "Search State: " + string(search_state) + "\n";
    debug_text += "Detection Level: " + string(floor(detection_level)) + "%\n";
    debug_text += "Can See Player: " + (can_see_player ? "Yes" : "No") + "\n";
    debug_text += "Can Detect Player: " + (can_detect_player ? "Yes" : "No") + "\n";
    debug_text += "Frame Rate: " + string(fps_real) + " FPS\n";

    // Add state-specific information
    switch(search_state) {
        case "move_to_sector":
            debug_text += "Current Sector: " + string(current_sector.x) + "," + string(current_sector.y) + "\n";
            debug_text += "Moving to new sector\n";
            break;
            
        case "search_sector":
            debug_text += "Current Sector: " + string(current_sector.x) + "," + string(current_sector.y) + "\n";
            if (array_length(search_points) > 0) {
                debug_text += "Search Point: " + string(current_search_point + 1) + "/" + 
                             string(array_length(search_points)) + "\n";
            }
            debug_text += "Wait Timer: " + string(ceil(wait_timer / room_speed)) + "s\n";
            break;
            
        case "investigate":
            debug_text += "Investigation Timer: " + 
                         string(ceil((investigate_duration - investigate_timer) / room_speed)) + "s\n";
            break;
    }
    
    // Calculate background rectangle size
    var text_width = string_width(debug_text);
    var text_height = string_height(debug_text);
    
    // Draw background
    draw_set_alpha(background_alpha);
    draw_set_color(c_black);
    draw_rectangle(x_pos - padding, 
                  y_pos - padding, 
                  x_pos + text_width + padding, 
                  y_pos + text_height + padding, 
                  false);
    
    // Draw text
    draw_set_alpha(1);
    draw_set_color(c_yellow);
    draw_text(x_pos, y_pos, debug_text);
    
    // Restore old drawing settings
    draw_set_color(old_color);
    draw_set_alpha(old_alpha);
    draw_set_halign(old_halign);
    draw_set_valign(old_valign);
}