/*************************************************************************
 *   PATHFINDING SYSTEM - OPTIMIZED VERSION
 *************************************************************************/

// 1) MACROS & GLOBAL VARS
#macro NAV_CELL_WALKABLE 1
#macro NAV_CELL_UNWALKABLE 0
#macro NAV_CELL_ENTITY_PRESENT 2

#macro PF_MAX_ITERATIONS 2000
#macro PF_MAX_TIME_MS 128
#macro PF_INIT_COST 9999999
#macro PF_VISIT_NONE -1
#macro PF_COST_STRAIGHT 10
#macro TILE_SIZE 32
#macro GRID_CELL_SIZE 32

globalvar PF_DIRECTIONS;

/****************************************************************************
 * 2) INIT FUNCTION
 ****************************************************************************/
function pathfinding_system_init() {
    if (!variable_global_exists("PathfindingSystem")) {
        global.PathfindingSystem = {
            nav_grid: undefined,
            grid_width: 0,
            grid_height: 0,
            cell_size: GRID_CELL_SIZE,
            
            // Cache grids
            collision_cache: undefined,
            wall_counts: undefined,
            
            // Pathfinding data structures
            visit_map: undefined,
            g_cost_map: undefined,
            parent_x_map: undefined,
            parent_y_map: undefined,
            
            current_visit_id: 0,
            initialized: false,
            debug_mode: false,
            
            // Queue system
            path_requests: ds_queue_create(),
            max_requests_per_frame: 2,
            requests_this_frame: 0,
            frame_start_time: get_timer()
        };
    }
    
    if (global.PathfindingSystem.initialized) {
        show_debug_message("[Pathfinding] System already initialized.");
        return true;
    }
    
    PF_DIRECTIONS = [
        { dx:  0, dy: -1, cost: PF_COST_STRAIGHT },       // Up
        { dx:  1, dy: -1, cost: PF_COST_STRAIGHT * 1.4 }, // Up-Right
        { dx:  1, dy:  0, cost: PF_COST_STRAIGHT },       // Right
        { dx:  1, dy:  1, cost: PF_COST_STRAIGHT * 1.4 }, // Down-Right
        { dx:  0, dy:  1, cost: PF_COST_STRAIGHT },       // Down
        { dx: -1, dy:  1, cost: PF_COST_STRAIGHT * 1.4 }, // Down-Left
        { dx: -1, dy:  0, cost: PF_COST_STRAIGHT },       // Left
        { dx: -1, dy: -1, cost: PF_COST_STRAIGHT * 1.4 }  // Up-Left
    ];
    
    global.PathfindingSystem.visit_map    = ds_grid_create(1, 1);
    global.PathfindingSystem.g_cost_map   = ds_grid_create(1, 1);
    global.PathfindingSystem.parent_x_map = ds_grid_create(1, 1);
    global.PathfindingSystem.parent_y_map = ds_grid_create(1, 1);
    
    global.PathfindingSystem.initialized = true;
    show_debug_message("[Pathfinding] Initialized with cell_size: " + string(GRID_CELL_SIZE));
    return true;
}

/****************************************************************************
 * 3) CREATE THE NAVIGATION GRID
 ****************************************************************************/
