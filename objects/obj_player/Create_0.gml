// Create Event for obj_player
event_inherited();
move_speed = 2.75;
hspeed = 0;
vspeed = 0;
sprite_index = spr_player1; // Updated to match your sprite name
image_speed = 0.1;
push_x = 0;
push_y = 0;

// Night vision properties
night_vision_radius = 200;  // Radius for night vision effect (adjust as needed))

current_anim_start = ANIM_WALK_DOWN_START;
current_anim_end = ANIM_WALK_DOWN_END;
is_moving = false;
last_direction = "down";

