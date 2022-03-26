// Analysis and Algorithmes   
    function launchAlgorithm {
        parameter data, change.
        
        // ========================================================================================================================================================= //
        //  data = lex(                                                           ||      change = lex(                                                              //
        //      "step"      , [float],                                            ||          "dev"  , lex(                                                          //
        //      "eng1"      , [part:engine],                                      ||                          "trigger"       , [string] >> "time", "alt", "dv" <<,  //
        //      "eng2"      , [part:engine],                                      ||                          "triggerVal"    , [float],                             //
        //      "maxG"      , [float],                                            ||                          "val"           , [float]                              //
        //      "startalt"  , [float] ( AGL - MSL compensation     ),             ||                      ),                                                         //
        //      "endApo"    , [float] ( loop until reached endApo  ),             ||          "stage", lex(                                                          //
        //      "m01"       , [float] ( wetmass [1] = stage [1] startmass ),      ||                          "trigger"       , [string] >> "time", "alt", "dv" <<,  //
        //      "mf1"       , [float] ( drymass [1] = stage [1] finalmass ),      ||                          "triggerVal"    , [float] ( if "dv"; [string] ),       //
        //      "m02"       , [float] ( wetmass [2] = stage [2] startmass ),      ||                          "spaceTime"     , [float]                              //
        //      "mf2"       , [float] ( drymass [2] = stage [2] finalmass ),      ||                      )                                                          //
        //      "body"      , [orbitable:body]                                    ||      ).                                                                         //
        //  )                                                                     ||                                                                                 //
        // ========================================================================================================================================================= //

        if not (defined inAlgorithym) {
            set ruppter to change.

            set csvName1 to path("analytics/A/a" + round(change["dev"]["val"], 2):tostring() + ".csv").
            set csvName2 to path("analytics/X/x" + round(change["dev"]["val"], 2):tostring() + ".csv").
            set csvName3 to path("analytics/_launch.csv").
            log " " to csvName3.
            
            set step   to data["step"].
            set bod    to data["body"].
            set eng1   to data["eng1"].
            set eng2   to data["eng2"].
            set maxG   to data["maxG"].
            set engNow to eng1.

            set mu  to bod:mu.
            set rad to bod:radius.
            set atm to bod:atm.
            set cw  to .42.

            // Aprox Drag = SURFACE_RADIUS^2 * PI * DRAG_COEFFICIENT * DENSITY * SPEED^2. 
            set dragConstant to 1.25^2 * constant:pi * cw * 0.5.
            
            set x    to 0.
            set y    to data["startalt"].
            set grav to mu / (rad + y)^2.

            set vx    to 0.
            set vy    to 0.
            set dv    to 0.
            set speed to sqrt(vx^2 + vy^2).
            set dvCounter to 0.

            set activationfactor to 1. // element of {0,1}; 1 = active Engine, 0 = deactive Engine 
            set velVang          to 0.
            set deviation        to 0.
            set thrVang          to 0.

            set m01  to data["m01"]. // full  orbiter + payload + full  bosststage
            set mf1  to data["mf1"]. // full  orbiter + payload + empty bosststage
            set m02  to data["m02"]. // full  orbiter + payload
            set mf2  to data["mf2"]. // empty orbiter + payload
            set mNow to m01 + m02. 

            set t to 0.
            set inAlgorithym to choose true if not change:length = 0 else false.
            set trigging to false.
        }

        if inAlgorithym {
            set t to t + step.
            local pres to atm:altitudepressure(y).

            // 287.058 = specific gas constant for dry air (J/(kg·K))
            // +273,15 to convert Kelvin into Celsius 
            local density is pres / (287.058 * (atm:alttemp(y) + 273.15)).
            
            local drag  is dragConstant * density * speed^2.
            local dragX is drag * sin(velVang). 
            local dragY is drag * cos(velVang). 

            set thr  to min(maxG*mNow*9.81, engNow:availableThrustat(pres)) * activationfactor.
            set thrX to thr * sin(thrVang).
            set thrY to thr * cos(thrVang).

            set x to vx * step + x. 
            set y to vy * step + y. 

            set vx        to step * (thrX / mNow - dragX       ) + vx.  
            set vy        to step * (thrY / mNow - dragY - grav) + vy. 
            set speed     to sqrt(vx^2 + vy^2).
            set dv        to dv        + step * (thr / mNow) * activationfactor.
            set dvCounter to dvCounter + step * (thr / mNow) * activationfactor.

            set velVang to arctan2(abs(vx), abs(vy)).
            set thrVang to velVang + deviation.

            set fuelflow to step * thr / (engNow:ispat(pres) * 9.81) .

            set dv1 to eng1:ispat(1   ) * 9.81 * ln( max(1,   (mNow - m02) / mf1) ).
            set dv2 to eng2:ispat(pres) * 9.81 * ln( max(1, min(mNow, m02) / mf2) ).

            set mNow to mNow - fuelflow.
            set grav to mu / (rad + y)^2.

            local apo  is (vy^2) / (2 * (grav - vx^2 / (rad + y))) + y.

            if apo > data["endApo"] {
                set activationfactor to 0.
            }

            if vy < 0 {
                set inAlgorithym to false.
                set reason to "-VERTICAL VEL".
            } else if mNow <= mf2 {
                set inAlgorithym to false.
                set reason to "NO FUEL".
            }

            if ruppter:length > 0 {
                for i in ruppter:keys {
                    if ruppter[i]["trigger"] = "time" {
                        if t >= ruppter[i]["triggerVal"] {
                            set trigging to true.
                        }
                    } else if ruppter[i]["trigger"] = "alt" {
                        if y >= ruppter[i]["triggerVal"] {
                            set trigging to true.
                        }
                    } else if ruppter[i]["trigger"] = "dv" {
                        // at the moment only 'KSC' is a possible landing position
                        if ruppter[i]["triggerVal"] = "KSC" {
                            if dv1 <= 2*speed {
                                set trigging to true.
                            }
                        }
                    }

                    if trigging {
                        if i = "dev" {
                            if velVang <= ruppter["dev"]["val"] {
                                set deviation to ruppter["dev"]["val"] - velVang.
                            } else {
                                set deviation to 0.
                                ruppter:remove(i).
                            }
                        } else if i = "stage" {
                            if not (defined t1) { 
                                set t1          to t. 
                                set mNow        to m02.
                                set engNow      to eng2.
                                set dvCounter   to 0.
                            }

                            if t < t1 + ruppter["stage"]["spaceTime"] {
                                set activationfactor to 0.
                            } else {
                                set activationfactor to 1.
                                ruppter:remove(i).
                            }
                        }

                        set trigging to false.
                    }
                }
            }
            
            set output to lex(
                "angle"     , change["dev"]["val"],
                //"step"      , step      ,
                "t"         , t         
                //"----------------------1","",
                //"x"         , x         ,
                //"y"         , y         ,
                //"apo"       , apo       ,
                //"----------------------2","",
                //"speed"     , speed     ,
                //"vx"        , vx        ,
                //"vy"        , vy        ,
                //"dv"        , dv        ,
                //"dv1"       , dv1       ,
                //"dv2"       , dv2       ,
                //"----------------------3","",
                //"thr"       , thr       ,
                //"thrX"      , thrX      ,
                //"thrY"      , thrY      ,
                //"TWR"       , engNow:availableThrustat(pres) / ((mNow + m02) * grav),
                //"isp"       , eng1:ispat(pres),
                //"fuelflow"  , fuelflow  ,
                //"----------------------4","",
                //"velVang"   , velVang   ,
                //"thrVang"   , thrVang   ,
                //"----------------------5","",
                //"mNow"      , mNow      ,
                //"m01"       , m01       ,
                //"mf1"       , mf1       ,
                //"----------------------6","",
                //"m02"       , m02       ,
                //"mf2"       , mf2       ,
                //"----------------------7","",
                //"grav"      , grav,
                //"acc eng"   , thr / mNow,
                //"acc total" , thr / mNow - grav,
                //"----------------------8","",
                //"ruppter"   , ruppter:keys + "                                                                                                                                               "
            ).

            log 
                step     +" "+
                t        +" "+
                x        +" "+
                y        +" "+
                apo      +" "+
                vx       +" "+
                vy       +" "+
                speed    +" "+
                dragX    +" "+
                dragY    +" "+
                drag     +" "+
                thrX     +" "+
                thrY     +" "+
                thr      +" "+
                velVang  +" "+
                thrVang  +" "+
                mNow     +" "+
                m01      +" "+
                mf1      +" "+
                m02      +" "+
                mf2      +" "+
                dv1      +" "+
                dv2      +" "+
                dv       +" "+
                fuelflow
            to csvName1.

            log 
                x        +" "+
                y        +" "+
                apo      
            to csvName2.

            log 
                x        +" "+
                y        +" "+
                apo      
            to csvName3.

            return output.
        } else { 
            local dCircV  is sqrt(mu / 680000) - vx.
            local devPath is path("analytics/_dvCounter.csv").

            log change["dev"]["val"] +" "+ (dvCounter + dCircV) to devPath.
            return lex("status", reason). 
        }
    }