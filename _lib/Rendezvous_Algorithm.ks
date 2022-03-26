@lazyGlobal off.

clearScreen.
clearVecDraws().

declare parameter 
    InitialOrbit is ship:orbit,     // the catchers orbit
    TargetOrbit  is target:orbit,   // the targets  orbit
    IntersectionTheta is 130.       // True Anomaly in Degrees (of Longitude of Ascending Node (LAN)) there the rendezvous should occure

runOncePath("0:_lib/Hohmann.ks"). // #include "0:_lib/Hohmann.ks"
runOncePath("0:_lib/HillClimber.ks"). // #include "0:_lib/HillClimber.ks"

local function debugData { // ₀ ₁ ₂ ₃   ‗ ͈ ₎  η γ θ Δ 
    log "==================================================================" to debugFile.
    log "e₀     :   " + InitialOrbit:eccentricity           to debugFile.
    log "e₃     :   " +  TargetOrbit:eccentricity           to debugFile.
    log "a₀     :   " + InitialOrbit:semimajoraxis          to debugFile.
    log "a₃     :   " +  TargetOrbit:semimajoraxis          to debugFile.
    log "η₀     :   " + InitialOrbit:argumentofperiapsis    to debugFile.
    log "η₃     :   " +  TargetOrbit:argumentofperiapsis    to debugFile.
    log "θ_tgt  :   " + theta_target                        to debugFile.
    log "θ_ship :   " + theta_Ship                          to debugFile.
    log "------------------------------------------------------------------" to debugFile.
    log "h₀     :   " + h0                                  to debugFile.
    log "h₃     :   " + h3                                  to debugFile.
    log "rI     :   " + rI                                  to debugFile.
    log "γi     :   " + fpA_at_I                            to debugFile.
    log "------------------------------------------------------------------" to debugFile.
    if defined ecc2                                     log "e₂     :   " + ecc2                                to debugFile.
    if defined TA_of_target_FpA                         log "θγi    :   " + TA_of_target_FpA                    to debugFile.
    if defined h2                                       log "h₂     :   " + h2                                  to debugFile.
    if defined a2                                       log "a₂     :   " + a2                                  to debugFile.
    if defined argOfPer2                                log "η₂     :   " + argOfPer2                           to debugFile.
    if defined TA_of_sameFpa_to_initalOrbit             log "θ‗₀₎₂  :   " + TA_of_sameFpa_to_initalOrbit        to debugFile.
    if defined r0_tangential                            log "r₀₎‗   :   " + r0_tangential                       to debugFile.
    if defined r2_tangential                            log "r₂₎‗   :   " + r2_tangential                       to debugFile.
    if defined r0_tangential and defined r2_tangential  log "Δr₎‗   :   " + abs(r0_tangential-r2_tangential)    to debugFile.
    log "------------------------------------------------------------------" to debugFile.
    if defined orbitPeriod2          log "T₂     :   " + orbitPeriod2                        to debugFile.
    if defined orbitPeriod3          log "T₃     :   " + orbitPeriod3                        to debugFile.
    if defined time_transition       log "t₀₃    :   " + time_transition                     to debugFile.
    if defined time_tgtToRendezvous  log "t_tgt_I:   " + time_tgtToRendezvous                to debugFile.
    if defined time_ShipToTransition log "t_s_b  :   " + time_ShipToTransition               to debugFile.
    if defined dv_Orbit1_to_Orbit2   log "Δv₀₎₂  :   " + dv_Orbit1_to_Orbit2                 to debugFile.
    if defined time_phaseUp          log "t_phase:   " + time_phaseUp                        to debugFile.
    log "------------------------------------------------------------------" to debugFile.
    if defined h1                    log "h₁     :   " + h1                                  to debugFile.
    if defined e1                    log "e₁     :   " + e1                                  to debugFile.
    if defined a1                    log "a₁     :   " + a1                                  to debugFile.
    if defined argOfPer1             log "η₁     :   " + argOfPer1                           to debugFile.
    if defined orbitPeriod1          log "T₁     :   " + orbitPeriod1                        to debugFile.
    if defined dv_p                  log "Δv     :   " + dv_p                                to debugFile.
    if defined OrbitPassesOf1        log "k₁     :   " + OrbitPassesOf1                      to debugFile.
    log "" to debugFile.
}
local logVal is { parameter val, name is -1. log " > " + (choose name:toString() + " : " if name <> -1 else "") + val:toString() to debugFile. }.

