include <BOSL2/std.scad>
include <BOSL2/rounding.scad>
include <Libraries/calibration.scad>

/* [Rendering Selection] */
Part_To_Render="none"; // [none, full_assembly, bottom, top]

/* [General] */
//width of pcb (x-axis)
pcb_width=52.1;
//length of pcb (y-axis)
pcb_length=58.4;
//distance from inside wall of enclosure to edge of pcb
pcb_right_offset=2.0;
//distance from inside wall of enclosure to edge of pcb
pcb_left_offset=2.0;
//distance from inside wall of enclosure to edge of pcb
pcb_bottom_offset=2.0;
//distance from inside wall of enclosure to edge of pcb
pcb_top_offset=2.0;
//diameter of pcb mounting screws hole
pcb_mounting_screw_hole_diameter=2.5;
//height of pcb standoffs
standoff_height=3.0;
//standoff offset from edge of pcb to center of standoff (assumes symetric holes)
standoff_offset_x=5.0;
//standoff offset from edge of pcb to center of standoff (assumes symetric holes)
standoff_offset_y=3.8;
//distance from bottom of pcb to bottom of rj45 connector hole
rj45_pcb_to_bottom=1.6;
//height of rj45 connector hole (this determines the height of the enclosure)
rj45_height=17.4;
//distance from edge of pcb to edge of rj45 connector hole
rj45_left_offset=10.7;
//width of rj45 connector hole
rj45_width=15.4;
//distance between top of rj45 connector and bottom of lid
rj54_top_to_lid_bottom=5.7;
//width of vent slots
vent_size=2.5;
//margin from edge of lid to edge of venting
vent_free_margin=10.0;

/* [Adjustments] */
min_wall_size=2.0;
snap_fit_size=1.0;

/* [Hidden] */
$debug=false;
$overlap=0.001;
$fn=60;

//Calculated
$slop_tight=$slop*slop_tight_multiple;
$slop_tight_metal_round=$slop*slop_tight_metal_round_multiple;
$slop_tight_metal_square=$slop*slop_tight_metal_square_multiple;
$slop_free=$slop*slop_free_multiple;
enclosure_wall_size=min_wall_size+snap_fit_size+$slop_free;
enclosure_inner_width=pcb_width+pcb_right_offset+pcb_left_offset;
enclosure_width=enclosure_inner_width+2*enclosure_wall_size;
enclosure_inner_length=pcb_length+pcb_bottom_offset+pcb_top_offset;
enclosure_length=enclosure_inner_length+2*enclosure_wall_size;
enclosure_bottom_inner_height=standoff_height+rj45_pcb_to_bottom+rj45_height;
enclosure_bottom_height=min_wall_size+enclosure_bottom_inner_height;
snapfit_cutout_width=snap_fit_size+$slop_free+$overlap;
standoff_diameter=pcb_mounting_screw_hole_diameter+2*min_wall_size;
snapfit_corner_size=4*snap_fit_size+min_wall_size;
vent_x=vent_free_margin;
vent_width=enclosure_width-2*vent_free_margin;
vent_count=floor((enclosure_length-2*vent_free_margin-vent_size)/(2*vent_size))+1;
vent_y_start=enclosure_length/2-(vent_count*2*vent_size-vent_size)/2;

/* DEBUGGING */
if ($debug==true) {
    echo(slop=$slop);
    echo(slop_free=$slop_free);
}

if (Part_To_Render=="full_assembly") render_assembled();
if (Part_To_Render=="bottom") bottom();
if (Part_To_Render=="top") top();


module render_assembled() {
    bottom();
    translate([0, 0, enclosure_bottom_height+2])
    top();
}

