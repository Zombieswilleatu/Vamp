function create_search_variables() {
    // Wait for sector grids to be initialized before proceeding
    if (!global.sectors_initialized) {
        show_debug_message("Sectors not initialized yet; retrying NPC search setup in a moment.");
        alarm[0] = 15;
        return;
    }

    if (!variable_instance_exists(id, "x") || !variable_instance_exists(id, "y")) {
        show_debug_message("Warning: Cannot initialize search - position not set");
        return;
    }

    // Initialize position variables
    npc_x = x;
    npc_y = y;
    
    // Search state variables
    search_state = "move_to_sector";
    current_sector = { x: 0, y: 0 };
    search_points = [];
    current_search_point = 0;
    point_spacing = global.cell_size;
    
    // Pathfinding timers and intervals
    pathfinding_timer = 0;
    pathfinding_check_interval = room_speed / 4;  // Check 4 times per second
    
	stuck_timeout = room_speed * 2;  // Define this first so it's available immediately
    stuck_timer = 0;
    max_stuck_attempts = 3;
    current_stuck_attempts = 0;

    // Wait for sector grids to be initialized before proceeding
    if (!global.sectors_initialized) {
        show_debug_message("Sectors not initialized yet; retrying NPC search setup in a moment.");
        alarm[0] = 15;
        return;
    }

    if (!variable_instance_exists(id, "x") || !variable_instance_exists(id, "y")) {
        show_debug_message("Warning: Cannot initialize search - position not set");
        return;
    }
    // Timer variables
    wait_timer = 0;
    wait_duration = room_speed * 0.5;
    clear_message_timer = 0;
    clear_message_duration = room_speed * 1.5;
    clear_message_scale = 1;
    clear_message_alpha = 1;
    clear_message_y_offset = 0;
    clear_message_initial_scale = 1.5;
    clear_message_rise_speed = 0.5;

    // Investigation variables
    investigate_x = 0;
    investigate_y = 0;
    investigate_timer = 0;
    investigate_duration = room_speed * 5;
    last_known_player_x = 0;
    last_known_player_y = 0;
    thorough_search_radius = global.cell_size * 2;

    // Path and movement variables
    path_started = false;
    current_path_index = 0;
    is_moving = false;
    
    // Detection variables
    can_see_player = false;
    can_detect_player = false;
    detection_level = 0;

    // Group behavior variables
    separation_radius = global.cell_size;
    separation_force = 0.15;

    // Initialize fallback state
    current_fallback = {
        active: false,
        x: 0,
        y: 0,
        attempts: 0,
        max_attempts: 3
    };

    // Initialize path
    if (!variable_instance_exists(id, "my_path")) {
        my_path = path_add();
    } else if (path_exists(my_path)) {
        path_clear_points(my_path);
    }

    // Initialize starting sector with boundary checks
    var start_sector_x = clamp(floor(npc_x / global.sector_size), 0, floor(room_width / global.sector_size) - 1);
    var start_sector_y = clamp(floor(npc_y / global.sector_size), 0, floor(room_height / global.sector_size) - 1);
    current_sector = find_nearest_unsearched_sector(start_sector_x, start_sector_y);

    // Debug output
    show_debug_message("Search system initialized for NPC " + string(id));
    show_debug_message("Starting sector: " + string(current_sector.x) + "," + string(current_sector.y));
}

function ensure_search_variables() {
    if (!variable_instance_exists(id, "search_state")) {
        create_search_variables();
        return false;
    }
    
    // Ensure fallback state exists
    if (!variable_instance_exists(id, "current_fallback")) {
        current_fallback = {
            active: false,
            x: 0,
            y: 0,
            attempts: 0,
            max_attempts: 3
        };
    }
    
    // Ensure stuck variables exist
    if (!variable_instance_exists(id, "stuck_timer")) {
        stuck_timer = 0;
        stuck_timeout = room_speed * 2;
        max_stuck_attempts = 3;
        current_stuck_attempts = 0;
    }
    
    // Ensure path exists
    if (!variable_instance_exists(id, "my_path") || !path_exists(my_path)) {
        my_path = path_add();
    }
    
    return true;
}
function log_grid_state() {
    show_debug_message("Logging current grid state:");
    for (var i = 0; i < ds_grid_width(global.path_grid); i++) {
        var row_state = "";
        for (var j = 0; j < ds_grid_height(global.path_grid); j++) {
            row_state += string(ds_grid_get(global.path_grid, i, j)) + " ";
        }
        show_debug_message("Row " + string(i) + ": " + row_state);
    }
}

