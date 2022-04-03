// libary imports
copypath("0:/_lib/Common.ks"     , "1:"). runOncePath("1:Common.ks").       // #include "0:/_lib/Common.ks"
copypath("0:/_lib/Terminal.ks"   , "1:"). runOncePath("1:Terminal.ks").     // #include "0:/_lib/Terminal.ks"
copypath("0:/_lib/Executer.ks"   , "1:"). runOncePath("1:Executer.ks").     // #include "0:/_lib/Executer.ks"
copypath("0:/_lib/Hohmann.ks"    , "1:"). runOncePath("1:Hohmann.ks").      // #include "0:/_lib/Hohmann.ks"
copypath("0:/_lib/Rendezvous.ks" , "1:"). runOncePath("1:Rendezvous.ks").   // #include "0:/_lib/Rendezvous.ks"
copypath("0:/_lib/HillClimber.ks", "1:"). runOncePath("1:HillClimber.ks").  // #include "0:/_lib/HillClimber.ks"
copypath("0:/_lib/Classes.ks"    , "1:"). runOncePath("1:Classes.ks").      // #include "0:/_lib/Classes.ks"

// extra Script imports
copypath("0:/_lib/Rendezvous_Algorithm.ks" , "1:"). // #include "0:/_lib/Rendezvous_Algorithm.ks"

// importing the global pool
copypath("0:/Auriga/Auriga3_globalPool.ks", "1:"). runOncePath("1:Auriga3_globalPool.ks"). // #include "0:/Auriga/Auriga3_globalPool.ks"

switch to 1.


parameter
    runmodeStart, 
    GPU_UID is choose ship:partstaggedpattern("GPU")[0]:uid if ship:partstaggedpattern("GPU"):length > 0 else core:part:uid.

local GPU_PROC is { for proc in ship:modulesnamed("kosprocessor") { if proc:part:uid = GPU_UID { return proc. } } }.
set GPU_PROC to GPU_PROC:call().

global runmode is runmodeStart.


// #region INITIALISATION
    // Control setup
    lock throt to 0.
    lock throttle to throt.
    lock steering to "Kill".

    local azi to 0.
    local gravturn to 0.

    local MaxG_Thrust to {
        parameter MaxG is 2.
        if availableThrust = 0 // ensuring no x/0 case
            return 0.
        local _thrust is 9.81*MASS*MaxG / availableThrust.
        return MAX(0, MIN(_thrust, 1)).
    }.
// #endregion

// #region ENVIROMENTAL VARIABLES
    lock GRAVITY to (body:mu) / (body:radius + ALTITUDE)^2. 
    lock TWR to availablethrust / (mass*GRAVITY).

    // the angle (Deg) from the Ascending node (in direction of motion) where a rendezvous between this ship and a target vessel should occure
    local rendezvousTA is 130.

    local startAlt is 0.
    local towerMass is 1100. // kg, launchequipment
    local timeDerivative is time:seconds.

    list engines in elist.

// #endregion

