//////////////////////////////////////////////////////////////////////
// LibFile: geometry.scad
//   Geometry helpers.
//   To use, add the following lines to the beginning of your file:
//   ```
//   use <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Lines, Rays, and Segments

// Function: point_on_segment2d()
// Usage:
//   point_on_segment2d(point, edge);
// Description:
//   Determine if the point is on the line segment between two points.
//   Returns true if yes, and false if not.
// Arguments:
//   point = The point to test.
//   edge = Array of two points forming the line segment to test against.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function point_on_segment2d(point, edge, eps=EPSILON) =
    assert( is_vector(point,2), "Invalid point." )
    assert( is_finite(eps) && eps>=0, "The tolerance should be a positive number." )
    assert( _valid_line(edge,2,eps=eps), "Invalid segment." )
    let( dp = point-edge[0],
         de = edge[1]-edge[0],
         ne = norm(de) ) 
    ( dp*de >= -eps*ne ) 
    && ( (dp-de)*de <= eps*ne )                  // point projects on the segment
    && _dist2line(point-edge[0],unit(de))<eps;   // point is on the line 
    
    
//Internal - distance from point `d` to the line passing through the origin with unit direction n
//_dist2line works for any dimension
function _dist2line(d,n) = norm(d-(d * n) * n);

// Internal non-exposed function.
function _point_above_below_segment(point, edge) =
    let( edge = edge - [point, point] )
    edge[0].y <= 0 
    ?   (edge[1].y >  0 && cross(edge[0], edge[1]-edge[0]) > 0) ?  1 : 0
    :   (edge[1].y <= 0 && cross(edge[0], edge[1]-edge[0]) < 0) ? -1 : 0 ;

//Internal
function _valid_line(line,dim,eps=EPSILON) = 
    is_matrix(line,2,dim) 
    && ! approx(norm(line[1]-line[0]), 0, eps); 
    
//Internal
function _valid_plane(p, eps=EPSILON) = is_vector(p,4) && ! approx(norm(p),0,eps);


// Function: point_left_of_line2d()
// Usage:
//   point_left_of_line2d(point, line);
// Description:
//   Return >0 if point is left of the line defined by `line`.
//   Return =0 if point is on the line.
//   Return <0 if point is right of the line.
// Arguments:
//   point = The point to check position of.
//   line  = Array of two points forming the line segment to test against.
function point_left_of_line2d(point, line) =
    assert( is_vector(point,2) && is_vector(line*point, 2), "Improper input." )
    cross(line[0]-point, line[1]-line[0]);


// Function: collinear()
// Usage:
//   collinear(a, [b, c], [eps]);
// Description:
//   Returns true if the points `a`, `b` and `c` are co-linear or if the list of points `a` is collinear.
// Arguments:
//   a = First point or list of points.
//   b = Second point or undef; it should be undef if `c` is undef
//   c = Third point or undef.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function collinear(a, b, c, eps=EPSILON) =
    assert( is_path([a,b,c],dim=undef)
            || ( is_undef(b) && is_undef(c) && is_path(a,dim=undef) ), 
            "Input should be 3 points or a list of points with same dimension.")
    assert( is_finite(eps) && eps>=0, "The tolerance should be a positive number." )
    let( points = is_def(c) ? [a,b,c]: a )
    len(points)<3 ? true
    : noncollinear_triple(points,error=false,eps=eps)==[];
 

// Function: distance_from_line()
// Usage:
//   distance_from_line(line, pt);
// Description:
//   Finds the perpendicular distance of a point `pt` from the line `line`.
// Arguments:
//   line = A list of two points, defining a line that both are on.
//   pt = A point to find the distance of from the line.
// Example:
//   distance_from_line([[-10,0], [10,0]], [3,8]);  // Returns: 8
function distance_from_line(line, pt) =
    assert( _valid_line(line) && is_vector(pt,len(line[0])), 
            "Invalid line, invalid point or incompatible dimensions." )
    _dist2line(pt-line[0],unit(line[1]-line[0]));
    
    
// Function: line_normal()
// Usage:
//   line_normal([P1,P2])
//   line_normal(p1,p2)
// Description:
//   Returns the 2D normal vector to the given 2D line. This is otherwise known as the perpendicular vector counter-clockwise to the given ray.
// Arguments:
//   p1 = First point on 2D line.
//   p2 = Second point on 2D line.
// Example(2D):
//   p1 = [10,10];
//   p2 = [50,30];
//   n = line_normal(p1,p2);
//   stroke([p1,p2], endcap2="arrow2");
//   color("green") stroke([p1,p1+10*n], endcap2="arrow2");
//   color("blue") move_copies([p1,p2]) circle(d=2, $fn=12);
function line_normal(p1,p2) =
    is_undef(p2)
    ?   assert( len(p1)==2 && !is_undef(p1[1]) , "Invalid input." ) 
        line_normal(p1[0],p1[1]) 
    :   assert( _valid_line([p1,p2],dim=2), "Invalid line." ) 
        unit([p1.y-p2.y,p2.x-p1.x]);


// 2D Line intersection from two segments.
// This function returns [p,t,u] where p is the intersection point of
// the lines defined by the two segments, t is the proportional distance
// of the intersection point along s1, and u is the proportional distance
// of the intersection point along s2.  The proportional values run over
// the range of 0 to 1 for each segment, so if it is in this range, then
// the intersection lies on the segment.  Otherwise it lies somewhere on
// the extension of the segment.  Result is undef for coincident lines.
function _general_line_intersection(s1,s2,eps=EPSILON) =
    let(
        denominator = det2([s1[0],s2[0]]-[s1[1],s2[1]])
    ) approx(denominator,0,eps=eps)? [undef,undef,undef] : let(
        t = det2([s1[0],s2[0]]-s2) / denominator,
        u = det2([s1[0],s1[0]]-[s2[0],s1[1]]) / denominator
    ) [s1[0]+t*(s1[1]-s1[0]), t, u];


// Function: line_intersection()
// Usage:
//   line_intersection(l1, l2);
// Description:
//   Returns the 2D intersection point of two unbounded 2D lines.
//   Returns `undef` if the lines are parallel.
// Arguments:
//   l1 = First 2D line, given as a list of two 2D points on the line.
//   l2 = Second 2D line, given as a list of two 2D points on the line.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function line_intersection(l1,l2,eps=EPSILON) =
    assert( is_finite(eps) && eps>=0, "The tolerance should be a positive number." )
    assert( _valid_line(l1,dim=2,eps=eps) &&_valid_line(l2,dim=2,eps=eps), "Invalid line(s)." )
    let(isect = _general_line_intersection(l1,l2,eps=eps)) 
    isect[0];


// Function: line_ray_intersection()
// Usage:
//   line_ray_intersection(line, ray);
// Description:
//   Returns the 2D intersection point of an unbounded 2D line, and a half-bounded 2D ray.
//   Returns `undef` if they do not intersect.
// Arguments:
//   line = The unbounded 2D line, defined by two 2D points on the line.
//   ray = The 2D ray, given as a list `[START,POINT]` of the 2D start-point START, and a 2D point POINT on the ray.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function line_ray_intersection(line,ray,eps=EPSILON) =
    assert( is_finite(eps) && eps>=0, "The tolerance should be a positive number." )
    assert( _valid_line(line,dim=2,eps=eps) && _valid_line(ray,dim=2,eps=eps), "Invalid line or ray." )
    let(
        isect = _general_line_intersection(line,ray,eps=eps)
    ) 
    is_undef(isect[0]) ? undef :
    (isect[2]<0-eps) ? undef : isect[0];


// Function: line_segment_intersection()
// Usage:
//   line_segment_intersection(line, segment);
// Description:
//   Returns the 2D intersection point of an unbounded 2D line, and a bounded 2D line segment.
//   Returns `undef` if they do not intersect.
// Arguments:
//   line = The unbounded 2D line, defined by two 2D points on the line.
//   segment = The bounded 2D line segment, given as a list of the two 2D endpoints of the segment.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function line_segment_intersection(line,segment,eps=EPSILON) =
    assert( is_finite(eps) && eps>=0, "The tolerance should be a positive number." )
    assert( _valid_line(line,  dim=2,eps=eps) &&_valid_line(segment,dim=2,eps=eps), "Invalid line or segment." )
    let(
        isect = _general_line_intersection(line,segment,eps=eps)
    )
    is_undef(isect[0]) ? undef :
    isect[2]<0-eps || isect[2]>1+eps ? undef :
    isect[0];


// Function: ray_intersection()
// Usage:
//   ray_intersection(s1, s2);
// Description:
//   Returns the 2D intersection point of two 2D line rays.
//   Returns `undef` if they do not intersect.
// Arguments:
//   r1 = First 2D ray, given as a list `[START,POINT]` of the 2D start-point START, and a 2D point POINT on the ray.
//   r2 = Second 2D ray, given as a list `[START,POINT]` of the 2D start-point START, and a 2D point POINT on the ray.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function ray_intersection(r1,r2,eps=EPSILON) =
    assert( is_finite(eps) && eps>=0, "The tolerance should be a positive number." )
    assert( _valid_line(r1,dim=2,eps=eps) && _valid_line(r2,dim=2,eps=eps), "Invalid ray(s)." )
    let(
        isect = _general_line_intersection(r1,r2,eps=eps)
    ) 
    is_undef(isect[0]) ? undef :
    isect[1]<0-eps || isect[2]<0-eps ? undef : isect[0];


// Function: ray_segment_intersection()
// Usage:
//   ray_segment_intersection(ray, segment);
// Description:
//   Returns the 2D intersection point of a half-bounded 2D ray, and a bounded 2D line segment.
//   Returns `undef` if they do not intersect.
// Arguments:
//   ray = The 2D ray, given as a list `[START,POINT]` of the 2D start-point START, and a 2D point POINT on the ray.
//   segment = The bounded 2D line segment, given as a list of the two 2D endpoints of the segment.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function ray_segment_intersection(ray,segment,eps=EPSILON) =
    assert( _valid_line(ray,dim=2,eps=eps) && _valid_line(segment,dim=2,eps=eps), "Invalid ray or segment." )
    assert( is_finite(eps) && eps>=0, "The tolerance should be a positive number." )
    let(
        isect = _general_line_intersection(ray,segment,eps=eps)
    ) 
    is_undef(isect[0]) ? undef :
    isect[1]<0-eps || isect[2]<0-eps || isect[2]>1+eps ? undef :
    isect[0];


// Function: segment_intersection()
// Usage:
//   segment_intersection(s1, s2);
// Description:
//   Returns the 2D intersection point of two 2D line segments.
//   Returns `undef` if they do not intersect.
// Arguments:
//   s1 = First 2D segment, given as a list of the two 2D endpoints of the line segment.
//   s2 = Second 2D segment, given as a list of the two 2D endpoints of the line segment.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function segment_intersection(s1,s2,eps=EPSILON) =
    assert( _valid_line(s1,dim=2,eps=eps) && _valid_line(s2,dim=2,eps=eps), "Invalid segment(s)." )
    assert( is_finite(eps) && eps>=0, "The tolerance should be a positive number." )
    let(
        isect = _general_line_intersection(s1,s2,eps=eps)
    ) 
    is_undef(isect[0]) ? undef :
    isect[1]<0-eps || isect[1]>1+eps || isect[2]<0-eps || isect[2]>1+eps ? undef :
    isect[0];


