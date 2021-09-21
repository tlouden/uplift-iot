//////////////////////////////////////////////////////////////////////
// LibFile: math.scad
//   Math helper functions.
//   To use, add the following lines to the beginning of your file:
//   ```
//   use <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Math Constants

PHI = (1+sqrt(5))/2;  // The golden ratio phi.

EPSILON = 1e-9;  // A really small value useful in comparing FP numbers.  ie: abs(a-b)<EPSILON

INF = 1/0;  // The value `inf`, useful for comparisons.

NAN = acos(2);  // The value `nan`, useful for comparisons.



// Section: Simple math

// Function: sqr()
// Usage:
//   sqr(x);
// Description:
//   If given a number, returns the square of that number,
//   If given a vector, returns the sum-of-squares/dot product of the vector elements.
//   If given a matrix, returns the matrix multiplication of the matrix with itself.
// Examples:
//   sqr(3);     // Returns: 9
//   sqr(-4);    // Returns: 16
//   sqr([2,3,4]); // Returns: 29
//   sqr([[1,2],[3,4]]);  // Returns [[7,10],[15,22]]
function sqr(x) = 
    assert(is_finite(x) || is_vector(x) || is_matrix(x), "Input is not a number nor a list of numbers.")
    x*x;


// Function: log2()
// Usage:
//   foo = log2(x);
// Description:
//   Returns the logarithm base 2 of the value given.
// Examples:
//   log2(0.125);  // Returns: -3
//   log2(16);     // Returns: 4
//   log2(256);    // Returns: 8
function log2(x) = 
    assert( is_finite(x), "Input is not a number.")
    ln(x)/ln(2);

// this may return NAN or INF; should it check x>0 ?

// Function: hypot()
// Usage:
//   l = hypot(x,y,<z>);
// Description:
//   Calculate hypotenuse length of a 2D or 3D triangle.
// Arguments:
//   x = Length on the X axis.
//   y = Length on the Y axis.
//   z = Length on the Z axis.  Optional.
// Example:
//   l = hypot(3,4);  // Returns: 5
//   l = hypot(3,4,5);  // Returns: ~7.0710678119
function hypot(x,y,z=0) = 
    assert( is_vector([x,y,z]), "Improper number(s).")
    norm([x,y,z]);


// Function: factorial()
// Usage:
//   x = factorial(n,<d>);
// Description:
//   Returns the factorial of the given integer value, or n!/d! if d is given.  
// Arguments:
//   n = The integer number to get the factorial of.  (n!)
//   d = If given, the returned value will be (n! / d!)
// Example:
//   x = factorial(4);  // Returns: 24
//   y = factorial(6);  // Returns: 720
//   z = factorial(9);  // Returns: 362880
function factorial(n,d=0) =
    assert(is_int(n) && is_int(d) && n>=0 && d>=0, "Factorial is defined only for non negative integers")
    assert(d<=n, "d cannot be larger than n")
    product([1,for (i=[n:-1:d+1]) i]);


// Function: binomial()
// Usage:
//   x = binomial(n);
// Description:
//   Returns the binomial coefficients of the integer `n`.  
// Arguments:
//   n = The integer to get the binomial coefficients of
// Example:
//   x = binomial(3);  // Returns: [1,3,3,1]
//   y = binomial(4);  // Returns: [1,4,6,4,1]
//   z = binomial(6);  // Returns: [1,6,15,20,15,6,1]
function binomial(n) =
    assert( is_int(n) && n>0, "Input is not an integer greater than 0.")
    [for( c = 1, i = 0; 
        i<=n; 
         c = c*(n-i)/(i+1), i = i+1
        ) c ] ;


// Function: binomial_coefficient()
// Usage:
//   x = binomial_coefficient(n,k);
// Description:
//   Returns the k-th binomial coefficient of the integer `n`.  
// Arguments:
//   n = The integer to get the binomial coefficient of
//   k = The binomial coefficient index
// Example:
//   x = binomial_coefficient(3,2);  // Returns: 3
//   y = binomial_coefficient(10,6); // Returns: 210
function binomial_coefficient(n,k) =
    assert( is_int(n) && is_int(k), "Some input is not a number.")
    k < 0 || k > n ? 0 :
    k ==0 || k ==n ? 1 :
    let( k = min(k, n-k),
         b = [for( c = 1, i = 0; 
                   i<=k; 
                   c = c*(n-i)/(i+1), i = i+1
                 ) c] )
    b[len(b)-1];


// Function: lerp()
// Usage:
//   x = lerp(a, b, u);
//   l = lerp(a, b, LIST);
// Description:
//   Interpolate between two values or vectors.
//   If `u` is given as a number, returns the single interpolated value.
//   If `u` is 0.0, then the value of `a` is returned.
//   If `u` is 1.0, then the value of `b` is returned.
//   If `u` is a range, or list of numbers, returns a list of interpolated values.
//   It is valid to use a `u` value outside the range 0 to 1.  The result will be an extrapolation
//   along the slope formed by `a` and `b`.
// Arguments:
//   a = First value or vector.
//   b = Second value or vector.
//   u = The proportion from `a` to `b` to calculate.  Standard range is 0.0 to 1.0, inclusive.  If given as a list or range of values, returns a list of results.
// Example:
//   x = lerp(0,20,0.3);  // Returns: 6
//   x = lerp(0,20,0.8);  // Returns: 16
//   x = lerp(0,20,-0.1); // Returns: -2
//   x = lerp(0,20,1.1);  // Returns: 22
//   p = lerp([0,0],[20,10],0.25);  // Returns [5,2.5]
//   l = lerp(0,20,[0.4,0.6]);  // Returns: [8,12]
//   l = lerp(0,20,[0.25:0.25:0.75]);  // Returns: [5,10,15]
// Example(2D):
//   p1 = [-50,-20];  p2 = [50,30];
//   stroke([p1,p2]);
//   pts = lerp(p1, p2, [0:1/8:1]);
//   // Points colored in ROYGBIV order.
//   rainbow(pts) translate($item) circle(d=3,$fn=8);
function lerp(a,b,u) =
    assert(same_shape(a,b), "Bad or inconsistent inputs to lerp")
    is_finite(u)? (1-u)*a + u*b :
    assert(is_finite(u) || is_vector(u) || valid_range(u), "Input u to lerp must be a number, vector, or valid range.")
    [for (v = u) (1-v)*a + v*b ];



// Section: Hyperbolic Trigonometry

// Function: sinh()
// Description: Takes a value `x`, and returns the hyperbolic sine of it.
function sinh(x) =
    assert(is_finite(x), "The input must be a finite number.")
    (exp(x)-exp(-x))/2;


// Function: cosh()
// Description: Takes a value `x`, and returns the hyperbolic cosine of it.
function cosh(x) =
    assert(is_finite(x), "The input must be a finite number.")
    (exp(x)+exp(-x))/2;


// Function: tanh()
// Description: Takes a value `x`, and returns the hyperbolic tangent of it.
function tanh(x) =
    assert(is_finite(x), "The input must be a finite number.")
    sinh(x)/cosh(x);


// Function: asinh()
// Description: Takes a value `x`, and returns the inverse hyperbolic sine of it.
function asinh(x) =
    assert(is_finite(x), "The input must be a finite number.")
    ln(x+sqrt(x*x+1));


// Function: acosh()
// Description: Takes a value `x`, and returns the inverse hyperbolic cosine of it.
function acosh(x) =
    assert(is_finite(x), "The input must be a finite number.")
    ln(x+sqrt(x*x-1));


// Function: atanh()
// Description: Takes a value `x`, and returns the inverse hyperbolic tangent of it.
function atanh(x) =
    assert(is_finite(x), "The input must be a finite number.")
    ln((1+x)/(1-x))/2;


// Section: Quantization

// Function: quant()
// Description:
//   Quantize a value `x` to an integer multiple of `y`, rounding to the nearest multiple.
//   If `x` is a list, then every item in that list will be recursively quantized.
// Arguments:
//   x = The value to quantize.
//   y = The multiple to quantize to.
// Example:
//   quant(12,4);    // Returns: 12
//   quant(13,4);    // Returns: 12
//   quant(13.1,4);  // Returns: 12
//   quant(14,4);    // Returns: 16
//   quant(14.1,4);  // Returns: 16
//   quant(15,4);    // Returns: 16
//   quant(16,4);    // Returns: 16
//   quant(9,3);     // Returns: 9
//   quant(10,3);    // Returns: 9
//   quant(10.4,3);  // Returns: 9
//   quant(10.5,3);  // Returns: 12
//   quant(11,3);    // Returns: 12
//   quant(12,3);    // Returns: 12
//   quant([12,13,13.1,14,14.1,15,16],4);  // Returns: [12,12,12,16,16,16,16]
//   quant([9,10,10.4,10.5,11,12],3);      // Returns: [9,9,9,12,12,12]
//   quant([[9,10,10.4],[10.5,11,12]],3);  // Returns: [[9,9,9],[12,12,12]]
function quant(x,y) =
    assert(is_finite(y) && !approx(y,0,eps=1e-24), "The multiple must be a non zero number.")
    is_list(x)
    ?   [for (v=x) quant(v,y)]
    :   assert( is_finite(x), "The input to quantize must be a number or a list of numbers.")
        floor(x/y+0.5)*y;