// #region INTERCOM
    local commentList is list().

    local InputCatcher is { parameter null. }.

    // SLAVE[GPU] -> MASTER[CPU]
    local Net_RX is Lex(
        "Get_TargetOrbit",      { parameter SlaveUID, _. onNet( SlaveUID, "Set_TargetOrbit",      Net_TX["Set_TargetOrbit"]() ). },
        "Get_CommentList",      { parameter SlaveUID, _. onNet( SlaveUID, "Set_CommentList",      Net_TX["Set_CommentList"]() ). },
        "Get_runmode",          { parameter SlaveUID, _. onNet( SlaveUID, "Set_runmode",          Net_TX["Set_runmode"]() ). },
        "Get_TZero",            { parameter SlaveUID, _. onNet( SlaveUID, "Set_TZero",            Net_TX["Set_TZero"]() ). },
        "Get_TNext",            { parameter SlaveUID, _. onNet( SlaveUID, "Set_TNext",            Net_TX["Set_TNext"]() ). },

        "Set_runmode",  { parameter from, _runmode. if RunmodeLexicon:haskey(_runmode) { set runmode to _runmode. } },
        "Set_Input",    { parameter from, data. InputCatcher:call(data). set InputCatcher to { parameter null. }. },

        "GPU_REBOOT",   { parameter from, _. onNet(from, "FORCED_BOOT", runmode). }
    ).

    // MASTER[CPU] -> SLAVE[GPU]
    local Net_TX is Lex(
        "Set_runmode",          { return runmode. },
        "Set_TZero",            { return TZero. },
        "Set_TNext",            { return TNext. },
        "Set_CommentList",      { return commentList. },
        "Set_Comment",          { return list(time:seconds, com). },
        "Set_TargetOrbit",      { return Target_Orbit. },
        "Set_TargetPort",       { return portT:nodeposition. },
        "Set_ShipPort",         { return portS:nodeposition. },

        "Set_checklist",        { return 0. },

        "Get_TargetOrbit",      { return 0. },
        "Get_CommentList",      { return 0. },
        "Get_TZero",            { return 0. },
        "Get_TNext",            { return 0. },
        "Get_Input",            { return "InputRequest". }
    ).

    local function sendGPU {
        parameter mode, data is "null". // set stuff that needs to be send
        local dataToSend is choose Net_TX[mode]:call() if data = "null" else data.
        onNet(GPU_UID, mode, dataToSend).
    }

    local function comment {
        parameter com.
        commentList:add( list(time:seconds, com) ).
        sendGPU( "Set_Comment", list(time:seconds, com) ).
    }

    if GPU_UID <> CORE_UID
        set DPCNet[GPU_UID:tostring()] to GPU_PROC:connection.

    local loggingCommunication is {
        parameter content.
        
        if RT:hasKscConnection(ship) {
            logFile:writeLn( "CPU: " + content[0] + " -> " + content[1][0] ).
            logFile:writeLn( "     => " + content[1][1]:toString() ).
        }
    }.

    local RT is 0. 
    if addons:available("RT")
        set RT to addons:RT. 
    else
        set loggingCommunication to { parameter _. }.
    
// #endregion

// #region ABORT PARAMETERS
    local ctAd to true.
    local ctAs to true.

    local dirError to {return steeringManager:angleerror.}.
    local dDir to derivative(dirError()).
// #endregion

// #region DEFAULT ORBIT SETUP
    local Target_Orbit is lex(
        "Apo", 80.000,
        "Per", 80.000,
        "SMA", 80.000,
        "Inc", 0,
        "LAN", body:rotationangle + ship:geoposition:lng + 2.5,
        "AoP", 0,
        "ECC", 0
    ).

    if hasTarget {
        if not target:isType("vessel")
            set target to target:ship.

        set Target_Orbit to lex(
            "Apo", .001*target:orbit:Apoapsis,
            "Per", .001*target:orbit:Periapsis,
            "SMA", .001*target:orbit:semimajoraxis,
            "Inc", target:orbit:inclination,
            "LAN", target:orbit:LAN,
            "AoP", target:orbit:ArgumentOfPeriapsis,
            "ECC", target:orbit:eccentricity
        ). 
    }

    local TZero to time:seconds.
    local TNext to time:seconds.

    local setTerminal to { 
        parameter h is 4, w is 25. 
        set terminal:height to h. // Min 3
        set terminal:width to w. // Min 15
    }.

    if terminal:height < 7
        setTerminal().

    comment("Programm Loaded").   // GUI --> GPU
// #endregion
    
