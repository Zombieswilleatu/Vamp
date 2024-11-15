/// Alarm[1] - Check for region initialization
// This alarm handles the region initialization check

// Temporarily comment out or remove search-related code
/*
if (search_state == "waiting_for_regions") {
    if (variable_global_exists("regions_initialized") && global.regions_initialized) {
        show_debug_message("NPC " + string(id) + " detected regions initialized, preparing to move");
        
        var start_sector_x = floor(x / global.sector_size);
        var start_sector_y = floor(y / global.sector_size);
        current_sector = find_nearest_unsearched_sector(start_sector_x, start_sector_y);
        search_state = "move_to_sector";
    } else {
        // Check again in a moment
        alarm[1] = 10;
    }
}
*/

show_debug_message("Alarm[1] executed but search-related functionality is disabled.");
