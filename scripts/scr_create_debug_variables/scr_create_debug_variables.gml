// In a script file, e.g., scr_create_debug_variables.gml

function create_debug_variables() {
    // Debug-related variables
    detection_level = detection_level ?? 0;
    npc_state = npc_state ?? "search";
    can_see_player = false;
    can_detect_player = false;
    debug_enabled = true;
    show_path_debug = true;
}
