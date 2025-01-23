// Script: scr_npc_init
/// @desc Initialize base NPC variables and systems
function npc_init() {
    // Core variables
    initialized = false;
    state = "search";
    
    // Movement variables
    push_x = 0;
    push_y = 0;
    move_speed = 3;
    
    // Animation variables
    sprite_index = spr_character_base; // Make sure this matches your sprite
    image_speed = 0;
    current_anim_frame = 0;
    anim_speed = 0.2;
    facing_direction = "down";
    
    // Initialize search state
    initialize_entity_search(id);
    
    // Set initial search parameters
    if (is_struct(search_state)) {
        search_state.scan_angle = 0;
        search_state.scan_complete = false;
        search_state.initialized = true;
    } else {
        __npc_debug_log("ERROR: Failed to initialize search_state");
        return false;
    }
    
    initialized = true;
    return true;
}