@lazyGlobal off.

copypath("0:/_lib/Terminal.ks", "1:").
runOncePath("1:Terminal.ks").
// #include "0:_lib/Terminal.ks"

parameter runmodeStart is 0, submodeStart is 0, CPU_UID is choose ship:partstaggedpattern("CPU")[0]:uid if ship:partstaggedpattern("CPU"):length > 0 else core:part:uid.
local CPU_PROC is {for proc in ship:modulesnamed("kosprocessor") { if proc:part:uid = CPU_UID { return proc. } } }.
set CPU_PROC to CPU_PROC:call().

local runmode is runmodeStart.
local submode is submodeStart.

// AT STARTUP:
//  CPU:
//      - runmode initialized & synced
//      - GPU is set
//     => recieve runmode Info List request
//     <= Send runmode Info List
//
//  GPU:
//      - runmode initialized & synced
//      - CPU is set
//     <= send runmode Info List request
//     => Await runmode Info List

// log  to path("0:/a.ks").

// #region initialisation
    local holdTime is 0.

    local printUpdate is list(
        list(0, list( list("TZero",
                        {return diffTime(TZero, "T").}, 
                        {return 41.},
                        1
                    ), list("TNext",
                        {return diffTime(TNext, "N").}, 
                        {return 41.},
                        2
                    ) )) 
    ).

    local section_Ptr_lex is lex().
    local module is lex(
        "OrbitInfo",    lex(
                            "on",       ON_OrbitInfo@,
                            "off",      OFF_OrbitInfo@,
                            "toggle",   TOGGLE_OrbitInfo@
                        ),
        "ProxOpInfo",    lex(
                            "on",       ON_ProxOpInfo@,
                            "off",      OFF_ProxOpInfo@,
                            "toggle",   TOGGLE_ProxOpInfo@
                        ),
        "DisplayInfo",  lex(
                            "on",       ON_DisplayHandle@,
                            "off",      OFF_DisplayHandle@,
                            "toggle",   TOGGLE_DisplayHandle@
                        )
    ).
    // Virtual Calculation RAM
    local VC_RAM is lex(). // [ key, func ] ==> outputs funcs values to same key in V_Ram
    local V_RAM is lex().  // [ key, value ] 

    local displayInfoVariables is list(true).
    local ptr_bottom is 6. // not 0; 0 would be above/ in the first section

    local TZero is time:seconds. // constant refernce times
    local TNext is time:seconds. // constant refernce times

    local runmodeInfoList is lex().
    local logList is list().
// #endregion

