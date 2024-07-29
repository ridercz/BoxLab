/************************************************************************************************************************
 * BoxLab Status Display R4                                                                                (2024-07-29) *
 * -------------------------------------------------------------------------------------------------------------------- *
 * This is simple status display for the BoxLab project. Consists of the PCD8544 LCD module (Nokia 5110) and Wemos D1   *
 * Mini ESP8266 module. The display is mounted on the top of the BoxLab and shows the current status of the device.     *
 * I am aware of two versions of the display. This is for bigger PCB version (43 x 46 mm). Use the R3 version for the   *
 * smaller PCB (43 x 42 mm).                                                                                             *
 * -------------------------------------------------------------------------------------------------------------------- *
 * Copyright (c) Michal Altair Valasek, 2024 | Licensed under terms of the MIT license.                                 *
 *               https://www.rider.cz | https://www.altair.blog | https://github.com/ridercz/BoxLab                     *
 ************************************************************************************************************************/

include <A2D.scad>; // https://github.com/ridercz/A2D
assert(a2d_required([1, 6, 2]), "Please upgrade A2D library to version 1.6.2 or higher.");

/* Configuration *****************************************************************************************************/

/* [Display] */
layout = "preview"; // [preview, print, template]
part_spacing = 3;

/* [Template] */
template_only = false;
template_height = .6;
template_cut_offset = .5;

/* [Panel] */
panel_size = [74, 64];
panel_corner_radius = 5;
panel_thickness = 2.6;
panel_lcd_thickness = .6;
panel_screw_hole_diameter = 3.5;
panel_screw_head_diameter = 5.5;
panel_screw_head_height = 1.8;

/* [Panel labels] */
label_text_top = "BOXLAB STATUS";
label_text_size_top = 6.5;
label_text_bottom = "www.lazyhorse.net";
label_text_size_bottom = 5.5;
label_text_font = "Signika Negative, Arial :bold";
label_text_extr = .4;

/* [Riser] */
riser_clearance = 9;
riser_thickness = 2.2;
riser_holes = 3;
esp_size = [15, 12];
esp_distance = 12;
esp_contacts_size = [22, 2.5];
esp_contacts_distance = [7, 4];    

/* [Display module size] */
lcd_pcb_hole_span = [34.5, 40.5];
// Offset of the holes from the center
lcd_pcb_hole_offset = [0, 4];
lcd_pcb_hole_diameter = 2.9;
lcd_pcb_pillar_wall = 1.67;
lcd_box_size = [40.5, 34.5, 3.5];
lcd_size = [34, 24];
// Offset of the LCD from center
lcd_offset = [0, 4];
lcd_radius = 2;

/* Computed variables *************************************************************************************************/

/* [Hidden] */
$fudge = 1;
$fn = 32;
panel_holes = square_points([panel_size.x - 2 * panel_corner_radius, panel_size.y - 2 * panel_corner_radius], center = true);
pcb_holes = translate_points(square_points(lcd_pcb_hole_span, center = true), lcd_pcb_hole_offset);
pcb_pillar_diameter = lcd_pcb_hole_diameter + 2 * lcd_pcb_pillar_wall;
riser_pillars = translate_points(square_points(lcd_pcb_hole_span), [pcb_pillar_diameter / 2, pcb_pillar_diameter / 2]);
riser_size = [lcd_pcb_hole_span.x + pcb_pillar_diameter, lcd_pcb_hole_span.y + pcb_pillar_diameter];
riser_cutout_size_y = esp_size.y + 2 * esp_contacts_distance.y + 2 * esp_contacts_size.y;

/* Render ************************************************************************************************************/

if(layout == "preview") {
    part_panel();
    translate(v = [lcd_pcb_hole_offset.x , lcd_pcb_hole_offset.y, -(riser_thickness + riser_clearance + 5)]) part_riser();
} else if(layout == "template") {
    part_template();
} else if(layout == "print") {
    translate(v = [0, 0, panel_thickness]) rotate([180, 0, 180]) part_panel();
    translate(v = [0, -(panel_size.y + riser_size.y) / 2 - part_spacing]) part_riser();
}

