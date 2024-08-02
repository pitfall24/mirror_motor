//
// mirror motor mechanics (gears etc.)
//

use<mirror_M05.scad>;
use<mini_stepper.scad>;
use<gears.scad>;
use<util.scad>;

$fn = 64;

hex_ratio = 2 / sqrt(3);

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

module bevel_gears(singular = false, axle_tol = 0, wide = false) {
    difference() {
        if (singular) {
            bevel_gear(modul = 0.65, tooth_number = 10, partial_cone_angle = 45, tooth_width = 2.2, bore = 0);
        } else {
            bevel_gear_pair(modul = 0.65, gear_teeth = 10, pinion_teeth = 10, axis_angle = 90, tooth_width = 2.2, gear_bore = 0, pinion_bore = 0, together_built = true);
        }
        
        if (!wide) translate([-4, 0, 3.74]) rotate([0, -90, 180]) cylinder(d = 2 * hex_ratio + axle_tol, h = 4, $fn = 6);
        if (!wide || !singular) translate([0, 0, -1]) cylinder(d = 2 * hex_ratio + axle_tol, h = 4, $fn = 6);
    }
    
    if (singular && !wide || !singular) { // normal base if the whole thing is normal or if it isn't wide
        difference() { // vertical hex bore & extension
            translate([0, 0, -3]) cylinder(d = 5, h = 3);
            translate([0, 0, -3.1]) cylinder(d = 2 * hex_ratio + axle_tol, h = 5, $fn = 6);
        }
    } else {
        difference() {
            union() {
                translate([0, 0, -2.5]) cylinder(d1 = 8, d2 = 5, h = 2.5);
                translate([0, 0, -5]) cylinder(d = 8, h = 2.5);
            }
            
            translate([0, 0, -16.5]) rotate([90, 0, 0]) mini_stepper(main_ax_tol = axle_tol);
            translate([0, 0, -4.5]) cylinder(d = 2, h = 3 + axle_tol / 2);
        }
    }
    
    if (!singular) difference() { // horizontal hex bore & extension
        if (wide) {
            translate([-3.635, 0, 3.74]) rotate([0, 90, 0]) {
                translate([0, 0, -2.5]) cylinder(d1 = 8, d2 = 5, h = 2.5);
                translate([0, 0, -5]) cylinder(d = 8, h = 2.5);
            }
        } else {
            translate([-6.635, 0, 3.74]) rotate([0, -90, 180]) cylinder(d = 5, h = 3.15);
        }
        
        if (wide) {
            translate([-3.635, 0, 3.74]) rotate([0, 90, 0]) {
                translate([0, 0, -16.5]) rotate([90, 0, 0]) mini_stepper(main_ax_tol = axle_tol);
                translate([0, 0, -4.5]) cylinder(d = 2, h = 3 + axle_tol / 2);
            }
        } else {
            translate([-6.7, 0, 3.74]) rotate([0, -90, 180]) cylinder(d = 2 * hex_ratio + axle_tol, h = 5, $fn = 6);
        }
    }
}

module normal_gear(for_stepper = false, axle_tol = 0) {
    difference() {
        spur_gear(modul = 0.5, tooth_number = 30, width = 4, bore = 0, optimized = false);
        
        if (for_stepper) {
            translate([0, 0, -3.1]) rotate([90, 0, 0]) mini_stepper(main_ax_tol = axle_tol);
        } else {
            translate([0, 0, -0.1]) cylinder(d = 2 * hex_ratio + axle_tol, h = 4.2, $fn = 6);
        }
    }
}

module mechanism(off_angle = 8, tol_boxes = false, stepper_ax_tol = 0, hori_axle_tol = -0.015, tolerance = 0) {
    axles(tl_len = 25, br_len = 26, tol_boxes = tol_boxes, tol = hori_axle_tol); // main controlling axles
    
    // bottom-right gear train
    translate([21.85, -15, 3.556]) {
        // miter gears
        translate([0, 3.74, 0]) rotate([0, off_angle, 0]) {
            if (tol_boxes) color("orange") {
                translate([0, 3, 0]) rotate([90, 0, 0]) cylinder(d = 7.5, h = 5.5);
                translate([0, -3.74, 1.135]) cylinder(d = 7.5, h = 5.5);
            } else {
                rotate([90, 90, 0]) bevel_gears(singular = false, axle_tol = stepper_ax_tol, wide = true);
            }
        }
        
        rotate([0, off_angle, 0]) translate([0, 0, 20.135]) rotate([-90, 0, 90]) mini_stepper(main_ax_tol = stepper_ax_tol, tol_boxes = tol_boxes);
    }
    
    // top-left gear train
    translate([3.556, -9, 21.85]) {
        if (tol_boxes) {
            color("orange") translate([0, -5 - tolerance / 2, 15]) rotate([90, 0, 0]) cylinder(d = 16.1 + tolerance, h = 4 + tolerance);
            color("orange") translate([0, -5 - tolerance / 2, 0]) rotate([90, 0, 0]) cylinder(d = 16.1 + tolerance, h = 4 + tolerance);
        } else {
            _render("green", false) translate([0, -5, 15]) rotate([90, 0, 0]) normal_gear(for_stepper = true, axle_tol = stepper_ax_tol);
            _render("green", false) translate([0, -5, 0]) rotate([90, 6, 0]) normal_gear(for_stepper = false, axle_tol = hori_axle_tol);
        }
        
        translate([0, 0, 15]) rotate([0, 0, 180]) mini_stepper(main_ax_tol = stepper_ax_tol, tol_boxes = tol_boxes);
    }
}

module parts_to_print(axle_tol = 0, stepper_tol = 0) {
    // miter gears
    translate([0, 0, 3]) bevel_gears(singular = true, axle_tol = axle_tol, wide = false);
    translate([20, 0, 5]) bevel_gears(singular = true, axle_tol = stepper_tol, wide = true);
    
    translate([0, 15, 0]) normal_gear(for_stepper = false, axle_tol = axle_tol);
    translate([20, 15, 0]) normal_gear(for_stepper = true, axle_tol = stepper_tol);
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

parts_to_print(axle_tol = -0.12, stepper_tol = -0.015);
//stepper_axle_tols();

//mechanism(tol_boxes = false, hori_axle_tol = 0);
//mechanism(tol_boxes = true, stepper_ax_tol = 0);

//import_mirror(convexity = 1);






















































//asdf
