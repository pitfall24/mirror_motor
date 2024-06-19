//
// mini stepper motor
// (https://www.amazon.com/Abovehill-Stepper-2-Phase-4-Wire-Connection/dp/B08346RFVZ/ref=pd_bxgy_d_sccl_1/136-7700863-2406023?pd_rd_w=IDu0U&content-id=amzn1.sym.c51e3ad7-b551-4b1a-b43c-3cf69addb649&pf_rd_p=c51e3ad7-b551-4b1a-b43c-3cf69addb649&pf_rd_r=NNP239HPWDPKZRQ4SN6C&pd_rd_wg=J23e9&pd_rd_r=8c85098f-a1b3-4aa4-8d58-038ba692a794&pd_rd_i=B08346RFVZ&psc=1)
//

$fs = 0.1;

use<gears.scad>;

module mini_stepper() {
    color("silver") difference() {
        union() {
            cylinder(d = 8, h = 8.2);
            translate([3.2, 0, 7.2]) cylinder(d = 3, h = 1);
            translate([-3.2, 0, 7.2]) cylinder(d = 3, h = 1);
        }
        
        union() {
            translate([3, 0, 6]) cylinder(d = 1, h = 3);
            translate([-3, 0, 6]) cylinder(d = 1, h = 3);
        }
    }
    
    translate([0, 0, 8.2]) {
        cylinder(d = 4, h = 0.8);
        color("silver") cylinder(d = 1.5, h = 3.99);
        translate([0, 0, 4 - 1.8]) spur_gear(modul = 2.2 / 9, tooth_number = 9, width = 1.8, bore = 0.8, optimized = false);
    }
    
    color("green") rotate([0, 0, 35]) translate([-5, 0, 2]) cube([2.5, 5, 4], center = true);
}

mini_stepper();
