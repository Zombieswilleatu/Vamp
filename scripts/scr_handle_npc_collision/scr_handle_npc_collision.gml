function scr_handle_npc_collision(entity) {
    if (!instance_exists(entity)) return;
    
    // Only process collisions if entities are close enough
    var check_radius = 64; // Adjust based on entity sizes
    var nearby_count = 0;
    var processing_needed = false;
    
    // Calculate entity center points
    var entity_center_x = entity.bbox_left + (entity.bbox_right - entity.bbox_left) / 2;
    var entity_center_y = entity.bbox_top + (entity.bbox_bottom - entity.bbox_top) / 2;
    
    with (obj_entity_root) {
        if (id != entity.id) {
            var other_center_x = bbox_left + (bbox_right - bbox_left) / 2;
            var other_center_y = bbox_top + (bbox_bottom - bbox_top) / 2;
            
            if (point_distance(other_center_x, other_center_y, entity_center_x, entity_center_y) < check_radius) {
                nearby_count++;
                if (nearby_count > 3) {
                    processing_needed = true;
                    break;
                }
            }
        }
    }
    
    if (!processing_needed) return;
    
    // Reset push forces for the entity
    with (entity) {
        push_x = 0;
        push_y = 0;
    }
    
    // Number of separation passes based on cluster size
    var separation_passes = min(3, nearby_count - 1);
    
    for (var pass = 0; pass < separation_passes; pass++) {
        with (obj_entity_root) {
            if (id != entity.id) {
                var other_center_x = bbox_left + (bbox_right - bbox_left) / 2;
                var other_center_y = bbox_top + (bbox_bottom - bbox_top) / 2;
                
                if (point_distance(other_center_x, other_center_y, entity_center_x, entity_center_y) < check_radius) {
                    var overlap = rectangle_rectangle_collision(
                        entity.bbox_left, entity.bbox_top, entity.bbox_right, entity.bbox_bottom,
                        bbox_left, bbox_top, bbox_right, bbox_bottom
                    );
                    
                    if (overlap) {
                        var dx = entity_center_x - other_center_x;
                        var dy = entity_center_y - other_center_y;
                        var dist = point_distance(0, 0, dx, dy);
                        
                        if (dist > 0) {
                            // Calculate push force based on overlap and distance
                            var push_force = (check_radius - dist) / check_radius;
                            var push_angle = point_direction(other_center_x, other_center_y, 
                                                          entity_center_x, entity_center_y);
                            
                            with (entity) {
                                push_x += lengthdir_x(2 * push_force, push_angle);
                                push_y += lengthdir_y(2 * push_force, push_angle);
                            }
                        }
                    }
                }
            }
        }
        
        // Apply movement with wall collision check using adjusted bbox
        with (entity) {
            // Calculate the offset from center to top-left corner
            var half_width = (bbox_right - bbox_left) / 2;
            var half_height = (bbox_bottom - bbox_top) / 2;
            
            // Adjust collision check position to account for entity's center point
            var check_x = x + push_x;
            var check_y = y + push_y;
            
            // Create a temporary collision mask at the potential new position
            var can_move_x = !collision_rectangle(
                check_x - half_width, bbox_top,
                check_x + half_width, bbox_bottom,
                obj_collision, false, true
            );
            
            var can_move_y = !collision_rectangle(
                bbox_left, check_y - half_height,
                bbox_right, check_y + half_height,
                obj_collision, false, true
            );
            
            if (can_move_x) x += push_x;
            if (can_move_y) y += push_y;
            if (!can_move_x) push_x = 0;
            if (!can_move_y) push_y = 0;
        }
    }
}