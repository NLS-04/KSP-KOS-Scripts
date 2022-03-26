// functions ===========================================================================================================
    function GravityTurnPitch { // Gravityturn Pitch Calculator
        Parameter StartAlt.
        parameter EndAlt.
        Parameter StartAngle.
        Parameter EndAngle.

        lock OutputPitch to (( ALT:RADAR / 1000 ) - StartAlt ) * (( EndAngle - StartAngle ) / ( EndAlt - StartAlt )) + StartAngle. 

        RETURN OutputPitch.
    }
    function VERTICAL_PID_LOOP { // Verticalspeed PID-LOOP 
        set lastPv to 0.
        set lastTimev to 0.
        set totalPv to 0.

        set kPv to 0.7.
        set kIv to 0.03.
        set kDv to 0.25.
        
        PARAMETER target.
        PARAMETER current.

        set outputv to 0.
        set nowv to TIME:SECONDS.

        set Pv to target - current.
        set Iv to 0.
        set Dv to 0.
        
        if lastTimev > 0 {
            set Iv to totalPv + (Pv + lastPv)/2 * (nowv - lastTimev).
            set Dv to (pv - lastPv) / (nowv - lastTimev). 
        }

        set outputv to Pv * kPv + Iv * kIv + Dv * kDv.

        set lastPv to Pv.
        set lastTimev to nowv.
        set totalPv to Iv.

        print "outputv:                      " + ROUND(outputv,2) at (5,16).
        
        RETURN outputv.
    }
    function Pitch_PID {
        set lastP to 0.
        set lastTime to 0.
        set totalP to 0.

        set kP to 0.7.
        set kI to 0.03.
        set kD to 0.25.
        
        PARAMETER target.
        PARAMETER current.

        set output to 0.
        set now to TIME:SECONDS.

        set P to target - current.
        set I to 0.
        set D to 0.
        
        if lastTime > 0 {
            set I to totalP + (P + lastP)/2 * (now - lastTime).
            set D to (p - lastP) / (now - lastTime). 
        }

        set output to P * kP + I * kI + D * kD.

        set lastP to P.
        set lastTime to now.
        set totalP to I.

        print "outputv:                      " + ROUND(output,2) at (5,16).
        
        RETURN output.    
    }
    function GeoDir { // direction [Heading] to target [LATLNG]
        parameter geo1. 
        parameter geo2. 
        
        RETURN ARCTAN2(geo1:LNG - geo2:LNG , geo1:LAT - geo2:LAT).
    }
    function GeoDist{ // distance [m] to target   
        parameter geo1. 
        parameter geo2.

        RETURN (geo1:POSITION - geo2:POSITION):MAG.
    }
    function DoSaveStage {
            wait until stage:Ready.
            stage.
    }
    function at_Alt_v {
        parameter r.

        set a to (SHIP:APOAPSIS + SHIP:PERIAPSIS) / 2.
        set GM to BODY:MU.
        set v to SQRT(GM * (2 / r - 1 / a)).

        RETURN v.
    }
    function circ_v {
        set GM to BODY:MU.
        set v to SQRT(GM / SHIP:APOAPSIS).
       
        RETURN v.
    }
    function control_point {
        PARAMETER pTag IS "controlPoint".
        LOCAL controlList IS SHIP:PARTSTAGGED(pTag).
        IF controlList:LENGTH > 0 {
            controlList[0]:CONTROLFROM().
        } ELSE {
            IF SHIP:ROOTPART:HASSUFFIX("CONTROLFROM") {
                SHIP:ROOTPART:CONTROLFROM().
            }
        }
    }
    function runmode_changer {
        IF AG5 {
            AG5 off.
            set runmode to runmode - 1.
        }

        IF AG6 {
            AG6 off.
            set runmode to runmode + 1.
        }

        IF ABORT {
            ABORT off.
            set runmode to runmode + 10.
        }
    }
    // Marcus House
    function setHoverPIDLOOPS{ // PIDloop(kp, ki, kd, min, max)
        SET bodyRadius TO 600 + AltLand. //note Kerbin is around 600
        //Controls altitude by changing climbPID setpoint
        SET hoverPID TO PIDLOOP(1, 0.02, 0.001, -50, 50). 
        //Controls vertical speed
        SET climbPID TO PIDLOOP(0.3, 0.25, 0.1, 0, 1). 
        //Controls horizontal speed by tilting rocket
        SET eastVelPID TO PIDLOOP(3, 0.01, 0.0, -20, 20).
        SET northVelPID TO PIDLOOP(3, 0.01, 0.0, -20, 20). 
        //controls horizontal position by changing velPID setpoints
        SET eastPosPID TO PIDLOOP(bodyRadius, 0, 100, -40,40).
        SET northPosPID TO PIDLOOP(bodyRadius, 0, 100, -40,40).
    }
    function updateHoverSteering{
        parameter reverse is false.
        parameter minPitch is 0.
        SET cVelLast TO cVel().
        SET eastVelPID:SETPOINT TO eastPosPID:UPDATE(TIME:SECONDS, SHIP:GEOPOSITION:LNG).
        SET northVelPID:SETPOINT TO northPosPID:UPDATE(TIME:SECONDS,SHIP:GEOPOSITION:LAT).
        LOCAL eastVelPIDOut IS eastVelPID:UPDATE(TIME:SECONDS, cVelLast:X).
        LOCAL northVelPIDOut IS northVelPID:UPDATE(TIME:SECONDS, cVelLast:Z).
        LOCAL eastPlusNorth is MAX(ABS(eastVelPIDOut), ABS(northVelPIDOut)).
        
        LOCAL steeringDirNonNorm IS ARCTAN2(eastVelPID:OUTPUT, northVelPID:OUTPUT). //might be negative
        if steeringDirNonNorm >= 0 {
            SET steeringDir TO steeringDirNonNorm.
        } else {
            SET steeringDir TO 360 + steeringDirNonNorm.
        }
        if (reverse) {
            SET steeringDir TO steeringDir - 180.
            if steeringDir < 0 {
                SET steeringDir TO 360 + steeringDir.
            }
        }
        SET shipPitch TO 90 - eastPlusNorth.
        if(shipPitch < minPitch) {
            SET shipPitch TO minPitch.
        }
        
        LOCAL thisHeading TO HEADING(steeringDir,shipPitch).
        LOCK STEERING TO lookdirup(thisHeading:vector, ship:facing:topvector).
    }
    
    function isShip{
        parameter tagName.
        IF CORE:part:tag = tagName {
            RETURN TRUE.
        }
        RETURN FALSE.
    }
    function isShipIdent {
        parameter tagName.
        IF CORE:part:tag = tagName {
            RETURN tagname.
        }
    }
    function cVel {
        lock Vs to SHIP:VELOCITY:SURFACE.
        lock eVect to VCRS(UP:VECTOR, NORTH:VECTOR).
        lock eComp to sProj(Vs, eVect).
        lock nComp to sProj(Vs, NORTH:VECTOR).
        lock uComp to sProj(Vs, UP:VECTOR).
        RETURN V(eComp, uComp, nComp).
    }
    function sProj { //Scalar projection of two vectors.
        parameter a.
        parameter b.
        if b:mag = 0 { PRINT "sProj: Divide by 0. Returning 1". RETURN 1. }
        RETURN VDOT(a, b) * (1/b:MAG).
    }
    function setHoverDescendSpeed{
        parameter a.
        parameter minThrott is 0.
        SET hoverPID:MAXOUTPUT TO a.
        SET hoverPID:MINOUTPUT TO -1*a.
        SET climbPID:SETPOINT TO hoverPID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE). //control descent speed with throttle
        SET calcThrott TO climbPID:UPDATE(TIME:SECONDS, SHIP:VERTICALSPEED).
        if(calcThrott<minThrott){
            SET calcThrott TO minThrott.
        }
        
        if(SHIP:VERTICALSPEED>-1) {
            SET calcThrott TO 0.
        }
        SET throt TO calcThrott.	
    }
    function setHoverAltitude{ //set just below landing altitude to touchdown smoothly
        parameter a.
        SET hoverPID:SETPOINT TO a.
    }
   
