
function create_villager_variables() {
    // Basic state variables
    initialized_follow = false;
    npc_state = "search";  // Start in search mode
    search_state = ""; // Initialize with an empty string
    // Movement properties
    move_speed = 1;
    hspeed = 0;
    vspeed = 0;
    is_moving = false;
    // Direction and animation
    facing_direction = "down";
    last_direction = "down";
    direction_change_timer = 5;
    image_speed = 1.5;
    // Follow script specific variables
    is_stuck = false;
    stuck_timer = 0;
    last_progress_x = x;
    last_progress_y = y;
    path_failed_count = 0;
    // Path variables
    pathfinding_check_interval = 10;
    pathfinding_timer = pathfinding_check_interval;
    current_path_index = 0;
    path_started = false;
    cell_size = 32;
    // Debug and detection
    detection_level = 0;
    // Final initialization flags
    initialized_follow = true;
	push_x = 0;
	push_y = 0;
}
