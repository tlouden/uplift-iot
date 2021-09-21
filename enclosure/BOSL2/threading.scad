//////////////////////////////////////////////////////////////////////
// LibFile: threading.scad
//   Triangular and Trapezoidal-Threaded Screw Rods and Nuts.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/threading.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Generic Threading

// Module: thread_helix()
// Usage:
//   thread_helix(base_d, pitch, thread_depth, thread_angle, twist, [profile], [left_handed], [higbee], [internal]);
// Description:
//   Creates a helical thread with optional end tapering.
// Arguments:
//   base_d = Inside base diameter of threads.
//   pitch = Distance between threads.
//   thread_depth = Depth of threads from top to bottom.
//   thread_angle = Angle of the thread faces.
//   twist = Number of degrees to rotate thread around.
//   profile = If a an asymmetrical thread profile is needed, it can be specified here.
//   left_handed = If true, thread has a left-handed winding.
//   higbee = Angle to taper thread ends by.
//   internal = If true, invert threads for internal threading.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example(2DMed): Typical Tooth Profile
//   pitch = 2;
//   depth = pitch * cos(30) * 5/8;
//   profile = [
//       [-7/16, -depth/pitch*1.07],
//       [-6/16, -depth/pitch],
//       [-1/16,  0],
//       [ 1/16,  0],
//       [ 6/16, -depth/pitch],
//       [ 7/16, -depth/pitch*1.07]
//   ];
//   stroke(profile, width=0.02);
module thread_helix(base_d, pitch, thread_depth=undef, thread_angle=15, twist=720, profile=undef, left_handed=false, higbee=60, internal=false, anchor=CENTER, spin=0, orient=UP)
{
    h = pitch*twist/360;
    r = base_d/2;
    dz = thread_depth/pitch * tan(thread_angle);
    cap = (1 - 2*dz)/2;
    profile = !is_undef(profile)? profile : (
        internal? [
            [thread_depth/pitch, -cap/2-dz],
            [0, -cap/2],
            [0, +cap/2],
            [thread_depth/pitch, +cap/2+dz],
        ] : [
            [0, +cap/2+dz],
            [thread_depth/pitch, +cap/2],
            [thread_depth/pitch, -cap/2],
            [0, -cap/2-dz],
        ]
    );
    pline = profile * pitch;
    dir = left_handed? -1 : 1;
    idir = internal? -1 : 1;
    attachable(anchor,spin,orient, r=r, l=h) {
        difference() {
            spiral_sweep(pline, h=h, r=base_d/2, twist=twist*dir, $fn=segs(base_d/2), anchor=CENTER);
            down(h/2) right(r) right(internal? thread_depth : 0) zrot(higbee*dir*idir) fwd(dir*pitch/2) cube([3*thread_depth/cos(higbee), pitch, pitch], center=true);
            up(h/2) zrot(twist*dir) right(r) right(internal? thread_depth : 0) zrot(-higbee*dir*idir) back(dir*pitch/2) cube([3*thread_depth/cos(higbee), pitch, pitch], center=true);
        }
        children();
    }
}