// Function: quantdn()
// Description:
//   Quantize a value `x` to an integer multiple of `y`, rounding down to the previous multiple.
//   If `x` is a list, then every item in that list will be recursively quantized down.
// Arguments:
//   x = The value to quantize.
//   y = The multiple to quantize to.
// Examples:
//   quantdn(12,4);    // Returns: 12
//   quantdn(13,4);    // Returns: 12
//   quantdn(13.1,4);  // Returns: 12
//   quantdn(14,4);    // Returns: 12
//   quantdn(14.1,4);  // Returns: 12
//   quantdn(15,4);    // Returns: 12
//   quantdn(16,4);    // Returns: 16
//   quantdn(9,3);     // Returns: 9
//   quantdn(10,3);    // Returns: 9
//   quantdn(10.4,3);  // Returns: 9
//   quantdn(10.5,3);  // Returns: 9
//   quantdn(11,3);    // Returns: 9
//   quantdn(12,3);    // Returns: 12
//   quantdn([12,13,13.1,14,14.1,15,16],4);  // Returns: [12,12,12,12,12,12,16]
//   quantdn([9,10,10.4,10.5,11,12],3);      // Returns: [9,9,9,9,9,12]
//   quantdn([[9,10,10.4],[10.5,11,12]],3);  // Returns: [[9,9,9],[9,9,12]]
function quantdn(x,y) =
    assert(is_finite(y) && !approx(y,0,eps=1e-24), "The multiple must be a non zero number.")
    is_list(x)
    ?    [for (v=x) quantdn(v,y)]
    :    assert( is_finite(x), "The input to quantize must be a number or a list of numbers.")
        floor(x/y)*y;


// Function: quantup()
// Description:
//   Quantize a value `x` to an integer multiple of `y`, rounding up to the next multiple.
//   If `x` is a list, then every item in that list will be recursively quantized up.
// Arguments:
//   x = The value to quantize.
//   y = The multiple to quantize to.
// Examples:
//   quantup(12,4);    // Returns: 12
//   quantup(13,4);    // Returns: 16
//   quantup(13.1,4);  // Returns: 16
//   quantup(14,4);    // Returns: 16
//   quantup(14.1,4);  // Returns: 16
//   quantup(15,4);    // Returns: 16
//   quantup(16,4);    // Returns: 16
//   quantup(9,3);     // Returns: 9
//   quantup(10,3);    // Returns: 12
//   quantup(10.4,3);  // Returns: 12
//   quantup(10.5,3);  // Returns: 12
//   quantup(11,3);    // Returns: 12
//   quantup(12,3);    // Returns: 12
//   quantup([12,13,13.1,14,14.1,15,16],4);  // Returns: [12,16,16,16,16,16,16]
//   quantup([9,10,10.4,10.5,11,12],3);      // Returns: [9,12,12,12,12,12]
//   quantup([[9,10,10.4],[10.5,11,12]],3);  // Returns: [[9,12,12],[12,12,12]]
function quantup(x,y) =
    assert(is_finite(y) && !approx(y,0,eps=1e-24), "The multiple must be a non zero number.")
    is_list(x)
    ?    [for (v=x) quantup(v,y)]
    :    assert( is_finite(x), "The input to quantize must be a number or a list of numbers.")
        ceil(x/y)*y;


// Section: Constraints and Modulos

// Function: constrain()
// Usage:
//   constrain(v, minval, maxval);
// Description:
//   Constrains value to a range of values between minval and maxval, inclusive.
// Arguments:
//   v = value to constrain.
//   minval = minimum value to return, if out of range.
//   maxval = maximum value to return, if out of range.
// Example:
//   constrain(-5, -1, 1);   // Returns: -1
//   constrain(5, -1, 1);    // Returns: 1
//   constrain(0.3, -1, 1);  // Returns: 0.3
//   constrain(9.1, 0, 9);   // Returns: 9
//   constrain(-0.1, 0, 9);  // Returns: 0
function constrain(v, minval, maxval) = 
    assert( is_finite(v+minval+maxval), "Input must be finite number(s).")
    min(maxval, max(minval, v));


// Function: posmod()
// Usage:
//   posmod(x,m)
// Description:
//   Returns the positive modulo `m` of `x`.  Value returned will be in the range 0 ... `m`-1.
// Arguments:
//   x = The value to constrain.
//   m = Modulo value.
// Example:
//   posmod(-700,360);  // Returns: 340
//   posmod(-270,360);  // Returns: 90
//   posmod(-120,360);  // Returns: 240
//   posmod(120,360);   // Returns: 120
//   posmod(270,360);   // Returns: 270
//   posmod(700,360);   // Returns: 340
//   posmod(3,2.5);     // Returns: 0.5
function posmod(x,m) = 
    assert( is_finite(x) && is_finite(m) && !approx(m,0) , "Input must be finite numbers. The divisor cannot be zero.")
    (x%m+m)%m;


// Function: modang(x)
// Usage:
//   ang = modang(x)
// Description:
//   Takes an angle in degrees and normalizes it to an equivalent angle value between -180 and 180.
// Example:
//   modang(-700,360);  // Returns: 20
//   modang(-270,360);  // Returns: 90
//   modang(-120,360);  // Returns: -120
//   modang(120,360);   // Returns: 120
//   modang(270,360);   // Returns: -90
//   modang(700,360);   // Returns: -20
function modang(x) =
    assert( is_finite(x), "Input must be a finite number.")
    let(xx = posmod(x,360)) xx<180? xx : xx-360;


// Function: modrange()
// Usage:
//   modrange(x, y, m, <step>)
// Description:
//   Returns a normalized list of numbers from `x` to `y`, by `step`, modulo `m`.  Wraps if `x` > `y`.
// Arguments:
//   x = The start value to constrain.
//   y = The end value to constrain.
//   m = Modulo value.
//   step = Step by this amount.
// Examples:
//   modrange(90,270,360, step=45);   // Returns: [90,135,180,225,270]
//   modrange(270,90,360, step=45);   // Returns: [270,315,0,45,90]
//   modrange(90,270,360, step=-45);  // Returns: [90,45,0,315,270]
//   modrange(270,90,360, step=-45);  // Returns: [270,225,180,135,90]
function modrange(x, y, m, step=1) =
    assert( is_finite(x+y+step+m) && !approx(m,0), "Input must be finite numbers and the module value cannot be zero." )
    let(
        a = posmod(x, m),
        b = posmod(y, m),
        c = step>0? (a>b? b+m : b) 
            : (a<b? b-m : b)
    ) [for (i=[a:step:c]) (i%m+m)%m ];



// Section: Random Number Generation

// Function: rand_int()
// Usage:
//   rand_int(minval,maxval,N,<seed>);
// Description:
//   Return a list of random integers in the range of minval to maxval, inclusive.
// Arguments:
//   minval = Minimum integer value to return.
//   maxval = Maximum integer value to return.
//   N = Number of random integers to return.
//   seed = If given, sets the random number seed.
// Example:
//   ints = rand_int(0,100,3);
//   int = rand_int(-10,10,1)[0];
function rand_int(minval, maxval, N, seed=undef) =
    assert( is_finite(minval+maxval+N) && (is_undef(seed) || is_finite(seed) ), "Input must be finite numbers.")
    assert(maxval >= minval, "Max value cannot be smaller than minval")
    let (rvect = is_def(seed) ? rands(minval,maxval+1,N,seed) : rands(minval,maxval+1,N))
    [for(entry = rvect) floor(entry)];


// Function: gaussian_rands()
// Usage:
//   gaussian_rands(mean, stddev, <N>, <seed>)
// Description:
//   Returns a random number with a gaussian/normal distribution.
// Arguments:
//   mean = The average random number returned.
//   stddev = The standard deviation of the numbers to be returned.
//   N = Number of random numbers to return.  Default: 1
//   seed = If given, sets the random number seed.
function gaussian_rands(mean, stddev, N=1, seed=undef) =
    assert( is_finite(mean+stddev+N) && (is_undef(seed) || is_finite(seed) ), "Input must be finite numbers.")
    let(nums = is_undef(seed)? rands(0,1,N*2) : rands(0,1,N*2,seed))
    [for (i = list_range(N)) mean + stddev*sqrt(-2*ln(nums[i*2]))*cos(360*nums[i*2+1])];


