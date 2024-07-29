include <A2D.scad>; // https://github.com/ridercz/A2D
assert(a2d_required([1, 6, 2]), "Please upgrade A2D library to version 1.6.2 or higher.");

/* [Preview] */
// Show in print position
print_position = false;

/* [Plate] */
// Render only the cutting and drilling template
template_only = false;
// Spacing around the slot block, [top, right, bottom, left]
plate_padding = [29.5, 10.5, 5, 10.5];
// Plate corner radius
plate_radius = 5;
// Thickness of the plate
plate_thickness = 2.6;

/* [Screw holes] */
// Diameter of the screw holes, 0 to disable
screw_hole_diameter = 3.5;
screw_head_diameter = 5.5;
screw_head_height = 1.8;
// Make central holes as well
add_top_hole = true;
add_bottom_hole = false;
add_left_hole = false;
add_right_hole = false;

/* [Slots] */
// Slot block definition, [type, argument]
// Type "keystone" - Keystone jack slot, argument is the label
// Type "spacer" - Spacer slot, argument is the width
slots = [
  ["keystone", "WAN"],
  ["spacer", 3],
  ["keystone", "LAN 1"],
  ["keystone", "LAN 2"],
  ["keystone", "LAN 3"],
  ["spacer", 3],
  ["keystone", "EXT A"],
  ["keystone", "EXT B"],
];

/* [Text] */
slot_text_size = 8;
slot_text_font = "Signika Negative, Arial :bold";
slot_text_extr = .4;
slot_text_xoff = 25;
slot_text_rotate = 90;

label_text = "";
label_text_font = "Signika Negative, Arial :bold";
label_text_size = 7;
label_text_extr = .4;
label_text_xoff = 45;

/* [Hidden] */
$fn = 32;
$fudge = 1;

// Keystone block dimensions
ks_jack_length = 16.5;
ks_jack_width = 15;
ks_wall_thickness = 4;
ks_catch_overhang = 2;
ks_size = [
  ks_jack_length + ks_catch_overhang + ks_catch_overhang + 2 + (ks_wall_thickness * 2), 
  ks_jack_width + (ks_wall_thickness * 2), 
  10
];

// Total size
total_slot_size = [ks_size.x, slot_offset(len(slots)), ks_size.z];
total_plate_size = [total_slot_size.x + plate_padding[0] + plate_padding[2], total_slot_size.y + plate_padding[1] + plate_padding[3], plate_thickness];

// Screw hole positions
corner_hole_span = [total_plate_size.x - 2 * plate_radius, total_plate_size.y - 2 * plate_radius];
hole_pos_def = [
  square_points(corner_hole_span), 
  add_bottom_hole ? [[0, corner_hole_span.y / 2]] : [],
  add_top_hole ? [[corner_hole_span.x, corner_hole_span.y / 2]] : [],
  add_right_hole ? [[corner_hole_span.x / 2, corner_hole_span.y]] : [],
  add_left_hole ? [[corner_hole_span.x / 2, 0]] : [],
];
screw_hole_pos = translate_points([for(l = hole_pos_def, a = l) a], [-plate_padding[2] + plate_radius, -plate_padding[3] + plate_radius]);

/* Print configuration ***********************************************************************************************/

echo(total_slot_size = total_slot_size);
echo(total_plate_size = total_plate_size);
if(screw_hole_diameter > 0) echo(corner_hole_span = corner_hole_span);

/* Render ************************************************************************************************************/

translate(print_position ? [0,0,0] : [total_slot_size.y + plate_padding.y, total_slot_size.x + plate_padding.x, ks_size.z]) rotate(print_position ? [0, 0, -90] : [0, 180, 90]) difference() {
  union() {
    // Keystone block
    if(!template_only) for(index = [0 : len(slots) - 1]) {
      echo(slot = slots[index], offset = slot_offset(index));
      translate([0, slot_offset(index)]) {
        if(slots[index][0] == "keystone") {
          assert(is_string(slots[index][1]), "WARNING: Keystone slot must have a string as the second argument.");
          keystone();
        } else if(slots[index][0] == "spacer") {
          assert(is_num(slots[index][1]), "WARNING: Spacer slot must have a number as the second argument.");
          cube([ks_size.x, slots[index][1], ks_size.z]);
        } else {
          assert(false, "WARNING: Unknown slot type: ", slots[index][0]);
        }
      }
    }

    // Plate
    linear_extrude(height = plate_thickness) difference() {
      // Outside plare
      translate([-plate_padding[2], -plate_padding[3]]) r_square([total_plate_size.x, total_plate_size.y], plate_radius);
      
      // Keystone block hole
      square([total_slot_size.x, total_slot_size.y]);
    }
  }

  // Screw holes
  if(screw_hole_diameter > 0) for(pos = screw_hole_pos) translate([pos[0], pos[1], -$fudge]) {
    cylinder(d = screw_hole_diameter, h = ks_size.z + 2 * $fudge);
    if(screw_head_diameter > 0 && screw_head_height > 0) cylinder(d = screw_head_diameter, h = screw_head_height + $fudge);
  }

  if(!template_only) {
    // Slot text
    for(index = [0 : len(slots) - 1]) translate([slot_text_xoff, slot_offset(index) + (slots[index][0] == "keystone" ? ks_size.y / 2 : slots[index][1] / 2), -$fudge]) linear_extrude(height = slot_text_extr + $fudge) mirror([0, 1, 0]) text(text = slots[index][1], size = slot_text_size, font = slot_text_font, halign = "left", valign = "center");

    // Label text
    if(label_text != "") translate([label_text_xoff, total_slot_size.y / 2, -$fudge]) linear_extrude(height = label_text_extr + $fudge) mirror([0, 1, 0]) rotate(-90) text(text = label_text, size = label_text_size, font = label_text_font, halign = "center", valign = "bottom");
  }
}

/* Modules ***********************************************************************************************************/

module keystone() {
  // Inspired by public domain code by Joe Sadusk
  // https://www.thingiverse.com/thing:6647/files

  difference() {
    difference() {
      cube([ks_size.x, ks_size.y, ks_size.z]);
      translate([ks_wall_thickness, ks_wall_thickness, 2]) cube([ks_size.x, ks_jack_width, ks_size.z]);
    }
    translate([ks_wall_thickness + ks_catch_overhang, ks_wall_thickness, -$fudge]) cube([ks_jack_length, ks_jack_width, ks_size.z + 2 * $fudge]);
  }

  cube([ks_wall_thickness, ks_size.y, ks_size.z]);
  cube([ks_wall_thickness + ks_catch_overhang, ks_size.y, 6.5]);

  translate([2, 23, 8]) ks_clip_catch();
  translate([26.5,0,0]) cube([4, 23, 10]);
  translate([29.5, 0, 8]) rotate([0, 0, -180]) ks_clip_catch();
}

module ks_clip_catch() {
  rotate([90, 0, 0]) linear_extrude(height = ks_size.y) polygon(points = [[0, 0], [ks_catch_overhang, 0], [ks_wall_thickness, ks_catch_overhang], [0, ks_catch_overhang]]);
}

/* Functions *********************************************************************************************************/

function slot_offset(index) = index == 0 ? 0 : ((slots[index - 1][0] == "keystone" ? ks_size.y : slots[index - 1][1]) + slot_offset(index - 1));