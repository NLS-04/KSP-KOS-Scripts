// this method will ensure enhanced (visual) debuging in editor
copypath("0:/lib/lib_Common.ks"  , "").
copypath("0:/lib/lib_Lander.ks"  , "").
copypath("0:/lib/lib_Terminal.ks", "").
runOncePath("lib_Common.ks"  ).
runOncePath("lib_Lander.ks"  ).
runOncePath("lib_Terminal.ks"). 

// this is the more practical method but doesnt provide any editor aids, like auto completion etc
// import("lib/lib_Common"  ).
// import("lib/lib_Lander"  ).
// import("lib/lib_Terminal").

set config:stat to true.

switch to core:volume.

parameter runmodeStart is 1, submodeStart is 0.   

// Initiation ========================================================
    local trAdd     is addons:tr.
    local impactPos is ship:geoposition.
    set   twrMass   to 0.
    set   pres      to 0.
    set   checker   to lex().

    set E   to 10000.
    set v_c to -300. 
// Ttarget ===========================================================
    set landingSpotsLex to lex(
        "Launch_Pad"      , latlng(-0.0972, -74.5575),
        // "VAB"             , latlng(-0.0968, -74.6188),
        "LandingPadCenter", latlng(-0.0979, -74.4739) // is group projected position into Geoposition
    ).

    set landingSpotsLex["LandingPadNorth"] to body:geopositionof(landingSpotsLex["LandingPadCenter"]:position + vecToLocal(V(76,  132, 0))). //group Center offset
    set landingSpotsLex["LandingPadSouth"] to body:geopositionof(landingSpotsLex["LandingPadCenter"]:position + vecToLocal(V(76, -132, 0))). //group Center offset

    global targetlocation to landingSpotsLex["LandingPadCenter"].
// Vectors ===========================================================
    lock relimpact to targetlocation:position - impactPos:position.
    lock relpos    to targetlocation:position - ship:position.
    lock relgeo    to targetlocation:position - ship:geoposition:position.
    lock vel       to ship:velocity:surface.
    lock east      to vCrs(Up:vector, north:vector).

    lock shipRot   to getShipsRotation().