global spVec is vecDraw( body:position, 1000000*solarPrimeVector, red, "♈︎", 1, true, 0.2, true ).
global anVec is vecDraw( body:position, ANVector(), green, "☊", 1, true, 0.2, true ).

// handy functions for TrueAnomaly, radial distance, flightpath angle (fpA) ... =====
    function SecantSolveAlgorithm {
        parameter 
            func, 
            searchValue is 0, 
            x0 is 0, 
            x1 is 1,
            maxError is 1E-5, 
            maxIterations is 1000
        .

        local x2 is (x0+x1)/2.

        until abs( searchValue - func(x2) ) <= maxError or maxIterations <= 0 {
            set maxIterations to maxIterations - 1.

            local divFunc is func(x1) - func(x0).
            if divFunc = 0 
                break.
            
            set x2 to (searchValue - func(x1)) * ( x1 - x0 ) / divFunc  + x1.
            set x0 to x1. 
            set x1 to x2.
            log (1000-maxIterations) +", "+ x2 +", "+ abs( searchValue - func(x2) ) to debugFile.
        }

        return x2.
    }

    function SecantSolveAlgorithm_Bounded {
        parameter 
            func, 
            searchValue is 0, 
            x0 is 0, 
            x1 is 1, 
            fixBound_low  is x0, 
            fixBound_high is x1, 
            maxError is 1E-5, 
            maxIterations is 1000
        .

        local x2 is (x0+x1)/2.

        until abs( searchValue - func(x2) ) <= maxError or maxIterations <= 0 {
            set maxIterations to maxIterations - 1.

            local divFunc is func(x1) - func(x0).
            if divFunc = 0 
                break.
            
            set x2 to (searchValue - func(x1)) * ( x1 - x0 ) / divFunc  + x1.

            if x2 < fixBound_low or x2 > fixBound_high 
                set x2 to (x0+x1)/2.

            set x0 to x1. 
            set x1 to x2.
            
            log (1000-maxIterations) +", val:   "+ x2 +", err:  "+ abs( searchValue - func(x2) ) to debugFile.
        }

        return x2.
    }

    local h is { parameter a, ecc. return sqrt( mu*a*(1-ecc^2) ). }.
    local r_dist is { parameter theta, _h, ecc. return (_h^2)/mu * 1/( 1+ecc*cos(theta) ). }.

    local function flightPathAngle {
        parameter theta, _ecc.
        return arcTan2( _ecc*sin(theta), 1+_ecc*cos(theta) ).
    }

    local function TrueAnomalyOf_FpA {
        parameter fpA, _ecc.

        local phi is - arcTan( 1 / (fpA * constant:degtorad) ).
        return list( 
                 phi + arcCos( -1/_ecc * cos(phi) ),
            mod( phi - arcCos( -1/_ecc * cos(phi) ) + 360, 360)
        ).
    }

    local function TrueAnomalyOf_tangetialPoints {
        parameter _ecc0, _ecc1, delta.

        local a is _ecc1 * sin(delta).
        local b is _ecc0 - _ecc1 * cos(delta).
        local c is _ecc0 * _ecc1 * sin(delta).
        local phi is arcTan2( b, a ).

        return list( 
                 phi + arcCos( c/a * cos(phi) ),
            mod( phi - arcCos( c/a * cos(phi) ) + 360, 360)
        ).
    }


    local function Time_Vessel_to_TrueAnomaly {
        parameter theta_vessel, theta_tgt, ecc, period.
        local time_to_Vessel is TrueAnomalyToTime( theta_vessel, ecc, period ).
        local time_to_theta  is TrueAnomalyToTime( theta_tgt, ecc, period ).
        return mod( ( time_to_theta - time_to_Vessel ) + period, period ).
    }
        

    local function apseRotationFromBurn { // calculating the apse Line rotation a burn defined by (dv_p, dv_r) at theta_ would create
        parameter dv_p_, dv_r, ecc_, theta_, h_, mu_ is body:mu.

        local r_burn is r_dist(theta_, h_, ecc_).

        local v_p_ is h_/r_burn.
        local v_r_ is mu_/h_ * ecc_ * sin(theta_).

        local a is (v_p_ + dv_p_) * (v_r_ + dv_r).
        local b is (v_p_ + dv_p_)^2 * ecc_ * cos(theta_) + dv_p_ * ( 2*v_p_ + dv_p_).
        local c is v_p_^2 * r_burn / mu_.

        return theta_ - arcTan( a/b * c ).
    }


    local r0 is { parameter theta. return r_dist( theta, h0, ecc0 ). }.
    local r3 is { parameter theta. return r_dist( theta, h3, ecc3 ). }.

