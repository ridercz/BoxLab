/************************************************************************************************************************
 * BoxLab PCB Standoff R2                                                                                  (2024-07-20) *
 * -------------------------------------------------------------------------------------------------------------------- *
 * This is simple standoff for PCBs. It has four corner holes and four pillars, connected with a frame with optional    *
 * cross braces. The frame can be used to hold the PCB in place. The design is parametric and can be easily adjusted.   *
 * -------------------------------------------------------------------------------------------------------------------- *
 * Copyright (c) Michal Altair Valasek, 2024 | Licensed under terms of the MIT license.                                 *
 *               https://www.rider.cz | https://www.altair.blog | https://github.com/ridercz/BoxLab                     *
 ************************************************************************************************************************/

include <A2D.scad>; // https://github.com/ridercz/A2D
assert(a2d_required([1, 6, 2]), "Please upgrade A2D library to version 1.6.2 or higher.");

/* [Corner holes] */
hole_span = [49, 58];
hole_diameter = 2.2;

/* [Pillars] */
pillar_height = 5;
pillar_wall = 1.67;

/* [Base] */
base_height = 1.5;
base_center = [20, 25];
brace_forward = true;
brace_backkward = true;
frame_thickness = 0;

/* [Hidden] */
$fn = 32;
$fudge = 1;
pillar_positions = square_points(hole_span, center = true);
pillar_diameter = hole_diameter + 2 * pillar_wall;
outer_size = hole_span + [pillar_diameter, pillar_diameter];
echo(outer_size = outer_size);
echo(pillar_diameter = pillar_diameter);

difference() {
    union() {
        linear_extrude(height = base_height) {
            // Outer frame
            thickness = frame_thickness == 0 ? pillar_diameter : frame_thickness;
            rh_square(outer_size, radius = pillar_diameter / 2,  thickness = -thickness, center = true);

            // Cross brace
            if(brace_forward) hull() for(i = [0, 2]) translate(pillar_positions[i]) circle(d = pillar_diameter);
            if(brace_backkward) hull() for(i = [1, 3]) translate(pillar_positions[i]) circle(d = pillar_diameter);

            // Center
            if(base_center.x > 0 && base_center.y > 0 && (brace_forward || brace_backkward)) square(base_center, center = true);
        }

        // Pillars
        for(pillar_position = pillar_positions) translate(pillar_position) cylinder(d = pillar_diameter, h = pillar_height);
    }
    for(pillar_position = pillar_positions) translate([pillar_position.x, pillar_position.y, -$fudge]) cylinder(d = hole_diameter, h = pillar_height + 2 * $fudge);
}