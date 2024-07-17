//
// mini stepper motor
// (https://www.amazon.com/Abovehill-Stepper-2-Phase-4-Wire-Connection/dp/B08346RFVZ/ref=pd_bxgy_d_sccl_1/136-7700863-2406023?pd_rd_w=IDu0U&content-id=amzn1.sym.c51e3ad7-b551-4b1a-b43c-3cf69addb649&pf_rd_p=c51e3ad7-b551-4b1a-b43c-3cf69addb649&pf_rd_r=NNP239HPWDPKZRQ4SN6C&pd_rd_wg=J23e9&pd_rd_r=8c85098f-a1b3-4aa4-8d58-038ba692a794&pd_rd_i=B08346RFVZ&psc=1)
//

$fs = 0.1;

use<gears.scad>;

module mini_stepper(tol_boxes = false) {
    color("silver") difference() {
        union() {
            cylinder(d = 8, h = 8.3);
            translate([0, 0, 3.35]) cylinder(d = 8.36, h = 1.3);
            translate([3.2, 0, 7.3]) cylinder(d = 2.54, h = 1);
            translate([-3.2, 0, 7.3]) cylinder(d = 2.54, h = 1);
        }
        
        if (!tol_boxes) union() {
            translate([3, 0, 6]) cylinder(d = 1, h = 3);
            translate([-3, 0, 6]) cylinder(d = 1, h = 3);
            translate([0, -3, 6]) cylinder(d = 1, h = 3);
        }
    }
    
    translate([0, 0, 8.3]) {
        translate([0, 0, -0.05]) cylinder(d = 4, h = 1.65); // height is 1mm too high for tolerance
        color("silver") cylinder(d = 1.5, h = 3.99);
        if (!tol_boxes) translate([0, 0, 4 - 1.5]) spur_gear(modul = 2.05 / 9, tooth_number = 9, width = 1.5, bore = 0.8, optimized = false);
        if (tol_boxes) color("orange") translate([0, 0, 4 - 1.5]) cylinder(d = 2.4, h = 1.5);
    }
    
    color("green") if (!tol_boxes) rotate([0, 0, 35]) translate([-5, 0, 2]) cube([2.5, 5, 4], center = true);
}

mini_stepper(tol_boxes = false);