/* Parts *************************************************************************************************************/

module part_riser() {
    translate(v = -riser_size / 2)  difference() {
        union() {
            // Riser base plate
            linear_extrude(height = riser_thickness) difference() {
                hull() for (pos = riser_pillars) translate(pos) difference() circle(d = pcb_pillar_diameter);

                // Holes for ESP module and contacts
                translate(v = [0, (riser_size.y - riser_cutout_size_y) / 2]) {
                    translate(v = [esp_contacts_distance.x, esp_size.y + 2 * esp_contacts_distance.y + esp_contacts_size.y]) square(size = esp_contacts_size);
                    translate(v = [esp_distance, esp_contacts_distance.y + esp_contacts_size.y]) square(size = esp_size);
                    translate(v = [esp_contacts_distance.x, 0]) square(size = esp_contacts_size);
                } 
            }
            // Pillars
            for (pos = riser_pillars) translate(pos) difference() cylinder(d = pcb_pillar_diameter, h = riser_clearance + riser_thickness);
        }
        for (pos = riser_pillars) translate([pos.x, pos.y, -$fudge]) cylinder(d = riser_holes, h = riser_thickness + riser_clearance + 2 * $fudge);
    }
}


module part_template() {
    linear_extrude(height = template_height) difference() {
        // Main panel shape
        r_square(panel_size, panel_corner_radius, center = true);

        // Screw holes
        for(pos = panel_holes) translate(pos) circle(d = panel_screw_hole_diameter);

        // LCD box cutout
        translate([lcd_offset.x, lcd_offset.y]) square([lcd_box_size.x, lcd_box_size.y], center = true);

        // PCB screws
        hull() for(pos = pcb_holes) translate(pos) circle(d = pcb_pillar_diameter);
    }
}

module part_panel() {
    difference() {
        union() {
            // Extruded 2D shape
            linear_extrude(height = panel_thickness) difference() {
                // Main panel shape
                r_square(panel_size, panel_corner_radius, center = true);

                // Screw holes
                for(pos = panel_holes) translate(pos) circle(d = panel_screw_hole_diameter);

                // LCD cutout
                r_square(lcd_size, lcd_radius, center = true);
            }
            // Pillars
            for(pos = pcb_holes) translate([pos.x, pos.y, panel_thickness - panel_lcd_thickness - lcd_box_size.z]) cylinder(d = pcb_pillar_diameter, h = lcd_box_size.z);
        }

        // Panel screw heads
        for(pos = panel_holes) translate([pos.x, pos.y, panel_thickness - panel_screw_head_height]) cylinder(d = panel_screw_head_diameter, h = panel_screw_head_height + $fudge);

        // LCD box cutout
        translate([lcd_offset.x, lcd_offset.y, panel_thickness - lcd_box_size.z / 2 - panel_lcd_thickness]) cube(lcd_box_size, center = true);

        // Pillar holes
        for(pos = pcb_holes) translate([pos.x, pos.y, panel_thickness - panel_lcd_thickness - lcd_box_size.z - $fudge]) cylinder(d = lcd_pcb_hole_diameter, h = lcd_box_size.z + $fudge);

        // Top label
        translate([0, +(panel_size.y - lcd_size.y) * .45, panel_thickness - label_text_extr]) linear_extrude(height = $fudge + label_text_extr) text(text = label_text_top, size = label_text_size_top, font = label_text_font, halign = "center", valign = "center");

        // Bottom label
        translate([0, -(panel_size.y - lcd_size.y) * .50, panel_thickness - label_text_extr]) linear_extrude(height = $fudge + label_text_extr) text(text = label_text_bottom, size = label_text_size_bottom, font = label_text_font, halign = "center", valign = "center");
    }
}