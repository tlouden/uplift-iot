/*
Calibration library supports the adjustments in sizing required to get best results on mechanical designs based on the variations between each printer.  It builds on the concept of $slop seen in BOSL2, and requires other parts of the library to work.
Usage:
    BOSL2
        Correct the path in the include statements below to point to BOSL2 library
    Direct
        render and print 0_shaft
        render and print 1_slop
        determine value for $slop based on the hole in 1_slop that best fits 0_shaft
            goal is the smallest value that doesn't require extra force to insert or remove
            put this value into the file (not just the customizer parameters)
        render and print 2_multiples
        determine values according to below
            slop_free_multiple
                smallest value that allows unresisted movement of 0_shaft through holes
            slop_tight_multiple
                best* value that creates a press-fit connection between 0_shaft and cubes holes
            slop_tight_metal_round_multiple
                best* value that creates a press-fit connection between metal rod and round holes
            slop_tight_metal_square_multiple
                best* value that creates a press-fit connection between metal rod and cubes holes
        put these values into the file (not just the customizer parameters)
        change the value of calibration_complete to true below (not just the customizer parameter)
        
        * note on best value for slop_tight_* multiples
            press-fit connection should be removable by hand, but not easily
            too large a value allows the part to come out accidentally
            too small a value makes insertion imposible
            if you never intend to remove the parts, a smaller value may work
    Including
        ensure calibration is complete per above
        include like a normal library (eg. include <Libraries/calibration.scad>)
*/

include <../BOSL2/std.scad>
include <../BOSL2/rounding.scad>

/* [Calibration] */
//printer specific amount of slop to make parts fit (mm)
$slop=0.10;
//multiply the slop by a multiple to make a free moving fit
slop_free_multiple=1.2;
//multiply the slop by a multiple to make a tight/press fit
slop_tight_multiple=-0.1;
//multiply the slop by a multiple to make a tight/press fit round hole with a metal rod
slop_tight_metal_round_multiple=1.2;
//multiply the slop by a multiple to make a tight/press fit square hole with a metal rod
slop_tight_metal_square_multiple=-0.8;
//set this to true when done calibrating, otherwise including the file can throw an assertion error
calibration_complete=true;

/* [General] */
Calibration_Stage="none"; // [none, 0_shaft, 1_slop, 2_multiples]
//print calibration options with this increment for the value of slop (mm)
slop_calibration_increment=0.02;
//print calibration options with this increment for the value of multiples
slop_multiple_increment=0.2;
//print this many calibration options
slop_calibration_count=5;
//edge size of the calibration shaft (mm)
calibration_shaft_size=6;
//length of the calibration shaft (mm)
calibration_shaft_length=20;
//diameter of metal rod for calibrating press-fit holes (mm)
calibration_rod_diameter=2;
//teardrop profile prevents buldge from first few layers (mm)
teardrop_radius=1.5;
//minimum distance between a hole and edge (mm)
min_wall_size=2;
//depth of text on calibration prints, set this to layer height (mm)
text_depth=0.2;
//margin between text and edges (mm)
text_margin=1;
//smallest text size (mm)
min_text_size=3;

/* [Hidden] */
$overlap=0.001;
$fn=60;

assert(calibration_complete==true || Calibration_Stage!="none", "calibration must be completed, select a Calibration_Stage")

if (Calibration_Stage=="0_shaft") calibration_0_shaft();
if (Calibration_Stage=="1_slop") calibration_1_slop();
if (Calibration_Stage=="2_multiples") calibration_2_multiples();

module calibration_0_shaft() {
    cube_size=calibration_shaft_size;
    shaft=square(cube_size, center=true);
    offset_sweep(shaft, height=calibration_shaft_length, bottom=os_teardrop(r=teardrop_radius));
}

module calibration_1_slop() {
    start_slop=$slop-floor((slop_calibration_count-1)/2)*slop_calibration_increment;
    cube_size=calibration_shaft_size;
    text_size=max(min_text_size,(cube_size+(start_slop+slop_calibration_increment*(slop_calibration_count-1))+2*min_wall_size)/3);
    hole_offset=(3*text_size-cube_size)/2;
    //holes
    difference() {
        cube([slop_calibration_count*3*text_size, cube_size+min_wall_size+text_size+2*text_margin, cube_size]);
        for (i=[0:slop_calibration_count-1]) {
            s=start_slop+i*slop_calibration_increment;
            assert(s<1,"$slop of 1mm is too large");
            translate([i*text_size*3+text_margin, text_margin, cube_size-text_depth+$overlap])
            linear_extrude(height=text_depth) {
                text(text=format_decimal(s, trailing_zeros=2, leading_zero=false), font="Arial:style=Bold", size=text_size);
            }
            hole_size=(cube_size+s);
            hole=square(hole_size, center=false);
            translate([i*text_size*3+hole_offset-(s/2), 2*text_margin+text_size, -$overlap])
            offset_sweep(hole, height=(cube_size+2*$overlap), bottom=os_teardrop(r=-teardrop_radius));
        }
    }
}

