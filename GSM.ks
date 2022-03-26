copypath("0:/common_lib.ks", "").
run common_lib.ks.
clearScreen.
ship:messages:clear().

parameter runmodeStart.

list volumes in volumesListl.
set timinglistl to list().

set babyUnIdent to Ship:shipname + " Relais".
set ti to terminal:input.

//set volumesAmount to volumesListl:length.
set volumesAmount to 8.

set nextSep to 0.

set runmode to runmodeStart.

until runmode = 0 {

    for t in timinglistl {
        if not timinglistl:length = 0 {
            if t - time:seconds > 0 {
                set nextSep to t.
                break.
            } else {
                timinglistl:remove(0).
                print "["+(timinglistl:length)+"] " + "D--|--:--:--" + " / " + "--:--:--" at (1,(timinglistl:length)).
                break.
            }
        }
    }

    for line in range(0,timinglistl:length) {
        print "["+line+"] " + SecondsToClock(ROUND(timinglistl[line], 3)) + " / " + SecondsToClock(ROUND(timinglistl[line] - time:seconds, 2)) at (1,line).
    }

    print "runmode:             " + runmode at (2,10).
    print "Next Seperation in:  " + SecondsToClock(ROUND(nextSep - time:seconds, 2)) at (2,11).
    print "Time:                " + time:clock at (2,12).

   
    if not ship:messages:empty {
        set sender to ship:messages:peek():sender.

        print sender:shipName+": " + ship:messages:peek():content at (2,9).

        if sender:shipname = babyUnIdent {
            print ship:name + " Baby " + (volumesAmount - timinglistl:length + 1) at (20,20).
            sender:connection:sendmessage(ship:name + " Baby " + (volumesAmount - timinglistl:length + 1)). // Name assigning the baby
            ship:messages:pop().
        } else {
            sender:connection:sendmessage(nextSep). // send maneuver time for baby
            ship:messages:pop().
        }
    }



    if runmode = 1 {
        set newNode to NODE(Time:seconds + eta:periapsis, 0, 0, hohmann_v1(Body:altitudeof(positionAt(ship, time:seconds + eta:periapsis)) - body:radius, 8500000)).
        add newNode.

        wait until not hasNode.
        set runmode to 2.
    }

    if runmode = 2 {
        set newNode to NODE(Time:seconds + eta:apoapsis, 0, 0, DeltaVcirc(orbit:apoapsis)).
        add newNode.

        wait until not hasNode.
        set runmode to 3.
    }

    if runmode = 3 {
        set period to 2*constant:pi*sqrt(orbit:semimajoraxis^3 / Body:mu).
        set dSepTime to ROUND(period/volumesAmount).
        print "dSepTime:        " + SecondsToClock(dSepTime) at (3,16).
        
        set startoperation to ROUND(time:seconds + 360).

        log startoperation + "," + dSepTime to save.csv.
        log "-------------------------" to save.csv.

        set runmode to 4.
    }

    if runmode = 4 {
        for t in range(1, volumesAmount + 1) {
            timinglistl:add(startoperation + t*dSepTime).
        }

        set runmode to 5.
    }

    if runmode = 6 {
        set chars to list().
        set ch to 0.
        set goOn to false.
        set l to 20.
        print "startOperation:  " at (1,5).

        until goOn {
            set ch0 to ti:getchar().
            print ch0 at (l,5).

            if ch0 = ti:enter {
                set goOn to true.
            } else {
                chars:add(ch0).
                set l to l+1.
            }
        }

        for a in chars {
            set ch to ch + a.
        }  

        set startoperation to ch:tostring():tonumber().

        chars:clear().

        set runmode to 7.
    }

    if runmode = 7 {
        set chars to list().
        set ch to 0.
        set goOn to false.
        set l to 20.
        print "dSepTime:        " at (1,6).

        until goOn {
            set ch0 to ti:getchar().
            print ch0 at (l,6).

            if ch0 = ti:enter {
                set goOn to true.
            } else {
                chars:add(ch0).
                set l to l+1.
            }
        }

        for a in chars {
            set ch to ch + a.
        } 

        set dSepTime to ch:tostring():tonumber().

        chars:clear().

        set runmode to 4.
    }

}
