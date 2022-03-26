copypath("0:/common_lib.ks", "").
run once common_lib.ks.

set config:stat to true.

parameter runmodeStart is 1, submodeStart is 0.   

// Initiation ========================================================
    local trAdd     is addons:tr.
    local impactPos is ship:geoposition.
// Ttarget ===========================================================
    set landingSpotsLex to lex(
        "Launch_Pad"      , latlng(-0.0972, -74.5575),
        "VAB"             , latlng(-0.0968, -74.6188),
        "LandingPadCenter", latlng(-0.0979, -74.4739) // is group projected position into Geoposition
    ).

    set landingSpotsLex["LandingPadNorth"] to ship:body:geopositionof(landingSpotsLex["LandingPadCenter"]:position + vecToLocal(V(76,  132, 0))). //group Center offset
    set landingSpotsLex["LandingPadSouth"] to ship:body:geopositionof(landingSpotsLex["LandingPadCenter"]:position + vecToLocal(V(76, -132, 0))). //group Center offset

    global targetlocation to landingSpotsLex["LandingPadCenter"].

// Vectors ===========================================================
    lock relimpact to targetlocation:position - impactPos:position.
    lock relpos    to targetlocation:position - ship:position.
    lock relgeo    to targetlocation:position - ship:geoposition:position.
    lock vel       to ship:velocity:surface.
    lock east      to vCrs(Up:vector, north:vector).
// Parts ===========================================================
    list engines in elist.
    list parts   in plist.
    local rcsP is ship:partsnamed(ship:partstagged("rcs")[0]:name).
    local finP is ship:partsnamed(ship:partstagged("fin")[0]:name).
    local tank is choose ship:partstagged("tank1")[0] if defined ship:partstagged("tank1") else ship:parts[0].
    local eng1 is ship:partstagged("eng1")[0].

    for ENG in elist {
        lock DeltaVelocity to (MAX(1, ENG:ISPAT(BODY:ATM:ALTITUDEPRESSURE(ALTITUDE)) * 9.8 * ln(SHIP:MASS / SHIP:DRYMASS))). // is dv of whole rocket
    }

    function toggleSoot {
        tank:getmodule("ModuleSootyShader"):doevent("toggle soot").
    }
    function engSwitcher {
        parameter mode.

        if mode = "AllEngines" or mode = "ThreeLanding" or mode = "CenterOnly" {
            until Eng1:getModule("WBIMultiModeEngine"):getField("current mode") = mode {
                Eng1:getModule("WBIMultiModeEngine"):doevent("next engine").
            }
        }
    }
    function getThrusts {
        local lexi is lex().
        for a in range(3) {
            set lexi[Eng1:getModule("WBIMultiModeEngine"):getField("current mode")] to Eng1:availablethrustat(1).
            Eng1:getModule("WBIMultiModeEngine"):doevent("next engine").
        }
        return lexi.
    }
    function finToggle {
        parameter mode is "toggle".
        //some are disabled because of internal problems
        for f in finP {
            if f:getModule("ModuleAnimateGeneric"):hasevent("extend fins") and (mode = "toggle" or mode = "extend") {
                f:getModule("ModuleAnimateGeneric"):doevent("extend fins"). 
                //f:getModule("SyncModuleControlSurface"):setfield("kontrollbegrenzerUI", 52). 
            } else if (mode = "toggle" or mode = "retract") {
                f:getModule("ModuleAnimateGeneric"):doevent("retract fins"). 
                //f:getModule("SyncModuleControlSurface"):setfield("kontrollbegrenzerUI", 0). 
            }
        }
    }
    function rcsLimit {
        parameter limit.
        for r in rcsP {
            r:getModule("ModuleRCSFX"):setfield("schubbegrenzung", limit).
        }
    }

