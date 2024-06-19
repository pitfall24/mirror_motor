//
// M05 mirror mount model.
// Curved surfaces may be inaccurate and mirror holder is probably largely inaccurate
//

inch = 25.4;

$fs = 0.5;

module mounter() {
    module curved_geometry() {
        hull() {
            translate([0.34 * inch, 0.835 * inch, 0]) circle(d = 0.19 * inch);
            translate([0.135 * inch, 0.865 * inch, 0]) circle(r = 0.135 * inch);
            translate([0, 0.5 * inch, 0]) square([3.5, 1]);
        }
    }
    
    difference() {
        union() {
            cube([(2 / 3) * inch, 9.4, (2 / 3) * inch]);
            
            mirror([0, 1, 0]) {
                rotate([90, 0, 0]) {
                    linear_extrude(9.4) {
                        curved_geometry();
                        
                        // Reflects across y=x.
                        multmatrix(m = [[0, 1, 0, 0],
                                        [1, 0, 0, 0],
                                        [0, 0, 1, 0],
                                       ]) curved_geometry();
                    }
                }
            }
        }
        
        union() {
            translate([inch / 3, -1, inch / 3]) {
                cube([inch / 3 + 1, 12, inch / 3 + 1]);
                
                translate([0, -1, -inch / 12]) cube([inch / 3 + 1, 12, 5]);
                translate([-inch / 12, -1, 0]) cube([5, 12, inch / 3 + 1]);
            }
        }
    }
    
    // make sure to bevel corner of cube with some sort of subtraction.
}

module mirror_model(incidence = false, path = false) {
    translate([inch / 2, 15, inch / 2]) {
        rotate([-90, 0, 0]) {
            cylinder(h = 4, d = 12.7);
            
            if (incidence) {
                cylinder(h = 40, d = 12.7, center = true);
            }
            
            if (path) {
                cylinder(h = 40, d = 3, center = true);
            }
        }
    }
}

module import_mirror(convexity = 3) {
    import("./M05_centered.stl", convexity = convexity);
}

//translate([0, 1, 0]) mounter();
//mirror_model();

import_mirror();