// Given Parameters ===========================================================
    // Static parameters ------------------------------------------------------
        local mu is ship:body:mu.
        local codetime is time.
        local debugFile is rendezvous_Algorithm_debuging.csv.

    // custom parameters ------------------------------------------------------        
        // createOrbit( inc, e, sma, lan, argPe, mEp, t, body )
        // inc, lan | can be anything (here 0 for simplicity) since the two Orbits are treated as coplanar Orbits
        // mEp, t   | only relevant for the timing and not the structure of the Orbits 
            // !! FOR TESTING // local InitialOrbit is createOrbit( 0, 0.025, 700000, 0, 225, 0, 0, ship:body ).
            // !! FOR TESTING // local TargetOrbit  is createOrbit( 0, 0.022, 800000, 0,  45, 0, 0, ship:body ).

        // true Anomaly of the target Ship in refrence to its Orbit (target Orbit 3)
        local theta_target is TargetOrbit:trueAnomaly.
            // !!! local theta_target is 25.
        
        // true Anomaly of the chaser Ship in refrence to its Orbit (initial Orbit 0)
        local theta_Ship is InitialOrbit:trueAnomaly.
            // !!! local theta_Ship is 300.

// pre Calculate important Variables ==========================================
    local thetaI_ofTarget is mod( IntersectionTheta - TargetOrbit:ArgumentOfPeriapsis + 360, 360 ).

    local ecc0 is InitialOrbit:eccentricity.
    local ecc3 is TargetOrbit:eccentricity.

    local h0 is h( InitialOrbit:semimajoraxis, ecc0 ).
    local h3 is h( TargetOrbit:semimajoraxis,  ecc3 ).

    // altitude of planed Rendevous position 
    local rI is r3( thetaI_ofTarget ).

    // flightpath angle (fpA) of the Target orbit at the rendevous Positon
    local fpA_at_I is flightPathAngle( thetaI_ofTarget, ecc3 ).