// Variables ===========================================================
    
    local mu       is body:mu.
    local radius   is body:radius.
    lock GRAVITY   to mu / (radius + ALTITUDE)^2. // accel

    lock aNet to max(0.001, (availableThrust / mass) - GRAVITY).

    lock alpha    to VANG(up:vector, ship:facing:vector).
    lock maxAlpha to arccos( min(1, (mass*GRAVITY) / max((mass*GRAVITY), availableThrust))).
    lock maxVang  to min(1, relimpact:mag/500).             // 500 is pivot based on dist                 // !RATIO needs adjustment Factor

    lock TWR       to maxThrust / (mass*GRAVITY).
    lock corrThrot to ((mass*GRAVITY) / cos(alpha)) / maxThrust.

// Code ===========================================================
    // Initialisation
        set throttle to 0.
        set steering to lookDirUp(up:vector, north:vector).

        clearscreen.
        clearVecDraws().

        set config:ipu to 1000.
        set terminal:width  to 50.
        set terminal:height to 45.
        
        mode(runmodeStart, submodeStart).
        set comment  to "Programm Loaded".
        set letPrint to true.

        set totalElapsedTimeStart to time:seconds.
        set modeElapsedTimeStart  to time:seconds.
        landingPIDs().
        
    //Terminal out ===========================================================
    function PrintUpdater {
        set printlistl to list().

        printlistl:add("~~~~~~~~~~~~~~~~~~~~ falcon 3 ~~~~~~~~~~~~~~~~~~~~"                                                 ).
        printlistl:add("Total Time:              " + SecondsToClock(time:seconds - totalElapsedTimeStart)                   ).
        printlistl:add("Mode Elapsed|next Time:  " + SecondsToClock(time:seconds - modeElapsedTimeStart) + " | " + (choose SecondsToClock(nextModeTime) if defined nextModeTime else "---              ")).
        printlistl:add("runmode:                 " + runmode + "        "                                                   ).
        printlistl:add("submode:                 " + submode + "        "                                                   ).
        printlistl:add("steer Mode:              " + landingSteer(targetlocation, false)["steerMode"]                       ).
        printlistl:add("Engine Mode:             " + Eng1:getModule("WBIMultiModeEngine"):getField("current mode")          ).
        printlistl:add("-------------------- comments --------------------"                                                 ).
        printlistl:add("comment:                 " + comment + "                                                           ").
        printlistl:add("===================== Height ====================="                                                 ).
        printlistl:add("Altitude:                " + ROUND(altitude/1000, 3) + "    km    "                                 ).
        printlistl:add("Apoapsis:                " + ROUND(Apoapsis/1000, 3) + "    km    "                                 ).
        printlistl:add("-------------------- Dynamics --------------------"                                                 ).
        printlistl:add("Throttle:                " + ROUND(throttle,2) + "    %    "                                        ).
        printlistl:add("TWR:                     " + round(twr,2) + "       "                                               ).
        printlistl:add("Dynamic Pressure:        " + ROUND(ship:Q * constant:ATMtokPa, 2) + "    kPa    "                   ).
        printlistl:add("--------------------- Steers ---------------------"                                                 ).
        printlistl:add("Steer (Pitch, HDG, Roll):" + round(getShipsRotation():y) + ", " + round(getShipsRotation():x) + ", " + round(getShipsRotation():z) + "    °    "  ).
        printlistl:add("dVang (Pitch, Yaw, Roll):" + round(steeringmanager:pitcherror) + ", " + round(steeringmanager:yawerror) + ", " + round(steeringmanager:rollerror) + " => " + abs(round(steeringManager:angleerror)) + "    °    "  ).
        printlistl:add("--------------------- Alphas ---------------------"                                                 ).
        printlistl:add("Alpha:                   " + round(alpha) + "    °    "                                             ).
        printlistl:add("    > max:               " + round(maxAlpha) + "    °    "                                          ).
        printlistl:add("Phi:                     " + round(100*maxVang) + "    %    "                                       ).
        printlistl:add("    > x:                 " + round(100*min( 1, ABS(vectolocal(relimpact):x/100))) + "    %    "     ).
        printlistl:add("    > y:                 " + round(100*min( 1, ABS(vectolocal(relimpact):y/100))) + "    %    "     ).
        printlistl:add("---------------------- Dist ----------------------"                                                 ).
        printlistl:add("dist:                    " + round(relimpact:mag, 1) + "    m    "                                  ).
        printlistl:add("dist(east, north):       " + round(vecToLocal(relimpact):x, 1) + ", " + round(vecToLocal(relimpact):y, 1) + "    m    ").
        printlistl:add("-------------------- Burn Alt --------------------"                                                 ).
        printlistl:add("burnAlt:                 " + (choose round(burnAlt)            if (defined burnAlt)                              else "---") + "    m    ").
        printlistl:add("error:                   " + (choose round(altitude - burnAlt) if (defined burnAlt and burnalt:isType("scalar")) else "---") + "    m    "). 
        printlistl:add("start:                   " + (choose round(burnStartIn)        if (defined burnStartIn)                          else "---") + "    s    "). 
        printlistl:add("--------------------- Speeds ---------------------"                                                 ).
        printlistl:add("verticalspeed:           " + round(vecToLocal(vel):z, 1) + "    m/s    "                            ).
        printlistl:add("horizontal (east, north):" + round(vecToLocal(vel):x, 1) + ", " + round(vecToLocal(vel):y, 1) + "    m/s    ").
        printlistl:add("----------------------- dv -----------------------"                                                 ).
        printlistl:add("dv Booster:              " + round(DeltaVelocity) + "    m/s    "                                         ).
        printlistl:add("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"                                                 ).
        
        for a in range(0, printlistl:length) {
            print printlistl[a] at (0,a + 1).
        }
    }

