// >> Lander
    // recommended variable names (for bugless experience): needed to bes set in YOUR code (not the lib)
    //      [geoPos] targetlocation = where do we butter our baby
    //      [vector] relimpact      = targetlocation:position - impactPos:position // where impactPos is (trajectory's) impactPos of your lander
    
    //need to import vecToLocal for proper calculations
    function vecToLocal {
        parameter V.
        local eVect is VCRS(UP:VECTOR, NORTH:VECTOR).
        local eComp is vdot(V, eVect:normalized).
        local nComp is vdot(V, NORTH:VECTOR:normalized).
        local uComp is vdot(V, UP:VECTOR:normalized).
        RETURN V(eComp, nComp, uComp).
    }
    
    function landingPIDs {
        //Controls vertical speed
        SET hoverVelPID TO PIDLOOP(.1, 0.3, 0.005, 0, 1). 
        //Controls altitude by changing climbPID setpoint
        SET hoverAltPID TO PIDLOOP(.5, 0.01, 0.05, -50, 50). 

        //Controls horizontal speed by tilting rocket
        SET  eastVelPID TO PIDLOOP(3, .15, 0.00005, -25, 25).
        SET northVelPID TO PIDLOOP(3, .15, 0.00005, -25, 25). 
        //controls horizontal position by changing velPID setpoints
        SET  eastPosPID TO PIDLOOP(5000, 50, 400, -50, 50).
        SET northPosPID TO PIDLOOP(5000, 50, 400, -50, 50).
    }
    function landingSteer { // horizontal navigation on low velocity + GLIDE (cold steer)
        parameter geo is (choose targetlocation if defined targetlocation else ship:geoPosition), doSteer is true.
        
        SET  eastPosPID:SETPOINT TO geo:LNG.
        SET northPosPID:SETPOINT TO geo:LAT.

        set refrence to (choose addons:tr:impactPos if (addons:tr:available and addons:tr:hasimpact) else ship:geoposition).

        local shipVel is vecToLocal(ship:velocity:surface).

        set eastVelPID:setpoint to eastPosPID:UPDATE(TIME:SECONDS,  refrence:lng).
        set northVelPID:setpoint to northPosPID:UPDATE(TIME:SECONDS,refrence:lat).

        if throttle > 0 or not body:atm:exists {
            set steerMode to "1st law".
            set eastRotation  to (Up:vector * Angleaxis( eastVelPID:UPDATE(TIME:SECONDS, shipVel:x),  -north:vector)).
            set northRotation to (Up:vector * Angleaxis(northVelPID:UPDATE(TIME:SECONDS, shipVel:y),           east)).
        } else if verticalSpeed < 0 {
            set steerMode to "2nd law". //glide
            set eastRotation  to ( -ship:velocity:surface * Angleaxis( eastVelPID:UPDATE(TIME:SECONDS, shipVel:x),  north:vector)).
            set northRotation to ( -ship:velocity:surface * Angleaxis(northVelPID:UPDATE(TIME:SECONDS, shipVel:y),         -east)).
        } else {
            set steerMode to "3rd law".
            set eastRotation  to (  ship:velocity:surface * Angleaxis( eastVelPID:UPDATE(TIME:SECONDS, shipVel:x),  -north:vector)).
            set northRotation to (  ship:velocity:surface * Angleaxis(northVelPID:UPDATE(TIME:SECONDS, shipVel:y),          east)).
        }

        if doSteer { set steering to lookDirUp((eastRotation + northRotation), facing:topvector). } else { 
            return lexicon(
                "eRvec", eastRotation, 
                "nRvec", northRotation, 
                "steerMode", steerMode
            ).     
        }        
    }
    function landingHotSteer { // horizontal navigation on high velocity (hot steer)
        parameter geo is (choose targetlocation if defined targetlocation else ship:geoPosition), doSteer is true.
        
        SET  eastPosPID:SETPOINT TO geo:LNG.
        SET northPosPID:SETPOINT TO geo:LAT.

        set refrence to (choose addons:tr:impactPos if (addons:tr:available and addons:tr:hasimpact) else ship:geoposition).

        local shipVel is vecToLocal(ship:velocity:surface).

        set eastVelPID:setpoint to eastPosPID:UPDATE(TIME:SECONDS,  refrence:lng).
        set northVelPID:setpoint to northPosPID:UPDATE(TIME:SECONDS,refrence:lat).
        
        if verticalSpeed < 0 {
            set steerMode to "1st law". 
            set eastRotation  to ( -ship:velocity:surface * Angleaxis( eastVelPID:UPDATE(TIME:SECONDS, shipVel:x), -north:vector)).
            set northRotation to ( -ship:velocity:surface * Angleaxis(northVelPID:UPDATE(TIME:SECONDS, shipVel:y),          east)).
        } else {
            set steerMode to "2nd law".
            set eastRotation  to (  ship:velocity:surface * Angleaxis( eastVelPID:UPDATE(TIME:SECONDS, shipVel:x),  north:vector)).
            set northRotation to (  ship:velocity:surface * Angleaxis(northVelPID:UPDATE(TIME:SECONDS, shipVel:y),         -east)).
        }

        if doSteer { set steering to lookDirUp((eastRotation + northRotation), facing:topvector). } else { 
            return lexicon(
                "eRvec", eastRotation, 
                "nRvec", northRotation, 
                "steerMode", steerMode
            ).     
        }        
    }
    function landingVelSteer { // controlled by target Hor. Vel.
        parameter eVel is 0, nVel is 0.

        local shipVel is vecToLocal(ship:velocity:surface).

        set  eastVelPID:setpoint to eVel.
        set northVelPID:setpoint to nVel.

        if throttle > 0 or not body:atm:exists {
            set steerMode to "1st law".
            set eastRotation  to (Up:vector * Angleaxis( eastVelPID:UPDATE(TIME:SECONDS, shipVel:x), -north:vector)).
            set northRotation to (Up:vector * Angleaxis(northVelPID:UPDATE(TIME:SECONDS, shipVel:y),          east)).
        } else if verticalSpeed < 0 {
            set steerMode to "2nd law".
            set eastRotation  to ( -ship:velocity:surface * Angleaxis( eastVelPID:UPDATE(TIME:SECONDS, shipVel:x), north:vector)).
            set northRotation to ( -ship:velocity:surface * Angleaxis(northVelPID:UPDATE(TIME:SECONDS, shipVel:y),        -east)).
        } else {
            set steerMode to "3rd law".
            set eastRotation  to (  ship:velocity:surface * Angleaxis( eastVelPID:UPDATE(TIME:SECONDS, shipVel:x), -north:vector)).
            set northRotation to (  ship:velocity:surface * Angleaxis(northVelPID:UPDATE(TIME:SECONDS, shipVel:y),          east)).
        }

        set steering to lookDirUp((eastRotation + northRotation), facing:topvector).        
    }
    function landingGlide {
        parameter 
            tangle, 
            tpivot is 100, 
            source is 
                choose ( 
                    vectoLocal(targetlocation:position - addons:tr:impactPos:position) 
                ) if (
                    defined targetlocation and (addons:tr:available and addons:tr:hasimpact)
                ) else (
                    lex("x", eastPosPID:output, "y", northPosPID:output)
                )
        .
        local eAngle is tangle * min(max(source:x / tpivot, -1), 1).
        local nAngle is tangle * min(max(source:y / tpivot, -1), 1).

        set eastRotation  to ( -ship:velocity:surface * Angleaxis(eAngle, north:vector)).
        set northRotation to ( -ship:velocity:surface * Angleaxis(nAngle,        -east)).

        set steering to lookDirUp((eastRotation + northRotation), facing:topvector).
    }

    function landingAltThrottle { // controlles vertical displacement + 2ndlaw and 3rdlaw prevention on low radar
        parameter hoverAlt, source is (choose trueRadar() if (defined trueRadar()) else alt:radar).

        if source < 100 { set hoverVelPID:minoutput to .01. } else { set hoverVelPID:minoutput to 0. }

        set hoverAltPID:setpoint to hoverAlt.
        
        set hoverVelPID:setpoint to hoverAltPID:update(time:seconds, source).

        set throttle to hoverVelPID:update(time:seconds, verticalSpeed).
    }
    function landingVelThrottle { // controlles vertical displacement
        parameter targetVel is 0.
        
        set hoverVelPID:setpoint to targetVel.

        set throttle to hoverVelPID:update(time:seconds, verticalSpeed).
    }
    function landingAltController { // suggeseted height based on dist to target
        parameter dist, cruiseAlt is 10, alpha is 45, margin is .5, expo is 1.

        return min(cruiseAlt, abs(tan(alpha) * dist^expo) - tan(alpha) * margin^expo). // returns a height
    }
    
    function landingMaxSteerAngle { 
        parameter a.
        set  eastVelPID:MAXOUTPUT to  a.
        set  eastVelPID:MINOUTPUT to -a.
        set northVelPID:MAXOUTPUT to  a.
        set northVelPID:MINOUTPUT to -a.
    }
    function landingMaxVang { 
        parameter a, p is 100. // p is pivot based on dist
        local source is (
            choose ( 
                vectoLocal(targetlocation:position - addons:tr:impactPos:position) 
            ) if (
                defined targetlocation and (addons:tr:available and addons:tr:hasimpact)
            ) else (
                lex("x", eastPosPID:output, "y", northPosPID:output)
            )
        ).
        set  eastVelPID:MAXOUTPUT to  a * min( 1, ABS(source:x/p) ).
        set  eastVelPID:MINOUTPUT to -a * min( 1, ABS(source:x/p) ).
        set northVelPID:MAXOUTPUT to  a * min( 1, ABS(source:y/p) ).
        set northVelPID:MINOUTPUT to -a * min( 1, ABS(source:y/p) ).
    }
    function landingMaxHorSpeed{
        parameter a.

        set  eastPosPID:MAXOUTPUT to a.
        set  eastPosPID:MINOUTPUT to -a.
        set northPosPID:MAXOUTPUT to a.
        set northPosPID:MINOUTPUT to -a.
    }
    function landingMaxVerticalSpeed{
        parameter a.
        set hoverAltPID:MAXOUTPUT to a.
        set hoverAltPID:MINOUTPUT to -a.
    }
    function landingLoger { // needed for analyzing
        if not (defined logger) {
            set logger to 1.
        }
        set logger to logger + 1.

        //log (time:seconds - (choose startTime if defined startTime else (choose modeElapsedTimeStart if defined modeElapsedTimeStart else time:seconds))) + " " + eastPosPID:setpoint + " " + eastPosPID:input + " " + GeoDist(refrence, latlng(northPosPID:SETPOINT, eastPosPID:SETPOINT)):lng + " " + eastPosPID:output + " " + eastPosPID:pterm + " " + eastPosPID:iterm + " " + eastPosPID:dterm + " " + northPosPID:setpoint + " " + northPosPID:input + " " + GeoDist(refrence, latlng(northPosPID:SETPOINT, eastPosPID:SETPOINT)):lat + " " + northPosPID:output + " " + northPosPID:pterm + " " + northPosPID:iterm + " " + northPosPID:dterm to ght1.csv.
        
        //log (time:seconds - startTime) + " " + hoverAltPID:setpoint + " " + hoverAltPID:input + " " + hoverAltPID:error + " " + hoverAltPID:output + " " + hoverAltPID:pterm + " " + hoverAltPID:iterm + " " + hoverAltPID:dterm + " " + hoverVelPID:setpoint + " " + hoverVelPID:input + " " + hoverVelPID:error + " " + hoverVelPID:output + " " + hoverVelPID:pterm + " " + hoverVelPID:iterm + " " + hoverVelPID:dterm to ght2.csv.

        local lexo is lexicon(
            "eVinput",  eastVelPID:input, 
            "nVinput", northVelPID:input,  
            "eVoutput",  eastVelPID:output, 
            "nVoutput", northVelPID:output,
            "eVerror",  eastVelPID:error, 
            "nVerror", northVelPID:error, 
            "ePinput",  eastPosPID:input, 
            "nPinput", northPosPID:input, 
            "ePoutput",  eastPosPID:output, 
            "nPoutput", northPosPID:output, 
            "ePerror",  eastPosPID:error, 
            "nPerror", northPosPID:error, 
            "eMAng",  eastVelPID:MAXOUTPUT, 
            "nMAng", northVelPID:MAXOUTPUT, 
            "eMVel",  eastPosPID:MAXOUTPUT, 
            "nMVel", northPosPID:MAXOUTPUT,
            "logger Lines", logger
        ).
        
        local lexa is lexicon(
            "Asp", hoverAltPID:setpoint,
            "Vsp", hoverVelPID:setpoint,
            "Ao", hoverAltPID:output,
            "Vo", hoverVelPID:output,
            "Ai", hoverAltPID:input,
            "Vi", hoverVelPID:input,
            "Ae", hoverAltPID:error,
            "Ve", hoverVelPID:error,
            "eVo",  eastVelPID:output, 
            "nVo", northVelPID:output,
            "logger Lines", logger
        ).
        
        return lexicon("lexo", lexo, "lexa", lexa).
    }

    function suicide { // sufixes Alt, Dv, Time
        parameter 
            angleMarngin is 0, 
            target  is (choose targetlocation if defined targetlocation else ship:geoPosition):terrainheight, 
            thrust  is availableThrust,
            initAlt is altitude, 
            intiVel is ship:velocity:surface:mag, 
            g is (body:mu / (body:radius)^2)
        .

        local sbAlt    is target + (initAlt * g + .5 * intiVel^2) / max(.01, (thrust / mass)).
        local sbDv     is sqrt(abs(intiVel^2 + 2*g*(initAlt - sbAlt))).
        local sbTime   is sbAlt/abs(verticalSpeed).

        return lexicon("Alt", sbAlt, "Dv", sbDv, "time", sbTime).
    }
    function suicideStarter {
        parameter nextrun, nextsub, offset is 0, suicideTriggerAlt is suicide():Alt.
        
        if not (defined t1) {
            set t1 to time:seconds.
        }
        
        global burnAlt     to suicideTriggerAlt + offset.
        global burnStartIn to suicide():time.

        local dt   to time:seconds - t1.
        local skip to vel:mag * dt * 0.

        if (altitude + skip < burnAlt) {
            set runmode to nextrun.
            set submode to nextsub.
        }

        set t1 to time:seconds.
    }

    
    function boostBack_Setup {
        parameter 
            E,              // Entryburn height in [m] MSL
            v_c,            // Entryburn end vertical vel in [m/s]
            F is maxThrust  // Entryburn accel in [m/s^2]
        .
        local g0 is choose GRAVITY if defined GRAVITY else body:mu / (body:radius + altitude)^2.

    // BEFORE ENTRY-BURN POINT
        // time till Entry burn POINT
        global t_E is choose (verticalSpeed + sqrt( verticalSpeed^2 + 2*g0*(altitude - E) )) / g0 if altitude > E else relpos:mag. // makes p_x = 1 if below E
        // Hor.speed for boostback
        global p_x is relpos:mag/t_E.
        // dv for Boostback-Burn
        global dvA is abs(p_x - groundspeed).

        // Speeds at E Point
        global e_x is p_x.
        global e_y is -g0*t_E + verticalSpeed.
        
    // AT ENTRY-BURN POINT
        // pitchangle for desired v_c at e_x=0 (up = 0, horizontal = 90)
        global a_c is arcTan(e_x/(v_c-e_y)).
        // dv for Entry-Burn
        global dvB is sqrt(e_x^2 + (v_c-e_y)^2).

        // Entryburn time
        global B_t is abs(e_x)/(F*sin(a_c)).
        // Entryburn start height
        global B_h is -g0/8 * B_t^2 + abs(e_y) * B_t/2 + E.
        // Entryburn end height
        global G_h is B_t*( (v_c+e_y)/2 - g0/8 *B_t + abs(e_y)/2 ) + E.
        // dv for Landing
        global dvL is sqrt(v_c^2 + 2*g0*G_h).

    // BEFORE ENTRY-BURN POINT
        // Impact time in relation to Entryburn point
        global t_IE is (e_y+sqrt(e_y^2 + 2*g0*E))/g0.
        // Impact x-offset in relation to Entryburn point
        global I_x  is e_x * t_IE + E.

        global dvTotal is dvA + dvB + dvL.
    }
    function boostBack_0A {
        // position:    Launch -> A (Seperation)
        // returns:     Dv
        // utilities:   t_E, p_x, e_x, e_y, (F)

        parameter E, v_c, F is maxthrust, overrideL is "NaN".

        local g0 is choose GRAVITY if defined GRAVITY else body:mu / (body:radius + altitude)^2. 


        // time till Entry burn POINT
        local t_E is choose (verticalSpeed + sqrt( verticalSpeed^2 + 2*g0*(altitude - E) )) / g0 if altitude > E else relpos:mag. // makes p_x = 1 if below E
        // Hor.speed for boostback
        local p_x is relpos:mag/t_E.


        // Speeds at E Point
        local e_x is p_x.
        local e_y is -g0*t_E + verticalSpeed.


        // pitchangle for desired v_c at e_x=0      (up = 0, horizontal = 90)
        local a_c is arcTan(e_x/(v_c-e_y)).
        // Entryburn time
        local B_t is abs(e_x)/(F*sin(a_c)).
        // Entryburn end height
        local G_h is B_t*( (v_c+e_y)/2 - g0/8 *B_t + abs(e_y)/2 ) + E.


        local a is abs(p_x - groundspeed).
        local b is sqrt(e_x^2 + (v_c-e_y)^2).
        local l is choose sqrt(v_c^2 + 2*g0*G_h) if overrideL:istype("String") else overrideL.

        local dv is a + b + l.

        log (time:seconds-modeElapsedTimeStart) +" "+ t_E +" "+ p_x +" "+ e_y +" "+ a_c +" "+ B_t +" "+ G_h +" "+ dv to path("0:/boostBack_0A.csv.").

        return dv.
    }
    function boostBack_A  {
        // position:    A (Boost-back)
        // returns:     p_x
        // utilities:   t_E (, e_x, e_y, t_IE, I_x)

        parameter E.

        local g0 is choose GRAVITY if defined GRAVITY else body:mu / (body:radius + altitude)^2. 

        // time till Entry burn POINT
        local t_E is choose (verticalSpeed + sqrt( verticalSpeed^2 + 2*g0*(altitude - E) )) / g0 if altitude > E else relpos:mag. // makes p_x = 1 if below E
        // Hor.speed for boostback
        local p_x is relpos:mag/t_E.

        // Speeds at E Point
        local e_x is p_x.
        local e_y is -g0*t_E + verticalSpeed.
        // Impact time in relation to Entryburn point
        local t_IE is (e_y+sqrt(e_y^2 + 2*g0*E))/g0.
        // Impact x-offset in relation to Entryburn point
        local I_x  is e_x * t_IE.
        log (time:seconds-modeElapsedTimeStart) +" "+ t_E +" "+ p_x +" "+ e_y +" "+ t_IE +" "+ I_x to path("0:/boostBack_A.csv.").

        return lex("p_x", p_x, "I_x", I_x).
    }
    function boostBack_AB {
        // position:    A -> B (Glide-back)
        // returns:     B_h
        // utilities:   lamda -> {t_E, e_x, e_y, (E')}

        parameter v_c, F is maxThrust.

        // will give us t_E, E (E'), e_x, e_y, a_c
        lamda(v_c).

        // Entryburn time
        local B_t is abs(e_x)/(F*sin(a_c)).
        // Entryburn start height
        local B_h is -g0/8 * B_t^2 + abs(e_y) * B_t/2 + E.
        log (time:seconds-modeElapsedTimeStart) +" "+ t_E +" "+ e_x +" "+ e_y +" "+ a_c +" "+ B_t +" "+ B_h +" "+ E to path("0:/boostBack_AB.csv.").

        return B_h.
    }
    function lamda {
        parameter vc.

        set g0 to choose GRAVITY if defined GRAVITY else body:mu / (body:radius + altitude)^2.

        // time till Entry burn POINT
        set t_E to choose relpos:mag/groundspeed if groundspeed <> 0 else 0.

        set E to -g0/2*t_E^2 + verticalSpeed*t_E + altitude.

        // Speeds at E Point
        set e_x to groundspeed.
        set e_y to -g0*t_E + verticalSpeed.

        // pitchangle for desired v_c at e_x=0 (up = 0, horizontal = 90)
        set a_c to arcTan(e_x/(vc-e_y)).
    }