Let's say you have these equations:
a = -x
d/dt v = a
d/dt x = v

x and v are state variables and their initial values are a free choice.
Let's say x = 1 and v = 0 are the chosen starting state.

According to Wolfram Alpha, the solution to these equations and these initial values is:
x(t) =  cos(t)
v(t) = -sin(t)
  which are a pair of sine waves 90 degrees out of phase with a period of 2 PI = 6.2831853
  
We want an algorithm to take a state of 2 numbers and simulate their future behavior
based on the example 3-equation system. If it works out we can generalize it to take other
equations as input.

Instead of delving into the math of differential equations, I will try to directly spell out
the algorithm and show the output. OK.

The input to the algorithm is 2 numbers, x and v. From here we can use the equations to get
values for a, dv/dt (from here on vdot), and dx/dt (from here on xdot).

With x, v, xdot and vdot we hope to do something to compute new x and v at some other point
in time. The formula x1 = x0 + xdot * dt is correct if xdot doesn't change over the span of dt time.

However in this system, after any span of time at all, xdot does change. So the linear formula
will only be an approximation. (By including more terms from the beginning of the taylor series for x,
we can get much more accurate approximations more efficiently. These extra terms use the square of dt,
the 3rd power of dt, etc, and higher order derivatives. For a reason that will become apparent later,
I will not use a more accurate formula.)

If x changes ever so slightly, the other state variables "immediately react", changing the way x changes.
Because of this, perhaps Zeno would say this system can never get anywhere at all. The computer can't
hope to exactly simulate this step by step because no step is small enough.

The trick I will use is: only allow equations to "see" approximations of whatever state variables it
refers to. For instance, if x happens to be 1.234, the equation for a will use 1.2 instead. If x happens
to be 1.267, the equation for x will use 1.3 instead. In this case I chose the granularity, the smallest
difference between observable values, to be 0.1.

With that trick in place, the equations can't react instantaneously to changes in other variables (as long
as they are changing continuously in time. I plan to show how to introduce discontinuous changes in a
later test). Since they can't see slight changes in the value of variables, derivatives are effectively
constant for some time, and during that time variables change linearly, and the formula x1 = x0 + xdot*dt
is correct.

How long is it correct? The answer to that is exactly computable given our assumptions so far, and gives
us the guidance for what the simulation should even output. In fact this is the guts of the algorithm:

- Calculate xdot and vdot.
- Calculate the amount of time it will take x and v to reach a "cross over" point where their
  observable value would change. The formula for this is |crossOverPoint - x| / |xdot|.
- Take the minimum of these two times, call it dt.
- The next state of the simulation occurs dt time from now, with the values
  x1 = x + xdot * dt
  v1 = v + vdot * dt
- repeat the process to get the next dt and the state variables at that time, and so on.

So the type of the program that gives us our simulation is
run ::
  Number -> -- the granularity size
  Number -> -- the initial value of x
  Number -> -- the initial value of v
  [(Time, Number, Number)] -- a sequence of times and what the state variables are at that time

