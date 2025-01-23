// Cleanup function - should be called when shutting down
function cleanup_pathfinding() {
    if (variable_global_exists("pf_system")) {
        if (ds_exists(global.pf_system.nodes, ds_type_grid)) {
            ds_grid_destroy(global.pf_system.nodes);
        }
        if (ds_exists(global.pf_system.open_list, ds_type_priority)) {
            ds_priority_destroy(global.pf_system.open_list);
        }
        global.pf_system = undefined;
    }

    if (variable_global_exists("fallback_cache")) {
        if (ds_exists(global.fallback_cache, ds_type_map)) {
            ds_map_destroy(global.fallback_cache);
        }
        global.fallback_cache = undefined;
    }
}