module calibration_2_multiples() {
    cube_size=calibration_shaft_size;
    rod_depth=3*calibration_rod_diameter;
    max_cube_size=cube_size+$slop*(slop_free_multiple+(slop_calibration_count-1)*slop_multiple_increment);
    max_rod_diameter=calibration_rod_diameter+$slop*(max(slop_tight_metal_round_multiple,slop_tight_metal_square_multiple));
    text_size=max(min_text_size,(max(max_rod_diameter,max_cube_size)+2*min_wall_size)/3);
    hole_offset=(3*text_size-cube_size)/2;
    free_region_height=max_cube_size+min_wall_size+text_size+2*text_margin;
    tight_region_height=free_region_height;
    tight_metal_round_region_height=max_rod_diameter+min_wall_size+text_size+2*text_margin;
    tight_metal_square_region_height=max_rod_diameter+min_wall_size+text_size+2*text_margin;
    
    translate([cube_size, cube_size, 0])
    difference() {
        cube([slop_calibration_count*3*text_size, free_region_height+tight_region_height+tight_metal_round_region_height+tight_metal_square_region_height, rod_depth+min_wall_size]);
        //slop label
        translate([text_margin, text_depth-$overlap, text_margin])
        rotate([90, 0, 0])
        linear_extrude(height=text_depth) {
            text(text=format_decimal($slop, trailing_zeros=2, leading_zero=true), font="Arial:style=Bold", size=text_size);
        }
        //free
        for (i=[0:slop_calibration_count-1]) {
            m=slop_free_multiple+i*slop_multiple_increment;
            s=$slop*m;
            translate([i*text_size*3+text_margin, text_margin+tight_region_height+tight_metal_round_region_height+tight_metal_square_region_height, min_wall_size+rod_depth-text_depth+$overlap])
            linear_extrude(height=text_depth) {
                text(text=format_decimal(m, trailing_zeros=1, leading_zero=true), font="Arial:style=Bold", size=text_size);
            }
            hole_size=(cube_size+s);
            hole=square(hole_size, center=false);
            translate([i*text_size*3+hole_offset-(s/2), 2*text_margin+text_size+tight_region_height+tight_metal_round_region_height+tight_metal_square_region_height, -$overlap])
            offset_sweep(hole, height=(rod_depth+min_wall_size+2*$overlap), bottom=os_teardrop(r=-teardrop_radius));
        }
        //tight
        for (i=[0:slop_calibration_count-1]) {
            m=slop_tight_multiple-i*slop_multiple_increment;
            s=$slop*m;
            translate([i*text_size*3+text_margin, text_margin+tight_metal_round_region_height+tight_metal_square_region_height, min_wall_size+rod_depth-text_depth+$overlap])
            linear_extrude(height=text_depth) {
                text(text=format_decimal(m, trailing_zeros=1, leading_zero=true), font="Arial:style=Bold", size=text_size);
            }
            hole_size=(cube_size+s);
            translate([i*text_size*3+hole_offset-(s/2), 2*text_margin+text_size+tight_metal_round_region_height+tight_metal_square_region_height, min_wall_size])
            cube([hole_size, hole_size, rod_depth+$overlap]);
        }
        //tight_metal_round
        for (i=[0:slop_calibration_count-1]) {
            m=slop_tight_metal_round_multiple-i*slop_multiple_increment;
            s=$slop*m;
            translate([i*text_size*3+text_margin, text_margin+tight_metal_square_region_height, min_wall_size+rod_depth-text_depth+$overlap])
            linear_extrude(height=text_depth) {
                text(text=format_decimal(m, trailing_zeros=1, leading_zero=true), font="Arial:style=Bold", size=text_size);
            }
            hole_size=(calibration_rod_diameter+s);
            translate([(i+0.5)*text_size*3, 2*text_margin+text_size+min_wall_size+tight_metal_square_region_height, min_wall_size])
            cylinder(d=hole_size, h=rod_depth+$overlap, center=false);
        }
        //tight_metal_square
        for (i=[0:slop_calibration_count-1]) {
            m=slop_tight_metal_square_multiple-i*slop_multiple_increment;
            s=$slop*m;
            translate([i*text_size*3+text_margin, text_margin, min_wall_size+rod_depth-text_depth+$overlap])
            linear_extrude(height=text_depth) {
                text(text=format_decimal(m, trailing_zeros=1, leading_zero=true), font="Arial:style=Bold", size=text_size);
            }
            hole_size=(calibration_rod_diameter+s);
            translate([(i+0.5)*text_size*3-hole_size/2, 2*text_margin+text_size, min_wall_size])
            cube([hole_size, hole_size, rod_depth+$overlap]);
        }
    }
}

function format_decimal(d, trailing_zeros=0, leading_zero=false) =
    let ( s_1 = d<0 ? "-" : "" )
    let ( s_2 = leading_zero==false && floor(abs(d))==0 ? "" : floor(abs(d)) )
    let ( s_3 = trailing_zeros==0 ? "" : "." )
    let ( s_4 = trailing_zeros==0 ? "" : decimal_position_concat(d=abs(d)-floor(abs(d)), depth=trailing_zeros) )
    str(s_1, s_2, s_3, s_4);

function decimal_position_concat(d, depth) = 
    let ( d_new = 10*(d-floor(d)))
    depth>1 ? str(floor(d_new),decimal_position_concat(d=d_new,depth=depth-1)) : str(round(d_new));