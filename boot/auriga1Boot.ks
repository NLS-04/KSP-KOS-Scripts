clearscreen.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
copyPath("0:/auriga1.ks", "").

until false {
    print "Choose a runmode for boot:" at (0,1).
    print ">>__<<" at (0,2).

    set ch0 to terminal:input:getchar().
    print ch0 at (2,2).

    set ch1 to terminal:input:getchar().
    print ch1 at (3,2).

    set ch to (ch0+ch1):tonumber(0).

    wait .125.

    clearScreen.

    print "Are you sure to boot at runmode: > " + ch + " <"at (0,1).
    print "YES = ENTER" at (13,2).
    print "NO = BACKSPACE" at (12,3).

    set check to terminal:input:getchar().

    if check = terminal:input:enter {
        clearScreen.

        print "Booting at runmode: > " + ch + " <"at (0,1).
        print "Load & Booting file" at (0,2).

        for j in range(0,1) {
            for i in range(19, 22) {
                print "." at (i,2).
                wait .125.
            }
            print "       " at(19,2).
        }

        BREAK.

    } else if check = terminal:input:backspace { clearScreen. } 
}

SAS off.
RCS off.

run auriga1.ks(ch).