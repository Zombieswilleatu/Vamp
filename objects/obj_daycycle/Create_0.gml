// Create Event for obj_daycycle
day_length = 600;  // Total time for one day (in seconds)
global.time_of_day =.1;  // Start at the beginning of the cycle
global.current_time_display = "";


// Define colors for different times of day
morning_color = make_color_rgb(255, 223, 186);  // Soft yellow for sunrise
noon_color = make_color_rgb(255, 255, 255);     // True color for midday (no tint)
evening_color = make_color_rgb(255, 160, 100);  // Softer orange for sunset
night_color = make_color_rgb(10, 10, 30);       // Darker blue for night

// Define daylight intensity for midday (True color, no tint)
daylight_intensity = 0;  // Set to 1 for no color alteration during midday

surf = -1;  // Surface for day/night cycle
