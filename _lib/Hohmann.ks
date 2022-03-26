// >> General Orbital 
    function VecToNodeConverter {   // Converting a local Vector to a Maneuver Node
        parameter deltaVec, mnv_time, inUTS is true.

        if not inUTS
            set mnv_time to mnv_time + time:seconds.
        
        local norm_vec to vcrs(ship:body:position, ship:velocity:orbit):normalized. // e.g angularMomentum_Vec
        local prog_vec to velocityAt(ship, mnv_time):orbit:normalized.
        local radi_vec to VCRS(norm_vec, prog_vec).
        
        local norm_comp to VDOT(norm_vec, deltaVec).
        local prog_comp to VDOT(prog_vec, deltaVec).
        local radi_comp to VDOT(radi_vec, deltaVec).
        
        local mynode to NODE(mnv_time, radi_comp, norm_comp, prog_comp).
        return mynode.
    }
    function PlaneChange {          // Returning the target Vel Vector of a new inclined orbit 
        parameter des_inc, mnv_time, inUTS is true.

        if not inUTS
            set mnv_time to mnv_time + time:seconds.
        
        local vel_vec to velocityat(ship, mnv_time):orbit.
        local pos_vec to positionat(ship, mnv_time).
        local body_vec to pos_vec - ship:body:position.
        
        local angle_rotate_inc to ANGLEAXIS(des_inc, -body_vec).
        local new_vel_vec to vel_vec*angle_rotate_inc.
        
        return new_vel_vec.
    }  
    
    // >> Display
    function OrbitDirections {  // returning a list (Positon) Vectors: [0]=eccentricity-vector; [1]=Ascendning Node-vector
        parameter 
            pos is positionAt(ship, time:seconds)-body:position, 
            vel is velocityAt(ship, time:Seconds):orbit, 
            mu  is body:mu.

        local Pmomentum is vel.
        local Lmomentum is VCRS(Pmomentum, pos).

        local Dir_Periapsis is VCRS(Lmomentum, Pmomentum) - mu * (pos:normalized).        

        return list(Dir_Periapsis:normalized, ANVector()).
    }
    function ANVector {         // returning the Position vector of the orbits Ascendiong Node
        parameter 
            pos2 is V(1,0,0),
            vel2 is V(0,0,1),
            pos1 is positionAt(ship, time:seconds)-body:position,
            vel1 is velocityAt(ship, time:Seconds):orbit,
            mu   is body:mu
        .
        local h1 is VCRS(pos1, vel1).
        local h2 is VCRS(pos2, vel2).
        return h1:mag^2/mu * VCRS( h1 , h2 ):normalized.
    }
    
    // True-, Mean Anomaly Timing
    function orbitPeriodBy_SMA {
        parameter a, mu is body:mu.
        return 2*constant:pi/sqrt(mu) * a^(3/2).
    }
    function orbitPeriodBy_h_ecc {
        parameter h, ecc, mu is body:mu.
        return 2*constant:pi/(mu^2) * ( h/sqrt(1-ecc^2) )^3.
    }
    function MeanAnomalyAtTrueAnomaly { // Convert True Anomaly to Mean Anomaly
        parameter theta, ecc is ship:orbit:eccentricity.

        local E is 2*arcTan( sqrt( (1-ecc)/(1+ecc) ) * tan(theta/2) ) * constant:degtorad.
        return E - ecc*sin(E*constant:radtodeg).
    }
    function MeanAnomalyToTime {        // Convert Mean Anomaly to relative time (to Periapsis)
        parameter Me, T is ship:orbit:Period.
        return Me * T / (2*constant:pi).
    }
    function TrueAnomalyToTime {        // Convert True Anomaly to relative time (to Periapsis)
        parameter theta, ecc is ship:orbit:eccentricity, T is ship:orbit:Period.
        return MeanAnomalyToTime( MeanAnomalyAtTrueAnomaly(theta, ecc), T ).
    }
    function timeToEpochrelativ {       // Convert the relative Time (to Periapsis) to Universal Time (UT)
        parameter t, theta is ship:orbit:trueanomaly, ecc is ship:orbit:eccentricity, TPeriod is ship:orbit:Period.
        return t - TrueAnomalyToTime( theta, ecc, TPeriod ) + time:seconds.
    }
    
    // >> Inclination Matching
    function relativeInclination {  // Get the relative Inclination of two pos' and vels
        parameter 
            pos2 is V(1,0,0),
            vel2 is V(0,0,1),
            pos1 is positionAt(ship, time:seconds)-body:position,
            vel1 is velocityAt(ship, time:Seconds):orbit
        .
        local h_Angle1 is 90 - VANG(VCRS(pos1, vel1), -up:vector).
        local h_Angle2 is 90 - VANG(VCRS(pos2, vel2), -up:vector). 
        return h_Angle2 - h_Angle1.
    }
    function zeroPlane {            // Get list of Maneuver Nodes wich level ship:orbit to an other orbit
        parameter 
            pos2 is positionAt(target, time:seconds)-body:position,
            vel2 is velocityAt(target, time:seconds):orbit
        .
        
        local AN  is ANVector(pos2, vel2).     // relative Ascending Node
        local AoP is OrbitDirections()[0].    // Periapsis-Direction-Vector (Apsline)
        local di  is relativeInclination(pos2, vel2).

        local AoPVel is velocityAt(ship, timeToEpochrelativ( 0 )):orbit.

        local realAngle1 is VANG(AoP,  AN).
        local realAngle2 is VANG(AoP, -AN).

        set realAngle1 to choose 360-realAngle1 if VANG(AoPVel,  AN) > 90 else realAngle1.
        set realAngle2 to choose 360-realAngle2 if VANG(AoPVel, -AN) > 90 else realAngle2.

        local t1 is timeToEpochrelativ( TrueAnomalyToTime(realAngle1) ).
        local t2 is timeToEpochrelativ( TrueAnomalyToTime(realAngle2) ).

        local deltaVec1 is PlaneChange(di, t1, true).
        local deltaVec2 is PlaneChange(di, t2, true).

        set nod1 to VecToNodeConverter(deltaVec1 - velocityAt(ship, t1):orbit, t1, true).
        set nod2 to VecToNodeConverter(deltaVec2 - velocityAt(ship, t2):orbit, t2, true).

        return choose list( nod1, nod2 ) if t1 < t2 else list( nod2, nod1 ).
    }

    // >> Aps Line Rotation
    function Convert_ForApsRotation {
        parameter obj1, obj2, Obj1_For_Obj2 is false.

        set obj1 to obj1:orbit.
        set obj2 to obj2:orbit.

        return lex(
            "n" , obj2:argumentofperiapsis - obj1:argumentofperiapsis,

            "e1", obj1:eccentricity,
            "h1", sqrt((body:radius + obj1:apoapsis)*body:mu*( 1-obj1:eccentricity )),

            "e2",   choose obj1:eccentricity 
                    if Obj1_For_Obj2 
                    else obj2:eccentricity,

            "h2",   choose sqrt((body:radius + obj1:apoapsis)*body:mu*( 1-obj1:eccentricity ))
                    if Obj1_For_Obj2
                    else sqrt((body:radius + obj2:apoapsis)*body:mu*( 1-obj2:eccentricity ))
        ).
    }
    function orbitIntersection {
        parameter dict. // dict in Convert_OrbitablesToElements format

        local a is  dict:e1*dict:h2^2 - dict:e2*dict:h1^2*cos(dict:n).
        local b is -dict:e2*dict:h1^2*sin(dict:n).
        local c is  dict:h1^2 - dict:h2^2.
        local theta is arcTan( b/a ).

        return list( theta + arcCos( c/a * cos(theta) ), mod( theta - arcCos( c/a * cos(theta) ) + 360, 360) ).
    }
    function IntersectionManeuver {
        parameter trueAno, dict. // dict in Convert_OrbitablesToElements format

        local t is timeToEpochrelativ( TrueAnomalyToTime(trueAno) ).
        set t to choose t + ship:orbit:period if t-time:seconds < 0 else t.

        local Vr is { parameter theta, e, h. return (body:mu/h) * e * sin(theta). }.

        local r is (dict:h1^2/body:mu)*( 1 / ( 1+dict:e1*cos(trueAno) ) ).

        local radial1 is Vr( trueAno, dict:e1, dict:h1 ).
        local radial2 is Vr( trueAno - dict:n, dict:e2, dict:h2 ).

        return node(t, radial2-radial1, 0, (dict:h2-dict:h1)/r).
    }


    function close_aproach_scan { // one method to try to find closest approach by checking points of finer and finer resolution (HillClimber)
        parameter 
            object1, 
            object2,                                    // the orbitals to examine for close approach
            startTime is time:seconds,                  // the start time (UTs) for the scan
            scanTimeRange is 2*object1:orbit:period,    // the max seconds after the startTime to check to 
            scanSteps is 36,                            // the of points of comparison for each level of resolution
            minTime is 1,                               // the smallest time increment that will be checked
            debug is false
        .

        local bestAproach is distance_at(object1, object2, startTime). 
        local bestAproachTime is startTime.

        local ptr_0 is 0.
        local ptr_1 is 0.
        if debug {
            set ptr_0 to vecDraw(body:position, positionAt(object1, bestAproachTime) , RGB(0,1,0), "BEST", 1, true, 0.2).
            set ptr_1 to vecDraw(body:position, positionAt(object1, bestAproachTime) , RGB(1,0,0), "NOW", 1, true, 0.2).
        }

        until scanTimeRange < minTime {
            local stepTime is scanTimeRange / scanSteps.
            local maxTime is startTime + scanTimeRange.
            set startTime to startTime + stepTime / 2.

            from { local i is startTime + stepTime. } until i >= maxTime step { set i to i + stepTime. } do {
                local tmpAproach is distance_at(object1, object2, i).

                if tmpAproach < bestAproach {
                    set bestAproach to tmpAproach.
                    set bestAproachTime to i.
                }

                if debug {
                    set ptr_0:vector to positionAt(object1, i).
                    set ptr_1:vector to positionAt(object1, i).
                }
            }

            set startTime to (bestAproachTime - (stepTime / 2)).
            set scanTimeRange to stepTime.
        }
        return lex("dist", bestAproach, "UTS", bestAproachTime).
    }
    local function distance_at {
        parameter object1, object2, t.
        return (positionAt(object1, t) - positionAt(object2, t)):MAG.
    }

