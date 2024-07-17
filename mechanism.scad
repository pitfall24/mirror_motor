//
// mirror motor mechanics (gears etc.)
//

use<mirror_M05.scad>;
use<mini_stepper.scad>;
use<gears.scad>;

$fn = 64;

hex_ratio = 2 / sqrt(3);
tol_box_tolerance = 0.2;

module axles(tol_boxes = false, tol = tol_box_tolerance / 2) {
    // top-left axle
    translate([3.556, 1, 21.85]) rotate([90, 0, 0]) {
        color("gray") cylinder(d = 2 * hex_ratio, h = 15, $fn = 6);
        if (tol_boxes) color("orange") translate([0, - tol, 0]) cylinder(d = 2 * hex_ratio + 2 * tol, h = 15 + 2 * tol);
    }
    
    // bottom-right axle
    color("gray") translate([21.85, 1, 3.556]) rotate([90, 0, 0]) cylinder(d = 2 * hex_ratio, h = 23, $fn = 6);
    if (tol_boxes) color("orange") translate([21.85, 1, 3.556 - tol]) rotate([90, -12.5, 0]) cylinder(d = 2 * hex_ratio + 2 * tol, h = 23 + 2 * tol);
}

module bevel_gears(singular = false, hex_bore = true, set_screw = false, axle_tol = 0) {
    difference() {
        if (singular) {
            bevel_gear(modul = 0.5, tooth_number = 13, partial_cone_angle = 45, tooth_width = 2, bore = hex_bore ? 1.5 : 2);
        } else {
            bevel_gear_pair(modul = 0.5, gear_teeth = 13, pinion_teeth = 13, axis_angle = 90, tooth_width = 2, gear_bore = hex_bore ? 1.5 : 2, pinion_bore = hex_bore ? 1.5 : 2, together_built = true);
        }
        if (hex_bore) {
            if (!singular) {
                translate([-4, 0, 3.635]) rotate([0, -90, 180]) cylinder(d = 2 * hex_ratio + axle_tol, h = 3, $fn = 6);
            }
            translate([0, 0, -1]) cylinder(d = 2 * hex_ratio + axle_tol, h = 3, $fn = 6);
        }
    }
    
    difference() {
        translate([0, 0, -3]) cylinder(d = 5, h = 3);
        union() {
            translate([0, 0, -3.1]) cylinder(d = 2 * (hex_bore ? hex_ratio : 1) + axle_tol, h = 5, $fn = hex_bore ? 6 : $fn);
            if (set_screw) translate([0, 0, -1.5]) rotate([90, 0, 0]) cylinder(d = 2 /*1.588*/, h = 3);
        }
    }
    
    if (!singular) {
        difference() {
            translate([-(3 + 3.635), 0, 3.635]) rotate([0, -90, 180]) cylinder(d = 5, h = 3);
            union() {
                translate([-(3.1 + 3.635), 0, 3.635]) rotate([0, -90, 180]) cylinder(d = 2 * (hex_bore ? hex_ratio : 1) + axle_tol, h = 5, $fn = hex_bore ? 6 : $fn);
                if (set_screw) translate([-(1.5 + 3.635), 0, 3.635]) rotate([90, 0, 0]) cylinder(d = 2 /*1.588*/, h = 3);
            }
        }
    }
}

module single_gear(breadth = 18, teeth = 50, lower_spacer = true, axle_tol = 0, tol_boxes = false) {
    difference() {
        union() {
            color("darkgreen") spur_gear(modul = breadth / teeth, tooth_number = teeth, width = 2, bore = 2 + axle_tol, optimized = false);
            if (lower_spacer) color("darkgreen") translate([0, 0, -2]) cylinder(d = 5, h = 2.05);
            
            if (tol_boxes) color("orange") {
                translate([0, 0, -0.05]) cylinder(d = breadth + 1, h = 2.1);
                if (lower_spacer) translate([0, 0, -2.05]) cylinder(d = 5.1, h = 2.1);
            }
        }
        
        translate([0, 0, -2.1]) cylinder(d = 2 * hex_ratio + axle_tol, h = 10, $fn = 6);
    }
}

module double_gear(outer_breadth = 13, outer_teeth = 50, inner_breadth = 4.32, inner_teeth = 12, axle_tol = 0, tol_boxes = false) {
    difference() {
        union() {
            color("lime") spur_gear(modul = outer_breadth / outer_teeth, tooth_number = outer_teeth, width = 2, bore = 2 + axle_tol, optimized = false);
            translate([0, 0, 1.95]) color("limegreen") spur_gear(modul = inner_breadth / inner_teeth, tooth_number = inner_teeth, width = 2.05, bore = 2 + axle_tol, optimized = false);
            
            if (tol_boxes) color("orange") {
                translate([0, 0, -0.05]) cylinder(d = outer_breadth + 1, h = 2.1);
                translate([0, 0, 1.95]) cylinder(d = inner_breadth + 1, h = 2.1);
            }
        }
        
        translate([0, 0, -0.1]) cylinder(d = 2 * hex_ratio + axle_tol, h = 10, $fn = 6);
    }
}