// Replace the validate_position function
function validate_position(x, y) {
    // First check room bounds
    if (x < 0 || x >= room_width || y < 0 || y >= room_height) {
        return false;
    }
    
    // Convert to path grid coordinates (accounting for double resolution)
    // The path grid was created with dimensions: grid_width * 2, grid_height * 2
    var grid_width = ceil(room_width / (global.cell_size / 2));
    var grid_height = ceil(room_height / (global.cell_size / 2));
    
    var grid_x = floor(x / (global.cell_size / 2));
    var grid_y = floor(y / (global.cell_size / 2));
    
    // Check grid bounds
    if (grid_x < 0 || grid_x >= grid_width || 
        grid_y < 0 || grid_y >= grid_height) {
        return false;
    }
    
    // Check if position is walkable
    return !mp_grid_get_cell(global.path_grid, grid_x, grid_y);
}

// Helper function to get path grid dimensions
function get_path_grid_dimensions() {
    return {
        width: ceil(room_width / (global.cell_size / 2)),
        height: ceil(room_height / (global.cell_size / 2))
    };
}

// Helper function to convert world coordinates to grid coordinates
function world_to_grid(x, y) {
    return {
        x: floor(x / (global.cell_size / 2)),
        y: floor(y / (global.cell_size / 2))
    };
}

// Helper function to convert grid coordinates to world coordinates
function grid_to_world(grid_x, grid_y) {
    return {
        x: grid_x * (global.cell_size / 2) + (global.cell_size / 4),
        y: grid_y * (global.cell_size / 2) + (global.cell_size / 4)
    };
}

// Core pathfinding update
function update_pathfinding() {
    pathfinding_timer--;
    if (pathfinding_timer <= 0) {
        pathfinding_timer = pathfinding_check_interval;

        var target_x, target_y;
        
        // Get current target based on state
        if (search_state == "move_to_sector") {
            if (current_fallback.active) {
                target_x = current_fallback.x;
                target_y = current_fallback.y;
            } else {
                target_x = current_sector.x * global.sector_size + global.sector_size / 2;
                target_y = current_sector.y * global.sector_size / 2;
            }
            show_debug_message("Moving to sector target: " + string(target_x) + "," + string(target_y));
        } else if (search_state == "search_sector" && array_length(search_points) > 0) {
            if (current_search_point >= array_length(search_points)) {
                complete_sector_search();
                return;
            }
            target_x = search_points[current_search_point].x;
            target_y = search_points[current_search_point].y;
            show_debug_message("Moving to search point: " + string(target_x) + "," + string(target_y));
        } else {
            //show_debug_message("No valid target found");
            return;
        }

        // Attempt to find path to target
        attempt_pathfinding(target_x, target_y);
    }
}

// Helper function to copy an mp_grid
function copy_mp_grid(source_grid, dest_grid) {
    var dimensions = get_path_grid_dimensions();
    
    for (var ix = 0; ix < dimensions.width; ix++) {
        for (var iy = 0; iy < dimensions.height; iy++) {
            if (mp_grid_get_cell(source_grid, ix, iy)) {
                mp_grid_add_cell(dest_grid, ix, iy);
            }
        }
    }
}