// Module: trapezoidal_threaded_rod()
// Description:
//   Constructs a generic trapezoidal threaded screw rod.  This method makes
//   much smoother threads than the naive linear_extrude method.
//   For metric trapezoidal threads, use thread_angle=15 and thread_depth=pitch/2.
//   For ACME threads, use thread_angle=14.5 and thread_depth=pitch/2.
//   For square threads, use thread_angle=0 and thread_depth=pitch/2.
//   For normal UTS or ISO screw threads, use the `threaded_rod()` module instead to get the correct thread profile.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = Length of threaded rod.
//   pitch = Length between threads.
//   thread_depth = Depth of the threads.  Default=pitch/2
//   thread_angle = The pressure angle profile angle of the threads.  Default = 14.5 degree ACME profile.
//   left_handed = If true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: true
//   starts = The number of lead starts.  Default = 1
//   internal = If true, make this a mask for making internal threads.
//   profile = The shape of a thread, if not a symmetric trapezoidal form.  Given as a 2D path, where X is between -1/2 and 1/2, representing the pitch distance, and Y is 0 for the peak, and `-depth/pitch` for the valleys.  The segment between the end of one thread profile and the start of the next is automatic, so the start and end coordinates should not both be at the same Y at X = ±1/2.  This path is scaled up by the pitch size in both dimensions when making the final threading.  This overrides the `thread_angle` and `thread_depth` options.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=UP`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Examples(Med):
//   trapezoidal_threaded_rod(d=10, l=40, pitch=2, thread_angle=15, $fn=32);
//   trapezoidal_threaded_rod(d=3/8*25.4, l=20, pitch=1/8*25.4, thread_angle=29, $fn=32);
//   trapezoidal_threaded_rod(d=60, l=16, pitch=8, thread_depth=3, thread_angle=45, left_handed=true, $fa=2, $fs=2);
//   trapezoidal_threaded_rod(d=60, l=16, pitch=8, thread_depth=3, thread_angle=45, left_handed=true, starts=4, $fa=2, $fs=2);
//   trapezoidal_threaded_rod(d=16, l=40, pitch=2, thread_angle=30);
//   trapezoidal_threaded_rod(d=10, l=40, pitch=3, thread_angle=15, left_handed=true, starts=3, $fn=36);
//   trapezoidal_threaded_rod(d=25, l=40, pitch=10, thread_depth=8/3, thread_angle=50, starts=4, center=false, $fa=2, $fs=2);
//   trapezoidal_threaded_rod(d=50, l=35, pitch=8, thread_angle=30, starts=3, bevel=true);
//   trapezoidal_threaded_rod(l=25, d=10, pitch=2, thread_angle=15, starts=3, $fa=1, $fs=1, orient=RIGHT, anchor=BOTTOM);
// Example(Med): Using as a Mask to Make Internal Threads
//   bottom_half() difference() {
//       cube(50, center=true);
//       trapezoidal_threaded_rod(d=40, l=51, pitch=5, thread_angle=30, internal=true, orient=RIGHT, $fn=36);
//   }
// Example(2DMed): Typical Tooth Profile
//   pitch = 2;
//   depth = pitch * cos(30) * 5/8;
//   profile = [
//       [-7/16, -depth/pitch*1.07],
//       [-6/16, -depth/pitch],
//       [-1/16,  0],
//       [ 1/16,  0],
//       [ 6/16, -depth/pitch],
//       [ 7/16, -depth/pitch*1.07]
//   ];
//   stroke(profile, width=0.02);
module trapezoidal_threaded_rod(
    d=10,
    l=100,
    pitch=2,
    thread_angle=15,
    thread_depth=undef,
    left_handed=false,
    bevel=false,
    starts=1,
    profile=undef,
    internal=false,
    center, anchor, spin=0, orient=UP
) {
    function _thread_pt(thread, threads, start, starts, astep, asteps, part, parts) =
        astep + asteps * (thread + threads * (part + parts * start));

    d = internal? (d/cos(180/segs(d/2)) + $slop*3) : d;
    astep = 360 / quantup(segs(d/2), starts);
    asteps = ceil(360/astep);
    threads = ceil(l/pitch/starts)+(starts<4?4-starts:1);
    depth = min((thread_depth==undef? pitch/2 : thread_depth), pitch/2/tan(thread_angle));
    pa_delta = min(pitch/4-0.01,depth*tan(thread_angle)/2)/pitch;
    dir = left_handed? -1 : 1;
    r1 = -depth/pitch;
    z1 = 1/4-pa_delta;
    z2 = 1/4+pa_delta;
    profile = profile!=undef? profile : [
        [-z2, r1],
        [-z1,  0],
        [ z1,  0],
        [ z2, r1],
    ];
    parts = len(profile);
    poly_points = concat(
        [
            for (
                start  = [0:1:starts-1],
                part   = [0:1:parts-1],
                thread = [0:1:threads-1],
                astep  = [0:1:asteps-1]
            ) let (
                ppt = profile[part] * pitch,
                dz = ppt.x,
                r = ppt.y + d/2,
                a = astep / asteps,
                c = cos(360 * (a * dir + start/starts)),
                s = sin(360 * (a * dir + start/starts)),
                z = (thread + a - threads/2) * starts * pitch
            ) [r*c, r*s, z+dz]
        ],
        [[0, 0, -threads*pitch*starts/2-pitch/4], [0, 0, threads*pitch*starts/2+pitch/4]]
    );
    point_count = len(poly_points);
    poly_faces = concat(
        // Thread surfaces
        [
            for (
                start  = [0:1:starts-1],
                part   = [0:1:parts-2],
                thread = [0:1:threads-1],
                astep  = [0:1:asteps-1],
                trinum = [0, 1]
            ) let (
                p0 = _thread_pt(thread, threads, start, starts, astep, asteps, part, parts),
                p1 = _thread_pt(thread, threads, start, starts, astep, asteps, part+1, parts),
                p2 = _thread_pt(thread, threads, start, starts, astep+1, asteps, part, parts),
                p3 = _thread_pt(thread, threads, start, starts, astep+1, asteps, part+1, parts),
                tri = trinum==0? [p0, p1, p3] : [p0, p3, p2],
                otri = left_handed? [tri[0], tri[2], tri[1]] : tri
            )
            if (!(thread == threads-1 && astep == asteps-1)) otri
        ],
        // Thread trough bottom
        [
            for (
                start  = [0:1:starts-1],
                thread = [0:1:threads-1],
                astep  = [0:1:asteps-1],
                trinum = [0, 1]
            ) let (
                p0 = _thread_pt(thread, threads, start, starts, astep, asteps, parts-1, parts),
                p1 = _thread_pt(thread, threads, (start+(left_handed?1:starts-1))%starts, starts, astep+asteps/starts, asteps, 0, parts),
                p2 = p0 + 1,
                p3 = p1 + 1,
                tri = trinum==0? [p0, p1, p3] : [p0, p3, p2],
                otri = left_handed? [tri[0], tri[2], tri[1]] : tri
            )
            if (
                !(thread >= threads-1 && astep > asteps-asteps/starts-2) &&
                !(thread >= threads-2 && starts == 1 && astep >= asteps-1)
            ) otri
        ],
        // top and bottom thread endcap
        [
            for (
                start  = [0:1:starts-1],
                part   = [1:1:parts-2],
                is_top = [0, 1]
            ) let (
                astep = is_top? asteps-1 : 0,
                thread = is_top? threads-1 : 0,
                p0 = _thread_pt(thread, threads, start, starts, astep, asteps, 0, parts),
                p1 = _thread_pt(thread, threads, start, starts, astep, asteps, part, parts),
                p2 = _thread_pt(thread, threads, start, starts, astep, asteps, part+1, parts),
                tri = is_top? [p0, p1, p2] : [p0, p2, p1],
                otri = left_handed? [tri[0], tri[2], tri[1]] : tri
            ) otri
        ],
        // body side triangles
        [
            for (
                start  = [0:1:starts-1],
                is_top = [false, true],
                trinum = [0, 1]
            ) let (
                astep = is_top? asteps-1 : 0,
                thread = is_top? threads-1 : 0,
                ostart = (is_top != left_handed? (start+1) : (start+starts-1))%starts,
                ostep = is_top? astep-asteps/starts : astep+asteps/starts,
                oparts = is_top? parts-1 : 0,
                p0 = is_top? point_count-1 : point_count-2,
                p1 = _thread_pt(thread, threads, start, starts, astep, asteps, 0, parts),
                p2 = _thread_pt(thread, threads, start, starts, astep, asteps, parts-1, parts),
                p3 = _thread_pt(thread, threads, ostart, starts, ostep, asteps, oparts, parts),
                tri = trinum==0?
                    (is_top? [p0, p1, p2] : [p0, p2, p1]) :
                    (is_top? [p0, p3, p1] : [p0, p3, p2]),
                otri = left_handed? [tri[0], tri[2], tri[1]] : tri
            ) otri
        ],
        // Caps
        [
            for (
                start  = [0:1:starts-1],
                astep  = [0:1:asteps/starts-1],
                is_top = [0, 1]
            ) let (
                thread = is_top? threads-1 : 0,
                part = is_top? parts-1 : 0,
                ostep = is_top? asteps-astep-2 : astep,
                p0 = is_top? point_count-1 : point_count-2,
                p1 = _thread_pt(thread, threads, start, starts, ostep, asteps, part, parts),
                p2 = _thread_pt(thread, threads, start, starts, ostep+1, asteps, part, parts),
                tri = is_top? [p0, p2, p1] : [p0, p1, p2],
                otri = left_handed? [tri[0], tri[2], tri[1]] : tri
            ) otri
        ]
    );
    anchor = get_anchor(anchor, center, BOT, CENTER);
    attachable(anchor,spin,orient, d=d, l=l) {
        difference() {
            polyhedron(points=poly_points, faces=poly_faces, convexity=threads*starts*2);
            zcopies(l+4*pitch*starts) cube([d+1, d+1, 4*pitch*starts], center=true);
            if (bevel) cylinder_mask(d=d, l=l+0.01, chamfer=depth);
        }
        children();
    }
}