// Function: log_rands()
// Usage:
//   log_rands(minval, maxval, factor, <N>, <seed>);
// Description:
//   Returns a single random number, with a logarithmic distribution.
// Arguments:
//   minval = Minimum value to return.
//   maxval = Maximum value to return.  `minval` <= X < `maxval`.
//   factor = Log factor to use.  Values of X are returned `factor` times more often than X+1.
//   N = Number of random numbers to return.  Default: 1
//   seed = If given, sets the random number seed.
function log_rands(minval, maxval, factor, N=1, seed=undef) =
    assert( is_finite(minval+maxval+N) 
            && (is_undef(seed) || is_finite(seed) )
            && factor>0, 
            "Input must be finite numbers. `factor` should be greater than zero.")
    assert(maxval >= minval, "maxval cannot be smaller than minval")
    let(
        minv = 1-1/pow(factor,minval),
        maxv = 1-1/pow(factor,maxval),
        nums = is_undef(seed)? rands(minv, maxv, N) : rands(minv, maxv, N, seed)
    ) [for (num=nums) -ln(1-num)/ln(factor)];



// Section: GCD/GCF, LCM

// Function: gcd()
// Usage:
//   gcd(a,b)
// Description:
//   Computes the Greatest Common Divisor/Factor of `a` and `b`.  
function gcd(a,b) =
    assert(is_int(a) && is_int(b),"Arguments to gcd must be integers")
    b==0 ? abs(a) : gcd(b,a % b);


// Computes lcm for two integers
function _lcm(a,b) =
    assert(is_int(a) && is_int(b), "Invalid non-integer parameters to lcm")
    assert(a!=0 && b!=0, "Arguments to lcm must be non zero")
    abs(a*b) / gcd(a,b);


// Computes lcm for a list of values
function _lcmlist(a) =
    len(a)==1 
    ?   a[0] 
    :   _lcmlist(concat(slice(a,0,len(a)-2),[lcm(a[len(a)-2],a[len(a)-1])]));


// Function: lcm()
// Usage:
//   lcm(a,b)
//   lcm(list)
// Description:
//   Computes the Least Common Multiple of the two arguments or a list of arguments.  Inputs should
//   be non-zero integers.  The output is always a positive integer.  It is an error to pass zero
//   as an argument.  
function lcm(a,b=[]) =
    !is_list(a) && !is_list(b) 
    ?   _lcm(a,b) 
    :   let( arglist = concat(force_list(a),force_list(b)) )
        assert(len(arglist)>0, "Invalid call to lcm with empty list(s)")
        _lcmlist(arglist);



// Section: Sums, Products, Aggregate Functions.

// Function: sum()
// Usage:
//   x = sum(v, <dflt>);
// Description:
//   Returns the sum of all entries in the given consistent list.
//   If passed an array of vectors, returns the sum the vectors.
//   If passed an array of matrices, returns the sum of the matrices.
//   If passed an empty list, the value of `dflt` will be returned.
// Arguments:
//   v = The list to get the sum of.
//   dflt = The default value to return if `v` is an empty list.  Default: 0
// Example:
//   sum([1,2,3]);  // returns 6.
//   sum([[1,2,3], [3,4,5], [5,6,7]]);  // returns [9, 12, 15]
function sum(v, dflt=0) =
    v==[]? dflt :
    assert(is_consistent(v), "Input to sum is non-numeric or inconsistent")
    _sum(v,v[0]*0);

function _sum(v,_total,_i=0) = _i>=len(v) ? _total : _sum(v,_total+v[_i], _i+1);


// Function: cumsum()
// Usage:
//   sums = cumsum(v);
// Description:
//   Returns a list where each item is the cumulative sum of all items up to and including the corresponding entry in the input list.
//   If passed an array of vectors, returns a list of cumulative vectors sums.
// Arguments:
//   v = The list to get the sum of.
// Example:
//   cumsum([1,1,1]);  // returns [1,2,3]
//   cumsum([2,2,2]);  // returns [2,4,6]
//   cumsum([1,2,3]);  // returns [1,3,6]
//   cumsum([[1,2,3], [3,4,5], [5,6,7]]);  // returns [[1,2,3], [4,6,8], [9,12,15]]
function cumsum(v) =
    assert(is_consistent(v), "The input is not consistent." )
    _cumsum(v,_i=0,_acc=[]);

function _cumsum(v,_i=0,_acc=[]) =
    _i==len(v) ? _acc :
    _cumsum(
        v, _i+1,
        concat(
            _acc,
            [_i==0 ? v[_i] : select(_acc,-1)+v[_i]]
        )
    );


// Function: sum_of_sines()
// Usage:
//   sum_of_sines(a,sines)
// Description:
//   Gives the sum of a series of sines, at a given angle.
// Arguments:
//   a = Angle to get the value for.
//   sines = List of [amplitude, frequency, offset] items, where the frequency is the number of times the cycle repeats around the circle.
// Examples:
//   v = sum_of_sines(30, [[10,3,0], [5,5.5,60]]);
function sum_of_sines(a, sines) =
    assert( is_finite(a) && is_matrix(sines,undef,3), "Invalid input.")
    sum([ for (s = sines) 
            let(
              ss=point3d(s),
              v=ss[0]*sin(a*ss[1]+ss[2])
            ) v
        ]);


// Function: deltas()
// Usage:
//   delts = deltas(v);
// Description:
//   Returns a list with the deltas of adjacent entries in the given list.
//   The list should be a consistent list of numeric components (numbers, vectors, matrix, etc).
//   Given [a,b,c,d], returns [b-a,c-b,d-c].
// Arguments:
//   v = The list to get the deltas of.
// Example:
//   deltas([2,5,9,17]);  // returns [3,4,8].
//   deltas([[1,2,3], [3,6,8], [4,8,11]]);  // returns [[2,4,5], [1,2,3]]
function deltas(v) = 
    assert( is_consistent(v) && len(v)>1 , "Inconsistent list or with length<=1.")
    [for (p=pair(v)) p[1]-p[0]] ;


// Function: product()
// Usage:
//   x = product(v);
// Description:
//   Returns the product of all entries in the given list.
//   If passed a list of vectors of same dimension, returns a vector of products of each part.
//   If passed a list of square matrices, returns the resulting product matrix.
// Arguments:
//   v = The list to get the product of.
// Example:
//   product([2,3,4]);  // returns 24.
//   product([[1,2,3], [3,4,5], [5,6,7]]);  // returns [15, 48, 105]
function product(v) = 
    assert( is_vector(v) || is_matrix(v) || ( is_matrix(v[0],square=true) && is_consistent(v)), 
    "Invalid input.")
    _product(v, 1, v[0]);

function _product(v, i=0, _tot) = 
    i>=len(v) ? _tot :
    _product( v, 
              i+1, 
              ( is_vector(v[i])? vmul(_tot,v[i]) : _tot*v[i] ) );
               


// Function: cumprod()
// Description:
//   Returns a list where each item is the cumulative product of all items up to and including the corresponding entry in the input list.
//   If passed an array of vectors, returns a list of elementwise vector products.  If passed a list of square matrices returns matrix
//   products multiplying in the order items appear in the list.  
// Arguments:
//   list = The list to get the product of.
// Example:
//   cumprod([1,3,5]);  // returns [1,3,15]
//   cumprod([2,2,2]);  // returns [2,4,8]
//   cumprod([[1,2,3], [3,4,5], [5,6,7]]));  // returns [[1, 2, 3], [3, 8, 15], [15, 48, 105]]
function cumprod(list) =
   is_vector(list) ? _cumprod(list) :
   assert(is_consistent(list), "Input must be a consistent list of scalars, vectors or square matrices")
   is_matrix(list[0]) ? assert(len(list[0])==len(list[0][0]), "Matrices must be square") _cumprod(list) 
                      : _cumprod_vec(list);

function _cumprod(v,_i=0,_acc=[]) =
    _i==len(v) ? _acc :
    _cumprod(
        v, _i+1,
        concat(
            _acc,
            [_i==0 ? v[_i] : _acc[len(_acc)-1]*v[_i]]
        )
    );

function _cumprod_vec(v,_i=0,_acc=[]) =
    _i==len(v) ? _acc :
    _cumprod_vec(
        v, _i+1,
        concat(
            _acc,
            [_i==0 ? v[_i] : vmul(_acc[len(_acc)-1],v[_i])]
        )
    );


