clearscreen.
set runmode to 2.
UNTIL runmode = 0 {
    // ==================================
    print "runmode:                     " + runmode at (2,2).
    print "Altitude:                    " + ROUND(ALT:RADAR,0) + "m" at (2,3).
    print "Groundspeed:                 " + ROUND(GROUNDSPEED,2) + "m/s"at (2,4).
    print "G-Force (earth):             " + ROUND(SHIP:SENSORS:ACC:MAG / 9.81) at (2,5).
    print "Atmos Pressure (in Q):       " + ROUND(SHIP:Q,3) at (2,6).
    print "Atmos pressure (in kPa):     " + ROUND(BODY:ATM:ALTITUDEPRESSURE(ALTITUDE) * constant:ATMtokPa,2) + "kPa" at (2,7).
    log ALt:RADAR + "," + Groundspeed + "," + (SHIP:SENSORS:ACC:MAG / 9.81) + "," + (SHIP:Q) + "," + (BODY:ATM:ALTITUDEPRESSURE(ALTITUDE) * constant:ATMtokPa) to evelanding.csv.
    // ==================================
    
    IF runmode = 2 {
        lock steering to retrograde.
        IF ALT:RADAR < 5000 {
            IF stage:NUMBER = 1 {
                stage. 
                set runmode to 1.
            }

            ELSE IF stage:NUMBER < 1 { 
                set runmode to 1. 
            }
        }
    }
    IF runmode = 1 {
        IF (VERTICALSPEED = 0) OR (SHIP:STATUS = "Landed" OR SHIP:STATUS = "Splashed"){
            AG1 on.
            set runmode to 0.
        }
    }
}

IF runmode = 0 {
    unlock steering.
    clearscreen.
}