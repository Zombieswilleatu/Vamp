// Alarm[1] - Assign Next Search Area
if (state == "search") {
    // Initialize search_state if needed
    if (!variable_instance_exists(self, "search_state")) {
        npc_search_init(id);
        show_debug_message("Entity " + string(id) + " search_state initialized in Alarm[1]");
    }
   
    // Assign new area if no current area
    if (!is_struct(search_state.current_area)) {
        show_debug_message("Finding next search area for entity: " + string(id));
        var found_area = find_next_search_area(self);
        
        if (is_struct(found_area)) {
            search_state.current_area = found_area;
            show_debug_message("Alarm[1] - Assigned new area: (" +
                string(search_state.current_area.x) + "," + 
                string(search_state.current_area.y) + ")"
            );
        } else {
            show_debug_message("Alarm[1] - No unsearched areas found for entity: " + string(id));
            var grid_pos = world_to_grid(self.x, self.y);
            mark_area_searched(
                grid_pos.x,
                grid_pos.y,
                self.search_state.radius
            );
        }
    }
   
    // Reset alarm
    alarm[1] = 10;
}