// #region variables
    // #region intercom
        local procIO is list(false, false).
        local gpuI is {parameter state. set procIO[0] to state. print choose "•" if state else " " at (42, 4).}.
        local gpuO is {parameter state. set procIO[1] to state. print choose "•" if state else " " at (44, 4).}.

        local CORE_UID is core:part:UID.
        local CORE_NET is core:messages.

        local DPCNet is lex(). // Direct_Processor_Communication_Network = lex(PROC_UID, PROC)
        local  onNet is {parameter UID, mode, data. gpuO(true). DPCNet[UID]:connection:sendmessage( list(CORE_UID, list(mode, data)) ).}.
        local offNet is {if not CORE_NET:empty { gpuI(true). return CORE_NET:pop:content. } else { return false. }}.

        // MASTER[CPU] -> SLAVE[GPU]
        local Net_RX is Lex(
            "Set_runmodeInfoList",  {parameter from, data. set runmodeInfoList to data. runmodeLister().},
            "Set_TargetOrbit",      {parameter from, data. set Target_Orbit to data. module:OrbitInfo:on().},
            "Set_runmode",          {parameter from, data. set runmode to data. runmodeLister().},
            "Set_TZero",            {parameter from, data. set TZero to data.},
            "Set_TNext",            {parameter from, data. set TNext to data.},
            "Set_logList",          {parameter from, data. set logList to data. logLister().},
            "Set_Comment",          {parameter from, data. logList:add(data). logLister().},
            "Set_TargetPort",       {parameter from, data. set V_RAM:ProxOp_Toffset to data.},
            "Set_ShipPort",         {parameter from, data. set V_RAM:ProxOp_Soffset to data.},

            "Get_TargetOrbit",      {parameter from, data. onNet(from, "Set_TargetOrbit", Target_Orbit).},
            "Get_logList",          {parameter from, data. onNet(from, "Set_logList", logList).},
            "Get_TZero",            {parameter from, data. onNet(from, "Set_TZero", TZero).},
            "Get_TNext",            {parameter from, data. onNet(from, "Set_TNext", TNext).},            
            "Get_Input",            {parameter from, data. onNet(from, "Set_Input", inputHandle(data)).},

            "Set_Display",          {parameter from, data. if data:istype("list") ON_DisplayHandle(data). else OFF_DisplayHandle().},
            "CPU_REBOOT",           {parameter from, nullData. onNet(from, "FORCED_BOOT", runmode).}
        ).

        // SLAVE[GPU] -> MASTER[CPU]
        local Net_TX is Lex(
            "Get_runmodeInfoList", {return 0.},
            "Get_TargetOrbit",     {return 0.},
            "Get_logList",  {return 0.},
            "Get_runmode",  {return 0.},
            "Get_TZero",    {return 0.},
            "Get_TNext",    {return 0.},
            
            "Set_Input",    {return "InputAnswer".},
            "Set_runmode",  {return runmode.}
        ).

        local function sendCPU {
            parameter mode, data is "null". // set stuf that needs to be send
            local dataToSend is choose Net_TX[mode]:call() if data = "null" else data.
            onNet(CPU_UID, mode, dataToSend).
        }

        if CPU_UID <> CORE_UID
            set DPCNet[CPU_UID:tostring()] to CPU_PROC.

        local Comunication is {
            parameter content.
            
            if RT:hasKscConnection(ship) {
                log "" to path("0:/a.csv").
                log "GPU: " + content[0] +" -> "+ content[1][0] to path("0:/a.csv").
                log "  " + content[1][1] to path("0:/a.csv").
            }
        }.

        local RT is 0. 
        if addons:available("RT")
            set RT to addons:RT. 
        else
            set Comunication to {parameter _.}.
        
    // #endregion

    // #region default orbit vals
        local selfOrbit is ship:orbit.

        local Target_Orbit is lex(
            "Apo", 80.000,
            "Per", 80.000,
            "SMA", 80.000,
            "Inc", 0,
            "LAN", body:rotationangle + ship:geoposition:lng + 2.5,
            "AoP", 0, // INOP ATM
            "ECC", 0
        ).

        lock selfOrbAPO to .001*selfOrbit:apoapsis.
        lock selfOrbPER to .001*selfOrbit:periapsis.
        lock selfOrbSMA to .001*selfOrbit:semimajoraxis.

        set V_RAM:ProxOp_Toffset to ship:dockingports[0]:position.
        set V_RAM:ProxOp_Soffset to ship:dockingports[0]:position.

        set V_RAM:DisplayHandle_Vars to list( list("HEADER", " ### TEST ### "), list("VAR", "testVar:     ", "defaultValue"), list("TXT", "this is a lovely Text :)") ).
    // #endregion
// #endregion

function Vec2Ship {
    parameter vecI.

    return list(
        vdot(vecI, ship:facing:foreVector),
        vdot(vecI, ship:facing:topVector),
        vdot(vecI, ship:facing:starVector)
    ).
}


local function diffTime {
    parameter timePoint, leading.
    local difTime is timePoint - time:seconds. 
    return choose leading+"+"+SecondsToClock(difTime, true) if difTime < 0 else leading+"-"+SecondsToClock(difTime, true).
}

local function middleString {
    parameter string, space, spacer is " ", hasleftTendency is true.

    local offset is space - string:length/2.

    local whites is "".
    for i in range(2*offset)
        set whites to whites + spacer.

    local out is whites:insert( (choose floor(offset) if hasleftTendency else ceiling(offset)), string).

    return out.
}

local function RightString {
    parameter string, space, spacer is " ".

    local offset is space - string:length.

    local whites is "".
    for i in range(offset) 
        set whites to whites + spacer.

    return whites + string.
}

local function decimalAlign {
    parameter rightSideIndex, scalar.
    return rightSideIndex - floor(scalar):tostring():length.
}


