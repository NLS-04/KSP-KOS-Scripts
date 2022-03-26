copypath("0:/common_lib.ks", "").
run common_lib.ks.
clearScreen.

set aT to 100.
set aSM to 100.
set aI to 100.
set sm to 850000.

parameter runmodeStart.
set runmode to runmodeStart.

until runmode = 0 {

    print "runmde:                  " + runmode at (2,0).
    print "accuracy Periode:        " + ROUND(aT , 3)                               + "  %  " at (2,1).
    print "accuracy semi-major:     " + ROUND(aSM, 3)                               + "  %  " at (2,2).
    print "accuracy inclination:    " + ROUND(aI , 3)                               + "  %  " at (2,3).
    print "Inc:                     " + ROUND(orbit:inclination, 3)                 + "  °  " at (2,4).
    print "SM:                      " + ROUND(orbit:semimajoraxis - body:radius, 2) + "  m  " at (2,5).
    print "Apo:                     " + ROUND(orbit:apoapsis, 2)                    + "  m  " at (2,6).
    print "Peri:                    " + ROUND(orbit:periapsis, 2)                   + "  m  " at (2,7).
    
    
    if runmode = 1 {
        set mother to Vessel(ship:shipname:remove(ship:shipname:find(" Relais"), 7)).

        if mother:connection:isconnected {
            mother:connection:sendmessage("Momy im lonely").

            ship:messages:clear().

            wait until not ship:messages:empty.

            set ship:shipname to ship:messages:pop():content.
            print "Ship Name changed to:    " + ship:shipName at (2,4).

            set runmode to 2.
        }
    }

    if runmode = 2 {
        mother:connection:sendmessage("I wanna be free").

        wait until not ship:messages:empty.

        set mn_time to ship:messages:pop():content - time:seconds.
        print "Maneuver dt:     " + mn_time at (2,5).
        set runmode to 3.
    }

    if runmode = 3 {
        set homannVector to IncChanger(70, mn_time):normalized * hohmann_v1(Body:altitudeof(positionAt(ship, time:seconds + mn_time)), 250000).
        VecToNodeConverter(homannVector, 600).

        print "dV:             " + nextNode:deltav:mag at (2,6).

        set runmode to 4.
    }

    if runmode = 4 {
        if not hasNode {
            set runmode to 7.
        }
    }

    if runmode = 7 {
        set newNode to NODE(Time:seconds + eta:periapsis, 0, 0, DeltaVcirc(orbit:periapsis)).
        add newNode.

        set runmode to 8.
    }

    if runmode = 8 {
        set aT  to 100*orbit:period/(2*constant:pi*sqrt(sm^3 / body:mu)).
        set aSM to 100*orbit:semimajoraxis/sm.
        set aI  to 100*orbit:inclination/70.
    }

    if runmode = 9 {
        set homannVector to IncChanger(70 - orbit:inclination, eta:periapsis):normalized * DeltaVcirc(orbit:periapsis).
        VecToNodeConverter(homannVector, 600).
        
        set runmode to 8.
    }

    if runmode = 10 {
        set homannVector to IncChanger(70 - orbit:inclination, eta:apoapsis):normalized * hohmann_v1(Body:altitudeof(positionAt(ship, time:seconds + eta:apoapsis)), 250000).
        VecToNodeConverter(homannVector, 600).

        set runmode to 4.
    }
}