function attempt_pathfinding(target_x, target_y) {
    var buffer_size = global.cell_size;
    var grid_dimensions = get_path_grid_dimensions();
    
    // Create temporary path grid
    var temp_grid = mp_grid_create(
        0, 0, 
        grid_dimensions.width,
        grid_dimensions.height,
        global.cell_size / 2, 
        global.cell_size / 2
    );
    
    // Manually copy grid cells
    copy_mp_grid(global.path_grid, temp_grid);
    
    // Clear existing path
    if (path_exists(my_path)) {
        path_clear_points(my_path);
    } else {
        my_path = path_add();
    }
    
    // Try direct path first
    var path_found = try_path_with_validation(temp_grid, my_path, x, y, target_x, target_y, buffer_size);

    if (!path_found) {
        show_debug_message("Direct path failed, attempting fallback paths");
        path_found = attempt_fallback_paths(temp_grid, target_x, target_y, buffer_size);
    }

    if (path_found) {
        current_path_index = 0;
        path_started = true;
        current_fallback.active = false;
        stuck_timer = 0;
        show_debug_message("Path found to target location");
    } else {
        show_debug_message("Failed to find any valid path");
        handle_failed_pathfinding();
    }

    mp_grid_destroy(temp_grid);
}

function attempt_fallback_paths(temp_grid, target_x, target_y, buffer_size) {
    var fallback_distances = [global.cell_size, global.cell_size * 2, global.cell_size * 4];
    var angles_per_distance = 8;  // Try 8 directions at each distance
    
    for (var d = 0; d < array_length(fallback_distances); d++) {
        var distance = fallback_distances[d];
        
        for (var i = 0; i < angles_per_distance; i++) {
            var angle = (360 / angles_per_distance) * i;
            var fallback_x = target_x + lengthdir_x(distance, angle);
            var fallback_y = target_y + lengthdir_y(distance, angle);
            
            // Ensure fallback point is within bounds
            fallback_x = clamp(fallback_x, buffer_size, room_width - buffer_size);
            fallback_y = clamp(fallback_y, buffer_size, room_height - buffer_size);
            
            if (validate_position(fallback_x, fallback_y)) {  // First check if position is valid
                if (try_path_with_validation(temp_grid, my_path, x, y, fallback_x, fallback_y, buffer_size)) {
                    current_fallback.active = true;
                    current_fallback.x = fallback_x;
                    current_fallback.y = fallback_y;
                    show_debug_message("Found valid fallback path at: " + string(fallback_x) + "," + string(fallback_y));
                    return true;
                }
            }
        }
    }
    
    return false;
}

function try_path_with_validation(grid, path, start_x, start_y, end_x, end_y, buffer_size) {
    // Validate and adjust coordinates
    start_x = clamp(start_x, buffer_size, room_width - buffer_size);
    start_y = clamp(start_y, buffer_size, room_height - buffer_size);
    end_x = clamp(end_x, buffer_size, room_width - buffer_size);
    end_y = clamp(end_y, buffer_size, room_height - buffer_size);
    
    // First check if either point is in collision
    if (place_meeting(start_x, start_y, obj_collision) || place_meeting(end_x, end_y, obj_collision)) {
        show_debug_message("Path endpoints in collision");
        return false;
    }

    // Attempt to create path
    if (!mp_grid_path(grid, path, start_x, start_y, end_x, end_y, true)) {
        show_debug_message("Failed to generate path");
        return false;
    }

    // Validate path points with more granular checks
    var path_length = path_get_number(path);
    var prev_x = start_x;
    var prev_y = start_y;
    
    for (var i = 1; i < path_length; i++) {
        var check_x = path_get_point_x(path, i);
        var check_y = path_get_point_y(path, i);
        
        // Check for collisions along the line between points
        var steps = 4; // Check multiple points along the line
        for(var j = 0; j <= steps; j++) {
            var fraction = j / steps;
            var test_x = lerp(prev_x, check_x, fraction);
            var test_y = lerp(prev_y, check_y, fraction);
            
            if (place_meeting(test_x, test_y, obj_collision)) {
                show_debug_message("Path intersects with collision at: " + string(test_x) + "," + string(test_y));
                return false;
            }
        }
        
        prev_x = check_x;
        prev_y = check_y;
    }

    show_debug_message("Path fully validated to endpoint: " + string(end_x) + "," + string(end_y));
    return true;
}

