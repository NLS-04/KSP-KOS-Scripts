function HillClimber { // classic HillClimber
    parameter
        extreme   is "MAX", // or "MIN"                     // extrema to be climbed
        lossy     is false,                                 // search for global or (first) local extreme
        deltaFunc is { parameter input. return 5-input. },  // return value of the function is the refrence for the climber 
        scanRange is 20,                                    // range for wich is searched
        scanSteps is 36,                                    // amount of steps for each iteration 
        start     is 0,                                     // startvalue
        minRange  is 1                                      // minimum Resulution at wich the climber stops searching
    .
    set minRange to max(1E-300, minRange).

    local bestDelta is deltaFunc(start).
    local bestInput is 0.
    local lastImprove is false.
    local LoopChecker is 1.
    local DoExit to false.

    until scanRange < minRange or DoExit {
        local stepSize is scanRange / scanSteps.
        set LoopChecker to 0.
        
        from { local i is stepSize*3/2 + start. } until i >= scanRange + start step { set i to i + stepSize. } do {
            set LoopChecker to LoopChecker + 1.
            if LoopChecker > scanSteps {
                set DoExit to true.
                break.
            }

            local tmpDelta is deltaFunc(i).

            local deltaDelta is bestDelta - tmpDelta.
            if (extreme = "MAX" and deltaDelta < 0) // tmpDelta > bestDelta 
            or (extreme = "MIN" and deltaDelta > 0) // tmpDelta < bestDelta 
            {
                set bestDelta to tmpDelta.
                set bestInput to i.
            }
            // log "   > " + i + " => " + tmpDelta + " => " + bestDelta to c.csv.

            if lossy {
                if i <> bestInput and lastImprove 
                    break.
                set lastImprove to bestInput=i.
            }
        }

        set start to (bestInput - (stepSize / 2)).
        set scanRange to stepSize.
    }

    return list( bestInput, bestDelta ).
}