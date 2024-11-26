function create_villager_variables() {
    // Basic state variables
    initialized = false;  // Use the same variable name as in the Step event
    npc_state = "search";
    search_state = "";

    // Movement properties
    move_speed = 3;

    // Direction and animation
    facing_direction = "down";
    last_direction = "down";
    direction_change_timer = 5;

    // Follow script specific variables
    is_stuck = false;
    stuck_timer = 0;
    last_progress_x = x;
    last_progress_y = y;
    path_failed_count = 0;

    // Path variables
    current_path = [];  // Initialize current_path
    pathfinding_check_interval = 10;
    path_timer = 45;
    pathfinding_timer = pathfinding_check_interval;
    current_path_index = 0;
    path_started = false;
    cell_size = 32;

    // Follow distance variables
    min_follow_dist = cell_size;
    max_follow_dist = cell_size * 3;

    // Pathfinding target tracking
    last_target_x = x; // Start with NPC's initial position
    last_target_y = y;

    // Path tolerance
    tolerance = 4; // Adjust this value as needed for precision

    // Position tracking (if needed)
    no_movement_timer = 0;

    // Push variables
    push_x = 0;
    push_y = 0;

    // Final initialization flags
    initialized = true;  // Set initialized to true
}