// TOcA (Transition Orbit calculation Algorithm) ==============================
    // Initializing TOcA dependant/defining variables in this scope
        local TA_of_target_FpA is 0.
        local h2 is 0.
        local a2 is 0.
        local argOfPer2 is 0.
        local TA_of_sameFpa_to_initalOrbit is 0.
        local r0_tangential is 0.
        local r2_tangential is 0.

    local TOcA is {
        parameter e2. 
        
        // calculating the transition Orbit's (tO) true Anomaly at which its tangential (same FpA) to the FpA at Rendevous
        local TA_of_target_FpA_thetas is TrueAnomalyOf_FpA( fpA_at_I, e2 ).
        
        // take the true anomlay with which the angular momentum of the transition orbit would ONLY DECREASE
        if TA_of_target_FpA_thetas[0] >= 90 and TA_of_target_FpA_thetas[0] <= 270
            set TA_of_target_FpA to TA_of_target_FpA_thetas[0].
        else 
            set TA_of_target_FpA to TA_of_target_FpA_thetas[1].
        set TA_of_target_FpA to mod( TA_of_target_FpA + 360, 360 ).

        // adjusting the tO's angular momentum so that has the same altitude at rendevous point as the target orbit
        set h2 to h3 * sqrt( ( 1 + e2 * cos(TA_of_target_FpA) ) / ( 1 + ecc3 * cos(thetaI_ofTarget) ) ).

        // calculating the tO's semi major axis 
        set a2 to ( h2^2 ) / ( mu*( 1-e2^2 ) ).

        // adjusting the tO's argument of Periapsis so that the tO and target Orbit are tangential at the rendezvous point
        set argOfPer2 to mod( IntersectionTheta - TA_of_target_FpA + 360, 360 ).

        // calculating the inital Orbit's true Anomaly at which it is tangential to the tO <== !! regard the refrence frame !!
        set TA_of_sameFpa_to_initalOrbit to TrueAnomalyOf_tangetialPoints( ecc0, e2, argOfPer2 - InitialOrbit:ArgumentOfPeriapsis )[0]. // !! ANGST !!
        set TA_of_sameFpa_to_initalOrbit to mod( TA_of_sameFpa_to_initalOrbit + 360, 360 ).

        set r0_tangential to r0( TA_of_sameFpa_to_initalOrbit ).
        set r2_tangential to r_dist ( TA_of_sameFpa_to_initalOrbit + InitialOrbit:ArgumentOfPeriapsis - argOfPer2, h2, e2).

        return r2_tangential - r0_tangential.
    }.

    local fpA_at_I_inRad is fpA_at_I * constant:degtorad.
    local minimumEcc2 is sqrt( fpA_at_I_inRad^2 / (1+fpA_at_I_inRad^2) ).

    local ecc2 is SecantSolveAlgorithm_Bounded( TOcA, 0, minimumEcc2 + 1E-5, 1 - 1E-5 ).

