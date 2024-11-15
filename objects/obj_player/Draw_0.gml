/// @description Insert description here
// You can write your code in this editor
// Inherit the parent event
event_inherited();

// Draw Event
draw_self();

if (keyboard_check(vk_tab)) {  // Only show when Tab is held
    draw_collision_debug();
}

// Draw collision mask and origin point
function draw_collision_debug() {
    var collision_index = mask_index != -1 ? mask_index : sprite_index;
    var half_width = sprite_get_width(sprite_index) / 2;
    
    // Draw the collision mask rectangle
    draw_set_color(c_red);
    draw_set_alpha(0.3);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, false);
    
    // Draw the origin point
    draw_set_color(c_yellow);
    draw_set_alpha(1);
    draw_circle(x, y, 2, false);
    
    // Draw sprite boundaries for bottom-center origin
    draw_set_color(c_lime);
    draw_set_alpha(0.3);
    draw_rectangle(x - half_width,                    // Left edge (half width left of origin)
                  y - sprite_get_height(sprite_index), // Top edge (full height up from origin)
                  x + half_width,                     // Right edge (half width right of origin)
                  y,                                  // Bottom edge (at origin)
                  true);
    
    // Draw cross to show center
    var cross_size = 4;
    draw_line(x - cross_size, y - sprite_get_height(sprite_index)/2,
              x + cross_size, y - sprite_get_height(sprite_index)/2);
    draw_line(x, y - sprite_get_height(sprite_index)/2 - cross_size,
              x, y - sprite_get_height(sprite_index)/2 + cross_size);
    
    // Reset drawing properties
    draw_set_color(c_white);
    draw_set_alpha(1);
}