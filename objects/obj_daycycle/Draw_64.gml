// Adjust the time of day scale to shift .00 to 5 AM
var shifted_time_of_day = (global.time_of_day + 0.20) % 1;  // Shift time by 0.20 (equivalent to 5 hours)

// Convert to 24-hour time scale
var total_hours = shifted_time_of_day * 24;
global.clock_hours = total_hours;  // Store the total hours as a global variable for others to use

var display_hour = floor(total_hours) % 12;
if (display_hour == 0) display_hour = 12;  // Convert 0 to 12 for AM/PM
var period = (total_hours >= 12) ? "PM" : "AM";

// Store the formatted time in a global variable
global.current_time_display = string(display_hour) + " " + period;

// Draw the time
draw_set_color(c_white);
draw_text(10, 30, "Current Time: " + global.current_time_display);

// Debug time of day
draw_text(10, 10, "Shifted Time of Day: " + string(shifted_time_of_day));