function pathfinding_create_grid() {
    var pfs = global.PathfindingSystem;
    if (!pfs.initialized) {
        show_debug_message("[Pathfinding] ERROR: System not initialized!");
        return false;
    }
    
    var unwalkable_layer = layer_get_id("Tile_unwalkable");
    var walkable_layer   = layer_get_id("Tile_walkable");
    if (unwalkable_layer == -1 || walkable_layer == -1) {
        show_debug_message("[Pathfinding] ERROR: Could not find required tile layers.");
        return false;
    }
    
    var unwalkable_map = layer_tilemap_get_id(unwalkable_layer);
    var walkable_map   = layer_tilemap_get_id(walkable_layer);
    
    // Calculate grid dimensions
    var tile_grid_w = tilemap_get_width(unwalkable_map);
    var tile_grid_h = tilemap_get_height(unwalkable_map);
    var grid_w = tile_grid_w * (TILE_SIZE / GRID_CELL_SIZE);
    var grid_h = tile_grid_h * (TILE_SIZE / GRID_CELL_SIZE);
    
    // Clear old grids if they exist
    if (pfs.nav_grid != undefined) ds_grid_destroy(pfs.nav_grid);
    if (pfs.collision_cache != undefined) ds_grid_destroy(pfs.collision_cache);
    if (pfs.wall_counts != undefined) ds_grid_destroy(pfs.wall_counts);
    
    // Create new grids
    pfs.nav_grid = ds_grid_create(grid_w, grid_h);
    pfs.collision_cache = ds_grid_create(grid_w, grid_h);
    pfs.wall_counts = ds_grid_create(grid_w, grid_h);
    
    pfs.grid_width = grid_w;
    pfs.grid_height = grid_h;
    
    ds_grid_clear(pfs.nav_grid, NAV_CELL_UNWALKABLE);
    ds_grid_clear(pfs.collision_cache, true);
    ds_grid_clear(pfs.wall_counts, 0);
    
    // Remove old collisions
    with (obj_collision) {
        instance_destroy();
    }
    
    // Fill the nav grid and create collision objects
    for (var tile_x = 0; tile_x < tile_grid_w; tile_x++) {
        for (var tile_y = 0; tile_y < tile_grid_h; tile_y++) {
            var tile_walkable   = tilemap_get(walkable_map,   tile_x, tile_y);
            var tile_unwalkable = tilemap_get(unwalkable_map, tile_x, tile_y);
            
            var grid_base_x = tile_x * (TILE_SIZE / GRID_CELL_SIZE);
            var grid_base_y = tile_y * (TILE_SIZE / GRID_CELL_SIZE);
            
            if (tile_walkable != 0 && tile_unwalkable == 0) {
                // Mark walkable
                for (var dx = 0; dx < (TILE_SIZE / GRID_CELL_SIZE); dx++) {
                    for (var dy = 0; dy < (TILE_SIZE / GRID_CELL_SIZE); dy++) {
                        ds_grid_set(pfs.nav_grid, grid_base_x + dx, grid_base_y + dy, NAV_CELL_WALKABLE);
                        ds_grid_set(pfs.collision_cache, grid_base_x + dx, grid_base_y + dy, false);
                    }
                }
            } else if (tile_unwalkable != 0) {
                // Mark unwalkable and create collision
                var world_x = tile_x * TILE_SIZE;
                var world_y = tile_y * TILE_SIZE;
                instance_create_layer(world_x, world_y, "CollisionLayer", obj_collision);
                
                for (var dx = 0; dx < (TILE_SIZE / GRID_CELL_SIZE); dx++) {
                    for (var dy = 0; dy < (TILE_SIZE / GRID_CELL_SIZE); dy++) {
                        ds_grid_set(pfs.nav_grid, grid_base_x + dx, grid_base_y + dy, NAV_CELL_UNWALKABLE);
                        ds_grid_set(pfs.collision_cache, grid_base_x + dx, grid_base_y + dy, true);
                    }
                }
            }
        }
    }
    
    // Calculate wall counts
    for (var gx = 0; gx < grid_w; gx++) {
        for (var gy = 0; gy < grid_h; gy++) {
            var wall_count = 0;
            for (var wx = -1; wx <= 1; wx++) {
                for (var wy = -1; wy <= 1; wy++) {
                    if (wx == 0 && wy == 0) continue;
                    var check_x = gx + wx;
                    var check_y = gy + wy;
                    if (validate_grid_coordinates(check_x, check_y)) {
                        if (ds_grid_get(pfs.nav_grid, check_x, check_y) == NAV_CELL_UNWALKABLE) {
                            wall_count++;
                        }
                    }
                }
            }
            ds_grid_set(pfs.wall_counts, gx, gy, wall_count);
        }
    }
    
    show_debug_message("[Pathfinding] Grid created: " + string(grid_w) + "x" + string(grid_h));
    return true;
}

/****************************************************************************
 * 4) HELPER FUNCTIONS
 ****************************************************************************/
function coords_to_index(coord_x, coord_y) {
    return coord_y * global.PathfindingSystem.grid_width + coord_x;
}

function index_to_coords(index) {
    var pfs = global.PathfindingSystem;
    var coord_x = index mod pfs.grid_width;
    var coord_y = floor(index / pfs.grid_width);
    return { x: coord_x, y: coord_y };
}

function validate_grid_coordinates(coord_x, coord_y) {
    var pfs = global.PathfindingSystem;
    if (!pfs.initialized) return false;
    return (coord_x >= 0 && coord_x < pfs.grid_width && coord_y >= 0 && coord_y < pfs.grid_height);
}

function world_to_grid(wx, wy) {
    return {
        x: floor(wx / GRID_CELL_SIZE),
        y: floor(wy / GRID_CELL_SIZE)
    };
}

function grid_to_world(gx, gy) {
    return {
        x: (gx * GRID_CELL_SIZE) + (GRID_CELL_SIZE * 0.5),
        y: (gy * GRID_CELL_SIZE) + (GRID_CELL_SIZE * 0.5)
    };
}

/****************************************************************************
 * 5) FIND A WALKABLE CELL NEAR
 ****************************************************************************/
