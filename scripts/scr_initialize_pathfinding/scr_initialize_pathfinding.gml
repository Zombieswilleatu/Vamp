function scr_initialize_pathfinding() {
    if (!global.grid || !global.grid.width || !global.grid.height) {
        show_debug_message("Error: Global grid dimensions are not set.");
        return;
    }

    global.pathfinding = {
        nodes: [],
        open_list: ds_priority_create(),
        closed_list: ds_map_create(),
        path_cache: ds_map_create(),
        path_queue: ds_queue_create(),
        cache_lifetime: 300,
        cache_timestamps: ds_map_create(),
        current_frame_paths: 0,
        total_time_this_frame: 0,
        node_grid_size: global.cell_size, // Use the same cell size
        max_search_iterations: 1000,
        max_time_per_path: (1000 / room_speed) / 2,
        path_smoothing: true
    };

    for (var i = 0; i < global.grid.width; i++) {
        global.pathfinding.nodes[i] = [];
        for (var j = 0; j < global.grid.height; j++) {
            global.pathfinding.nodes[i][j] = {
                x: i,
                y: j,
                g_cost: 0,
                h_cost: 0,
                f_cost: 0,
                walkable: check_node_walkable(i, j),
                movement_cost: 1,
                parent: noone, // Ensure a valid default value
                world_x: i * global.pathfinding.node_grid_size,
                world_y: j * global.pathfinding.node_grid_size
            };
        }
    }
    scr_setup_collision_system();
}

function check_node_walkable(grid_x, grid_y) {
    if (grid_x < 0 || grid_x >= array_length(global.navigation_grid) ||
        grid_y < 0 || grid_y >= array_length(global.navigation_grid[grid_x])) {
        return false;
    }
    return global.navigation_grid[grid_x][grid_y] == 1;
}

function line_clear(start_x, start_y, end_x, end_y) {
    var dist = point_distance(start_x, start_y, end_x, end_y);
    var steps = ceil(dist / global.pathfinding.node_grid_size);

    for (var i = 0; i <= steps; i++) {
        var t = i / steps;
        var check_x = lerp(start_x, end_x, t);
        var check_y = lerp(start_y, end_y, t);

        var grid_x = floor(check_x / global.pathfinding.node_grid_size);
        var grid_y = floor(check_y / global.pathfinding.node_grid_size);

        if (!check_node_walkable(grid_x, grid_y)) {
            return false;
        }
    }
    return true;
}

function get_node_from_world_pos(world_x, world_y, entity = noone) {
    var grid_x = floor(world_x / global.pathfinding.node_grid_size);
    var grid_y = floor(world_y / global.pathfinding.node_grid_size);

    grid_x = clamp(grid_x, 0, global.grid.width - 1);
    grid_y = clamp(grid_y, 0, global.grid.height - 1);

    return global.pathfinding.nodes[grid_x][grid_y];
}

function calculate_distance(node_a, node_b) {
    var dx = abs(node_a.x - node_b.x);
    var dy = abs(node_a.y - node_b.y);
    return (dx + dy) * 10 + min(dx, dy) * 4;
}

function is_diagonal_clear(current_x, current_y, neighbor_x, neighbor_y) {
    if (neighbor_x != current_x && neighbor_y != current_y) {
        var node1_walkable = check_node_walkable(current_x, neighbor_y);
        var node2_walkable = check_node_walkable(neighbor_x, current_y);
        return node1_walkable && node2_walkable;
    }
    return true;
}