local function setFrame {
    set terminal:width to 54.
    set terminal:height to 31.

    print "
┌ =================== AURIGA III ================== ┐
│ •                                    │ T+00:00:00 │
│ •                                    │ N-00:00:00 │
│―> [?] ... Requesting Programs ...    │> CPU_MAIN <│
│ •                                    │ [*|*] [*]  │
│ •                                    │ [*] Input  │
│――――――――――――――――――――――――――――――――――――― + ―――――――――――│
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│                                                   │
│―――――――――――――――――――――――――――――――――――――――――――――――――――│
│                                                   │
└ ================================================= ┘".
}
local function logLister {
    if logList:length = 0 { return. }

    local bottom is terminal:height-4.

    for index in range(1, MIN(logList:length, bottom - ptr_bottom)) {
        print "│                                                   │" at (0, bottom - index).
        local printString is "["+SecondsToClock(logList[logList:length - index][0]-TZero)+"] "+ logList[logList:length - index][1].
        if printString:length > 49 {set printString to printString:remove(49, printString:length-49).}

        print printString at (2, bottom - index).
    }
}
local function runmodeLister {
    // 5 lines x 34 Charackters[6(mode) + 28(info)]
    // runmode/submode range (atm.) = [0, 99]
    parameter lexi is runmodeInfoList, Rmode is runmode, Smode is submode.

    local squeezFlag is "•".
    
    local RmodeS to Rmode:toString().
    local SmodeS to Smode:toString().

    local relcol is 4.
    local p is {
        parameter r, s, i, l. 
        print "["+r + (choose " | " + s if s > 0 else "") + "]" at (relcol, l).
        print i at (relcol+5, l).
    }.

    for i in range(1,6) { // clear the fields
        print "                                  " at (relcol, i).
    }

    if lexi:haskey(RmodeS) {
        if lexi[RmodeS]:istype("String") { // == no Submodes for that runmode (submode => new lex())
            p(Rmode, Smode, lexi[RmodeS], 3). 
        } else {
            p(Rmode, Smode, lexi[RmodeS][SmodeS], 3). 
        }
    } else {
        p(Rmode, Smode, "", 3). 
    }

    local lastR is Rmode.
    local lastS is 0.
    for line in range(2,0) {
        for lowwer in range(lastR-1, -1) {
            if lexi:haskey(lowwer:toString()) {
                print (choose squeezFlag if lowwer < lastR-1 else " ") at (2, line).
                set lastR to lowwer.
                p(lowwer, Smode, lexi[lowwer:toString()], line).
                break.
            }
        }
    }

    set lastR to Rmode.
    set lastS to 0.
    for line in range(4,6) {
        for upper in range(lastR+1, 100) {
            if lexi:haskey(upper:toString()) {
                print (choose squeezFlag if upper > lastR+1 else " ") at (2, line).
                set lastR to upper.
                p(upper, Smode, lexi[upper:toString()], line).
                break.
            }
        }
    }
    
}

local function DataSectionPrinter {
    for section in printUpdate { // gets the reletive section line number
        local secLine is section[0].

        for element in section[1] {
            print element[1]:call() at (element[2]:call(), element[3] + secLine).
        }
    }
}
local function netHandle {
    local netContent is offNet().

    if netContent:istype("boolean") or not netContent:istype("list") { return. }
    if not Net_RX:haskey(netContent[1][0]) { return. }

    if procIO[0] { gpuI(false). }
    if procIO[1] { gpuO(false). }

    Comunication(netContent).

    ipuAdjuster().
    
    Net_RX[netContent[1][0]]:call(netContent[0], netContent[1][1]). // Net_RX['command']:call('from', 'data')
}
local function ipuAdjuster {
    parameter listLength is CORE_NET:length, max is 20, default is 0.5.

    if listLength <= max
        set holdTime to default * ( 1 - listLength/max ).
    else 
        CORE_NET:clear().
    
    print round( 100*listLength/max )+"] " at (48, 4).
}
local function VC_Calc {
    for calc in VC_RAM:keys {
        set V_RAM[calc] to VC_RAM[calc]:call().
    }
}


