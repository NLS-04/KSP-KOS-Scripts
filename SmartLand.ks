// functions ===========================================================================================================
    function GravityTurnPitch { // Gravityturn Pitch Calculator
        Parameter StartAlt.
        parameter EndAlt.
        Parameter StartAngle.
        Parameter EndAngle.

        lock OutputPitch to (( ALT:RADAR / 1000 ) - StartAlt ) * (( EndAngle - StartAngle ) / ( EndAlt - StartAlt )) + StartAngle. 

        RETURN OutputPitch.
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
    function Time_uni_xy {
        parameter dist_xy.

        RETURN (SQRT( dist_xy / (2 * accel_drift_max)) / 3). 
    }
    function Time_uni_up {
        parameter dist_up.

        RETURN (SQRT( dist_up / (2 * accel_up_max)) / 3). 
    }
    
// variables ===========================================================================================================
    set throt to 0.
    lock throttle to throt. 

// parameters ==========================================================================================================
    //landing pat parameter    
        set Launch_Pad_Lat to -0.0972077635067718.
        set Launch_Pad_Lng to -74.5576726244574.
        // set Landing_Pos_LatLng to BODY:GEOPOSITIONLATLNG(Launch_Pad_Lat, Launch_Pad_Lng).
        
        set Center_Landing_Pad_Lat to -0.0971241845581497.
        set Center_Landing_Pad_Lng to -74.535975689435.
        set Landing_Pos_LatLng to BODY:GEOPOSITIONLATLNG(Center_Landing_Pad_Lat, Center_Landing_Pad_Lng).
        
        set AltLandPos_corection to -25 - 15. 
    
    //rocket parameter
// aids (setable)=======================================================================================================
    set  Thrust_Limit to 1. // !SET! 0 < Available_Max_Thrust < 1
    set  above_land_Pos to 100. // suicide burn x[m] above landing spot
    lock MaxG to 2. // Max G-Forces during |acceleration|

// aids (auto)==========================================================================================================
    lock shipLatLng to SHIP:GEOPOSITION.
    lock surfaceElevation to shipLatLng:TERRAINHEIGHT.
    lock betterALTRADAR to MIN(Altitude - surfaceElevation, MAX(ALTITUDE,0)).
    lock GRAVITY to (constant:g * body:mass) / (body:radius + ALTITUDE)^2.
    lock Fg to MASS * GRAVITY.

    lock ship_angle to VANG(Upvector, Facingvector).
    lock ship_angle_max to arccos(Fg / MAXTHRUST). //Max ship angle

    lock throttle_stable to (Fg / cos(ship_angle)) / MAXTHRUST. // thrust needed for [ALT HLD] -> ship_angle 
    lock force_thrust_stable to Fg / cos(ship_angle). // force needed for [ALT HLD] -> ship_angle

    lock accel_drift to tan(ship_angle) * GRAVITY.
    lock accel_drift_max to tan(ship_angle_max) * GRAVITY.
    lock force_drift to tan(ship_angle) * Fg.
    lock force_drift_max to tan(ship_angle_max) * Fg.

    lock accel_up to (thrust / tan(ship_angle) - Fg) / MASS.
    lock accel_up_max to (MAXTHRUST - Fg) / MASS.

    lock aZL to max(0.001, ((Maxthrust * Thrust_Limit) / Mass) - GRAVITY). 
    lock TWRnow to max( 0.001, Maxthrust / (MASS*GRAVITY)).
    
    set  timeToImpact to betterALTRADAR/ABS(Verticalspeed).
    lock AltLand to betterALTRADAR - AltLandPos_corection - above_Pad_Suicide.
    lock suicide_burn_altitude to (((GROUNDSPEED + VERTICALSPEED)^2 / aZL) / 2) - Verticalspeed/CONFIG:IPU. //CON.IPU = processing speed
    lock Pressure to BODY:ATM:ALTITUDEPRESSURE(ALTITUDE).
    set  Ship_mass_start to SHIP:MASS.
    lock thrust_G_up_max to MAX(0, MIN(1, (((9.81 * MaxG) + 9.81) * SHIP:MASS) / MAX(0.001, Maxthrust))). //wenn accel nach oben
    
    FOR ENG IN My_Engines {
        lock DeltaVelocity_all to (MAX(1, ENG:ISPAT(Pressure) * 9.8 * ln(SHIP:MASS / SHIP:DRYMASS))).
        lock DeltaVelocity_LB to (MAX(1, ENG:ISPAT(Pressure) * 9.8 * ln((SHIP:MASS - (Ship_mass_start - 113.212)) / 25.212))).
    }

// main Sequence =======================================================================================================
    UNTIL runmode = 0 {
        runmode_changer().
        // ========================================== //
            print "Runmode:                     " + runmode + "     " at (5,2).
            print "betterAltRadar:              " + ROUND(betterALTRADAR) + "    m    " at (5,3).

            print "Throttle:                    " + ROUND(throt,1) + "    %    " at (5,5).
            print "Throttle STABLE:             " + ROUND(throttle_stable,1) + "    %max    " at (5,6).

            print "Ship angle:                  " + ROUND(ship_angle,1) + "    °    " at (5,8).
            print "Ship angle MAX:              " + ROUND(ship_angle_max,1) + "    °max    " at (5,9).

            print "Acceleration DRIFT:          " + ROUND(accel_drift,1) + "    m/s^2    " at (5,11).
            print "Acceleration DRIFT MAX:      " + ROUND(accel_drift_max,1) + "    m/s^2 max    " at (5,12).
            print "Acceleration UP:             " + ROUND(accel_up,1) + "    m/s^2    " at (5,13).
            print "Acceleration UP MAX:         " + ROUND(accel_up_max,1) + "    m/s^2 max    " at (5,14).


        // ========================================== //

        IF runmode = 1 { //

        }
    }    