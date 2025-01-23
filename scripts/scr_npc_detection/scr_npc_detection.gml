// Script: scr_npc_detection

function create_detection_variables() {
    // Vision cone settings
    vision_angle = 90;           // Width of the cone in degrees
    vision_range = 500;          // Length of the cone in pixels
    vision_direction = 0;        // Current direction (auto-updated based on facing)
    vision_los_step = 4;         // How precise the line of sight check is
    
    // Store tilemap ID for collision checking
    collision_tilemap = layer_tilemap_get_id("Tile_unwalkable");
    
    // Detection states - initialize all variables
    can_see_player = false;
    can_detect_player = false;
    detection_level = 0;         // 0 to 100
    detection_increase_rate = 1; 
    detection_decay_rate = 0.5;    
    fully_detected = false;
    
    // Other detection settings
    detection_radius = 225;       // Radius for circular detection (hearing)
}

function is_point_collision(check_x, check_y) {
    // Convert pixel coordinates to tilemap coordinates
    var tile_x = floor(check_x / 32);
    var tile_y = floor(check_y / 32);
    
    // Check tilemap collision
    if (collision_tilemap != -1) {
        var tile = tilemap_get(collision_tilemap, tile_x, tile_y);
        if (tile != 0) return true;  // There's a wall here
    }
    
    // Check for collision objects if they exist
    if (instance_position(check_x, check_y, obj_collision_root)) {
        return true;
    }
    
    return false;
}

function is_line_of_sight_clear(start_x, start_y, target_x, target_y, step_size) {
    var dir = point_direction(start_x, start_y, target_x, target_y);
    var dist = point_distance(start_x, start_y, target_x, target_y);
    var steps = dist / step_size;
    
    for (var i = 1; i < steps; i++) {
        var check_x = start_x + lengthdir_x(i * step_size, dir);
        var check_y = start_y + lengthdir_y(i * step_size, dir);
        
        if (is_point_collision(check_x, check_y)) {
            return false;
        }
    }
    
    return true;
}

function update_npc_detection() {
    if (!instance_exists(obj_player)) return;

    // Update vision direction based on facing_direction
    switch(facing_direction) {
        case "right": vision_direction = 0; break;
        case "up": vision_direction = 90; break;
        case "left": vision_direction = 180; break;
        case "down": vision_direction = 270; break;
    }

    // Check for radius-based detection first (like hearing)
    var dist_to_player = point_distance(x, y, obj_player.x, obj_player.y);

    // Reset detection states
    can_see_player = false;
    can_detect_player = false;

    // Calculate detection rate based on proximity
    var proximity_rate_modifier = 1 + (detection_radius / max(1, dist_to_player));

    // Check if player is within hearing range
    if (dist_to_player <= detection_radius) {
        can_detect_player = true;
    }

    // Vision cone detection
    if (dist_to_player <= vision_range) {
        var dir_to_player = point_direction(x, y, obj_player.x, obj_player.y);
        var angle_diff = angle_difference(vision_direction, dir_to_player);

        if (abs(angle_diff) <= (vision_angle / 2) + 10) {
            if (is_line_of_sight_clear(x, y, obj_player.x, obj_player.y, 8)) {
                can_see_player = true;
            }
        }
    }

    // Update detection level
    if (can_see_player || can_detect_player) {
        var detection_rate = detection_increase_rate * proximity_rate_modifier;
        detection_level = min(100, detection_level + detection_rate);
    } else {
        detection_level = max(0, detection_level - detection_decay_rate);
    }

    // Update fully detected state
    fully_detected = (detection_level >= 100);
}