function find_walkable_point_near(grid_x, grid_y, world_x, world_y) {
    var pfs = global.PathfindingSystem;
    var search_radius = 2;
    var candidates = [];
    
    for (var r = 1; r <= search_radius; r++) {
        for (var dx = -r; dx <= r; dx++) {
            for (var dy = -r; dy <= r; dy++) {
                var tx = grid_x + dx;
                var ty = grid_y + dy;
                
                if (validate_grid_coordinates(tx, ty)) {
                    if (ds_grid_get(pfs.nav_grid, tx, ty) == NAV_CELL_WALKABLE &&
                        !ds_grid_get(pfs.collision_cache, tx, ty)) {
                        var test_world = grid_to_world(tx, ty);
                        array_push(candidates, {
                            grid:  { x: tx, y: ty },
                            world: test_world
                        });
                    }
                }
            }
        }
    }
    
    if (array_length(candidates) <= 0) return undefined;
    
    // Return whichever is physically closest
    var best_index = -1;
    var best_dist  = 9999999;
    for (var i = 0; i < array_length(candidates); i++) {
        var c = candidates[i];
        var dist = point_distance(c.world.x, c.world.y, world_x, world_y);
        if (dist < best_dist) {
            best_dist = dist;
            best_index = i;
        }
    }
    return candidates[best_index];
}

/****************************************************************************
 * 6) MAIN PATHFINDING WITH A*
 ****************************************************************************/