// Helper function to check if a point is within the path grid
function is_within_path_grid(grid_x, grid_y) {
    var dimensions = get_path_grid_dimensions();
    return (grid_x >= 0 && grid_x < dimensions.width && 
            grid_y >= 0 && grid_y < dimensions.height);
}

// Helper function to convert a world position to path grid cell
function get_path_grid_cell(x, y) {
    return {
        x: floor(x / (global.cell_size / 2)),
        y: floor(y / (global.cell_size / 2))
    };
}

function follow_path() {
    if (!path_started || !path_exists(my_path)) {
        is_moving = false;
        return;
    }
    
    if (current_path_index >= path_get_number(my_path)) {
        path_started = false;
        is_moving = false;
        return;
    }

    var path_x = path_get_point_x(my_path, current_path_index);
    var path_y = path_get_point_y(my_path, current_path_index);
    
    var dist_to_point = point_distance(x, y, path_x, path_y);
    
    // Handle point reaching
    if (dist_to_point < global.cell_size / 8) {  // More precise movement threshold
        current_path_index++;
        
        if (current_path_index >= path_get_number(my_path)) {
            path_started = false;
            is_moving = false;
            return;
        }
        
        path_x = path_get_point_x(my_path, current_path_index);
        path_y = path_get_point_y(my_path, current_path_index);
    }
    
    // Movement speed calculations
    var base_speed = 2;
    var min_speed = 1;
    var max_speed = 3;
    var speed_factor = clamp(dist_to_point / global.cell_size, 0, 1);
    var move_spd = min_speed + (base_speed * speed_factor);
    move_spd = min(move_spd, max_speed);
    
    var dir = point_direction(x, y, path_x, path_y);
    var move_x = lengthdir_x(move_spd, dir);
    var move_y = lengthdir_y(move_spd, dir);
    
    // Collision checking and movement
    var test_x = x + move_x;
    var test_y = y + move_y;
    
    if (!place_meeting(test_x, test_y, obj_collision)) {
        x = test_x;
        y = test_y;
        is_moving = true;
        
        // Update facing direction
        facing_direction = get_facing_direction(dir);
    } else {
        // Wall sliding
        if (!place_meeting(x + move_x, y, obj_collision)) {
            x += move_x;
            is_moving = true;
        } else if (!place_meeting(x, y + move_y, obj_collision)) {
            y += move_y;
            is_moving = true;
        }
    }
}

function get_facing_direction(angle) {
    if (angle >= 315 || angle < 45) return "right";
    if (angle >= 45 && angle < 135) return "up";
    if (angle >= 135 && angle < 225) return "left";
    return "down";
}

function handle_failed_pathfinding() {
    current_fallback.attempts++;
    if (current_fallback.attempts >= current_fallback.max_attempts) {
        array_push(global.failed_sectors, current_sector);
        current_sector = find_nearest_unsearched_sector(current_sector.x, current_sector.y);
        current_fallback.attempts = 0;
        show_debug_message("Max fallback attempts reached, marking sector as failed");
    }
}

function advance_to_next_point() {
    current_search_point++;
    current_fallback.active = false;
    path_started = false;
    stuck_timer = 0;
    
    if (current_search_point >= array_length(search_points)) {
        complete_sector_search();
    }
}