local function __offModule {
    parameter key, linesRefreshed.

    if not section_Ptr_lex:haskey(key) 
        return.

    for line in range(0, linesRefreshed+1) {
        print "                                                   " at(1, section_Ptr_lex[key]+1 + line).
    }

    for sectionIndex in range(printUpdate:length-1, -1) {
        if printUpdate[sectionIndex][0] > section_Ptr_lex[key]
            set printUpdate[sectionIndex][0] to printUpdate[sectionIndex][0] - linesRefreshed-1.
        
        if printUpdate[sectionIndex][0] = section_Ptr_lex[key] 
            printUpdate:remove(sectionIndex).
    }

    set ptr_bottom to ptr_bottom - linesRefreshed-1.

    section_Ptr_lex:remove(key).

    for activeModule in section_Ptr_lex:keys {            
        if module:haskey(activeModule) { if module[activeModule]:hassuffix("on") { module[activeModule]:on(). } }
    }
}

local function ON_OrbitInfo {
    OFF_OrbitInfo().

    set section_Ptr_lex["OrbitInfo"] to ptr_bottom.

    print " ▪▪▪ │   CURRENT   │    TARGET   │  Δ DELTA   │ ▪▪ " at (1, ptr_bottom + 1).
    print " Apo │             │             │            │ km " at (1, ptr_bottom + 2).
    print " Per │             │             │            │ km " at (1, ptr_bottom + 3).
    print " SMA │             │             │            │ km " at (1, ptr_bottom + 4).
    print " Inc │             │             │            │  ° " at (1, ptr_bottom + 5).
    print " LAN │             │             │            │  ° " at (1, ptr_bottom + 6).
    print " AoP │             │             │            │  ° " at (1, ptr_bottom + 7).
    print " ECC │             │             │            │    " at (1, ptr_bottom + 8).
    print "―――――――――――――――――――――――――――――――――――――――――――――――――――" at (1, ptr_bottom + 9).

    printUpdate:add(list(ptr_bottom, list( 
        list("", {return round(selfOrbAPO, 3).},                    {return decimalAlign(13, selfOrbAPO).},                    2),
        list("", {return round(selfOrbPER, 3).},                    {return decimalAlign(13, selfOrbPER).},                    3),
        list("", {return round(selfOrbSMA, 3).},                    {return decimalAlign(13, selfOrbSMA).},                    4),
        list("", {return round(selfOrbit:inclination, 3).},         {return decimalAlign(13, selfOrbit:inclination).},         5),
        list("", {return round(selfOrbit:LAN, 3).},                 {return decimalAlign(13, selfOrbit:LAN).},                 6),
        list("", {return round(selfOrbit:ArgumentOfPeriapsis, 3).}, {return decimalAlign(13, selfOrbit:ArgumentOfPeriapsis).}, 7),
        list("", {return round(selfOrbit:eccentricity, 3).},        {return decimalAlign(13, selfOrbit:eccentricity).},        8),

        list("", {return round(Target_Orbit:Apo - selfOrbAPO, 3).},                    {return decimalAlign(40, Target_Orbit:Apo - selfOrbAPO).},                    2),
        list("", {return round(Target_Orbit:Per - selfOrbPER, 3).},                    {return decimalAlign(40, Target_Orbit:Per - selfOrbPER).},                    3),
        list("", {return round(Target_Orbit:SMA - selfOrbSMA, 3).},                    {return decimalAlign(40, Target_Orbit:SMA - selfOrbSMA).},                    4),
        list("", {return round(Target_Orbit:Inc - selfOrbit:inclination, 3).},         {return decimalAlign(40, Target_Orbit:Inc - selfOrbit:inclination).},         5),
        list("", {return round(Target_Orbit:LAN - selfOrbit:LAN, 3).},                 {return decimalAlign(40, Target_Orbit:LAN - selfOrbit:LAN).},                 6),
        list("", {return round(Target_Orbit:AoP - selfOrbit:ArgumentOfPeriapsis, 3).}, {return decimalAlign(40, Target_Orbit:AoP - selfOrbit:ArgumentOfPeriapsis).}, 7),
        list("", {return round(Target_Orbit:ECC - selfOrbit:eccentricity, 3).},        {return decimalAlign(40, Target_Orbit:ECC - selfOrbit:eccentricity).},        8)
    ))).

    set ptr_bottom to ptr_bottom + 9.

    updateTargetorbit().
}
local function OFF_OrbitInfo {
    __offModule("OrbitInfo", 8).
}
local function TOGGLE_OrbitInfo {
    if section_Ptr_lex:haskey("OrbitInfo") { OFF_OrbitInfo(). } else { ON_OrbitInfo(). }
}
local function updateTargetorbit {
    if not section_Ptr_lex:haskey("OrbitInfo") { return. }

    local sectionLine is section_Ptr_lex["OrbitInfo"].

    print round( Target_Orbit:Apo, 3 ) at ( decimalAlign(28, Target_Orbit:Apo ), sectionLine + 2 ).
    print round( Target_Orbit:Per, 3 ) at ( decimalAlign(28, Target_Orbit:Per ), sectionLine + 3 ).
    print round( Target_Orbit:SMA, 3 ) at ( decimalAlign(28, Target_Orbit:SMA ), sectionLine + 4 ).
    print round( Target_Orbit:Inc, 3 ) at ( decimalAlign(28, Target_Orbit:Inc ), sectionLine + 5 ).
    print round( Target_Orbit:LAN, 3 ) at ( decimalAlign(28, Target_Orbit:LAN ), sectionLine + 6 ).
    print round( Target_Orbit:AoP, 3 ) at ( decimalAlign(28, Target_Orbit:AoP ), sectionLine + 7 ).
    print round( Target_Orbit:ECC, 3 ) at ( decimalAlign(28, Target_Orbit:ECC ), sectionLine + 8 ).
}

