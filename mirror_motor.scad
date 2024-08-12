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
        
        // -0.7 if you are planning on tapping the hole, -0.4 (ish) otherwise
        securing_bolt_pos() securing_bolt(dia_tol = -0.7); // securing bolt tolerance here !!
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
    
    center_stepper = 0.853;
    
    // pulled out for convenience
    module bearings() {
        color("lime", 0.5) {
            translate(top_le_main_ax + [0, -3.65, 0]) rotate([90, 0, 0]) cylinder(d = 7, h = 7.25); // top-left inner
            translate(top_le_main_ax + [0, -15.1, 0]) rotate([90, 0, 0]) cylinder(d = 7, h = 7); // top-left outer
            
            translate(top_le_main_ax + [-center_stepper, -15.1, 15]) rotate([90, 0, 0]) cylinder(d = 7, h = 7); // top-left motor axle
            translate(top_le_main_ax + [-center_stepper, -9, 15]) rotate([90, 0, 0]) cylinder(d = 7, h = 1.9); // top-left motor axle stabilizer
            
            translate(bot_ri_main_ax + [center_stepper, -15.6, 33]) rotate([90, 0, 0]) cylinder(d = 7, h = 7); // bot_ri motor axle
            translate(bot_ri_main_ax + [center_stepper, -9.5, 33]) rotate([90, 0, 0]) cylinder(d = 7, h = 1.9); // bot_ri motor axle stabilizer
            
            translate(bot_ri_main_ax + [center_stepper / 2, -19.6, 23.25]) rotate([90, 0, 0]) cylinder(d = 7, h = 5); // bot_ri tertiary gears
            translate(bot_ri_main_ax + [center_stepper / 2, -5.4, 23.25]) rotate([90, 0, 0]) cylinder(d = 7, h = 6); // bot_ri tertiary gears
            
            translate(bot_ri_main_ax + [0, -19.6, 9]) rotate([90, 0, 0]) cylinder(d = 7, h = 5); // bot_ri tertiary gears
            translate(bot_ri_main_ax + [0, -10.6, 9]) rotate([90, 0, 0]) cylinder(d = 7, h = 4.8); // bot_ri tertiary gears
        }
    }
    
    difference() {
        union() {
            // --- supporting bases, braces, and platforms ---
            color("plum") {
                translate([11, -15.4, 0]) beveled_cube([14.5, 4.8, 7], [0, 1, 0], 0.5); // outer bottom-right axle brace/bearing
                translate([11, -6.4, 0]) beveled_cube([14.5, 2.3, 16], [0, 1, 0], 0.21875); // inner bottom-right axle brace/bearing
                
                translate([11, -6.3, 7]) beveled_cube([14.5, 4.5, 9], [0, 1, 0], 0.35);
                
                // main lower platform
                translate([-4.05, -15.4, 0]) cube([20, 14.9, 7]);
                translate([-4.05, -23, 0]) cube([14, 7.8, 7]);
                
                // diagonal brace
                translate([-0.55, -0.5, 0]) rotate([0, -90, 0]) linear_extrude(height = 3.5) polygon(points = [ [21.7, 0], [0, -18], [0, 0] ]);
                
                // flat plate connector
                translate([5, -22.7, 4]) cube([18, 2.5, 36.2]);
                translate([0.056, -25, 30]) cube([22.944, 4, 4]);
                translate([0.056, -25, 4]) cube([22.944, 4, 5]);
            }
            
            // --- bearings ---
            bearings();
            
            // --- supports ---
            difference() {
                color("peru") union() {
                    difference() {
                        translate([top_le_main_ax[0] - center_stepper, -3, top_le_main_ax[2] + 14.9758]) rotate([-90, 0, 0]) motor_holder(securing_ring_tol = 0, screw_tol = 0);
                        translate([13, -7, 24]) cube([5, 9, 25]);
                        translate(top_le_main_ax + [0, 2, -3]) rotate([90, 0, 0]) cylinder(d = 15, h = 4);
                    }
                    
                    difference() {
                        translate([bot_ri_main_ax[0] + center_stepper, -3, bot_ri_main_ax[2] + 33]) rotate([-90, 0, 0]) motor_holder(securing_ring_tol = 0, screw_tol = 0);
                        translate([10, -7, 24]) cube([2, 9, 25]);
                    }
                    
                    translate([0.056, -10.9, 7]) cube([7, 7.25, 14.85]); // top-left motor inner bearing support
                    translate([0.056, -3.65, 7]) cube([7, 1.65, 10]);
                    translate([0.056, -22.1, 7]) cube([7, 7, 40]); // top-left motor outer bearings support
                    
                    translate([0.056, -15.3, 42]) cube([7, 10, 5]); // top connecting support
                    
                    translate([0.056, -10.8, 21]) cube([7, 1.7, 24]); // thin vertical inner support
                    translate([1.5, -10, 24.9]) cube([3, 4.2, 9]); // support for thin vertical inner support
                    
                    translate([-4.05, -6, 14]) cube([3.5, 7, 14]); // top-left motor holder support
                    translate([12, -6.4, 14]) cube([12, 4.6, 10.7]); // bottom right main motor holder support
                    
                    translate([21.85 + center_stepper, -5.9, 36.556]) rotate([90, 0, 0]) difference() { // hollow tube support at top-right
                        cylinder(d = 8, h = 4.5);
                        translate([0, 0, -1]) cylinder(d = 6, h = 6.5);
                    }
                    
                    translate([21.85 + center_stepper - 2, -20, 39]) { // top-right connecting stabilizer
                        cube([4, 4, 3]);
                        translate([0, 9, 0]) cube([4, 5.5, 3]);
                        translate([0, 0, 2.9]) cube([4, 14.5, 3]);
                    }
                    
                    translate([21.85 - 3.45, -15.35, 4]) cube([6.9, 4, 9]); // bottom right secondary gear support
                    
                    // strengthening
                    translate([3.556 - center_stepper - 12, -6, 48.5]) cube([44, 7, 3]);
                    translate([-4, 1, 24.826]) rotate([90, 0, 0]) linear_extrude(height = 7) polygon(points = [ [-5.297, 0], [0, -12], [0, 0] ]);
                    translate([23.99, -1.8, 24.56]) rotate([90, 0, 0]) linear_extrude(height = 4.2) polygon(points = [ [10.71, 0], [0, -12], [0, 0] ]);
                    translate([12, -1.82, 10]) cube([6, 2, 14.6]);
                }
                
                bearings();
            }
        }
        
        // difference operations between such complicated meshes is quite expensive (theyre no longer *that* complicated)
        mechanism(tol_boxes = true, stepper_ax_tol = 0.1);
        
        translate([-5, -30, -1]) cube([40, 40, 1.1]); // maybe remove some material from the very bottom for clearance
        
        // screw holes
        translate([3.556 - center_stepper + 8, -30, 28.825]) rotate([-90, 0, 0]) cylinder(d = 2, h = 20);
        translate([21.85 + center_stepper - 8, -30, 28.556]) rotate([-90, 0, 0]) cylinder(d = 2, h = 20);
        
        // motor holder fix
        translate([12, -3, 26.8257]) cube([2, 5, 19.7305]);
    }
}

//motor_holder(securing_ring_tol = 0.1, screw_tol = 0.1);

//import_mirror(convexity = 1);

mirror([0, 0, 0]) {
    _render("red") mount();
    mechanism_mount();
}

//mechanism(tol_boxes = false);
































// asdf
