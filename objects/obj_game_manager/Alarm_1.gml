/// Alarm[1] Event
function map_regions_after_init() {
    if (variable_global_exists("path_grid")) {
        show_debug_message("Starting region mapping...");
        global.num_regions = map_room_regions();
        global.regions_initialized = true;  // Set the flag after mapping is complete
        show_debug_message("Region mapping complete. Number of regions: " + string(global.num_regions));
        show_debug_message("Regions initialized flag set to: " + string(global.regions_initialized));
        
        // Notify all existing NPCs to reinitialize their sectors
        with(obj_villager_1) {  // Update this to match your NPC parent object
            var start_sector_x = floor(x / global.sector_size);
            var start_sector_y = floor(y / global.sector_size);
            current_sector = find_nearest_unsearched_sector(start_sector_x, start_sector_y);
            //search_state = "move_to_sector";  // Force state change
            show_debug_message("NPC " + string(id) + " initialized with sector: " + 
                             string(current_sector.x) + "," + string(current_sector.y));
        }
    } else {
        alarm[1] = 1;
        show_debug_message("Waiting for path_grid to be created...");
    }
}