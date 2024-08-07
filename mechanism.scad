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
    _render("green", true) difference() {
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

module br_gears(axle_tol = 0, stepper_tol = 0, tol_boxes = false) {
    // ratios: 15:24, 24:12, 12:45, 45:30, 30:15
    // ==> (24/15) * (45/12) * (15/30) ==> 3:1 (im goated?)
    
    rend = true;
    
    _render(tol_boxes ? "orange" : "green", rend) difference() {
        if (tol_boxes) {
            cylinder(d = 6.9, h = 4);
        } else {
            spur_gear(modul = 0.4, tooth_number = 15, width = 4, bore = 0, optimized = false); // small primary br-axle gear
        }
        translate([0, 0, -1]) cylinder(d = 2 * hex_ratio + axle_tol, h = 6, $fn = 6);
    }

    _render(tol_boxes ? "orange" : "green", rend) difference() {
        union() {
            if (tol_boxes) {
                translate([0, 9, 0]) cylinder(d = 12.9, h = 4);
                translate([0, 9, 9]) cylinder(d = 23.7, h = 4);
            } else {
                translate([0, 9, 0]) spur_gear(modul = 0.4, tooth_number = 30, width = 4, bore = 0, optimized = false); // medium secondary gear
                translate([0, 9, 9]) spur_gear(modul = 0.5, tooth_number = 45, width = 4, bore = 0, optimized = false); // large secondary gear
            }
        }
        
        translate([0, 9, -1]) cylinder(d = 2 * hex_ratio + axle_tol, h = 15, $fn = 6);
    }

    _render(tol_boxes ? "orange" : "green", rend) difference() {
        union() {
            if (tol_boxes) {
                translate([center_stepper / 2, 23.25, 9]) cylinder(d = 7.2, h = 4);
                translate([center_stepper / 2, 23.25, 5]) cylinder(d = 13.2, h = 4);
            } else {
                translate([center_stepper / 2, 23.25, 9]) spur_gear(modul = 0.5, tooth_number = 12, width = 4, bore = 0, optimized = false); // small tertiary gear
                translate([center_stepper / 2, 23.25, 5]) spur_gear(modul = 0.5, tooth_number = 24, width = 4, bore = 0, optimized = false); // medium tertiary gear
            }
        }
        
        translate([center_stepper / 2, 23.25, 4]) cylinder(d = 2 * hex_ratio + axle_tol, h = 10, $fn = 6);
    }
    
    _render(tol_boxes ? "orange" : "green", rend) difference() {
        if (tol_boxes) {
            translate([center_stepper, 33, 5]) cylinder(d = 8.7, h = 4);
        } else {
            translate([center_stepper, 33, 5]) spur_gear(modul = 0.5, tooth_number = 15, width = 4, bore = 0, optimized = false); // top stepper small gear
        }
        
        translate([center_stepper, 33, 0]) rotate([90, 0, 0]) mini_stepper(main_ax_tol = stepper_tol);
    }
    
    // axles
    _render(tol_boxes ? "orange" : "gray", true) translate([0, 9, -3]) cylinder(d = 2 * hex_ratio + axle_tol, h = 22, $fn = tol_boxes ? $fn : 6);
    _render(tol_boxes ? "orange" : "gray", true) translate([center_stepper / 2, 23.25, 2]) cylinder(d = 2 * hex_ratio + axle_tol, h = 17, $fn = tol_boxes ? $fn : 6);
}

module mechanism(tol_boxes = false, stepper_ax_tol = 0, hori_axle_tol = -0.015, tolerance = 0) {
    axles(tl_len = 20, br_len = 14.7, tol_boxes = tol_boxes, tol = hori_axle_tol); // main controlling axles
    
    tl_hyp = sqrt(15 * 15 + center_stepper * center_stepper);
    tl_angle = abs(atan(15 / center_stepper));
    
    br_hyp = sqrt(0 * 0 + center_stepper * center_stepper);
    br_angle = abs(atan(0 / center_stepper));
    
    // bottom-right gear train
    translate([21.85, -6, 3.556]) {
        translate([0, -0.5, 0]) rotate([90, 0, 0]) br_gears(axle_tol = hori_axle_tol, tol_boxes = tol_boxes);
        
        translate([center_stepper, 3, 33]) rotate([0, 180, 180]) mini_stepper(main_ax_tol = stepper_ax_tol, tol_boxes = tol_boxes);
    }
    
    // top-left gear train
    translate([3.556, -6, 21.85]) {
        if (tol_boxes) {
            color("orange") translate([-center_stepper, -5 - tolerance / 2, 14.9758]) rotate([90, 0, 0]) cylinder(d = 8.7 + tolerance, h = 4 + tolerance);
            color("orange") translate([0, -5 - tolerance / 2, 0]) rotate([90, 0, 0]) cylinder(d = 23.8 + tolerance, h = 4 + tolerance);
        } else {
            translate([-center_stepper, -5, 15 * sin(tl_angle)]) rotate([90, 0, 0]) normal_tl_gear(for_stepper = true, axle_tol = stepper_ax_tol);
            translate([0, -5, 0]) rotate([90, 3.66, 0]) normal_tl_gear(for_stepper = false, axle_tol = hori_axle_tol);
        }
        
        translate([-center_stepper, 3, 15 * sin(tl_angle)]) rotate([0, 180, 180]) mini_stepper(main_ax_tol = stepper_ax_tol, tol_boxes = tol_boxes);
    }
}

module parts_to_print(axle_tol = 0, stepper_tol = 0) { // TODO: alternates for the bottom-right primary gears
    // top left gears
    translate([0, 15, 0]) normal_tl_gear(for_stepper = false, axle_tol = axle_tol);
    translate([20, 15, 0]) normal_tl_gear(for_stepper = true, axle_tol = stepper_tol);
    
    // bottom right gears
    translate([15, 0, 0]) difference() {
        spur_gear(modul = 0.4, tooth_number = 15, width = 4, bore = 0, optimized = false); // small primary br-axle gear
        translate([0, 0, -1]) cylinder(d = 2 * hex_ratio + axle_tol, h = 6, $fn = 6);
    }

    translate([35, 0, 0]) difference() {
        union() {
            translate([0, 9, 0]) spur_gear(modul = 0.4, tooth_number = 30, width = 4, bore = 0, optimized = false); // medium secondary gear
            translate([0, 30, 0]) spur_gear(modul = 0.5, tooth_number = 45, width = 4, bore = 0, optimized = false); // large secondary gear
        }
        
        translate([0, 9, -1]) cylinder(d = 2 * hex_ratio + axle_tol, h = 15, $fn = 6);
        translate([0, 30, -1]) cylinder(d = 2 * hex_ratio + axle_tol, h = 15, $fn = 6);
    }

    translate([0, 15, -5]) difference() {
        union() {
            translate([center_stepper / 2, 23.25, 9]) spur_gear(modul = 0.5, tooth_number = 12, width = 4, bore = 0, optimized = false); // small tertiary gear
            translate([center_stepper / 2, 23.25, 5]) spur_gear(modul = 0.5, tooth_number = 24, width = 4, bore = 0, optimized = false); // medium tertiary gear
        }
        
        translate([center_stepper / 2, 23.25, 4]) cylinder(d = 2 * hex_ratio + axle_tol, h = 10, $fn = 6);
    }
    
    translate([15, 2, -5]) difference() {
        translate([center_stepper, 33, 5]) spur_gear(modul = 0.5, tooth_number = 15, width = 4, bore = 0, optimized = false); // top stepper small gear
        translate([center_stepper, 33, 0]) rotate([90, 0, 0]) mini_stepper(main_ax_tol = stepper_tol);
    }
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
