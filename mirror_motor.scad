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

motor_wid = 20.3;

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
        
        securing_bolt_pos() securing_bolt(dia_tol = -0.25); // securing bolt tolerance here !!
    }
    
    color("blue") difference() {
        plate();
        union() {
            adjustment_pins();
            translate([19.35, -4, 0]) cube([2, 4, 3.5]);
        }
    }
}

module motor_holder(outer_dia = 10, parity = false) {
    color("steelblue") {
        translate([0, 0, -1.5]) cylinder(d = outer_dia, h = 1.5);
        difference() {
            cylinder(d = outer_dia, h = 3.4);
            
            union() {
                translate([0, 0, 1.9]) cube([4, 25, 4], center = true);
                translate([0, 0, 1.9]) rotate([0, 0, parity ? -25 : 25]) cube([4, 25, 4], center = true);
                translate([-1, -7, 4]) rotate([0, 0, 55]) cube([3, 6, 5]);
            }
        }
        
        for (i = [0, 1]) mirror([0, i, 0]) {
            translate([0, 0, -0.35]) rotate([-3.5, 0, 0]) difference() {
                union() {
                    translate([-1.5, -6.1, -1.4]) cube([3, 1.5, 12.5]);
                    translate([-1.5, -5.6, 8.35]) cube([3, 2.5, 0.67]);
                    translate([-1.5, -3.91915, 8.4464]) rotate([35, 0, 0]) cube([3, 1, 3]);
                    translate([-1.5, -5, 8.5]) cube([3, 1, 1]);
                }
                translate([-1.55, -7, 10]) rotate([-35, 0, 0]) cube([3.1, 1, 3]);
            }
        }
    }
}

// generic elastic bearing assembly
module bearing(outer_dia = 7, inner_dia = 3.5, height = 6) {
    // TODO: do
}

module mechanism_mount() {
    // coordinates
    top_le_main_ax = [3.556, 0, 21.85];
    top_le_sec_ax = [3.556, 0, 21.85 + 9 + 2.16];
    top_le_motor = [3.556, 0, 21.85 + 9 + 6.5 + 2.16 + 1];
    
    bot_ri_main_ax = [21.85, 0, 3.556];
    bot_ri_vert_ax = [21.85, -14.635, 5];
    bot_ri_sec_ax = [21.85 - 9 - 2.16, -11 - 3.635, 3.556 + 6.6];
    bot_ri_motor = [21.85 - 9 - 2.16 + (6.5 + 1) * cos(225), -11 - 3.635 + (6.5 + 1) * sin(225), 3.556 + 6.6];
    
    // pulled out for convenience
    module bearings() {
        color("lime", 0.5) {
            translate(bot_ri_vert_ax + [0, 0, 13.1]) cube([6, 6, 13], center = true); // bottom right vertical miter axle bearing // BEARING (3)
            translate(bot_ri_sec_ax + [-3, -3, -8]) cube([6, 6, 6]); // bottom right secondary axle lower bearing // BEARING (4)
            translate(bot_ri_sec_ax + [0, 0, 2.1]) cylinder(d = 7, h = 6); // bottom right secondary axle upper bearing // BEARING (5)
            
            translate(top_le_main_ax + [0, -11, 0]) rotate([90, 0, 0]) cylinder(d = 7, h = 4.7); // top left main axle bearing // BEARING (6)
            translate(top_le_sec_ax + [0, -11, 0]) rotate([90, 0, 0]) cylinder(d = 7, h = 5.8); // top left secondary axle outer bearing // BEARING (7)
            translate(top_le_sec_ax + [0, -1.2, 0]) rotate([90, 0, 0]) cylinder(d = 7, h = 5.8); // top left secondary axle inner bearing // BEARING (8)
            
            translate(top_le_main_ax + [0, -9, 0]) rotate([-90, 0, 0]) cylinder(d = 8, h = 2); // top left main axle tentative *plastic* bearing // BEARING (9)
            translate(top_le_main_ax + [0, -7, 0]) rotate([-90, 0, 0]) cylinder(d = 6, h = 3);
        }
    }
    
