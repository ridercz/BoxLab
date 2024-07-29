/************************************************************************************************************************
 * BoxLab Status Display R3                                                                                (2024-07-20) *
 * -------------------------------------------------------------------------------------------------------------------- *
 * This is simple status display for the BoxLab project. Consists of the PCD8544 LCD module (Nokia 5110) and Wemos D1   *
 * Mini ESP8266 module. The display is mounted on the top of the BoxLab and shows the current status of the device.     *
 * I am aware of two versions of the display. This is for smaller PCB version (43 x 42 mm). Use the R4 version for the  *
 * bigger PCB (43 x 46 mm).                                                                                             *
 * -------------------------------------------------------------------------------------------------------------------- *
 * Copyright (c) Michal Altair Valasek, 2024 | Licensed under terms of the MIT license.                                 *
 *               https://www.rider.cz | https://www.altair.blog | https://github.com/ridercz/BoxLab                     *
 ************************************************************************************************************************/

include <A2D.scad>; // https://github.com/ridercz/A2D
assert(a2d_required([1, 6, 2]), "Please upgrade A2D library to version 1.6.2 or higher.");

/* Configuration *****************************************************************************************************/

/* [Template] */
template_only = false;
template_height = .6;
template_cut_offset = .5;

/* [Panel] */
panel_padding = 20;
panel_corner_radius = 5;
panel_thickness = 2.6;
panel_lcd_thickness = .6;
total_thickness = 10;

/* [Panel screws] */
screw_hole_diameter = 3.5;
screw_head_diameter = 5.5;
screw_head_height = 1.8;

/* [PCB screws] */
pcb_pillar_hole_diameter = 2.2;
pcb_pillar_wall = 1.67;

/* [Labels] */
label_text_top = "LAZYHORSE.NET";
label_text_size_top = 5;
label_text_bottom = "BOXLAB STATUS";
label_text_size_bottom = 5;
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
pcb_size = [44, 43];
pcb_hole_diameter = 2.2;
pcb_hole_span = [40, 39];
lcd_box_size = [40.5, 34.5, 3.5];
lcd_size = [34,24];
lcd_radius = 3;
lcd_box_offset = [2, 4.5];
lcd_offset = [5, 7];

/* Computed variables *************************************************************************************************/

/* [Hidden] */
$fudge = 1;
$fn = 32;
panel_size = [panel_padding * 2 + lcd_size.x, panel_padding * 2 + lcd_size.y];
panel_offset = [-(panel_padding - lcd_offset.x), -(panel_padding - lcd_offset.y)];
panel_hole_pos = translate_points(square_points([panel_size.x - 2 * panel_corner_radius, panel_size.y - 2 * panel_corner_radius]), panel_offset + [panel_corner_radius, panel_corner_radius]);
pcb_pillar_diameter = pcb_pillar_hole_diameter + pcb_pillar_wall * 2;
pcb_pillar_pos = translate_points(square_points(pcb_hole_span), [(pcb_size.x - pcb_hole_span.x) / 2, (pcb_size.y - pcb_hole_span.y) / 2]);
label_offset_x = panel_size.x / 2 - panel_padding + lcd_offset.x;
label_offset_y_bottom = panel_offset.y + (panel_size.y - lcd_size.y) / 4;
label_offset_y_top = panel_size.y - (panel_size.y - lcd_size.y) / 4 + panel_offset.y;

echo(panel_size = panel_size);

/* Model *************************************************************************************************************/

if(template_only) {
    part_template();
} else {
    part_panel();
    translate([panel_size.x + 5, 0]) part_riser();
}

/* Parts *************************************************************************************************************/

module part_template() {
    translate(v = -panel_offset) linear_extrude(height = template_height) difference() {
        translate(v = panel_offset) r_square([panel_size.x, panel_size.y], radius = panel_corner_radius);
        for(pos = panel_hole_pos) translate(pos) circle(d = screw_hole_diameter + 2 * template_cut_offset);
        offset(template_cut_offset) hull() for (pos = pcb_pillar_pos) translate(pos) difference() circle(d = pcb_pillar_diameter);
    }
    translate(v = [panel_size.x / 2, panel_padding / 2 - lcd_box_offset.y, template_height]) linear_extrude(height = label_text_extr) text(text = "BOTTOM", size = 5, font = label_text_font, halign = "center", valign = "center");
}

module part_riser() {
    difference() {
        union() {
            // Riser base plate
            linear_extrude(height = riser_thickness) difference() {
                hull() for (pos = pcb_pillar_pos) translate(pos) difference() circle(d = pcb_pillar_diameter);

                // Holes for ESP module and contacts
                translate(v = [0, (pcb_size.y - esp_size.y) / 2]) {
                    translate(v = [esp_distance, 0]) square(size = esp_size);
                    translate(v = [esp_contacts_distance.x, esp_size.y + esp_contacts_distance.y]) square(size = esp_contacts_size);
                    translate(v = [esp_contacts_distance.x, -esp_contacts_distance.y - esp_contacts_size.y]) square(size = esp_contacts_size);
                } 
            }
            // Pillars
            for (pos = pcb_pillar_pos) translate(pos) difference() cylinder(d = pcb_pillar_diameter, h = riser_clearance + riser_thickness);
        }
        for (pos = pcb_pillar_pos) translate([pos.x, pos.y, -$fudge]) cylinder(d = riser_holes, h = riser_thickness + riser_clearance + 2 * $fudge);
    }
}

module part_panel() {
    translate(v = -panel_offset) {
        // Face plate
        difference() {
            // Panel with holes
            linear_extrude(height = panel_thickness) difference() {
                translate(v = panel_offset) r_square([panel_size.x, panel_size.y], radius = panel_corner_radius);
                translate(lcd_offset) r_square(lcd_size, radius = lcd_radius); 
                for(pos = panel_hole_pos) translate(pos) circle(d = screw_hole_diameter);
            }

            // LCD box cutout
            translate(v = [lcd_box_offset.x, lcd_box_offset.y, panel_lcd_thickness]) cube(lcd_box_size);

            // Panel screw heads
            for(pos = panel_hole_pos) translate([pos.x, pos.y, -$fudge]) cylinder(d = screw_head_diameter, h = screw_head_height + $fudge);

            // Labels
            translate(v = [label_offset_x, label_offset_y_top, -$fudge]) linear_extrude(height = $fudge + label_text_extr) rotate(180) mirror([0, 1, 0]) text(text = label_text_top, size = label_text_size_top, font = label_text_font, halign = "center", valign = "center");
            translate(v = [label_offset_x, label_offset_y_bottom, -$fudge]) linear_extrude(height = $fudge + label_text_extr) rotate(180) mirror([0, 1, 0]) text(text = label_text_bottom, size = label_text_size_bottom, font = label_text_font, halign = "center", valign = "center");
        }

        // PCB screw pillars
        for (pos = pcb_pillar_pos) translate([pos.x, pos.y]) difference() {
            translate([0, 0, panel_lcd_thickness]) cylinder(d = pcb_pillar_diameter, h = lcd_box_size.z);
            translate([0, 0, panel_lcd_thickness]) cylinder(d = pcb_pillar_hole_diameter, h = panel_thickness + lcd_box_size.z);
        }
    }
}