// Module: trapezoidal_threaded_nut()
// Description:
//   Constructs a hex nut for a threaded screw rod.  This method makes
//   much smoother threads than the naive linear_extrude method.
//   For metric screw threads, use thread_angle=30 and leave out thread_depth argument.
//   For SAE screw threads, use thread_angle=30 and leave out thread_depth argument.
//   For metric trapezoidal threads, use thread_angle=15 and thread_depth=pitch/2.
//   For ACME threads, use thread_angle=14.5 and thread_depth=pitch/2.
//   For square threads, use thread_angle=0 and thread_depth=pitch/2.
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   thread_depth = Depth of the threads.  Default=pitch/2.
//   thread_angle = The pressure angle profile angle of the threads.  Default = 14.5 degree ACME profile.
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   bevel = if true, bevel the thread ends.  Default: true
//   profile = The shape of a thread, if not a symmetric trapezoidal form.  Given as a 2D path, where X is between -1/2 and 1/2, representing the pitch distance, and Y is 0 for the peak, and `-depth/pitch` for the valleys.  The segment between the end of one thread profile and the start of the next is automatic, so the start and end coordinates should not both be at the same Y at X = ±1/2.  This path is scaled up by the pitch size in both dimensions when making the final threading.  This overrides the `thread_angle` and `thread_depth` options.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Examples(Med):
//   trapezoidal_threaded_nut(od=16, id=8, h=8, pitch=2, $slop=0.2, anchor=UP);
//   trapezoidal_threaded_nut(od=17.4, id=10, h=10, pitch=2, $slop=0.2, left_handed=true);
//   trapezoidal_threaded_nut(od=17.4, id=10, h=10, pitch=2, thread_angle=15, starts=3, $fa=1, $fs=1);
module trapezoidal_threaded_nut(
    od=17.4,
    id=10,
    h=10,
    pitch=2,
    thread_depth=undef,
    thread_angle=15,
    profile=undef,
    left_handed=false,
    starts=1,
    bevel=true,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    depth = min((thread_depth==undef? pitch/2 : thread_depth), pitch/2/tan(thread_angle));
    attachable(anchor,spin,orient, size=[od/cos(30),od,h]) {
        difference() {
            cylinder(d=od/cos(30), h=h, center=true, $fn=6);
            trapezoidal_threaded_rod(
                d=id,
                l=h+1,
                pitch=pitch,
                thread_depth=depth,
                thread_angle=thread_angle,
                profile=profile,
                left_handed=left_handed,
                starts=starts,
                internal=true
            );
            if (bevel) {
                zflip_copy() {
                    down(h/2+0.01) {
                        cylinder(r1=id/2+$slop, r2=id/2+$slop-depth, h=depth, center=false);
                    }
                }
            }
        }
        children();
    }
}


