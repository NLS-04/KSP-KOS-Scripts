copypath("0:/_lib/lib_common.ks", "1:").
copypath("0:/_lib/lib_Terminal.ks", "1:").
copypath("0:/_lib/lib_Executer.ks", "1:").
copypath("0:/_lib/lib_Hohmann.ks", "1:").
copypath("0:/Auriga/Auriga2.ks", "1:").
runOncePath("lib_Common.ks").
runOncePath("lib_Terminal.ks").
runOncePath("lib_Executer.ks").
runOncePath("lib_Hohmann.ks").

switch to 1.

parameter runmodeStart.   

// Variables =======================================
    lock GRAVITY to (body:mu) / (body:radius + ALTITUDE)^2. 
    lock TWR to availablethrust / (mass*GRAVITY).

    list engines in elist.

    set MaxG to 1.
    lock MaxG_Thrust to MAX(0, MIN(1, (((9.81 * MaxG) + 9.81) * MASS) / MAX(0.001, availableThrust))).

// Code ============================================
    // Initialisation
    clearscreen.
    clearVecDraws().

    set terminal:width to 52.
    set terminal:height to 30.
    
    global runmode is runmodeStart.
    set com to "Programm Loaded".
    set abortPossible to true.
    set ctAd to true.
    set ctAs to true.
    set phasingAngle to -1.
    set azi to 0.
    set gravturn to 0.
    
    set steering to ship:facing.
    set throt to 0.
    lock throttle to throt.

    lock dirError to steeringManager:angleerror.
    set dDir to derivative(dirError).

    // defualt setup vals
    set targetApo  to 700000.
    set targetPeri to 700000.
    set targetInc  to 0.
    set targetLAN  to body:rotationangle + ship:geoposition:lng + 2.5.
    set targetAoP  to false. // INOP


    global letprint is true.
    set missionElepsedTime to "T-"+SecondsToClock(0).

    function PrintUpdater {
        set printlistl to list().

        printlistl:add("~~~~~~~~~~~~~~~~~~~~ Auriga III ~~~~~~~~~~~~~~~~~~"                                                 ).
        printlistl:add("Ship Name:               " + ship:name                                                              ).
        printlistl:add("Time:                    " + missionElepsedTime + "        "                                        ).
        printlistl:add("Runmode:                 " + runmode + "        "                                                   ).
        printlistl:add("=================================================="                                                 ).
        printlistl:add("Altitude:                " + ROUND(altitude/1000, 3) + "    km    "                                 ).
        printlistl:add("Apoapsis:                " + ROUND(orbit:apoapsis/1000, 3) + "    km    "                           ).
        printlistl:add("Periapsis:               " + ROUND(orbit:periapsis/1000, 3) + "    km    "                          ).
        printlistl:add("--------------------------------------------------"                                                 ).
        printlistl:add("Eccentricity:            " + ROUND(orbit:eccentricity, 2) + "        "                              ).
        printlistl:add("Inclination:             " + ROUND(orbit:inclination, 2) + "    °    "                              ).
        printlistl:add("Lng of Ascending Node:   " + ROUND(orbit:longitudeofascendingnode, 2) + "    °    "                 ).
        printlistl:add("Argument of Periapsis:   " + ROUND(orbit:argumentofperiapsis, 2) + "    °    "                      ).
        printlistl:add("--------------------------------------------------"                                                 ).
        printlistl:add("Throttle:                " + ROUND(throt,2) + "    %    "                                           ).
        printlistl:add("Dynamic Pressure:        " + ROUND(ship:Q * constant:ATMtokPa, 2) + "    kPa    "                   ).
        printlistl:add("--------------------------------------------------"                                                 ).
        printlistl:add("Direction ERROR:         " + ROUND(VANG(ship:facing:vector, steering:vector), 4) + "    °    "      ).
        printlistl:add("Azimuth:                 " + ROUND(azi, 1) + "    °    "                                            ).
        printlistl:add("Pitch:                   " + ROUND(gravturn, 1) + "    °    "                                       ).
        printlistl:add("--------------------------------------------------"                                                 ).
        printlistl:add("Direction  Acceleration: " + ROUND(dDir(dirError), 3) + "    m/s²    "                              ).
        printlistl:add("Vertical   Acceleration: " + ROUND(dVer(verticalSpeed), 3) + "    m/s²    "                         ).
        printlistl:add("Horizontal Acceleration: " + ROUND(dHor(groundspeed), 3) + "    m/s²    "                           ).
        printlistl:add("--------------------------------------------------"                                                 ).
        printlistl:add("phasingAngle:            " + phasingAngle + "    °    "                                             ).
        printlistl:add("--------------------------------------------------"                                                 ).
        printlistl:add("Comment: " + com + "                                                                            "   ).
        printlistl:add("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"                                                 ).
    }

    until runmode = 0 {

        if letprint {
            PrintUpdater().

            for p in range(0, printlistl:length - 1) {
                print printlistl[p] at (0,p).
            }
        }
        
        if terminal:input:haschar {
            if terminal:input:getchar() = terminal:input:enter {
                global runmode is TerminalInput("runmode").
            }
        }

        if runmode > 0 and runmode < 10 {
            if abortPossible { // ABORT ==========================================================================================================
                if runmode > 4 {
                    set abortPossible to false. // auto-ABORT mechanism disabled
                }

                if VANG(ship:facing:vector, steering:vector) > 10 {
                    if ctAd {
                        set ctA to time:seconds.
                        set ctAd to false.
                    }

                    set com to "! ABORT WARNING ! " + round(5 - (time:seconds - ctA), 3) + " secs until ABORTION!".

                    // log (5 - (time:seconds - ctA)) + " , " + VANG(ship:facing:vector, steering:vector) to abortD.csv.

                    wait 0.

                    if time:seconds - ctA > 5 {
                        set com to "!!! ABORTING !!! DIRECTION ERROR !!!".
                        set abortPossible to false.

                        set runmode to "ABORT".
                        ABORT on.
                        core:deactivate().
                    }
                } else if VANG(ship:facing:vector, steering:vector) < 10 { 
                    set ctA to 0. 
                    set ctAd to true.
                }

                if dVer(verticalSpeed) < -.75*GRAVITY {
                    if ctAs {
                        set ctS to time:seconds.
                        set ctAs to false.
                    }

                    set com to "! ABORT WARNING ! " + round(5 - (time:seconds - ctS), 3) + " secs until ABORTION!".
                    // log (5 - (time:seconds - ctS)) + "," + (dVer(verticalSpeed) +.75*GRAVITY) to abortS.csv.
                    
                    wait 0.
                    
                    if time:seconds - ctS > 5 {
                        set com to "!!! ABORTING !!! VERTICAL ACCELERATION ERROR !!!".
                        set abortPossible to false.

                        set runmode to "ABORT".
                        ABORT on.
                        core:deactivate().
                    }
                } else if dVer(verticalSpeed) > -.9*GRAVITY { 
                    set ctS to 0. 
                    set ctAs to true.
                }

                //on abort {
                //    set com to "!!! ABORTING !!! MANUAL ABORT !!!".
                //    set abortPossible to false.
    //
                //    set runmode to "ABORT".
                //}
            }
            
            if runmode = "ABORT" {
                SAS on.
                RCS on.

                unlock steering.
                unlock throt.
            }

            if runmode = 1 {
                local timeLaunch to time:seconds + waitForLaunch(
                    ship:geoposition:lat,
                    ship:geoposition:lng, 
                    targetInc, 
                    targetLAN
                )[0].

                set timeDelta to timeLaunch - time:seconds.
                set missionElepsedTime to "T-" + SecondsToClock(timeDelta).

                if timeDelta <= 30 { 
                    kuniverse:timewarp:cancelwarp().
                
                    if timeDelta <= 5 {
                        set com to "Control Override".
                        RCS off.
                        SAS off.
                        set steering to lookDirUp(Up:vector, ship:facing:topvector).

                        if timeDelta <= 2 {
                            set com to "Engine startup".
                            set startAlt to altitude.
                            lock throt to MaxG_Thrust.
                            
                            DoSaveStage(). // active engines

                            lock timeDelta to timeLaunch - time:seconds.
                            wait until TWR > 1 and timeDelta <= 0.

                            set com to "Lift-off".
                            lock missionElepsedTime to "T+"+SecondsToClock(missionTime).

                            DoSaveStage(). // unclamp from tower
                            mode(2).  
                        }    
                    }
                }
            }

            else if runmode = 2 {
                if (altitude - startAlt) > 200 {
                    set azi to Azimuth(targetInc).
                    set steering to lookDirUp(Up:vector, North:vector) + R(0,0, azi).
                    
                    if (altitude - startAlt) > 1000 {
                        mode(3).
                    }
                }
            }

            else if runmode = 3 {
                set com to "Launch Pad cleared".

                lock azi to Azimuth(targetInc).
                lock gravturn to GravityTurnPitch(85, 2).
                lock steering to heading(azi, gravturn, 180).

                wait 1.
                set com to "flight Path Initialised".
                wait 1.

                set com to "waiting for: save Apoapsis".
                mode(4).
            }

            else if runmode = 4 {
                if orbit:apoapsis > 30000 {
                    set com to "auto-ABORT mechanism disabled".
                    wait 1.
                    set com to "waiting for: Engine Flame out".

                    DoSaveStage().
                    mode(5).
                }      
            }

            else if runmode = 5 {
                for e in elist {
                    if e:flameout {
                        DoSaveStage().
                        mode(6).
                        break.
                    }
                }
            }

            else if runmode = 6 {
                set com to "Apoapsis is save".

                set steering to ship:facing.
                set throt to 0.

                wait 4.
                mode(7).
            }

            else if runmode = 7 {
                set com to "waiting for: Kármán-line passage".
                set steering to lookDirUp(velocity:orbit, Up:vector).

                if ship:altitude > 70000 {
                    set com to "Kármán-line has been passed".  
                    wait 2.

                    mode(8).
                }
            }

            else if runmode = 8 {
                set com to "Node: Raising Apoapsis to 80 km".
                set alignment80Node to NODE(Time:seconds + eta:apoapsis, 0, 0, hohmann_v1(orbit:apoapsis, 80000) - velocityAt(ship, Time:seconds + eta:apoapsis):orbit:mag).
                add alignment80Node.
                wait 5.

                Executer(alignment80Node).
            }

            else if runmode = 9 {
                set com to "Node: Circularising Apoapsis at 80 km".
                wait 1.
                set circ80Node to NODE(Time:seconds + eta:periapsis, 0, 0, DeltaVcirc(orbit:periapsis)).
                add circ80Node.
                wait 5.

                Executer(circ80Node).
            }

        } else {
// normal operation --------------------------------------------------------------------------------------------------------------
            if runmode = 10 {
                Executer(nextNode).
            }

            else if runmode = 16 {
                local timeHoh is hohmann_time(orbit:semimajoraxis, target:orbit:semimajoraxis).
                local breakBurn is velocityAt(target, timeHoh):orbit - velocityAt(ship, timeHoh):orbit.
                VecToNodeConverter(breakburn, timeHoh).
                set runmode to 10.
            }

            else if runmode = 15 {
                local OrbTarget is target:orbit.

                local targetMean is OrbTarget:MeanAnomalyAtEpoch + 360 * MOD((time:seconds - OrbTarget:epoch) / OrbTarget:period, 1).

                local angleTarget is targetMean + OrbTarget:ArgumentOfPeriapsis + OrbTarget:longitudeofascendingnode.
                local angleChaser is orbit:MeanAnomalyAtEpoch + orbit:ArgumentOfPeriapsis + orbit:longitudeofascendingnode.
                
                set angleTarget to MOD(angleTarget, 360).
                set angleChaser to MOD(angleChaser, 360).

                local phasingAngle is angleTarget - angleChaser.

                local mn_time is time:seconds + hohmann_timing(phasingAngle * constant:degtorad, orbit:semimajoraxis, target:orbit:semimajoraxis).            

                set newNode to NODE(mn_time, 0, 0, hohmann_v1(Body:altitudeof(positionAt(ship, mn_time)), target:orbit:semimajoraxis - body:radius) - velocityAt(ship, mn_time):orbit:mag).
                add newNode.
                set runmode to 10.
            }

            else if runmode = 12 {
                if letprint {
                    clearScreen.
                    set letprint to false.
                }

                if hasTarget {
                    local OrbTarget is target:orbit.
                    local rtarget   is target:position - target:body:position.
                    local targetMean to OrbTarget:MeanAnomalyAtEpoch + 360 * MOD((time:seconds - OrbTarget:epoch) / OrbTarget:period, 1).
                
                    print "TARGET:  " at (0, 2).
                    print "M:       " + targetMean at (2, 3).
                    print "w:       " + OrbTarget:ArgumentOfPeriapsis at (2, 4).
                    print "O:       " + OrbTarget:longitudeofascendingnode at (2, 5).
                    print "I:       " + OrbTarget:inclination at (2, 6).
                    print "t:       " + OrbTarget:epoch at (2, 7).
                    print "------------------------" at (2, 8).
                    print "AoE:     " + MOD(targetMean + OrbTarget:ArgumentOfPeriapsis + OrbTarget:longitudeofascendingnode, 360) at (2, 9).
                    print "AoVE:    " + (vang(rtarget, solarPrimeVector) - OrbTarget:inclination) at (2, 10).
                }

                local rShip     is ship:position - ship:body:position.

                print "SHIP:    " at (0, 12).
                print "M:       " + orbit:MeanAnomalyAtEpoch at (2, 13).
                print "w:       " + orbit:ArgumentOfPeriapsis at (2, 14).
                print "O:       " + orbit:longitudeofascendingnode at (2, 15).
                print "I:       " + orbit:inclination at (2, 16).
                print "t:       " + orbit:epoch at (2, 17).
                print "------------------------" at (2, 18).
                print "AoE:     " + MOD(orbit:MeanAnomalyAtEpoch + orbit:ArgumentOfPeriapsis + orbit:longitudeofascendingnode, 360) at (2, 19).
                print "AoVE:    " + (vang(rShip, solarPrimeVector) - orbit:inclination) at (2, 20).
            }
        }

        if runmode >= 70 and runmode < 80 { // launch configs
            if runmode = 70 {
                global letprint is true.
            }

            if runmode = 71 { // launch setup with Elements
                clearScreen.
                if letprint {
                    global letprint is false.
                }

                print "TARGET ORBIT ELEMENTS:" at (1, 1).
                print "Apo.  [MSL/km]:  " + (targetApo - body:radius)  at (2, 2).
                print "Peri. [MSL/km]:  " + (targetPeri - body:radius) at (2, 3).
                print "Inclination:     " + targetInc  at (2, 4).
                print "LAN:             " + targetLAN  at (2, 5).
                print "Arg. of Periap:  ~~~ INOP ~~~"  at (2, 6).

                local select is ">".

                function spacer {
                    parameter line, col is 18, sel is select.
                    print " " at (col, line).
                    print sel at (col, line +1).
                }

                print select at (18, 2).
                           global targetApo  to getInputs(19, 2):tonumber(targetApo - body:radius) + body:radius.   	  // refer to default vals if unclear
                spacer(2). global targetPeri to getInputs(19, 3):tonumber(targetPeri - body:radius) + body:radius.  	  // refer to default vals if unclear
                spacer(3). global targetInc  to getInputs(19, 4):tonumber(targetInc).                               	  // refer to default vals if unclear
                spacer(4). global targetLAN  to getInputs(19, 5):tonumber(body:rotationangle + ship:geoposition:lng + 10).// refer to default vals if unclear
                print " "   at (14, 5).
                // print select at (13, 6).
                // global targetAoP  to getInputs(17, 6).
                // print " " at (13, 6).

                global letprint is true.
                mode(70).
            }
            else if runmode = 72 { // launch setup with target
                if hasTarget {
                    print "TARGET:  " + target:name at (1, 0).
                    global targetApo  is target:orbit:apoapsis.
                    global targetPeri is target:orbit:periapsis.
                    global targetInc  is target:orbit:inclination.
                    global targetLAN  is target:orbit:LAN.
                    // global targetAoP  is target:orbit:argumentOfPeriapsis.
                }

                mode(71).
            }
            else if runmode = 77 {
                clearScreen.
                set letprint to true.

                mode(78).
            }
            else if runmode = 78 {
                
            }
        }

        if runmode = 88 {
            
        }

        if runmode = 99 {
            unlock steering.
            unlock throttle.
            SAS on.
        }

    }