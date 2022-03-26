clearscreen.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

set countdown to 10.
set NowCountdown to countdown.
clearscreen.
until countdown = 0 {
    set OldCountdown to NowCountdown.
    set NowCountdown to OldCountdown - 1.
    print "T - " + NowCountdown at (5,4).
    wait 1.

    if NowCountdown = 0 {
        Print "!!! STARTING !!!" at (5,5).
        Wait 0.2.
        Print "!!! STARTING !!!" at (5,6).
        Wait 0.2.
        Print "!!! STARTING !!!" at (5,7).
        runpath("0:/launch.ks").
        wait 0.1.
        set countdown to 0.
    }
}