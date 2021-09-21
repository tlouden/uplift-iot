//////////////////////////////////////////////////////////////////////
// LibFile: partitions.scad
//   Modules to help partition large objects into smaller parts that can be reassembled. 
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/partitions.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Partitioning


_partition_cutpaths = [
    ["flat",       [[0,0],[1,0]]],
    ["sawtooth",   [[0,-0.5], [0.5,0.5], [1,-0.5]]],
    ["sinewave",   [for (a=[0:5:360]) [a/360,sin(a)/2]]],
    ["comb",       let(dx=0.5*sin(2)) [[0,0],[0+dx,0.5],[0.5-dx,0.5],[0.5+dx,-0.5],[1-dx,-0.5],[1,0]]],
    ["finger",     let(dx=0.5*sin(20)) [[0,0],[0+dx,0.5],[0.5-dx,0.5],[0.5+dx,-0.5],[1-dx,-0.5],[1,0]]],
    ["dovetail",   [[0,-0.5], [0.3,-0.5], [0.2,0.5], [0.8,0.5], [0.7,-0.5], [1,-0.5]]],
    ["hammerhead", [[0,-0.5], [0.35,-0.5], [0.35,0], [0.15,0], [0.15,0.5], [0.85,0.5], [0.85,0], [0.65,0], [0.65,-0.5],[1,-0.5]]],
    ["jigsaw",     concat(
                        arc(N=6, r=5/16, cp=[0,-3/16],  start=270, angle=125),
                        arc(N=12, r=5/16, cp=[1/2,3/16], start=215, angle=-250),
                        arc(N=6, r=5/16, cp=[1,-3/16],  start=145, angle=125)
                    )
    ],
];


function _partition_cutpath(l, h, cutsize, cutpath, gap) =
    let(
        check = assert(is_finite(l))
            assert(is_finite(h))
            assert(is_finite(gap))
            assert(is_finite(cutsize) || is_vector(cutsize,2))
            assert(is_string(cutpath) || is_path(cutpath,2)),
        cutsize = is_vector(cutsize)? cutsize : [cutsize*2, cutsize],
        cutpath = is_path(cutpath)? cutpath : (
            let(idx = search([cutpath], _partition_cutpaths))
            idx==[[]]? assert(in_list(cutpath,_partition_cutpaths,idx=0)) :
            _partition_cutpaths[idx.x][1]
        ),
        reps = ceil(l/(cutsize.x+gap)),
        cplen = (cutsize.x+gap) * reps,
        path = deduplicate(concat(
            [[-l/2, cutpath[0].y*cutsize.y]],
            [for (i=[0:1:reps-1], pt=cutpath) vmul(pt,cutsize)+[i*(cutsize.x+gap)+gap/2-cplen/2,0]],
            [[ l/2, cutpath[len(cutpath)-1].y*cutsize.y]]
        ))
    ) path;


// Module: partition_mask()
// Usage:
//   partition_mask(l, w, h, [cutsize], [cutpath], [gap], [inverse], [spin], [orient]);
// Description:
//   Creates a mask that you can use to difference or intersect with an object to remove half of it, leaving behind a side designed to allow assembly of the sub-parts.
// Arguments:
//   l = The length of the cut axis.
//   w = The width of the part to be masked, back from the cut plane.
//   h = The height of the part to be masked.
//   cutsize = The width of the cut pattern to be used.
//   cutpath = The cutpath to use.  Standard named paths are "flat", "sawtooth", "sinewave", "comb", "finger", "dovetail", "hammerhead", and "jigsaw".  Alternatively, you can give a cutpath as a 2D path, where X is between 0 and 1, and Y is between -0.5 and 0.5.
//   gap = Empty gaps between cutpath iterations.  Default: 0
//   inverse = If true, create a cutpath that is meant to mate to a non-inverted cutpath.
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#orient).  Default: `UP`
// Examples:
//   partition_mask(w=50, gap=0, cutpath="jigsaw");
//   partition_mask(w=50, gap=30, cutpath="jigsaw");
//   partition_mask(w=50, gap=30, cutpath="jigsaw", inverse=true);
//   partition_mask(w=50, gap=30, cutsize=15, cutpath="jigsaw");
//   partition_mask(w=50, cutsize=[20,20], gap=30, cutpath="jigsaw");
// Examples(2D):
//   partition_mask(w=20, cutpath="sawtooth");
//   partition_mask(w=20, cutpath="sinewave");
//   partition_mask(w=20, cutpath="comb");
//   partition_mask(w=20, cutpath="finger");
//   partition_mask(w=20, cutpath="dovetail");
//   partition_mask(w=20, cutpath="hammerhead");
//   partition_mask(w=20, cutpath="jigsaw");
module partition_mask(l=100, w=100, h=100, cutsize=10, cutpath=undef, gap=0, inverse=false, spin=0, orient=UP)
{
    cutsize = is_vector(cutsize)? point2d(cutsize) : [cutsize*2, cutsize];
    path = _partition_cutpath(l, h, cutsize, cutpath, gap);
    fullpath = concat(path, [[l/2,w*(inverse?-1:1)], [-l/2,w*(inverse?-1:1)]]);
    rot(from=UP,to=orient) {
        rotate(spin) {
            linear_extrude(height=h, convexity=10) {
                offset(delta=-$slop) polygon(fullpath);
            }
        }
    }
}


