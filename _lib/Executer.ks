// >> Executer
    function Executer {
        local function StageIsp {
            set sumOne to 0.
            set sumTwo to 0.

            for eng in engList {
                if eng:ignition {
                    set sumOne to sumOne + eng:availablethrust.
                    set sumTwo to sumTwo + eng:availablethrust/eng:isp.
                    set useRCS to false.
                }
            }

            if useRCS {
                send("Set_Comment", list(time:seconds, "*  No Active Engines   *")).
                send("Set_Comment", list(time:seconds, "* Using RCS propulsion *")).
                RCS on.
                local info is rcsInfo().
                return lex("Thrust", info["Thrust"][0][0], "Isp", info["Isp"][0][0] ). // atm using +FORE RCS
            }

            if sumTwo > 0            
                return lex("Thrust", availableThrust, "Isp", sumOne / sumTwo).
            
            // if there was no solution/propultion suitable
            send("Set_Comment", list(time:seconds, "*** NO propulsion System found ***")).
            remove nextNode.
            return -1.
        }
        local function BurnTime {
            local propultion is StageIsp().
                        
            local finalMass is mass * constant:e^( -dV / (propultion["Isp"]*constant:g0) ).        

            local thrLim is 100.
            for eng in engList {
                if eng:ignition {
                    set eng:thrustlimit to MIN(100, ROUND( (200*dV) / ( eng:maxThrust*minimumBurnTime*(1/mass + 1/finalMass) ), 2 ) ).
                    local thrLim is eng:thrustlimit.
                }
            }
            send("Set_Comment", list(time:seconds, "Throttle is limited to: " + ROUND(thrLim, 2):tostring() + " %")).

            local startAcc is propultion["Thrust"] / mass.
            local finalAcc is propultion["Thrust"] / finalMass.

            return 2*dV / (startAcc + finalAcc).
        }
        local function interruptWait {
            parameter timeWait, additionalFunc is {}.
            local startTimeInt is time:seconds.

            until time:seconds - startTimeInt >= timeWait { CoroutineFunction:call(). additionalFunc:call().}
        }
        local function send {
            parameter modeName, data.
            sendTo:sendmessage( list(core:part:UID, list(modeName, data)) ).
        }
        parameter xNode, CoroutineFunction is {}, sendTo is core:messages.

        send("Set_Comment", list(time:seconds, "~ Executer Loaded and Started ~")).

        // SETTABLE Parameters
        local startReduceTime to 2.
        local minimumBurnTime to 5.

        if core:volume:files:keys:find("RcsControll.ks") = -1 {
            copyPath("0:_lib/RcsControll.ks", "1:").
        }
        runOncePath("1:RcsControll.ks"). // #include "0:_lib/RcsControll.ks"

        list engines in engList.
        local useRCS is true.   // sets itself to false if it detects active engines

        local dV to xNode:burnvector:mag.
        local burnTimeLength is BurnTime().
        local startTime is time:seconds + xNode:eta - .5*(burnTimeLength + startReduceTime).
        local startVector is xNode:burnvector.

        lock steering to xNode:burnvector.
        SAS off.
        RCS off.
        set ship:control:neutralize to true.

        send("Set_Display", list(
                list("HEADER", "MANEUVER DATA:"),
                list("TXT", "ΔV req.          |  ", list("NODE", "DV")),
                list("TXT", "Burn Time        |  "+ round(burnTimeLength,1) + "  s  "),
                list("TXT", "Preperation in   |  ", list("TIME", (startTime - 30)            )),
                list("TXT", "Execution begin  |  ", list("TIME", (startTime)                 )),
                list("TXT", "Burnout arpox.   |  ", list("TIME", (startTime + burnTimeLength)))
            )
        ).

        when not hasNode then {
            unlock throttle.
            unlock steering.
            set ship:control:neutralize to true.
            
            set runmode to 70.
            send("Set_runmode", runmode).
            send("Set_Comment", list(time:seconds, "STOPPED: NODE EXECUTION")).
            send("Set_Comment", list(time:seconds, "REBOOTING: CPU")).
            send("Set_Display", 0).
            reboot.
        }

        local thr is {
            parameter F.
            if useRCS 
                set ship:control:fore to F.
            else
                set throt to F.
        }.

        //#region Start setup
            interruptWait(startTime - 30 - time:seconds).
            send("Set_Comment", list(time:seconds, "Time Warping Canceled")).
            interruptWait(startTime-time:seconds, {kuniverse:timewarp:cancelwarp().}).

            RCS on.
            thr(1).
            send("Set_Comment", list(time:seconds, "Starting burn")).
        //#endregion
        //#region reduceThrottle
            interruptWait(burnTimeLength - startReduceTime).
            send("Set_Comment", list(time:seconds, "Throttle reduce has started")).

            set startTime to Time:seconds.

            thr( MAX(.05 , 0.37^((time:seconds - startTime)/startReduceTime)) ). 
        //#endregion
        //#region End of Burn
            when xNode:Burnvector:mag < 2 then {
                set steering to "KILL".
                send("Set_Comment", list(time:seconds, "LOCKED Throttle")).
            }

            until VANG(startVector, xNode:Burnvector) > 45 { // or time:seconds >= startTime + burnTimeLength + startReduceTime 
                CoroutineFunction:call().
            }

            thr(0).

            for eng in engList {
                if eng:ignition {
                    set eng:thrustlimit to 100.
                }
            }

            SAS off.
            RCS off.

            remove xNode.
            set runmode to runmode + 1.
            send("Set_runmode", runmode).
            send("Set_Display", 0).
        //#endregion       
    }