// Sector management and search point generation
function find_nearest_unsearched_sector(start_x, start_y) {
    var grid_width = ds_grid_width(global.global_searched_sectors);
    var grid_height = ds_grid_height(global.global_searched_sectors);
    
    // First pass: gather all valid unsearched sectors
    var unsearched_sectors = [];
    for (var grid_x = 0; grid_x < grid_width; grid_x++) {
        for (var grid_y = 0; grid_y < grid_height; grid_y++) {
            // Check if sector is valid and unsearched
            if (!ds_grid_get(global.global_searched_sectors, grid_x, grid_y) &&
                !ds_grid_get(global.global_sectors_in_progress, grid_x, grid_y) &&
                !array_contains(global.failed_sectors, {x: grid_x, y: grid_y})) {
                
                // Verify sector has some valid space
                if (verify_sector_accessibility(grid_x, grid_y)) {
                    array_push(unsearched_sectors, { 
                        x: grid_x, 
                        y: grid_y,
                        dist: point_distance(grid_x, grid_y, start_x, start_y)
                    });
                }
            }
        }
    }

    if (array_length(unsearched_sectors) == 0) {
        show_debug_message("No unsearched sectors available - resetting search state");
        reset_search_state();
        return { x: start_x, y: start_y };
    }

    // Sort sectors by distance and pick from closest ones
    array_sort(unsearched_sectors, function(a, b) {
        return a.dist - b.dist;
    });
    
    // Pick randomly from the closest third of sectors
    var selection_pool = min(ceil(array_length(unsearched_sectors) / 3), 5);
    var chosen_index = irandom(selection_pool - 1);
    var next_sector = {
        x: unsearched_sectors[chosen_index].x,
        y: unsearched_sectors[chosen_index].y
    };

    ds_grid_set(global.global_sectors_in_progress, next_sector.x, next_sector.y, true);
    show_debug_message("Selected new sector: " + string(next_sector.x) + "," + string(next_sector.y));
    return next_sector;
}

function verify_sector_accessibility(sector_x, sector_y) {
    var sector_left = sector_x * global.sector_size;
    var sector_top = sector_y * global.sector_size;
    var test_points = 9; // 3x3 grid of test points
    var spacing = global.sector_size / 4;
    
    for (var i = 1; i <= 3; i++) {
        for (var j = 1; j <= 3; j++) {
            var test_x = sector_left + spacing * i;
            var test_y = sector_top + spacing * j;
            
            if (validate_position(test_x, test_y)) {
                return true;
            }
        }
    }
    
    return false;
}

function generate_sector_search_points() {
    search_points = [];
    current_search_point = 0;
    
    var sector_left = current_sector.x * global.sector_size;
    var sector_top = current_sector.y * global.sector_size;
    var sector_center_x = sector_left + global.sector_size / 2;
    var sector_center_y = sector_top + global.sector_size / 2;
    
    // Generate a grid of potential points
    var grid_size = 4; // 4x4 grid
    var spacing = global.sector_size / (grid_size + 1);
    
    // First, add the center point if valid
    if (validate_position(sector_center_x, sector_center_y)) {
        array_push(search_points, {
            x: sector_center_x,
            y: sector_center_y,
            priority: 1
        });
    }
    
    // Add grid points with some randomization
    for (var i = 1; i <= grid_size; i++) {
        for (var j = 1; j <= grid_size; j++) {
            var base_x = sector_left + spacing * i;
            var base_y = sector_top + spacing * j;
            
            // Add some random offset
            var offset = global.cell_size / 2;
            var test_x = base_x + random_range(-offset, offset);
            var test_y = base_y + random_range(-offset, offset);
            
            if (validate_position(test_x, test_y)) {
                // Calculate priority based on distance from center
                var dist_to_center = point_distance(test_x, test_y, sector_center_x, sector_center_y);
                var priority = 1 + (dist_to_center / global.sector_size); // Higher number = lower priority
                
                array_push(search_points, {
                    x: test_x,
                    y: test_y,
                    priority: priority
                });
            }
        }
    }
    
    // Add some random points around valid points
    var extra_points = array_length(search_points);
    for (var i = 0; i < extra_points; i++) {
        var base_point = search_points[i];
        var angle = random(360);
        var distance = random_range(global.cell_size, global.cell_size * 2);
        var test_x = base_point.x + lengthdir_x(distance, angle);
        var test_y = base_point.y + lengthdir_y(distance, angle);
        
        if (validate_position(test_x, test_y)) {
            array_push(search_points, {
                x: test_x,
                y: test_y,
                priority: base_point.priority + 0.5
            });
        }
    }
    
    // Sort points by priority
    array_sort(search_points, function(a, b) {
        return a.priority - b.priority;
    });
    
    // Add some randomization while keeping general priority order
    var groups = 4; // Split into 4 priority groups
    var points_per_group = ceil(array_length(search_points) / groups);
    
    for (var g = 0; g < groups; g++) {
        var start_idx = g * points_per_group;
        var end_idx = min(start_idx + points_per_group, array_length(search_points));
        
        // Shuffle within each group
        for (var i = start_idx; i < end_idx - 1; i++) {
            var j = i + irandom(end_idx - i - 1);
            var temp = search_points[i];
            search_points[i] = search_points[j];
            search_points[j] = temp;
        }
    }
    
    if (array_length(search_points) == 0) {
        show_debug_message("No valid search points found in sector - marking as failed");
        array_push(global.failed_sectors, current_sector);
        complete_sector_search();
    } else {
        show_debug_message("Generated " + string(array_length(search_points)) + 
            " search points for sector: " + string(current_sector.x) + "," + 
            string(current_sector.y));
    }
}

