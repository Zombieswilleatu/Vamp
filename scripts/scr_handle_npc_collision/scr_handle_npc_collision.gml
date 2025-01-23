/// @function check_entity_collision(entity, test_x, test_y, ignore_ids = [])
/// @description Checks for collisions with other entities at a test position
/// @returns {Array} Array of colliding entity IDs, empty if none
function check_entity_collision(entity, test_x, test_y, ignore_ids = []) {
    var colliding_entities = [];
    
    // Store original position
    var orig_x = entity.x;
    var orig_y = entity.y;
    
    // Temporarily move to test position
    entity.x = test_x;
    entity.y = test_y;
    
    // Check for collisions with other entities
    with(obj_entity_root) {
        if (id != entity.id && !array_contains(ignore_ids, id)) {  // Don't check against self or ignored entities
            if (place_meeting(x, y, entity)) {
                array_push(colliding_entities, id);
            }
        }
    }
    
    // Restore original position
    entity.x = orig_x;
    entity.y = orig_y;
    
    return colliding_entities;
}

/// @function get_nearby_entities(x, y, radius, ignore_ids = [])
/// @description Gets all entities within a radius for pathfinding consideration
/// @returns {Array} Array of nearby entity data
function get_nearby_entities(x, y, radius, ignore_ids = []) {
    var nearby = [];
    
    with(obj_entity_root) {
        if (!array_contains(ignore_ids, id)) {  // Skip ignored entities
            var center_x = bbox_left + (bbox_right - bbox_left) / 2;
            var center_y = bbox_top + (bbox_bottom - bbox_top) / 2;
            
            var dist = point_distance(center_x, center_y, x, y);
            if (dist < radius) {
                array_push(nearby, {
                    id: id,
                    x: center_x,
                    y: center_y,
                    bbox_width: bbox_right - bbox_left,
                    bbox_height: bbox_bottom - bbox_top,
                    distance: dist
                });
            }
        }
    }
    
    // Sort by distance for priority processing
    array_sort(nearby, function(a, b) {
        return a.distance - b.distance;
    });
    
    return nearby;
}

/// @function update_nav_grid_with_entities(ignore_ids = [])
/// @description Updates the navigation grid with current entity positions
function update_nav_grid_with_entities(ignore_ids = []) {
    var pfs = global.PathfindingSystem;
    if (!pfs.initialized || pfs.nav_grid == undefined) return;
    
    // Clear previous entity markers
    for (var gx = 0; gx < pfs.grid_width; gx++) {
        for (var gy = 0; gy < pfs.grid_height; gy++) {
            if (ds_grid_get(pfs.nav_grid, gx, gy) == NAV_CELL_ENTITY_PRESENT) {
                ds_grid_set(pfs.nav_grid, gx, gy, NAV_CELL_WALKABLE);
            }
        }
    }
    
    // Mark cells with entities
    with(obj_entity_root) {
        if (!array_contains(ignore_ids, id)) {  // Skip ignored entities
            // Get grid coordinates for entity bounds
            var grid_left   = floor(bbox_left / GRID_CELL_SIZE);
            var grid_right  = floor(bbox_right / GRID_CELL_SIZE);
            var grid_top    = floor(bbox_top / GRID_CELL_SIZE);
            var grid_bottom = floor(bbox_bottom / GRID_CELL_SIZE);
            
            // Mark cells
            for (var gx = grid_left; gx <= grid_right; gx++) {
                for (var gy = grid_top; gy <= grid_bottom; gy++) {
                    if (validate_grid_coordinates(gx, gy)) {
                        if (ds_grid_get(pfs.nav_grid, gx, gy) == NAV_CELL_WALKABLE) {
                            ds_grid_set(pfs.nav_grid, gx, gy, NAV_CELL_ENTITY_PRESENT);
                        }
                    }
                }
            }
        }
    }
}

/// @function should_repath_for_entities(entity, path, ignore_ids = [])
/// @description Checks if we need to repath due to entity positions
/// @returns {Boolean} true if repathing is recommended
function should_repath_for_entities(entity, path, ignore_ids = []) {
    if (array_length(path) < 2) return false;
    
    // Look ahead a few waypoints
    var look_ahead = min(3, array_length(path) - 1);
    var check_radius = GRID_CELL_SIZE * 2; // Adjust based on needs
    
    for (var i = 1; i <= look_ahead; i++) {
        var waypoint = path[i];
        var nearby = get_nearby_entities(waypoint.x, waypoint.y, check_radius, ignore_ids);
        
        // If too many entities near upcoming waypoint, suggest repathing
        if (array_length(nearby) >= 2) {  // Adjust threshold as needed
            return true;
        }
        
        // Check if direct path to waypoint is blocked by entities
        var collision_entities = check_entity_collision(
            entity,
            waypoint.x,
            waypoint.y,
            ignore_ids
        );
        
        if (array_length(collision_entities) > 0) {
            return true;
        }
    }
    
    return false;
}