module arranged_gear_pair(breadths = [18, 13, 4.32], teeths = [50, 50, 12], lower_spacer = true, axle_tol = 0, tol_boxes = false) {
    single_breadth = breadths[0];
    outer_breadth = breadths[1];
    inner_breadth = breadths[2];
    
    single_teeth = teeths[0];
    outer_teeth = teeths[1];
    inner_teeth = teeths[2];
    
    single_gear(breadth = single_breadth, teeth = single_teeth, lower_spacer = lower_spacer, axle_tol = axle_tol, tol_boxes = tol_boxes);
    translate([0, 18 / 2 + 4.32 / 2, -2]) double_gear(outer_breadth = outer_breadth, outer_teeth = outer_teeth, inner_breadth = inner_breadth, inner_teeth = inner_teeth, axle_tol = axle_tol, tol_boxes = tol_boxes);
}

module mechanism(tol_boxes = false, axle_tol = 0) {
    axles(tol_boxes = tol_boxes); // main controlling axles
    
    // vertical miter gear axle
    color("gray") translate([21.85, -14.635, 5]) rotate([0, 0, 30]) cylinder(d = 2 * hex_ratio, h = 15, $fn = 6);
    if (tol_boxes) color("orange") translate([21.85, -14.635, 5]) cylinder(d = 2 * hex_ratio + tol_box_tolerance, h = 15 + tol_box_tolerance);
    
    // bottom-right gear train
    translate([21.85, -11, 3.556]) {
        rotate([90, 90, 0]) bevel_gears(hex_bore = true, set_screw = false, axle_tol = axle_tol);
        
        // miter gears tol boxes
        color("orange") if (tol_boxes) {
            translate([0, 3 + tol_box_tolerance / 2, 0]) rotate([90, 0, 0]) cylinder(d = 7 + tol_box_tolerance, h = 5 + tol_box_tolerance);
            translate([0, -3.635, 1.635]) cylinder(d = 7 + tol_box_tolerance, h = 5 + tol_box_tolerance);
        }
        
        
        translate([0, -3.635, 6.6]) {
            rotate([0, 0, 90]) arranged_gear_pair(lower_spacer = false, axle_tol = axle_tol, tol_boxes = tol_boxes);
            translate([-11.16 + 7.5 * cos(225), 7.5 * sin(225), 10.75]) rotate([180, 0, 90]) mini_stepper(tol_boxes = tol_boxes);
            
            // bottom-right gear pair axle
            color("gray") translate([-11.16, 0, -6]) rotate([0, 0, 30]) cylinder(d = 2 * hex_ratio, h = 12, $fn = 6);
            if (tol_boxes) color("orange") translate([-11.16, 0, -6 - tol_box_tolerance / 2]) cylinder(d = 2 * hex_ratio + tol_box_tolerance, h = 16 + tol_box_tolerance);
        }
    }
    
    // top-left gear train
    translate([3.556, -9, 21.85]) {
        translate([0, 0, 0]) rotate([90, 0, 0]) arranged_gear_pair(axle_tol = axle_tol, tol_boxes = tol_boxes); 
        translate([0, -10.75, 18.7]) rotate([-90, 45, 0]) mini_stepper(tol_boxes = tol_boxes);
        
        // top-left gear pair axle
        color("gray") translate([0, 6, 11.16]) rotate([90, 0, 0]) cylinder(d = 2 * hex_ratio, h = 12, $fn = 6);
    }
}

module parts_to_print(hex_bore = true, set_screw = false, custom_gears = true, include_miter = true, axle_tol = 0) {
    // miter gears
    if (include_miter) {
        translate([0, 0, 3]) bevel_gears(singular = true, hex_bore = hex_bore, set_screw = set_screw, axle_tol = axle_tol);
        translate([15, 0, 4.99]) bevel_gears(singular = true, hex_bore = hex_bore, set_screw = set_screw, axle_tol = axle_tol);
    }
    
    mod = custom_gears ? 12 / 39 : 8 / 29;
    num = custom_gears ? 39 : 29;
    wid = custom_gears ? 2 : 4;
    
    difference() {
        union() {
            //translate([0, 15, 0]) spur_gear(modul = mod, tooth_number = num, width = wid, bore = 2 + axle_tol, optimized = false);
            //translate([0, 15, 1.95]) cylinder(d = 5, h = 3.05);
            
            translate([15, 0, 0]) spur_gear(modul = mod, tooth_number = num, width = wid, bore = 2 + axle_tol, optimized = false);
        }
        
        translate([0, 15, -1]) cylinder(d = 2 * hex_ratio + axle_tol, h = 8, $fn = hex_bore ? 6 : $fn);
        translate([15, 15, -1]) cylinder(d = 2 * hex_ratio + axle_tol, h = 8, $fn = hex_bore ? 6 : $fn);
    }
    
    translate([20, 20, 2]) rotate([180, 0, 0]) single_gear(axle_tol = axle_tol);
    translate([0, 20, 0]) double_gear(axle_tol = axle_tol);
}

mechanism(tol_boxes = false, axle_tol = -0.2);
import_mirror();

//parts_to_print(axle_tol = -0.2);































// asdf
