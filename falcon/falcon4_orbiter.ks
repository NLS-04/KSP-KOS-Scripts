// this method will ensure enhanced (visual) debuging in editor
copypath("0:/lib/lib_Common.ks"  , "").
copypath("0:/lib/lib_Terminal.ks", "").
runOncePath("0:/lib/lib_Common.ks"  ).
runOncePath("0:/lib/lib_Terminal.ks").

// this is the more practical method but doesnt provide any editor aids, like auto completion etc
// import("lib/lib_Common"  ).
// import("lib/lib_Terminal").

set config:stat to true.

parameter runmodeStart is 1, submodeStart is 0.   

// Initiation ========================================================
    set pres    to 0.
    set checker to lex().
    set comment to "Programm Loaded".
// Ttarget ===========================================================

// Vectors ===========================================================
    lock vel       to ship:velocity:surface.
    lock east      to vCrs(Up:vector, north:vector).

    lock shipRot   to getShipsRotation().
// Parts ===========================================================
    list engines in elist.
    list parts   in plist.
    local dExist is false.
    local pStage is 0.

    local mother is ship:shipname.

    if mother:endswith("trümmer") {
        set mother to mother:remove(mother:length - 8, 8).
    } else if mother:endswith("relais") {
        set mother to mother:remove(mother:length - 7, 7).
    }

    local mother is vessel(mother).

    local pStage is choose ship:partstagged("sepPayload")[0]:stage if ship:partstagged("sepPayload"):length > 0 else 0.
    local dExist is choose true if ship:partstagged("sepOrbiter"):length > 0 else false.
    local procs  is processorAssignment(list("cpu1", "cpu2")).

    local eng2 is choose ship:partstagged("eng2")[0] if ship:partstagged("eng2"):length > 0   else elist[0].
    // local cpu1 is choose procs["cpu1"] if procs:haskey("cpu1") else processorAssignment(list("cpu1"), mother)["cpu1"]. // cpu1 should be your Bosster cpu
    local cpu2 is choose procs["cpu2"] if procs:haskey("cpu2") else core.                                              // cpu2 should be your Orbiter cpu
    local fairing is choose ship:partsnamed(ship:partstagged("fairing")[0]:name) if ship:partstagged("fairing"):length > 0 else "NaN".

    local msg  is ship:messages.
    local msg2 is core:messages.

    set m2 to lex("resParts", list(), "wet", 0, "dry", 0).
    set payload to 0.

    for p in plist {
        if not (p:tag:matchespattern("ground") or p:tag:matchespattern("fairing")) { // filters OUT ground & fairings
            local res is p:resources.

            if p:stage > pStage or p:tag:matchespattern("sepPayload") { // checks if its not payload
                if p:decoupler:isType("string") { // checks if it DOES retrun "NONE" (== 'active'-stage) 
                    // if they would be still undecoupled
                    // 'active'-stage woukd be Booster 
                    // => NOT interresting for us

                    if not dExist { // checks if 'active'-stage is Orbiter
                        set m2["dry"] to m2["dry"] + p:drymass. // is absolute pseudo constant
                        set m2["wet"] to m2["wet"] + p:wetmass. // is absolute pseudo constant

                        if not res:empty {
                            for r in res {
                                if r:name:matchespattern("LiquidFuel") or r:name:matchespattern("Oxidizer") or r:name:matchespattern("MonoProb") {
                                    m2["resParts"]:add(p). // is variable 
                                    break.
                                }
                            }
                        }
                    }

                } else if p:decoupler:tag:matchespattern("sepOrbiter") {
                    set m2["dry"] to m2["dry"] + p:drymass. // is absolute pseudo constant
                    set m2["wet"] to m2["wet"] + p:wetmass. // is absolute pseudo constant

                    if not res:empty {
                        for r in res {
                            if r:name:matchespattern("LiquidFuel") or r:name:matchespattern("Oxidizer") or r:name:matchespattern("MonoProb") {
                                m2["resParts"]:add(p). // is variable 
                                break.
                            }
                        }
                    }
                }
            } else if p:stage <= pStage and p:stage >= 0 { // checks if its payload
                set payload to payload + p:mass.
            } 
        }
    }
    
    // log m2      to path("0:/ght1.csv.").
    // log payload to path("0:/ght1.csv.").

    function fairingJettison {
        if not fairing:istype("string") {
            for p in fairing {
                p:getmodule("ModuleDecouple"):doevent("entkoppeln").
            }

            set fairing to "NaN".
        }
    }

