function scr_handle_npc_collision(entity) {
    if (!instance_exists(entity)) exit;
    
    // Only process collisions if entities are close enough
    var check_radius = 64; // Adjust based on entity sizes
    var nearby_count = 0;
    var processing_needed = false;
    
    with(obj_entity_root) {
        if(id != entity.id && point_distance(x, y, entity.x, entity.y) < check_radius) {
            nearby_count++;
            if(nearby_count > 3) { // Only process if there's significant grouping
                processing_needed = true;
                break;
            }
        }
    }
    
    if(!processing_needed) return;

    with(entity) {
        push_x = 0;
        push_y = 0;
    }
    
    var separation_passes = min(3, nearby_count - 1); // Adjust passes based on cluster size
    
    for(var pass = 0; pass < separation_passes; pass++) {
        with(obj_entity_root) {
            if(id != entity.id && point_distance(x, y, entity.x, entity.y) < check_radius) {
                var overlap = rectangle_rectangle_collision(
                    entity.bbox_left, entity.bbox_top, entity.bbox_right, entity.bbox_bottom,
                    bbox_left, bbox_top, bbox_right, bbox_bottom
                );
                
                if(overlap) {
                    var dx = entity.x - x;
                    var dy = entity.y - y;
                    var dist = point_distance(0, 0, dx, dy);
                    
                    if(dist > 0) {
                        // Calculate push force based on overlap and distance
                        var push_force = (check_radius - dist) / check_radius;
                        var push_angle = point_direction(x, y, entity.x, entity.y);
                        
                        with(entity) {
                            push_x += lengthdir_x(2 * push_force, push_angle);
                            push_y += lengthdir_y(2 * push_force, push_angle);
                        }
                    }
                }
            }
        }
        
        // Apply movement with wall collision check
        with(entity) {
            var can_move_x = !place_meeting(x + push_x, y, obj_collision);
            var can_move_y = !place_meeting(x, y + push_y, obj_collision);
            
            if(can_move_x) x += push_x;
            if(can_move_y) y += push_y;
            
            if(!can_move_x) push_x = 0;
            if(!can_move_y) push_y = 0;
        }
    }
}