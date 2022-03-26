copypath("0:/_lib/Common.ks", "1:").
copypath("0:/_lib/Common.ks", "1:").
copypath("0:/_lib/Executer.ks", "1:").
runOncePath("0:_lib/Common.ks").
runOncePath("0:_lib/Hohmann.ks").
runOncePath("0:_lib/Executer.ks").
// #include "0:/_lib/Common.ks"
// #include "0:/_lib/Hohmann.ks"
// #include "0:/_lib/Executer.ks"

parameter runmodeStart.   
    
// Variables =======================================
    LIST ENGINES IN elist.
    
    lock pressure to body:atm:altitudepressure(ship:altitude).
    
    set thrlistl to list().
    set thr to 0.

    FOR ENG IN elist {
        lock DeltaVelocity_all to (MAX(1, ENG:ISPAT(Pressure) * constant:g0 * ln(SHIP:MASS / SHIP:DRYMASS))).
    }

    set ti to terminal:input.

    lock GRAVITY to (body:mu) / (body:radius + ALTITUDE)^2. 
    lock Fg to ship:mass * GRAVITY.
    lock TWRp to thr / Fg.
    lock TWR to ship:availablethrust / Fg.

// Code ============================================
    // Initialisation
    clearscreen.
    set terminal:width to 52.
    set terminal:height to 25.
    clearVecDraws().
    global runmode to runmodeStart.
    set com to "Programm Loaded".
    set azi to 0.
    set gravturn to 0.
    set steering to ship:facing.
    set throt to 0.
    lock throttle to throt.


    set targetEcc to 90.


    until runmode = 0 {

        if ti:haschar {
            if ti:getchar() = ti:enter {
                print "check" at (25,25).

                set initialRunmode to runmode.

                set runmode to  ">>__<<".

                set ch0 to terminal:input:getchar().
                set runmode to  ">>" + ch0 + "_<<".

                set ch1 to terminal:input:getchar().
                set runmode to  ">>" + ch0 + ch1 + "<<".

                set ch to (ch0+ch1):tonumber(0).

                set check to terminal:input:getchar().

                if check = terminal:input:enter {
                    set runmode to ch.
                } else if check = terminal:input:backspace {
                    set runmode to initialRunmode.
                } 
            }
        }
        
        set thr to 0.

        for eng in elist {
            set thr to thr + eng:thrust.
        }

        print "~~~~~~~~~~~~~~~~~~~~ InVision ~~~~~~~~~~~~~~~~~~~~"                                              at (0,0).
        print "Ship Name:               " + ship:name                                                           at (0,1).
        print "Time:                    " + time:clock + " | Year" + time:year + " Day" + time:day + "        " at (0,2).
        print "Runmode:                 " + runmode + "        "                                                at (0,3).
        // print "Has Range to:            " + antM:getfield("target") + "                               "         at (0,4).
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
        print "Comment: " + com + "                                                                            "at (0,22).
        print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"                                              at (0,23).

        if runmode = 1 {
            set com to "Vehicle Initialisation".
            set startAlt to altitude.
            set topvec to ship:facing:topvector.

            lock steering to lookDirUp(Up:vector, topvec).

            RCS on.
            SAS off.
            
            DoSaveStage().
            set runmode to 2.  
        }

        if runmode = 2{
            if TWRp > 1 {
                DoSaveStage().
                set runmode to 3.
            }
        }

        if runmode = 3{
            if (altitude > startalt + 1000) {
                set com to "Launch Pad cleared".

                lock azi to Azimuth(targetEcc).
                lock gravturn to GravityTurnPitch(75000, 500, 1000, 85).
                lock steering to heading(azi, gravturn, 0).

                wait 1.
                set com to "flight Path Initialised".
                wait 1.
                set runmode to 4.
            }
        }

        if runmode = 4 {
            set com to "waiting for: solid engine flameout".

            wait 0.

            if thr/Fg < 1 {
                RCS on.
                lock steering to lookDirUp(velocity:surface, Up:vector).
                DoSaveStage().

                list engines in elist.
                set runmode to 5.
            }            
        }

        if runmode = 5 { 
            set com to "waiting for: save Apoapsis".
            if orbit:apoapsis > 75000 {
                set com to "Apoapsis is save".
                
                set throt to 0.
                set runmode to 6.
            } else { 
                set throt to 1.
            }
        }

        if runmode = 6 {
            set com to "waiting for: Kármán-line passage".
            if ship:altitude > 65000 {
                set com to "Kármán-line has been passed".  
                DoSaveStage().
                wait 2.
                set com to "Fairings have been jettisoned".
                wait 5.

                set runmode to 7.
            }
        }

        if runmode = 7 {
            set com to "Node: Raising Apoapsis to 80 km".
            set alignment80Node to NODE(Time:seconds + eta:apoapsis, 0, 0, hohmann_v1(orbit:apoapsis, 80000) - velocityAt(ship, Time:seconds + eta:apoapsis):orbit:mag).
            add alignment80Node.
            wait 5.

            Executer(alignment80Node).
        }

        if runmode = 8 {
            set com to "Node: Circularising Apoapsis at 80 km".
            wait 1.
            set circ80Node to NODE(Time:seconds + eta:apoapsis, 0, 0, DeltaVcirc(orbit:apoapsis)).
            add circ80Node.
            wait 5.

            Executer(circ80Node).
        } 
        // NORMAL OPERATION ----------------------------------------------------------------------------------------------------------------------------------------------------------------

        if runmode = 11 {
            
        }

        if runmode = 12 {

        }
    }