local function ON_ProxOpInfo {
    OFF_ProxOpInfo().

    set section_Ptr_lex["ProxOpInfo"] to ptr_bottom.

    print " Proximity Operation:                    Mode_Name " at ( 1, ptr_bottom + 1 ).
    print "      │  Δ DISTANCE  |  Δ VELOCITY  | δ/s PYR RATE " at ( 1, ptr_bottom + 2 ).
    print " Fore │           m  │          m/s │    INOP  °/s " at ( 1, ptr_bottom + 3 ).
    print " Top  │           m  │          m/s │    INOP  °/s " at ( 1, ptr_bottom + 4 ).
    print " Star │           m  │          m/s │    INOP  °/s " at ( 1, ptr_bottom + 5 ).
    print "  MAG │           m  │          m/s │    INOP  °/s " at ( 1, ptr_bottom + 6 ).
    print "―――――――――――――――――――――――――――――――――――――――――――――――――――" at ( 1, ptr_bottom + 7 ).

    set VC_RAM:ProxOp_hasTgt  to { if hasTarget { if not target:istype("vessel") set target to target:ship. return true. } else return false. }.
    set VC_RAM:ProxOp_Rel_Pos to { return choose (target:position + V_RAM:ProxOp_Toffset) - (ship:position + V_RAM:ProxOp_Soffset) if V_RAM:ProxOp_hasTgt else V(0,0,0). }.
    set VC_RAM:ProxOp_Rel_Vel to { return choose Target:velocity:orbit - ship:velocity:orbit if V_RAM:ProxOp_hasTgt else V(0,0,0). }.
    set VC_RAM:ProxOp_Pos     to { return Vec2Ship( V_RAM:ProxOp_Rel_Pos ). }.
    set VC_RAM:ProxOp_Vel     to { return Vec2Ship( V_RAM:ProxOp_Rel_Vel ). }.
    set VC_RAM:ProxOp_Pos_Mag to { return V_RAM:ProxOp_Rel_Pos:mag. }.
    set VC_RAM:ProxOp_Vel_Mag to { return V_RAM:ProxOp_Rel_Vel:mag. }.

    set V_RAM:ProxOp_Mode    to "...Setup... ".
    VC_Calc().

    printUpdate:add( list( ptr_bottom, list( 
        list("", { return RightString( V_RAM:ProxOp_Mode, 29 ). }, { return 22. }, 1), // Mode

        list("", { return round( V_RAM:ProxOp_Pos[0], 3 ). }, { return decimalAlign(14, V_RAM:ProxOp_Pos[0]). }, 3), // Pos Fore
        list("", { return round( V_RAM:ProxOp_Pos[1], 3 ). }, { return decimalAlign(14, V_RAM:ProxOp_Pos[1]). }, 4), // Pos Top
        list("", { return round( V_RAM:ProxOp_Pos[2], 3 ). }, { return decimalAlign(14, V_RAM:ProxOp_Pos[2]). }, 5), // Pos Star

        list("", { return round( V_RAM:ProxOp_Vel[0], 3 ). }, { return decimalAlign(28, V_RAM:ProxOp_Vel[0]). }, 3), // Vel Fore
        list("", { return round( V_RAM:ProxOp_Vel[1], 3 ). }, { return decimalAlign(28, V_RAM:ProxOp_Vel[1]). }, 4), // Vel Top
        list("", { return round( V_RAM:ProxOp_Vel[2], 3 ). }, { return decimalAlign(28, V_RAM:ProxOp_Vel[2]). }, 5), // Vel Star

        list("", { return round( V_RAM:ProxOp_Rel_Pos:mag, 3 ). }, { return decimalAlign(14, V_RAM:ProxOp_Rel_Pos:mag). }, 6), // Pos Mag
        list("", { return round( V_RAM:ProxOp_Rel_Vel:mag, 3 ). }, { return decimalAlign(28, V_RAM:ProxOp_Rel_Vel:mag). }, 6)  // Vel Mag

        // mising PYR RATEs
    ))
    ).

    set ptr_bottom to ptr_bottom + 7.
}
local function OFF_ProxOpInfo {
    __offModule("ProxOpInfo", 6).
}
local function TOGGLE_ProxOpInfo {
    if section_Ptr_lex:haskey("ProxOpInfo") OFF_ProxOpInfo(). else ON_ProxOpInfo().
}