// Module: partition_cut_mask()
// Usage:
//   partition_cut_mask(l, w, h, [cutsize], [cutpath], [gap], [inverse], [spin], [orient]);
// Description:
//   Creates a mask that you can use to difference with an object to cut it into two sub-parts that can be assembled.
// Arguments:
//   l = The length of the cut axis.
//   w = The width of the part to be masked, back from the cut plane.
//   h = The height of the part to be masked.
//   cutsize = The width of the cut pattern to be used.
//   cutpath = The cutpath to use.  Standard named paths are "flat", "sawtooth", "sinewave", "comb", "finger", "dovetail", "hammerhead", and "jigsaw".  Alternatively, you can give a cutpath as a 2D path, where X is between 0 and 1, and Y is between -0.5 and 0.5.
//   gap = Empty gaps between cutpath iterations.  Default: 0
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#orient).  Default: `UP`
// Examples:
//   partition_cut_mask(gap=0, cutpath="dovetail");
//   partition_cut_mask(gap=30, cutpath="dovetail");
//   partition_cut_mask(gap=30, cutsize=15, cutpath="dovetail");
//   partition_cut_mask(gap=30, cutsize=[20,20], cutpath="dovetail");
// Examples(2DMed):
//   partition_cut_mask(cutpath="sawtooth");
//   partition_cut_mask(cutpath="sinewave");
//   partition_cut_mask(cutpath="comb");
//   partition_cut_mask(cutpath="finger");
//   partition_cut_mask(cutpath="dovetail");
//   partition_cut_mask(cutpath="hammerhead");
//   partition_cut_mask(cutpath="jigsaw");
module partition_cut_mask(l=100, h=100, cutsize=10, cutpath=undef, gap=0, spin=0, orient=UP)
{
    cutsize = is_vector(cutsize)? cutsize : [cutsize*2, cutsize];
    path = _partition_cutpath(l, h, cutsize, cutpath, gap);
    rot(from=UP,to=orient) {
        rotate(spin) {
            linear_extrude(height=h, convexity=10) {
                stroke(path, width=$slop*2);
            }
        }
    }
}


// Module: partition()
// Usage:
//   partition(size, [spread], [cutsize], [cutpath], [gap], [spin]) ...
// Description:
//   Partitions an object into two parts, spread apart a small distance, with matched joining edges.
// Arguments:
//   size = The [X,Y,Z] size of the object to partition.
//   spread = The distance to spread the two parts by.
//   cutsize = The width of the cut pattern to be used.
//   cutpath = The cutpath to use.  Standard named paths are "flat", "sawtooth", "sinewave", "comb", "finger", "dovetail", "hammerhead", and "jigsaw".  Alternatively, you can give a cutpath as a 2D path, where X is between 0 and 1, and Y is between -0.5 and 0.5.
//   gap = Empty gaps between cutpath iterations.  Default: 0
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#spin).  Default: `0`
// Examples(Med):
//   partition(spread=12, cutpath="dovetail") cylinder(h=50, d=80, center=false);
//   partition(spread=12, gap=30, cutpath="dovetail") cylinder(h=50, d=80, center=false);
//   partition(spread=20, gap=20, cutsize=15, cutpath="dovetail") cylinder(h=50, d=80, center=false);
//   partition(spread=25, gap=15, cutsize=[20,20], cutpath="dovetail") cylinder(h=50, d=80, center=false);
// Examples(2DMed):
//   partition(cutpath="sawtooth") cylinder(h=50, d=80, center=false);
//   partition(cutpath="sinewave") cylinder(h=50, d=80, center=false);
//   partition(cutpath="comb") cylinder(h=50, d=80, center=false);
//   partition(cutpath="finger") cylinder(h=50, d=80, center=false);
//   partition(spread=12, cutpath="dovetail") cylinder(h=50, d=80, center=false);
//   partition(spread=12, cutpath="hammerhead") cylinder(h=50, d=80, center=false);
//   partition(cutpath="jigsaw") cylinder(h=50, d=80, center=false);
module partition(size=100, spread=10, cutsize=10, cutpath=undef, gap=0, spin=0)
{
    size = is_vector(size)? size : [size,size,size];
    cutsize = is_vector(cutsize)? cutsize : [cutsize*2, cutsize];
    rsize = vabs(rot(spin,p=size));
    vec = rot(spin,p=BACK)*spread/2;
    move(vec) {
        intersection() {
            children();
            partition_mask(l=rsize.x, w=rsize.y, h=rsize.z, cutsize=cutsize, cutpath=cutpath, gap=gap, spin=spin);
        }
    }
    move(-vec) {
        intersection() {
            children();
            partition_mask(l=rsize.x, w=rsize.y, h=rsize.z, cutsize=cutsize, cutpath=cutpath, gap=gap, inverse=true, spin=spin);
        }
    }
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