// Function: line_closest_point()
// Usage:
//   line_closest_point(line,pt);
// Description:
//   Returns the point on the given 2D or 3D `line` that is closest to the given point `pt`.
//   The `line` and `pt` args should either both be 2D or both 3D.
// Arguments:
//   line = A list of two points that are on the unbounded line.
//   pt = The point to find the closest point on the line to.
// Example(2D):
//   line = [[-30,0],[30,30]];
//   pt = [-32,-10];
//   p2 = line_closest_point(line,pt);
//   stroke(line, endcaps="arrow2");
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(2D):
//   line = [[-30,0],[30,30]];
//   pt = [-5,0];
//   p2 = line_closest_point(line,pt);
//   stroke(line, endcaps="arrow2");
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(2D):
//   line = [[-30,0],[30,30]];
//   pt = [40,25];
//   p2 = line_closest_point(line,pt);
//   stroke(line, endcaps="arrow2");
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(FlatSpin):
//   line = [[-30,-15,0],[30,15,30]];
//   pt = [5,5,5];
//   p2 = line_closest_point(line,pt);
//   stroke(line, endcaps="arrow2");
//   color("blue") translate(pt) sphere(r=1,$fn=12);
//   color("red") translate(p2) sphere(r=1,$fn=12);
// Example(FlatSpin):
//   line = [[-30,-15,0],[30,15,30]];
//   pt = [-35,-15,0];
//   p2 = line_closest_point(line,pt);
//   stroke(line, endcaps="arrow2");
//   color("blue") translate(pt) sphere(r=1,$fn=12);
//   color("red") translate(p2) sphere(r=1,$fn=12);
// Example(FlatSpin):
//   line = [[-30,-15,0],[30,15,30]];
//   pt = [40,15,25];
//   p2 = line_closest_point(line,pt);
//   stroke(line, endcaps="arrow2");
//   color("blue") translate(pt) sphere(r=1,$fn=12);
//   color("red") translate(p2) sphere(r=1,$fn=12);
function line_closest_point(line,pt) =
    assert(_valid_line(line), "Invalid line." )
    assert( is_vector(pt,len(line[0])), "Invalid point or incompatible dimensions." )
    let( n = unit( line[0]- line[1]) )
    line[1]+((pt- line[1]) * n) * n;


// Function: ray_closest_point()
// Usage:
//   ray_closest_point(seg,pt);
// Description:
//   Returns the point on the given 2D or 3D ray `ray` that is closest to the given point `pt`.
//   The `ray` and `pt` args should either both be 2D or both 3D.
// Arguments:
//   ray = The ray, given as a list `[START,POINT]` of the start-point START, and a point POINT on the ray.
//   pt = The point to find the closest point on the ray to.
// Example(2D):
//   ray = [[-30,0],[30,30]];
//   pt = [-32,-10];
//   p2 = ray_closest_point(ray,pt);
//   stroke(ray, endcap2="arrow2");
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(2D):
//   ray = [[-30,0],[30,30]];
//   pt = [-5,0];
//   p2 = ray_closest_point(ray,pt);
//   stroke(ray, endcap2="arrow2");
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(2D):
//   ray = [[-30,0],[30,30]];
//   pt = [40,25];
//   p2 = ray_closest_point(ray,pt);
//   stroke(ray, endcap2="arrow2");
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(FlatSpin):
//   ray = [[-30,-15,0],[30,15,30]];
//   pt = [5,5,5];
//   p2 = ray_closest_point(ray,pt);
//   stroke(ray, endcap2="arrow2");
//   color("blue") translate(pt) sphere(r=1,$fn=12);
//   color("red") translate(p2) sphere(r=1,$fn=12);
// Example(FlatSpin):
//   ray = [[-30,-15,0],[30,15,30]];
//   pt = [-35,-15,0];
//   p2 = ray_closest_point(ray,pt);
//   stroke(ray, endcap2="arrow2");
//   color("blue") translate(pt) sphere(r=1,$fn=12);
//   color("red") translate(p2) sphere(r=1,$fn=12);
// Example(FlatSpin):
//   ray = [[-30,-15,0],[30,15,30]];
//   pt = [40,15,25];
//   p2 = ray_closest_point(ray,pt);
//   stroke(ray, endcap2="arrow2");
//   color("blue") translate(pt) sphere(r=1,$fn=12);
//   color("red") translate(p2) sphere(r=1,$fn=12);
function ray_closest_point(ray,pt) =
    assert( _valid_line(ray), "Invalid ray." )
    assert(is_vector(pt,len(ray[0])), "Invalid point or incompatible dimensions." )
    let(
        seglen = norm(ray[1]-ray[0]),
        segvec = (ray[1]-ray[0])/seglen,
        projection = (pt-ray[0]) * segvec
    )
    projection<=0 ? ray[0] :
    ray[0] + projection*segvec;


// Function: segment_closest_point()
// Usage:
//   segment_closest_point(seg,pt);
// Description:
//   Returns the point on the given 2D or 3D line segment `seg` that is closest to the given point `pt`.
//   The `seg` and `pt` args should either both be 2D or both 3D.
// Arguments:
//   seg = A list of two points that are the endpoints of the bounded line segment.
//   pt = The point to find the closest point on the segment to.
// Example(2D):
//   seg = [[-30,0],[30,30]];
//   pt = [-32,-10];
//   p2 = segment_closest_point(seg,pt);
//   stroke(seg);
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(2D):
//   seg = [[-30,0],[30,30]];
//   pt = [-5,0];
//   p2 = segment_closest_point(seg,pt);
//   stroke(seg);
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(2D):
//   seg = [[-30,0],[30,30]];
//   pt = [40,25];
//   p2 = segment_closest_point(seg,pt);
//   stroke(seg);
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(FlatSpin):
//   seg = [[-30,-15,0],[30,15,30]];
//   pt = [5,5,5];
//   p2 = segment_closest_point(seg,pt);
//   stroke(seg);
//   color("blue") translate(pt) sphere(r=1,$fn=12);
//   color("red") translate(p2) sphere(r=1,$fn=12);
// Example(FlatSpin):
//   seg = [[-30,-15,0],[30,15,30]];
//   pt = [-35,-15,0];
//   p2 = segment_closest_point(seg,pt);
//   stroke(seg);
//   color("blue") translate(pt) sphere(r=1,$fn=12);
//   color("red") translate(p2) sphere(r=1,$fn=12);
// Example(FlatSpin):
//   seg = [[-30,-15,0],[30,15,30]];
//   pt = [40,15,25];
//   p2 = segment_closest_point(seg,pt);
//   stroke(seg);
//   color("blue") translate(pt) sphere(r=1,$fn=12);
//   color("red") translate(p2) sphere(r=1,$fn=12);
function segment_closest_point(seg,pt) =
    assert(_valid_line(seg), "Invalid segment." )
    assert(len(pt)==len(seg[0]), "Incompatible dimensions." )
    approx(seg[0],seg[1])? seg[0] :
    let(
        seglen = norm(seg[1]-seg[0]),
        segvec = (seg[1]-seg[0])/seglen,
        projection = (pt-seg[0]) * segvec
    )
    projection<=0 ? seg[0] :
    projection>=seglen ? seg[1] :
    seg[0] + projection*segvec;

    
// Function: line_from_points()
// Usage:
//   line_from_points(points, [fast], [eps]);
// Description:
//   Given a list of 2 or more colinear points, returns a line containing them.
//   If `fast` is false and the points are coincident, then `undef` is returned.
//   if `fast` is true, then the collinearity test is skipped and a line passing through 2 distinct arbitrary points is returned.
// Arguments:
//   points = The list of points to find the line through.
//   fast = If true, don't verify that all points are collinear.  Default: false
//   eps = How much variance is allowed in testing each point against the line.  Default: `EPSILON` (1e-9)
function line_from_points(points, fast=false, eps=EPSILON) =
    assert( is_path(points,dim=undef), "Improper point list." )
    assert( is_finite(eps) && eps>=0, "The tolerance should be a positive number." )
    let( pb = furthest_point(points[0],points) )
    approx(norm(points[pb]-points[0]),0) ? undef :
    fast || collinear(points) ? [points[pb], points[0]] : undef;



// Section: 2D Triangles


// Function: law_of_cosines()
// Usage:
//   C = law_of_cosines(a, b, c);
//   c = law_of_cosines(a, b, C);
// Description:
//   Applies the Law of Cosines for an arbitrary triangle.
//   Given three side lengths, returns the angle in degrees for the corner opposite of the third side.
//   Given two side lengths, and the angle between them, returns the length of the third side.
// Figure(2D):
//   stroke([[-50,0], [10,60], [50,0]], closed=true);
//   color("black") {
//       translate([ 33,35]) text(text="a", size=8, halign="center", valign="center");
//       translate([  0,-6]) text(text="b", size=8, halign="center", valign="center");
//       translate([-22,35]) text(text="c", size=8, halign="center", valign="center");
//   }
//   color("blue") {
//       translate([-37, 6]) text(text="A", size=8, halign="center", valign="center");
//       translate([  9,51]) text(text="B", size=8, halign="center", valign="center");
//       translate([ 38, 6]) text(text="C", size=8, halign="center", valign="center");
//   }
// Arguments:
//   a = The length of the first side.
//   b = The length of the second side.
//   c = The length of the third side.
//   C = The angle in degrees of the corner opposite of the third side.
function law_of_cosines(a, b, c, C) =
    // Triangle Law of Cosines:
    //   c^2 = a^2 + b^2 - 2*a*b*cos(C)
    assert(num_defined([c,C]) == 1, "Must give exactly one of c= or C=.")
    is_undef(c) ? sqrt(a*a + b*b - 2*a*b*cos(C)) :
    acos(constrain((a*a + b*b - c*c) / (2*a*b), -1, 1));


// Function: law_of_sines()
// Usage:
//   B = law_of_sines(a, A, b);
//   b = law_of_sines(a, A, B);
// Description:
//   Applies the Law of Sines for an arbitrary triangle.
//   Given two triangle side lengths and the angle between them, returns the angle of the corner opposite of the second side.
//   Given a side length, the opposing angle, and a second angle, returns the length of the side opposite of the second angle.
// Figure(2D):
//   stroke([[-50,0], [10,60], [50,0]], closed=true);
//   color("black") {
//       translate([ 33,35]) text(text="a", size=8, halign="center", valign="center");
//       translate([  0,-6]) text(text="b", size=8, halign="center", valign="center");
//       translate([-22,35]) text(text="c", size=8, halign="center", valign="center");
//   }
//   color("blue") {
//       translate([-37, 6]) text(text="A", size=8, halign="center", valign="center");
//       translate([  9,51]) text(text="B", size=8, halign="center", valign="center");
//       translate([ 38, 6]) text(text="C", size=8, halign="center", valign="center");
//   }
// Arguments:
//   a = The length of the first side.
//   A = The angle in degrees of the corner opposite of the first side.
//   b = The length of the second side.
//   B = The angle in degrees of the corner opposite of the second side.
function law_of_sines(a, A, b, B) =
    // Triangle Law of Sines:
    //   a/sin(A) = b/sin(B) = c/sin(C)
    assert(num_defined([b,B]) == 1, "Must give exactly one of b= or B=.")
    let( r = a/sin(A) )
    is_undef(b) ? r*sin(B) : asin(constrain(b/r, -1, 1));


