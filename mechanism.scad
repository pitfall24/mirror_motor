//
// mirror motor mechanics (gears etc.)
//

use<mirror_M05.scad>;
use<mini_stepper.scad>;
use<gears.scad>;

$fn = 64;

hex_ratio = 2 / sqrt(3);
tol_box_tolerance = 0.2;

module axles(tol_boxes = false) {
    translate([3.556, 1, 21.85]) rotate([90, -12.5, 0]) {
        color("gray") cylinder(d = 2 * hex_ratio, h = 12, $fn = 6);
        if (tol_boxes) color("orange") translate([0, 0, 0]) cylinder(d = 2 * hex_ratio + tol_box_tolerance / 3, h = 12 + tol_box_tolerance);
    }
    
    color("gray") translate([21.85, 1, 3.556]) rotate([90, -12.5, 0]) cylinder(d = 2 * hex_ratio, h = 20, $fn = 6);
    if (tol_boxes) color("orange") translate([21.85, 1, 3.556]) rotate([90, -12.5, 0]) cylinder(d = 2 * hex_ratio + tol_box_tolerance / 3, h = 20 + tol_box_tolerance);
}

module bevel_gears(singular = false, hex_bore = false, set_screw = true) {
    difference() {
        if (singular) {
            bevel_gear(modul = 0.5, tooth_number = 13, partial_cone_angle = 45, tooth_width = 2, bore = hex_bore ? 1.5 : 2);
        } else {
            bevel_gear_pair(modul = 0.5, gear_teeth = 13, pinion_teeth = 13, axis_angle = 90, tooth_width = 2, gear_bore = hex_bore ? 1.5 : 2, pinion_bore = hex_bore ? 1.5 : 2, together_built = true);
        }
        if (hex_bore) {
            if (!singular) {
                translate([-4, 0, 3.635]) rotate([0, -90, 180]) cylinder(d = 2 * hex_ratio, h = 3, $fn = 6);
            }
            translate([0, 0, -1]) cylinder(d = 2 * hex_ratio, h = 3, $fn = 6);
        }
    }
    
    difference() {
        translate([0, 0, -3]) cylinder(d = 5, h = 3);
        union() {
            translate([0, 0, -3.1]) cylinder(d = 2 * (hex_bore ? hex_ratio : 1), h = 5, $fn = hex_bore ? 6 : $fn);
            if (set_screw) translate([0, 0, -1.5]) rotate([90, 0, 0]) cylinder(d = 2 /*1.588*/, h = 3);
        }
    }
    
    if (!singular) {
        difference() {
            translate([-(3 + 3.635), 0, 3.635]) rotate([0, -90, 180]) cylinder(d = 5, h = 3);
            union() {
                translate([-(3.1 + 3.635), 0, 3.635]) rotate([0, -90, 180]) cylinder(d = 2 * (hex_bore ? hex_ratio : 1), h = 5, $fn = hex_bore ? 6 : $fn);
                if (set_screw) translate([-(1.5 + 3.635), 0, 3.635]) rotate([90, 0, 0]) cylinder(d = 2 /*1.588*/, h = 3);
            }
        }
    }
}

module mechanism(3d_print = false, hex_bores = false, tol_boxes = false) {
    axles(tol_boxes = tol_boxes);
    color("gray") translate([21.85, -11.635, 5]) cylinder(d = 2, h = 11, $fn = hex_bores ? 6 : $fn);
    if (tol_boxes) color("orange") translate([21.85, -11.635, 5]) cylinder(d = 2 * hex_ratio + tol_box_tolerance, h = 11 + tol_box_tolerance);
    
