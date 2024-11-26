// General helper functions

function rectangle_rectangle_collision(left1, top1, right1, bottom1, left2, top2, right2, bottom2) {
    return !(left1 >= right2 || right1 <= left2 || top1 >= bottom2 || bottom1 <= top2);
}

function get_overlap_rectangle(left1, top1, right1, bottom1, left2, top2, right2, bottom2) {
    var overlap_left = max(left1, left2);
    var overlap_top = max(top1, top2);
    var overlap_right = min(right1, right2);
    var overlap_bottom = min(bottom1, bottom2);
    return {
        left: overlap_left,
        top: overlap_top,
        right: overlap_right,
        bottom: overlap_bottom
    };
}

function approach(current, target, amount) {
    if (abs(target - current) <= amount) {
        return target;
    } else {
        return current + sign(target - current) * amount;
    }
}

function log_npc_debug(npc_id, state_name, details = "") {
    var msg = "[NPC:" + string(npc_id) + "] " + state_name;
    if (details != "") {
        msg += " - " + details;
    }
    show_debug_message(msg);
}

function debug_coordinates(prefix, x1, y1, x2, y2) {
    show_debug_message(prefix + " Start: (" + string(x1) + "," + string(y1) + 
                      ") End: (" + string(x2) + "," + string(y2) + ")");
}

// scr_entity_utils
function get_entity_center(entity) {
    if (!variable_instance_exists(entity, "bbox_bottom") || !variable_instance_exists(entity, "bbox_top")) {
        show_debug_message("[ERROR] Entity does not have bounding box data: " + string(entity));
        return { x: entity.x, y: entity.y }; // Fallback to raw coordinates
    }
    return {
        x: (entity.bbox_right + entity.bbox_left) / 2,
        y: (entity.bbox_bottom + entity.bbox_top) / 2
    };
}



function is_position_valid_npc(check_x, check_y, entity) {
    // Temporarily disable entity mask to avoid self-collision
    var was_active = entity.mask_index;
    entity.mask_index = -1;

    // Grid-based walkability check
    var grid_x = floor(check_x / global.cell_size);
    var grid_y = floor(check_y / global.cell_size);

    // Ensure the position is within the bounds of the navigation grid
    if (grid_x < 0 || grid_x >= global.grid.width || grid_y < 0 || grid_y >= global.grid.height) {
        entity.mask_index = was_active;
        return false; // Out of bounds, not valid
    }

    // Check walkability based on the navigation grid
    if (!check_node_walkable(grid_x, grid_y)) {
        entity.mask_index = was_active;
        return false; // Unwalkable tile, not valid
    }

    // Check for collisions with objects like walls
    var collision = place_meeting(check_x, check_y, obj_collision);
    if (collision) {
        entity.mask_index = was_active;
        return false; // Collision detected, not valid
    }

    // Restore the entity's mask index
    entity.mask_index = was_active;

    // If all checks pass, the position is valid
    return true;
}