    difference() {
        union() {
            // --- supporting bases, braces, and platforms ---
            color("plum") {
                // NOTE: in the future these will both be converted to elastic bearings
                translate([13, -25, 0]) beveled_cube([12.5, 5.5, 7], [0, 1, 0], 0.5); // outer bottom-right axle brace/bearing // BEARING (1)
                translate([13, -7.7, 0]) beveled_cube([12.5, 3.5, 7], [0, 1, 0], 0.5); // inner bottom-right axle brace/bearing // BEARING (2)
                translate([15.5, -23.5, 0]) cube([2.5, 19.3, 7]); // connector. NOTE: might add another far-right connector for rigidity?
                
                // main lower platform
                difference() {
                    translate([-4.05, -25, 0]) cube([20, 24.5, 7]); // made this thicker for strength and rigidity (and heft?)
                    translate(bot_ri_sec_ax + [-3, -3, -8]) cube([6, 6, 6]); // BEARING (4)
                }
                
                // diagonal brace
                translate([-0.55, -0.5, 0]) rotate([0, -90, 0]) linear_extrude(height = 3.5) polygon(points = [ [21.7, 0], [0, -20], [0, 0] ]);
                
                // vertical support pillar and brace
                translate([7.95, -6.9, 0]) cube([8, 6.4, 34]);
                translate([13.87, -1, 16.5]) rotate([0, -90, 0]) linear_extrude(height = 2.5) polygon(points = [ [17.5, 0], [0, 10], [0, 0] ]);
                
                // smaller vertical pillar
                translate([15.9, -4.3, 0]) cube([3.35, 3.8, 17.5]);
            }
            
            // --- bearings ---
            bearings();
            
            // --- supports ---
            difference() {
                color("peru") union() {
                    translate([-4.05, -28.9, 0]) cube([29.55, 4, 16]); // backplate
                    translate([16, -28.9, 12.5]) cube([9.5, 28.4, 5]); // right support (primarily for bearing (3) 
                }
                
                bearings();
                translate(bot_ri_motor + [0, 0, 2]) cylinder(d = 11.9, h = 4.5);
            }
            
            // left motor mount
            difference() {
                translate([3.556, -11.45, 21.85 + 18.66]) rotate([90, 90, 0]) motor_holder(outer_dia = 12);
                translate([3.556, -9.3, 21.85 + 13]) cube([10, 5, 3], center = true);
            }
            
            // right motor mount
            xdiff = 18 / 2 + 4.32 / 2 - (13 / 2 + 2 / 2) * cos(225);
            ydiff = (13 / 2 + 2 / 2) * sin(225);
            
            difference() {
                translate([21.85 - xdiff, -14.635 + ydiff, 3.556 + 9.05]) rotate([0, 0, 60]) motor_holder(outer_dia = 12, parity = true);
                translate(bot_ri_sec_ax + [0, 0, 0.8]) cylinder(d = 7, h = 6);
            }
        }
        
        // difference operations between such complicated meshes is quite expensive (theyre no longer *that* complicated)
        mechanism(tol_boxes = true);
    }
}

import_mirror(convexity = 1);
_render("red") mount();

_render("orange") mechanism(axle_tol = -0.2, tol_boxes = false);
mechanism_mount();

// translate([-20, -20, 0]) cube([19.74, 8.34, 23.25]); // servo motor size

// ######################################################################################
// test printing land ###################################################################
// ######################################################################################

module motor_holder_print() {
    difference() {
        motor_holder(outer_dia = 11);
        translate([0, 0, 8.3]) rotate([180, 0, 90]) mini_stepper(tol_boxes = true);
    }
}

module screw_test_print() {
    difference() {
        cube([8, 56, 8]);
        
        dict = [[4, 0], [10, -0.05], [16, -0.1], [22, -0.15], [28, -0.2], [34, -0.25], [40, -0.3], [46, -0.35], [52, -0.4]];
        for (i = [4, 10, 16, 22, 28, 34, 40, 46, 52]) {
            tol = dict[search(i, dict)[0]][1];
            
            translate([4, i, 8.05]) rotate([0, 90, 0]) securing_bolt(dia_tol = tol, head_tol = 1);
            translate([0.5, i - 1, 1]) rotate([0, -90, 0]) linear_extrude(height = 2) text(text = str(tol), size = 2);
        }
    }
}

module axle_tol_print() {
    difference() {
        cube([6, 26, 6]);
        
        dict = [[3, 0], [8, 0.05], [13, 0.1], [18, 0.15], [23, 0.2]];
        for (i = [3, 8, 13, 18, 23]) {
            tol = dict[search(i, dict)[0]][1];
            
            translate([3.3 - 3.556, i - 21.85, 0]) rotate([-90, 0, 0]) axles(tol_boxes = true, tol = tol);
            translate([0.5, i - 1.33, 0.5]) rotate([0, -90, 0]) linear_extrude(height = 2) text(text = str(tol), size = 2);
        }
    }
}

module elastic_test_print(solid = true, elastic = true) {
    hex_ratio = 2 / sqrt(3);
    toled_axle = 1.8 * hex_ratio + 0.9 * 0.2;
    
    difference() {
        union() {
            if (solid) difference() {
                cube([8, 8, 8]);
                
                translate([4, 4, -0.1]) cylinder(d = toled_axle + 1, h = 10);
                translate([4, 4, 7]) cylinder(d = 6.5, h = 2);
                translate([4, 4, 2.5]) cylinder(d = 5, h = 2);
            };
            
            if (elastic) color("lime", 0.5) translate([4, 4, 0]) cylinder(d = toled_axle + 1, h = 7);
            if (elastic) color("lime", 0.5) translate([4, 4, 7]) cylinder(d = 6.5, h = 1);
            if (elastic) color("lime", 0.5) translate([4, 4, 2.5]) cylinder(d = 5, h = 2);
        }
        
        translate([4, 4, -0.1]) cylinder(d = toled_axle, h = 10); // axle
    }
}

//elastic_test_print(solid = true, elastic = false);
//elastic_test_print(solid = false, elastic = true);

























// asdf
