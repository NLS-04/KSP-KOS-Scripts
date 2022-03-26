// functions
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
        set Iv to totalPv + (Pv + lastPv) / 2 * (nowv - lastTimev).
        set Dv to (pv - lastPv) / MAX(0.001, (nowv - lastTimev)). 
    }

    set outputv to Pv * kPv + Iv * kIv + Dv * kDv.

    set lastPv to Pv.
    set lastTimev to nowv.
    set totalPv to Iv.

    print "outputv:                      " + ROUND(outputv,2) at (5,16).
    
    RETURN outputv.
}
function Landing_Pitch {
    parameter tLat.
    set YAW to 0.

    IF SHIP:GEOPOSITION:LAT > tLat {
        lock PITCH to 2.
    }

    IF SHIP:GEOPOSITION:LAT < tLat {
        lock PITCH to -2.
    }

    RETURN PITCH.
}
function Landing_Yaw {
    parameter tLng.
    set YAW to 0.

    IF SHIP:GEOPOSITION:Lng > tLng {
        lock YAW to 2.
    }

    IF SHIP:GEOPOSITION:Lng > tLng {
        lock YAW to -2.
    }

    RETURN YAW.
}
function Landing_Pitch_PID { // Pitch PID-LOOP for landing
    set lastP to 0.
    set lastTime to 0.
    set totalP to 0.

    set kP to 0.75.
    set kI to 0.03.
    set kD to 0.3.
    
    PARAMETER target.       // target LAT eg. Launchpad:LAT
    PARAMETER current.      // SHIP's LAT

    set outputPITCH to 0.
    set now to TIME:SECONDS.

    set P to target - current.
    set I to 0.
    set D to 0.
    
    if lastTime > 0 {
        set I to totalP + (P + lastP)/2 * (now - lastTime).
        set D to (p - lastP) / max((now - lastTime), 0.0001). 
    }

    set outputPITCH to P * kP + I * kI + D * kD.

    set lastP to P.
    set lastTime to now.
    set totalP to I.

    print "outputPITCH:                      " + ROUND(outputPITCH,2) at (5,11).
    
    RETURN outputPITCH.
}
function Landing_YAW_PID { // YAW PID-LOOP for landing
    set lastP to 0.
    set lastTime to 0.
    set totalP to 0.

    set kP to 0.75.
    set kI to 0.03.
    set kD to 0.3.
    
    PARAMETER target.       // target LNG eg. Launchpad:LNG
    PARAMETER current.      // SHIP's LNG

    set outputYAW to 0.
    set now to TIME:SECONDS.

    set P to target - current.
    set I to 0.
    set D to 0.
    
    if lastTime > 0 {
        set I to totalP + (P + lastP)/2 * (now - lastTime).
        set D to (p - lastP) / max((now - lastTime), 0.0001). 
    }

    set outputYAW to P * kP + I * kI + D * kD.

    set lastP to P.
    set lastTime to now.
    set totalP to I.

    print "outputYAW:                      " + ROUND(outputYAW,2) at (5,12).
    
    RETURN outputYAW.
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

// variables
set throt to 0.
lock throttle to throt. 
set TimeToStartBurn to 0.

// lists
    LIST ENGINES IN My_Engines.

// parameters
set stagingAlt to 40000.
set Launch_Pad_Lat1 to -0.0971980934745649.
set Launch_Pad_Lng1 to -74.55766399546.
set Launch_Pad_LatLng1 to BODY:GEOPOSITIONLATLNG(-0.0971980934745649,-74.55766399546).
set Launch_Pad_Lat2 to -0.0972092543643722.
set Launch_Pad_Lng2 to -74.557706433623.
set Launch_Pad_LatLng2 to BODY:GEOPOSITIONLATLNG(-0.0972092543643722,-74.557706433623).

// aids
lock shipLatLng to SHIP:GEOPOSITION.
lock surfaceElevation to shipLatLng:TERRAINHEIGHT.
lock betterALTRADAR to max(ALT:RADAR, Altitude - surfaceElevation).
lock LandAlt to max(0,betterALTRADAR-0). // ...- "Elevation"
lock GRAVITY to (constant:g * body:mass) / (body:radius + ALTITUDE)^2.
lock aNow to max(0.001, Maxthrust / MASS). 
lock aZ to max(0.001, (Maxthrust / Mass) - GRAVITY).
lock aZL to max(0.001, ((Maxthrust * 0.4) / Mass) - GRAVITY). // !SET! 0 < Available_Max_Thrust < 1
lock TWRnow to max( 0.001, Maxthrust / (MASS*GRAVITY)).
lock zeroAccelthrust to ((MASS*GRAVITY)/max(0.001,Maxthrust)).
lock timeToImpact to betterALTRADAR/(-1)*Verticalspeed.
lock AltTouch to betterALTRADAR - 1.2 - 30.
lock suicide_burn_altitude to 0.5 * (Verticalspeed^2 / aZL) - Verticalspeed/CONFIG:IPU. //CON.IPU = processing speed
lock distance_to_suicide_burn to (AltTouch - suicide_burn_altitude).
lock Pressure to BODY:ATM:ALTITUDEPRESSURE(ALTITUDE).
FOR ENG IN My_Engines {
    lock DeltaVelocity to (MAX(1, ENG:ISPAT(Pressure) * 9.8 *ln(SHIP:MASS/SHIP:DRYMASS))).
}

// Checks
set runmode to "test_a".
IF betterALTRADAR >= stagingAlt {
    set runmode to 2.
}

UNTIL runmode = 0 {
    // ========================================== //
    print "Runmode:                 " + runmode at (5,2).
    print "betterAltRadar:          " + ROUND(betterALTRADAR,5) + "    m"at (5,3).
    print "Delat V:                 " + ROUND(DeltaVelocity,2) + "    m/s" at (5,4).
    print "aNow:                    " + ROUND(aNow,2) + "    m/s^2" at (5,5).
    print "A net:                   " + ROUND(aNow-GRAVITY,2) + "    m/s^2"at (5,6).
    print "TWRnow:                  " + ROUND(TWRnow,2) at (5,7).
    print "Throttle:                " + ROUND(throt,2) + "%" at (5,8).
    print "Time to Impact:          " + ROUND(timeToImpact,0) + "    s" at (5,9).

    // ========================================== //

    IF runmode = 1 { //Launch + GT
        lock turnAngle to GravityTurnPitch(7, 40, 90, 45). //StartAlt, EndAlt, StartAngle, EndAngle
        lock steering to HEADING(90, turnAngle).
        set throt to 1.
    
        IF betterALTRADAR > 1000 AND Groundspeed > 200 {
            set throt to 0.75.
        }

        IF betterALTRADAR >= stagingAlt {
            //...
            set runmode to 2.
        }
    }

    IF runmode = 2 { // return & Land
        //...
    }

    IF runmode = "test_a" {
        stage.
        lock steering to UP.
        set throt to 1/2.5.
        wait 10.
        set throt to 0.
        RCS on.
        SAS off.
        
        WAIT UNTIL Verticalspeed < -7. 
        set runmode to "test_b".
        
    }

    IF runmode = "test_b" {
        // Vecdraws

        // set vdUp to VECDRAW(V(0,0,0), 4 * UP:VECTOR, RGB(0,0,1), "UP", 2.5, TRUE, 0.1). 
        // set vdFace to VECDRAW(V(0,0,0), 4 * SHIP:facing:VECTOR, RGB(0,1,0), "facing", 2.5, TRUE, 0.1).
        // set vdPID to VECDRAW(V(0,0,0), 4 * UP:VECTOR + R(Landing_Pitch_PID(Launch_Pad_Lat2,SHIP:GEOPOSITION:LAT),Landing_YAW_PID(Launch_Pad_Lng2,SHIP:GEOPOSITION:LNG),0), RGB(1,0,0), "PID", 2.5, TRUE, 0.1).
        
        set startTime to 0.

        IF Verticalspeed < 0 {
            // lock PITCH to Landing_Pitch_PID(Launch_Pad_Lat2,SHIP:GEOPOSITION:LAT).
            // lock YAW to Landing_YAW_PID(Launch_Pad_Lng2,SHIP:GEOPOSITION:LNG).
            // lock steering to UP + R(PITCH,YAW,0).
            
            // lock PITCH to Landing_Pitch(Launch_Pad_Lat2).
            // lock YAW to Landing_Yaw(Launch_Pad_Lng2).
            // lock steering to UP + R(PITCH,YAW,180).
            lock throt to 0.5 - 0.85 * distance_to_suicide_burn.

            IF Verticalspeed < 10 AND betterALTRADAR <= 50 {
                lock throt to VERTICAL_PID_LOOP(-5,Verticalspeed).
            }

            IF GROUNDSPEED > 2 {
                lock steering to VELOCITY:SURFACE * (-1).
            }

            ELSE IF GROUNDSPEED <= 2 {
                lock steering to UP.
            }
            
            // log (TIME:SECONDS - startTime) + "," + Landing_Pitch_PID(Launch_Pad_Lat2,SHIP:GEOPOSITION:LAT) + "," + Landing_YAW_PID(Launch_Pad_Lng2,SHIP:GEOPOSITION:LNG) to Outputs.csv.
    
            IF timeToImpact < 15 {
                gear on.
            }    
        }

        IF Verticalspeed > 1 AND betterALTRADAR < 5 { 
            set throt to 0.
            AG9 on.
            AG8 on.
            set runmode to 0.
        }
    }
}

IF runmode = 0 {
    clearscreen.
    set throt to 0.
    set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
    unlock steering.
    SAS on.
    RCS off.
    AG7 off.
}