// >> Rendezvous
    if core:volume:files:keys:find("RcsControll.ks") = -1 {
        copyPath("0:_lib/RcsControll.ks", "1:").
    }
    runOncePath("1:RcsControll.ks"). // #include "0:_lib/RcsControll.ks"


    function Vec2Ship {
        parameter vecI, face is ship:facing.

        return list(
            vdot(vecI, face:foreVector),
            vdot(vecI, face:topVector),
            vdot(vecI, face:starVector)
        ).
    }

    // rcsInfo Layout: [ [FORE, -FORE], [TOP, -TOP], [STAR, -STAR] ] for (thrust, Isp)
    function translationPIDs {
        parameter maxVelSettle is 10, maxVel is 5.

        // Debug log info
        global counter is time:seconds.
        open("0:ftsv.csv"):clear().
        log "time; F_set; F_input; F_error; F_output +; F_output -; T_set; T_input; T_error; T_output +; T_output -; S_set; S_input; S_error; S_output +; S_output -; F_kp+; F_kp-; F_ki+; F_ki-; F_kd+; F_kd-; T_kp+; T_kp-; T_ki+; T_ki-; T_kd+; T_kd-; S_kp+; S_kp-; S_ki+; S_ki-; S_kd+; S_kd-" to path("0:ftsv.csv").

        global Info_RCS is rcsInfo(false).
        local VKps is Get_Vel_KpGains(maxVelSettle, Info_RCS).
        local VKis is Get_Vel_KiGains(maxVelSettle, Info_RCS).
        local VKds is Get_Vel_KdGains(maxVelSettle, Info_RCS).
        local PKps is Get_Pos_KpGains(Info_RCS).

        local velFac is 1.
        local posFac is 2/3.

        global FTS_Vel_PIDs is list( list(0, -0), list(0, -0), list(0, -0) ).
        global FTS_Pos_PIDs is list( list(0, -0), list(0, -0), list(0, -0) ).
        
        for pidI in range(3) {
            set FTS_Vel_PIDs[pidI][0] to pidLoop( velFac * VKps[pidI][0], velFac * VKis[pidI][0], velFac * VKds[pidI][0], 0, 1 ).
            set FTS_Vel_PIDs[pidI][1] to pidLoop( velFac * VKps[pidI][1], velFac * VKis[pidI][1], velFac * VKds[pidI][1], 0, 1 ).
        }
        
        for pidI in range(3) {
            set FTS_Pos_PIDs[pidI][0] to pidLoop( posFac * PKps[pidI][0], 0, .0 * posFac * PKps[pidI][0], 0, maxVel ).
            set FTS_Pos_PIDs[pidI][1] to pidLoop( posFac * PKps[pidI][1], 0, .0 * posFac * PKps[pidI][1], 0, maxVel ).
        }
    }

    function Get_Vel_KpGains {
        parameter maxVel is 10, thrusts is rcsInfo().

        local settles is list( list(0, -0), list(0, -0), list(0, -0) ).

        for index in range(3) {
            set settles[index][0] to 8*thrusts["Thrust"][index][0] / maxVel.
            set settles[index][1] to 8*thrusts["Thrust"][index][1] / maxVel.
        }

        return settles.
    }
    function Get_Vel_KiGains {
        parameter maxVel is 10, thrusts is rcsInfo().

        local settles is list( list(0, -0), list(0, -0), list(0, -0) ).

        for index in range(3) {
            set settles[index][0] to  16*( thrusts["Thrust"][index][0] / maxVel )^2 / mass.
            set settles[index][1] to -16*( thrusts["Thrust"][index][1] / maxVel )^2 / mass.
        }

        return settles.
    }
    function Get_Vel_KdGains {
        parameter maxVel is 10, thrusts is rcsInfo().

        local settles is list( list(0, -0), list(0, -0), list(0, -0) ).

        for index in range(3) {
            set settles[index][0] to 1*( ( thrusts["Thrust"][index][0] / maxVel )^2 / mass )^2.
            set settles[index][1] to 1*( ( thrusts["Thrust"][index][1] / maxVel )^2 / mass )^2.
        }

        return settles.
    }

    function Get_Pos_KpGains {
        parameter thrusts is rcsInfo().

        local settles is list( list(0, -0), list(0, -0), list(0, -0) ).

        for index in range(3) {
            set settles[index][0] to .5*( thrusts["Thrust"][index][0]/mass ).
            set settles[index][1] to .5*( thrusts["Thrust"][index][1]/mass ).
        }

        return settles.
    }


    function set_Vel {
        parameter tgt is list( 0, 0, 0 ).

        local epsilon is 0.
        for i in range(3)
            set epsilon to epsilon + tgt[i]^2.

        set epsilon to .1^2 * epsilon.

        for pidI in range(3) {
            set FTS_Vel_PIDs[pidI][0]:epsilon to epsilon.
            set FTS_Vel_PIDs[pidI][1]:epsilon to epsilon.

            set FTS_Vel_PIDs[pidI][0]:setpoint to tgt[pidI].
            set FTS_Vel_PIDs[pidI][1]:setpoint to tgt[pidI].
        } 
    }
    function set_Pos {
        parameter tgt is list( 0, 0, 0 ).

        local epsilon is 0.
        for i in range(3)
            set epsilon to epsilon + tgt[i]^2.

        set epsilon to .1^2 * epsilon.

        for pidI in range(3) {
            set FTS_Pos_PIDs[pidI][0]:epsilon to epsilon.
            set FTS_Pos_PIDs[pidI][1]:epsilon to epsilon.

            set FTS_Pos_PIDs[pidI][0]:setpoint to tgt[pidI].
            set FTS_Pos_PIDs[pidI][1]:setpoint to tgt[pidI].
        }
    }

    function perform_Vel {
        parameter CPerr is list( 0, 0, 0 ). // [ FORE, TOP, STAR ]

        local t is time:Seconds.

        set ship:control:translation to V( // [ STAR, TOP, FORE ]
            FTS_Vel_PIDs[2][0]:update(t, CPerr[2]) - FTS_Vel_PIDs[2][1]:update(t, CPerr[2]),
            FTS_Vel_PIDs[1][0]:update(t, CPerr[1]) - FTS_Vel_PIDs[1][1]:update(t, CPerr[1]),
            FTS_Vel_PIDs[0][0]:update(t, CPerr[0]) - FTS_Vel_PIDs[0][1]:update(t, CPerr[0])
        ).

        logDebug().
    }
    function perform_Pos {
        parameter CPerr is list( 0, 0, 0 ), CVerr is list( 0, 0, 0 ). // [ FORE, TOP, STAR ]

        local t is time:Seconds.
        for i in range(3)
            set CVerr[i] to choose -(CVerr[i])^2 if CVerr[i] < 0 else (CVerr[i])^2.

        local velList is list( 0, 0, 0 ).
        for pidI in range(3)
            set velList[pidI] to FTS_Pos_PIDs[pidI][0]:update(t, CPerr[pidI]) - FTS_Pos_PIDs[pidI][1]:update(t, CPerr[pidI]).

        set_Vel( velList ).
        perform_Vel( CVerr ).
    }
    function perform_VePo {
        parameter vepo is list( list( 0, "", "" ), list( "", 0, 0 ) ), CPerr is list( 0, 0, 0 ), CVerr is list( 0, 0, 0 ). // [ FORE, TOP, STAR ]
        // use "" if the axis is conroled by the other element
        // vepo = [ Vel, Pos ]

        local t is time:seconds.

        local epsilist is list( 0, 0 , .1, .1).
        local TVel is List( "Fore", "Top", "Star" ).

        for j in range(2) {
            for i in range(3)
                set epsilist[j] to epsilist[j] + (choose vepo[j][i]^2 if vepo[j][i]:istype("scalar") else FTS_Vel_PIDs[i][0]:setpoint).
            set epsilist[j] to epsilist[j+2]^2 * epsilist[j].

            for pidI in range(3) {
                set FTS_Vel_PIDs[pidI][0]:epsilon to epsilist[j].
                set FTS_Vel_PIDs[pidI][1]:epsilon to epsilist[j].

                if vepo[j][pidI]:istype("scalar") {
                    set FTS_Vel_PIDs[pidI][0]:setpoint to vepo[j][pidI].
                    set FTS_Vel_PIDs[pidI][1]:setpoint to vepo[j][pidI].
                }
            }
        }

        for i in range(3) {
            if vepo[0][i]:istype("scalar")
                set TVel[i] to vepo[0][i].
            else
                set TVel[i] to FTS_Pos_PIDs[i][0]:update(t, CPerr[i]) - FTS_Pos_PIDs[i][1]:update(t, CPerr[i]).
        }

        set_Vel( TVel ).
        perform_Vel( CVerr ).
    }

    function logDebug {
        local c is "; ".

        local outString is round( FTS_Vel_PIDs[0][0]:lastsampletime - counter, 5 ) +c.

        for i in range(3) {
            set outString to outString +
                round( FTS_Vel_PIDs[i][0]:setpoint, 5 ) +c+
                round( FTS_Vel_PIDs[i][0]:input   , 5 ) +c+
                round( FTS_Vel_PIDs[i][0]:error   , 5 ) +c+
                round( FTS_Vel_PIDs[i][0]:output  , 5 ) +c+
                round( FTS_Vel_PIDs[i][1]:output  , 5 ) +c
            .
        }

        for i in range(3) {
            set outString to outString +
                round( FTS_Vel_PIDs[i][0]:pterm, 5 ) +c+
                round( FTS_Vel_PIDs[i][1]:pterm, 5 ) +c+
                round( FTS_Vel_PIDs[i][0]:iterm, 5 ) +c+
                round( FTS_Vel_PIDs[i][1]:iterm, 5 ) +c+
                round( FTS_Vel_PIDs[i][0]:dterm, 5 ) +c+
                round( FTS_Vel_PIDs[i][1]:dterm, 5 ) +c
            .
        }

        log outString to path("0:ftsv.csv").
    }
    