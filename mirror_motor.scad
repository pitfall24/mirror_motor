//
// mirror motor controller model
//

use<mirror_M05.scad>;
use<mechanism.scad>;
use<util.scad>;
use<mini_stepper.scad>;

$fs = 0.01;
$fn = 100;

inch = 25.4;
hex_ratio = 2 / sqrt(3);

module securing_bolt(dia_tol = 0, head_tol = 0) {
    color("blue") {
        rotate([0, -90, 0]) cylinder(h = 7, d = 8 + head_tol);
        translate([-0.05, 0, 0]) rotate([0, 90, 0]) cylinder(h = 14.05, d = 4.11226 + dia_tol);
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
            translate([0, 0, -protrusion_dist]) cylinder(h = 3, d = 3.4);
            translate([0, -8.39, -protrusion_dist]) cylinder(h = 3, d = 3.4);
        }
        translate([3.556, -0.5, inch / 2]) cube([1.65, 3, 0.515 * inch], center = true);
    }
    
    module inner_walls() {
        difference() {
            translate([9.8625, 4, inch / 2]) cube([8.075, 12, inch / 3], center = true);
            translate([6, -3, 6]) rotate([0, -15, 0]) cube([10, 14, 2]);
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
        
        securing_bolt_pos() securing_bolt(dia_tol = -0.32); // securing bolt tolerance here !!
    }
    
    color("blue") difference() {
        plate();
        union() {
            adjustment_pins();
            translate([19.35, -4, 0]) cube([2, 4, 3.5]);
        }
    }
}

module motor_holder(securing_ring_tol = 0, screw_tol = 0) {
    color("steelblue") rotate([-90, 0, 0]) difference() {
        union() {
            translate([-12, -4, -12]) cube([24, 7, 24]);
        }
        
        translate([-8, -0.1, -8]) rotate([-90, 0, 0]) cylinder(d = 2 + screw_tol, h = 3.2);
        translate([-8, -0.1,  8]) rotate([-90, 0, 0]) cylinder(d = 2 + screw_tol, h = 3.2);
        translate([ 8, -0.1, -8]) rotate([-90, 0, 0]) cylinder(d = 2 + screw_tol, h = 3.2);
        translate([ 8, -0.1,  8]) rotate([-90, 0, 0]) cylinder(d = 2 + screw_tol, h = 3.2);
        
        mini_stepper(main_ax_tol = 1, securing_ring_tol = securing_ring_tol, tol_boxes = true);
    }
}

module mechanism_mount() {
    // coordinates
    top_le_main_ax = [3.556, 0, 21.85];
    bot_ri_main_ax = [21.85, 0, 3.556];
    
    off_angle = 8;
    
    // pulled out for convenience
    module bearings() {
        color("lime", 0.5) {
            translate(top_le_main_ax + [0, -3.65, 0]) rotate([90, 0, 0]) cylinder(d = 7, h = 10.2); // top-left inner
            translate(top_le_main_ax + [0, -18.1, 0]) rotate([90, 0, 0]) cylinder(d = 7, h = 7); // top-left outer
            
            translate(top_le_main_ax + [0, -18.1, 15]) rotate([90, 0, 0]) cylinder(d = 7, h = 7); // top-left motor axle
            
            translate(bot_ri_main_ax) rotate([0, off_angle, 0]) translate([0, -15, 8.7]) cylinder(d = 8, h = 9.135); // bottom_right motor axle
        }
    }
    
    difference() {
        union() {
            // --- supporting bases, braces, and platforms ---
            color("plum") {
                translate([13, -27, 0]) beveled_cube([12.5, 7.5, 7], [0, 1, 0], 0.5); // outer bottom-right axle brace/bearing
                translate([13, -8.21, 0]) beveled_cube([12.5, 3.81, 7], [0, 1, 0], 0.5); // inner bottom-right axle brace/bearing
                translate([15.5, -23.5, 0]) cube([2, 19.3, 7]); // connector
                
                // main lower platform
                translate([-4.05, -27, 0]) cube([20, 26.5, 7]);
                
                // diagonal brace
                translate([-0.55, -0.5, 0]) rotate([0, -90, 0]) linear_extrude(height = 3.5) polygon(points = [ [21.7, 0], [0, -20], [0, 0] ]);
            }
            
            // --- bearings ---
            bearings();
            
            // --- supports ---
            difference() {
                color("peru") union() {
                    translate(top_le_main_ax + [0, -9, 15]) rotate([-90, 0, 0]) motor_holder(securing_ring_tol = 0, screw_tol = 0);
                    
                    translate(bot_ri_main_ax + [0, -15, 0]) rotate([0, off_angle, 0]) {
                        translate([0, 0, 20.135]) motor_holder(securing_ring_tol = 0, screw_tol = 0);
                        
                        translate([-5, -12, -1]) cube([8.78, 7.5, 18.635]); // bottom-right motor outer support
                        translate([-5, 6.79, -1]) cube([8.78, 3.81, 18.635]); // bottom-right motor inner support
                        translate([-12, -4.5, -1]) cube([7.5, 9, 18.635]); // bottom-right motor left support
                        translate([-5.1, -4.6, 9]) cube([7, 7, 2]); // bottom-right motor axle bearing stabilizer
                        
                        translate([-19, -10.1, 16]) cube([7, 7, 7]);
                    }
                    
                    translate([11.4, -2, 15.5]) cube([3, 12, 11.35]); // top-left motor right support
                    translate([-4.05, -2, 20]) cube([4.05, 8, 6.85]); // top-left motor left support
                    translate([-4.05, -5, 25.5]) cube([18.45, 15, 1.35]); // top-left motor middle support
                    
                    translate([0.056, -13.85, 7]) cube([7, 10.2, 14.85]); // top-left motor inner bearing support
                    translate([0.056, -3.65, 7]) cube([7, 1.65, 10]);
                    translate([0.056, -25.1, 7]) cube([7, 7, 41.85]); // top-left motor outer bearings support
                    translate([0.056, -25.1, 46.85]) cube([7, 20.1, 5]); // upper connector
                }
                
                bearings();
            }
        }
        
        // difference operations between such complicated meshes is quite expensive (theyre no longer *that* complicated)
        mechanism(off_angle = off_angle, tol_boxes = true, stepper_ax_tol = -0.015);
        
        //translate([-5, -30, -1]) cube([40, 40, 1.0]); // maybe remove some material from the very bottom for clearance
    }
}

motor_holder(securing_ring_tol = 0.1, screw_tol = 0.1);

//import_mirror(convexity = 1);

//_render("red") mount();
//mechanism_mount();

//_render("orange") mechanism(tol_boxes = false);
//mechanism();
































// asdf