function reset_search_state() {
    // Clear all sector states
    ds_grid_clear(global.global_searched_sectors, false);
    ds_grid_clear(global.global_sectors_in_progress, false);
    global.failed_sectors = [];
    
    // Reset search variables
    search_points = [];
    current_search_point = 0;
    current_fallback.active = false;
    current_fallback.attempts = 0;
    path_started = false;
    
    show_debug_message("Search state reset - all sectors marked as unsearched");
}

function complete_sector_search() {
    current_search_point = 0;
    search_points = [];
    current_fallback.active = false;
    current_fallback.attempts = 0;

    ds_grid_set(global.global_searched_sectors, current_sector.x, current_sector.y, true);
    ds_grid_set(global.global_sectors_in_progress, current_sector.x, current_sector.y, false);

    show_debug_message("Completed search in sector: " + 
        string(current_sector.x) + "," + string(current_sector.y));

    current_sector = find_nearest_unsearched_sector(current_sector.x, current_sector.y);
    search_state = "move_to_sector";
}

// Main search control function
function scr_npc_search() {
    // Ensure variables are initialized
    if (!ensure_search_variables()) {
        return;
    }

    // Handle failed sectors immediately
    if (array_contains(global.failed_sectors, current_sector)) {
        show_debug_message("Currently in failed sector, finding new sector");
        current_sector = find_nearest_unsearched_sector(current_sector.x, current_sector.y);
        search_state = "move_to_sector";
        return;
    }

    // Debug logging
    show_debug_message("Search tick - State: " + string(search_state) + 
                      "\n  Sector: " + string(current_sector.x) + "," + string(current_sector.y) +
                      "\n  Search Points: " + string(array_length(search_points)) +
                      "\n  Current Point: " + string(current_search_point) +
                      "\n  Fallback Active: " + string(current_fallback.active));

    // Main state machine
    switch (search_state) {
        case "move_to_sector": {
            handle_sector_movement();
        } break;

        case "search_sector": {
            handle_sector_search();
        } break;

        default: {
            show_debug_message("Invalid search state detected, resetting to move_to_sector");
            search_state = "move_to_sector";
        } break;
    }

    // Always update pathfinding and movement
    update_pathfinding();
    follow_path();
}

