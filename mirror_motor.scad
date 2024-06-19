//
// mirror motor controller model
//

use<mirror_M05.scad>;
use<mechanism.scad>;
use<util.scad>;

$fs = 0.01;
$fn = 100;

inch = 25.4;

motor_wid = 20.3;

module securing_bolt() {
    color("blue") {
        rotate([0, -90, 0]) cylinder(h = 7, d = 8);
        rotate([0, 90, 0]) cylinder(h = 14, d = 4.115);
    }
}

module securing_bolt_pos() {
    translate([0.1, 5.85, inch / 2]) children();
}

module adjustment_pins() {
    translate([3.556, -3.5, 21.85]) rotate([-90, 0, 0]) cylinder(h = 10, d = 5);
    translate([21.85, -3.5, 3.556]) rotate([-90, 0, 0]) cylinder(h = 10, d = 5);
}

module motor_pos() {
    translate([motor_wid / 2, -6, 30]) rotate([180, 0, 90]) children();
}

module mount() {
    protrusion_dist = 2;
    
    module circular_pegs() {
        // circular pegs
        translate([8.47, -protrusion_dist, 21.22]) rotate([-90, 0, 0]) {
            cylinder(h = protrusion_dist + inch / 10, d = 3.2);
        }
        translate([21.22, -protrusion_dist, 8.47]) rotate([-90, 0, 0]) {
            cylinder(h = protrusion_dist + inch / 10, d = 3.2);
        }
    }
    
    module side_notches() {
        // side notches. bottom one unnecessary?
        translate([0, 1.23, inch / 2]) {
            rotate([0, 90, 0]) cylinder(h = 3.04, r = 0.75, center = true);
            translate([0, -1.615, 0]) cube([3.04, 3.23, 1.5], center = true);
        }
        translate([inch / 2, 1.23, 1.52 / 2]) {
            rotate([0, 0, 0]) cylinder(h = 1.52, r = 0.75, center = true);
            translate([0, -1.615, 0]) cube([1.5, 3.23, 1.52], center = true);
        }
    }
      
    module inner_slot() {
        translate([3.556, 0, 8.51]) rotate([-90, 0, 0]) {
            translate([0, 0, -protrusion_dist]) cylinder(h = 3.2, d = 3.4);
            translate([0, -8.39, -protrusion_dist]) cylinder(h = 3.2, d = 3.4);
        }
        translate([3.556, -0.4, inch / 2]) cube([1.65, 3.2, 0.515 * inch], center = true);
    }
    
    module inner_walls() {
        difference() {
            translate([8.8625, 4, inch / 2]) cube([6.075, 12, inch / 3], center = true);
            translate([6, -3, 6]) rotate([0, -15, 0]) cube([8, 14, 2]);
        }
        
        difference() {
            translate([inch / 2, 1, 7.9]) cube([inch / 3, 6, 4], center = true);
            translate([inch / 2, 5.8, 0]) cylinder(h = 10, d = 8);
        }
        
        rotate([0, -45, 0]) translate([16.5, -0.25, -1.5]) cube([4, 3.5, 6.5], center = true);
    }
    
    module outer_walls() {
        translate([-2.05, 2, inch / 2]) cube([4, 8, 18], center = true);
    }
    
    thickness = 1.9;
    module plate() {
        translate([-0.1, -2, inch / 2 - 9]) cube([10, thickness, 18]);
        translate([5, -2, 1.2]) cube([16.2, thickness, 8.9]);
    }
    
    color("red") circular_pegs();
    difference() {
        color("red") side_notches();
        securing_bolt_pos() securing_bolt();
    }
    
    color("red") inner_slot();
    color("red") multmatrix(m = [[0, 0, 1, 0], [0, 1, 0, 0], [1, 0, 0, 0]]) inner_slot();
    
    color("red") difference() {
        union() {
            inner_walls();
            outer_walls();
        }
        
        securing_bolt_pos() securing_bolt();
    }
    
    color("blue") difference() {
        plate();
        adjustment_pins();
    }
}

module mechanism_mount() {
    difference() {
        union() {
            translate([9, -20.5, 0]) cube([8, 20, 5]);
            translate([16.5, -4, 0]) cube([3, 3.5, 5]);
            translate([9, -20.5, 0]) beveled_cube([16.5, 4, 8], [0, 1, 0], 0.5);
            translate([9, -4.7, 0]) beveled_cube([16.5, 1.4, 8], [0, 1, 0], 0.5); // adjust this thickness
            
            translate([18, -23, 3]) beveled_cube([3, 4, 10], [1, 1, 1], 0.5);
        }
        
        // difference operations between such complicated meshes is quite expensive
        //mechanism(3d_print = true, hex_bores = true, tol_boxes = true);
    }
}

import_mirror(convexity = 1);
mount();

mechanism(3d_print = true, hex_bores = true, tol_boxes = true);
color("plum") mechanism_mount();























// asdf