local function ON_DisplayHandle {
    // vars = [['HEADER', header], ['VAR', varName, (defaultValue: optional)], ['TXT', text, (optional) ['time', timeToCalc]]]
    // all spaces and layout relevant stuff MUST be set in vars
    // except the space between variableNames and their optinal default Values
    parameter vars is V_RAM:DisplayHandle_Vars.

    OFF_DisplayHandle().
    
    local leftOffset is 2.
    local topOffset is ptr_bottom+1.

    for line in range(topOffset, topOffset + vars:length+1) {
        print "                                                   " at(1, line).
    }
    print "―――――――――――――――――――――――――――――――――――――――――――――――――――" at(1, topOffset+vars:length).

    set displayInfoVariables to vars.
    for index in range(0, vars:length) {
        local printString is "".

        if vars[index][0] = "HEADER" { 
            set printString to vars[index][1].
        } else {
            set printString to "  "+vars[index][1].

            if vars[index][0] = "VAR" { 
                if vars[index]:length = 3 { 
                    set printString to printString + "  " + vars[index][2].
                } 
            } else if vars[index][0] = "TXT" {
                if vars[index]:length = 3 {

                    if vars[index][2][0] = "TIME" {

                        local deleget is { 
                            parameter t. 
                            return {return "M-" + SecondsToClock(t-time:seconds).}.
                        }.

                        printUpdate:add(list(ptr_bottom, list(list("", 
                            deleget(displayInfoVariables[index][2][1]),
                            {return leftOffset+vars[index][1]:length+2.},
                            index+1
                        )))).

                    } else if vars[index][2][0] = "NODE" {

                        printUpdate:add(list(ptr_bottom, list(list("",
                            {return (choose round(nextNode:deltaV:mag, 1) if hasNode else -1) + "  m/s  ".},
                            {return leftOffset+vars[index][1]:length+2.},
                            index+1
                        )))).
                    }
                }
            }
        }

        print printString at (leftOffset, topOffset + index).
    }
    
    section_Ptr_lex:add("DisplayInfo", ptr_bottom).
    set V_RAM:DisplayHandle_Vars to vars.
    set ptr_bottom to ptr_bottom + vars:length + 1.
}
local function OFF_DisplayHandle {
    __offModule("DisplayInfo", V_RAM:DisplayHandle_Vars:length).
    
    set displayInfoVariables to list(true).
}
local function TOGGLE_DisplayHandle {
    if section_Ptr_lex:haskey("DisplayInfo") OFF_DisplayHandle(). else ON_DisplayHandle().
}

local function inputHandle {
    parameter vars.

    local leftOffset is 2.
    local topOffset is ptr_bottom.
    local select is ">".

    ON_DisplayHandle(vars).

    local outList is list().
    for index in range(0, vars:length) {
        if not (vars[index][0] = "HEADER") {
            local col is leftOffset+1 + vars[index][1]:length + 3.
            local line is topOffset+1 + index.
            
            print select at (col-1, line).

            local input is getInputs(col, line).

            if vars[index]:length = 3 {
                set input to choose vars[index][2] if input = "" else input.
            }

            outList:add( input:tostring() ).
            print " " at (col-1, line).
        }
    }

    OFF_DisplayHandle().

    return outList.
}