// Section: Triangular Threading

// Module: threaded_rod()
// Description:
//   Constructs a standard metric or UTS threaded screw rod.  This method
//   makes much smoother threads than the naive linear_extrude method.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   internal = If true, make this a mask for making internal threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Example(2D):
//   projection(cut=true)
//       threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med):
//   threaded_rod(d=10, l=20, pitch=1.25, left_handed=true, $fa=1, $fs=1);
//   threaded_rod(d=25, l=20, pitch=2, $fa=1, $fs=1);
module threaded_rod(
    d=10, l=100, pitch=2,
    left_handed=false,
    bevel=false,
    internal=false,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    depth = pitch * cos(30) * 5/8;
    profile = internal? [
        [-6/16, -depth/pitch],
        [-1/16,  0],
        [-1/32,  0.02],
        [ 1/32,  0.02],
        [ 1/16,  0],
        [ 6/16, -depth/pitch]
    ] : [
        [-7/16, -depth/pitch*1.07],
        [-6/16, -depth/pitch],
        [-1/16,  0],
        [ 1/16,  0],
        [ 6/16, -depth/pitch],
        [ 7/16, -depth/pitch*1.07]
    ];
    trapezoidal_threaded_rod(
        d=d, l=l, pitch=pitch,
        thread_depth=depth,
        thread_angle=30,
        profile=profile,
        left_handed=left_handed,
        bevel=bevel,
        internal=internal,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: threaded_nut()
// Description:
//   Constructs a hex nut for a metric or UTS threaded screw rod.  This method
//   makes much smoother threads than the naive linear_extrude method.
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Examples(Med):
//   threaded_nut(od=16, id=8, h=8, pitch=1.25, left_handed=true, $slop=0.2, $fa=1, $fs=1);
module threaded_nut(
    od=16, id=10, h=10,
    pitch=2, left_handed=false, bevel=false,
    anchor=CENTER, spin=0, orient=UP
) {
    depth = pitch * cos(30) * 5/8;
    profile = [
        [-6/16, -depth/pitch],
        [-1/16,  0],
        [-1/32,  0.02],
        [ 1/32,  0.02],
        [ 1/16,  0],
        [ 6/16, -depth/pitch]
    ];
    trapezoidal_threaded_nut(
        od=od, id=id, h=h,
        pitch=pitch, thread_angle=30,
        profile=profile,
        left_handed=left_handed,
        bevel=bevel,
        anchor=anchor, spin=spin,
        orient=orient
    ) children();
}


// Section: Buttress Threading

// Module: buttress_threaded_rod()
// Description:
//   Constructs a simple buttress threaded screw rod.  This method
//   makes much smoother threads than the naive linear_extrude method.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   internal = If true, this is a mask for making internal threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Example(2D):
//   projection(cut=true)
//       buttress_threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med):
//   buttress_threaded_rod(d=10, l=20, pitch=1.25, left_handed=true, $fa=1, $fs=1);
//   buttress_threaded_rod(d=25, l=20, pitch=2, $fa=1, $fs=1);
module buttress_threaded_rod(
    d=10, l=100, pitch=2,
    left_handed=false,
    bevel=false,
    internal=false,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    depth = pitch * 3/4;
    profile = [
        [ -7/16, -0.75],
        [  5/16,  0],
        [  7/16,  0],
        [  7/16, -0.75],
        [  1/ 2, -0.77],
    ];
    trapezoidal_threaded_rod(
        d=d, l=l, pitch=pitch,
        thread_depth=depth,
        thread_angle=30,
        profile=profile,
        left_handed=left_handed,
        bevel=bevel,
        internal=internal,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: buttress_threaded_nut()
// Description:
//   Constructs a hex nut for a simple buttress threaded screw rod.  This method
//   makes much smoother threads than the naive linear_extrude method.
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Examples(Med):
//   buttress_threaded_nut(od=16, id=8, h=8, pitch=1.25, left_handed=true, $slop=0.2, $fa=1, $fs=1);
module buttress_threaded_nut(
    od=16, id=10, h=10,
    pitch=2, left_handed=false,
    bevel=false,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    depth = pitch * 3/4;
    profile = [
        [ -7/16, -0.75],
        [  5/16,  0],
        [  7/16,  0],
        [  7/16, -0.75],
        [  1/ 2, -0.77],
    ];
    trapezoidal_threaded_nut(
        od=od, id=id, h=h,
        pitch=pitch, thread_angle=30,
        profile=profile,
        thread_depth=pitch*3*sqrt(3)/8,
        left_handed=left_handed,
        bevel=bevel,
        anchor=anchor, spin=spin,
        orient=orient
    ) children();
}


// Section: Metric Trapezoidal Threading

// Module: metric_trapezoidal_threaded_rod()
// Description:
//   Constructs a metric trapezoidal threaded screw rod.  This method makes much
//   smoother threads than the naive linear_extrude method.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   starts = The number of lead starts.  Default = 1
//   internal = If true, this is a mask for making internal threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Example(2D):
//   projection(cut=true)
//       metric_trapezoidal_threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med):
//   metric_trapezoidal_threaded_rod(d=10, l=30, pitch=2, left_handed=true, $fa=1, $fs=1);
module metric_trapezoidal_threaded_rod(
    d=10, l=100, pitch=2,
    left_handed=false,
    starts=1,
    bevel=false,
    internal=false,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    trapezoidal_threaded_rod(
        d=d, l=l,
        pitch=pitch,
        thread_angle=15,
        left_handed=left_handed,
        starts=starts,
        bevel=bevel,
        internal=internal,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: metric_trapezoidal_threaded_nut()
// Description:
//   Constructs a hex nut for a metric trapezoidal threaded screw rod.  This method
//   makes much smoother threads than the naive linear_extrude method.
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   starts = The number of lead starts.  Default = 1
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Examples(Med):
//   metric_trapezoidal_threaded_nut(od=16, id=10, h=10, pitch=2, left_handed=true, bevel=true, $fa=1, $fs=1);
module metric_trapezoidal_threaded_nut(
    od=17.4, id=10.5, h=10,
    pitch=3.175,
    starts=1,
    left_handed=false,
    bevel=false,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    trapezoidal_threaded_nut(
        od=od, id=id, h=h,
        pitch=pitch, thread_angle=15,
        left_handed=left_handed,
        starts=starts,
        bevel=bevel,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}


// Section: ACME Trapezoidal Threading

// Module: acme_threaded_rod()
// Description:
//   Constructs an ACME trapezoidal threaded screw rod.  This method makes
//   much smoother threads than the naive linear_extrude method.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.
//   thread_depth = Depth of the threads.  Default = pitch/2
//   thread_angle = The pressure angle profile angle of the threads.  Default = 14.5 degrees
//   starts = The number of lead starts.  Default = 1
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   internal = If true, this is a mask for making internal threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Example(2D):
//   projection(cut=true)
//       acme_threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med):
//   acme_threaded_rod(d=3/8*25.4, l=20, pitch=1/8*25.4, $fn=32);
//   acme_threaded_rod(d=10, l=30, pitch=2, starts=3, $fa=1, $fs=1);
module acme_threaded_rod(
    d=10, l=100, pitch=2,
    thread_angle=14.5,
    thread_depth=undef,
    starts=1,
    left_handed=false,
    bevel=false,
    internal=false,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    trapezoidal_threaded_rod(
        d=d, l=l, pitch=pitch,
        thread_angle=thread_angle,
        thread_depth=thread_depth,
        starts=starts,
        left_handed=left_handed,
        bevel=bevel,
        internal=internal,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: acme_threaded_nut()
// Description:
//   Constructs a hex nut for an ACME threaded screw rod.  This method makes
//   much smoother threads than the naive linear_extrude method.
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   thread_depth = Depth of the threads.  Default=pitch/2
//   thread_angle = The pressure angle profile angle of the threads.  Default = 14.5 degree ACME profile.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Examples(Med):
//   acme_threaded_nut(od=16, id=3/8*25.4, h=8, pitch=1/8*25.4, $slop=0.2);
//   acme_threaded_nut(od=16, id=10, h=10, pitch=2, starts=3, $slop=0.2, $fa=1, $fs=1);
module acme_threaded_nut(
    od, id, h, pitch,
    thread_angle=14.5,
    thread_depth=undef,
    starts=1,
    left_handed=false,
    bevel=false,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    trapezoidal_threaded_nut(
        od=od, id=id, h=h, pitch=pitch,
        thread_depth=thread_depth,
        thread_angle=thread_angle,
        left_handed=left_handed,
        bevel=bevel,
        starts=starts,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}


// Section: Square Threading

// Module: square_threaded_rod()
// Description:
//   Constructs a square profile threaded screw rod.  This method makes
//   much smoother threads than the naive linear_extrude method.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   starts = The number of lead starts.  Default = 1
//   internal = If true, this is a mask for making internal threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Example(2D):
//   projection(cut=true)
//       square_threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med):
//   square_threaded_rod(d=10, l=20, pitch=2, starts=2, $fn=32);
module square_threaded_rod(
    d=10, l=100, pitch=2,
    left_handed=false,
    bevel=false,
    starts=1,
    internal=false,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    trapezoidal_threaded_rod(
        d=d, l=l, pitch=pitch,
        thread_angle=0,
        left_handed=left_handed,
        bevel=bevel,
        starts=starts,
        internal=internal,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: square_threaded_nut()
// Description:
//   Constructs a hex nut for a square profile threaded screw rod.  This method
//   makes much smoother threads than the naive linear_extrude method.
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   starts = The number of lead starts.  Default = 1
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Examples(Med):
//   square_threaded_nut(od=16, id=10, h=10, pitch=2, starts=2, $slop=0.15, $fn=32);
module square_threaded_nut(
    od=17.4, id=10.5, h=10,
    pitch=3.175,
    left_handed=false,
    bevel=false,
    starts=1,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    trapezoidal_threaded_nut(
        od=od, id=id, h=h, pitch=pitch,
        thread_angle=0,
        left_handed=left_handed,
        bevel=bevel,
        starts=starts,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}


// Section: Ball Screws

// Module: ball_screw_rod()
// Description:
//   Constructs a ball screw rod.  This method makes much smoother threads than the naive linear_extrude method.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.  Also, the diameter of the ball bearings used.
//   ball_diam = The diameter of the ball bearings to use with this ball screw.
//   ball_arc = The arc portion that should touch the ball bearings. Default: 120 degrees.
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   bevel = if true, bevel the thread ends.  Default: false
//   internal = If true, make this a mask for making internal threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Example(2D): Thread Profile, ball_diam=4, ball_arc=100
//   projection(cut=true) ball_screw_rod(d=10, l=15, pitch=5, ball_diam=4, ball_arc=100, orient=BACK);
// Example(2D): Thread Profile, ball_diam=4, ball_arc=120
//   projection(cut=true) ball_screw_rod(d=10, l=15, pitch=5, ball_diam=4, ball_arc=120, orient=BACK);
// Example(2D): Thread Profile, ball_diam=3, ball_arc=120
//   projection(cut=true) ball_screw_rod(d=10, l=15, pitch=5, ball_diam=3, ball_arc=120, orient=BACK);
// Examples(Med):
//   ball_screw_rod(d=15, l=20, pitch=8, ball_diam=5, ball_arc=120, $fa=1, $fs=1);
//   ball_screw_rod(d=15, l=20, pitch=5, ball_diam=4, ball_arc=120, $fa=1, $fs=1);
//   ball_screw_rod(d=15, l=20, pitch=5, ball_diam=4, ball_arc=120, left_handed=true, $fa=1, $fs=1);
module ball_screw_rod(
    d=10, l=100, pitch=2, starts=1,
    ball_diam=5, ball_arc=100,
    left_handed=false,
    internal=false,
    bevel=false,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    depth = ball_diam * (1-cos(ball_arc/2))/2;
    profile = arc(N=11, d=ball_diam/pitch, cp=[0,ball_diam/2/pitch*cos(ball_arc/2)], start=270-ball_arc/2, angle=ball_arc);
    trapezoidal_threaded_rod(
        d=d, l=l, pitch=pitch,
        thread_depth=depth,
        thread_angle=90-ball_arc/2,
        profile=profile,
        left_handed=left_handed,
        starts=starts,
        bevel=bevel,
        internal=internal,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
