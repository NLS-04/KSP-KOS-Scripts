// >> other Functions
    function GeoDir { // direction [Heading] to target [LATLNG]
        parameter geo1. 
        parameter geo2. 
        
        RETURN ARCTAN2(geo1:LNG - geo2:LNG , geo1:LAT - geo2:LAT).
    }
    function GeoDist{ // distance [m] to target   
        parameter geo1, geo2. 
        
        local diste is vecToLocal(geo2:position - geo1:position).

        return (lexicon("mag", diste:mag, "lat", ABS(diste:y), "lng", ABS(diste:x))).
    }
    function GeoHdgoffset {
        parameter geo, hdg, dist. // dist 1 in geo units is roughly 10473.556 !FOR EARTH!
        
        local clng is (dist/10473.556)*sin(hdg).
        local clat is (dist/10473.556)*cos(hdg).
        
        return latlng(geo:lat + clat, geo:lng + clng).
    }
    
    function DoSaveStage {
        wait until stage:Ready.
        stage.
    } 
    function Cmach {
        local currentPresure is body:atm:altitudepressure(ship:altitude).
        return choose sqrt(2 / body:atm:adiabaticindex * ship:Q / currentPresure) if currentPresure > 0 else 0.
    }

    function waitForLaunch {
        parameter lat, lng, inc is 0, LAN is 0, T_rot is body:rotationperiod, body_angle is body:rotationangle, ORBIT is "USE INSTATE OF THE ELEMENTS".

        if ORBIT:istype("orbit") {
            set inc to ORBIT:inclination.    
            set LAN to ORBIT:LAN.
            set T_rot to ORBIT:body:rotationperiod.
            set body_angle to ORBIT:body:rotationangle.
        } 
    
        local t1 is 0.
        local t2 is 0.

        local tau is T_rot / 360.
        local delta_Lng is LAN - (body_angle + lng).

        if delta_Lng < 0 
            set delta_Lng to 360 + delta_Lng.

        if inc > 0.5 { 
            local sinFrac is arcSin( MAX( -1, MIN( lat/inc, 1 ) ) ).

            set t1 to tau*(delta_Lng + sinFrac).
            set t2 to tau*(delta_Lng - sinFrac + 180).

            set t1 to MOD(t1, T_rot). // get closest incounters
            set t2 to MOD(t2, T_rot). // get closest incounters            
        } else {
            set t1 to delta_Lng * tau. // time[s] = dist[°] * (period[s]/360°)
        }

        return list(t1, t2).
    }
    function Azimuth {
        parameter tgt. 

        return arcSin(MIN(1, MAX(-1, cos(tgt)/cos(SHIP:GEOPOSITION:lat)))).
    }
    function AdjustedLaunchPitch { // Gravityturn Pitch Calculator
        Parameter targetAlt, turnStart is 1000.
        
        return 90*(1 - min( max( (ship:orbit:apoapsis - TurnStart) / (targetAlt - TurnStart), -0.1 ), 1 )).
    }
    function GravityTurnPitch {
        parameter targetAlt is 80000, startAlt is 1000, midAlt is 10000, midPitch is 45.

        local pitch is 90.
        if ship:altitude < midAlt {
            set pitch to 90 - ( 90-midPitch )*( ship:altitude-startAlt ) / ( midAlt-startAlt ).
        } else {
            set pitch to midPitch*( 1 + ( ship:altitude-midAlt ) / ( midAlt-targetAlt ) ).
        }

        return pitch.
    }
    function maxGThrust {
        parameter maxG.
        return MAX(0, MIN(1, ( (9.81 * MaxG) * MASS ) / MAX(0.001, availableThrust))).
    }
    function flipBy {
        parameter r is V(0,0,0), t is 0. // r == [vector][RANGE(0-1)] V(YAW, PITCH, ROLL), t == [scalar]

        if not (r = V(0,0,0) and t = 0) {
            set ship:control:rotation to r.
            wait t.
        }

        set ship:control:rotation to V(0,0,0).
    }
    
    function massCalc {
        parameter p, type is "mass".

        local m is 0.
        if type:matchespattern("fuel") {
            for i in p {
                set m to m + (i:mass - i:drymass).
            }
        } else if type:matchespattern("mass") {
            for i in p {
                set m to m + i:mass.
            }
        }

        return m.
    }
    function trueRadar {
        if not (defined bound)
            set bound to ship:bounds.

        return bound:bottomaltradar.
    }
    function mode {
        parameter r, s is 0.
        set runmode to r.
        set submode to s.
    }
    function getShipsRotation {
        //getting heading and pitch data
        local pointing is ship:facing.
        local east     is vCrs(up:vector, north:vector).

        local trig_x is vdot(north:vector, pointing:vector).
        local trig_y is vdot(east,         pointing:vector).
        local trig_z is vdot(up:vector,    pointing:vector).

        local compass is arctan2(trig_y, trig_x).
        
        if compass < 0 {
            set compass to 360 + compass.
        }
        
        local pitch is arctan2(trig_z, sqrt(trig_x^2 + trig_y^2)).

        // getting roll data
        local roll_x is vdot(pointing:topvector, up:vector).

        if abs(trig_x) < 0.0035 { //this is the dead zone for roll when within 0.2 degrees of vertical
            set roll to 0.
        } else {
            local vec_y  is vcrs(up:vector, facing:vector).
            local roll_y is vdot(pointing:topvector, vec_y).
            set roll     to arctan2(roll_y, roll_x).
        }

        return V(compass, pitch, roll).
    }
    
    function ConnectionToGroundStations {
        parameter module.

        if not(addons:RT:haskscconnection(ship)) {
            local gsList is addons:RT:groundstations().
            
            for s in gsList {
                module:setfield("target", s:tostring()).

                if addons:RT:haskscconnection(ship)
                    BREAK.
            }
        }
    }
    function derivative {
        PARAMETER initalVal.
        LOCAL oldTime IS TIME:SECONDS.
        LOCAL oldVal IS initalVal.
        LOCAL oldDelta IS 0.
        RETURN {
            PARAMETER newVal.
            LOCAL newTime IS TIME:SECONDS.
            LOCAL deltaT IS newTime - oldTime.
            IF deltaT = 0 {
                RETURN oldDelta.
            } ELSE {
                LOCAL deltaVal IS newVal - oldVal.
                SET oldTime TO newTime.
                SET oldVal TO newVal.
                SET oldDelta TO deltaVal / deltaT.
                RETURN oldDelta.
            }
        }.
    }
    SET dVer TO derivative(VERTICALSPEED).
    SET dHor TO derivative(groundspeed).

    function vecToLocal {
        parameter V.
        local eVect is VCRS(UP:VECTOR, NORTH:VECTOR).
        local eComp is vdot(V, eVect:normalized).
        local nComp is vdot(V, NORTH:VECTOR:normalized).
        local uComp is vdot(V, UP:VECTOR:normalized).
        RETURN V(eComp, nComp, uComp).
    }
    function processorAssignment {
        parameter names, ves is ship. // as list

        local lexi is lex().

        for p in ves:modulesnamed("kOsProcessor") {
            for n in names {
                if p:tag:matchespattern(n) {
                    if ves = ship {
                        set lexi[n] to processor(n).
                    } else {
                        set lexi[n] to p.
                    }
                }
            }
        }

        return lexi.
    }
    function parseVecToList {
        parameter vec.

        return list(vec:x, vec:y, vec:z).
    }
    function ThrustVector {
        local totalMVec is V(0,0,0).
        local totaltorqueVec is V(0,0,0).
        local totalThrustVec is V(0,0,0).
        local maxTorque is V(0,0,0).

        for e in elist {
            set ePos to e:position.
            
            set eGimbal to e:gimbal:range * (
                e:gimbal:pitchangle * (-1) * VXCL(e:facing:forevector, V(1,0,0)) + 
                e:gimbal:yawangle   * V(0,1,0) + 
                e:gimbal:rollangle  * VXCL(e:facing:starvector, V(0,0,1))
            ).

            set eThrust to e:thrust * (e:facing + angleAxis(eGimbal:mag, eGimbal)):vector.
            set totalThrustVec to totalThrustVec + eThrust.

            set torqueVec to VXCL(ePos, eThrust).
            set totalMVec to totalMVec + VCRS(torqueVec, ePos).
            set totaltorqueVec to totaltorqueVec + torqueVec.

            //set v_r to vecDraw(V(0,0,0), ePos, RGB(1,1,1), "r", 1, true, .1).
            //set v_thr to vecDraw(ePos, eThrust, RGB(1,0,1), "thr", 1, true, .2).
            //set v_vxcl to vecDraw(ePos, torqueVec, RGB(1,0,0), "vxcl", 1, true, .2).
        }
        set v_M to vecDraw(V(0,0,0), totalMVec, RGB(0,0,1), "M", 1, true, .2).
        set v_Fm to vecDraw(V(0,0,0), totaltorqueVec, RGB(1,1,0), "Fm", 1, true, .2).

        set coT to VCRS(totalMVec, totaltorqueVec) / 1000.

        set v_thrust to vecDraw(coT, -1*totalThrustVec, RGB(1,0,0), "thrust", 1, true, .2).
    }    

// >> Structurs
        // Action Group structur
    //        if AG1 {
    //                    
    //        } else if AG2 {
    //            
    //        } else if AG3 {
    //            
    //        } else if AG4 {
    //            
    //        } else if AG5 {
    //            
    //        } else if AG6 {
    //            
    //        } else if AG7 {
    //            
    //        } else if AG8 {
    //            
    //        } else if AG9 {
    //            
    //        } else if AG10 {
    //            
    //        } 
    
        // Parts Modules etc.
    // log "NEW MODULES LIST ===================================================================" to ght2.csv.

    // for part in ship:parts {
    //     log part to ght2.csv.
    //     log "   modules:" to ght2.csv.
    //     for module in part:modules {
    //         log "       " + module to ght2.csv.
    //         log "           fields:" to ght2.csv.
    //             for field in part:getmodule(module):allfields {
    //                 log "               " + field to ght2.csv.
    //             }
    //         log "           events:" to ght2.csv.
    //             for event in part:getmodule(module):allevents {
    //                 log "               " + event to ght2.csv.
    //             }
    //         log "           actions:" to ght2.csv.
    //             for action in part:getmodule(module):allactions {
    //                 log "               " + action to ght2.csv.
    //             }
    //     }
    // }
        
    // set runode to 1.