// In a script file, e.g., scr_create_debug_variables.gml
function create_debug_variables() {
    // Debug-related variables
    detection_level = detection_level ?? 0;      // Default detection level
    npc_state = npc_state ?? "search";          // Default state
    can_see_player = false;                     // Vision detection debug
    can_detect_player = false;                  // Hearing detection debug
    debug_enabled = true;                       // Toggle debug information
    show_path_debug = true;                     // Pathfinding debug visualization
}