// >> Hohmann
    function DeltaVcirc {
        parameter radius, sma is orbit:semimajoraxis.
        set radius to radius + body:radius.
        return sqrt(body:mu)*(sqrt(1/radius) - sqrt(2/radius - 1/sma)).
    }
    function hohmann_dv1 {
        parameter r1.
        parameter r2.

        set r1 to r1 + body:radius.
        set r2 to r2 + body:radius.

        return SQRT(Body:mu/r1)*(SQRT(2*r2/((r1+r2))-1)).
    }
    function hohmann_dv2 {
        parameter r1.
        parameter r2.

        set r1 to r1 + body:radius.
        set r2 to r2 + body:radius.

        return SQRT(Body:mu/r2)*(1-SQRT((2*r1/(r1+r2)))).
    }
    function hohmann_v1 {
        parameter r1.
        parameter r2.

        set r1 to r1 + body:radius.
        set r2 to r2 + body:radius.

        return SQRT(body:mu*(2/r1 - 2/(r1+r2))).
    }
    function hohmann_v2 {
        parameter r1.
        parameter r2.

        set r1 to r1 + body:radius.
        set r2 to r2 + body:radius.

        return SQRT(body:mu*(2/r2 - 2/(r1+r2))).
    }
    function hohmann_alignment {
        parameter r1.
        parameter r2.

        set r1 to r1 + body:radius.
        set r2 to r2 + body:radius.

        return constant:pi*(1 - sqrt(.25) * (r1/r2 + 1)^(3/2)).
    } 
    function hohmann_timing {
        parameter phasingStart, a1, a2.

        // Mean velocities
        local n1 is sqrt(Body:mu / a1^3).
        local n2 is sqrt(Body:mu / a2^3). 

        local timeH is hohmann_time(a1, a2).
        local phaseFinal is constant:pi - n2*timeH.
        
        set phasingStart to choose 2*constant:pi + phasingStart if phasingStart < 0 else phasingStart.
        local phasingDelta is phaseFinal - phasingStart.
        local timeWait is abs(phasingDelta/(n2-n1)).

        print "phaseFinal:   " + (constant:radtodeg*phaseFinal)     at (5,3).
        print "phasingDelta: " + (constant:radtodeg*phasingDelta)   at (5,4).
        print "timeWait:     " + timeWait               at (5,5).
        print "n1:     " + (constant:radtodeg*n1)       at (5,6).
        print "n2:     " + (constant:radtodeg*n2)       at (5,7).
        print "dn:     " + (constant:radtodeg*(n2-n1))  at (5,8).

        return timeWait.
    }
    function hohmann_time {
        parameter a1, a2.
        return constant:pi * sqrt( (a1+a2)^3 / (8*body:mu)).
    }