local function Start {
    setFrame().

    sendCPU("Get_runmode").
    sendCPU("Get_logList").
    sendCPU("Get_TZero").
    sendCPU("Get_TNext").
    sendCPU("Get_runmodeInfoList").
    sendCPU("Get_TargetOrbit").

    module:OrbitInfo:on().
    logLister().
}

local function Update {
    // wait holdTime.

    DataSectionPrinter().
    netHandle().
    VC_Calc().

    if terminal:input:haschar {
        local char is terminal:input:getchar().
        
        if char = terminal:input:enter {
            print "■" at (42,5).
            set runmode to TerminalInput("│ RUNMODE", 3, false).
            
            print "│                                                   │" at (0, terminal:height-3).
            print " " at (42,5).
            
            if runmode > 100 { set runmode to 70. }
            runmodeLister().
            sendCPU("Set_runmode").
        } else {
            if char = "1" module:OrbitInfo:toggle().
            if char = "2" module:ProxOpInfo:toggle().
            if char = "9" module:DisplayInfo:toggle().
        }
    }
}

// EXAMPLES
local printUpdate_EXAMPLE is list(
    list("section_0: int", list( list("Name: string", "data1: func", "colum: func", "relLine: int"), list("Name: string", "data2: func", "colum: func", "relLine: int") )),
    list("section_1: int", list( list("Name: string", "data1: func", "colum: func", "relLine: int"), list("Name: string", "data2: func", "colum: func", "relLine: int") ))
).
//

local term is " ΩΔω‖ε|→←│┌┐└┘―⁞‰͢   ͚˽ꓕ  ː˸•⃝□▪▫◊○◌●◦❶ • ■  〈  〉  δε
┌ =================== AURIGA III ================== ┐ -------- section_0: 0
│   [ | ] |<-----------28----------->| │ T+00:01:35 │
│   [1|1] Initialisation               │ N-00:00:12 │
│ → [1|2] Clearing Tower               │> CPU_MAIN <│
│   [3]   Ascend Profile               │ [•|•] []   │
│   [4]   LES jetison                  │ [■] Input  │
│――――――――――――――――――――――――――――――――――――― + ―――――――――――│ -------- section_1: 6
│ ▪▪▪ │   CURRENT   │    TARGET   │  Δ DELTA   │ ▪▪ │
│ Apo │    74.342   │     80      │    5.658   │ km │
│ Per │   -50.185   │     80      │  130.185   │ km │
│ SMA │    12.079   │     80      │   67.921   │ km │
│ Inc │    25.234   │     25      │    0.234   │  ° │
│ LAN │   251.235   │    251      │    0.235   │  ° │
│ AoP │     5.844   │      6      │    0.156   │  ° │
│ ECC │   0.19435   │      0      │  0.19435   │    │
│―――――――――――――――――――――――――――――――――――――――――――――――――――│ -------- section_2: 15
│ Proximity Operation:                    Mode_Name │
│      │  Δ DISTANCE  |  Δ VELOCITY  | δ/s PYR RATE │
│ Fore │   100.001 m  │   10.001 m/s │    0.001 °/s │
│ Top  │     1.908 m  │   -1.908 m/s │    1.908 °/s │
│ Star │     5.22  m  │    5.22  m/s │    5.22  °/s │
│  MAG │   100.115 m  │   10.115 m/s │    5.115 °/s │
│―――――――――――――――――――――――――――――――――――――――――――――――――――│ -------- section_3: 22  <-- Ptr_bottom
│                                                   │
│―――――――――――――――――――――――――――――――――――――――――――――――――――│ <------- terminal:height - 4
│ RUNMODE >>                                        │
└ ================================================= ┘
".

// LOOP -- SETUP =========================================
        // local HOLD is {return.}.

        // local RunmodeLexicon is Lex(
        //     "", runmode_ @,
        // ).

// LOOP ==================================================
    Start().

    until runmode = 0 {
        Update().
            // RunmodeLexicon[runmode:tostring()]:call().
    }