// variables ===========================================================================================================
    set throt to 0.
    lock throttle to throt. 
    set TimeToStartBurn to 0.
    set VanDiff to 0.
    set impactDist to 0.
    set suicide_burn_altitude to 0.
    set is_single to false.

// lists ===============================================================================================================
    LIST ENGINES IN My_Engines.
    LIST PROCESSORS IN Pro_List.

// parameters ==========================================================================================================
    set Launch_Pad_Lat to -0.0972077635067718.
    set Launch_Pad_Lng to -74.5576726244574.
    // set Landing_Pos_LatLng to BODY:GEOPOSITIONLATLNG(Launch_Pad_Lat, Launch_Pad_Lng).

// aids (setable)=======================================================================================================
    set  Thrust_Limit to 1. // !SET! 0 < Available_Max_Thrust < 1
    set  above_Pad_Suicide to 100. // suicide burn x[m] above landing spot
    set  MaxG to 2. // Max G-Forces duing launch
    set  parking_orbit to 100000. // park orbit in [m]
    set  target_orbit to 100000. // target orbit in [m]
    set  start_Azimuth to 90.
    //set target_ship to Vessel("KSS"). // doesnt have to be set
// aids (auto)==========================================================================================================
    lock shipLatLng to SHIP:GEOPOSITION.
    lock surfaceElevation to shipLatLng:TERRAINHEIGHT.
    lock betterALTRADAR to MIN(Altitude - surfaceElevation, MAX(ALTITUDE,0)).
    lock GRAVITY to (constant:g * body:mass) / (body:radius + ALTITUDE)^2.
    lock aZL to max(0.001, ((Maxthrust * Thrust_Limit) / Mass) - GRAVITY). 
    lock TWRnow to max( 0.001, Maxthrust / (MASS*GRAVITY)).
    lock zeroAccelthrust to ((MASS*GRAVITY)/max(0.001,Maxthrust)).
    lock timeToImpact to betterALTRADAR/-Verticalspeed.
    lock AltLand to betterALTRADAR - AltLandPos_corection - above_Pad_Suicide.
    lock suicide_burn_altitude to (((GROUNDSPEED + VERTICALSPEED)^2 / aZL) / 2) - Verticalspeed/CONFIG:IPU. //CON.IPU = processing speed
    lock distance_to_suicide_burn to (AltLand - suicide_burn_altitude). 
    lock Pressure to BODY:ATM:ALTITUDEPRESSURE(ALTITUDE).
    set  Ship_mass_start to SHIP:MASS.
    lock MaxG_Thrust to MAX(0, MIN(1, (((9.81 * MaxG) + 9.81) * SHIP:MASS) / MAX(0.001, Maxthrust))).
    
    FOR ENG IN My_Engines {
        lock DeltaVelocity_all to (MAX(1, ENG:ISPAT(Pressure) * 9.8 * ln(SHIP:MASS / SHIP:DRYMASS))).
        lock DeltaVelocity_LB to (MAX(1, ENG:ISPAT(Pressure) * 9.8 * ln((SHIP:MASS - (Ship_mass_start - 113.212)) / 25.212))).
    }    
