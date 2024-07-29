/************************************************************************************************************************
 * BoxLab C14 connector cutout template                                                                    (2024-07-06) *
 * -------------------------------------------------------------------------------------------------------------------- *
 * This is template for cutting hole for the IEC C14 connector.                                                         *
 * -------------------------------------------------------------------------------------------------------------------- *
 * Copyright (c) Michal Altair Valasek, 2024 | Licensed under terms of the MIT license.                                 *
 *               https://www.rider.cz | https://www.altair.blog | https://github.com/ridercz/BoxLab                     *
 ************************************************************************************************************************/

outer_size = [60, 26];
inner_size = [27, 19];
screw_hole_diameter = 3.5;
screw_hole_span = 40;
thickness = 1.5;

main_hole_points = [
    [00, 19],
    [27, 19],
    [27, 05],
    [22, 00],
    [05, 00],
    [00, 05],
];

linear_extrude(height = thickness) difference() {
    // Outer template shape
    square(outer_size, center = true);
    // Main hole
    translate(inner_size / -2) polygon(points = main_hole_points);
    // Screw holes
    for(xpos = [-screw_hole_span/2, screw_hole_span/2]) translate([xpos, 0]) circle(d = screw_hole_diameter, $fn = 32);
}