// Parts ===========================================================
    list engines   in englist.
    list parts     in partlist.
    
    local rcsP is ship:partsnamed(ship:partstagged("rcs")[0]:name).
    local finP is ship:partsnamed(ship:partstagged("fin")[0]:name).
    local tank is ship:partstagged("tank1")[0].
    local eng1 is ship:partstagged("eng1")[0].
    local eng2 is choose ship:partstagged("eng2")[0] if englist:length >= 2 else eng1.

    local pStage is choose ship:partstagged("sepPayload")[0]:stage if ship:partstagged("sepPayload"):length > 0 else "NaN".
    local procs  is processorAssignment(list("cpu1", "cpu2")).

    local cpu1 is choose procs["cpu1"] if procs:haskey("cpu1") else core. // cpu1 should be your Bosster cpu
    local cpu2 is choose procs["cpu2"] if procs:haskey("cpu2") else cpu1. // cpu2 should be your Orbiter cpu

    //log "cpu1: " + cpu1:volume:files to path("0:/ght1.csv").
    //log "cpu2: " + cpu2:volume:files to path("0:/ght1.csv").

    set m1 to lex("resParts", list(), "wet", 0, "dry", 0).
    set m2 to lex("resParts", list(), "wet", 0, "dry", 0).
    set payload to 0.

    // if it reboots inflight, it checks if its yet seperated or not 
    if not pStage:istype("String") {
        for p in partlist {
            if not p:tag:matchespattern("ground") { // filters OUT ground
                local res is p:resources.

                // log p to path("0:/ght1.csv.").
                // log "   > Stage:     " + p:stage to path("0:/ght1.csv.").                

                // NOT payload = ]0, pStage[ => payload = [0, pStage]
                if not (p:stage <= pStage and p:stage >= 0) or p:tag:matchespattern("sepPayload") { // checks if its not payload
                    if p:decoupler:isType("string") { // checks if it DOES retrun "NONE" (== Booster-stage) 
                        // log "   > Payload:  1" to path("0:/ght1.csv.").
                        set m1["wet"] to m1["wet"] + p:wetmass. // is absolute pseudo constant
                        set m1["dry"] to m1["dry"] + p:drymass. // is absolute pseudo constant

                        if not res:empty {
                            for r in res {
                                if r:name:matchespattern("LiquidFuel") or r:name:matchespattern("Oxidizer") or r:name:matchespattern("MonoProb") {
                                    m1["resParts"]:add(p). // is variable 
                                    break.
                                }
                            }
                        }
                    } else if p:decoupler:tag:matchespattern("sepOrbiter") {
                        if not p:tag:matchespattern("fairing") {
                            // log "   > Payload:  2" to path("0:/ght1.csv.").
                            set m2["dry"] to m2["dry"] + p:drymass. // is absolute pseudo constant

                            if not res:empty {
                                for r in res {
                                    if r:name:matchespattern("LiquidFuel") or r:name:matchespattern("Oxidizer") or r:name:matchespattern("MonoProb") {
                                        m2["resParts"]:add(p). // is variable 
                                        break.
                                    }
                                }
                            }
                        } else {
                        // log "   > Payload:  2f" to path("0:/ght1.csv.").

                        }

                        set m2["wet"] to m2["wet"] + p:wetmass. // is absolute pseudo constant
                    }
                } else if p:stage <= pStage { // checks if its payload and not in sepPayload
                    // log "   > Payload:  3b" to path("0:/ght1.csv.").
                    set payload to payload + p:mass.
                }
                
                // log "   > Decoupler: " + p:decoupler to path("0:/ght1.csv.").
                // log "   > masses:    " to path("0:/ght1.csv.").
                // log "       > DRY:   " + p:drymass to path("0:/ght1.csv.").
                // log "       > WET:   " + p:wetmass to path("0:/ght1.csv.").
                // log "   > res:       " + res:length to path("0:/ght1.csv.").
                // log "" to path("0:/ght1.csv.").
            } else {
                set twrMass to twrMass + p:mass.
            }
        }
    } else {
        // if its already seperated
        set m1["wet"] to ship:wetmass.
        set m1["dry"] to ship:drymass.
    }

    // log m1      to path("0:/ght1.csv.").
    // log m2      to path("0:/ght1.csv.").
    // log payload to path("0:/ght1.csv.").
    // log pstage  to path("0:/ght1.csv.").

    // log  to path("0:/ght1.csv.").

    function toggleSoot {
        tank:getmodule("ModuleSootyShader"):doevent("toggle soot").
    }
    function engSwitcher {
        parameter mode.

        if mode:matchespattern("AllEngines") or mode:matchespattern("ThreeLanding") or mode:matchespattern("CenterOnly") {
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
            if f:getModule("ModuleAnimateGeneric"):hasevent("extend fins") and (mode:matchespattern("toggle") or mode:matchespattern("extend")) {
                f:getModule("ModuleAnimateGeneric"):doevent("extend fins"). 
                //f:getModule("SyncModuleControlSurface"):setfield("kontrollbegrenzerUI", 52). 
            } else if (mode:matchespattern("toggle") or mode:matchespattern("retract")) {
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
    local mu     is body:mu.
    local radius is body:radius.
    lock GRAVITY to mu / (radius + ALTITUDE)^2. // accel

    lock aNet to max(0.001, (availableThrust / mass) - GRAVITY).

    lock alpha    to VANG(up:vector, ship:facing:vector).
    lock maxAlpha to arccos( min(1, (mass*GRAVITY) / max((mass*GRAVITY), availableThrust))).
    lock maxVang  to min(1, relimpact:mag/500). // 500 is pivot based on dist // !RATIO needs adjustment Factor

    lock TWR to ship:availablethrustat(pres) / (mass*GRAVITY).

    set dv1     to 0.
    set dv1SL   to 0.
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

        printlistl:add("~~~~~~~~~~~~~~~~~~~~ FALCON 4 ~~~~~~~~~~~~~~~~~~~~"                                                 ).
        printlistl:add("Total Time:              " + SecondsToClock(time:seconds - totalElapsedTimeStart)                   ).
        printlistl:add("Mode Elapsed|next Time:  " + SecondsToClock(time:seconds - modeElapsedTimeStart) + " | " + (choose SecondsToClock(nextModeTime) if defined nextModeTime else "---              ")).
        printlistl:add("runmode:                 " + runmode + "        "                                                   ).
        printlistl:add("submode:                 " + submode + "        "                                                   ).
        printlistl:add("steer Mode:              " + landingSteer(targetlocation, false)["steerMode"]                       ).
        printlistl:add("Engine Mode:             " + Eng1:getModule("WBIMultiModeEngine"):getField("current mode")          ).
        printlistl:add("-------------------- COMMENTS --------------------"                                                 ).
        printlistl:add("comment:                 " + comment + "                                                           ").
        printlistl:add("===================== HEIGHT ====================="                                                 ).
        printlistl:add("Altitude:                " + ROUND(altitude/1000, 3) + "    km    "                                 ).
        printlistl:add("Apoapsis:                " + ROUND(Apoapsis/1000, 3) + "    km    "                                 ).
        printlistl:add("-------------------- DYNAMICS --------------------"                                                 ).
        printlistl:add("Throttle:                " + ROUND(100 * throttle,2) + "    %    "                                  ).
        printlistl:add("TWR:                     " + round(twr,2) + "       "                                               ).
        printlistl:add("Dynamic Pressure:        " + ROUND(ship:Q * constant:ATMtokPa, 2) + "    kPa    "                   ).
        printlistl:add("--------------------- STEERS ---------------------"                                                 ).
        printlistl:add("Steer (Pitch, HDG, Roll):" + round(shipRot:y) + ", " + round(shipRot:x) + ", " + round(shipRot:z) + "    °    "  ).
        printlistl:add("dVang (Pitch, Yaw, Roll):" + round(steeringmanager:pitcherror) + ", " + round(steeringmanager:yawerror) + ", " + round(steeringmanager:rollerror) + " => " + abs(round(steeringManager:angleerror)) + "    °    "  ).
        printlistl:add("--------------------- ALPHAS ---------------------"                                                 ).
        printlistl:add("Alpha:                   " + round(alpha) + "    °    "                                             ).
        printlistl:add("    > max:               " + round(maxAlpha) + "    °    "                                          ).
        printlistl:add("Phi:                     " + round(100*maxVang) + "    %    "                                       ).
        printlistl:add("    > x:                 " + round(100*min( 1, ABS(vectolocal(relimpact):x/100))) + "    %    "     ).
        printlistl:add("    > y:                 " + round(100*min( 1, ABS(vectolocal(relimpact):y/100))) + "    %    "     ).
        printlistl:add("---------------------- DIST ----------------------"                                                 ).
        printlistl:add("dist:                    " + round(relimpact:mag, 1) + "    m    "                                  ).
        printlistl:add("dist(east, north):       " + round(vecToLocal(relimpact):x, 1) + ", " + round(vecToLocal(relimpact):y, 1) + "    m    ").
        printlistl:add("-------------------- BURN ALT --------------------"                                                 ).
        printlistl:add("burnAlt:                 " + (choose round(burnAlt)            if (defined burnAlt)                              else "---") + "    m    ").
        printlistl:add("error:                   " + (choose round(altitude - burnAlt) if (defined burnAlt and burnalt:isType("scalar")) else "---") + "    m    "). 
        printlistl:add("start:                   " + (choose round(burnStartIn)        if (defined burnStartIn)                          else "---") + "    s    "). 
        printlistl:add("--------------------- SPEEDS ---------------------"                                                 ).
        printlistl:add("verticalspeed:           " + round(vecToLocal(vel):z, 1) + "    m/s    "                            ).
        printlistl:add("horizontal (east, north):" + round(vecToLocal(vel):x, 1) + ", " + round(vecToLocal(vel):y, 1) + "    m/s    ").
        printlistl:add("----------------------- DV -----------------------"                                                 ).
        printlistl:add("dv Booster:              " + round(dv1) + "    m/s    "                                             ).
        printlistl:add("dv SEA LEVEL:            " + round(dv1SL) + "    m/s    "                                           ).
        printlistl:add("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"                                                 ).
        
        for a in range(0, printlistl:length) {
            print printlistl[a] at (0,a).
        }
    }

//Loop =================================================================================================================================
until runmode = 0 { 
    if letprint {
        PrintUpdater().
    }   

    if terminal:input:haschar {
        if terminal:input:getchar() = terminal:input:enter {
            local setListl is list("runmode", "submode", "Total De-initialize").
            local ch_      is "".

            for j in range(0, terminal:width) {
                set ch_ to ch_ + "-".
            }

            print ch_ at (0, terminal:height - setListl:length - 2).

            for i in range(1, setListl:length + 1) {
                print "[" + i + "] " + setListl[i-1] at (3, terminal:height - setListl:length + i - 2).
            }
            
            set a to terminal:input:getchar().

            if a = "1" {
                mode(TerminalInput("runmode"):tonumber(choose runmode if runmode:istype("scalar") else 1)).
            } else if a = "2" {
                mode(runmode, TerminalInput("submode"):tonumber(submode)).
            } else if a = "3" {
                print "De-initialize ALL entry triggers:" at(0, terminal:height - 2).
                print "YES = ENTER | NO = ELSE" at(5, terminal:height - 1).
                if terminal:input:getchar() = terminal:input:enter { set checker to lex(). }
            }

            clearscreen.
        } 
    }

    set impactPos to (choose trAdd:impactPos if trAdd:hasimpact else ship:geoposition).
    local pres    is body:atm:altitudepressure(altitude).

    set dv1   to max(1, eng1:ispat(pres) * 9.81 * ln((massCalc( m1["resParts"], "fuel") + m1["dry"] ) / m1["dry"] )).
    set dv1SL to max(1, eng1:ispat(1   ) * 9.81 * ln((massCalc( m1["resParts"], "fuel") + m1["dry"] ) / m1["dry"] )).
    // Code ==============================================================
        if runmode = 1 {
            set config:ipu to 1000.
            set letprint   to true.
            
            lock throttle to 0.
            lock steering to "kill".
            
            SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
            SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
            
            wait .1.
            set hdg to 360.

            unlock throttle.
            unlock steering.

            set modeElapsedTimeStart to time:seconds. //End of runmode
            mode("µ").
        }

        if runmode = 2 { // for testing
            if not (defined angle) {
                import("lib/lib_Algorithym").

                if not eng1:ignition { print "ENG 1 NOT ACTIVE      ACTIVATE" at (2, printlistl:length + 3). }
                if not eng2:ignition { print "ENG 2 NOT ACTIVE      ACTIVATE" at (2, printlistl:length + 4). }

                wait until eng1:ignition and eng2:ignition.

                set angle      to 1.2.
                set m02ForSim  to (eng1:availablethrustat(pres) / 9.81) - m1["wet"].
                set letPrint   to false.
                set config:ipu to 2000.
                clearScreen.
            }

            if AG1 {
                mode("µ").
            } else {
                // "m01" = [22600, 136000] 
                // "mf1" = {22600} 
                // "m02" = {eng:thrust / g - mo1} 
                // "mf2" = {5200 + payload}

                set out to launchAlgorithym(
                    lex(
                        "step"      , .05,
                        "eng1"      , eng1,
                        "eng2"      , eng2,
                        "startalt"  , altitude, // roughtly 100 m
                        "endApo"    , 80000,
                        "maxG"      , 2,
                        "m01"       , m1["wet"],
                        "mf1"       , m1["dry"],
                        "m02"       , m02ForSim,
                        "mf2"       , m2["dry"],
                        "body"      , body   
                    ), lex(
                            "dev"   , lex(
                                            "trigger"       , "alt",
                                            "triggerVal"    , 1000,
                                            "val"           , angle              
                                        ),
                            "stage" , lex(
                                            "trigger"       , "dv",
                                            "triggerVal"    , "KSC",
                                            "spaceTime"     , 5              
                                        )
                        )
                ).

                if out:haskey("status") {
                    unset inAlgorithym.
                    set angle to angle + .05.
                }

                lexiprinter(out, 2, 5).
            }
        }

        if runmode = 22 { // for testing
            local s2 is cpu2:part:ship.

            if cpu2:connection:isconnected {
                if cpu2:connection:sendmessage("You're now lonely") { 
                    mode(33). 
                }
            } else if s2:connection:isconnected {
                if s2:connection:sendmessage("You're now lonely") { 
                    mode(44). 
                }
            }
        }

        if runmode = 33 {
            set tp       to vecDraw(V(0,0,0),                19*relimpact:normalized,       red,    "tPoint", 1, true, .2).
            set v_TUp    to vecDraw(targetlocation:position, 20*Up:vector,            RGB(0,0,1),   "Target", 1, true, .5).
            set v_relpos to vecDraw(V(0,0,0),                15*relgeo:normalized,    RGB(1,1,0),   "GEO " + round(vang(relimpact, relgeo), 2), 1, true, .2, false).
        }

        if runmode = 3 { // launch procedure
            if not (checker:haskey(3)) {
                set hdg        to 360*random().
                set pitchAngle to 5.

                set t1 to time:seconds.

                GEAR off.
                SAS off.
                RCS off.

                if not eng1:ignition { DoSaveStage(). }

                set thrusts to getThrusts(). // need to do it in the intialisation cause it has to "physicaly" enumerate the engine in KSP
                set thrusts["threshold"] to thrusts["CenterOnly"] / thrusts["ThreeLanding"].

                wait .125.

                engSwitcher("AllEngines").
                set comment to "Launch initialized".

                set throttle to 1.

                if trueRadar() < 100 and vel:mag < 10 { 
                    mode(3,1). 
                } else { 
                    mode(3,2). 
                }
                
                set checker[3] to true.
            }

            if submode = 1 {
                if ship:availablethrustat(pres) / ((mass - twrMass)*GRAVITY) > 1 { // basicly twr excluding ground
                    DoSaveStage().
                    mode(3,2).

                    local x is sin(hdg).
                    local y is cos(hdg).

                    set upDir to vecToLocal(V(x,y,0)).

                    rcsLimit(50).
                    RCS on.

                    set comment to "Launch sequence normal".
                    set modeElapsedTimeStart to time:seconds. //End of submode
                } else {
                    set comment to "!!TWR " + round(ship:availablethrustat(pres) / ((mass - twrMass)*GRAVITY), 3) + " < 1 !!".
                }
            }

            if submode = 2 {
                lock throttle to maxGThrust(2).

                if altitude > 1000 {
                    set steering to heading(hdg, 90 - pitchAngle, 0).

                    if vang(up:vector, vel) >= pitchAngle {
                        lock steering to lookDirUp(vel, up:vector).

                        steeringManager:resettodefault().

                        rcsLimit(100).
                        RCS off.
                        clearVecDraws().
                        
                        set submode to 3.
                    }
                } else if trueRadar() > 50 {
                    set steering to lookDirUp(up:vector, -upDir).
                    set steeringManager:rollts to 100.
                    set v_updir to vecdraw(V(0,0,0), 7*upDir, rgb(.25, .68, .45), "ROLL HDG " + round(hdg), 1, true, .2).
                } else {
                    set steering to lookDirUp(up:vector, ship:facing:topvector).
                }
            }

            if submode = 3 {
                local dvTrigger is choose boostBack_0A(E, v_c, thrusts["ThreeLanding"]) if altitude > E + 100 else 0.

                set nextModeTime to 125 - (time:seconds - t1).
                set comment to "ddv: " + round(dv1SL - dvTrigger).

                if dv1SL < dvTrigger {
                    RCS on.

                    SAS on.
                    set throttle to 0.1.
                    DoSaveStage(). // Booster-Orbiter seperation
                    SAS off. 
                    set throttle to 0.

                    wait 0.

                    // sends msg to orbiter that they have seperated
                    if cpu2:connection:isconnected {
                        cpu2:connection:sendmessage("You're now lonely").
                    }

                    set t1 to time:seconds.

                    unset nextModeTime.

                    set submode to 4.
                } 
            }

            if submode = 4 {
                if vang(up:vector, facing:vector) < 25 {
                    mode(4,1).
                } else {
                    set steering to up:vector.
                }

                set v_steer to vecDraw(V(0,0,0), 20 * (choose steering if steering:istype("vector") else steering:vector), RGB(1,1,1), "Steering", 1, true, .2).
            }
        }

        if runmode = 4 { // return to target
            if not (checker:haskey(4)) {
                GEAR off.
                SAS off.
                RCS on.

                //global targetlocation to landingSpotsLex["LandingPadCenter"].
                
                set thrusts to getThrusts(). // need to do it in the intialisation cause it has to "physicaly" enumerate the engine in KSP
                set thrusts["threshold"] to thrusts["CenterOnly"] / thrusts["ThreeLanding"].

                wait .125.

                set throttle to 0.
                flipBy(). // resets raw inputs
                //set submode to 1. //currently disabled due to FLIPBY()

                set comment to "turning for boostback".

                set checker[4] to lex(0, true).
            }

            if submode = 1 {
                if not (checker[4]:haskey(1)) {
                    set checker[4][1] to true.
                    set comment to "turning for Boostback".
                }

                set steering to Heading(GeoDir(targetlocation, impactPos), 0, 180).

                if (VANG(Up:vector, facing:vector) > 45 and VANG(steering:vector, facing:vector) < 55) {
                    engSwitcher("ThreeLanding").
                    
                    set comment to "boostback started".
                    set submode to 21.
                }
            }

            if submode = 2 {
                local offset is GeoHdgoffset( targetlocation, GeoDir( targetlocation, ship:geoposition ), 200 ).

                if (offset:position - impactPos:position):mag < 100 or (defined triggerOverride) {
                    if not (defined triggerOverride) {
                        set triggerOverride to time:seconds.
                        set comment to "turning for Glideback".
                        set modeElapsedTimeStart to time:seconds. //End of submode
                        
                        set throttle to 0.  
                        set steering to Heading(GeoDir(ship:geoposition, targetlocation), 0). 

                        set steeringManager:yawtorquefactor  to 0.
                        set steeringManager:rolltorquefactor to 0.                  

                        flipBy(V(0, -.75, 0), 5).
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
                    set throttle to 0.0001 * (offset:position - impactPos:position):mag * cos(vang(steering:vector, facing:vector)).
                    set steering to heading( geodir( offset, impactPos), 0, 180 ). // ROLL(180) due to flip
                }
            }

            if submode = 21 {
                local lexi is boostBack_A(E).
                local p_x is lexi["p_x"].
                local I_x is lexi["I_x"].

                local tPoint is GeoHdgoffset( targetlocation, GeoDir( targetlocation, ship:geoposition ), I_x ).
                local imp    is tPoint:position - impactPos:position.
                local geo    is tPoint:position - ship:geoposition:position.
                local ang    is vang(imp, geo).
                
                set steering to heading( geoDir(tPoint, impactPos), 0, 180). // ROLL(180) due to flip
                set throttle to 0.002 * relimpact:mag * cos(vang(facing:vector, steering:vector)).

                set Vimp to vecDraw(V(0,0,0), 20*imp:normalized, red, "imp " + round(ang, 2), 1, true, .2).
                set Vgeo to vecDraw(V(0,0,0), 20*geo:normalized, green, "geo", 1, true, .2).

                set comment to "p_x: " + round(p_x - groundspeed).

                if (ang < 90 and groundspeed > p_x) or ang > 120 {  
                    set throttle to 0.
                    clearVecDraws().
                    finToggle("extend").
                set modeElapsedTimeStart to time:seconds. //End of submode
                    set submode to 22.
                }
            }

            if submode = 22 {
                local B_h is boostBack_AB(v_c, thrusts["ThreeLanding"]).

                set steering to lookDirUp(-vel, up:vector).

                if altitude < B_h {
                    set submode to 23.
                set modeElapsedTimeStart to time:seconds. //End of submode
                    set throttle to 1.
                    set initialDir to relimpact.
                    lamda(v_c).
                }
            }

            if submode = 23 {
                set steering to lookDirUp( heading( GeoDir(ship, impactPos), a_c ):vector, up:vecctor ).

                if vang(intialDir, relimpact) > 90 {
                    set throttle to 0.

                    set submode to 3.
                }
            }

            if submode = 3 {
                if not (checker[4]:haskey(3)) {
                    set throttle to 0.
                    SAS off.

                    engSwitcher("ThreeLanding").
                    fintoggle("extend").
                    rcsLimit(100). 
                    flipBy(). // resets raw inputs
                    
                    set intitialTarget to targetlocation.
                    set angle to 30.
                    set pivot to 100.
                    
                    set checker[4][3] to true.
                }

                // toggles soot for 'reentry-(visual-)effect' 
                if not (defined soot) {
                    if altitude < 15000 {
                        toggleSoot().
                        set soot to true.
                    }
                }

                suicideStarter(runmode, 4).
                //log eastPosPID:error +" "+ eastPosPID:output +" "+ eastVelPID:output +" "+ northPosPID:error +" "+ northPosPID:output +" "+ northVelPID:output to path("0:/ght1.csv").
                //lexiprinter	(landingLoger()["lexo"], printlistl:length + 4, 6).
                // log (time:seconds - modeElapsedTimeStart) +" "+ altitude +" "+ body:atm:altitudepressure(altitude) +" "+ vel:mag +" "+ vel:mag*body:atm:altitudepressure(altitude) to path("0:/ght1.csv"). 
                // log (time:seconds - modeElapsedTimeStart) +" "+ altitude +" "+ body:atm:altitudepressure(altitude)*constant:atmtokpa +" "+ vel:mag +" "+ vel:mag*body:atm:altitudepressure(altitude)*constant:atmtokpa to path("0:/ght11.csv"). 

                local offset is min(max(relgeo:mag/50, 50), 400).
                // local offset is 200.

                set comment to "off: " +round(offset, 2) + " m, piv: " + round(pivot) + " m".

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
                } else {
                    landingGlide(angle, pivot, vecToLocal(relimpact)).

                    if altitude > 20000 {
                        set steering to lookdirup(-vel, relimpact).
                    }
                }

                set steering to lookdirup(steering:vector, relimpact). // reorientates vessel
            }

            if submode = 4 {
                if not (checker[4]:haskey(4)) {
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

                    set checker[4][4] to true.
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

                landingsteer().


                local c1B is (GRAVITY * trueRadar() + .5 * vel:mag^2) / (aNet * trueRadar()) - offseting.

                set throttle to c1B.

                //if throttle < thrusts["threshold"] { engSwitcher("CenterOnly"). } else { engSwitcher("ThreeLandings"). }

                //log time:seconds - modeElapsedTimeStart +" "+ vel:mag +" "+ trueRadar() +" "+ suicide():alt +" "+ c1B to path("0:/ght1.csv").


                if verticalSpeed > -100 {
                    if defined intitialTarget { 
                        set targetlocation to intitialTarget. 
                        unset intitialTarget.
                    }

                    GEAR on.
                    landingMaxSteerAngle(.5*maxAlpha).

                    if relimpact:mag > 100 {
                        set comment to "100 NOT nominal". 
                        landingMaxVerticalSpeed(10).                     
                        
                        set submode to 6.
                    } else {
                        set comment to "100 nominal".
                        landingSteer().    
                        
                        if verticalSpeed > -30 {

                            landingPIDs().
                            landingMaxVerticalSpeed(10).

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
                    landingMaxVerticalSpeed(5).
                    landingAltThrottle(0).
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
            set v_steer     to vecDraw(V(0,0,0),  20*(choose steering if steering:istype("vector") else steering:vector), RGB(1,1,1), "Steering", 1, true, .2).

            set v_eR to vecDraw(V(0,0,0), 16 * esRot:normalized, RGB(1,0,1), "eRot " + round(landingLoger()["lexo"]["eVoutput"]), 1, true, .2).
            set v_nR to vecDraw(V(0,0,0), 16 * noRot:normalized, RGB(0,1,1), "nRot " + round(landingLoger()["lexo"]["nVoutput"]), 1, true, .2).

// TO DOs: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// 1)       ---
//  -> run 3, sub 2
// 2)       (better launch guidance)
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

    switch to 0.
    
    //log profileResult() to path("0:/profileResults.csv").    
}