function find_path(start_x, start_y, end_x, end_y, entity = noone) {
    ds_priority_clear(global.pathfinding.open_list);
    ds_map_clear(global.pathfinding.closed_list);

    var start_node = get_node_from_world_pos(start_x, start_y, entity);
    var end_node = get_node_from_world_pos(end_x, end_y, entity);

    if (!start_node || !end_node || !start_node.walkable || !end_node.walkable) {
        show_debug_message("Invalid start or end node for pathfinding.");
        return [];
    }

    start_node.g_cost = 0;
    start_node.h_cost = calculate_distance(start_node, end_node);
    start_node.f_cost = start_node.h_cost;
    start_node.parent = noone;

    ds_priority_add(global.pathfinding.open_list, start_node, start_node.f_cost);

    while (!ds_priority_empty(global.pathfinding.open_list)) {
        var current = ds_priority_delete_min(global.pathfinding.open_list);

        if (current.x == end_node.x && current.y == end_node.y) {
            return reconstruct_path(current, entity);
        }

        var key = string(current.x) + "," + string(current.y);
        ds_map_add(global.pathfinding.closed_list, key, current);

        for (var dx = -1; dx <= 1; dx++) {
            for (var dy = -1; dy <= 1; dy++) {
                if (dx == 0 && dy == 0) continue;

                var neighbor_x = current.x + dx;
                var neighbor_y = current.y + dy;

                if (neighbor_x < 0 || neighbor_x >= global.grid.width ||
                    neighbor_y < 0 || neighbor_y >= global.grid.height) continue;

                var neighbor = global.pathfinding.nodes[neighbor_x][neighbor_y];
                var neighbor_key = string(neighbor_x) + "," + string(neighbor_y);

                if (!neighbor.walkable || ds_map_exists(global.pathfinding.closed_list, neighbor_key)) continue;

                if (!is_diagonal_clear(current.x, current.y, neighbor_x, neighbor_y)) continue;

                var movement_cost = current.g_cost + neighbor.movement_cost * ((dx != 0 && dy != 0) ? 1.4 : 1);

                var in_open_list = ds_priority_find_priority(global.pathfinding.open_list, neighbor);
                if (!in_open_list || movement_cost < neighbor.g_cost) {
                    neighbor.g_cost = movement_cost;
                    neighbor.h_cost = calculate_distance(neighbor, end_node);
                    neighbor.f_cost = neighbor.g_cost + neighbor.h_cost;
                    neighbor.parent = current;

                    if (!in_open_list) {
                        ds_priority_add(global.pathfinding.open_list, neighbor, neighbor.f_cost);
                    }
                }
            }
        }
    }

    show_debug_message("No path found!");
    return [];
}

function reconstruct_path(end_node, entity) {
    var raw_path = [];
    var current = end_node;

    while (current != noone) {
        var world_pos = grid_to_world_pos(current.x, current.y, entity);
        array_insert(raw_path, 0, {
            x: world_pos.x,
            y: world_pos.y,
            grid_x: current.x,
            grid_y: current.y
        });
        current = current.parent;
    }

    if (array_length(raw_path) < 2) return raw_path;

    var squared_path = [];
    array_push(squared_path, raw_path[0]);  // Add start point

    for (var i = 1; i < array_length(raw_path) - 1; i++) {
        var prev = raw_path[i - 1];
        var curr = raw_path[i];
        var next = raw_path[i + 1];

        var dx1 = sign(curr.grid_x - prev.grid_x);
        var dy1 = sign(curr.grid_y - prev.grid_y);
        var dx2 = sign(next.grid_x - curr.grid_x);
        var dy2 = sign(next.grid_y - curr.grid_y);

        if (dx1 != dx2 || dy1 != dy2) {  // Direction change detected
            array_push(squared_path, curr);
        }
    }

    array_push(squared_path, raw_path[array_length(raw_path) - 1]);  // Add end point
    return squared_path;
}

function grid_to_world_pos(grid_x, grid_y, entity) {
    return {
        x: grid_x * global.pathfinding.node_grid_size + global.pathfinding.node_grid_size / 2,
        y: grid_y * global.pathfinding.node_grid_size + global.pathfinding.node_grid_size / 2
    };
}

function process_path_queue() {
    var max_paths_per_frame = 3;
    var paths_processed = 0;

    while (!ds_queue_empty(global.pathfinding.path_queue) && paths_processed < max_paths_per_frame) {
        var request = ds_queue_dequeue(global.pathfinding.path_queue);
        find_path(request.start_x, request.start_y, request.end_x, request.end_y, request.entity);
        paths_processed++;
    }
}