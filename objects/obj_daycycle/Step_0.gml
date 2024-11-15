// Update global variables for night vision
global.night_vision_radius = obj_player.night_vision_radius;
global.player_x = obj_player.x;
global.player_y = obj_player.y;

global.time_of_day += (1 / (room_speed * day_length));  // Increment based on frame rate

if (global.time_of_day >= 1) {
    global.time_of_day = 0;  // Reset after a full cycle
}

// Adjust clock hours based on shifted time of day
var shifted_time_of_day = (global.time_of_day + 0.25) % 1;  // Adjust time by 0.25 to match 5 AM correctly
global.clock_hours = shifted_time_of_day * 24;  // Convert time to hours

// Adjust the day phases as before
if (global.time_of_day < 0.15) {  // Dawn
    current_light_color = lerp_color(night_color, morning_color, global.time_of_day / 0.15);
    current_light_intensity = lerp(0.95, daylight_intensity, global.time_of_day / 0.15);
} else if (global.time_of_day < 0.45) {  // Daytime
    current_light_color = lerp_color(morning_color, noon_color, (global.time_of_day - 0.15) / 0.3);
    current_light_intensity = daylight_intensity;
} else if (global.time_of_day < 0.55) {  // Dusk
    current_light_color = lerp_color(noon_color, evening_color, (global.time_of_day - 0.45) / 0.1);
    current_light_intensity = lerp(daylight_intensity, 0.4, (global.time_of_day - 0.45) / 0.1);
} else if (global.time_of_day < 0.65) {  // Early Night
    current_light_color = lerp_color(evening_color, night_color, (global.time_of_day - 0.55) / 0.1);
    current_light_intensity = lerp(0.4, 0.95, (global.time_of_day - 0.55) / 0.1);
} else {  // Deep Night
    current_light_color = night_color;
    current_light_intensity = 0.95;
}