// Function: tri_calc()
// Usage:
//   tri_calc(ang,ang2,adj,opp,hyp);
// Description:
//   Given a side length and an angle, or two side lengths, calculates the rest of the side lengths
//   and angles of a right triangle.  Returns [ADJACENT, OPPOSITE, HYPOTENUSE, ANGLE, ANGLE2] where
//   ADJACENT is the length of the side adjacent to ANGLE, and OPPOSITE is the length of the side
//   opposite of ANGLE and adjacent to ANGLE2.  ANGLE and ANGLE2 are measured in degrees.
//   This is certainly more verbose and slower than writing your own calculations, but has the nice
//   benefit that you can just specify the info you have, and don't have to figure out which trig
//   formulas you need to use.
// Figure(2D):
//   color("#ccc") {
//       stroke(closed=false, width=0.5, [[45,0], [45,5], [50,5]]);
//       stroke(closed=false, width=0.5, arc(N=6, r=15, cp=[0,0], start=0, angle=30));
//       stroke(closed=false, width=0.5, arc(N=6, r=14, cp=[50,30], start=212, angle=58));
//   }
//   color("black") stroke(closed=true, [[0,0], [50,30], [50,0]]);
//   color("#0c0") {
//       translate([10.5,2.5]) text(size=3,text="ang",halign="center",valign="center");
//       translate([44.5,22]) text(size=3,text="ang2",halign="center",valign="center");
//   }
//   color("blue") {
//       translate([25,-3]) text(size=3,text="Adjacent",halign="center",valign="center");
//       translate([53,15]) rotate(-90) text(size=3,text="Opposite",halign="center",valign="center");
//       translate([25,18]) rotate(30) text(size=3,text="Hypotenuse",halign="center",valign="center");
//   }
// Arguments:
//   ang = The angle in degrees of the primary corner of the triangle.
//   ang2 = The angle in degrees of the other non-right corner of the triangle.
//   adj = The length of the side adjacent to the primary corner.
//   opp = The length of the side opposite to the primary corner.
//   hyp = The length of the hypotenuse.
// Example:
//   tri = tri_calc(opp=15,hyp=30);
//   echo(adjacent=tri[0], opposite=tri[1], hypotenuse=tri[2], angle=tri[3], angle2=tri[4]);
// Examples:
//   adj = tri_calc(ang=30,opp=10)[0];
//   opp = tri_calc(ang=20,hyp=30)[1];
//   hyp = tri_calc(ang2=50,adj=20)[2];
//   ang = tri_calc(adj=20,hyp=30)[3];
//   ang2 = tri_calc(adj=20,hyp=40)[4];
function tri_calc(ang,ang2,adj,opp,hyp) =
    assert(ang==undef || ang2==undef,"At most one angle is allowed.")
    assert(num_defined([ang,ang2,adj,opp,hyp])==2, "Exactly two arguments must be given.")
    let(
        ang   = ang!=undef
                ? assert(ang>0&&ang<90, "The input angles should be acute angles." ) ang 
                : ang2!=undef ? (90-ang2) 
                : adj==undef ? asin(constrain(opp/hyp,-1,1)) 
                : opp==undef ? acos(constrain(adj/hyp,-1,1)) 
                : atan2(opp,adj),
        ang2 =  ang2!=undef
                ? assert(ang2>0&&ang2<90, "The input angles should be acute angles." ) ang2 
                : (90-ang),
        adj  =  adj!=undef
                ? assert(adj>0, "Triangle side lengths should be positive." ) adj 
                : (opp!=undef? (opp/tan(ang)) : (hyp*cos(ang))),
        opp  =  opp!=undef
                ? assert(opp>0, "Triangle side lengths should be positive." )  opp 
                : (adj!=undef? (adj*tan(ang)) : (hyp*sin(ang))),
        hyp  =  hyp!=undef
                ? assert(hyp>0, "Triangle side lengths should be positive." ) 
                  assert(adj<hyp && opp<hyp, "Hyphotenuse length should be greater than the other sides." )
                  hyp 
                : (adj!=undef? (adj/cos(ang)) 
                : (opp/sin(ang)))
    )
    [adj, opp, hyp, ang, ang2];


// Function: hyp_opp_to_adj()
// Usage:
//   adj = hyp_opp_to_adj(hyp,opp);
// Description:
//   Given the lengths of the hypotenuse and opposite side of a right triangle, returns the length
//   of the adjacent side.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
// Example:
//   hyp = hyp_opp_to_adj(5,3);  // Returns: 4
function hyp_opp_to_adj(hyp,opp) =
    assert(is_finite(hyp+opp) && hyp>=0 && opp>=0, 
           "Triangle side lengths should be a positive numbers." )
    sqrt(hyp*hyp-opp*opp);


// Function: hyp_ang_to_adj()
// Usage:
//   adj = hyp_ang_to_adj(hyp,ang);
// Description:
//   Given the length of the hypotenuse and the angle of the primary corner of a right triangle,
//   returns the length of the adjacent side.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   adj = hyp_ang_to_adj(8,60);  // Returns: 4
function hyp_ang_to_adj(hyp,ang) =
    assert(is_finite(hyp) && hyp>=0, "Triangle side length should be a positive number." )
    assert(is_finite(ang) && ang>-90 && ang<90, "The angle should be an acute angle." )
    hyp*cos(ang);


// Function: opp_ang_to_adj()
// Usage:
//   adj = opp_ang_to_adj(opp,ang);
// Description:
//   Given the angle of the primary corner of a right triangle, and the length of the side opposite of it,
//   returns the length of the adjacent side.
// Arguments:
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   adj = opp_ang_to_adj(8,30);  // Returns: 4
function opp_ang_to_adj(opp,ang) =
    assert(is_finite(opp) && opp>=0, "Triangle side length should be a positive number." )
    assert(is_finite(ang) && ang>-90 && ang<90, "The angle should be an acute angle." )
    opp/tan(ang);


// Function: hyp_adj_to_opp()
// Usage:
//   opp = hyp_adj_to_opp(hyp,adj);
// Description:
//   Given the length of the hypotenuse and the adjacent side, returns the length of the opposite side.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
// Example:
//   opp = hyp_adj_to_opp(5,4);  // Returns: 3
function hyp_adj_to_opp(hyp,adj) =
    assert(is_finite(hyp) && hyp>=0 && is_finite(adj) && adj>=0, 
           "Triangle side lengths should be a positive numbers." )
    sqrt(hyp*hyp-adj*adj);


// Function: hyp_ang_to_opp()
// Usage:
//   opp = hyp_ang_to_opp(hyp,adj);
// Description:
//   Given the length of the hypotenuse of a right triangle, and the angle of the corner, returns the length of the opposite side.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   opp = hyp_ang_to_opp(8,30);  // Returns: 4
function hyp_ang_to_opp(hyp,ang) =
    assert(is_finite(hyp)&&hyp>=0, "Triangle side length should be a positive number." )
    assert(is_finite(ang) && ang>-90 && ang<90, "The angle should be an acute angle." )
    hyp*sin(ang);


// Function: adj_ang_to_opp()
// Usage:
//   opp = adj_ang_to_opp(adj,ang);
// Description:
//   Given the length of the adjacent side of a right triangle, and the angle of the corner, returns the length of the opposite side.
// Arguments:
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   opp = adj_ang_to_opp(8,45);  // Returns: 8
function adj_ang_to_opp(adj,ang) =
    assert(is_finite(adj)&&adj>=0, "Triangle side length should be a positive number." )
    assert(is_finite(ang) && ang>-90 && ang<90, "The angle should be an acute angle." )
    adj*tan(ang);


// Function: adj_opp_to_hyp()
// Usage:
//   hyp = adj_opp_to_hyp(adj,opp);
// Description:
//   Given the length of the adjacent and opposite sides of a right triangle, returns the length of thee hypotenuse.
// Arguments:
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
// Example:
//   hyp = adj_opp_to_hyp(3,4);  // Returns: 5
function adj_opp_to_hyp(adj,opp) =
    assert(is_finite(opp) && opp>=0 && is_finite(adj) && adj>=0, 
           "Triangle side lengths should be a positive numbers." )
    norm([opp,adj]);


// Function: adj_ang_to_hyp()
// Usage:
//   hyp = adj_ang_to_hyp(adj,ang);
// Description:
//   For a right triangle, given the length of the adjacent side, and the corner angle, returns the length of the hypotenuse.
// Arguments:
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   hyp = adj_ang_to_hyp(4,60);  // Returns: 8
function adj_ang_to_hyp(adj,ang) =
    assert(is_finite(adj) && adj>=0, "Triangle side length should be a positive number." )
    assert(is_finite(ang) && ang>-90 && ang<90, "The angle should be an acute angle." )
    adj/cos(ang);


// Function: opp_ang_to_hyp()
// Usage:
//   hyp = opp_ang_to_hyp(opp,ang);
// Description:
//   For a right triangle, given the length of the opposite side, and the corner angle, returns the length of the hypotenuse.
// Arguments:
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   hyp = opp_ang_to_hyp(4,30);  // Returns: 8
function opp_ang_to_hyp(opp,ang) =
    assert(is_finite(opp) && opp>=0, "Triangle side length should be a positive number." )
    assert(is_finite(ang) && ang>-90 && ang<90, "The angle should be an acute angle." )
    opp/sin(ang);


// Function: hyp_adj_to_ang()
// Usage:
//   ang = hyp_adj_to_ang(hyp,adj);
// Description:
//   For a right triangle, given the lengths of the hypotenuse and the adjacent sides, returns the angle of the corner.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
// Example:
//   ang = hyp_adj_to_ang(8,4);  // Returns: 60 degrees
function hyp_adj_to_ang(hyp,adj) =
    assert(is_finite(hyp) && hyp>0 && is_finite(adj) && adj>=0, 
            "Triangle side lengths should be positive numbers." )
    acos(adj/hyp);


// Function: hyp_opp_to_ang()
// Usage:
//   ang = hyp_opp_to_ang(hyp,opp);
// Description:
//   For a right triangle, given the lengths of the hypotenuse and the opposite sides, returns the angle of the corner.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
// Example:
//   ang = hyp_opp_to_ang(8,4);  // Returns: 30 degrees
function hyp_opp_to_ang(hyp,opp) =
    assert(is_finite(hyp+opp) && hyp>0 && opp>=0, 
            "Triangle side lengths should be positive numbers." )
    asin(opp/hyp);


// Function: adj_opp_to_ang()
// Usage:
//   ang = adj_opp_to_ang(adj,opp);
// Description:
//   For a right triangle, given the lengths of the adjacent and opposite sides, returns the angle of the corner.
// Arguments:
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
// Example:
//   ang = adj_opp_to_ang(sqrt(3)/2,0.5);  // Returns: 30 degrees
function adj_opp_to_ang(adj,opp) =
    assert(is_finite(adj+opp) && adj>0 && opp>=0, 
            "Triangle side lengths should be positive numbers." )
    atan2(opp,adj);


// Function: triangle_area()
// Usage:
//   triangle_area(a,b,c);
// Description:
//   Returns the area of a triangle formed between three 2D or 3D vertices.
//   Result will be negative if the points are 2D and in clockwise order.
// Examples:
//   triangle_area([0,0], [5,10], [10,0]);  // Returns -50
//   triangle_area([10,0], [5,10], [0,0]);  // Returns 50
function triangle_area(a,b,c) = 
    assert( is_path([a,b,c]), "Invalid points or incompatible dimensions." )    
    len(a)==3 
      ? 0.5*norm(cross(c-a,c-b)) 
      : 0.5*cross(c-a,c-b);



// Section: Planes


// Function: plane3pt()
// Usage:
//   plane3pt(p1, p2, p3);
// Description:
//   Generates the normalized cartesian equation of a plane from three 3d points.
//   Returns [A,B,C,D] where Ax + By + Cz = D is the equation of a plane. 
//   Returns [], if the points are collinear.
// Arguments:
//   p1 = The first point on the plane.
//   p2 = The second point on the plane.
//   p3 = The third point on the plane.
function plane3pt(p1, p2, p3) =
    assert( is_path([p1,p2,p3],dim=3) && len(p1)==3,
            "Invalid points or incompatible dimensions." )    
    let(
        crx = cross(p3-p1, p2-p1),
        nrm = norm(crx)
    ) 
    approx(nrm,0) ? [] :
    concat(crx, crx*p1)/nrm;