// Function: outer_product()
// Usage:
//   x = outer_product(u,v);
// Description:
//   Compute the outer product of two vectors, a matrix.  
// Usage:
//   M = outer_product(u,v);
function outer_product(u,v) =
  assert(is_vector(u) && is_vector(v), "The inputs must be vectors.")
  [for(ui=u) ui*v];


// Function: mean()
// Usage:
//   x = mean(v);
// Description:
//   Returns the arithmetic mean/average of all entries in the given array.
//   If passed a list of vectors, returns a vector of the mean of each part.
// Arguments:
//   v = The list of values to get the mean of.
// Example:
//   mean([2,3,4]);  // returns 3.
//   mean([[1,2,3], [3,4,5], [5,6,7]]);  // returns [3, 4, 5]
function mean(v) = 
    assert(is_list(v) && len(v)>0, "Invalid list.")
    sum(v)/len(v);


// Function: convolve()
// Usage:
//   x = convolve(p,q);
// Description:
//   Given two vectors, finds the convolution of them.
//   The length of the returned vector is len(p)+len(q)-1 .
// Arguments:
//   p = The first vector.
//   q = The second vector.
// Example:
//   a = convolve([1,1],[1,2,1]); // Returns: [1,3,3,1]
//   b = convolve([1,2,3],[1,2,1])); // Returns: [1,4,8,8,3]
function convolve(p,q) =
    p==[] || q==[] ? [] :
    assert( is_vector(p) && is_vector(q), "The inputs should be vectors.")
    let( n = len(p),
         m = len(q))
    [for(i=[0:n+m-2], k1 = max(0,i-n+1), k2 = min(i,m-1) )
       [for(j=[k1:k2]) p[i-j] ] * [for(j=[k1:k2]) q[j] ] 
    ];



// Section: Matrix math

// Function: linear_solve()
// Usage:
//   solv = linear_solve(A,b)
// Description:
//   Solves the linear system Ax=b.  If `A` is square and non-singular the unique solution is returned.  If `A` is overdetermined
//   the least squares solution is returned. If `A` is underdetermined, the minimal norm solution is returned.
//   If `A` is rank deficient or singular then linear_solve returns `[]`.  If `b` is a matrix that is compatible with `A`
//   then the problem is solved for the matrix valued right hand side and a matrix is returned.  Note that if you 
//   want to solve Ax=b1 and Ax=b2 that you need to form the matrix `transpose([b1,b2])` for the right hand side and then
//   transpose the returned value.
function linear_solve(A,b,pivot=true) =
    assert(is_matrix(A), "Input should be a matrix.")
    let(
        m = len(A),
        n = len(A[0])
    )
    assert(is_vector(b,m) || is_matrix(b,m),"Invalid right hand side or incompatible with the matrix")
    let (
        qr = m<n? qr_factor(transpose(A),pivot) : qr_factor(A,pivot),
        maxdim = max(n,m),
        mindim = min(n,m),
        Q = submatrix(qr[0],[0:maxdim-1], [0:mindim-1]),
        R = submatrix(qr[1],[0:mindim-1], [0:mindim-1]),
        P = qr[2],
        zeros = [for(i=[0:mindim-1]) if (approx(R[i][i],0)) i]
    )
    zeros != [] ? [] :
    m<n ? Q*back_substitute(R,transpose(P)*b,transpose=true) // Too messy to avoid input checks here
        : P*_back_substitute(R, transpose(Q)*b);             // Calling internal version skips input checks

// Function: matrix_inverse()
// Usage:
//    mat = matrix_inverse(A)
// Description:
//    Compute the matrix inverse of the square matrix `A`.  If `A` is singular, returns `undef`.
//    Note that if you just want to solve a linear system of equations you should NOT use this function.
//    Instead use [[`linear_solve()`|linear_solve]], or use [[`qr_factor()`|qr_factor]].  The computation
//    will be faster and more accurate.  
function matrix_inverse(A) =
    assert(is_matrix(A) && len(A)==len(A[0]),"Input to matrix_inverse() must be a square matrix")
    linear_solve(A,ident(len(A)));


// Function: null_space()
// Usage:
//   x = null_space(A)
// Description:
//   Returns an orthonormal basis for the null space of `A`, namely the vectors {x} such that Ax=0.
//   If the null space is just the origin then returns an empty list. 
function null_space(A,eps=1e-12) =
    assert(is_matrix(A))
    let(
        Q_R = qr_factor(transpose(A),pivot=true),
        R = Q_R[1],
        zrow = [for(i=idx(R)) if (all_zero(R[i],eps)) i]
    )
    len(zrow)==0 ? [] :
    transpose(subindex(Q_R[0],zrow));


// Function: qr_factor()
// Usage:
//   qr = qr_factor(A,[pivot]);
// Description:
//   Calculates the QR factorization of the input matrix A and returns it as the list [Q,R,P].  This factorization can be
//   used to solve linear systems of equations.  The factorization is A = Q*R*transpose(P).  If pivot is false (the default)
//   then P is the identity matrix and A = Q*R.  If pivot is true then column pivoting results in an R matrix where the diagonal
//   is non-decreasing.  The use of pivoting is supposed to increase accuracy for poorly conditioned problems, and is necessary
//   for rank estimation or computation of the null space, but it may be slower.  
function qr_factor(A, pivot=false) =
    assert(is_matrix(A), "Input must be a matrix." )
    let(
        m = len(A),
        n = len(A[0])
    )
    let(
        qr = _qr_factor(A, Q=ident(m),P=ident(n), pivot=pivot, column=0, m = m, n=n),
        Rzero = let( R = qr[1]) [
            for(i=[0:m-1]) [
                let( ri = R[i] )
                for(j=[0:n-1]) i>j ? 0 : ri[j]
            ]
        ]
    ) [qr[0], Rzero, qr[2]];

function _qr_factor(A,Q,P, pivot, column, m, n) =
    column >= min(m-1,n) ? [Q,A,P] :
    let(
        swap = !pivot ? 1
             : _swap_matrix(n,column,column+max_index([for(i=[column:n-1]) sqr([for(j=[column:m-1]) A[j][i]])])),
        A = pivot ? A*swap : A,
        x = [for(i=[column:1:m-1]) A[i][column]],
        alpha = (x[0]<=0 ? 1 : -1) * norm(x),
        u = x - concat([alpha],repeat(0,m-1)),
        v = alpha==0 ? u : u / norm(u),
        Qc = ident(len(x)) - 2*outer_product(v,v),
        Qf = [for(i=[0:m-1]) [for(j=[0:m-1]) i<column || j<column ? (i==j ? 1 : 0) : Qc[i-column][j-column]]]
    )
    _qr_factor(Qf*A, Q*Qf, P*swap, pivot, column+1, m, n);

// Produces an n x n matrix that swaps column i and j (when multiplied on the right)
function _swap_matrix(n,i,j) =
  assert(i<n && j<n && i>=0 && j>=0, "Swap indices out of bounds")
  [for(y=[0:n-1]) [for (x=[0:n-1])
     x==i ? (y==j ? 1 : 0)
   : x==j ? (y==i ? 1 : 0)
   : x==y ? 1 : 0]];



// Function: back_substitute()
// Usage:
//   x = back_substitute(R, b, <transpose>);
// Description:
//   Solves the problem Rx=b where R is an upper triangular square matrix.  The lower triangular entries of R are
//   ignored.  If transpose==true then instead solve transpose(R)*x=b.
//   You can supply a compatible matrix b and it will produce the solution for every column of b.  Note that if you want to
//   solve Rx=b1 and Rx=b2 you must set b to transpose([b1,b2]) and then take the transpose of the result.  If the matrix
//   is singular (e.g. has a zero on the diagonal) then it returns [].  
function back_substitute(R, b, transpose = false) =
    assert(is_matrix(R, square=true))
    let(n=len(R))
    assert(is_vector(b,n) || is_matrix(b,n),str("R and b are not compatible in back_substitute ",n, len(b)))
    transpose
      ? reverse(_back_substitute(transpose(R, reverse=true), reverse(b)))  
      : _back_substitute(R,b);

function _back_substitute(R, b, x=[]) =
    let(n=len(R))
    len(x) == n ? x
    : let(ind = n - len(x) - 1)
      R[ind][ind] == 0 ? []
    : let(
          newvalue = len(x)==0
            ? b[ind]/R[ind][ind]
            : (b[ind]-select(R[ind],ind+1,-1) * x)/R[ind][ind]
      )
      _back_substitute(R, b, concat([newvalue],x));


// Function: det2()
// Usage:
//   d = det2(M);
// Description:
//   Optimized function that returns the determinant for the given 2x2 square matrix.
// Arguments:
//   M = The 2x2 square matrix to get the determinant of.
// Example:
//   M = [ [6,-2], [1,8] ];
//   det = det2(M);  // Returns: 50
function det2(M) = 
    assert(is_matrix(M,2,2), "Matrix must be 2x2.")
    M[0][0] * M[1][1] - M[0][1]*M[1][0];


