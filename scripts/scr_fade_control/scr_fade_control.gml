function scr_fade_control(obj) {
    // Check if global light intensity exists; use a default if not
    var global_intensity;
    if (variable_global_exists("current_light_intensity")) {
        global_intensity = global.current_light_intensity;  // Use global value set by the day/night system
    } else {
        global_intensity = 1;  // Default to full intensity if not set yet
    }

    // Time-based fading logic
    var fade_out_start = 20;  // 7 PM
    var fade_out_end = 22;    // 9 PM
    var fade_in_start = 6;    // 5 AM
    var fade_in_end = 8;      // 7 AM

    var fade_out_duration = fade_out_end - fade_out_start;
    var fade_in_duration = fade_in_end - fade_in_start;

    var clock_hours = global.clock_hours;
    var night_progress;

    if (clock_hours >= fade_out_start && clock_hours < fade_out_end) {
        night_progress = (clock_hours - fade_out_start) / fade_out_duration;
    } else if (clock_hours >= fade_out_end || clock_hours < fade_in_start) {
        night_progress = 1;  // Full night, full fading
    } else if (clock_hours >= fade_in_start && clock_hours < fade_in_end) {
        night_progress = 1 - ((clock_hours - fade_in_start) / fade_in_duration);
    } else {
        night_progress = 0;  // Full visibility during the day
        obj.image_alpha = global_intensity;  // Use global intensity during the day
        return;  // No need to process proximity fading in the daytime
    }

    // Proximity fading logic
    var light_radius = global.night_vision_radius * 1.2;  // Adjusted light radius
    var full_visibility_distance = light_radius * 0.8;    // Full visibility at 80% of the light radius

    // Calculate the distance to the player
    var light_source_x = global.player_x + (obj_player.sprite_width / 2) - obj_player.sprite_xoffset;
    var light_source_y = global.player_y + (obj_player.sprite_height / 2) - obj_player.sprite_yoffset;
    var distance_to_light = point_distance(obj.x, obj.y, light_source_x, light_source_y);

    var proximity_alpha;

    if (distance_to_light < full_visibility_distance) {
        // Fully visible within 80% of the light radius
        proximity_alpha = 1;
    } else if (distance_to_light < light_radius) {
        // Gradual fade between 80% and 100% of the light radius
        var fade_factor = (distance_to_light - full_visibility_distance) / (light_radius - full_visibility_distance);
        proximity_alpha = 1 - fade_factor;  // Fade as the distance increases
    } else {
        // Outside the light radius, fully invisible
        proximity_alpha = 0;
    }

    // Combine time-based and proximity-based fading with global intensity
    var original_alpha = 1 - night_progress;
    obj.image_alpha = max(proximity_alpha, original_alpha) * global_intensity;
    obj.image_alpha = clamp(obj.image_alpha, 0, 1);
}
