clearscreen.

switch to core:volume.

set config:ipu to 2000.

local isCPU is core:tag:matchespattern("CPU").
local isGPU is core:tag:matchespattern("GPU").

local CORE_NET is core:messages.

local registered is lex(). // <UID, koSProcessor:CONNECTION>
local targetprocessorList is list().
local targetprocessorIndex is -1.

local timeStart is time:seconds + 2.

list Processors in procs.

local function searchUID {
    parameter UID.

    for p in procs {
        if p:part:uid = UID 
            return p.
    }

    return false.
}

// normal:
//  "CPU_REBOOT"
//  "GPU_REBOOT"
//
//  "runmodeStart", ch, uid
//
// GPU REBOOT:
//  "GPU_REBOOT"
//  "FORCED_REBOOT", uid
//
// CPU REBOOT:
//  "CPU_REBOOT"
//  "FORCED_REBOOT", ch, uid

if isCPU { // are we the control unit
    copyPath("0:/Auriga/Auriga3_C.ks", "1:").
    set targetprocessorList to ship:partstaggedpattern("gpu"+core:tag:substring(3, core:tag:length - 3)).   // search for "suffix" same gpu's

    for i in range(targetprocessorList:length) {
        print "                                     " at(0, i+5).
        print "["+i+"] " + targetprocessorList[i]:tag at(3, i+5).
    }

    if ship:partstaggedpattern("GPU"):length > 0 { // are there any graphic units
        print "waiting for a GPU instruction".

        set timeStart to time:seconds.

        local msg is false.
        until false {
            print "["+CORE_NET:length+"]  " at(5, 4).
            if not CORE_NET:empty {
                local letter is CORE_NET:peek:content[1][0].
                print letter at(15, 4).
                
                if letter = "FORCED_BOOT" or letter = "RunmodeStart" {                    
                    set msg to CORE_NET:pop:content.
                    break.
                }

                CORE_NET:pop.
            }

            if time:seconds > timeStart {
                set timeStart to time:seconds + 2.

                print "   " at(0, targetprocessorIndex+5).
                set targetprocessorIndex to choose targetprocessorIndex + 1 if targetprocessorIndex < targetprocessorList:length-1 else 0.
                print " > " at(0, targetprocessorIndex+5).

                targetprocessorList[targetprocessorIndex]:getmodule("kosProcessor"):connection:sendmessage(list(core:part:uid, list("CPU_REBOOT", 0))).
            }
        }

        run Auriga3_C.ks(msg[1][1], msg[0]). // msg = [GPU_UID, modeName, runmode]
    }
} 

if isGPU or isCPU {
    core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
    
    if isGPU {
        copyPath("0:/Auriga/Auriga3_G.ks", "1:").
        set targetprocessorList to ship:partstaggedpattern("cpu"+core:tag:substring(3, core:tag:length - 3)).   // search for "suffix" same cpu's
    }

    for i in range(targetprocessorList:length) {
        print "                                     " at(0, i+5).
        print "["+i+"] " + targetprocessorList[i]:tag at(3, i+5).
    }

    set timeStart to time:seconds.
    
    until false {
        print "Choose a runmode for boot:" at (0,1).
        print ">>__<<" at (0,2).

        local chars is list().

        for index in range(2) {
            until terminal:input:haschar {
                print "["+CORE_NET:length+"]  " at(5, 4).
                if not CORE_NET:empty {
                    local letter is CORE_NET:peek:content[1][0].
                    print letter at(15, 4).

                    if letter = "FORCED_BOOT" {
                        local msg is CORE_NET:pop:content.
                        run Auriga3_G.ks(msg[1][1], 0, msg[0]). // msg = [CPU_UID, modeName, runmode]
                        break.
                    } else if letter = "CPU_REBOOT" {
                        set letter to CORE_NET:pop:content[0].
                        local p is searchUID( letter ).
                        if p:istype("KOSProcessor")
                            set registered[letter] to p:connection.
                    } else CORE_NET:pop.
                }

                if time:seconds > timeStart {
                    set timeStart to time:seconds + 2.

                    print "   " at(0, targetprocessorIndex+5).
                    set targetprocessorIndex to choose targetprocessorIndex + 1 if targetprocessorIndex < targetprocessorList:length-1 else 0.
                    print " > " at(0, targetprocessorIndex+5).

                    targetprocessorList[targetprocessorIndex]:getmodule("kosProcessor"):connection:sendmessage(list(core:part:uid, list("GPU_REBOOT", 0))).
                }
            }

            chars:add(terminal:input:getchar()).
            print chars[index] at (2+index, 2).
        }

        set ch to (chars[0]+chars[1]):tonumber(0).

        wait .25.

        clearScreen.

        print "Are you sure to boot at runmode: > " + ch + " <"at (0,1).
        print "YES = ENTER" at (13,2).
        print "NO = BACKSPACE" at (12,3).

        set check to terminal:input:getchar().

        clearScreen.
        if check = terminal:input:enter {
            break.
        }
    }

    SAS off.
    RCS off.

    if isCPU { // we are CPU and havent detected any GPU
        copyPath("0:/Auriga/Auriga3_C.ks", "1:").
        run Auriga3_C.ks(ch, false).
    } else if isGPU { // we are GPU
        if ship:partstaggedpattern("CPU"):length > 0 { // if there are some CPUs
            for proc in registered:keys
                registered[proc]:sendmessage(list(core:part:UID, list("RunmodeStart", ch))). // pushes the selected runmode to all potential CPUs

            run Auriga3_G.ks(ch, 0, targetprocessorList[0]:UID).
        } else { // if there arent any CPUs
            copyPath("0:/Auriga/Auriga3_C.ks", "1:"). // we make our self the virtuall CPU
            run Auriga3_C.ks(ch, false). 
        }
    }
}