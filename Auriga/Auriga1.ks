copypath("0:/_lib/common_lib.ks", "").
run common_lib.ks.

parameter runmodeStart.   

// Variables =======================================
    lock GRAVITY to (body:mu) / (body:radius + ALTITUDE)^2. 
    lock TWR to availablethrust / (mass*GRAVITY).

    list engines in elist.

    set MaxG to 1.
    lock MaxG_Thrust to MAX(0, MIN(1, (((9.81 * MaxG) + 9.81) * MASS) / MAX(0.001, maxThrust))).
// Code ============================================
    // Initialisation
    clearscreen.
    set terminal:width to 52.
    set terminal:height to 30.
    clearVecDraws().
    global runmode to runmodeStart.
    set com to "Programm Loaded".
    set abortPossible to true.
    set ctAd to true.
    set ctAs to true.
    set azi to 0.
    set gravturn to 0.
    set steering to ship:facing.
    set targetEcc to 35.
    set throt to 0.
    lock throttle to throt.

    lock dirError to VANG(ship:facing:vector, steering:vector).
    set dDir to derivative(dirError).

    until runmode = 0 {

            print "~~~~~~~~~~~~~~~~~~~~~ Auriga I ~~~~~~~~~~~~~~~~~~~"                                              at (0,1).
            print "Ship Name:               " + ship:name                                                           at (0,2).
            print "Time:                    " + time:clock + " | Year" + time:year + " Day" + time:day + "        " at (0,3).
            print "Runmode:                 " + runmode + "        "                                                at (0,4).
            print "=================================================="                                              at (0,5).
            print "Altitude:                " + ROUND(altitude/1000, 1) + "    km    "                              at (0,6).
            print "Apoapsis:                " + ROUND(orbit:apoapsis/1000, 1) + "    km    "                        at (0,7).
            print "Periapsis:               " + ROUND(orbit:periapsis/1000, 1) + "    km    "                       at (0,8).
            print "--------------------------------------------------"                                              at (0,9).
            print "Eccentricity:            " + ROUND(orbit:eccentricity, 2) + "        "                           at (0,10).
            print "Inclination:             " + ROUND(orbit:inclination, 2) + "    °    "                           at (0,11).
            print "Lng of Ascending Node:   " + ROUND(orbit:longitudeofascendingnode, 2) + "    °    "              at (0,12).
            print "Argument of Periapsis:   " + ROUND(orbit:argumentofperiapsis, 2) + "    °    "                   at (0,13).
            print "--------------------------------------------------"                                              at (0,14).
            print "Throttle:                " + ROUND(throt,2) + "    %    "                                        at (0,15).
            print "Dynamic Pressure:        " + ROUND(ship:Q * constant:ATMtokPa, 2) + "    kPa    "                at (0,16).
            print "--------------------------------------------------"                                              at (0,17).
            print "Direction ERROR:         " + ROUND(VANG(ship:facing:vector, steering:vector), 4) + "    °    "   at (0,18).
            print "Azimuth:                 " + ROUND(azi, 1) + "    °    "                                         at (0,19).
            print "Pitch:                   " + ROUND(gravturn, 1) + "    °    "                                    at (0,20).
            print "--------------------------------------------------"                                              at (0,21).
            print "Direction  Acceleration: " + ROUND(dDir(dirError), 3) + "    m/s²    "                           at (0,22).
            print "Vertical   Acceleration: " + ROUND(dVer(verticalSpeed), 3) + "    m/s²    "                      at (0,23).
            print "Horizontal Acceleration: " + ROUND(dHor(groundspeed), 3) + "    m/s²    "                        at (0,24).
            print "--------------------------------------------------"                                              at (0,25).
            print "Comment: " + com + "                                                                            "at (0,26).
            print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"                                              at (0,27).        


        if abortPossible {
            if VANG(ship:facing:vector, steering:vector) > 10 {
                if ctAd {
                    set ctA to time:seconds.
                    set ctAd to false.
                }

                set com to "! ABORT WARNING ! " + (5 - (time:seconds - ctA)) + " seconds until ABORTION!".

                log (5 - (time:seconds - ctA)) + " , " + VANG(ship:facing:vector, steering:vector) to abortD.csv.

                wait 0.

                if time:seconds - ctA > 5 {
                    set com to "!!! ABORTING !!! DIRECTION ERROR !!!".
                    set abortPossible to false.

                    set runmode to "ABORT".
                    ABORT on.
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

                set com to "! ABORT WARNING ! " + (5 - (time:seconds - ctS)) + " seconds until ABORTION!".
                log (5 - (time:seconds - ctS)) + "," + (dVer(verticalSpeed) +.75*GRAVITY) to abortS.csv.
                
                wait 0.
                
                if time:seconds - ctS > 5 {
                    set com to "!!! ABORTING !!! VERTICAL ACCELERATION ERROR !!!".
                    set abortPossible to false.

                    set runmode to "ABORT".
                    ABORT on.
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
            set com to "Vehicle Initialisation".
            set startAlt to altitude.

            lock steering to lookDirUp(Up:vector, -North:vector).

            RCS on.
            SAS off.

            lock throt to MaxG_Thrust.

            DoSaveStage().
            
            if TWR > 1 {
                DoSaveStage().
                set runmode to 2.  
            }
        }

        if runmode = 2 {
            if (altitude - startAlt) > 200 {
                lock steering to lookDirUp(Up:vector, -North:vector) + R(0,0,-90).
                
                if (altitude - startAlt) > 1000 {
                    set runmode to 3.
                }
            }
        }

        if runmode = 3 {
            set com to "Launch Pad cleared".

            lock azi to Azimuth(targetEcc).
            lock gravturn to MIN(90, MAX(45, GravityTurnPitch(1, 12, 85, 45))) + MIN(45, MAX(5, GravityTurnPitch(10, 50, 45, 5))) - 45.
            lock steering to heading(azi, gravturn, 180).

            wait 1.
            set com to "flight Path Initialised".
            wait 1.

            set runmode to 4.
        }

        if runmode = 4 {
            for e in elist {
                if e:tag = "SB" {
                    set bossterTWR to e:availablethrust/( GRAVITY * (e:mass + 0.42)).
                }
            }

            if bossterTWR < 1 {
                DoSaveStage().

                set runmode to 5.
            }
        }

        if runmode = 5 {
            set com to "waiting for: save Apoapsis".
            
            if orbit:apoapsis > 30000 {
                set abortPossible to false. // auto-ABORT mechanism disabled
                set com to "auto-ABORT mechanism disabled".
                DoSaveStage().

                set runmode to 6.
            }      
        }

        if runmode = 6 { 
            if orbit:apoapsis > 75000 {
                set com to "Apoapsis is save".
                
                set throt to 0.
                set runmode to 7.
            }
        }

        if runmode = 7 {
            set com to "waiting for: Kármán-line passage".
            if ship:altitude > 70000 {
                set com to "Kármán-line has been passed".  
                wait 2.

                set runmode to 8.
            }
        }

        if runmode = 8 {
            set com to "Node: Raising Apoapsis to 80 km".
            set alignment80Node to NODE(Time:seconds + eta:apoapsis, 0, 0, hohmann_v1(orbit:apoapsis, 80000) - velocityAt(ship, Time:seconds + eta:apoapsis):orbit:mag).
            add alignment80Node.
            wait 5.

            Executer(alignment80Node).
        }

        if runmode = 9 {
            set com to "Node: Circularising Apoapsis at 80 km".
            wait 1.
            set circ80Node to NODE(Time:seconds + eta:apoapsis, 0, 0, DeltaVcirc(orbit:apoapsis)).
            add circ80Node.
            wait 5.

            Executer(circ80Node).
        }

        if runmode = 10 {
            set com to "End Initialisation".

            DoSaveStage().

            RCS on.
            SAS on.

            unlock throt.
            unlock steering.

            wait until (VANG(ship:facing:vector, steering:vector) < 1).
            set runmode to 99.
        }

        if runmode = 11 {
            unlock steering.
            unlock throttle.
            
            set runmode to 99.
        }
    }