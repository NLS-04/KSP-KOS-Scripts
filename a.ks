set config:ipu to 2000.
clearScreen. 
clearVecDraws().

runOncePath("0:_lib/Rendezvous.ks").
// #include "0:_lib/Rendezvous.ks"

translationPIDs(20, 10).

local count is 16.

for i in range(3) {
    print " "+ round(FTS_Vel_PIDs[i][0]:kp, 3) + ", " + round(FTS_Vel_PIDs[i][0]:ki, 3) + ", " + round(FTS_Vel_PIDs[i][0]:kd, 3) + ", " + FTS_Vel_PIDs[i][0]:minoutput + ", " + FTS_Vel_PIDs[i][0]:maxoutput at (0, count).
    print "" + round(FTS_Vel_PIDs[i][1]:kp, 3) + ", " + round(FTS_Vel_PIDs[i][1]:ki, 3) + ", " + round(FTS_Vel_PIDs[i][1]:kd, 3) + ", " + FTS_Vel_PIDs[i][1]:minoutput + ", " + FTS_Vel_PIDs[i][1]:maxoutput at (0, count+1).

    print " "+ round(FTS_Pos_PIDs[i][0]:kp, 3) + ", " + round(FTS_Pos_PIDs[i][0]:ki, 3) + ", " + round(FTS_Pos_PIDs[i][0]:kd, 3) + ", " + FTS_Pos_PIDs[i][0]:minoutput + ", " + FTS_Pos_PIDs[i][0]:maxoutput at (0, count+7).
    print "" + round(FTS_Pos_PIDs[i][1]:kp, 3) + ", " + round(FTS_Pos_PIDs[i][1]:ki, 3) + ", " + round(FTS_Pos_PIDs[i][1]:kd, 3) + ", " + FTS_Pos_PIDs[i][1]:minoutput + ", " + FTS_Pos_PIDs[i][1]:maxoutput at (0, count+8).

    set count to count + 2.
}

local portT is target:dockingports[0].
local portS is ship:dockingports[0].

local point is 5*portT:portfacing:forevector.

local startPos is portS:position. 
local endPos is portT:position + point.

local VDdelPos is vecDraw(startPos, endPos, blue, "dP", 1, true, .2).
local VDdelTgt is vecDraw(endPos, point, red, "dT", 1, true, .2).
local VDdelVel is vecDraw(startPos, endPos, yellow, "dV", 1, true, .2).

set VDdelPos:startupdater to { return startPos. }.
set VDdelPos:vecupdater to { return endPos. }.

set VDdeltgt:startupdater to { return portT:position. }.
set VDdeltgt:vecupdater to { return point. }.

set VDdelVel:startupdater to { return startPos. }.

local F is 0.
local T is 0.
local S is 0.

until AG10 {
    set startPos to portS:position. 
    set endPos to portT:position + point - startPos.

    local dP is startPos - endPos.
    local dV is ship:velocity:orbit - Target:velocity:orbit.

    local dVComp is Vec2Ship(dV).
    local dPComp is Vec2Ship(dP).

    set VDdelVel:vector to 5*dV.

    // perform_Vel( dVComp ).
    // perform_Pos( dPComp, dVComp ).

    if AG9 {
        set F to 0.
        set T to 0.
        set S to 0.
        AG9 off. AG10 on.
    } if AG6 {
        set F to F + (choose .1 if AG4 else 1)*(choose -1 if AG5 else 1).
        AG6 off. AG10 on.
    } if AG7 {
        set T to T + (choose .1 if AG4 else 1)*(choose -1 if AG5 else 1).
        AG7 off. AG10 on.
    } if AG8 {
        set S to S + (choose .1 if AG4 else 1)*(choose -1 if AG5 else 1).
        AG8 off. AG10 on.
    }

    if AG10 {
        set point to T*ship:facing:topvector + S*ship:facing:starvector.
        // set_Vel( list( F, T, S ) ).
        // set_Pos( list( F, T, S ) ).
        AG10 off.
    }

    perform_VePo( list( list( F, "", "" ), list( "", point:y, point:z ) ) , dPComp, dVComp ).

    local adj is 0.

    print "dP " + round(dP:mag, 3) + " m "at(2, 2+adj).

    print "F   " + round(dPComp[0], 3) + " m " at(2, 3+adj).
    print "T   " + round(dPComp[1], 3) + " m " at(2, 4+adj).
    print "S   " + round(dPComp[2], 3) + " m " at(2, 5+adj).
    print "Eps " + round(FTS_Vel_PIDs[0][0]:epsilon, 3) + " , " + round(FTS_Pos_PIDs[0][0]:epsilon, 3) + "    " at(2, 6+adj).

    print round(dVComp[0], 3) + " m/s      " at(16, 3+adj).
    print round(dVComp[1], 3) + " m/s      " at(16, 4+adj).
    print round(dVComp[2], 3) + " m/s      " at(16, 5+adj).

    for i in range(3) {
        print "P F  S " + round(FTS_Pos_PIDs[i][0]:setpoint, 3) + " E " + round(FTS_Pos_PIDs[i][1]:error, 3) + "        " at(2, i+8+adj).
        print "O ( " + round(FTS_Pos_PIDs[i][0]:output, 3) + " , " + round(FTS_Pos_PIDs[i][1]:output, 3) + " )        " at(23, i+8+adj).

        print "V F  S " + round(FTS_Vel_PIDs[i][0]:setpoint, 3) + " E " + round(FTS_Vel_PIDs[i][1]:error, 3) + "        " at(2, i+12+adj).
        print "O ( " + round(FTS_Vel_PIDs[i][0]:output, 3) + " , " + round(FTS_Vel_PIDs[i][1]:output, 3) + " )        " at(23, i+12+adj).
    }
}