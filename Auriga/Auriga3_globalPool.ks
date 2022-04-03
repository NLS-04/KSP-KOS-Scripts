@lazyGlobal off.

  //////////////////////////////////////////////////////////////////
 // THIS FILE IS USED TO SETUP UNIVERSAL VARIABLES AND CONSTANTS //
//////////////////////////////////////////////////////////////////


global runmodeInfoList is Lex(
//  rmN , |<-----------28----------->|
    "1" , "Initialisation",
    "2" , "Lift-off",
    "3" , "Launch Tower cleared",
    "4" , "Ascend profile",
    "5" , "LES jetison",
    "6" , "MECO",
    "7" , "Wait for Atmosphere Exit",
    "8" , "Rais Apoapsis to Park km",
    "9" , "Circ Orbit at Periapsis km",
    "10", "Execute Next Node",
    "11", "▪ ▪ ▪ ▪ ▪ ▪ HOLD ▪ ▪ ▪ ▪ ▪",

    "15", "Rendezvous Caculation",

    "21", "proximity Op-Setup",
    "23", "proximity Operation",
    "25", "proximity Operation",

    "31", "Aps Line Rotation => TARGET",
    "32", "Aps Line Rotation => SHIP",

    "50", "Orbital Vector Display",
    "51", "Asc. Node Display",
    "52", "Asc. Node Correction",
    "53", "Closest Approach scan",
    "54", "Cls App detail Display",
        
    "70", "▪ ▪ ▪ ▪ ▪ ▪ NOOP ▪ ▪ ▪ ▪ ▪",
    "71", "Set Target Orbit by Elements",
    "72", "Set Target Orbit by 'Target'",
    "74", "set rendezvous angle ",

    "97", " ** CLEAR: VecDraws ** ",
    "98", " ** RELOCK KOS - CONTROL ** ",
    "99", " ** UNLOCK KOS - CONTROL ** ",

    "ABORT", "ABORTING"
).

// LOGGING STUFF
    global PARENT_PATH is "0:/Auriga".
    global LOG_PATH_NAME is PARENT_PATH+"/log_auriga3.txt".
    global CHECKLIST_PATH_NAME is PARENT_PATH+"/Auriga3_Checklist.json".

    // ONLY TEMPORARY !!!
    runOncePath( "0:/Auriga/Auriga3_ChecklistCompiler.ks" ).

    global log_path is path( LOG_PATH_NAME ).

    if not exists( log_path )
        create( log_path ).

    global logFile is open( log_path ).
    logFile:clear().

// INTERCOM
    global CORE_UID is core:part:UID.
    global CORE_NET is core:messages.

    global DPCNet is lex(). // Direct_Processor_Communication_Network = lex(PROC_UID, PROC:connection)
    global  onNet is { parameter _UID, _mode, _data. DPCNet[_UID]:sendmessage( list(CORE_UID, list(_mode, _data)) ). }. // wait so we wont try fetching ourself
    global offNet is { return choose CORE_NET:pop():content if not CORE_NET:empty else false. }.


// clearing
    clearscreen.
    clearVecDraws().