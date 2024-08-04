//
// mirror motor mechanics (gears etc.)
//

use<mirror_M05.scad>;
use<mini_stepper.scad>;
use<gears.scad>;
use<util.scad>;

$fn = 64;

hex_ratio = 2 / sqrt(3);
center_stepper = 0.853;

module axles(tl_len = 10, br_len = 10, tol_boxes = false, tol = 0) {  
    // top-left axle
    translate([3.556, 1, 21.85]) rotate([90, 0, 0]) {
        if (tol_boxes) {
            color("orange") cylinder(d = 2 * hex_ratio + tol, h = tl_len + tol / 2);
        } else {
            color("gray") cylinder(d = 2 * hex_ratio, h = tl_len, $fn = 6);
        }
    }
    
    // bottom-right axle
    translate([21.85, 1, 3.556]) rotate([90, 0, 0]) {
        if (tol_boxes) {
            color("orange") cylinder(d = 2 * hex_ratio + tol, h = br_len + tol / 2);
        } else {
            color("gray") cylinder(d = 2 * hex_ratio, h = br_len, $fn = 6);
        }
    }
}

module normal_tl_gear(for_stepper = false, axle_tol = 0) {
    _render("green", false) difference() {
        if (for_stepper) {
            spur_gear(modul = 0.5, tooth_number = 15, width = 4, bore = 0, optimized = false);
        } else {
            spur_gear(modul = 0.5, tooth_number = 45, width = 4, bore = 0, optimized = false);
        }
        
        if (for_stepper) {
            translate([0, 0, -3.1]) rotate([90, 0, 0]) mini_stepper(main_ax_tol = axle_tol);
        } else {
            translate([0, 0, -0.1]) cylinder(d = 2 * hex_ratio + axle_tol, h = 4.2, $fn = 6);
        }
    }
}

module br_gears(axle_tol = 0) {
    translate([0, 0, 0]) spur_gear(modul = 0.4, tooth_number = 15, width = 4, bore = 0, optimized = false); // small primary br-axle gear
    
    translate([0, 9, 0]) spur_gear(modul = 0.4, tooth_number = 30, width = 4, bore = 0, optimized = false); // medium secondary gear
    translate([0, 9, 9]) spur_gear(modul = 0.5, tooth_number = 45, width = 4, bore = 0, optimized = false); // large secondary gear
    
    translate([center_stepper / 2, 23.25, 9]) spur_gear(modul = 0.5, tooth_number = 12, width = 4, bore = 0, optimized = false); // small tertiary gear
    translate([center_stepper / 2, 23.25, 5]) spur_gear(modul = 0.5, tooth_number = 24, width = 4, bore = 0, optimized = false); // medium tertiary gear
    
    translate([center_stepper, 33, 5]) spur_gear(modul = 0.5, tooth_number = 15, width = 4, bore = 0, optimized = false);
}

module mechanism(off_angle = 8, tol_boxes = false, stepper_ax_tol = 0, hori_axle_tol = -0.015, tolerance = 0) {
    axles(tl_len = 25, br_len = 15, tol_boxes = tol_boxes, tol = hori_axle_tol); // main controlling axles
    
    tl_hyp = sqrt(15 * 15 + center_stepper * center_stepper);
    tl_angle = abs(atan(15 / center_stepper));
    
    br_hyp = sqrt(0 * 0 + center_stepper * center_stepper);
    br_angle = abs(atan(0 / center_stepper));
    
    // bottom-right gear train
    translate([21.85, -6, 3.556]) {
        _render("green", false) translate([0, -0.5, 0]) rotate([90, 0, 0]) br_gears(axle_tol = hori_axle_tol);
        
        translate([center_stepper, 3, 33]) rotate([0, 180, 180]) mini_stepper(main_ax_tol = stepper_ax_tol, tol_boxes = tol_boxes);
    }
    
    // top-left gear train
    translate([3.556, -6, 21.85]) {
        if (tol_boxes) {
            color("orange") translate([0, -5 - tolerance / 2, 15]) rotate([90, 0, 0]) cylinder(d = 16.1 + tolerance, h = 4 + tolerance);
            color("orange") translate([0, -5 - tolerance / 2, 0]) rotate([90, 0, 0]) cylinder(d = 16.1 + tolerance, h = 4 + tolerance);
        } else {
            translate([-center_stepper, -5, 15 * sin(tl_angle)]) rotate([90, 0, 0]) normal_tl_gear(for_stepper = true, axle_tol = stepper_ax_tol);
            translate([0, -5, 0]) rotate([90, 3.66, 0]) normal_tl_gear(for_stepper = false, axle_tol = hori_axle_tol);
        }
        
        translate([-center_stepper, 3, 15 * sin(tl_angle)]) rotate([0, 180, 180]) mini_stepper(main_ax_tol = stepper_ax_tol, tol_boxes = tol_boxes);
        echo(tl_angle);
    }
}

module parts_to_print(axle_tol = 0, stepper_tol = 0) { // TODO: alternates for the bottom-right primary gears
    // miter gears
    translate([0, 0, 3]) bevel_gears(singular = true, axle_tol = axle_tol, wide = false);
    translate([20, 0, 5]) bevel_gears(singular = true, axle_tol = stepper_tol, wide = true);
    
    translate([0, 15, 0]) normal_tl_gear(for_stepper = false, axle_tol = axle_tol);
    translate([20, 15, 0]) normal_tl_gear(for_stepper = true, axle_tol = stepper_tol);
}

module stepper_axle_tols() {
    difference() {
        cube([9, 52, 10]);
        
        dict = [0.5, 0.25, 0, -0.05, -0.1, -0.15, -0.25, -0.35];
        dy = 6;
        for (i = [0:len(dict) - 1]) {
            tol = dict[i];
            
            translate([4.5, dy * (i + 1), -1.5]) rotate([90, 0, 0]) mini_stepper(main_ax_tol = tol);
            translate([0.5, dy * (i + 1) - 1.5, 0.5]) rotate([0, -90, 0]) linear_extrude(height = 2) text(text = str(tol), size = 3);
        }
    }
}

//parts_to_print(axle_tol = -0.14, stepper_tol = -0.03);

mechanism(tol_boxes = false);
//mechanism(tol_boxes = true, stepper_ax_tol = 0);

import_mirror(convexity = 1);






















































//asdf