// Checks ==============================================================================================================
    print "press ENTER to start the sequence". 
    
    CLEARVECDRAWS().
    IF TERMINAL:INPUT:GETCHAR = TERMINAL:INPUT:ENTER {
        clearscreen.
        
        IF isShip("LB") {
            control_point("LB_Control").
            DoSaveStage().
            set runmode to 101.
        }
            
        ELSE IF isShip("OB") {
            set runmode to -1. //temporarly disabled
        }
    }
// main Sequence =======================================================================================================
    UNTIL runmode = 0 {
        runmode_changer().
        // ========================================== //
            IF isShip("LB") { // Terminal Display of LB
                print "Ship Name:               " + isShipIdent("LB") + isShipIdent("0B") at (5,1).
                print "Runmode:                 " + runmode + "    " at (5,2).
                print "betterAltRadar:          " + ROUND(betterALTRADAR) + "    m    " at (5,3).
                print "suicide burn altitude:   " + ROUND(suicide_burn_altitude) + "    m    " at (5,4).

                print "Throttle:                " + ROUND(throt,2) + "    %    " at (5,6).
                
                print "Delat V (all):           " + ROUND(DeltaVelocity_all,2) + "    m/s    " at (5,8).
                print "Delat V (LB):            " + ROUND(DeltaVelocity_LB,2) + "    m/s    " at (5,9).
                
                print "Time to Impact:          " + ROUND(timeToImpact) + "    s    " at (5,11).
                
                print "Distance ship:           " + ROUND(GeoDist(shipLatLng, Landing_Pos_LatLng)) + "    m    " at (5,13).
                print "Distance Impact:         " + ROUND(impactDist) + "    m    " at (5,14).
                print "Direction:               " + ROUND(GeoDir(shipLatLng, Landing_Pos_LatLng)) + "    " at (5,15).
                
                print "Q:                       " + ROUND(SHIP:Q,3) at (5,17).
            }

            IF isShip("OB") { // Terminal Display of OB
                print "SHIP NAME:               " + isShipIdent("LB") + isShipIdent("0B") at (5,1).
                print "RUNMODE:                 " + runmode + "    " at (5,2).
                
                print "ALTITUDE:                " + ROUND(altitude / 1000, 2) + "    km    " at (5,4).
                print "APOAPSIS:                " + ROUND(SHIP:Apoapsis / 1000, 2) + "    km    " at (5,5).
                print "PERIAPSIS:               " + ROUND(SHIP:Periapsis / 1000, 2) + "    km    " at (5,6).
                
                print "TRHOTTLE:                " + ROUND(throt,2) + "    %    " at (5,8).
                
                print "DELTA V:                 " + ROUND(DeltaVelocity_all,2) + "    m/s    " at (5,10).
                
                print "ETA APOAPSIS:            " + ROUND(ETA:APOAPSIS) + "    s    " at (5,12).
                print "ETA PERIAPSIS:           " + ROUND(ETA:PERIAPSIS) + "    s    " at (5,13).
                            
                print "is_single:               " + is_single at (5,15).
            }
        // ========================================== //

        // Vecdraws
            lock Vec_Steering to (5*UP:Vector + Landing_Pos_LatLng:POSITION/GeoDist(SHIP, Landing_Pos_LatLng)).
            lock Vec_Vel_tartget to -(velocity:surface + Landing_Pos_LatLng:POSITION/GeoDist(SHIP, Landing_Pos_LatLng)).
            lock Vec_Combined to (Vec_Steering + 2 * velocity:surface).
            lock Vec_Steering_Combined to (Vec_Steering + (1/10) * Vec_Combined).
            lock Vec_Steering_Vel to (Vec_Steering + velocity:surface).
            
            // set vd_Up to VECDRAW(V(0,0,0), 15 * UP:VECTOR, RGB(0,0,1), "UP", 2.5, TRUE, 0.1). 
            // set vd_Face to VECDRAW(V(0,0,0), 15 * SHIP:facing:Vector, RGB(0,1,0), "facing", 2.5, TRUE, 0.1).
            // set vd_velocity to VECDRAW(V(0,0,0), (velocity:surface:MAG) * velocity:surface, RGB(1,0,1), "velocity", 2, TRUE, 0.1).
            // set vd_Position to VECDRAW(V(0,0,0), Landing_Pos_LatLng:POSITION, RGB(1,0,0), "Landing Vector", 1, TRUE, 0.5).
             //set vd_CalcDir to VECDRAW(V(0,0,0), 5 * Vec_Steering , RGB(1,1,0), "Steering", 2.5, TRUE, 0.1).
             //set vd_Steering_Combined to VECDRAW(V(0,0,0), Vec_Steering_Combined, RGB(1,1,1), "CalcCalc", 2.5, TRUE, 0.1).
             //set vd_Combined to VECDRAW(V(0,0,0), Vec_Combined, RGB(0,1,1), "Combined", 2.5, TRUE, 0.1).
             //set vd_Vel_target to VECDRAW(V(0,0,0), Vec_Vel_tartget, RGB(0,1,1), "Vel_Target", 2.5, TRUE, 0.1).
             //set vd_cVel to VECDRAW(V(0,0,0), cVel(), RGB(0,1,1), "cVel", 2.5, TRUE, 0.1).

        
        
        
        // runmodes = 10X
            IF runmode = 101 { // Launch + GT
                lock turnAngle to MIN(90, MAX(25, GravityTurnPitch(1, 10, 90, 70))). // StartAlt, EndAlt, StartAngle, EndAngle
                lock steering to HEADING(start_Azimuth, turnAngle).
                lock throt to MaxG_Thrust.

                IF (DeltaVelocity_LB <= 2 * (Groundspeed + Verticalspeed) OR DeltaVelocity_all <= 2 * (Groundspeed + Verticalspeed)) AND ALTITUDE > 1000 AND (Groundspeed + Verticalspeed) > 100 {
                    set throt to 0.
                    wait 2.5.
                    AG10 on. //3 engine burn
                    wait 1.
                    DoSaveStage().
                    RCS on.

                    set runmode to 102.
                }
            }
            IF runmode = 102 { // turn for return burn
                IF isShip("LB") {
                    control_point("LB_Control").
                    set throt to 0.
                    wait 2.
                    //functions
                        function steerToTarget_ReturnBurn{
                            parameter landingTarget.

                            set pitch to 0.
                            set overshootLat to 0.
                            set overshootLng to 0.
                            SET overshootLatLng TO LATLNG(landingTarget:LAT + overshootLat, landingTarget:LNG + overshootLng).
                            LOCK targetDir TO GeoDir(ADDONS:TR:IMPACTPOS,overshootLatLng).
                            LOCK impactDist TO GeoDist(overshootLatLng, ADDONS:TR:IMPACTPOS).
                            LOCK steeringDir TO targetDir - 180.
                            
                            LOCK STEERING TO HEADING(steeringDir,pitch).
                        }
                    RCS on.
                    setHoverPIDLOOPS().
                    setHoverTarget(Landing_Pos_LatLng).
                    steerToTarget_ReturnBurn(Landing_Pos_LatLng).
                    
                    wait 8.
                    
                    IF isShip("LB") {
                        set runmode to 103. 
                    }
                }
            }
            IF runmode = 103 { // return burn to target
                IF isShip("LB") {
                    //functions
                        function steerToTarget_ReturnBurn{
                            parameter landingTarget.

                            set pitch to 0.
                            set overshootLat to 0.
                            set overshootLng to -0.01.
                            SET overshootLatLng TO LATLNG(landingTarget:LAT + overshootLat, landingTarget:LNG + overshootLng).
                            LOCK targetDir TO GeoDir(ADDONS:TR:IMPACTPOS,overshootLatLng).
                            LOCK impactDist TO GeoDist(overshootLatLng, ADDONS:TR:IMPACTPOS).
                            LOCK steeringDir TO targetDir - 180.
                            
                            LOCK STEERING TO HEADING(steeringDir,pitch).

                            IF impactDist < 1000 {
                                set throt to 0.1.
                                AG9 on. //1 engine burn

                                IF impactDist < 100 {
                                    set throt to 0.
                                    AG9 off. //3  engine burn

                                    IF isShip("LB") {    
                                        set runmode to 104.
                                    }
                                }
                            } ELSE {
                                set throt to 1.
                            }
                        }
                    
                    setHoverPIDLOOPS().
                    setHoverTarget(Landing_Pos_LatLng).
                    steerToTarget_ReturnBurn(Landing_Pos_LatLng).
                }
            }
            IF runmode = 104 { // glide to target
                IF isShip("LB") {
                    //functions
                        function steerToTarget_ReturnGlide{
                            parameter landingTarget.

                            set overshootLat to 0.
                            IF betterALTRADAR < 5000 {
                                set overshootLng to 0.
                            } ELSE {
                                set overshootLng to -0.005.
                            }
                            
                            LOCK overshootLatLng TO LATLNG(landingTarget:LAT + overshootLat, landingTarget:LNG + overshootLng).
                            LOCK targetDir TO GeoDir(ADDONS:TR:IMPACTPOS,overshootLatLng).
                            LOCK impactDist TO GeoDist(overshootLatLng, ADDONS:TR:IMPACTPOS).
                            LOCK steeringDir TO targetDir.
                            
                            // LOCK retro_pitch to -VELOCITY:SURFACE:MAG.
                            // PRINT "retro pitch:             " + ROUND(retro_pitch,2) at (5,19).

                            IF impactDist > 50 AND GROUNDSPEED < 600 {
                                LOCK pitching to 90 - MAX((impactDist/10), 20).
                                LOCK STEERING TO HEADING(steeringDir,pitching).
                            } ELSE {
                                lock STEERING TO RETROGRADE.
                            }
                        }
                    steerToTarget_ReturnGlide(Landing_Pos_LatLng).
                    set throt to 0.
                    AG7 on. //Gridfins deployed
                    
                    IF distance_to_suicide_burn < 5 {
                        IF isShip("LB") {    
                            set runmode to 105.
                        }
                    }
                }
            }
            IF runmode = 105 { // suicide burn
                IF isShip("LB") {
                    setHoverPIDLOOPS().
                    setHoverTarget(Landing_Pos_LatLng).
                    updateHoverSteering(). //steering
                    setHoverMaxSteerAngle(5).
                    set throt to Thrust_Limit.
                    
                    GEAR on.

                    IF Verticalspeed > -5 {
                        IF isShip("LB") {
                            set runmode to 106.
                        }
                    }
                 }
            }
            IF runmode = 106 { // hover to target
                IF isShip("LB") {
                    setHoverPIDLOOPS().
                    setHoverTarget(Landing_Pos_LatLng).
                    updateHoverSteering(). //steering
                    setHoverMaxSteerAngle(5).
                    setHoverMaxHorizSpeed(5).

                    IF impactDist > 3 {
                        setHoverAltitude(AltLand + 20).
                        setHoverDescendSpeed(5,0.1). //Throttle
                    } ELSE {
                        setHoverAltitude(AltLand - 5).
                        setHoverDescendSpeed(1,0.1). //Throttle
                    }

                    IF impactDist > 250 {
                        IF isShip("LB") {    
                            set runmode to 616.
                        }
                    }

                    WHEN SHIP:STATUS = "Landed" OR SHIP:STATUS = "Splashed" THEN {
                        set throt to 0.
                        AG9 on.
                        AG8 on.
                        IF isShip("LB") {
                            set runmode to 000.
                        }
                    }
                }
            }

        // runmodes = 20X
            IF runmode = 200 {
                //function 
                    IF pro_list:LENGTH > 1 {
                        set is_single to false.
                    } ELSE {
                        set is_single to true.
                    }
                IF is_single {
                    set runmode to 202.
                } ELSE IF AG10 {
                    set AG10 to off.
                    set runmode to 202.
                }
            }
            IF runmode = 202 { // Contiue of ascend
                IF isShip("OB") {
                    SAS on.
                    wait 5.
                    
                    set throt to 0.
                    lock throt to throttle.

                    UNTIL SHIP:APOAPSIS >= 0.95 * parking_orbit {
                        SAS off.
                        lock turnAngle to MIN(90, MAX(25, GravityTurnPitch(1, 10, 90, 70))). // StartAlt, EndAlt, StartAngle, EndAngle
                        lock steering to HEADING(start_Azimuth, turnAngle).
                        set throt to MaxG_Thrust.
                    } 

                    IF SHIP:APOAPSIS >= 0.95 * parking_orbit {
                        IF isShip("OB") {
                            set throt to 0.
                            set steering to velocity:orbit.
                            set runmode to 203.
                        }
                    }
                }
            }
            IF runmode = 203 { // circ_prep for parking orbit
                IF isShip("OB") {
                    IF SHIP:ALTITUDE > 70000 {
                        IF SHIP:APOAPSIS < parking_orbit { // raise orbit
                            set steering to velocity:orbit.
                            wait 5.
                            //wait until VANG(SHIP:facing, velocity:orbit) < 5.
                            until ABS(ship:APOAPSIS - parking_orbit) < 5 {
                                lock throt to ABS(ship:APOAPSIS - parking_orbit) / 1000.
                            }
                            set throt to 0.
                            IF isShip("OB") {
                                set runmode to 204.
                            }
                        } 
                        
                        ELSE IF SHIP:APOAPSIS > parking_orbit { // lower orbit
                            set steering to -velocity:orbit.
                            wait 5.
                            //wait until VANG(SHIP:facing, -velocity:orbit) < 5.
                            until ABS(ship:APOAPSIS - parking_orbit) < 5 {
                                lock throt to ABS(ship:APOAPSIS - parking_orbit) / 1000.
                            }
                            set throt to 0.
                            IF isShip("OB") {
                                set runmode to 204.
                            }
                        }
                        
                    } 
                }
            }
            IF runmode = 204 { // circ of parking orbit
                IF isShip("OB") {    
                    set Apo_Speed to at_Alt_v(SHIP:APOAPSIS).
                    set Orb_Speed to circ_v().
                    set a to max(0.001, ((Maxthrust * Thrust_Limit) / mass)).
                    set burn_time to Orb_Speed - Apo_Speed.

                    WHEN burn_time / 2 + 30 < ETA:APOAPSIS THEN {
                        set steering to velocity:orbit.
                    }
                    
                    WHEN burn_time / 2 <= ETA:APOAPSIS THEN {
                        until ABS(SHIP:PERIAPSIS / parking_orbit) < 0.99 {
                            lock throt to ABS(SHIP:PERIAPSIS - MAX(parking_orbit, SHIP:APOAPSIS) / 1000). 
                        }

                        IF ABS(SHIP:PERIAPSIS / parking_orbit) < 0.99 {
                            set throt to 0.
                            IF isShip("OB") {
                                set runmode to 205.
                            }
                        }
                    }
                }
            }
            IF runmode = 205 { // Transition burn to target orbit
                print "juhu endlich im orbit (also hoffentlich)".
                wait 20.
                IF isShip("OB") {
                    set runmode to 000.
                }
            }

        // runmodes = X1X
            IF runmode = 616 { // Lands at current position, caus not near target 
                setHoverPIDLOOPS().
                setHoverTarget(shipLatLng). 
                updateHoverSteering(). //steering
                setHoverMaxSteerAngle(5).
                setHoverMaxHorizSpeed(10).
                
                IF betterALTRADAR < 50 {
                    setHoverDescendSpeed(1,0.1). //Throttle
                } ELSE {
                    setHoverDescendSpeed(10,0.1). //Throttle
                }
                IF impactDist > 3 {
                    setHoverAltitude(AltLand + 20).
                } ELSE {
                    setHoverAltitude(AltLand - 5).
                }

                WHEN SHIP:STATUS = "Landed" OR SHIP:STATUS = "Splashed" THEN {
                    set throt to 0.
                    AG9 on.
                    AG8 on.
                    set runmode to 000.
                } 
            }
        // runmodes = X2X
    }

    IF runmode = 000 { // End script
        clearscreen.
        CLEARVECDRAWS().
        set throt to 0.
        unlock steering.
        SAS on.
        RCS off.
        AG7 off.
    }