// Function: plane3pt_indexed()
// Usage:
//   plane3pt_indexed(points, i1, i2, i3);
// Description:
//   Given a list of 3d points, and the indices of three of those points,
//   generates the normalized cartesian equation of a plane that those points all
//   lie on. If the points are not collinear, returns [A,B,C,D] where Ax+By+Cz=D is the equation of a plane.
//   If they are collinear, returns [].
// Arguments:
//   points = A list of points.
//   i1 = The index into `points` of the first point on the plane.
//   i2 = The index into `points` of the second point on the plane.
//   i3 = The index into `points` of the third point on the plane.
function plane3pt_indexed(points, i1, i2, i3) =
    assert( is_vector([i1,i2,i3]) && min(i1,i2,i3)>=0 && is_list(points) && max(i1,i2,i3)<len(points),
            "Invalid or out of range indices." )
    assert( is_path([points[i1], points[i2], points[i3]],dim=3),
            "Improper points or improper dimensions." )
    let(
        p1 = points[i1],
        p2 = points[i2],
        p3 = points[i3]
    ) 
    plane3pt(p1,p2,p3);


// Function: plane_from_normal()
// Usage:
//   plane_from_normal(normal, [pt])
// Description:
//   Returns a plane defined by a normal vector and a point.
// Example:
//   plane_from_normal([0,0,1], [2,2,2]);  // Returns the xy plane passing through the point (2,2,2)
function plane_from_normal(normal, pt=[0,0,0]) =
  assert( is_matrix([normal,pt],2,3) && !approx(norm(normal),0), 
          "Inputs `normal` and `pt` should 3d vectors/points and `normal` cannot be zero." )
  concat(normal, normal*pt) / norm(normal);


// Function: plane_from_points()
// Usage:
//   plane_from_points(points, <fast>, <eps>);
// Description:
//   Given a list of 3 or more coplanar 3D points, returns the coefficients of the normalized cartesian equation of a plane,
//   that is [A,B,C,D] where Ax+By+Cz=D is the equation of the plane where norm([A,B,C])=1.
//   If `fast` is false and the points in the list are collinear or not coplanar, then `undef` is returned.
//   if `fast` is true, then the coplanarity test is skipped and a plane passing through 3 non-collinear arbitrary points is returned.
// Arguments:
//   points = The list of points to find the plane of.
//   fast = If true, don't verify that all points in the list are coplanar.  Default: false
//   eps = How much variance is allowed in testing that each point is on the same plane.  Default: `EPSILON` (1e-9)
// Example(3D):
//   xyzpath = rot(45, v=[-0.3,1,0], p=path3d(star(n=6,id=70,d=100), 70));
//   plane = plane_from_points(xyzpath);
//   #stroke(xyzpath,closed=true);
//   cp = centroid(xyzpath);
//   move(cp) rot(from=UP,to=plane_normal(plane)) anchor_arrow();
function plane_from_points(points, fast=false, eps=EPSILON) =
    assert( is_path(points,dim=3), "Improper 3d point list." )
    assert( is_finite(eps) && eps>=0, "The tolerance should be a positive number." )
    let(
        points = deduplicate(points),
        indices = noncollinear_triple(points,error=false)
    )
    indices==[] ? undef :
    let(
        p1 = points[indices[0]],
        p2 = points[indices[1]],
        p3 = points[indices[2]],
        plane = plane3pt(p1,p2,p3)
    )
    fast || points_on_plane(points,plane,eps=eps) ? plane : undef;


// Function: plane_from_polygon()
// Usage:
//   plane_from_polygon(points, [fast], [eps]);
// Description:
//   Given a 3D planar polygon, returns the normalized cartesian equation of its plane.
//   Returns [A,B,C,D] where Ax+By+Cz=D is the equation of the plane where norm([A,B,C])=1.
//   If not all the points in the polygon are coplanar, then [] is returned.
//   If `fast` is true, the polygon coplanarity check is skipped and the plane may not contain all polygon points.
// Arguments:
//   poly = The planar 3D polygon to find the plane of.
//   fast = If true, doesn't verify that all points in the polygon are coplanar.  Default: false
//   eps = How much variance is allowed in testing that each point is on the same plane.  Default: `EPSILON` (1e-9)
// Example(3D):
//   xyzpath = rot(45, v=[0,1,0], p=path3d(star(n=5,step=2,d=100), 70));
//   plane = plane_from_polygon(xyzpath);
//   #stroke(xyzpath,closed=true);
//   cp = centroid(xyzpath);
//   move(cp) rot(from=UP,to=plane_normal(plane)) anchor_arrow();
function plane_from_polygon(poly, fast=false, eps=EPSILON) =
    assert( is_path(poly,dim=3), "Invalid polygon." )
    assert( is_finite(eps) && eps>=0, "The tolerance should be a positive number." )
    let(
        poly = deduplicate(poly),
        n = polygon_normal(poly),
        plane = [n.x, n.y, n.z, n*poly[0]]
    ) 
    fast? plane: coplanar(poly,eps=eps)? plane: [];


// Function: plane_normal()
// Usage:
//   plane_normal(plane);
// Description:
//   Returns the unit length normal vector for the given plane.
function plane_normal(plane) = 
    assert( _valid_plane(plane), "Invalid input plane." )
    unit([plane.x, plane.y, plane.z]);


// Function: plane_offset()
// Usage:
//   d = plane_offset(plane);
// Description:
//   Returns coeficient D of the normalized plane equation `Ax+By+Cz=D`, or the scalar offset of the plane from the origin. 
//   This value may be negative.
//   The absolute value of this coefficient is the distance of the plane from the origin.
function plane_offset(plane) =  
    assert( _valid_plane(plane), "Invalid input plane." )
    plane[3]/norm([plane.x, plane.y, plane.z]);


// Function: plane_transform()
// Usage:
//   mat = plane_transform(plane);
// Description:
//   Given a plane definition `[A,B,C,D]`, where `Ax+By+Cz=D`, returns a 3D affine
//   transformation matrix that will linear transform points on that plane
//   into points on the XY plane.  You can generally then use `path2d()` to drop the
//   Z coordinates, so you can work with the points in 2D.
// Arguments:
//   plane = The `[A,B,C,D]` plane definition where `Ax+By+Cz=D` is the formula of the plane.
// Example(3D):
//   xyzpath = move([10,20,30], p=yrot(25, p=path3d(circle(d=100))));
//   plane = plane_from_points(xyzpath);
//   mat = plane_transform(plane);
//   xypath = path2d(apply(mat, xyzpath));
//   #stroke(xyzpath,closed=true);
//   stroke(xypath,closed=true);
function plane_transform(plane) =
    let(
        plane = normalize_plane(plane),
        n = point3d(plane),
        cp = n * plane[3]
        ) 
    rot(from=n, to=UP) * move(-cp);


// Function: projection_on_plane()
// Usage:
//   projection_on_plane(points);
// Description:
//   Given a plane definition `[A,B,C,D]`, where `Ax+By+Cz=D`, and a list of 2d or 3d points, return the 3D orthogonal 
//   projection of the points on the plane.
// Arguments:
//   plane = The `[A,B,C,D]` plane definition where `Ax+By+Cz=D` is the formula of the plane.
//   points = List of points to project
// Example(3D):
//   points = move([10,20,30], p=yrot(25, p=path3d(circle(d=100))));
//   plane = plane3pt([1,0,0],[0,1,0],[0,0,1]);
//   proj = projection_on_plane(plane,points);
function projection_on_plane(plane, points) =
    assert( _valid_plane(plane), "Invalid plane." )
    assert( is_path(points), "Invalid list of points or dimension." )
    let( 
        p  = len(points[0])==2
             ? [for(pi=points) point3d(pi) ]
             : points, 
        plane = normalize_plane(plane),
        n = point3d(plane)
        ) 
    [for(pi=p) pi - (pi*n - plane[3])*n];


// Function: plane_point_nearest_origin()
// Usage:
//   pt = plane_point_nearest_origin(plane);
// Description:
//   Returns the point on the plane that is closest to the origin.
function plane_point_nearest_origin(plane) =
    let( plane = normalize_plane(plane) )
    point3d(plane) * plane[3];


// Function: distance_from_plane()
// Usage:
//   distance_from_plane(plane, point)
// Description:
//   Given a plane as [A,B,C,D] where the cartesian equation for that plane
//   is Ax+By+Cz=D, determines how far from that plane the given point is.
//   The returned distance will be positive if the point is in front of the
//   plane; on the same side of the plane as the normal of that plane points
//   towards.  If the point is behind the plane, then the distance returned
//   will be negative.  The normal of the plane is the same as [A,B,C].
// Arguments:
//   plane = The [A,B,C,D] values for the equation of the plane.
//   point = The distance evaluation point.
function distance_from_plane(plane, point) =
    assert( _valid_plane(plane), "Invalid input plane." )
    assert( is_vector(point,3), "The point should be a 3D point." )
    let( plane = normalize_plane(plane) )
    point3d(plane)* point - plane[3];


// Function: closest_point_on_plane()
// Usage:
//   pt = closest_point_on_plane(plane, point);
// Description:
//   Takes a point, and a plane [A,B,C,D] where the equation of that plane is `Ax+By+Cz=D`.
//   Returns the coordinates of the closest point on that plane to the given `point`.
// Arguments:
//   plane = The [A,B,C,D] coefficients for the equation of the plane.
//   point = The 3D point to find the closest point to.
function closest_point_on_plane(plane, point) =
    assert( _valid_plane(plane), "Invalid input plane." )
    assert( is_vector(point,3), "Invalid point." )
    let( plane = normalize_plane(plane),
        n = point3d(plane),
        d = n*point - plane[3] // distance from plane
        ) 
    point - n*d;


// Returns [POINT, U] if line intersects plane at one point.
// Returns [LINE, undef] if the line is on the plane.
// Returns undef if line is parallel to, but not on the given plane.
function _general_plane_line_intersection(plane, line, eps=EPSILON) =
    let(
        a = plane*[each line[0],-1],         //  evaluation of the plane expression at line[0] 
        b = plane*[each(line[1]-line[0]),0]  // difference between the plane expression evaluation at line[1] and at line[0]
    )
    approx(b,0,eps)                          // is  (line[1]-line[0]) "parallel" to the plane ?
    ? approx(a,0,eps)                        // is line[0] on the plane ?
       ? [line,undef]                        // line is on the plane
       : undef                               // line is parallel but not on the plane
    : [ line[0]-a/b*(line[1]-line[0]), -a/b ];
    
    
// Function: normalize_plane()
// Usage: 
//   nplane = normalize_plane(plane);
// Description:
//   Returns a new representation [A,B,C,D] of `plane` where norm([A,B,C]) is equal to one.
function normalize_plane(plane) =
    assert( _valid_plane(plane), "Invalid plane." )
    plane/norm(point3d(plane));


// Function: plane_line_angle()
// Usage: 
//   angle = plane_line_angle(plane,line);
// Description:
//   Compute the angle between a plane [A, B, C, D] and a line, specified as a pair of points [p1,p2].
//   The resulting angle is signed, with the sign positive if the vector p2-p1 lies on 
//   the same side of the plane as the plane's normal vector.  
function plane_line_angle(plane, line) =
    assert( _valid_plane(plane), "Invalid plane." )
    assert( _valid_line(line), "Invalid line." )
    let(
        linedir   = unit(line[1]-line[0]),
        normal    = plane_normal(plane),
        sin_angle = linedir*normal,
        cos_angle = norm(cross(linedir,normal))
        ) 
    atan2(sin_angle,cos_angle);


