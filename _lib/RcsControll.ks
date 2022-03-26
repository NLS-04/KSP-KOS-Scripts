// >> RCS Controll
    function rcsInfo {
        parameter debug is false.

        // general Layout: [ [FORE, -FORE], [TOP, -TOP], [STAR, -STAR] ]
        local thr is list( list(0, -0), list(0, -0), list(0, -0) ).
        local isps is list( list(0, -0), list(0, -0), list(0, -0) ).
        local Cord is list(ship:facing:ForeVector, ship:facing:TopVector, ship:facing:StarVector).

        if debug clearVecDraws(). 
        local vecs is list().
        local colors is list(red, blue, green).
        local Check is list(
            { parameter c. return c:foreEnabled. },
            { parameter c. return c:topEnabled. },
            { parameter c. return c:starboardEnabled. }
        ).

        list rcs in rc.
        for r in rc {
            for ThrVec in r:thrustvectors {
                set ThrVec to ThrVec*r:availableThrust.

                if debug vecDraw(r:position, ThrVec, white, round(r:availableThrust, 2), 1, true, .1).

                for i in range(3) {
                    if Check[i]:call(r) {
                        local ThrEff is r:availableThrust * cos( vang(ThrVec, Cord[i]) ).
                        
                        if ThrEff > 0 {
                            set thr [i][0] to thr [i][0] + ThrEff.
                            set isps[i][0] to isps[i][0] + ThrEff/r:Visp.
                        } else {
                            set thr [i][1] to thr [i][1] + ThrEff.
                            set isps[i][1] to isps[i][1] + ThrEff/r:Visp.
                        } 
                        
                        if debug vecs:add( vecDraw(r:position, ThrEff*Cord[i], colors[i], "", 1, true, .05, true) ).
                    }
                }
            }
        }

        if debug 
            for i in range(3)
                vecDraw(V(0,0,0), 10*Cord[i], colors[i], "", 1, true, .2).

        for i in range(3) {
            set isps[i][0] to thr[i][0] / isps[i][0]. 
            set isps[i][1] to thr[i][1] / isps[i][1].
        }

        return lex("Thrust", thr, "Isp", isps).
    }
