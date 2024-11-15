// NPC_Init.gml - Place this in a script file

function try_complete_initialization() {
    // Ensure CELL_SIZE is defined
    var CELL_SIZE = global.cell_size; // Assuming global.cell_size is defined and matches the path grid

    // Safety check for path grid
    if (!variable_global_exists("path_grid") || !global.path_grid) {
        show_debug_message("Path grid still not ready. Will retry...");
        
        // Increment retry count
        if (!variable_instance_exists(id, "init_retry_count")) {
            init_retry_count = 0;
        }
        init_retry_count++;
        
        // Check if maximum retry limit is reached
        if (init_retry_count >= 10) {
            show_error("Failed to initialize NPC after 10 retries. Path grid not ready.", true);
            return false;
        }
        
        alarm[0] = 1;
        return false;
    }
    
    // If already initialized, don't do it again
    if (is_fully_initialized) {
        return true;
    }
    
    show_debug_message("Attempting to complete NPC initialization...");
    
    // Convert current position to grid coordinates
    var grid_x = floor(x / CELL_SIZE);
    var grid_y = floor(y / CELL_SIZE);
    
    // Debug messages
    show_debug_message("Current grid position: (" + string(grid_x) + ", " + string(grid_y) + ")");

    // Check for valid position
    try {
        if (mp_grid_get_cell(global.path_grid, grid_x, grid_y)) {
            show_debug_message("Invalid starting position. Finding new position...");
            if (!find_valid_position(grid_x, grid_y, CELL_SIZE)) {
                alarm[0] = 1;
                return false;
            }
        }
    } catch(error) {
        show_debug_message("Grid check failed. Will retry initialization...");
        alarm[0] = 1;
        return false;
    }
    
    // Additional collision check after position adjustment
    if (place_meeting(x, y, obj_collision)) {
        show_debug_message("Adjusted position overlaps with a wall. Finding new position...");
        if (!find_valid_position(grid_x, grid_y, CELL_SIZE)) {
            alarm[0] = 1;
            return false;
        }
    }
    
    // Mark initialization as successful
    is_fully_initialized = true;
    show_debug_message("NPC initialized at position: (" + string(x) + ", " + string(y) + ")");
    return true;
}