// Function: plane_line_intersection()
// Usage:
//   pt = plane_line_intersection(plane, line, [bounded], [eps]);
// Description:
//   Takes a line, and a plane [A,B,C,D] where the equation of that plane is `Ax+By+Cz=D`.
//   If `line` intersects `plane` at one point, then that intersection point is returned.
//   If `line` lies on `plane`, then the original given `line` is returned.
//   If `line` is parallel to, but not on `plane`, then undef is returned.
// Arguments:
//   plane = The [A,B,C,D] values for the equation of the plane.
//   line = A list of two distinct 3D points that are on the line.
//   bounded = If false, the line is considered unbounded.  If true, it is treated as a bounded line segment.  If given as `[true, false]` or `[false, true]`, the boundedness of the points are specified individually, allowing the line to be treated as a half-bounded ray.  Default: false (unbounded)
//   eps = The tolerance value in determining whether the line is parallel to the plane.  Default: `EPSILON` (1e-9)
function plane_line_intersection(plane, line, bounded=false, eps=EPSILON) =
    assert( is_finite(eps) && eps>=0, "The tolerance should be a positive number." )
    assert(_valid_plane(plane,eps=eps) && _valid_line(line,dim=3,eps=eps), "Invalid plane and/or line.")
    assert(is_bool(bounded) || (is_list(bounded) && len(bounded)==2), "Invalid bound condition(s).")
    let(
        bounded = is_list(bounded)? bounded : [bounded, bounded],
        res = _general_plane_line_intersection(plane, line, eps=eps)
    )
    is_undef(res) ? undef :
    is_undef(res[1]) ? res[0] :
    bounded[0] && res[1]<0 ? undef :
    bounded[1] && res[1]>1 ? undef :
    res[0];


// Function: polygon_line_intersection()
// Usage:
//   pt = polygon_line_intersection(poly, line, [bounded], [eps]);
// Description:
//   Takes a possibly bounded line, and a 3D planar polygon, and finds their intersection point.
//   If the line and the polygon are on the same plane then returns a list, possibly empty, of 3D line
//   segments, one for each section of the line that is inside the polygon.
//   If the line is not on the plane of the polygon, but intersects it, then returns the 3D intersection
//   point.  If the line does not intersect the polygon, then `undef` is returned.
// Arguments:
//   poly = The 3D planar polygon to find the intersection with.
//   line = A list of two distinct 3D points on the line.
//   bounded = If false, the line is considered unbounded.  If true, it is treated as a bounded line segment.  If given as `[true, false]` or `[false, true]`, the boundedness of the points are specified individually, allowing the line to be treated as a half-bounded ray.  Default: false (unbounded)
//   eps = The tolerance value in determining whether the line is parallel to the plane.  Default: `EPSILON` (1e-9)
function polygon_line_intersection(poly, line, bounded=false, eps=EPSILON) =
    assert( is_finite(eps) && eps>=0, "The tolerance should be a positive number." )
    assert(is_path(poly,dim=3), "Invalid polygon." )
    assert(!is_list(bounded) || len(bounded)==2, "Invalid bound condition(s).")
    assert(_valid_line(line,dim=3,eps=eps), "Invalid line." )
    let(
        bounded = is_list(bounded)? bounded : [bounded, bounded],
        poly = deduplicate(poly),
        indices = noncollinear_triple(poly)
    )
    indices==[] ? undef :
    let(
        p1 = poly[indices[0]],
        p2 = poly[indices[1]],
        p3 = poly[indices[2]],
        plane = plane3pt(p1,p2,p3),
        res = _general_plane_line_intersection(plane, line, eps=eps)
    )
    is_undef(res)? undef :
    is_undef(res[1])
    ? ( let(// Line is on polygon plane.
            linevec = unit(line[1] - line[0]),
            lp1 = line[0] + (bounded[0]? 0 : -1000000) * linevec,
            lp2 = line[1] + (bounded[1]? 0 :  1000000) * linevec,
            poly2d = clockwise_polygon(project_plane(poly, plane)),
            line2d = project_plane([lp1,lp2], plane),
            parts = split_path_at_region_crossings(line2d, [poly2d], closed=false),
            inside = [for (part = parts)
                          if (point_in_polygon(mean(part), poly2d)>0) part
                     ]
        ) 
        !inside? undef :
        let(
            isegs = [for (seg = inside) lift_plane(seg, plane) ]
        ) 
        isegs
    ) 
    :   bounded[0] && res[1]<0? undef :
        bounded[1] && res[1]>1? undef :
        let(
            proj = clockwise_polygon(project_plane(poly, p1, p2, p3)),
            pt = project_plane(res[0], p1, p2, p3)
        ) 
        point_in_polygon(pt, proj) < 0 ? undef : res[0];


// Function: plane_intersection()
// Usage:
//   plane_intersection(plane1, plane2, [plane3])
// Description:
//   Compute the point which is the intersection of the three planes, or the line intersection of two planes.
//   If you give three planes the intersection is returned as a point.  If you give two planes the intersection
//   is returned as a list of two points on the line of intersection.  If any two input planes are parallel
//   or coincident then returns undef.  
function plane_intersection(plane1,plane2,plane3) =
    assert( _valid_plane(plane1) && _valid_plane(plane2) && (is_undef(plane3) ||_valid_plane(plane3)),
                "The input must be 2 or 3 planes." )
    is_def(plane3)
    ?   let(
          matrix = [for(p=[plane1,plane2,plane3]) point3d(p)],
          rhs = [for(p=[plane1,plane2,plane3]) p[3]]
        ) 
        linear_solve(matrix,rhs)
    :   let( normal = cross(plane_normal(plane1), plane_normal(plane2)) ) 
        approx(norm(normal),0) ? undef :
        let(
            matrix = [for(p=[plane1,plane2]) point3d(p)],
            rhs = [plane1[3], plane2[3]],
            point = linear_solve(matrix,rhs)
        ) 
        point==[]? undef: [point, point+normal];


// Function: coplanar()
// Usage:
//   coplanar(points,<eps>);
// Description:
//   Returns true if the given 3D points are non-collinear and are on a plane.
// Arguments:
//   points = The points to test.
//   eps = How much variance is allowed in the planarity test.  Default: `EPSILON` (1e-9)
function coplanar(points, eps=EPSILON) =
    assert( is_path(points,dim=3) , "Input should be a list of 3D points." )
    assert( is_finite(eps) && eps>=0, "The tolerance should be a non-negative number." )
    len(points)<=2 ? false
    :   let( ip = noncollinear_triple(points,error=false,eps=eps) ) 
        ip == [] ? false : 
        let( plane  = plane3pt(points[ip[0]],points[ip[1]],points[ip[2]]), 
             normal = point3d(plane) )
        max( points*normal ) - plane[3]< eps*norm(normal);

    
// Function: points_on_plane()
// Usage:
//   points_on_plane(points, plane, <eps>);
// Description:
//   Returns true if the given 3D points are on the given plane.
// Arguments:
//   plane = The plane to test the points on.
//   points = The list of 3D points to test.
//   eps = How much variance is allowed in the planarity testing.  Default: `EPSILON` (1e-9)
function points_on_plane(points, plane, eps=EPSILON) =
    assert( _valid_plane(plane), "Invalid plane." )
    assert( is_matrix(points,undef,3) && len(points)>0, "Invalid pointlist." ) // using is_matrix it accepts len(points)==1
    assert( is_finite(eps) && eps>=0, "The tolerance should be a positive number." )
    let( normal = point3d(plane),
         pt_nrm = points*normal )
    abs(max( max(pt_nrm) - plane[3], -min(pt_nrm)+plane[3]))< eps*norm(normal);


// Function: in_front_of_plane()
// Usage:
//   in_front_of_plane(plane, point);
// Description:
//   Given a plane as [A,B,C,D] where the cartesian equation for that plane
//   is Ax+By+Cz=D, determines if the given 3D point is on the side of that
//   plane that the normal points towards.  The normal of the plane is the
//   same as [A,B,C].
// Arguments:
//   plane = The [A,B,C,D] coefficients for the equation of the plane.
//   point = The 3D point to test.
function in_front_of_plane(plane, point) =
    distance_from_plane(plane, point) > EPSILON;



// Section: Circle Calculations

// Function&Module: circle_2tangents()
// Usage: As Function
//   circ = circle_2tangents(pt1, pt2, pt3, r|d, <tangents>);
// Usage: As Module
//   circle_2tangents(pt1, pt2, pt3, r|d, <h>, <center>);
// Description:
//   Given a pair of rays with a common origin, and a known circle radius/diameter, finds
//   the centerpoint for the circle of that size that touches both rays tangentally.
//   Both rays start at `pt2`, one passing through `pt1`, and the other through `pt3`.
//   .
//   When called as a module with an `h` height argument, creates a 3D cylinder of `h`
//   length at the found centerpoint, aligned with the found normal.
//   .
//   When called as a module with 2D data and no `h` argument, creates a 2D circle of
//   the given radius/diameter, tangentially touching both rays.
//   .
//   When called as a function with collinear rays, returns `undef`.
//   Otherwise, when called as a function with `tangents=false`, returns `[CP,NORMAL]`.
//   Otherwise, when called as a function with `tangents=true`, returns `[CP,NORMAL,TANPT1,TANPT2,ANG1,ANG2]`.
//   - CP is the centerpoint of the circle.
//   - NORMAL is the normal vector of the plane that the circle is on (UP or DOWN if the points are 2D).
//   - TANPT1 is the point where the circle is tangent to the ray `[pt2,pt1]`.
//   - TANPT2 is the point where the circle is tangent to the ray `[pt2,pt3]`.
//   - ANG1 is the angle from the ray `[CP,pt2]` to the ray `[CP,TANPT1]`
//   - ANG2 is the angle from the ray `[CP,pt2]` to the ray `[CP,TANPT2]`
// Arguments:
//   pt1 = A point that the first ray passes though.
//   pt2 = The starting point of both rays.
//   pt3 = A point that the second ray passes though.
//   r = The radius of the circle to find.
//   d = The diameter of the circle to find.
//   h = Height of the cylinder to create, when called as a module.
//   center = When called as a module, center the cylinder if true,  Default: false
//   tangents = If true, extended information about the tangent points is calculated and returned.  Default: false
// Example(2D):
//   pts = [[60,40], [10,10], [65,5]];
//   rad = 10;
//   stroke([pts[1],pts[0]], endcap2="arrow2");
//   stroke([pts[1],pts[2]], endcap2="arrow2");
//   circ = circle_2tangents(pt1=pts[0], pt2=pts[1], pt3=pts[2], r=rad);
//   translate(circ[0]) {
//       color("green") {
//           stroke(circle(r=rad),closed=true);
//           stroke([[0,0],rad*[cos(315),sin(315)]]);
//       }
//   }
//   move_copies(pts) color("blue") circle(d=2, $fn=12);
//   translate(circ[0]) color("red") circle(d=2, $fn=12);
//   labels = [[pts[0], "pt1"], [pts[1],"pt2"], [pts[2],"pt3"], [circ[0], "CP"], [circ[0]+[cos(315),sin(315)]*rad*0.7, "r"]];
//   for(l=labels) translate(l[0]+[0,2]) color("black") text(text=l[1], size=2.5, halign="center");
// Example(2D):
//   pts = [[-5,25], [5,-25], [45,15]];
//   rad = 12;
//   color("blue") stroke(pts, width=0.75, endcaps="arrow2");
//   circle_2tangents(pt1=pts[0], pt2=pts[1], pt3=pts[2], r=rad);
// Example: Non-centered Cylinder
//   pts = [[45,15,10], [5,-25,5], [-5,25,20]];
//   rad = 12;
//   color("blue") stroke(pts, width=0.75, endcaps="arrow2");
//   circle_2tangents(pt1=pts[0], pt2=pts[1], pt3=pts[2], r=rad, h=10, center=false);
// Example: Non-centered Cylinder
//   pts = [[45,15,10], [5,-25,5], [-5,25,20]];
//   rad = 12;
//   color("blue") stroke(pts, width=0.75, endcaps="arrow2");
//   circle_2tangents(pt1=pts[0], pt2=pts[1], pt3=pts[2], r=rad, h=10, center=true);
function circle_2tangents(pt1, pt2, pt3, r, d, tangents=false) =
    let(r = get_radius(r=r, d=d, dflt=undef))
    assert(r!=undef, "Must specify either r or d.")
    assert( ( is_path(pt1) && len(pt1)==3 && is_undef(pt2) && is_undef(pt3)) 
            || (is_matrix([pt1,pt2,pt3]) && (len(pt1)==2 || len(pt1)==3) ),
            "Invalid input points." )
    is_undef(pt2) 
    ? circle_2tangents(pt1[0], pt1[1], pt1[2], r=r, tangents=tangents) 
    : collinear(pt1, pt2, pt3)? undef :
        let(
            v1 = unit(pt1 - pt2),
            v2 = unit(pt3 - pt2),
            vmid = unit(mean([v1, v2])),
            n = vector_axis(v1, v2),
            a = vector_angle(v1, v2),
            hyp = r / sin(a/2),
            cp = pt2 + hyp * vmid
            ) 
        !tangents ? [cp, n] :
        let(
            x = hyp * cos(a/2),
            tp1 = pt2 + x * v1,
            tp2 = pt2 + x * v2,
            dang1 = vector_angle(tp1-cp,pt2-cp),
            dang2 = vector_angle(tp2-cp,pt2-cp)
            ) 
        [cp, n, tp1, tp2, dang1, dang2];

