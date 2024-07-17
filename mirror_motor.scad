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

module motor_holder(outer_dia = 10) {
    color("steelblue") {
        translate([0, 0, -1.5]) cylinder(d = outer_dia, h = 1.5);
        difference() {
            cylinder(d = outer_dia, h = 3.4);
            
            union() {
                translate([0, 0, 1.9]) cube([4, 25, 4], center = true);
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

module mechanism_mount() {
    difference() {
        union() {
            color("plum") {
                translate([9, -23.5, 0]) cube([8, 23, 5]); // main lower brace
                translate([16.5, -4.5, 0]) cube([2.8, 4, 5]); // minor lower brace
                translate([9, -23.5, 0]) beveled_cube([16.5, 4, 8], [0, 1, 0], 0.5); // outer bottom-right axle brace
                translate([9, -7.7, 0]) beveled_cube([16.5, 3.5, 8], [0, 1, 0], 0.5); // adjust this thickness, inner brace
            }
            
            // bottom-right large gear bracing
            color("peru") {
                translate([21.85, -14.635, 8.1]) difference() {
                    cylinder(d = 11, h = 2);
                    union() {
                        translate([0, 0, -0.1]) cylinder(d = 9, h = 2.2);
                        translate([5, 0, 0]) rotate([0, 0, 45]) cube([6, 6, 4.5], center = true);
                    }
                }
                
                // bottom-right lower supports
                translate([19.85, -21, 7]) cube([4, 2.2, 3]);
                translate([16.85, -10.2, 7.5]) cube([7, 4.5, 2.5]);
                translate([15.5, -16.5, 0]) cube([2, 4, 10]);
            
                // bottom-right upper stops
                translate([19, -26, 3]) beveled_cube([6, 4, 11.5], [1, 0, 1], 0.5);
                translate([19, -7.7, 5]) beveled_cube([6, 3.5, 9.5], [1, 0, 1], 0.5);
                translate([19, -24, 12.3]) cube([6, 18, 2.2]);
                translate([22, -14.635, 15]) cube([6, 6, 4], center = true);
            }
            
            color("plum") translate([-0.9, -19, 0]) cube([10, 18.5, 5]); // left side main brace
            
            color("peru") {
                // left axle supports
                translate([0, -7.9, 15]) beveled_cube([7, 3.7, 10], [0, 1, 0], 0.5);
                translate([0, -7.9, 10]) cube([7, 6.2, 9]);
                translate([1, -14, 9.5]) cube([5, 7, 3]);
                translate([1, -18.3, 19.3]) beveled_cube([5, 5, 5], [0, 1, 0], 0.5); // needs to be supported // TODO
            }
            
            difference() {
                translate([14.75, -14.635, 14.256]) motor_holder(outer_dia = 12); // right motor mount
                translate([22, -14.635, 15]) cube([5, 5.9, 3.9], center = true);
            }
            
            translate([3.556, -15, 14.85]) rotate([90, 135, 0]) motor_holder(outer_dia = 11.5); // left motor mount
            
            color("peru") difference() {
                translate([0.3, -18, 4.9]) cube([6, 4, 7]);
                union() {
                    translate([3.3, -18.5, 15]) rotate([-90, 0, 0]) cylinder(d = 11, h = 5);
                    translate([4.57756, -18.5, 11]) rotate([0, 45, 0]) cube([3, 5, 3]);
                }
            }
            
            color("peru") translate([10, -16.2, 4.9]) cube([2, 3, 8]);
        }
        
        // difference operations between such complicated meshes is quite expensive
        //mechanism(3d_print = true, hex_bores = true, tol_boxes = true);
    }
}

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

elastic_test_print(solid = true, elastic = false);
elastic_test_print(solid = false, elastic = true);

//import_mirror(convexity = 1);
//_render("red") mount();

/*_render("orange")*/ //mechanism(3d_print = true, hex_bores = true, tol_boxes = false);
//mechanism_mount();

// translate([-20, -20, 0]) cube([19.74, 8.34, 23.25]); // servo motor size

























// asdf