I implemented run in Haskell but I will not go into the details here. One thing to note is that
the computations use rational numbers instead of floating point. Specifically, the time-until-cross
calculation involves a division which in general will not give an exact answer with floats.
(Now you can see why this algorithm won't work if you use quadratic or higher terms of the
taylor series. The time until a parabolic arc reaches a point involves a square root, and our
rational numbers can't handle that.)

So what do we get when we run: run 1 1 0, which is granularity 1 and our initial problem x=1 v=0 ?
    t     x     v
  0.0   1.0   0.0
  0.5   1.0  -0.5   -- this state will be repeated later
  1.0   0.5  -1.0
  2.0  -0.5  -1.0
  2.5  -1.0  -0.5
  3.5  -1.0   0.5
  4.0  -0.5   1.0
  5.0   0.5   1.0
  5.5   1.0   0.5
  6.5   1.0  -0.5   -- returned to a previous state 6 time units later
  7.0   0.5  -1.0
  8.0  -0.5  -1.0
  8.5  -1.0  -0.5
  9.5  -1.0   0.5
 10.0  -0.5   1.0
 11.0   0.5   1.0
 11.5   1.0   0.5
 12.5   1.0  -0.5   -- repeated again
 13.0   0.5  -1.0
 14.0  -0.5  -1.0

Since the algorithm completely depends on the two state variables (and not t, this systems
equations are time-independent), and x, v repeats itself at time 6.5, the output is precisely
periodic! And the period here is 6. Hmm. That is kind of close to 2 PI. What if we use a
smaller granularity?

run 0.25 1 0
                   t                    x                    v
                 0.0                  1.0                  0.0
               0.125                  1.0               -0.125   -- this state will be repeated later
               0.375               0.9375               -0.375
                 0.5                0.875                 -0.5
  0.6666666666666666   0.7916666666666666               -0.625
  0.8888888888888888                0.625  -0.7916666666666666
  1.0555555555555556                  0.5               -0.875
  1.1805555555555556                0.375              -0.9375
  1.4305555555555556                0.125                 -1.0
  1.6805555555555556               -0.125                 -1.0
  1.9305555555555556               -0.375              -0.9375
  2.0555555555555554                 -0.5               -0.875
  2.2222222222222223               -0.625  -0.7916666666666666
  2.4444444444444446  -0.7916666666666666               -0.625
   2.611111111111111               -0.875                 -0.5
   2.736111111111111              -0.9375               -0.375
   2.986111111111111                 -1.0               -0.125
   3.236111111111111                 -1.0                0.125
   3.486111111111111              -0.9375                0.375
   3.611111111111111               -0.875                  0.5
  3.7777777777777777  -0.7916666666666666                0.625
                 4.0               -0.625   0.7916666666666666
   4.166666666666667                 -0.5                0.875
   4.291666666666667               -0.375               0.9375
   4.541666666666667               -0.125                  1.0
   4.791666666666667                0.125                  1.0
   5.041666666666667                0.375               0.9375
   5.166666666666667                  0.5                0.875
   5.333333333333333                0.625   0.7916666666666666
   5.555555555555555   0.7916666666666666                0.625
   5.722222222222222                0.875                  0.5
   5.847222222222222               0.9375                0.375
   6.097222222222222                  1.0                0.125
   6.347222222222222                  1.0               -0.125    -- returned to a previous state here
   6.597222222222222               0.9375               -0.375
   6.722222222222222                0.875                 -0.5
   6.888888888888889   0.7916666666666666               -0.625
   7.111111111111111                0.625  -0.7916666666666666
   7.277777777777778                  0.5               -0.875
   7.402777777777778                0.375              -0.9375
   7.652777777777778                0.125                 -1.0
   7.902777777777778               -0.125                 -1.0
   8.152777777777779               -0.375              -0.9375
   8.277777777777779                 -0.5               -0.875
   8.444444444444445               -0.625  -0.7916666666666666
   8.666666666666666  -0.7916666666666666               -0.625
   8.833333333333334               -0.875                 -0.5
   8.958333333333334              -0.9375               -0.375
   9.208333333333334                 -1.0               -0.125
   9.458333333333334                 -1.0                0.125
   
   
This simulation returned to a previously visited state after 6.347222222222222 - 0.125 = 6.222222
2 PI = 6.2831853, so it appears that the simulation gets closer to what we expect if you
reduce the granularity, which also increases the rate of time steps. That is awesome.
  
We're not done being awesome yet. The run algorithm goes forward in time, but with some signs
swapped around it could have gone back in time. The perfect Wolfram solution isn't a wave that
exists only for positive time. It goes indefinitely far into the past as well. Generally wave
equations produce waves travelling forward and backward in time. Why do we care?
  
Ah ha! All the information necessary to simulate this system is contained in only 2 numbers.
And we can choose whatever numbers we want to start with. What if you picked -1.0, 0.125,
the last numbers in the test above (before I canceled it), and put those in the time reversed
version of run?
  
Would you travel back in time, eventually returning to our initial x=1 v=0 starting state?
Would be cool! Any game built on such a system would get time reversed simulation for free.

(You may notice that the simulation only becomes periodic after a certain point. This is
because it only reports changes in the observable state, but we can choose any state to
start in, even if none of the variables are "on the edge" of changing value. This means `run'
can fail to return exactly to where you began. What are the criteria for the starting state
to ensure a time reversed simulation will land exactly there on its way into the past?)