module circle_2tangents(pt1, pt2, pt3, r, d, h, center=false) {
    c = circle_2tangents(pt1=pt1, pt2=pt2, pt3=pt3, r=r, d=d);
    assert(!is_undef(c), "Cannot find circle when both rays are collinear.");
    cp = c[0]; n = c[1];
    if (approx(point3d(cp).z,0) && approx(point2d(n),[0,0]) && is_undef(h)) {
        translate(cp) circle(r=r, d=d);
    } else {
        assert(is_finite(h), "h argument required when result is not flat on the XY plane.");
        translate(cp) {
            rot(from=UP, to=n) {
                cylinder(r=r, d=d, h=h, center=center);
            }
        }
    }
}

// Function&Module: circle_3points()
// Usage: As Function
//   circ = circle_3points(pt1, pt2, pt3);
//   circ = circle_3points([pt1, pt2, pt3]);
// Usage: As Module
//   circle_3points(pt1, pt2, pt3, <h>, <center>);
//   circle_3points([pt1, pt2, pt3], <h>, <center>);
// Description:
//   Returns the [CENTERPOINT, RADIUS, NORMAL] of the circle that passes through three non-collinear
//   points where NORMAL is the normal vector of the plane that the circle is on (UP or DOWN if the points are 2D).
//   The centerpoint will be a 2D or 3D vector, depending on the points input.  If all three
//   points are 2D, then the resulting centerpoint will be 2D, and the normal will be UP ([0,0,1]).
//   If any of the points are 3D, then the resulting centerpoint will be 3D.  If the three points are
//   collinear, then `[undef,undef,undef]` will be returned.  The normal will be a normalized 3D
//   vector with a non-negative Z axis.
//   Instead of 3 arguments, it is acceptable to input the 3 points in a list `pt1`, leaving `pt2`and `pt3` as undef.
// Arguments:
//   pt1 = The first point.
//   pt2 = The second point.
//   pt3 = The third point.
//   h = Height of the cylinder to create, when called as a module.
//   center = When called as a module, center the cylinder if true,  Default: false
// Example(2D):
//   pts = [[60,40], [10,10], [65,5]];
//   circ = circle_3points(pts[0], pts[1], pts[2]);
//   translate(circ[0]) color("green") stroke(circle(r=circ[1]),closed=true,$fn=72);
//   translate(circ[0]) color("red") circle(d=3, $fn=12);
//   move_copies(pts) color("blue") circle(d=3, $fn=12);
// Example(2D):
//   pts = [[30,40], [10,20], [55,30]];
//   circle_3points(pts[0], pts[1], pts[2]);
//   move_copies(pts) color("blue") circle(d=3, $fn=12);
// Example: Non-Centered Cylinder
//   pts = [[30,15,30], [10,20,15], [55,25,25]];
//   circle_3points(pts[0], pts[1], pts[2], h=10, center=false);
//   move_copies(pts) color("cyan") sphere(d=3, $fn=12);
// Example: Centered Cylinder
//   pts = [[30,15,30], [10,20,15], [55,25,25]];
//   circle_3points(pts[0], pts[1], pts[2], h=10, center=true);
//   move_copies(pts) color("cyan") sphere(d=3, $fn=12);
function circle_3points(pt1, pt2, pt3) =
    (is_undef(pt2) && is_undef(pt3) && is_list(pt1))
      ? circle_3points(pt1[0], pt1[1], pt1[2]) 
      : assert( is_vector(pt1) && is_vector(pt2) && is_vector(pt3) 
                && max(len(pt1),len(pt2),len(pt3))<=3 && min(len(pt1),len(pt2),len(pt3))>=2,
                "Invalid point(s)." )
        collinear(pt1,pt2,pt3)? [undef,undef,undef] :
        let(
            v  = [ point3d(pt1), point3d(pt2), point3d(pt3) ], // triangle vertices
            ed = [for(i=[0:2]) v[(i+1)%3]-v[i] ],    // triangle edge vectors
            pm = [for(i=[0:2]) v[(i+1)%3]+v[i] ]/2,  // edge mean points
            es = sortidx( [for(di=ed) norm(di) ] ),   
            e1 = ed[es[1]],                          // take the 2 longest edges
            e2 = ed[es[2]],
            n0 = vector_axis(e1,e2),                 // normal standardization 
            n  = n0.z<0? -n0 : n0,
            sc = plane_intersection(                 
                    [ each e1, e1*pm[es[1]] ],       // planes orthogonal to 2 edges
                    [ each e2, e2*pm[es[2]] ],
                    [ each n,  n*v[0] ]
                ),  // triangle plane
            cp = len(pt1)+len(pt2)+len(pt3)>6 ? sc : [sc.x, sc.y], 
            r  = norm(sc-v[0])
        ) [ cp, r, n ];


module circle_3points(pt1, pt2, pt3, h, center=false) {
    c = circle_3points(pt1, pt2, pt3);
    assert(!is_undef(c[0]), "Points cannot be collinear.");
    cp = c[0];  r = c[1];  n = c[2];
    if (approx(point3d(cp).z,0) && approx(point2d(n),[0,0]) && is_undef(h)) {
        translate(cp) circle(r=r);
    } else {
        assert(is_finite(h));
        translate(cp) rot(from=UP,to=n) cylinder(r=r, h=h, center=center);
    }
}


// Function: circle_point_tangents()
// Usage:
//   tangents = circle_point_tangents(r|d, cp, pt);
// Description:
//   Given a 2d circle and a 2d point outside that circle, finds the 2d tangent point(s) on the circle for a
//   line passing through the point.  Returns a list of zero or more 2D tangent points.
// Arguments:
//   r = Radius of the circle.
//   d = Diameter of the circle.
//   cp = The coordinates of the 2d circle centerpoint.
//   pt = The coordinates of the 2d external point.
// Example:
//   cp = [-10,-10];  r = 30;  pt = [30,10];
//   tanpts = circle_point_tangents(r=r, cp=cp, pt=pt);
//   color("yellow") translate(cp) circle(r=r);
//   color("cyan") for(tp=tanpts) {stroke([tp,pt]); stroke([tp,cp]);}
//   color("red") move_copies(tanpts) circle(d=3,$fn=12);
//   color("blue") move_copies([cp,pt]) circle(d=3,$fn=12);
function circle_point_tangents(r, d, cp, pt) =
    assert(is_finite(r) || is_finite(d), "Invalid radius or diameter." )
    assert(is_path([cp, pt],dim=2), "Invalid center point or external point.")
    let(
        r = get_radius(r=r, d=d, dflt=1),
        delta = pt - cp,
        dist = norm(delta),
        baseang = atan2(delta.y,delta.x)
    ) dist < r? [] :
    approx(dist,r)? [[baseang, pt]] :
    let(
        relang = acos(r/dist),
        angs = [baseang + relang, baseang - relang]
    ) [for (ang=angs) cp + r*[cos(ang),sin(ang)]];


// Function: circle_circle_tangents()
// Usage:
//   segs = circle_circle_tangents(c1, r1|d1, c2, r2|d2);
// Description:
//   Computes 2d lines tangents to a pair of circles in 2d.  Returns a list of line endpoints [p1,p2] where
//   p2 is the tangent point on circle 1 and p2 is the tangent point on circle 2.
//   If four tangents exist then the first one the left hand exterior tangent as regarded looking from
//   circle 1 toward circle 2.  The second value is the right hand exterior tangent.  The third entry
//   gives the interior tangent that starts on the left of circle 1 and crosses to the right side of
//   circle 2.  And the fourth entry is the last interior tangent that starts on the right side of
//   circle 1.  If the circles intersect then the interior tangents don't exist and the function
//   returns only two entries.  If one circle is inside the other one then no tangents exist
//   so the function returns the empty set.  When the circles are tangent a degenerate tangent line
//   passes through the point of tangency of the two circles:  this degenerate line is NOT returned.  
// Example(2D): Four tangents, first in green, second in black, third in blue, last in red.  
//   $fn=32;
//   c1 = [3,4];  r1 = 2;
//   c2 = [7,10]; r2 = 3;
//   pts = circle_circle_tangents(c1,r1,c2,r2);
//   move(c1) stroke(circle(r=r1), width=.1, closed=true);
//   move(c2) stroke(circle(r=r2), width=.1, closed=true);
//   colors = ["green","black","blue","red"];
//   for(i=[0:len(pts)-1]) color(colors[i]) stroke(pts[i],width=.1);
// Example(2D): Circles overlap so only exterior tangents exist.
//   $fn=32;
//   c1 = [4,4];  r1 = 3;
//   c2 = [7,7]; r2 = 2;
//   pts = circle_circle_tangents(c1,r1,c2,r2);
//   move(c1) stroke(circle(r=r1), width=.1, closed=true);
//   move(c2) stroke(circle(r=r2), width=.1, closed=true);
//   colors = ["green","black","blue","red"];
//   for(i=[0:len(pts)-1]) color(colors[i]) stroke(pts[i],width=.1);
// Example(2D): Circles are tangent.  Only exterior tangents are returned.  The degenerate internal tangent is not returned.  
//   $fn=32;
//   c1 = [4,4];  r1 = 4;
//   c2 = [4,10]; r2 = 2;
//   pts = circle_circle_tangents(c1,r1,c2,r2);
//   move(c1) stroke(circle(r=r1), width=.1, closed=true);
//   move(c2) stroke(circle(r=r2), width=.1, closed=true);
//   colors = ["green","black","blue","red"];
//   for(i=[0:1:len(pts)-1]) color(colors[i]) stroke(pts[i],width=.1);
// Example(2D): One circle is inside the other: no tangents exist.  If the interior circle is tangent the single degenerate tangent will not be returned.  
//   $fn=32;
//   c1 = [4,4];  r1 = 4;
//   c2 = [5,5];  r2 = 2;
//   pts = circle_circle_tangents(c1,r1,c2,r2);
//   move(c1) stroke(circle(r=r1), width=.1, closed=true);
//   move(c2) stroke(circle(r=r2), width=.1, closed=true);
//   echo(pts);   // Returns []
function circle_circle_tangents(c1,r1,c2,r2,d1,d2) =
    assert( is_path([c1,c2],dim=2), "Invalid center point(s)." )
    let(
        r1 = get_radius(r1=r1,d1=d1),
        r2 = get_radius(r1=r2,d1=d2),
        Rvals = [r2-r1, r2-r1, -r2-r1, -r2-r1]/norm(c1-c2),
        kvals = [-1,1,-1,1],
        ext = [1,1,-1,-1],
        N = 1-sqr(Rvals[2])>=0 ? 4 :
            1-sqr(Rvals[0])>=0 ? 2 : 0,
        coef= [
            for(i=[0:1:N-1]) [
                [Rvals[i], -kvals[i]*sqrt(1-sqr(Rvals[i]))],
                [kvals[i]*sqrt(1-sqr(Rvals[i])), Rvals[i]]
            ] * unit(c2-c1)
        ]
    ) [
        for(i=[0:1:N-1]) let(
            pt = [
                c1-r1*coef[i],
                c2-ext[i]*r2*coef[i]
            ]
        ) if (pt[0]!=pt[1]) pt
    ];



