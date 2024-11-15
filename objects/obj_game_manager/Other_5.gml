/// ROOM END EVENT - obj_game_manager
function cleanup_global_search_system() {
    if (variable_global_exists("path_grid")) {
        mp_grid_destroy(global.path_grid);
    }
    if (variable_global_exists("global_searched_sectors")) {
        ds_grid_destroy(global.global_searched_sectors);
    }
    if (variable_global_exists("global_sectors_in_progress")) {
        ds_grid_destroy(global.global_sectors_in_progress);
    }
    if (variable_global_exists("region_grid")) {
        ds_grid_destroy(global.region_grid);
    }
}