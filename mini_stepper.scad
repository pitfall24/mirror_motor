//
// mini stepper motor
// https://www.pololu.com/product/1204/resources
//

$fs = 0.1;
$fn = 64;

use<util.scad>;

module mini_stepper(main_ax_tol = 0, securing_ring_tol = 0, tol_boxes = false) {
    _render("dimgray") translate([-10, -30, -10]) if (tol_boxes) { // body
        cube([20, 30, 20]);
    } else {
        beveled_cube([20, 30, 20], [0, 1, 0], 0.106);
    }
    _render("darkgray") translate([0, -0.1, 0]) rotate([-90, 0, 0]) cylinder(d = 15 + securing_ring_tol, h = 1.6 + securing_ring_tol / 2); // securing ring
    
    _render("silver", false) difference() { // main axle
        translate([0, 1.4, 0]) rotate([-90, 0, 0]) cylinder(d = 4 + main_ax_tol, h = 13.6 + main_ax_tol / 2);
        
        if (!tol_boxes) {
            translate([-3, 3, -3 - main_ax_tol / 2]) cube([6, 12.1, 1.5]); // flat face
            
            difference() { // end taper
                translate([0, 13.6 + main_ax_tol / sqrt(8), 0]) rotate([-90, 0, 0]) cylinder(d = 6, h = 4);
                translate([0, 13.5 + main_ax_tol / sqrt(8), 0]) rotate([-90, 0, 0]) cylinder(d1 = 6, d2 = 0, h = 3);
            }
            
            translate([0, 14, 0]) rotate([-90, 0, 0]) cylinder(d = 1.25, h = 2); // end hole
        }
    }
    
    if (tol_boxes) _render("orange") translate([9.9, -31, -6]) cube([3, 10, 12]); // connector
}

module import_mini_stepper(convexity = 1) {
    import("./stepper_motor.stl", convexity = convexity);
}

mini_stepper(main_ax_tol = 0, tol_boxes = false);
//import_mini_stepper();