// Function: det3()
// Usage:
//   d = det3(M);
// Description:
//   Optimized function that returns the determinant for the given 3x3 square matrix.
// Arguments:
//   M = The 3x3 square matrix to get the determinant of.
// Example:
//   M = [ [6,4,-2], [1,-2,8], [1,5,7] ];
//   det = det3(M);  // Returns: -334
function det3(M) =
    assert(is_matrix(M,3,3), "Matrix must be 3x3.")
    M[0][0] * (M[1][1]*M[2][2]-M[2][1]*M[1][2]) -
    M[1][0] * (M[0][1]*M[2][2]-M[2][1]*M[0][2]) +
    M[2][0] * (M[0][1]*M[1][2]-M[1][1]*M[0][2]);


// Function: determinant()
// Usage:
//   d = determinant(M);
// Description:
//   Returns the determinant for the given square matrix.
// Arguments:
//   M = The NxN square matrix to get the determinant of.
// Example:
//   M = [ [6,4,-2,9], [1,-2,8,3], [1,5,7,6], [4,2,5,1] ];
//   det = determinant(M);  // Returns: 2267
function determinant(M) =
    assert(is_matrix(M, square=true), "Input should be a square matrix." )
    len(M)==1? M[0][0] :
    len(M)==2? det2(M) :
    len(M)==3? det3(M) :
    sum(
        [for (col=[0:1:len(M)-1])
            ((col%2==0)? 1 : -1) *
                M[col][0] *
                determinant(
                    [for (r=[1:1:len(M)-1])
                        [for (c=[0:1:len(M)-1])
                            if (c!=col) M[c][r]
                        ]
                    ]
                )
        ]
    );


// Function: is_matrix()
// Usage:
//   is_matrix(A,<m>,<n>,<square>)
// Description:
//   Returns true if A is a numeric matrix of height m and width n.  If m or n
//   are omitted or set to undef then true is returned for any positive dimension.
// Arguments:
//   A = The matrix to test.
//   m = Is given, requires the matrix to have the given height.
//   n = Is given, requires the matrix to have the given width.
//   square = If true, requires the matrix to have a width equal to its height. Default: false
function is_matrix(A,m,n,square=false) =
   is_list(A)
   && (( is_undef(m) && len(A) ) || len(A)==m)
   && is_list(A[0])
   && (( is_undef(n) && len(A[0]) ) || len(A[0])==n)
   && (!square || len(A) == len(A[0]))
   && is_consistent(A);


// Function: norm_fro()
// Usage:
//    norm_fro(A)
// Description:
//    Computes frobenius norm of input matrix.  The frobenius norm is the square root of the sum of the
//    squares of all of the entries of the matrix.  On vectors it is the same as the usual 2-norm.
//    This is an easily computed norm that is convenient for comparing two matrices.  
function norm_fro(A) =
    assert(is_matrix(A) || is_vector(A))
    norm(flatten(A));


// Function: matrix_trace()
// Usage:
//   matrix_trace(M)
// Description:
//   Computes the trace of a square matrix, the sum of the entries on the diagonal.  
function matrix_trace(M) =
   assert(is_matrix(M,square=true), "Input to trace must be a square matrix")
   [for(i=[0:1:len(M)-1])1] * [for(i=[0:1:len(M)-1]) M[i][i]];


// Section: Comparisons and Logic

// Function: all_zero()
// Usage:
//   x = all_zero(x, <eps>);
// Description:
//   Returns true if the finite number passed to it is approximately zero, to within `eps`.
//   If passed a list, recursively checks if all items in the list are approximately zero.
//   Otherwise, returns false.
// Arguments:
//   x = The value to check.
//   eps = The maximum allowed variance.  Default: `EPSILON` (1e-9)
// Example:
//   all_zero(0);  // Returns: true.
//   all_zero(1e-3);  // Returns: false.
//   all_zero([0,0,0]);  // Returns: true.
//   all_zero([0,0,1e-3]);  // Returns: false.
function all_zero(x, eps=EPSILON) =
    is_finite(x)? approx(x,eps) :
    is_list(x)? (x != [] && [for (xx=x) if(!all_zero(xx,eps=eps)) 1] == []) :
    false;


// Function: all_nonzero()
// Usage:
//   x = all_nonzero(x, <eps>);
// Description:
//   Returns true if the finite number passed to it is not almost zero, to within `eps`.
//   If passed a list, recursively checks if all items in the list are not almost zero.
//   Otherwise, returns false.
// Arguments:
//   x = The value to check.
//   eps = The maximum allowed variance.  Default: `EPSILON` (1e-9)
// Example:
//   all_nonzero(0);  // Returns: false.
//   all_nonzero(1e-3);  // Returns: true.
//   all_nonzero([0,0,0]);  // Returns: false.
//   all_nonzero([0,0,1e-3]);  // Returns: false.
//   all_nonzero([1e-3,1e-3,1e-3]);  // Returns: true.
function all_nonzero(x, eps=EPSILON) =
    is_finite(x)? !approx(x,eps) :
    is_list(x)? (x != [] && [for (xx=x) if(!all_nonzero(xx,eps=eps)) 1] == []) :
    false;


// Function: all_positive()
// Usage:
//   all_positive(x);
// Description:
//   Returns true if the finite number passed to it is greater than zero.
//   If passed a list, recursively checks if all items in the list are positive.
//   Otherwise, returns false.
// Arguments:
//   x = The value to check.
// Example:
//   all_positive(-2);  // Returns: false.
//   all_positive(0);  // Returns: false.
//   all_positive(2);  // Returns: true.
//   all_positive([0,0,0]);  // Returns: false.
//   all_positive([0,1,2]);  // Returns: false.
//   all_positive([3,1,2]);  // Returns: true.
//   all_positive([3,-1,2]);  // Returns: false.
function all_positive(x) =
    is_num(x)? x>0 :
    is_list(x)? (x != [] && [for (xx=x) if(!all_positive(xx)) 1] == []) :
    false;


// Function: all_negative()
// Usage:
//   all_negative(x);
// Description:
//   Returns true if the finite number passed to it is less than zero.
//   If passed a list, recursively checks if all items in the list are negative.
//   Otherwise, returns false.
// Arguments:
//   x = The value to check.
// Example:
//   all_negative(-2);  // Returns: true.
//   all_negative(0);  // Returns: false.
//   all_negative(2);  // Returns: false.
//   all_negative([0,0,0]);  // Returns: false.
//   all_negative([0,1,2]);  // Returns: false.
//   all_negative([3,1,2]);  // Returns: false.
//   all_negative([3,-1,2]);  // Returns: false.
//   all_negative([-3,-1,-2]);  // Returns: true.
function all_negative(x) =
    is_num(x)? x<0 :
    is_list(x)? (x != [] && [for (xx=x) if(!all_negative(xx)) 1] == []) :
    false;


// Function: all_nonpositive()
// Usage:
//   all_nonpositive(x);
// Description:
//   Returns true if the finite number passed to it is less than or equal to zero.
//   If passed a list, recursively checks if all items in the list are nonpositive.
//   Otherwise, returns false.
// Arguments:
//   x = The value to check.
// Example:
//   all_nonpositive(-2);  // Returns: true.
//   all_nonpositive(0);  // Returns: true.
//   all_nonpositive(2);  // Returns: false.
//   all_nonpositive([0,0,0]);  // Returns: true.
//   all_nonpositive([0,1,2]);  // Returns: false.
//   all_nonpositive([3,1,2]);  // Returns: false.
//   all_nonpositive([3,-1,2]);  // Returns: false.
//   all_nonpositive([-3,-1,-2]);  // Returns: true.
function all_nonpositive(x) =
    is_num(x)? x<=0 :
    is_list(x)? (x != [] && [for (xx=x) if(!all_nonpositive(xx)) 1] == []) :
    false;


// Function: all_nonnegative()
// Usage:
//   all_nonnegative(x);
// Description:
//   Returns true if the finite number passed to it is greater than or equal to zero.
//   If passed a list, recursively checks if all items in the list are nonnegative.
//   Otherwise, returns false.
// Arguments:
//   x = The value to check.
// Example:
//   all_nonnegative(-2);  // Returns: false.
//   all_nonnegative(0);  // Returns: true.
//   all_nonnegative(2);  // Returns: true.
//   all_nonnegative([0,0,0]);  // Returns: true.
//   all_nonnegative([0,1,2]);  // Returns: true.
//   all_nonnegative([0,-1,-2]);  // Returns: false.
//   all_nonnegative([3,1,2]);  // Returns: true.
//   all_nonnegative([3,-1,2]);  // Returns: false.
//   all_nonnegative([-3,-1,-2]);  // Returns: false.
function all_nonnegative(x) =
    is_num(x)? x>=0 :
    is_list(x)? (x != [] && [for (xx=x) if(!all_nonnegative(xx)) 1] == []) :
    false;