    // bottom-right gear train
    translate([21.85, -8, 3.556]) {
        rotate([90, 90, 0]) bevel_gears(hex_bore = hex_bores, set_screw = !3d_print);
        color("orange") if (tol_boxes) {
            translate([0, 3 + tol_box_tolerance / 2, 0]) rotate([90, 0, 0]) cylinder(d = 7 + tol_box_tolerance, h = 5 + tol_box_tolerance);
            translate([0, -3.635, 1.635]) cylinder(d = 7 + tol_box_tolerance, h = 5 + tol_box_tolerance);
        }
        translate([0, -3.635, 6.7]) {
            color("orange") if (tol_boxes) {
                translate([0, 0, -tol_box_tolerance / 2]) cylinder(d = 12.8 + tol_box_tolerance, h = 2 + tol_box_tolerance);
                translate([-7.1, 0, 0]) cylinder(d = 2.75 + tol_box_tolerance, h = 2 + tol_box_tolerance);
            }
            
            difference() {
                if (3d_print) {
                    // use custom gears which will fit better
                    spur_gear(modul = 12 / 39, tooth_number = 39, width = 2, bore = 2, optimized = false);
                } else {
                    spur_gear(modul = 8 / 29, tooth_number = 29, width = 4, bore = 2);
                }
                if (hex_bores) {
                    translate([0, 0, -1]) cylinder(d = 2 * hex_ratio, h = 6, $fn = 6);
                }
            }
            if (3d_print) {
                translate([-7.1, 0, 12.3]) rotate([180, 0, 90]) mini_stepper();
            } else {
                translate([-5, 0, 14.3]) rotate([180, 0, 90]) mini_stepper();
            }
        }
    }
    
    // top-left gear train
    translate([3.556, -5, 21.85]) {
        color("orange") if (tol_boxes) {
            translate([0, tol_box_tolerance / 2, 0]) rotate([90, 0, 0]) cylinder(d = 12.8 + tol_box_tolerance, h = 2 + tol_box_tolerance);
            translate([0, 0, -7.1]) rotate([90, 0, 0]) cylinder(d = 2.75 + tol_box_tolerance, h = 2 + tol_box_tolerance);
        }
        
        rotate([90, 0, 0]) difference() {
            if (3d_print) {
                spur_gear(modul = 12 / 39, tooth_number = 39, width = 2, bore = 2, optimized = false);
            } else {
                spur_gear(modul = 8 / 29, tooth_number = 29, width = 4, bore = 2);
            }
            if (hex_bores) {
                translate([0, 0, -1]) cylinder(d = 2 * hex_ratio, h = 6, $fn = 6);
            }
        }
        if (3d_print) {
            translate([0, -12.3, -7.1]) rotate([-90, 0, 0]) mini_stepper();
        } else {
            translate([0, -14.3, -5]) rotate([-90, 0, 0]) mini_stepper();
        }
    }
}

module parts_to_print(hex_bore = true, set_screw = false, custom_gears = true, include_miter = true) {
    // miter gears
    if (include_miter) {
        translate([0, 0, 3]) bevel_gears(singular = true, hex_bore = hex_bore, set_screw = set_screw);
        translate([15, 0, 3]) bevel_gears(singular = true, hex_bore = hex_bore, set_screw = set_screw);
    }
    
    mod = custom_gears ? 12 / 39 : 8 / 29;
    num = custom_gears ? 39 : 29;
    wid = custom_gears ? 2 : 4;
    
    difference() {
        union() {
            translate([0, 15, 0]) spur_gear(modul = mod, tooth_number = num, width = wid, bore = 2, optimized = false);
            translate([15, 15, 0]) spur_gear(modul = mod, tooth_number = num, width = wid, bore = 2, optimized = false);
        }
        if (hex_bore) {
            translate([0, 15, -1]) cylinder(d = 2 * hex_ratio, h = 6, $fn = 6);
            translate([15, 15, -1]) cylinder(d = 2 * hex_ratio, h = 6, $fn = 6);
        }
    }
}

translate([0, /*4*/0, 0]) {
    mechanism(3d_print = true, hex_bores = true, tol_boxes = true);
    import_mirror();
}

/*
parts_to_print();
translate([30, 0, 0]) parts_to_print(hex_bore = false, include_miter = true);
translate([0, 15, 0]) parts_to_print(hex_bore = true, custom_gears = false, include_miter = false);
translate([30, 15, 0]) parts_to_print(hex_bore = false, custom_gears = false, include_miter = false, set_screw=false);
*/




























// asdf