// Variables ===========================================================
    local mu       is body:mu.
    local radius   is body:radius.
    lock GRAVITY   to mu / (radius + ALTITUDE)^2. // accel

    lock TWR to ship:availablethrustat(pres) / (mass*GRAVITY).

    set dv2     to 0.
// Code ===========================================================
    // Initialisation
        set throttle to 0.
        set steering to "kill".

        clearscreen.
        clearVecDraws().

        set config:ipu to 1000.
        set terminal:width  to 50.
        set terminal:height to 45.
        
        mode(runmodeStart, submodeStart).
        set letPrint to true.

        set totalElapsedTimeStart to time:seconds.
        set modeElapsedTimeStart  to time:seconds.
        
    //Terminal out ===========================================================
    function PrintUpdater {
        set printlistl to list().

        printlistl:add("~~~~~~~~~~~~~~~~~~~~ FALCON 4 ~~~~~~~~~~~~~~~~~~~~"                                                 ).
        printlistl:add("Total Time:              " + SecondsToClock(time:seconds - totalElapsedTimeStart)                   ).
        printlistl:add("Mode Elapsed|next Time:  " + SecondsToClock(time:seconds - modeElapsedTimeStart) + " | " + (choose SecondsToClock(nextModeTime) if defined nextModeTime else "---              ")).
        printlistl:add("runmode:                 " + runmode + "        "                                                   ).
        printlistl:add("submode:                 " + submode + "        "                                                   ).
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
        printlistl:add("--------------------- SPEEDS ---------------------"                                                 ).
        printlistl:add("verticalspeed:           " + round(vecToLocal(vel):z, 1) + "    m/s    "                            ).
        printlistl:add("horizontal (east, north):" + round(vecToLocal(vel):x, 1) + ", " + round(vecToLocal(vel):y, 1) + "    m/s    ").
        printlistl:add("----------------------- DV -----------------------"                                                 ).
        printlistl:add("dv Orbiter:              " + round(dv2) + "    m/s    "                                             ).
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

    local pres is body:atm:altitudepressure(altitude).

    set dv2 to max(1, eng2:ispat(pres) * 9.81 * ln((massCalc( m2["resParts"], "fuel") + m2["dry"] ) / m2["dry"] )).
    // Code ==============================================================
        if runmode = 1 {
            set config:ipu to 1000.
            set letPrint   to true.
            
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
            fairingJettison().
            mode(1).            
        }

        if runmode = 22 { // for testing
            // set letPrint to false.

            log "MSG  EMPTY: " + msg:empty  to path("0:/ght1.csv").
            log "MSG2 EMPTY: " + msg2:empty to path("0:/ght1.csv").

            if not msg2:empty {
                log "   > MSG2 SENDER: " + msg2:peek():sender to path("0:/ght1.csv").
                log "   > MSG2 CONTENT: " + msg2:pop:content  to path("0:/ght1.csv").
            }
            
            if not msg:empty {
                log "   > MSG SENDER: " + msg:peek():sender to path("0:/ght1.csv").
                log "   > MSG CONTENT: " + msg:pop:content  to path("0:/ght1.csv").
            }

            mode(1).
        }

    // <==============================================================================================>
    //  ! BECAUSE falcon_booster already inherites runmode 3 & 4 THEY MUSTN'T be used in the ORBITER !
    // <==============================================================================================>

        if runmode = 5 { 
            if not checker[5]:haskey(0) {
                lock throttle to 0.
                lock steering to "kill".
                
                SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
                SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
                
                wait .1.

                unlock throttle.
                unlock steering.

                set modeElapsedTimeStart to time:seconds. //End of runmode
                mode(5,1).
            }

            if submode = 1 {
                // waiting for seperation
                if not msg2:empty {
                    if msg2:peek():sender = cpu1 {
                        RCS on.
                        mode(5,2).
                    } else {
                        set comment to msg2:peek():sender.
                    }
                }
            }

            if submode = 2 {
                local distShips is (cpu1:part:ship:position - ship:position):mag.
                
                if distShips < 5 {
                    set steering to lookdirup(vel, facing:topVector).
                    set throttle to 0.
                } else {
                    mode(6).
                }
            }
        }
}

if runmode = 0 {
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
    
    SAS on.
    RCS on.

    clearScreen.
    clearVecDraws().

    //log profileResult() to path("0:/profileResults.csv").
}