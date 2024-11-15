event_inherited();
if (!variable_instance_exists(id, "initialized") || !initialized) exit;
var emergency_unstuck = scr_handle_stuck(self);
if (!emergency_unstuck) scr_npc_follow();
scr_animate_npc(self);
scr_fade_control(self);