//Loop =================================================================================================================================
until runmode = 0 { 
    if letprint {
        PrintUpdater().
    }   

    if terminal:input:haschar {
        if terminal:input:getchar() = terminal:input:enter {
            set a to terminal:input:getchar().
            if a = "1" {
                mode(TerminalInput("runmode")).
            } else if a = "2" {
                mode(runmode, TerminalInput("submode")).
            }
        } 
    }

    set impactPos to (choose trAdd:impactPos if trAdd:hasimpact else ship:geoposition).
    local pres is body:atm:altitudepressure(altitude).

    set dv1     to DeltaVelocity.
    
    // Code ==============================================================
        if runmode = 1 {
            set config:ipu to 1000.
            
            lock throttle to 0.
            lock steering to "kill".
            
            SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
            SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
            
            wait .1.

            unlock throttle.
            unlock steering.

            set modeElapsedTimeStart to time:seconds. //End of runmode
            mode("µ").
        }

        if runmode = 2 { // for testing
            
        }

        if runmode = 22 { // for testing
            
        }

        if runmode = 3 { // launch procedure
            if not (defined r3) {
                set hdg to 360*random().
                set dvChange to dv1.
                set ddv to 0.
                set t1  to time:seconds.

                GEAR off.
                SAS off.
                RCS off.

                engSwitcher("AllEngines").
                set comment to "Launch sequence initialized".

                set throttle to 1.

                if trueRadar() < 100 and vel:mag < 10 { 
                    mode(3,1). 
                    if not eng1:ignition { DoSaveStage(). }
                } else { 
                    mode(3,2). 
                }
                
                set r3 to true.
            }

            if submode = 1 {
                if twr > 1 {
                    DoSaveStage().
                    mode(3,2).

                    set comment to "Launch sequence normal".
                    set modeElapsedTimeStart to time:seconds. //End of submode
                }
            }

            if submode = 2 {
                set throttle to maxGThrust(2.5).
                set pitch    to GravityTurnPitch(80).
                //set pitch    to 90. // pitch override
                set steering to heading(hdg, pitch).

                local triggerdVel is 2*vel:mag + 00.

                local ddv is choose (dv1 - dvChange) / (time:seconds - t1) if time:seconds - t1 > 0 else ddv.

                wait 0.

                set dvChange to dv1.
                set t1  to time:seconds.
                
                set nextModeTime to triggerdVel / ddv.
                //log triggerdVel +", "+ ddv +", "+ nextModeTime to ght1.csv.

                if dv1 < triggerdVel {
                    set throttle to 0.
                    set steering to Heading(GeoDir(targetlocation, impactPos), 0).

                    unset nextModeTime.
                    RCS on.
                    mode(4,1).

                    set modeElapsedTimeStart to time:seconds. //End of runmode
                } 
            }
        }

        if runmode = 4 { // return to target
            if not (defined r4) {
                GEAR off.
                SAS off.
                RCS on.

                global targetlocation to landingSpotsLex["LandingPadCenter"].

                set throttle to 0.
                flipBy(). // resets raw inputs
                set submode to 1. //currently disabled due to FLIPBY()

                set comment to "turning for boostback".

                set r4 to true.
            }

            if submode = 1 {
                if not (defined s1) {
                    set s1 to true.
                    set comment to "turning for Boostback".

                    //set steeringManager:yawtorquefactor  to 0.
                    //set steeringManager:rolltorquefactor to 0.

                    //flipBy(V(0, 1, 0), 5). // V(YAW, PITCH, ROLL) 
                }

                set steering to Heading(GeoDir(targetlocation, impactPos), 0, 180).

                if (VANG(Up:vector, facing:vector) > 45 and VANG(steering:vector, facing:vector) < 55) {
                    engSwitcher("ThreeLanding").
                    flipBy(). // resets raw inputs

                    set steeringManager:yawtorquefactor  to 1.
                    set steeringManager:rolltorquefactor to 1.
                    
                    set comment to "boostback started".
                    set submode to 2.
                }
            }

            if submode = 2 {
                if relimpact:mag < 250 or (defined triggerOverride) {
                    if not (defined triggerOverride) {
                        set triggerOverride to time:seconds.
                        set comment to "turning for Glideback".
                        set modeElapsedTimeStart to time:seconds. //End of submode
                        
                        set throttle to 0.  
                        set steering to Heading(GeoDir(ship:geoposition, targetlocation), 0). 

                        set steeringManager:yawtorquefactor  to 0.
                        set steeringManager:rolltorquefactor to 0.                  

                        flipBy(V(0, -1, 0), 5).
                    }

                    if VANG(steering:vector, facing:vector) < 25 or VANG(Up:vector, facing:vector) > 75 {
                        finToggle("extend").
                        landingPIDs().

                        set steeringManager:yawtorquefactor  to 1.
                        set steeringManager:rolltorquefactor to 1.

                        set submode to 3. 
                        
                        unset triggerOverride.
                        set modeElapsedTimeStart to time:seconds. //End of submode
                    }
                } else {
                    local offset is GeoHdgoffset( targetlocation, GeoDir( targetlocation, ship:geoposition ), 1000 ).
                    set throttle to 0.0001 * (offset:position - impactPos:position):mag.
                    set steering to heading( geodir( offset, impactPos), 0, 180 ). // ROLL(180) due to flip
                }
            }

            if submode = 3 {
                if not (defined s3) {
                    set throttle to 0.

                    set thrusts to getThrusts(). // need to do it in the intialisatin cause it has to physicaly enumerate the engine in KSP
                    set thrusts["threshold"] to thrusts["CenterOnly"] / thrusts["ThreeLanding"].
                    
                    engSwitcher("ThreeLanding").
                    rcsLimit(100). 
                    flipBy(). // resets raw inputs
                    
                    set startTime      to time:seconds.
                    set intitialTarget to targetlocation.
                    set angle to 30.
                    set pivot to 100.
                    
                    set s3 to true.
                }

                suicideStarter(runmode, 4).
                //log eastPosPID:error +" "+ eastPosPID:output +" "+ eastVelPID:output +" "+ northPosPID:error +" "+ northPosPID:output +" "+ northVelPID:output to ght1.csv.
                //lexiprinter	(landingLoger()["lexo"], printlistl:length + 4, 6).

                local offset is min(max(relgeo:mag/50, 25), 200).
                //local offset is 200.

                set comment to "offset: " +round(offset, 2) + " m, pivot: " + round(pivot) + " m".

                set targetlocation to GeoHdgoffset(
                    intitialTarget, 
                    GeoDir(intitialTarget, ship:geoposition), 
                    offset
                ).

                if trueRadar() - burnAlt < 1000 { 
                    set pivot to 50.
                } else if trueRadar() - burnAlt < 500 { 
                    set angle to 10.
                } else {
                    set angle to 30.
                }

                if verticalSpeed > 0 {
                    set steering to heading(GeoDir(ship:geoposition, intitialTarget), 0, 0).
                } else  {
                    landingGlide(angle, pivot, vecToLocal(relimpact)).
                }

                set steering to lookdirup(steering:vector, relimpact). // reorientates vessel
            }

            if submode = 4 {
                if not (defined s4) {
                    set offseting to 0 * ((GRAVITY * trueRadar() + .5 * vel:mag^2) / (aNet * trueRadar()) - 1).

                    set printTarget to "Initial Target".

                    for spot in landingSpotsLex:keys {
                        if (landingSpotsLex[spot]:position - impactPos:position):mag < relimpact:mag {
                            set targetlocation to landingSpotsLex[spot].
                            set intitialTarget to landingSpotsLex[spot].
                        }

                        if intitialTarget = landingSpotsLex[spot] { set printTarget to spot:tostring():toUpper(). }
                    }

                    landingPIDs().
                    landingMaxHorSpeed(500). // slightly high
                    rcsLimit(100).

                    set  eastVelPID:Kp to 2. //set the P-Gain lower for the better controlerbility
                    set northVelPID:Kp to 2. //set the P-Gain lower for the better controlerbility

                    set s4 to true.
                    set modeElapsedTimeStart to time:seconds. //End of submode
                }

                landingMaxSteerAngle(.25*maxAlpha).
                

                if defined intitialTarget { 
                    local distl is GeoDist(impactPos, intitialTarget):mag.
                    local hdg   is geodir(intitialTarget, impactPos).

                    local estimatedTime is (vel:mag + sqrt(vel:mag^2 + 2*aNet*trueRadar())).
                    local aCalced       is (2/estimatedTime^2) * (groundspeed*estimatedTime + relimpact:mag) + GRAVITY.
                    local alphaCalced   is min(45, max(0, arcsin(min(1, aCalced/aNet)))).
                    local phi           is Vang(up:vector, -vel).
                    local theta         is (alphaCalced + phi) / 2.

                    if distl > 50 {
                        set comment  to "α: " + round(alphaCalced) + "°, Φ: " + round(phi) + "°, θ: " + round(theta) + "°".
                        set steering to lookdirup(heading(hdg, 90 - alphaCalced):vector, facing:topvector).
                    } else if distl < 50 or verticalSpeed > -100 {
                        set comment        to "target is: " + printTarget.
                        set targetlocation to intitialTarget.
                        
                        landingPIDs().
                        landingMaxHorSpeed(150). // slightly higher

                        set  eastVelPID:Kp to 2. //set the P-Gain lower for the better controlerbility
                        set northVelPID:Kp to 2. //set the P-Gain lower for the better controlerbility
                        
                        unset intitialTarget. //exits loop
                    }

                } else { landingSteer(). }


                local c1B is (GRAVITY * trueRadar() + .5 * vel:mag^2) / (aNet * trueRadar()) - offseting.

                set throttle to c1B.

                //if throttle < thrusts["threshold"] { engSwitcher("CenterOnly"). } else { engSwitcher("ThreeLandings"). }

                //log time:seconds - modeElapsedTimeStart +" "+ vel:mag +" "+ trueRadar() +" "+ suicide():alt +" "+ c1B to ght1.csv. 


                if verticalSpeed > -100 {
                    if defined intitialTarget { 
                        set targetlocation to intitialTarget. 
                        unset intitialTarget.
                    }

                    GEAR on.
                    landingMaxSteerAngle(.5*maxAlpha).

                    if relimpact:mag > 100 {
                        set comment to "100 NOT nominal".                      
                        set submode to 6.
                    } else {
                        set comment to "100 nominal".
                        landingSteer().    
                        
                        if verticalSpeed > -30 {

                            landingPIDs().
                            landingMaxVerticalSpeed(25).

                            set submode to 5.
                        }
                    }
                }
            }

            if submode = 5 {
                if throttle < thrusts["threshold"] { engSwitcher("CenterOnly"). }

                landingMaxSteerAngle(.5*maxAlpha).
                landingSteer().

                if relimpact:mag < 5 and groundspeed < 10 {
                    set comment to "on target".
                    landingAltThrottle(-0.1).
                } else {
                    set comment to "drifting to target".
                   landingAltThrottle(5).
                }
            }

            if submode = 6 {
                if throttle < thrusts["threshold"] { engSwitcher("CenterOnly"). }

                landingVelSteer().
                landingAltThrottle(1).
            }

            if (SHIP:STATUS = "landed" or SHIP:STATUS = "splashed") and (submode >= 4) {
                set r4 to 1.
                unset r4.

                lock throttle to 0.
                lock steering to UP:vector.

                SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
                SET SHIP:CONTROL:NEUTRALIZE TO TRUE.

                wait until VANG(ship:facing:vector, up:vector) < 5.

                unlock throttle.
                unlock steering.

                mode(0).
                
                set modeElapsedTimeStart to time:seconds. //End of runmode
            }

            local esRot is (choose eastRotation  if defined eastRotation  else V(0,0,0)).
            local noRot is (choose northRotation if defined northRotation else V(0,0,0)).

            set v_TUp    to vecDraw(targetlocation:position, 20 * Up:vector, RGB(0,0,1), "Target", 1, true, .5).
            set v_iTUp   to (choose (  vecDraw(intitialTarget:position, 10 * Up:vector, RGB(0,.125,.5), "INTITIAL Target", 1, true, .2)  ) if defined intitialTarget else false).
            set v_relpos to vecDraw(V(0,0,0), relpos, RGB(1,1,0), "error", 1, true, .2, false).
            set v_relDir to vecDraw(V(0,0,0), relimpact/10, RGB(.5,.5,0), "error Dir", 1, true, .2).
            
            set v_Vel       to vecDraw(V(0,0,0),  15*ship:velocity:surface:normalized, RGB(1,0,0), "vel", 1, true, .2).
            set v_InversVel to vecDraw(V(0,0,0), -15*ship:velocity:surface:normalized, RGB(.5,.25,0), "invers Vvl", 1, true, .1).
            set v_steer     to vecDraw(V(0,0,0), 20 * (choose steering if steering:istype("vector") else steering:vector), RGB(1,1,1), "Steering", 1, true, .2).

            set v_eR to vecDraw(V(0,0,0), 16 * esRot:normalized, RGB(1,0,1), "eRot " + round(landingLoger()["lexo"]["eVoutput"]), 1, true, .2).
            set v_nR to vecDraw(V(0,0,0), 16 * noRot:normalized, RGB(0,1,1), "nRot " + round(landingLoger()["lexo"]["nVoutput"]), 1, true, .2).

// TO DOs: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// 1)       make runmode for reseting all/some initialization vars eg. r3, s4
//  -> run 3, sub 2
// 2)       better launch guidance (can wait)
//  -> run xxx, sub xxx          
// 3)       flip Logic needs ENHANCEMENT

        }
}

if runmode = 0 {
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
    
    SAS on.
    RCS on.

    clearScreen.
    clearVecDraws().

    //log profileResult() to profileResults.csv.    
}