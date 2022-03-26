copypath("0:/common_lib.ks", "").
run once common_lib.ks.

set config:stat to true.

parameter runmodeStart is 1, submodeStart is 0.   

// Ttarget ============================================
    set Launch_Pad to latlng(-0.0972, -74.5575).
    set VAB        to latlng(-0.0968, -74.6188).
    set LandingPadCenter to latlng(-0.0979, -74.4739). // is group projected position into Geoposition
    set LandingPadNorth  to ship:body:geopositionof(LandingPadCenter:position + vecToLocal(V(76,  132, 0))). //group Center offset
    set LandingPadSouth  to ship:body:geopositionof(LandingPadCenter:position + vecToLocal(V(76, -132, 0))). //group Center offset

    set targetlocation to Launch_Pad.
    //set targetlocation to VAB.
    //set targetlocation to grass1.
    //set targetlocation to grass2.
    //set targetlocation to grass3.

// Vectors ===========================================================
    lock relpos to targetlocation:position - ship:position.
    lock relimpact to targetlocation:position - impactPos:position.
    lock vel to ship:velocity:surface.
    set east to vCrs(Up:vector, north:vector).

// Variables =======================================
    set trAdd to addons:tr.
    set impactPos to ship:geoposition.
    
    set mu to body:mu.
    set radius to body:radius.
    lock GRAVITY to mu / (radius + ALTITUDE)^2. 

    lock alpha to VANG(up:vector, ship:facing:vector).
    lock maxAlpha to arccos( min(1, (mass*GRAVITY) / max((mass*GRAVITY), availableThrust))).
    lock maxVang to min(maxAlpha, relimpact:mag*80/500). // 500 is pivot based on dist

    lock TWR to maxThrust / (mass*GRAVITY).
    lock corrThrot to ((mass*GRAVITY) / cos(alpha)) / maxThrust.

    list engines in elist.

    set MaxG to 1.
    lock MaxG_Thrust to MAX(0, MIN(1, (((9.81 * MaxG) + 9.81) * MASS) / MAX(0.001, availableThrust))).

// Vector Draws ======================================================

// Code ============================================
    // Initialisation
        set throttle to 0.
        set steering to lookDirUp(up:vector, north:vector).

        clearscreen.
        clearVecDraws().

        set terminal:width to 60.
        set terminal:height to 50.
        
        set runmode to runmodeStart.
        set submode to submodeStart.
        set com to "Programm Loaded".

    //Terminal out
    function PrintUpdater {
        set printlistl to list().

        //printlistl:add("~~~~~~~~~~~~~~~~~~~ Gras Hoper ~~~~~~~~~~~~~~~~~~~"                                                 ).
        //printlistl:add("Ship Name:               " + ship:name                                                              ).
        //printlistl:add("Time:                    " + time:clock + " | Year" + time:year + " Day" + time:day + "        "    ).
            //printlistl:add("runmode:                   " + runmode + "        "                                                   ).
            //printlistl:add("submode:                   " + submode + "        "                                                   ).
        //printlistl:add("=================================================="                                                 ).
        //printlistl:add("Altitude:                " + ROUND(altitude/1000, 3) + "    km    "                                 ).
        //printlistl:add("--------------------------------------------------"                                                 ).
        //printlistl:add("Throttle:                " + ROUND(throttle,2) + "    %    "                                           ).
        //printlistl:add("Dynamic Pressure:        " + ROUND(ship:Q * constant:ATMtokPa, 2) + "    kPa    "                   ).
        //printlistl:add("--------------------------------------------------"                                                 ).
        ////printlistl:add("Direction ERROR:         " + ROUND(VANG(ship:facing:vector, steering:vector), 4) + "    °    "      ).
        ////printlistl:add("Azimuth:                 " + ROUND(azi, 1) + "    °    "                                            ).
        ////printlistl:add("Pitch:                   " + ROUND(gravturn, 1) + "    °    "                                       ).
        ////printlistl:add("--------------------------------------------------"                                                 ).
        ////printlistl:add("Direction  Acceleration: " + ROUND(dDir(dirError), 3) + "    m/s²    "                              ).
        ////printlistl:add("Vertical   Acceleration: " + ROUND(dVer(verticalSpeed), 3) + "    m/s²    "                         ).
        ////printlistl:add("Horizontal Acceleration: " + ROUND(dHor(groundspeed), 3) + "    m/s²    "                           ).
        //printlistl:add("--------------------------------------------------"                                                 ).
        //printlistl:add("Comment: " + com + "                                                                            "   ).
        //printlistl:add("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"                                                 ).

        printlistl:add(""                                                                                                            ).
        printlistl:add("Alpha:                          " + round(alpha) + "        "                                                        ).
        printlistl:add("max Alpha:                      " + round(maxAlpha) + "        "  ).
        printlistl:add("max Vang:                       " + round(maxVang) + "        "  ).
        printlistl:add("real dist Mag:                  " + round(relpos:mag, 2) + "           "  ).
        printlistl:add("real dist(east, north, ver):    " + round(vecToLocal(relpos):x, 2) + ", " + round(vecToLocal(relpos):y, 2) + ", " + round(vecToLocal(relpos):z, 2) + "              "  ).
        printlistl:add(""                                                                                                             ).
        printlistl:add("impact dist Mag:                " + round(relimpact:mag, 2) + "             "  ).
        printlistl:add("impact dist(east, north):       " + round(vecToLocal(relimpact):x, 2) + ", " + round(vecToLocal(relimpact):y, 2) + "                 "  ).
        printlistl:add(""                                                                                                             ).
        printlistl:add("Steer (pitch, yaw, roll):       " + round(steering:pitch) + ", " + round(steering:yaw) + ", " + round(steering:roll) + "                 "  ).
        printlistl:add("Face  (pitch, yaw, roll):       " + round(ship:facing:pitch) + ", " + round(ship:facing:yaw) + ", " + round(ship:facing:roll) + "                 "  ).
        printlistl:add(""                                                                                                             ).
        printlistl:add("Heading:                        " + round(geodir(targetlocation, impactPos)) + "     "                                                      ).
        printlistl:add(""                                                                                                             ).

        for a in range(0, printlistl:length) {
            print printlistl[a] at (0,a + 1).
        }
    }

