function relativeDisplay { // Draw Vectdraws to ilustrate relative movement off two ships
    parameter 
        tgt is choose target if hasTarget else ship,
        amount is 20,
        stepsLength is 30
    .

    global __OBJECT__RD is Lex(
        "__PosList", list(),
        "__steps", stepsLength,
        "__amount", amount,
        "__target", tgt,

        "__dr",         { parameter t. 
                            set t to t + time:seconds. 
                            return positionAt(__OBJECT__RD["__target"], t) - positionAt(Ship, t).
                        },
        "Update",       { for i in range(1, __OBJECT__RD["__amount"]) {
                                set __OBJECT__RD["__PosList"][i]:start to __OBJECT__RD["__PosList"][i-1]:vec + __OBJECT__RD["__PosList"][i-1]:start.
                                set __OBJECT__RD["__PosList"][i]:vec   to __OBJECT__RD["__dr"](__OBJECT__RD["__steps"]*(i-1)) - __OBJECT__RD["__dr"](__OBJECT__RD["__steps"]*i).
                            }
                        },

        "setTarget",    { parameter tagt. set __OBJECT__RD["__target"] to tagt. },
        "setSteps",     { parameter stp.  set __OBJECT__RD["__steps"] to stp. },
        "setAmount",    { parameter am is __OBJECT__RD["__amount"].
                            set __OBJECT__RD["__PosList"] to list().
                            set __OBJECT__RD["__amount"] to am.
                            
                            clearVecDraws().
                            for i in range(am) {
                                __OBJECT__RD["__PosList"]:add( vecDraw(2*up:vector*i, up:vector*(i+1), rgb(i/am, 0, 1 - i/am), i, 1, true, .1) ).
                            }

                            set __OBJECT__RD["__PosList"][0]:start to V(0,0,0).
                            set __OBJECT__RD["__PosList"][0]:vec to V(0,0,0).
                        },
        "getTarget",     { return __OBJECT__RD["__target"].    },
        "getStepsLength",{ return __OBJECT__RD["__steps"].  },
        "getAmount",     { return __OBJECT__RD["__amount"].    }
    ).

    __OBJECT__RD["setAmount"]:call().

    return __OBJECT__RD.    
}