// #region RUNMODE & FUNCTIONS
    // >> Organisation Functions
        local function netHandle {
            local netContent is offNet().

            if netContent:istype("boolean") or not netContent:istype("list") 
                return.
            if not Net_RX:haskey(netContent[1][0]) 
                return. 

            loggingCommunication(netContent).
            
            Net_RX[netContent[1][0]]:call(netContent[0], netContent[1][1]). // Net_RX['command']:call('from', 'data')
        }

        local function modeChange {
            parameter r, s is 0.
            set runmode to r.
            set submode to s.
            sendGPU("Set_runmode", r).
        }

        local function interruptWait {
            parameter timeWait, otherDeleget is Update@.
            local startTimeInt is time:seconds.

            until time:seconds - startTimeInt >= timeWait { otherDeleget:call(). }
        }

    // >> Program Functions
        local function launchControl  {
            set azi to Azimuth(Target_Orbit:Inc).
            set throt to maxGThrust(2).
            set gravturn to AdjustedLaunchPitch(80000, 200).
            set steering to heading(azi, gravturn, 180).
        }
        local function GeneralApsLineRotation {
            parameter obj. // obj is a lex containing the necessary parameters for calculation

            // Get Intersactions
            local intersection is orbitIntersection( obj ).
            
            // choose Intersection wich is closest to us
            if intersection[0]-ship:orbit:trueanomaly > 0
                set intersection to intersection[0].
            else 
                set intersection to intersection[1].
            
            // add the Maneuver Node with 'rough-ish' values
            add IntersectionManeuver( intersection, obj ).
            local initalProg is nextNode:prograde.
            
            HillClimber( // correcting the Prograde Component of the Maneuver Node
                "MIN", false,
                { parameter _. 
                    set nextNode:prograde to initalProg + _. 
                    return abs(target:orbit:argumentofperiapsis - nextNode:orbit:argumentofperiapsis). 
                }, 80, 50, -80, 0 
            ).
        }

        local function runmode_ABORT {
            runmode_99().
            RCS on.
            ABORT on.
            core:deactivate().
        }

        local function abortChecker {
            if VANG(ship:facing:vector, steering:vector) > 10 {
                if ctAd {
                    set ctA to time:seconds.
                    set ctAd to false.
                }

                comment("! ABORT WARNING ! " + round(5 - (time:seconds - ctA), 3) + " secs until ABORTION!").

                // log (5 - (time:seconds - ctA)) + " , " + VANG(ship:facing:vector, steering:vector) to abortD.csv.

                wait 0.

                if time:seconds - ctA > 5 {
                    comment("!!! ABORTING !!! DIRECTION ERROR !!!").
                    modeChange("ABORT").
                }
            } else { 
                set ctA to 0. 
                set ctAd to true.
            }

            if dVer(verticalSpeed) < -.75*GRAVITY {
                if ctAs {
                    set ctS to time:seconds.
                    set ctAs to false.
                }

                comment("! ABORT WARNING ! " + round(5 - (time:seconds - ctS), 3) + " secs until ABORTION!").
                // log (5 - (time:seconds - ctS)) + "," + (dVer(verticalSpeed) +.75*GRAVITY) to abortS.csv.
                
                wait 0.
                
                if time:seconds - ctS > 5 {
                    comment("!!! ABORTING !!! VERTICAL ACCELERATION ERROR !!!").
                    modeChange("ABORT").
                }
            } else if dVer(verticalSpeed) > -.9*GRAVITY { 
                set ctS to 0. 
                set ctAs to true.
            }
        }

        local function PO_display {
            set VDdelPos:start to portS:nodeposition.
            set VDdelPos:vector to -dp.

            set VDdeltgt:start to portT:position.
            set VDdeltgt:vector to point.

            set VDdelVel:start to startPos.
            set VDdelVel:vector to 5*dV.

            local adj is 5.

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
        local function PO_Update {
            set startPos to portS:position. 
            set endPos to portT:position + point.

            global dP is startPos - endPos.
            global dV is ship:velocity:orbit - Target:velocity:orbit.

            global dVComp is Vec2Ship(dV).
            global dPComp is Vec2Ship(dP).
        }
        local function PO_velHelper {
            // https://www.desmos.com/calculator/ksp9kioqmv
            parameter dist, StartDist is 10, Cutoff is 0.05, Initial is 0.1, maxVel is 1.

            local IS is Initial / StartDist.
            local a  is -2*(2*maxVel-Initial-Cutoff)/StartDist^2.
            local o1 is Cutoff/(a*StartDist-IS).
            local o2 is StartDist - IS/a.

            return abs( a*( dist - o1 )*( dist - o2 ) ).
        }

    // #region Launch
        local function runmode_1 { // Initialisation
            abortChecker().
            local timeLaunch to time:seconds + waitForLaunch(
                ship:geoposition:lat,
                ship:geoposition:lng, 
                Target_Orbit:Inc, 
                Target_Orbit:Lan
            )[0].

            set TZero to timeLaunch.
            sendGPU("Set_TZero").
            
            interruptWait(timeLaunch - time:seconds - 30). // 30 secs to LAUNCH ================

            kuniverse:timewarp:cancelwarp().

            interruptWait(timeLaunch - time:seconds - 5). // 5 secs to LAUNCH ===========================

            comment("Control Override").
            RCS off.
            SAS off.
            
            kuniverse:timewarp:cancelwarp().

            interruptWait(timeLaunch - time:seconds - 2). // 2 secs to LAUNCH ===========================
            
            DoSaveStage(). // active engines
            comment("Engine startup").
            set startAlt to altitude.
            set throt to 1.

            kuniverse:timewarp:cancelwarp().
            set kuniverse:timewarp:Warp to 0.

            interruptWait(timeLaunch - time:seconds). // 0 secs to LAUNCH ===========================

            wait until TWR*(1+mass/towerMass) > 1.

            comment("Lift-off").

            DoSaveStage(). // unclamp from tower
            modeChange(2).  
        }
        local function runmode_2 { // Lift-off
            abortChecker().
            if (altitude - startAlt) > 200 {
                set azi to Azimuth(Target_Orbit:Inc).
                set steering to lookDirUp(Up:vector, North:vector) + R(0,0, azi).
                comment("Azimuth-Roll initiated").
                
                modeChange(3).
            } else {
                set steering to lookDirUp(Up:vector, ship:facing:topvector).
                set throt to 1.
            }
        }
        local function runmode_3 { // Launch Tower cleared
            abortChecker().
            launchControl().
            if (altitude - startAlt) > 1000 {
                comment("Launch Pad cleared").
                comment("flight Path Initialised").
                comment("waiting for: save Apoapsis").
                modeChange(4).
            }
        }
        local function runmode_4 { // Ascend profile
            abortChecker().
            launchControl().
            if orbit:apoapsis > 30000 {
                comment("auto-ABORT mechanism disabled").
                comment("waiting for: Engine Flame out").

                DoSaveStage().
                modeChange(5).
            }      
        }
        local function runmode_5 { // LES jetison
            launchControl().
            for e in elist {
                if e:flameout {
                    DoSaveStage().
                    set throt to 0.
                    set steering to ship:facing.
                    modeChange(6).
                    break.
                }
            }
        }
        local function runmode_6 { // MECO
            comment("Apoapsis is save").

            set steering to ship:facing.
            set throt to 0.

            wait 4.
            
            comment("waiting for: Kármán-line passage").
            set steering to lookDirUp(ship:facing:vector, Up:vector).
            
            modeChange(7).
        }
        local function runmode_7 { // Wait for Atmosphere Exit
            if ship:altitude > 70000 {
                comment("Kármán-line has been passed").
                wait 2.

                modeChange(8).
            }
        }
        local function runmode_8 { // Rais Apoapsis to Park km
            comment("Node: Circularising at Apoapsis").
            set circNode to NODE(Time:seconds + eta:apoapsis, 0, 0, DeltaVcirc(orbit:apoapsis)).
            add circNode.

            Executer(circNode, Update@, DPCNet[GPU_UID]).
        }
        local function runmode_9 { // Circ Orbit at Periapsis km
            comment("Node: Circularising Apoapsis at 80 km").
            wait 1.
            set circ80Node to NODE(Time:seconds + eta:periapsis, 0, 0, DeltaVcirc(orbit:periapsis)).
            add circ80Node.
            modeChange(10).
        }
    // #endregion
    // #region normal operation
        local function runmode_10 { // Execute Next Node
            if hasNode {
                if runmode <> 10 
                    modeChange(10).
                Executer(nextNode, Update@, DPCNet[GPU_UID]).
            }
            modeChange(11).
        }
        
        local function runmode_15 { // rendezvous calculation Algorithm
            if not hasTarget {
                modeChange(70).
                return.
            }
            run Rendezvous_Algorithm.ks( ship:orbit, target:orbit, rendezvousTA ).
            runmode_10(). wait 1. 
            runmode_10(). wait 1.
            runmode_10(). wait 1.
        }

        local function runmode_21 { // PO Setup
            if not hasTarget {
                modeChange(70).
                return.
            }
            if not target:isType("vessel")
                set target to target:ship.


            set config:ipu to 2000.

            setTerminal(25, 45).

            SAS off.
            RCS on.

            translationPIDs(100, 20).
            set_Pos( list(0,0,0) ).

            global portT is target:dockingports[0].
            global portS is ship:dockingports[0].

            sendGPU("Set_TargetPort").
            sendGPU("Set_ShipPort").            

            global point is 10*portT:portfacing:forevector.

            // visuals
            global rd is relativeDisplay(target, 20, 10).
            global startPos is portS:position. 
            global endPos is portT:position + point.

            global VDdelPos is vecDraw(startPos, endPos, blue   , "dP", 1, true, .2).
            global VDdelTgt is vecDraw(startPos, endPos, red    , "dT", 1, true, .2).
            global VDdelVel is vecDraw(startPos, endPos, yellow , "dV", 1, true, .2).

            PO_Update().
            PO_display().


            modeChange(23).
            
            // global mV is 100.
            // global mP is 20.

            // if AG5 set mV to mV + 1.
            // if AG6 set mV to mV - 1.
            // if AG7 set mP to mP + 1.
            // if AG8 set mP to mP - 1.

            // if AG5 or AG7 or AG6 or AG8 {
            //     translationPIDs(mV, mP).
            //     AG5 off. AG7 off. AG6 off. AG8 off.
            // }

            // print mV + "  " at(terminal:width-5, 1).
            // print mP + "  " at(terminal:width-5, 2).
        }
        local function runmode_23 {
            rd:Update().
            PO_Update().
            PO_display().

            if dp:mag < 1 and dv:mag < 1 or AG10 { // and vang(ship:facing:vector, -dp) < 45
                local t is time:seconds + 5.
                until time:seconds > t or AG10 {
                    PO_Update().
                    PO_display().
                    perform_Pos(dPComp, dVComp).

                    if dp:mag > 1 and dv:mag > 1
                        return.
                }

                AG10 off.

                translationPIDs(30, 1).
                set point to V(0,0,0).

                modeChange(25).
            }

            set steering to lookDirUp( portT:position - portS:position, target:facing:topvector ).

            perform_Pos(dPComp, dVComp).
        }
        local function runmode_25 {
            // close distance control: dist < 10-ish
            rd:Update().
            PO_Update().
            PO_display().

            if dP:mag < 0.5 {
                runmode_97().
                runmode_98().
                setTerminal().
                modeChange(99).
            }

            set steering to lookDirUp( -portT:portfacing:forevector, target:facing:topvector ).
            // PO_velHelper(dP:mag)
            perform_VePo( list( list( .05*dP:mag, "", "" ), list( "", point:y, point:z ) ) , dPComp, dVComp ).
        }

        local function runmode_31 { // Aps Line Rotation => TARGET
            if not hasTarget { // return if we dont have a target
                modeChange(70).
                return.
            }

            // calculating Aps Line Rotation
            // !! CHANGING => ALL PARAMETERS !!      (matching target parameters)
            GeneralApsLineRotation( Convert_ForApsRotation(ship, target) ).

            modeChange(11).
        }
        local function runmode_32 { // Aps Line Rotation => SHIP
            if not hasTarget { // return if we dont have a target
                modeChange(70).
                return.
            }

            // calculating Aps Line Rotation
            // !! ONLY CHANGING  =>  ARG. OF PERIAPSIS !!
            GeneralApsLineRotation( Convert_ForApsRotation(ship, target, true) ).

            modeChange(11).
        }

        local function runmode_50 { // Orbital Vector Display
            lock Vecs to OrbitDirections().
            global Vec_Per is vecDraw(body:position,  (body:radius+ship:periapsis)*Vecs[0], RGB(1,0,0), "Per", 1, true, 0.2).
            global Vec_Apo is vecDraw(body:position, -(body:radius+ship:apoapsis )*Vecs[0], RGB(0,1,0), "Apo", 1, true, 0.2).
            global Vec_AN  is vecDraw(body:position,  Vecs[1], RGB(0,0,1), "Ω", 1, true, 0.2).
            global Vec_DN  is vecDraw(body:position, -Vecs[1], RGB(0,0,1), "-Ω", 1, true, 0.2).

            set Vec_Per:vecUpdater to { return  (body:radius+ship:periapsis)*Vecs[0]. }.
            set Vec_Apo:vecUpdater to { return -(body:radius+ship:apoapsis )*Vecs[0]. }.
            set Vec_AN :vecUpdater to { return  Vecs[1]. }.
            set Vec_DN :vecUpdater to { return -Vecs[1]. }.
            
            if hasTarget {
                lock vec to ANVector(positionAt(target, time:seconds)-body:position, velocityAt(target, time:seconds):orbit).
                global Vec_ANT is vecDraw(body:position,  vec, RGB(.5,.75,1), "T+Ω", 1, true, 0.2).
                global Vec_DNT is vecDraw(body:position, -vec, RGB(.5,.75,1), "T-Ω", 1, true, 0.2).               
                set Vec_ANT to { return  vec. }.
                set Vec_DNT to { return -vec. }.               
            }

            modeChange(70).
        }
        local function runmode_51 { // Asc. Node Display
            local AN is ANVector().
            local w  is OrbitDirections()[0].

            local theta is VANG(w, AN).

            local t is TrueAnomalyToTime(theta).
            local tAdjust is MeanAnomalyToTime( constant:DegToRad * ship:orbit:MeanAnomalyAtEpoch).

            set ANNode to NODE(ship:orbit:epoch + t - tAdjust, 0, 0, 0).
            add ANNode.
            modeChange(70).
        }
        local function runmode_52 { // Asc. Node Correction
            local l is zeroPlane(positionAt(target, time:seconds)-body:position, velocityAt(target, time:seconds):orbit).
            
            for msg in l {
                comment( msg ).
            }

            add l[0].
            // add l[1].
            
            modeChange(70).
        }
        local function runmode_53 { // Closest Approach scan
            if not hasTarget {
                modeChange(70).
                return.
            }
            local clsApr is close_aproach_scan(ship, target).
            comment("=-=-=-=-= Closest Approach =-=-=-=-=").
            comment("Dist: " + round(clsApr:dist, 3) + " m").
            comment("Time: " + SecondsToClock(clsApr:UTS - time:seconds)).
            modeChange(70).
        }
        local function runmode_54 { // Cls App detail Display
            if not hasTarget {
                modeChange(70).
                return.
            }
            local t is close_aproach_scan(ship, target, time:seconds, 2*ship:orbit:period, 36, 1, true)["UTS"].
            global Vec_SVel is vecDraw(V(0,0,0), V(0,0,0) + velocityAt(Ship, t):orbit, RGB(1,0,0), "Ship VEL", 1, true, 0.2).
            global Vec_TVel is vecDraw(V(0,0,0), V(0,0,0) + velocityAt(Target, t):orbit, RGB(0,0,1), "Target VEL", 1, true, 0.2).
            global Vec_dVel is vecDraw(V(0,0,0), V(0,0,0) + velocityAt(Target, t):orbit - velocityAt(Ship, t):orbit, RGB(0,1,0), "relative VEL", 1, true, 0.2).

            global Vec_SPos is vecDraw(body:position, positionAt(Ship, t), RGB(1,0,0), "Ship POS", 1, true, 0.2).
            global Vec_TPos is vecDraw(body:position, positionAt(Target, t), RGB(0,0,1), "Target POS", 1, true, 0.2).
            global Vec_dPos is vecDraw(body:position, positionAt(Target, t) - positionAt(Ship, t), RGB(0,1,0), "relative POS", 1, true, 0.2).

            add VecToNodeConverter( velocityAt(Target, t):orbit - velocityAt(Ship, t):orbit, t, true).

            comment("=-=-= Closest Approach ..Detail.. =-=-=").
            comment("SVel: "+ round(Vec_SVel:Vector:mag, 2)+" m/s").
            comment("TVel: "+ round(Vec_TVel:Vector:mag, 2)+" m/s").
            comment("dVel: "+ round(Vec_dVel:Vector:mag, 2)+" m/s").
            comment("-------------------------------").
            comment("SPos: "+ round(Vec_SPos:Vector:mag, 2)+" m").
            comment("TPos: "+ round(Vec_TPos:Vector:mag, 2)+" m").
            comment("dPos: "+ round(Vec_dPos:Vector:mag, 2)+" m").
            comment("==> Time: " + SecondsToClock(t - time:seconds) +" <==").
            .
            modeChange(70).
        }

        local function runmode_71 { // launch setup with Elements
            sendGPU("Get_Input", 
                list(
                    list("HEADER", "TARGET ORBIT ELEMENTS:"),
                    list("VAR", "Apo.  [MSL/km]:", round(Target_Orbit:Apo, 3)),
                    list("VAR", "Peri. [MSL/km]:", round(Target_Orbit:Per, 3)),
                    list("VAR", "Inclination:   ", round(Target_Orbit:Inc, 3)),
                    list("VAR", "Lng. Asc. Node:", round(Target_Orbit:Lan, 3)),
                    list("VAR", "Arg. of Periap:", round(Target_Orbit:AoP, 3))
                )
            ).

            set InputCatcher to {
                parameter data.

                set Target_Orbit:Apo to data[0]:tonumber(Target_Orbit:Apo).  // refer to default vals if unclear
                set Target_Orbit:Per to data[1]:tonumber(Target_Orbit:Per).  // refer to default vals if unclear
                set Target_Orbit:Inc to data[2]:tonumber(Target_Orbit:Inc).  // refer to default vals if unclear
                set Target_Orbit:Lan to data[3]:tonumber(Target_Orbit:Lan).  // refer to default vals if unclear
                set Target_Orbit:AoP to data[4]:tonumber(Target_Orbit:AoP).  // refer to default vals if unclear
                
                set Target_Orbit:SMA to 0.5*(Target_Orbit:Apo + Target_Orbit:Per).
                set Target_Orbit:ECC to choose 0.5*(Target_Orbit:Apo - Target_Orbit:Per)/Target_Orbit:SMA if Target_Orbit:SMA > 0 else 0.

                sendGPU("Set_TargetOrbit").
            }.

            modeChange(70).
        }
        local function runmode_72 { // launch setup with target
            if hasTarget {
                local orb is target:orbit.
                set Target_Orbit:Apo to 0.001*orb:apoapsis.
                set Target_Orbit:Per to 0.001*orb:periapsis.
                set Target_Orbit:Inc to orb:inclination.
                set Target_Orbit:Lan to orb:LAN.
                set Target_Orbit:AoP to orb:argumentOfPeriapsis.
            }

            modeChange(71).
        }
        local function runmode_74 { // set rendezvous angle 
            sendGPU("Get_Input", 
                list(
                    list("HEADER", "RENDEZVOUS AT ANGLE:"),
                    list("VAR", "rendezvousTA [0, 360]:", round(rendezvousTA, 3))
                )            
            ).

            set InputCatcher to {
                parameter data.

                set rendezvousTA to data[0]:tonumber(rendezvousTA).  // refer to default vals if unclear
                set rendezvousTA to mod( rendezvousTA + 360, 360 ).
            }.

            modeChange(70).
        }

        local function runmode_97 { //  ** CLEAR: VecDraws ** 
            clearVecDraws().
            modeChange(70).
        }
        local function runmode_98 { //  ** RELOCK KOS - CONTROL ** 
            lock throttle to throt.
            lock sterring to "KILL".
            SAS off.
            RCS off.
            modeChange(70).
        }
        local function runmode_99 { //  ** UNLOCK KOS - CONTROL ** 
            unlock steering.
            unlock throttle.
            set ship:control:neutralize to true.
            SAS on.
            modeChange(70).
        }
    // #endregion 
    
    global function Update {
        netHandle().

        print SecondsToClock(Time:seconds) + " , " + round(1000*(time:seconds - timeDerivative)) + " ms       " at (2,0).
        print "runmode: " + runmode + "          " at (2,1).
        print commentList[commentList:length - 1][1] at (2,2).

        set timeDerivative to time:seconds.

        if terminal:input:haschar {
            if terminal:input:getchar() = terminal:input:enter {
                modeChange( TerminalInput("runmode") ).
            }
        }
    }

    local function Start {
        sendGPU("Set_TargetOrbit").
        sendGPU("Get_CommentList").
        sendGPU("Get_TZero").
        sendGPU("Get_TNext").
    }
// #endregion

//#region LOOP & SETUP
    local HOLD is { return. }.

    local RunmodeLexicon is Lex(
        1 , runmode_1  @,
        2 , runmode_2  @,
        3 , runmode_3  @,
        4 , runmode_4  @,
        5 , runmode_5  @,
        6 , runmode_6  @,
        7 , runmode_7  @,
        8 , runmode_8  @,
        9 , runmode_9  @,
        10, runmode_10 @, // JMP into 11 after Maneuver Node execution
        11, HOLD        , // !!! MUST BE A NONE-DOING FUCTION 

        15, runmode_15 @,

        21, runmode_21 @,
        23, runmode_23 @,
        25, runmode_25 @,

        31, runmode_31 @,
        32, runmode_32 @,
        
        50, runmode_50 @,
        51, runmode_51 @,
        52, runmode_52 @,
        53, runmode_53 @,
        54, runmode_54 @,

        70, HOLD        ,
        71, runmode_71 @,
        72, runmode_72 @,
        74, runmode_74 @,

        97, runmode_97 @,
        98, runmode_98 @,
        99, runmode_99 @,

        "ABORT", runmode_ABORT@
    ).

// LOOP ==================================================
    Start().
    Update().
    until runmode = 0 {
        RunmodeLexicon[runmode]:call().
        Update().
    }
// #endregion