// Function: approx()
// Usage:
//   b = approx(a,b,<eps>)
// Description:
//   Compares two numbers or vectors, and returns true if they are closer than `eps` to each other.
// Arguments:
//   a = First value.
//   b = Second value.
//   eps = The maximum allowed difference between `a` and `b` that will return true.
// Example:
//   approx(-0.3333333333,-1/3);  // Returns: true
//   approx(0.3333333333,1/3);    // Returns: true
//   approx(0.3333,1/3);          // Returns: false
//   approx(0.3333,1/3,eps=1e-3);  // Returns: true
//   approx(PI,3.1415926536);     // Returns: true
function approx(a,b,eps=EPSILON) = 
    (a==b && is_bool(a) == is_bool(b)) ||
    (is_num(a) && is_num(b) && abs(a-b) <= eps) ||
    (is_list(a) && is_list(b) && len(a) == len(b) && [] == [for (i=idx(a)) if (!approx(a[i],b[i],eps=eps)) 1]);


function _type_num(x) =
    is_undef(x)?  0 :
    is_bool(x)?   1 :
    is_num(x)?    2 :
    is_nan(x)?    3 :
    is_string(x)? 4 :
    is_list(x)?   5 : 6;


// Function: compare_vals()
// Usage:
//   b = compare_vals(a, b);
// Description:
//   Compares two values.  Lists are compared recursively.
//   Returns <0 if a<b.  Returns >0 if a>b.  Returns 0 if a==b.
//   If types are not the same, then undef < bool < nan < num < str < list < range.
// Arguments:
//   a = First value to compare.
//   b = Second value to compare.
function compare_vals(a, b) =
    (a==b)? 0 :
    let(t1=_type_num(a), t2=_type_num(b)) (t1!=t2)? (t1-t2) :
    is_list(a)? compare_lists(a,b) :
    is_nan(a)? 0 :
    (a<b)? -1 : (a>b)? 1 : 0;


// Function: compare_lists()
// Usage:
//   b = compare_lists(a, b)
// Description:
//   Compare contents of two lists using `compare_vals()`.
//   Returns <0 if `a`<`b`.
//   Returns 0 if `a`==`b`.
//   Returns >0 if `a`>`b`.
// Arguments:
//   a = First list to compare.
//   b = Second list to compare.
function compare_lists(a, b) =
    a==b? 0 
    :   let(
          cmps = [ for(i=[0:1:min(len(a),len(b))-1]) 
                      let( cmp = compare_vals(a[i],b[i]) )
                      if(cmp!=0) cmp 
                 ]
           ) 
        cmps==[]? (len(a)-len(b)) : cmps[0];


// Function: any()
// Usage:
//   b = any(l);
// Description:
//   Returns true if any item in list `l` evaluates as true.
//   If `l` is a lists of lists, `any()` is applied recursively to each sublist.
// Arguments:
//   l = The list to test for true items.
// Example:
//   any([0,false,undef]);  // Returns false.
//   any([1,false,undef]);  // Returns true.
//   any([1,5,true]);       // Returns true.
//   any([[0,0], [0,0]]);   // Returns false.
//   any([[0,0], [1,0]]);   // Returns true.
function any(l) =
    assert(is_list(l), "The input is not a list." )
    _any(l);

function _any(l, i=0, succ=false) =
    (i>=len(l) || succ)? succ :
    _any(
        l, i+1, 
        succ = is_list(l[i]) ? _any(l[i]) : !(!l[i])
    );


// Function: all()
// Usage:
//   b = all(l);
// Description:
//   Returns true if all items in list `l` evaluate as true.
//   If `l` is a lists of lists, `all()` is applied recursively to each sublist.
// Arguments:
//   l = The list to test for true items.
// Example:
//   all([0,false,undef]);  // Returns false.
//   all([1,false,undef]);  // Returns false.
//   all([1,5,true]);       // Returns true.
//   all([[0,0], [0,0]]);   // Returns false.
//   all([[0,0], [1,0]]);   // Returns false.
//   all([[1,1], [1,1]]);   // Returns true.
function all(l) =
    assert( is_list(l), "The input is not a list." )
    _all(l);

function _all(l, i=0, fail=false) =
    (i>=len(l) || fail)? !fail :
    _all(
        l, i+1,
        fail = is_list(l[i]) ? !_all(l[i]) : !l[i]
    ) ;


// Function: count_true()
// Usage:
//   n = count_true(l)
// Description:
//   Returns the number of items in `l` that evaluate as true.
//   If `l` is a lists of lists, this is applied recursively to each
//   sublist.  Returns the total count of items that evaluate as true
//   in all recursive sublists.
// Arguments:
//   l = The list to test for true items.
//   nmax = If given, stop counting if `nmax` items evaluate as true.
// Example:
//   count_true([0,false,undef]);  // Returns 0.
//   count_true([1,false,undef]);  // Returns 1.
//   count_true([1,5,false]);      // Returns 2.
//   count_true([1,5,true]);       // Returns 3.
//   count_true([[0,0], [0,0]]);   // Returns 0.
//   count_true([[0,0], [1,0]]);   // Returns 1.
//   count_true([[1,1], [1,1]]);   // Returns 4.
//   count_true([[1,1], [1,1]], nmax=3);  // Returns 3.
function _count_true_rec(l, nmax, _cnt=0, _i=0) =
    _i>=len(l) || (is_num(nmax) && _cnt>=nmax)? _cnt :
    _count_true_rec(l, nmax, _cnt=_cnt+(l[_i]?1:0), _i=_i+1);

function count_true(l, nmax) = 
    is_undef(nmax)? len([for (x=l) if(x) 1]) :
    !is_list(l) ? ( l? 1: 0) :
    _count_true_rec(l, nmax);



// Section: Calculus

// Function: deriv()
// Usage:
//   x = deriv(data, [h], [closed])
// Description:
//   Computes a numerical derivative estimate of the data, which may be scalar or vector valued.
//   The `h` parameter gives the step size of your sampling so the derivative can be scaled correctly. 
//   If the `closed` parameter is true the data is assumed to be defined on a loop with data[0] adjacent to
//   data[len(data)-1].  This function uses a symetric derivative approximation
//   for internal points, f'(t) = (f(t+h)-f(t-h))/2h.  For the endpoints (when closed=false) the algorithm
//   uses a two point method if sufficient points are available: f'(t) = (3*(f(t+h)-f(t)) - (f(t+2*h)-f(t+h)))/2h.
//   .
//   If `h` is a vector then it is assumed to be nonuniform, with h[i] giving the sampling distance
//   between data[i+1] and data[i], and the data values will be linearly resampled at each corner
//   to produce a uniform spacing for the derivative estimate.  At the endpoints a single point method
//   is used: f'(t) = (f(t+h)-f(t))/h.  
// Arguments:
//   data = the list of the elements to compute the derivative of.
//   h = the parametric sampling of the data.
//   closed = boolean to indicate if the data set should be wrapped around from the end to the start.
function deriv(data, h=1, closed=false) =
    assert( is_consistent(data) , "Input list is not consistent or not numerical.") 
    assert( len(data)>=2, "Input `data` should have at least 2 elements.") 
    assert( is_finite(h) || is_vector(h), "The sampling `h` must be a number or a list of numbers." )
    assert( is_num(h) || len(h) == len(data)-(closed?0:1),
            str("Vector valued `h` must have length ",len(data)-(closed?0:1)))
    is_vector(h) ? _deriv_nonuniform(data, h, closed=closed) :
    let( L = len(data) )
    closed
    ? [
        for(i=[0:1:L-1])
        (data[(i+1)%L]-data[(L+i-1)%L])/2/h
      ]
    : let(
        first = L<3 ? data[1]-data[0] : 
                3*(data[1]-data[0]) - (data[2]-data[1]),
        last = L<3 ? data[L-1]-data[L-2]:
               (data[L-3]-data[L-2])-3*(data[L-2]-data[L-1])
         ) 
      [
        first/2/h,
        for(i=[1:1:L-2]) (data[i+1]-data[i-1])/2/h,
        last/2/h
      ];


function _dnu_calc(f1,fc,f2,h1,h2) =
    let(
        f1 = h2<h1 ? lerp(fc,f1,h2/h1) : f1 , 
        f2 = h1<h2 ? lerp(fc,f2,h1/h2) : f2
       )
    (f2-f1) / 2 / min(h1,h2);