// TcA (Timing calculation Algorithm) =========================================
    local orbitPeriod2 is orbitPeriodBy_SMA( a2 ).
    local orbitPeriod3 is orbitPeriodBy_h_ecc( h3, ecc3 ).

    // time it takes to transition from the inital Orbit (or else phase Orbit) to the final target Orbit
    local time_transition is TrueAnomalyToTime( IntersectionTheta-argOfPer2, ecc2, orbitPeriod2 ) - // time to rendezvous point from tO
                             TrueAnomalyToTime( TA_of_sameFpa_to_initalOrbit + InitialOrbit:ArgumentOfPeriapsis - argOfPer2, ecc2, orbitPeriod2 ). // time to tO's tangential point with inital Orbit
    set time_transition to mod( time_transition + orbitPeriod2, orbitPeriod2 ).

    // time it takes the Target Orbitable to get to the rendezvous point    
    local time_tgtToRendezvous is Time_Vessel_to_TrueAnomaly( theta_target, thetaI_ofTarget, ecc3, orbitPeriodBy_h_ecc(h3, ecc3) ).
        
    // time it takes the ship to get to the first maneuver node, which raises the initial orbit to the phaseup Orbit
    local time_ShipToTransition is Time_Vessel_to_TrueAnomaly( theta_Ship, TA_of_sameFpa_to_initalOrbit, ecc0, orbitPeriodBy_h_ecc(h0, ecc0) ).

    // time it would take to instandly go for the rendezvous
    local time_ShipToRendezvous is time_ShipToTransition + time_transition.

    // time diffrence between the target and ship time, which has the be covered in a phasing Orbit
    local time_phaseUp is time_tgtToRendezvous - time_ShipToRendezvous.

    // Initializing TcA (Orbit 1) dependant/defining variables in this scope
        local h1 is 0.
        local e1 is 0.
        local a1 is 0.
        local argOfPer1 is 0.
        local orbitPeriod1 is 0.

    local calculateorbit1 is {
        parameter dv.

        local apseRotation is apseRotationFromBurn(dv, 0, ecc0, TA_of_sameFpa_to_initalOrbit, h0).
        
        // radial out component of the velocity vector at the Burn point
        local v_r0 is mu/h0 * ecc0 * sin(TA_of_sameFpa_to_initalOrbit).

        local r_burn is r_dist(TA_of_sameFpa_to_initalOrbit, h0, ecc0).

        set h1 to h0 + r_burn*dv.

        // apseRotation is the diffrence of both arg.Of.Pers. therefor the burn theta of the initial Orbit needs to be subtracted, resulting in the true theta of Orbit 1
        set e1 to ( v_r0*h1 ) / ( mu*sin( apseRotation - TA_of_sameFpa_to_initalOrbit ) ). 
        set e1 to abs( e1 ). // often tends to be negative because of refrence frame ambiguity
        set a1 to h1^2 / ( mu * ( 1 - e1^2 ) ).
        set argOfPer1 to mod( apseRotation + InitialOrbit:ArgumentOfPeriapsis + 360, 360 ).

        set orbitPeriod1 to orbitPeriodBy_SMA( a1 ).
    }.

    local calculateTimeDelta is {
        // generalize the amount of orbit passes needed for some dv range
        // and find in that continous function (dependent on dv) the 1st root
        // note: one continous strip formed by some dv range only has ONE root, but
        //       increasing the amount of how often the target orbits 360° around, will
        //       lead to multiple strips having a root in our respectiv interval 

        parameter dv.

        calculateorbit1( dv ).

        // the amount of orbit passes needed based on the dv provided
        local passivOrbit1PassesAmount is round( time_phaseUp / orbitPeriod1 ).

        return time_phaseUp - passivOrbit1PassesAmount * orbitPeriod1.
    }.

    // start of iteration algorithm

    // essentialy calculates the parameters same as the of the initial Orbit
    calculateorbit1( 0 ).

    local increasePhaseTime is {
        set time_phaseUp to time_phaseUp + orbitPeriod3.
        logVal(time_phaseUp, "time_phaseUp").
    }.
    
    // increase phaseUp time by orbit3 periods until its at least as long as the intial Orbits Period
    until time_phaseUp >= orbitPeriod1
        increasePhaseTime().

    local dv_Orbit1_to_Orbit2 is ( h2 - h0 ) / r0_tangential.
    local dv_Orbit2_to_Orbit3 is ( h3 - h2 ) / rI.
    local dv_p is -1.

    local maxDeltaTimeError is 1E-5.
    
    // loop until a dv is found which is in Bounds of our search interval
    until false {
        set dv_p to SecantSolveAlgorithm_Bounded( calculateTimeDelta, 0, 0, dv_Orbit1_to_Orbit2 ).

        log "   # dv_p        : " + dv_p to debugFile.
        log "   # dv_p < 0    : " + (dv_p < 0) to debugFile.
        log "   # dv_p > dv02 : " + (dv_p > dv_Orbit1_to_Orbit2) to debugFile.

        if abs( calculateTimeDelta( dv_p ) ) > maxDeltaTimeError
            increasePhaseTime().
        else
            break.
    }

    // the (integer) amount of how many time we have to Orbit around Orbit 1 so we are lined up with the rendezvous
    local OrbitPassesOf1 is round( time_phaseUp / orbitPeriod1 ).

// Maneuver Node claculations (MNc) ===========================================
    // a sclara measurement of time on which every timing events are added
    // this allows a simpler track of the nodes occuring time
    local timeCounter is codetime.
    
    // a helper ADD-Function to simplify the incrementation of the accumulating times
    local addTimeCount is { parameter t. set timeCounter to timeCounter + t. }.
    
    
    // time at which the Ship (Chaser) is at the first maneuver node
    addTimeCount( time_ShipToTransition ).
    // maneuver : orbit 0 -> orbit 1
    local mn_initial_2_phaseUp is Node( timeCounter, 0, 0, dv_p ).

    // time which the Ship has to cover in the phaseup orbit
    addTimeCount( OrbitPassesOf1 * orbitPeriod1 ).
    // maneuver : orbit 1 -> orbit 2
    local mn_phaseUp_2_transition is Node( timeCounter, 0, 0, dv_Orbit1_to_Orbit2 - dv_p ).

    // time which the Ship has to cover in the phaseup orbit
    addTimeCount( time_transition ).
    // maneuver : orbit 2 -> orbit 3
    local mn_transition_2_final is Node( timeCounter, 0, 0, dv_Orbit2_to_Orbit3 ).
    print timeCounter.

    add mn_initial_2_phaseUp.
    add mn_phaseUp_2_transition.
    add mn_transition_2_final.


debugData().