// Section: Pointlists


// Function: noncollinear_triple()
// Usage:
//   noncollinear_triple(points);
// Description:
//   Finds the indices of three good non-collinear points from the points list `points`.
//   If all points are collinear, returns [].
function noncollinear_triple(points,error=true,eps=EPSILON) =
    assert( is_path(points), "Invalid input points." )
    assert( is_finite(eps) && (eps>=0), "The tolerance should be a non-negative number." )
    let(
        pa = points[0],
        b  = furthest_point(pa, points),
        pb = points[b],
        nrm = norm(pa-pb)
        )
    approx(nrm, 0)
    ? assert(!error, "Cannot find three noncollinear points in pointlist.")
        []
    :   let(
            n = (pb-pa)/nrm,
            distlist = [for(i=[0:len(points)-1]) _dist2line(points[i]-pa, n)]   
           )
        max(distlist)<eps
        ?  assert(!error, "Cannot find three noncollinear points in pointlist.")
           []
        :  [0,b,max_index(distlist)];    


// Function: pointlist_bounds()
// Usage:
//   pointlist_bounds(pts);
// Description:
//   Finds the bounds containing all the points in `pts` which can be a list of points in any dimension.
//   Returns a list of two items: a list of the minimums and a list of the maximums.  For example, with
//   3d points `[[MINX, MINY, MINZ], [MAXX, MAXY, MAXZ]]`
// Arguments:
//   pts = List of points.
function pointlist_bounds(pts) =
    assert(is_matrix(pts) && len(pts)>0 && len(pts[0])>0 , "Invalid pointlist." ) 
    let(ptsT = transpose(pts))
    [
      [for(row=ptsT) min(row)],
      [for(row=ptsT) max(row)]
    ];


// Function: closest_point()
// Usage:
//   closest_point(pt, points);
// Description:
//   Given a list of `points`, finds the index of the closest point to `pt`.
// Arguments:
//   pt = The point to find the closest point to.
//   points = The list of points to search.
function closest_point(pt, points) =
    assert( is_vector(pt), "Invalid point." )
    assert(is_path(points,dim=len(pt)), "Invalid pointlist or incompatible dimensions." )
    min_index([for (p=points) norm(p-pt)]);


// Function: furthest_point()
// Usage:
//   furthest_point(pt, points);
// Description:
//   Given a list of `points`, finds the index of the furthest point from `pt`.
// Arguments:
//   pt = The point to find the farthest point from.
//   points = The list of points to search.
function furthest_point(pt, points) =
    assert( is_vector(pt), "Invalid point." )
    assert(is_path(points,dim=len(pt)), "Invalid pointlist or incompatible dimensions." )
    max_index([for (p=points) norm(p-pt)]);



// Section: Polygons

// Function: polygon_area()
// Usage:
//   area = polygon_area(poly);
// Description:
//   Given a 2D or 3D planar polygon, returns the area of that polygon.  
//   If the polygon is self-crossing, the results are undefined. For non-planar points the result is undef.
//   When `signed` is true, a signed area is returned; a positive area indicates a counterclockwise polygon.
// Arguments:
//   poly = polygon to compute the area of.
//   signed = if true, a signed area is returned (default: false)
function polygon_area(poly, signed=false) =
    assert(is_path(poly), "Invalid polygon." )
    len(poly)<3 ? 0 :
    len(poly[0])==2
    ? sum([for(i=[1:1:len(poly)-2]) cross(poly[i]-poly[0],poly[i+1]-poly[0]) ])/2
    : let( plane = plane_from_points(poly) )
      plane==undef? undef :
      let( n = unit(plane_normal(plane)), 
           total = sum([for(i=[1:1:len(poly)-1]) cross(poly[i]-poly[0],poly[i+1]-poly[0])*n ])/2
          )
      signed ? total : abs(total);


// Function: is_convex_polygon()
// Usage:
//   is_convex_polygon(poly);
// Description:
//   Returns true if the given 2D polygon is convex.  The result is meaningless if the polygon is not simple (self-intersecting).
//   If the points are collinear the result is true. 
// Example:
//   is_convex_polygon(circle(d=50));  // Returns: true
// Example:
//   spiral = [for (i=[0:36]) let(a=-i*10) (10+i)*[cos(a),sin(a)]];
//   is_convex_polygon(spiral);  // Returns: false
function is_convex_polygon(poly) =
    assert(is_path(poly,dim=2), "The input should be a 2D polygon." )
    let( l = len(poly) )
    len([for( i = l-1, 
              c = cross(poly[(i+1)%l]-poly[i], poly[(i+2)%l]-poly[(i+1)%l]), 
              s = sign(c);
            i>=0 && sign(c)==s;
              i = i-1, 
              c = i<0? 0: cross(poly[(i+1)%l]-poly[i],poly[(i+2)%l]-poly[(i+1)%l]), 
              s = s==0 ? sign(c) : s
            ) i 
        ])== l;


// Function: polygon_shift()
// Usage:
//   polygon_shift(poly, i);
// Description:
//   Given a polygon `poly`, rotates the point ordering so that the first point in the polygon path is the one at index `i`.
// Arguments:
//   poly = The list of points in the polygon path.
//   i = The index of the point to shift to the front of the path.
// Example:
//   polygon_shift([[3,4], [8,2], [0,2], [-4,0]], 2);   // Returns [[0,2], [-4,0], [3,4], [8,2]]
function polygon_shift(poly, i) =
    assert(is_path(poly), "Invalid polygon." )
    list_rotate(cleanup_path(poly), i);


// Function: polygon_shift_to_closest_point()
// Usage:
//   polygon_shift_to_closest_point(path, pt);
// Description:
//   Given a polygon `poly`, rotates the point ordering so that the first point in the path is the one closest to the given point `pt`.
function polygon_shift_to_closest_point(poly, pt) =
    assert(is_vector(pt), "Invalid point." )
    assert(is_path(poly,dim=len(pt)), "Invalid polygon or incompatible dimension with the point." )
    let(
        poly = cleanup_path(poly),
        dists = [for (p=poly) norm(p-pt)],
        closest = min_index(dists)
    ) select(poly,closest,closest+len(poly)-1);


// Function: reindex_polygon()
// Usage:
//   newpoly = reindex_polygon(reference, poly);
// Description:
//   Rotates and possibly reverses the point order of a 2d or 3d polygon path to optimize its pairwise point
//   association with a reference polygon.  The two polygons must have the same number of vertices and be the same dimension. 
//   The optimization is done by computing the distance, norm(reference[i]-poly[i]), between
//   corresponding pairs of vertices of the two polygons and choosing the polygon point order that
//   makes the total sum over all pairs as small as possible.  Returns the reindexed polygon.  Note
//   that the geometry of the polygon is not changed by this operation, just the labeling of its
//   vertices.  If the input polygon is 2d and is oriented opposite the reference then its point order is
//   flipped.
// Arguments:
//   reference = reference polygon path
//   poly = input polygon to reindex
// Example(2D):  The red dots show the 0th entry in the two input path lists.  Note that the red dots are not near each other.  The blue dot shows the 0th entry in the output polygon
//   pent = subdivide_path([for(i=[0:4])[sin(72*i),cos(72*i)]],30);
//   circ = circle($fn=30,r=2.2);
//   reindexed = reindex_polygon(circ,pent);
//   move_copies(concat(circ,pent)) circle(r=.1,$fn=32);
//   color("red") move_copies([pent[0],circ[0]]) circle(r=.1,$fn=32);
//   color("blue") translate(reindexed[0])circle(r=.1,$fn=32);
// Example(2D): The indexing that minimizes the total distance will not necessarily associate the nearest point of `poly` with the reference, as in this example where again the blue dot indicates the 0th entry in the reindexed result.
//   pent = move([3.5,-1],p=subdivide_path([for(i=[0:4])[sin(72*i),cos(72*i)]],30));
//   circ = circle($fn=30,r=2.2);
//   reindexed = reindex_polygon(circ,pent);
//   move_copies(concat(circ,pent)) circle(r=.1,$fn=32);
//   color("red") move_copies([pent[0],circ[0]]) circle(r=.1,$fn=32);
//   color("blue") translate(reindexed[0])circle(r=.1,$fn=32);
function reindex_polygon(reference, poly, return_error=false) = 
    assert(is_path(reference) && is_path(poly,dim=len(reference[0])),
           "Invalid polygon(s) or incompatible dimensions. " )
    assert(len(reference)==len(poly), "The polygons must have the same length.")
    let(
        dim = len(reference[0]),
        N = len(reference),
        fixpoly = dim != 2? poly :
                  polygon_is_clockwise(reference)
                  ? clockwise_polygon(poly)
                  : ccw_polygon(poly),
        I   = [for(i=[0:N-1]) 1],
        val = [ for(k=[0:N-1]) 
                  [for(i=[0:N-1]) 
                     (reference[i]*poly[(i+k)%N]) ] ]*I,
        optimal_poly = polygon_shift(fixpoly, max_index(val))
      )
    return_error? [optimal_poly, min(poly*(I*poly)-2*val)] :
    optimal_poly;
    

// Function: align_polygon()
// Usage:
//   newpoly = align_polygon(reference, poly, angles, <cp>);
// Description:
//   Tries the list or range of angles to find a rotation of the specified 2D polygon that best aligns
//   with the reference 2D polygon.  For each angle, the polygon is reindexed, which is a costly operation
//   so if run time is a problem, use a smaller sampling of angles.  Returns the rotated and reindexed
//   polygon.
// Arguments:
//   reference = reference polygon 
//   poly = polygon to rotate into alignment with the reference
//   angles = list or range of angles to test
//   cp = centerpoint for rotations
// Example(2D): The original hexagon in yellow is not well aligned with the pentagon.  Turning it so the faces line up gives an optimal alignment, shown in red.  
//   $fn=32;
//   pentagon = subdivide_path(pentagon(side=2),60);
//   hexagon = subdivide_path(hexagon(side=2.7),60);
//   color("red") move_copies(scale(1.4,p=align_polygon(pentagon,hexagon,[0:10:359]))) circle(r=.1);
//   move_copies(concat(pentagon,hexagon))circle(r=.1);
function align_polygon(reference, poly, angles, cp) =
    assert(is_path(reference,dim=2) && is_path(poly,dim=2),
           "Invalid polygon(s). " )
    assert(len(reference)==len(poly), "The polygons must have the same length.")
    assert( (is_vector(angles) && len(angles)>0) || valid_range(angles),
            "The `angle` parameter must be a range or a non void list of numbers.")
    let(     // alignments is a vector of entries of the form: [polygon, error]
        alignments = [
            for(angle=angles) reindex_polygon(
                reference,
                zrot(angle,p=poly,cp=cp),
                return_error=true
            )
        ],
        best = min_index(subindex(alignments,1))
    ) alignments[best][0];


