// In obj_collision_root -> Draw Event
//draw_self(); // This will make the collision object visible for debugging purposes


// In obj_collision Draw Event
if (keyboard_check(vk_tab)) {
    draw_set_color(c_red);
    draw_set_alpha(0.5);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, false);
    draw_set_alpha(1);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
}