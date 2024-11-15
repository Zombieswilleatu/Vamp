function create_astar_grid(tilemap_id) {
    // Get tilemap dimensions
    var map_width = tilemap_get_width(tilemap_id);
    var map_height = tilemap_get_height(tilemap_id);
    show_debug_message("Generating A* grid for tilemap. Width: " + string(map_width) + ", Height: " + string(map_height));

    // Create an empty grid for A* (2D array)
    var astar_grid = [];
    for (var i = 0; i < map_width; i++) {
        astar_grid[i] = [];
        for (var j = 0; j < map_height; j++) {
            // Get the tile at this position
            var tile = tilemap_get(tilemap_id, i, j);

            // If tile is walkable, mark it as 0 (walkable), otherwise 1 (blocked)
            if (tile == 0) { // Adjust based on your walkable tile index
                astar_grid[i][j] = 0;  // Walkable
            } else {
                astar_grid[i][j] = 1;  // Non-walkable (collider)
            }
        }
    }

    show_debug_message("A* grid generated.");
    return astar_grid;
}