//Loop
until runmode = 0 {
    // Terminal stuff
        PrintUpdater().
        
        if terminal:input:haschar {
            if terminal:input:getchar() = terminal:input:enter {
                set runmode to TerminalInput("runmode").
            }
        }

        set impactPos to choose trAdd:impactPos if trAdd:hasimpact else ship:geoposition.
    
    // Other looping variables

    // Code ==============================================================
        if runmode = 1 {
            //set config:ipu to 1000.
            lock throttle to 0.
            lock steering to "kill".
            
            SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
            SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
            
            wait .1.

            unlock throttle.
            unlock steering.

            set runmode to "µ".
        }

        if runmode = 2 { // for testing
            for part in ship:parts {
                log part to ght2.csv.
                log "   modules:" to ght2.csv.
                for module in part:modules {
                    log "       " + module to ght2.csv.
                    log "           fields:" to ght2.csv.
                        for field in part:getmodule(module):allfields {
                            log "               " + field to ght2.csv.
                        }
                    log "           events:" to ght2.csv.
                        for event in part:getmodule(module):allevents {
                            log "               " + event to ght2.csv.
                        }
                    log "           actions:" to ght2.csv.
                        for action in part:getmodule(module):allactions {
                            log "               " + action to ght2.csv.
                        }
                }
            }

            set runmode to "µ".
        }

        if runmode >= 3 and runmode <= 7 {
            if not (defined intialized37) {
                //set starttime to time:seconds.

                GEAR off.
                SAS off.
                RCS on.

                landingPIDs().

                set intialized37 to 1.
                set submode to 1.
                set comment to "initialized".
            }

                if runmode = 3 {
                    set targetlocation to Launch_Pad.
                } else if runmode = 4 {
                    set targetlocation to VAB.
                } else if runmode = 5 {
                    set targetlocation to LandingPadCenter.
                } else if runmode = 6 {
                    set targetlocation to LandingPadNorth.
                } else if runmode = 7 {
                    set targetlocation to LandingPadSouth.   
                }

            lexiprinter( 
                lexicon(
                    "runmode"           , runmode + "           ",
                    "submode"           , submode + "           ",
                    "steerMode cold hot", landingSteer(targetlocation, false)["steerMode"] + ", " + landingHotSteer(targetlocation, false)["steerMode"],
                    "comment"           , comment + "           ",
                    "-------"           , "-------",
                    "burnAlt"           , (choose burnAlt if defined burnAlt else "---"),
                    "error"             , altitude - (choose burnAlt if defined burnAlt else 0) - (choose skip if defined skip else 0), 
                    "-------"           , "-------",
                    "c1B throttle"      , (choose c1B if defined c1B else "---"),
                    "c1B offset"        , (choose offseting if defined offseting else "---"),
                    "verticalspeed"     , verticalSpeed,
                    "-------"           , "-------",
                    "dist"              , relimpact:mag
                )
            , printlistl:length + 1, 5).

            lexiprinter	(landingLoger()["lexo"], printlistl:length + 14, 5).
            
            if submode = 1 {
                if trueRadar() > 0 and not (defined s1) {
                    landingPIDs().

                    landingMaxSteerAngle(maxAlpha * .5).
                    landingMaxHorSpeed(100).

                    set s1 to true.
                }

                set throttle to MaxG_Thrust.
                landingVelSteer(0).

                if apoapsis > 20000 { 
                    set throttle to 0.

                    if relimpact:mag < 25 { 
                        set comment to "Glide nominal".  
                        set submode to 3.
                    } else { set submode to 2. }
                }
            }
            
            if submode = 2 { 
                if not (defined s2) {
                    landingPIDs().

                    landingMaxHorSpeed(50).

                    set s2 to true.
                }
                landingMaxSteerAngle(maxVang).

                suicideStarter(runmode, 4).

                local atmoExist is body:atm:exists.
                local vertiVel is verticalSpeed.

                if relimpact:mag < 25 { 
                    set comment to "Glide nominal".
                    set throttle to 0.
                    set submode to 3.
                } else {
                    if atmoExist and vertiVel < 100 and vertiVel > 0 {
                        set comment to "correction phase POSITIV SPEEDY".
                        set submode to 2.1.
                    } else if atmoExist and vertiVel < 0 and vertiVel > -50 {
                        set comment to "correction phase NEGATIV SPEEDY".
                        set submode to 2.2.
                    } else if atmoExist {
                        set comment to "correction phase WET".
                        landingSteer().
                        set throttle to 0.
                    } else {
                        set comment to "correction phase DRY".
                        set submode to 2.3.
                    }
                }
            }

            if submode > 2 and submode < 3 {
                suicideStarter(runmode, 4).

                if relimpact:mag < 25 { 
                    set comment to "Glide nominal".
                    set throttle to 0.
                    set submode to 3.
                } else {
                    if submode = 2.1 {
                        set steering to heading(geodir(targetlocation, impactPos), 75).
                        set throttle to 0.0005 * relimpact:mag.
                    }
                    if submode = 2.2 {
                        set steering to heading(geodir(targetlocation, impactPos), 75).
                        set throttle to 1/corrThrot + 0.001 * relimpact:mag.
                    }
                    if submode = 2.3 {
                        set steering to relimpact.
                        set throttle to 0.001 * relimpact:mag.
                    }
                }
            }

            if submode = 3 {
                if not (defined s3) {
                    landingPIDs().
                    set startTime to time:seconds.

                    landingMaxHorSpeed(100).

                    set s3 to true.
                }                
                suicideStarter(runmode, 4).

                landingMaxSteerAngle(maxVang).
                landingSteer().  
            }

            if submode = 4 {
                if not (defined s4) {
                    set comment to "Burn started".
                    //set startTime to time:seconds.

                    set offseting to .75 * ((GRAVITY * trueRadar() + .5 * vel:mag^2) / ((availableThrust / mass - GRAVITY) * trueRadar()) - 1).

                    set config:ipu to 2000.

                    landingPIDs().

                    landingMaxHorSpeed(50).

                    set s4 to true.
                }
                landingMaxSteerAngle(maxVang).
                landingHotSteer().

                set c1B to (GRAVITY * trueRadar() + .5 * vel:mag^2) / ((availableThrust / mass - GRAVITY) * trueRadar()) - offseting.

                log time:seconds - startTime +" "+ vel:mag +" "+ trueRadar() +" "+ suicide():alt +" "+ c1B to ght1.csv. 

                set throttle to c1B.

                if verticalSpeed > -100 {
                    GEAR on.
                    set config:ipu to 1000.

                    if relimpact:mag > 100 {
                        set comment to "-100 NOT nominal".                        
                        set submode to 6.
                    } else {
                        set comment to "-100 nominal".
                        landingMaxSteerAngle(5).
                        landingSteer().    
                        
                        if verticalSpeed > -25 {
                            landingPIDs().
                            landingMaxVerticalSpeed(25).

                            set submode to 5.
                        }
                    }
                }
            }

            if submode = 5 {
                landingMaxSteerAngle(maxAlpha * .5).
                landingSteer().

                if relimpact:mag < 5 {
                    set comment to "on target".
                    landingAltThrottle(-0.1).
                } else {
                    set comment to "drifting to target".
                   landingAltThrottle(landingAltController(relimpact:mag, 10, 60, 4)).
                }
            }

            if submode = 6 {
                landingVelSteer().
                landingAltThrottle(-0.1).
            }

            if (SHIP:STATUS = "Landed" or SHIP:STATUS = "splashed") and (submode = 5 or submode = 6) {
                set intialized37 to 1.
                unset intialized37.

                lock throttle to 0.
                lock steering to "kill".

                SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
                SET SHIP:CONTROL:NEUTRALIZE TO TRUE.

                wait 2.

                unlock throttle.
                unlock steering.

                set runmode to 0.
                set submode to 0.
            }

            set vT_Up to vecDraw(targetlocation:position, 20 * Up:vector, RGB(0,0,1), "Target", 1, true, .5).
            set v_relpos to vecDraw(V(0,0,0), relpos, RGB(1,1,0), "error", 1, true, .2, false).
            
            set v_Vel       to vecDraw(V(0,0,0),  ship:velocity:surface, RGB(1,0,0), "vel", 1, true, .2).
            set v_InversVel to vecDraw(V(0,0,0), -22*ship:velocity:surface:normalized, RGB(.5,.25,0), "invers Vvl", 1, true, .1).
            set v_steer to vecDraw(V(0,0,0), 20 * (choose steering if steering:istype("vector") else steering:vector), RGB(1,1,1), "Steering", 1, true, .2).
            
            set v_eR to vecDraw(V(0,0,0), 16 * landingSteer(targetlocation, false)["eRvec"]:normalized, RGB(1,0,1), "eRot " + round(landingLoger()["lexo"]["eVoutput"]), 1, true, .2).
            set v_nR to vecDraw(V(0,0,0), 16 * landingSteer(targetlocation, false)["nRvec"]:normalized, RGB(0,1,1), "nRot " + round(landingLoger()["lexo"]["nVoutput"]), 1, true, .2).
        }

        if runmode = 8 {
            if not (defined s8) {
                landingPIDs().
                landingMaxVerticalSpeed(10).
                landingMaxHorSpeed(50).
                
                set s8 to true.
            }
            landingMaxSteerAngle(maxAlpha*.5).

            landingAltThrottle(100).
            landingSteer().

            set vT_Up to vecDraw(targetlocation:position, 20 * Up:vector, RGB(0,0,1), "Target", 1, true, .5).
            set v_relpos to vecDraw(V(0,0,0), relpos, RGB(1,1,0), "error", 1, true, .2, false).
            
            set v_Vel       to vecDraw(V(0,0,0),  ship:velocity:surface, RGB(1,0,0), "vel", 1, true, .2).
            set v_InversVel to vecDraw(V(0,0,0), -22*ship:velocity:surface:normalized, RGB(.5,.25,0), "invers Vvl", 1, true, .1).
            set v_steer to vecDraw(V(0,0,0), 20 * (choose steering if steering:istype("vector") else steering:vector), RGB(1,1,1), "Steering", 1, true, .2).
            
            set v_eR to vecDraw(V(0,0,0), 16 * landingSteer(targetlocation, false)["eRvec"]:normalized, RGB(1,0,1), "eRot " + round(landingLoger()["lexo"]["eVoutput"]), 1, true, .2).
            set v_nR to vecDraw(V(0,0,0), 16 * landingSteer(targetlocation, false)["nRvec"]:normalized, RGB(0,1,1), "nRot " + round(landingLoger()["lexo"]["nVoutput"]), 1, true, .2).

        }

}

if runmode = 0 {
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
    
    SAS on.
    RCS off.

    clearScreen.
    clearVecDraws().

    log profileResult() to profileResults.csv.    
}