/// @desc STEP EVENT
// Update state machine
scr_enemy_behavior();

// Update animation based on current state
if (npc_state == "search") {
    scr_npc_animation(search_last_move_x, search_last_move_y);
} else if (npc_state == "follow") {
    scr_npc_animation(follow_last_move_x, follow_last_move_y);
}