// Handler functions for different states
function handle_sector_movement() {
    var target_x, target_y;
    
    if (current_fallback.active) {
        target_x = current_fallback.x;
        target_y = current_fallback.y;
    } else {
        target_x = current_sector.x * global.sector_size + global.sector_size / 2;
        target_y = current_sector.y * global.sector_size / 2;
        
        // Check if target is in collision
        if (place_meeting(target_x, target_y, obj_collision)) {
            show_debug_message("Sector center in collision, searching for valid point");
            var valid_point = find_valid_sector_entry_point(current_sector.x, current_sector.y);
            if (valid_point.found) {
                target_x = valid_point.x;
                target_y = valid_point.y;
            } else {
                show_debug_message("No valid entry point found, marking sector as failed");
                array_push(global.failed_sectors, current_sector);
                current_sector = find_nearest_unsearched_sector(current_sector.x, current_sector.y);
                return;
            }
        }
    }
    
    var dist = point_distance(x, y, target_x, target_y);
    if (dist < global.cell_size) {
        show_debug_message("Reached target point, transitioning to search");
        current_fallback.active = false;
        search_state = "search_sector";
        generate_sector_search_points();
        pathfinding_timer = 0;
    } else if (!path_started || !path_exists(my_path)) {
        // If we don't have a valid path, try to create one
        if (!attempt_pathfinding(target_x, target_y)) {
            // If pathfinding fails, try fallback
            if (!current_fallback.active) {
                show_debug_message("Direct path failed, attempting fallback");
                current_fallback.active = true;
                current_fallback.x = x + lengthdir_x(global.cell_size * 2, point_direction(x, y, target_x, target_y));
                current_fallback.y = y + lengthdir_y(global.cell_size * 2, point_direction(x, y, target_x, target_y));
            } else {
                // If we're already in fallback and still can't path, mark sector as failed
                show_debug_message("Fallback pathing failed, marking sector as failed");
                array_push(global.failed_sectors, current_sector);
                current_sector = find_nearest_unsearched_sector(current_sector.x, current_sector.y);
            }
        }
    }
}

function handle_sector_search() {
    // Check if we need to generate or have exhausted points
    if (array_length(search_points) == 0 || current_search_point >= array_length(search_points)) {
        complete_sector_search();
        return;
    }
    
    var search_target = search_points[current_search_point];
    var dist_to_target = point_distance(x, y, search_target.x, search_target.y);

    // Point reached check
    if (dist_to_target < global.cell_size / 2) {
        handle_point_reached();
        return;
    }

    // Handle movement to current point
    if (!path_started && !current_fallback.active) {
        if (!try_path_to_point(search_target.x, search_target.y)) {
            handle_failed_point();
        }
    }
}

function find_valid_sector_entry_point(sector_x, sector_y) {
    var center_x = sector_x * global.sector_size + global.sector_size / 2;
    var center_y = sector_y * global.sector_size + global.sector_size / 2;
    var search_radius = global.sector_size / 4;  // Start with smaller radius
    var angles = 8;
    var max_attempts = 4;
    
    for (var attempt = 0; attempt < max_attempts; attempt++) {
        var current_radius = search_radius * (1 + attempt);
        
        for (var i = 0; i < angles; i++) {
            var angle = (360 / angles) * i;
            var test_x = center_x + lengthdir_x(current_radius, angle);
            var test_y = center_y + lengthdir_y(current_radius, angle);
            
            if (!place_meeting(test_x, test_y, obj_collision)) {
                // Additional validation to ensure point is reachable
                if (try_path_with_validation(global.path_grid, my_path, x, y, test_x, test_y, global.cell_size)) {
                    return {
                        found: true,
                        x: test_x,
                        y: test_y
                    };
                }
            }
        }
    }
    
    return { found: false };
}

function handle_point_reached() {
    current_search_point++;
    current_fallback.active = false;
    path_started = false;
    
    if (current_search_point >= array_length(search_points)) {
        complete_sector_search();
    } else {
        // Try to path to next point immediately
        var next_point = search_points[current_search_point];
        try_path_to_point(next_point.x, next_point.y);
    }
}

function handle_failed_point() {
    // Increment attempts counter
    current_fallback.attempts++;
    
    if (current_fallback.attempts >= current_fallback.max_attempts) {
        show_debug_message("Max attempts reached for current point, moving to next");
        current_search_point++;
        current_fallback.attempts = 0;
        current_fallback.active = false;
        
        if (current_search_point >= array_length(search_points)) {
            complete_sector_search();
        }
    } else {
        // Try a fallback position
        var fallback_angle = random(360);
        var fallback_dist = global.cell_size * (1 + current_fallback.attempts);
        current_fallback.x = x + lengthdir_x(fallback_dist, fallback_angle);
        current_fallback.y = y + lengthdir_y(fallback_dist, fallback_angle);
        current_fallback.active = true;
    }
}