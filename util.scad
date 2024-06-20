//
// utility functions (so far beveled_cube and _render)
//

$fs = 0.01;
$fn = 100;

inf = 1 / 0; // positive infinity

module _render(col = "gold") {
    if (true && $preview) {
        color(col) render(convexity = 6) children();
    } else {
        color(col) children();
    }
}

/*
 cube_dims = [x, y, z]            : dimensions of cube to be beveled
 axes = [{0, 1}, {0, 1}, {0, 1}]  : whether to bevel edges perpendicular to corresponding axis
 ratio = (0, 0.707]                 : ratio of smallest (active) side length to bevel by
 */
module beveled_cube(cube_dims, axes, ratio = 0.1) {
    x = cube_dims[0];
    y = cube_dims[1];
    z = cube_dims[2];
    
    ax = axes[0] != 0;
    ay = axes[1] != 0;
    az = axes[2] != 0;
    
    r = min(ax ? min(y, z) : x, ay ? min(x, z) : y, az ? min(x, y) : z) * ratio;
    c = r / sqrt(2);
    
    union() {
        difference() {
            cube(cube_dims);
            
            // 45-deg cuts
            union() {
                if (ax) {
                    translate([x / 2, 0, 0]) rotate([45, 0, 0]) cube([x + 0.05, r, r], center = true);
                    translate([x / 2, y, 0]) rotate([45, 0, 0]) cube([x + 0.05, r, r], center = true);
                    translate([x / 2, 0, z]) rotate([45, 0, 0]) cube([x + 0.05, r, r], center = true);
                    translate([x / 2, y, z]) rotate([45, 0, 0]) cube([x + 0.05, r, r], center = true);
                }
                
                if (ay) {
                    translate([0, y / 2, 0]) rotate([0, 45, 0]) cube([r, y + 0.05, r], center = true);
                    translate([x, y / 2, 0]) rotate([0, 45, 0]) cube([r, y + 0.05, r], center = true);
                    translate([0, y / 2, z]) rotate([0, 45, 0]) cube([r, y + 0.05, r], center = true);
                    translate([x, y / 2, z]) rotate([0, 45, 0]) cube([r, y + 0.05, r], center = true);
                }
                
                if (az) {
                    translate([0, 0, z / 2]) rotate([0, 0, 45]) cube([r, r, z + 0.05], center = true);
                    translate([x, 0, z / 2]) rotate([0, 0, 45]) cube([r, r, z + 0.05], center = true);
                    translate([0, y, z / 2]) rotate([0, 0, 45]) cube([r, r, z + 0.05], center = true);
                    translate([x, y, z / 2]) rotate([0, 0, 45]) cube([r, r, z + 0.05], center = true);
                }
            }
        }
        
        // bevels, always use spheres on corners (this is wrong probably complicated to make precise)
        if (ax) {
            shorter = ay || az;
            
            translate([x / 2, c,     c    ]) rotate([0, 90, 0]) cylinder(r = c, h = shorter ? x - 2 * c : x, center = true);
            translate([x / 2, y - c, c    ]) rotate([0, 90, 0]) cylinder(r = c, h = shorter ? x - 2 * c : x, center = true);
            translate([x / 2, c,     z - c]) rotate([0, 90, 0]) cylinder(r = c, h = shorter ? x - 2 * c : x, center = true);
            translate([x / 2, y - c, z - c]) rotate([0, 90, 0]) cylinder(r = c, h = shorter ? x - 2 * c : x, center = true);
        }
        
        if (ay) {
            shorter = ax || az;
            
            translate([c,     y / 2, c    ]) rotate([90, 0, 0]) cylinder(r = c, h = shorter ? y - 2 * c : y, center = true);
            translate([x - c, y / 2, c    ]) rotate([90, 0, 0]) cylinder(r = c, h = shorter ? y - 2 * c : y, center = true);
            translate([c,     y / 2, z - c]) rotate([90, 0, 0]) cylinder(r = c, h = shorter ? y - 2 * c : y, center = true);
            translate([x - c, y / 2, z - c]) rotate([90, 0, 0]) cylinder(r = c, h = shorter ? y - 2 * c : y, center = true);
        }
        
        if (az) {
            shorter = ax || ay;
            
            translate([c,     c,     z / 2]) cylinder(r = c, h = shorter ? z - 2 * c : z, center = true);
            translate([x - c, c,     z / 2]) cylinder(r = c, h = shorter ? z - 2 * c : z, center = true);
            translate([c,     y - c, z / 2]) cylinder(r = c, h = shorter ? z - 2 * c : z, center = true);
            translate([x - c, y - c, z / 2]) cylinder(r = c, h = shorter ? z - 2 * c : z, center = true);
        }
        
        // just use spheres if all axes are to be beveled
        if (ax && ay && az) {
            translate([c,     c,     c    ]) sphere(r = c);
            translate([c,     c,     z - c]) sphere(r = c);
            translate([c,     y - c, c    ]) sphere(r = c);
            translate([c,     y - c, z - c]) sphere(r = c);
            translate([x - c, c,     c    ]) sphere(r = c);
            translate([x - c, c,     z - c]) sphere(r = c);
            translate([x - c, y - c, c    ]) sphere(r = c);
            translate([x - c, y - c, z - c]) sphere(r = c);
        } else { // otherwise we use the intersection of two cylinders for paired axes
            for (nx = [c, x - c]) {
                for (ny = [c, y - c]) {
                    for (nz = [c, z - c]) {
                        if (ax && ay) {
                            intersection() {
                                translate([x / 2, ny, nz]) rotate([0, 90, 0]) cylinder(r = c, h = x, center = true);
                                translate([nx, y / 2, nz]) rotate([90, 0, 0]) cylinder(r = c, h = y, center = true);
                            }
                        } else if (ax && az) {
                            intersection() {
                                translate([nx, ny, z / 2]) cylinder(r = c, h = z, center = true);
                                translate([x / 2, ny, nz]) rotate([0, 90, 0]) cylinder(r = c, h = x, center = true);
                            }
                        } else if (ay && az) {
                            intersection() {
                                translate([nx, ny, z / 2]) cylinder(r = c, h = z, center = true);
                                translate([nx, y / 2, nz]) rotate([90, 0, 0]) cylinder(r = c, h = y, center = true);
                            }
                        }
                    }
                }
            }
        } // otherwise we dont add anything (length of cylinder is conditionally adjusted)
    }
}

beveled_cube([5, 6, 7], [0, 1, 1]);
