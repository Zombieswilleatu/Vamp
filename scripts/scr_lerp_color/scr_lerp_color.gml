/// @function lerp_color(col1, col2, t)
/// @param col1 The first color
/// @param col2 The second color
/// @param t The interpolation factor (0 to 1)

function lerp_color(col1, col2, t) {
    var r1 = color_get_red(col1);
    var g1 = color_get_green(col1);
    var b1 = color_get_blue(col1);

    var r2 = color_get_red(col2);
    var g2 = color_get_green(col2);
    var b2 = color_get_blue(col2);

    var r = lerp(r1, r2, t);
    var g = lerp(g1, g2, t);
    var b = lerp(b1, b2, t);

    return make_color_rgb(r, g, b);
}