module bottom() {
    union() {
        difference() {
            //enclosing
            cuboid([enclosure_width, enclosure_length, enclosure_bottom_height], anchor=FRONT+LEFT+BOTTOM, rounding=min_wall_size, except_edges=[TOP]);
            //inside
            translate([enclosure_wall_size, enclosure_wall_size, min_wall_size])
            cuboid([enclosure_inner_width, enclosure_inner_length, enclosure_bottom_inner_height+$overlap], anchor=FRONT+LEFT+BOTTOM, rounding=min_wall_size, except_edges=[TOP]);
            //rj45 - bottom
            translate([rj45_left_offset+pcb_left_offset+enclosure_wall_size, -$overlap, enclosure_bottom_height-rj45_height])
            cube([rj45_width, enclosure_wall_size+2*$overlap, rj45_height+$overlap]);
            //rj45 - top
            translate([rj45_left_offset+pcb_left_offset+enclosure_wall_size, enclosure_length-enclosure_wall_size-$overlap, enclosure_bottom_height-rj45_height])
            cube([rj45_width, enclosure_wall_size+2*$overlap, rj45_height+$overlap]);
            //snapfit
            translate([enclosure_wall_size+min_wall_size, min_wall_size+$overlap, enclosure_bottom_height-enclosure_wall_size])
            snapfit_cutout();
            translate([enclosure_inner_width-snapfit_cutout_width-min_wall_size, min_wall_size+$overlap, enclosure_bottom_height-enclosure_wall_size])
            snapfit_cutout();
            translate([enclosure_wall_size+min_wall_size, enclosure_inner_length+enclosure_wall_size-$overlap, enclosure_bottom_height-enclosure_wall_size])
            snapfit_cutout();
            translate([enclosure_inner_width-snapfit_cutout_width-min_wall_size, enclosure_inner_length+enclosure_wall_size-$overlap, enclosure_bottom_height-enclosure_wall_size])
            snapfit_cutout();
        }
        //standoffs
        translate([standoff_offset_x+enclosure_wall_size+pcb_left_offset, standoff_offset_y+enclosure_wall_size+pcb_bottom_offset, min_wall_size])
        standoff();
        translate([enclosure_wall_size+enclosure_inner_width-(standoff_offset_x+pcb_left_offset), standoff_offset_y+enclosure_wall_size+pcb_bottom_offset, min_wall_size])
        standoff();
        translate([standoff_offset_x+enclosure_wall_size+pcb_left_offset, enclosure_wall_size+enclosure_inner_length-(standoff_offset_y+pcb_top_offset), min_wall_size])
        standoff();
        translate([enclosure_wall_size+enclosure_inner_width-(standoff_offset_x+pcb_left_offset), enclosure_wall_size+enclosure_inner_length-(standoff_offset_y+pcb_top_offset), min_wall_size])
        standoff();
    }
}

module top() {
    union() {
        //plate
        difference() {
            cuboid([enclosure_width, enclosure_length, min_wall_size], anchor=FRONT+LEFT+BOTTOM, rounding=min_wall_size, except_edges=[BOTTOM, TOP]);
            //ventilation
            for (i=[0:vent_count-1]) {
                translate([vent_x, vent_y_start+i*2*vent_size, -$overlap])
                cuboid([vent_width, vent_size, min_wall_size+2*$overlap], anchor=FRONT+LEFT+BOTTOM, rounding=vent_size/2, except_edges=[BOTTOM, TOP]);
            }
        }
        //snapfit corners
        translate([enclosure_wall_size+$slop, enclosure_wall_size+$slop, -enclosure_wall_size])
        snapfit_corner();
        translate([snapfit_corner_size+enclosure_inner_width-(enclosure_wall_size+$slop), snapfit_corner_size+enclosure_inner_length-(enclosure_wall_size+$slop), -enclosure_wall_size])
        rotate([0, 0, 180])
        snapfit_corner();
        translate([snapfit_corner_size+enclosure_inner_width-(enclosure_wall_size+$slop), enclosure_wall_size+$slop, -enclosure_wall_size])
        rotate([0, 0, 90])
        snapfit_corner(alt=true);
        translate([enclosure_wall_size+$slop, snapfit_corner_size+enclosure_inner_length-(enclosure_wall_size+$slop), -enclosure_wall_size])
        rotate([0, 0, 270])
        snapfit_corner(alt=true);
        //rj45 retentions
        translate([rj45_left_offset+pcb_left_offset+enclosure_wall_size+$slop_free/2, 0, -rj54_top_to_lid_bottom])
        cube([rj45_width-$slop_free, enclosure_wall_size, rj54_top_to_lid_bottom]);
        translate([rj45_left_offset+pcb_left_offset+enclosure_wall_size+$slop_free/2, enclosure_length-enclosure_wall_size, -rj54_top_to_lid_bottom])
        cube([rj45_width-$slop_free, enclosure_wall_size, rj54_top_to_lid_bottom]);
    }
}

module snapfit_corner(alt=false) {
    union() {
        cuboid([snapfit_corner_size, snapfit_corner_size, enclosure_wall_size], anchor=FRONT+LEFT+BOTTOM, rounding=min_wall_size, edges=[FRONT+LEFT]);
        if (alt) {
            translate([-snap_fit_size, min_wall_size+2*snap_fit_size, 0])
            cube([snap_fit_size, snap_fit_size, snap_fit_size]);
        } else {
            translate([min_wall_size+2*snap_fit_size, -snap_fit_size, 0])
            cube([snap_fit_size, snap_fit_size, snap_fit_size]);
        }
    }
}

module snapfit_cutout() {
    cube([4*snap_fit_size, snapfit_cutout_width, snap_fit_size+$slop_free]);
}

module standoff() {
    difference() {
        cylinder(r=standoff_diameter/2, h=standoff_height);
        cylinder(r=pcb_mounting_screw_hole_diameter/2+$slop, h=standoff_height+$overlap);
    }
}