// Function: centroid()
// Usage:
//   cp = centroid(poly);
// Description:
//   Given a simple 2D polygon, returns the 2D coordinates of the polygon's centroid.
//   Given a simple 3D planar polygon, returns the 3D coordinates of the polygon's centroid.
//   If the polygon is self-intersecting, the results are undefined.
function centroid(poly) =
    assert( is_path(poly,dim=[2,3]), "The input must be a 2D or 3D polygon." )
    len(poly[0])==2
    ? sum([
            for(i=[0:len(poly)-1])
            let(segment=select(poly,i,i+1))
            det2(segment)*sum(segment)
          ]) / 6 / polygon_area(poly)
    : let( plane = plane_from_points(poly, fast=true) )
      assert( !is_undef(plane), "The polygon must be planar." )
      let(
        n = plane_normal(plane),
        val = sum([for(i=[1:len(poly)-2])
                      let(
                         v0 = poly[0],
                         v1 = poly[i],
                         v2 = poly[i+1],
                         area = cross(v2-v0,v1-v0)*n
                         )
                      [ area, (v0+v1+v2)*area ]
                  ] )
          )
      val[1]/val[0]/3;
            

// Function: point_in_polygon()
// Usage:
//   point_in_polygon(point, poly, <eps>)
// Description:
//   This function tests whether the given 2D point is inside, outside or on the boundary of
//   the specified 2D polygon using either the Nonzero Winding rule or the Even-Odd rule.
//   See https://en.wikipedia.org/wiki/Nonzero-rule and https://en.wikipedia.org/wiki/Even–odd_rule.
//   The polygon is given as a list of 2D points, not including the repeated end point.
//   Returns -1 if the point is outside the polyon.
//   Returns 0 if the point is on the boundary.
//   Returns 1 if the point lies in the interior.
//   The polygon does not need to be simple: it can have self-intersections.
//   But the polygon cannot have holes (it must be simply connected).
//   Rounding error may give mixed results for points on or near the boundary.
// Arguments:
//   point = The 2D point to check position of.
//   poly = The list of 2D path points forming the perimeter of the polygon.
//   nonzero = The rule to use: true for "Nonzero" rule and false for "Even-Odd" (Default: true )
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function point_in_polygon(point, poly, eps=EPSILON, nonzero=true) =
    // Original algorithms from http://geomalgorithms.com/a03-_inclusion.html
    assert( is_vector(point,2) && is_path(poly,dim=2) && len(poly)>2,
            "The point and polygon should be in 2D. The polygon should have more that 2 points." )
    assert( is_finite(eps) && eps>=0, "Invalid tolerance." )
    // Does the point lie on any edges?  If so return 0.
    let(
        on_brd = [for(i=[0:1:len(poly)-1]) 
                    let( seg = select(poly,i,i+1) ) 
                    if( !approx(seg[0],seg[1],eps=EPSILON) ) 
                        point_on_segment2d(point, seg, eps=eps)? 1:0 ]
        )
    sum(on_brd) > 0
    ? 0 
    :   nonzero
        ?    // Compute winding number and return 1 for interior, -1 for exterior
            let(
                windchk = [for(i=[0:1:len(poly)-1]) 
                            let(seg=select(poly,i,i+1)) 
                            if(!approx(seg[0],seg[1],eps=eps)) 
                                _point_above_below_segment(point, seg)
                          ]
                )
            sum(windchk) != 0 ? 1 : -1
        :   // or compute the crossings with the ray [point, point+[1,0]]
            let( 
              n  = len(poly),
              cross = 
                [for(i=[0:n-1])
                    let( 
                      p0 = poly[i]-point, 
                      p1 = poly[(i+1)%n]-point
                      )
                    if( ( (p1.y>eps && p0.y<=0) || (p1.y<=0 && p0.y>eps) )
                        &&  0 < p0.x - p0.y *(p1.x - p0.x)/(p1.y - p0.y) )
                    1
                ]
            )
            2*(len(cross)%2)-1;;


// Function: polygon_is_clockwise()
// Usage:
//   polygon_is_clockwise(poly);
// Description:
//   Return true if the given 2D simple polygon is in clockwise order, false otherwise.
//   Results for complex (self-intersecting) polygon are indeterminate.
// Arguments:
//   poly = The list of 2D path points for the perimeter of the polygon.
function polygon_is_clockwise(poly) =
    assert(is_path(poly,dim=2), "Input should be a 2d path")
    polygon_area(poly, signed=true)<0;


// Function: clockwise_polygon()
// Usage:
//   clockwise_polygon(poly);
// Description:
//   Given a 2D polygon path, returns the clockwise winding version of that path.
function clockwise_polygon(poly) =
    assert(is_path(poly,dim=2), "Input should be a 2d polygon")
    polygon_area(poly, signed=true)<0 ? poly : reverse_polygon(poly);


// Function: ccw_polygon()
// Usage:
//   ccw_polygon(poly);
// Description:
//   Given a 2D polygon poly, returns the counter-clockwise winding version of that poly.
function ccw_polygon(poly) =
    assert(is_path(poly,dim=2), "Input should be a 2d polygon")
    polygon_area(poly, signed=true)<0 ? reverse_polygon(poly) : poly;


// Function: reverse_polygon()
// Usage:
//   reverse_polygon(poly)
// Description:
//   Reverses a polygon's winding direction, while still using the same start point.
function reverse_polygon(poly) =
    assert(is_path(poly), "Input should be a polygon")
    let(lp=len(poly)) [for (i=idx(poly)) poly[(lp-i)%lp]];


// Function: polygon_normal()
// Usage:
//   n = polygon_normal(poly);
// Description:
//   Given a 3D planar polygon, returns a unit-length normal vector for the
//   clockwise orientation of the polygon. 
function polygon_normal(poly) =
    assert(is_path(poly,dim=3), "Invalid 3D polygon." )
    let(
        poly = cleanup_path(poly),
        p0 = poly[0],
        n = sum([
            for (i=[1:1:len(poly)-2])
            cross(poly[i+1]-p0, poly[i]-p0)
        ])
    ) unit(n);


function _split_polygon_at_x(poly, x) =
    let(
        xs = subindex(poly,0)
    ) (min(xs) >= x || max(xs) <= x)? [poly] :
    let(
        poly2 = [
            for (p = pair_wrap(poly)) each [
                p[0],
                if(
                    (p[0].x < x && p[1].x > x) ||
                    (p[1].x < x && p[0].x > x)
                ) let(
                    u = (x - p[0].x) / (p[1].x - p[0].x)
                ) [
                    x,  // Important for later exact match tests
                    u*(p[1].y-p[0].y)+p[0].y,
                    u*(p[1].z-p[0].z)+p[0].z,
                ]
            ]
        ],
        out1 = [for (p = poly2) if(p.x <= x) p],
        out2 = [for (p = poly2) if(p.x >= x) p],
        out3 = [
            if (len(out1)>=3) each split_path_at_self_crossings(out1),
            if (len(out2)>=3) each split_path_at_self_crossings(out2),
        ],
        out = [for (p=out3) if (len(p) > 2) cleanup_path(p)]
    ) out;


function _split_polygon_at_y(poly, y) =
    let(
        ys = subindex(poly,1)
    ) (min(ys) >= y || max(ys) <= y)? [poly] :
    let(
        poly2 = [
            for (p = pair_wrap(poly)) each [
                p[0],
                if(
                    (p[0].y < y && p[1].y > y) ||
                    (p[1].y < y && p[0].y > y)
                ) let(
                    u = (y - p[0].y) / (p[1].y - p[0].y)
                ) [
                    u*(p[1].x-p[0].x)+p[0].x,
                    y,  // Important for later exact match tests
                    u*(p[1].z-p[0].z)+p[0].z,
                ]
            ]
        ],
        out1 = [for (p = poly2) if(p.y <= y) p],
        out2 = [for (p = poly2) if(p.y >= y) p],
        out3 = [
            if (len(out1)>=3) each split_path_at_self_crossings(out1),
            if (len(out2)>=3) each split_path_at_self_crossings(out2),
        ],
        out = [for (p=out3) if (len(p) > 2) cleanup_path(p)]
    ) out;


function _split_polygon_at_z(poly, z) =
    let(
        zs = subindex(poly,2)
    ) (min(zs) >= z || max(zs) <= z)? [poly] :
    let(
        poly2 = [
            for (p = pair_wrap(poly)) each [
                p[0],
                if(
                    (p[0].z < z && p[1].z > z) ||
                    (p[1].z < z && p[0].z > z)
                ) let(
                    u = (z - p[0].z) / (p[1].z - p[0].z)
                ) [
                    u*(p[1].x-p[0].x)+p[0].x,
                    u*(p[1].y-p[0].y)+p[0].y,
                    z,  // Important for later exact match tests
                ]
            ]
        ],
        out1 = [for (p = poly2) if(p.z <= z) p],
        out2 = [for (p = poly2) if(p.z >= z) p],
        out3 = [
            if (len(out1)>=3) each split_path_at_self_crossings(close_path(out1), closed=false),
            if (len(out2)>=3) each split_path_at_self_crossings(close_path(out2), closed=false),
        ],
        out = [for (p=out3) if (len(p) > 2) cleanup_path(p)]
    ) out;


// Function: split_polygons_at_each_x()
// Usage:
//   splitpolys = split_polygons_at_each_x(polys, xs);
// Description:
//   Given a list of 3D polygons, splits all of them wherever they cross any X value given in `xs`.
// Arguments:
//   polys = A list of 3D polygons to split.
//   xs = A list of scalar X values to split at.
function split_polygons_at_each_x(polys, xs, _i=0) =
    assert( is_consistent(polys) && is_path(poly[0],dim=3) ,
            "The input list should contains only 3D polygons." )
    assert( is_finite(xs), "The split value list should contain only numbers." )  
    _i>=len(xs)? polys :
    split_polygons_at_each_x(
        [
            for (poly = polys)
            each _split_polygon_at_x(poly, xs[_i])
        ], xs, _i=_i+1
    );
    

// Function: split_polygons_at_each_y()
// Usage:
//   splitpolys = split_polygons_at_each_y(polys, ys);
// Description:
//   Given a list of 3D polygons, splits all of them wherever they cross any Y value given in `ys`.
// Arguments:
//   polys = A list of 3D polygons to split.
//   ys = A list of scalar Y values to split at.
function split_polygons_at_each_y(polys, ys, _i=0) =
//    assert( is_consistent(polys) && is_path(polys[0],dim=3) , // not all polygons should have the same length!!!
  //          "The input list should contains only 3D polygons." )
    assert( is_finite(ys) || is_vector(ys), "The split value list should contain only numbers." )  //***
    _i>=len(ys)? polys :
    split_polygons_at_each_y(
        [
            for (poly = polys)
            each _split_polygon_at_y(poly, ys[_i])
        ], ys, _i=_i+1
    );


// Function: split_polygons_at_each_z()
// Usage:
//   splitpolys = split_polygons_at_each_z(polys, zs);
// Description:
//   Given a list of 3D polygons, splits all of them wherever they cross any Z value given in `zs`.
// Arguments:
//   polys = A list of 3D polygons to split.
//   zs = A list of scalar Z values to split at.
function split_polygons_at_each_z(polys, zs, _i=0) =
    assert( is_consistent(polys) && is_path(poly[0],dim=3) ,
            "The input list should contains only 3D polygons." )
    assert( is_finite(zs), "The split value list should contain only numbers." )  
    _i>=len(zs)? polys :
    split_polygons_at_each_z(
        [
            for (poly = polys)
            each _split_polygon_at_z(poly, zs[_i])
        ], zs, _i=_i+1
    );


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