function pathfinding_find_path(start_x, start_y, end_x, end_y, requesting_entity = undefined) {
    var pfs = global.PathfindingSystem;
    if (!pfs.initialized || pfs.nav_grid == undefined) return [];
    
    // Check if entity is in desperate mode
    var ignore_entities = false;
    var in_narrow_space = false;
    
    if (requesting_entity != undefined) {
        if (!variable_instance_exists(requesting_entity, "path_fail_counter")) {
            requesting_entity.path_fail_counter = 0;
            requesting_entity.consecutive_failures = 0;
        }
        
        // Check for narrow space
        var near_walls = 0;
        with(requesting_entity) {
            for (var wx = -1; wx <= 1; wx++) {
                for (var wy = -1; wy <= 1; wy++) {
                    if (wx == 0 && wy == 0) continue;
                    if (place_meeting(x + wx * GRID_CELL_SIZE, y + wy * GRID_CELL_SIZE, obj_collision)) {
                        near_walls++;
                    }
                }
            }
        }
        in_narrow_space = (near_walls >= 3);
        
        show_debug_message("PF: Entity " + string(requesting_entity.id) + 
                          " near_walls=" + string(near_walls) +
                          " consecutive_failures=" + string(requesting_entity.consecutive_failures) +
                          " path_fail_counter=" + string(requesting_entity.path_fail_counter));
        
        // Lower threshold for desperate mode in narrow spaces
        var desperate_threshold = in_narrow_space ? 2 : 3;
        
        if (requesting_entity.consecutive_failures >= desperate_threshold) {
            ignore_entities = true;
            show_debug_message("PF: Entity " + string(requesting_entity.id) + 
                             " DESPERATE MODE ACTIVATED - ignoring entities");
        }
    }
    
    // Convert world coordinates to grid
    var start_g = world_to_grid(start_x, start_y);
    var end_g   = world_to_grid(end_x, end_y);
    
    // Validate coordinates
    if (!validate_grid_coordinates(start_g.x, start_g.y) ||
        !validate_grid_coordinates(end_g.x, end_g.y)) {
        show_debug_message("PF: Invalid grid coords");
        return [];
    }
    
    // If those cells are blocked, find near walkable
    var start_pos = undefined;
    var end_pos = undefined;
    
    if (ds_grid_get(pfs.nav_grid, start_g.x, start_g.y) == NAV_CELL_UNWALKABLE) {
        start_pos = find_walkable_point_near(start_g.x, start_g.y, start_x, start_y);
    }
    if (ds_grid_get(pfs.nav_grid, end_g.x, end_g.y) == NAV_CELL_UNWALKABLE) {
        end_pos = find_walkable_point_near(end_g.x, end_g.y, end_x, end_y);
    }
    
    if (start_pos != undefined) start_g = start_pos.grid;
    if (end_pos != undefined) end_g = end_pos.grid;
    
    // Only check for unwalkable cells
    if (ds_grid_get(pfs.nav_grid, start_g.x, start_g.y) == NAV_CELL_UNWALKABLE ||
        ds_grid_get(pfs.nav_grid, end_g.x, end_g.y) == NAV_CELL_UNWALKABLE) {
        show_debug_message("PF: Start or end unwalkable");
        return [];
    }
    
    // A* preparation
    var open_set = ds_priority_create();
    ds_grid_resize(pfs.visit_map,    pfs.grid_width, pfs.grid_height);
    ds_grid_resize(pfs.g_cost_map,   pfs.grid_width, pfs.grid_height);
    ds_grid_resize(pfs.parent_x_map, pfs.grid_width, pfs.grid_height);
    ds_grid_resize(pfs.parent_y_map, pfs.grid_width, pfs.grid_height);
    
    ds_grid_clear(pfs.visit_map,    PF_VISIT_NONE);
    ds_grid_clear(pfs.g_cost_map,   PF_INIT_COST);
    ds_grid_clear(pfs.parent_x_map, -1);
    ds_grid_clear(pfs.parent_y_map, -1);
    
    ds_grid_set(pfs.g_cost_map, start_g.x, start_g.y, 0);
    ds_priority_add(open_set, coords_to_index(start_g.x, start_g.y), 0);
    
    var start_time = get_timer();
    var iterations = 0;
    
    // A* loop
    while (!ds_priority_empty(open_set)) {
        iterations++;
        if (iterations > PF_MAX_ITERATIONS) {
            show_debug_message("PF: Exceeded max iterations " + string(PF_MAX_ITERATIONS));
            break;
        }
        if ((get_timer() - start_time) > PF_MAX_TIME_MS * 1000) {
            show_debug_message("PF: Exceeded max time " + string(PF_MAX_TIME_MS) + "ms");
            break;
        }
        
        var current_index = ds_priority_delete_min(open_set);
        var current = index_to_coords(current_index);
        
        if (current.x == end_g.x && current.y == end_g.y) {
            var final_path = __pf_reconstruct_path(current.x, current.y);
            ds_priority_destroy(open_set);
            show_debug_message("PF: Path found with " + string(array_length(final_path)) + " points");
            return final_path;
        }
        
        var current_g = ds_grid_get(pfs.g_cost_map, current.x, current.y);
        
        // Expand neighbors
        for (var d = 0; d < array_length(PF_DIRECTIONS); d++) {
            var dir = PF_DIRECTIONS[d];
            var nx = current.x + dir.dx;
            var ny = current.y + dir.dy;
            
            if (!validate_grid_coordinates(nx, ny)) continue;
            
            var cell_value = ds_grid_get(pfs.nav_grid, nx, ny);
            if (cell_value == NAV_CELL_UNWALKABLE) continue;
            
            // Special handling for entity cells in desperate mode
            if (cell_value == NAV_CELL_ENTITY_PRESENT) {
                if (!ignore_entities) continue;
                // If desperate, allow pathing through entities but with a cost
                move_cost *= in_narrow_space ? 1.5 : 2.0;  // Lower penalty in narrow spaces
            } else {
                var move_cost = dir.cost;
            }
            
            // Check cached collision
            if (ds_grid_get(pfs.collision_cache, nx, ny)) continue;
            
            // Simple diagonal check
            if (abs(dir.dx) == 1 && abs(dir.dy) == 1) {
                if (ds_grid_get(pfs.nav_grid, current.x + dir.dx, current.y) == NAV_CELL_UNWALKABLE &&
                    ds_grid_get(pfs.nav_grid, current.x, current.y + dir.dy) == NAV_CELL_UNWALKABLE) {
                    continue;
                }
            }
            
            var new_g = current_g + move_cost;
            if (new_g < ds_grid_get(pfs.g_cost_map, nx, ny)) {
                ds_grid_set(pfs.g_cost_map, nx, ny, new_g);
                ds_grid_set(pfs.parent_x_map, nx, ny, current.x);
                ds_grid_set(pfs.parent_y_map, nx, ny, current.y);
                
                // Manhattan distance heuristic
                var h_cost = 10 * (abs(end_g.x - nx) + abs(end_g.y - ny));
                ds_priority_add(open_set, coords_to_index(nx, ny), new_g + h_cost);
            }
        }
    }
    
    show_debug_message("PF: No path found");
    ds_priority_destroy(open_set);
    return [];
}

/****************************************************************************
 * 7) PATH RECONSTRUCTION
 ****************************************************************************/
function __pf_reconstruct_path(end_gx, end_gy) {
    var pfs = global.PathfindingSystem;
    var path = [];
    
    var cx = end_gx;
    var cy = end_gy;
    var count = 0;
    
    while (cx != -1 && cy != -1) {
        var pt = grid_to_world(cx, cy);
        array_push(path, pt);
        count++;
        
        if (count > PF_MAX_ITERATIONS) {
            show_debug_message("PF: Reconstruct path exceeded max iterations!");
            break;
        }
        
        var px = ds_grid_get(pfs.parent_x_map, cx, cy);
        var py = ds_grid_get(pfs.parent_y_map, cx, cy);
        
        if (px == cx && py == cy) {
            show_debug_message("PF: Loop detected in reconstruction!");
            break;
        }
        
        cx = px;
        cy = py;
    }
    
    array_reverse(path);
    return smooth_path(path);  // Using your existing smooth_path function
}