function _deriv_nonuniform(data, h, closed) =
    let( L = len(data) )
    closed
    ? [for(i=[0:1:L-1])
          _dnu_calc(data[(L+i-1)%L], data[i], data[(i+1)%L], select(h,i-1), h[i]) ]
    : [
        (data[1]-data[0])/h[0],
        for(i=[1:1:L-2]) _dnu_calc(data[i-1],data[i],data[i+1], h[i-1],h[i]),
        (data[L-1]-data[L-2])/h[L-2]                            
      ];


// Function: deriv2()
// Usage:
//   x = deriv2(data, <h>, <closed>)
// Description:
//   Computes a numerical estimate of the second derivative of the data, which may be scalar or vector valued.
//   The `h` parameter gives the step size of your sampling so the derivative can be scaled correctly. 
//   If the `closed` parameter is true the data is assumed to be defined on a loop with data[0] adjacent to
//   data[len(data)-1].  For internal points this function uses the approximation 
//   f''(t) = (f(t-h)-2*f(t)+f(t+h))/h^2.  For the endpoints (when closed=false),
//   when sufficient points are available, the method is either the four point expression
//   f''(t) = (2*f(t) - 5*f(t+h) + 4*f(t+2*h) - f(t+3*h))/h^2 or 
//   f''(t) = (35*f(t) - 104*f(t+h) + 114*f(t+2*h) - 56*f(t+3*h) + 11*f(t+4*h)) / 12h^2
//   if five points are available.
// Arguments:
//   data = the list of the elements to compute the derivative of.
//   h = the constant parametric sampling of the data.
//   closed = boolean to indicate if the data set should be wrapped around from the end to the start.
function deriv2(data, h=1, closed=false) =
    assert( is_consistent(data) , "Input list is not consistent or not numerical.") 
    assert( is_finite(h), "The sampling `h` must be a number." )
    let( L = len(data) )
    assert( L>=3, "Input list has less than 3 elements.") 
    closed
    ? [
        for(i=[0:1:L-1])
        (data[(i+1)%L]-2*data[i]+data[(L+i-1)%L])/h/h
      ]
    :
    let(
        first = 
            L==3? data[0] - 2*data[1] + data[2] :
            L==4? 2*data[0] - 5*data[1] + 4*data[2] - data[3] :
            (35*data[0] - 104*data[1] + 114*data[2] - 56*data[3] + 11*data[4])/12, 
        last = 
            L==3? data[L-1] - 2*data[L-2] + data[L-3] :
            L==4? -2*data[L-1] + 5*data[L-2] - 4*data[L-3] + data[L-4] :
            (35*data[L-1] - 104*data[L-2] + 114*data[L-3] - 56*data[L-4] + 11*data[L-5])/12
    ) [
        first/h/h,
        for(i=[1:1:L-2]) (data[i+1]-2*data[i]+data[i-1])/h/h,
        last/h/h
    ];


// Function: deriv3()
// Usage:
//   x = deriv3(data, <h>, <closed>)
// Description:
//   Computes a numerical third derivative estimate of the data, which may be scalar or vector valued.
//   The `h` parameter gives the step size of your sampling so the derivative can be scaled correctly. 
//   If the `closed` parameter is true the data is assumed to be defined on a loop with data[0] adjacent to
//   data[len(data)-1].  This function uses a five point derivative estimate, so the input data must include 
//   at least five points:
//   f'''(t) = (-f(t-2*h)+2*f(t-h)-2*f(t+h)+f(t+2*h)) / 2h^3.  At the first and second points from the end
//   the estimates are f'''(t) = (-5*f(t)+18*f(t+h)-24*f(t+2*h)+14*f(t+3*h)-3*f(t+4*h)) / 2h^3 and
//   f'''(t) = (-3*f(t-h)+10*f(t)-12*f(t+h)+6*f(t+2*h)-f(t+3*h)) / 2h^3.
// Arguments:
//   data = the list of the elements to compute the derivative of.
//   h = the constant parametric sampling of the data.
//   closed = boolean to indicate if the data set should be wrapped around from the end to the start.
function deriv3(data, h=1, closed=false) =
    assert( is_consistent(data) , "Input list is not consistent or not numerical.") 
    assert( len(data)>=5, "Input list has less than 5 elements.") 
    assert( is_finite(h), "The sampling `h` must be a number." )
    let(
        L = len(data),
        h3 = h*h*h
    )
    closed? [
        for(i=[0:1:L-1])
        (-data[(L+i-2)%L]+2*data[(L+i-1)%L]-2*data[(i+1)%L]+data[(i+2)%L])/2/h3
    ] :
    let(
        first=(-5*data[0]+18*data[1]-24*data[2]+14*data[3]-3*data[4])/2,
        second=(-3*data[0]+10*data[1]-12*data[2]+6*data[3]-data[4])/2,
        last=(5*data[L-1]-18*data[L-2]+24*data[L-3]-14*data[L-4]+3*data[L-5])/2,
        prelast=(3*data[L-1]-10*data[L-2]+12*data[L-3]-6*data[L-4]+data[L-5])/2
    ) [
        first/h3,
        second/h3,
        for(i=[2:1:L-3]) (-data[i-2]+2*data[i-1]-2*data[i+1]+data[i+2])/2/h3,
        prelast/h3,
        last/h3
    ];


// Section: Complex Numbers

// Function: C_times()
// Usage:
//   c = C_times(z1,z2)
// Description:
//   Multiplies two complex numbers represented by 2D vectors.  
//   Returns a complex number as a 2D vector [REAL, IMAGINARY].
// Arguments:
//   z1 = First complex number, given as a 2D vector [REAL, IMAGINARY]
//   z2 = Second complex number, given as a 2D vector [REAL, IMAGINARY]
function C_times(z1,z2) = 
    assert( is_matrix([z1,z2],2,2), "Complex numbers should be represented by 2D vectors" )
    [ z1.x*z2.x - z1.y*z2.y, z1.x*z2.y + z1.y*z2.x ];

// Function: C_div()
// Usage:
//   x = C_div(z1,z2)
// Description:
//   Divides two complex numbers represented by 2D vectors.  
//   Returns a complex number as a 2D vector [REAL, IMAGINARY].
// Arguments:
//   z1 = First complex number, given as a 2D vector [REAL, IMAGINARY]
//   z2 = Second complex number, given as a 2D vector [REAL, IMAGINARY]
function C_div(z1,z2) = 
    assert( is_vector(z1,2) && is_vector(z2), "Complex numbers should be represented by 2D vectors." )
    assert( !approx(z2,0), "The divisor `z2` cannot be zero." ) 
    let(den = z2.x*z2.x + z2.y*z2.y)
    [(z1.x*z2.x + z1.y*z2.y)/den, (z1.y*z2.x - z1.x*z2.y)/den];

// For the sake of consistence with Q_mul and vmul, C_times should be called C_mul

// Section: Polynomials

// Function: quadratic_roots()
// Usage:
//    roots = quadratic_roots(a,b,c,<real>)
// Description:
//    Computes roots of the quadratic equation a*x^2+b*x+c==0, where the
//    coefficients are real numbers.  If real is true then returns only the
//    real roots.  Otherwise returns a pair of complex values.  This method
//    may be more reliable than the general root finder at distinguishing
//    real roots from complex roots.  
//    Algorithm from: https://people.csail.mit.edu/bkph/articles/Quadratics.pdf
function quadratic_roots(a,b,c,real=false) =
  real ? [for(root = quadratic_roots(a,b,c,real=false)) if (root.y==0) root.x]
  :
  is_undef(b) && is_undef(c) && is_vector(a,3) ? quadratic_roots(a[0],a[1],a[2]) :
  assert(is_num(a) && is_num(b) && is_num(c))
  assert(a!=0 || b!=0 || c!=0, "Quadratic must have a nonzero coefficient")
  a==0 && b==0 ? [] :     // No solutions
  a==0 ? [[-c/b,0]] : 
  let(
      descrim = b*b-4*a*c,
      sqrt_des = sqrt(abs(descrim))
  )
  descrim < 0 ?             // Complex case
     [[-b, sqrt_des],
      [-b, -sqrt_des]]/2/a :
  b<0 ?                     // b positive
     [[2*c/(-b+sqrt_des),0],
      [(-b+sqrt_des)/a/2,0]]
      :                     // b negative
     [[(-b-sqrt_des)/2/a, 0],
      [2*c/(-b-sqrt_des),0]];


