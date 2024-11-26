if (!variable_instance_exists(id, "initialized") || !initialized) exit;

// Check for emergency unstuck logic
var emergency_unstuck = scr_handle_stuck(self);

// If not stuck, handle regular follow logic
if (!emergency_unstuck) {
    scr_npc_follow(); // Pathfinding movement
    scr_handle_npc_collision(self); // Collision resolution
    
    // Calculate movement for animation
    var move_h = x - xprevious;
    var move_v = y - yprevious;
    scr_npc_animation(move_h, move_v);  // Pass movement values
}

scr_fade_control(self); // Handle fading effects