// Function: polynomial() 
// Usage:
//   x = polynomial(p, z)
// Description:
//   Evaluates specified real polynomial, p, at the complex or real input value, z.
//   The polynomial is specified as p=[a_n, a_{n-1},...,a_1,a_0]
//   where a_n is the z^n coefficient.  Polynomial coefficients are real.
//   The result is a number if `z` is a number and a complex number otherwise.
function polynomial(p,z,k,total) =
    is_undef(k)
    ?   assert( is_vector(p) , "Input polynomial coefficients must be a vector." )
        assert( is_finite(z) || is_vector(z,2), "The value of `z` must be a real or a complex number." )
        polynomial( _poly_trim(p), z, 0, is_num(z) ? 0 : [0,0])
    : k==len(p) ? total
    : polynomial(p,z,k+1, is_num(z) ? total*z+p[k] : C_times(total,z)+[p[k],0]);

// Function: poly_mult()
// Usage:
//   x = polymult(p,q)
//   x = polymult([p1,p2,p3,...])
// Description:
//   Given a list of polynomials represented as real coefficient lists, with the highest degree coefficient first, 
//   computes the coefficient list of the product polynomial.  
function poly_mult(p,q) = 
    is_undef(q) ?
        len(p)==2 
        ? poly_mult(p[0],p[1]) 
        : poly_mult(p[0], poly_mult(select(p,1,-1)))
    :
    assert( is_vector(p) && is_vector(q),"Invalid arguments to poly_mult")
    p*p==0 || q*q==0
    ? [0]
    : _poly_trim(convolve(p,q));

    
// Function: poly_div()
// Usage:
//    [quotient,remainder] = poly_div(n,d)
// Description:
//    Computes division of the numerator polynomial by the denominator polynomial and returns
//    a list of two polynomials, [quotient, remainder].  If the division has no remainder then
//    the zero polynomial [] is returned for the remainder.  Similarly if the quotient is zero
//    the returned quotient will be [].  
function poly_div(n,d) =
    assert( is_vector(n) && is_vector(d) , "Invalid polynomials." )
    let( d = _poly_trim(d), 
         n = _poly_trim(n) )
    assert( d!=[0] , "Denominator cannot be a zero polynomial." )
    n==[0]
    ? [[0],[0]]
    : _poly_div(n,d,q=[]);

function _poly_div(n,d,q) =
    len(n)<len(d) ? [q,_poly_trim(n)] : 
    let(
      t = n[0] / d[0], 
      newq = concat(q,[t]),
      newn = [for(i=[1:1:len(n)-1]) i<len(d) ? n[i] - t*d[i] : n[i]]
    )  
    _poly_div(newn,d,newq);


// Internal Function: _poly_trim()
// Usage:
//    _poly_trim(p,[eps])
// Description:
//    Removes leading zero terms of a polynomial.  By default zeros must be exact,
//    or give epsilon for approximate zeros.  
function _poly_trim(p,eps=0) =
    let( nz = [for(i=[0:1:len(p)-1]) if ( !approx(p[i],0,eps)) i])
    len(nz)==0 ? [0] : select(p,nz[0],-1);


// Function: poly_add()
// Usage:
//    sum = poly_add(p,q)
// Description:
//    Computes the sum of two polynomials.  
function poly_add(p,q) = 
    assert( is_vector(p) && is_vector(q), "Invalid input polynomial(s)." )
    let(  plen = len(p),
          qlen = len(q),
          long = plen>qlen ? p : q,
          short = plen>qlen ? q : p
       )
     _poly_trim(long + concat(repeat(0,len(long)-len(short)),short));


// Function: poly_roots()
// Usage:
//   poly_roots(p,<tol>)
// Description:
//   Returns all complex roots of the specified real polynomial p.
//   The polynomial is specified as p=[a_n, a_{n-1},...,a_1,a_0]
//   where a_n is the z^n coefficient.  The tol parameter gives
//   the stopping tolerance for the iteration.  The polynomial
//   must have at least one non-zero coefficient.  Convergence is poor
//   if the polynomial has any repeated roots other than zero.  
// Arguments:
//   p = polynomial coefficients with higest power coefficient first
//   tol = tolerance for iteration.  Default: 1e-14

// Uses the Aberth method https://en.wikipedia.org/wiki/Aberth_method
//
// Dario Bini. "Numerical computation of polynomial zeros by means of Aberth's Method", Numerical Algorithms, Feb 1996.
// https://www.researchgate.net/publication/225654837_Numerical_computation_of_polynomial_zeros_by_means_of_Aberth's_method
function poly_roots(p,tol=1e-14,error_bound=false) =
    assert( is_vector(p), "Invalid polynomial." )
    let( p = _poly_trim(p,eps=0) )
    assert( p!=[0], "Input polynomial cannot be zero." )
    p[len(p)-1] == 0 ?                                       // Strip trailing zero coefficients
        let( solutions = poly_roots(select(p,0,-2),tol=tol, error_bound=error_bound))
        (error_bound ? [ [[0,0], each solutions[0]], [0, each solutions[1]]]
                    : [[0,0], each solutions]) :
    len(p)==1 ? (error_bound ? [[],[]] : []) :               // Nonzero constant case has no solutions
    len(p)==2 ? let( solution = [[-p[1]/p[0],0]])            // Linear case needs special handling
                (error_bound ? [solution,[0]] : solution)
    : 
    let(
        n = len(p)-1,   // polynomial degree
        pderiv = [for(i=[0:n-1]) p[i]*(n-i)],
           
        s = [for(i=[0:1:n]) abs(p[i])*(4*(n-i)+1)],  // Error bound polynomial from Bini

        // Using method from: http://www.kurims.kyoto-u.ac.jp/~kyodo/kokyuroku/contents/pdf/0915-24.pdf
        beta = -p[1]/p[0]/n,
        r = 1+pow(abs(polynomial(p,beta)/p[0]),1/n),
        init = [for(i=[0:1:n-1])                // Initial guess for roots       
                 let(angle = 360*i/n+270/n/PI)
                 [beta,0]+r*[cos(angle),sin(angle)]
               ],
        roots = _poly_roots(p,pderiv,s,init,tol=tol),
        error = error_bound ? [for(xi=roots) n * (norm(polynomial(p,xi))+tol*polynomial(s,norm(xi))) /
                                  abs(norm(polynomial(pderiv,xi))-tol*polynomial(s,norm(xi)))] : 0
      )
      error_bound ? [roots, error] : roots;

// Internal function
// p = polynomial
// pderiv = derivative polynomial of p
// z = current guess for the roots
// tol = root tolerance
// i=iteration counter
function _poly_roots(p, pderiv, s, z, tol, i=0) =
    assert(i<45, str("Polyroot exceeded iteration limit.  Current solution:", z))
    let(
        n = len(z),
        svals = [for(zk=z) tol*polynomial(s,norm(zk))],
        p_of_z = [for(zk=z) polynomial(p,zk)],
        done = [for(k=[0:n-1]) norm(p_of_z[k])<=svals[k]],
        newton = [for(k=[0:n-1]) C_div(p_of_z[k], polynomial(pderiv,z[k]))],
        zdiff = [for(k=[0:n-1]) sum([for(j=[0:n-1]) if (j!=k) C_div([1,0], z[k]-z[j])])],
        w = [for(k=[0:n-1]) done[k] ? [0,0] : C_div( newton[k],
                                                     [1,0] - C_times(newton[k], zdiff[k]))]
    )
    all(done) ? z : _poly_roots(p,pderiv,s,z-w,tol,i+1);


// Function: real_roots()
// Usage:
//   real_roots(p, <eps>, <tol>)
// Description:
//   Returns the real roots of the specified real polynomial p.
//   The polynomial is specified as p=[a_n, a_{n-1},...,a_1,a_0]
//   where a_n is the x^n coefficient.  This function works by
//   computing the complex roots and returning those roots where
//   the imaginary part is closed to zero.  By default it uses a computed
//   error bound from the polynomial solver to decide whether imaginary
//   parts are zero.  You can specify eps, in which case the test is
//   z.y/(1+norm(z)) < eps.  Because
//   of poor convergence and higher error for repeated roots, such roots may
//   be missed by the algorithm because their imaginary part is large.  
// Arguments:
//   p = polynomial to solve as coefficient list, highest power term first
//   eps = used to determine whether imaginary parts of roots are zero
//   tol = tolerance for the complex polynomial root finder

function real_roots(p,eps=undef,tol=1e-14) =
    assert( is_vector(p), "Invalid polynomial." )
    let( p = _poly_trim(p,eps=0) )
    assert( p!=[0], "Input polynomial cannot be zero." )
    let( 
       roots_err = poly_roots(p,error_bound=true),
       roots = roots_err[0],
       err = roots_err[1]
    )
    is_def(eps) 
    ? [for(z=roots) if (abs(z.y)/(1+norm(z))<eps) z.x]
    : [for(i=idx(roots)) if (abs(roots[i].y)<=err[i]) roots[i].x];

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
