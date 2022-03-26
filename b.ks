runOncePath("0:_lib/Hohmann.ks").
runOncePath("0:_lib/HillClimber.ks").
runOncePath("0:_lib/Classes.ks").
// #include "0:_lib/Hohmann.ks"
// #include "0:_lib/Hohmann.ks"
// #include "0:_lib/Classes.ks"

// t1: t_trans

clearScreen.
clearVecDraws().

local tgt_e is target:orbit:eccentricity.
local tgt_T is target:orbit:period.

local h is { 
    parameter Rapo is body:radius + target:orbit:apoapsis, ecc is target:orbit:eccentricity.
    return sqrt(Rapo*body:mu*( 1-ecc )).
}.

function dvViva {
    parameter r, a1, a2.
    return sqrt(body:mu) * ( sqrt(2/r - 1/a2) - sqrt(2/r - 1/a1) ).
}

// dv to match orbits at Intersection
// local endDV is 30.

// dr to match orbits at Intersection
local endDR is 1000.
// true Anomaly at which Intersection occurse
local IntersectionTheta is 130.

local Per_phase is obt:apoapsis + body:radius.

// minimum safe altitude to center of Body
local r_min is 670000.

local h_tgt is h().
local rI is h_tgt^2/body:mu * 1/( 1+tgt_e*cos(IntersectionTheta) ).

// local endDV_max is ( h_tgt-h(r_min) )/rI.

local h_trans is sqrt( h_tgt^2 - endDR*body:mu*( 1+tgt_e*cos(IntersectionTheta) ) ).

local Per_trans is h_trans^2/body:mu * 1/(1+tgt_e).

// >>> TIMINGS <<<
    // time till target is at intersection Point
    local t_tgt_I is mod( TrueAnomalyToTime(IntersectionTheta, tgt_e, tgt_T) - TrueAnomalyToTime(target:orbit:trueAnomaly, tgt_e, tgt_T) + tgt_T, tgt_T).
    // time of ship to till Apoapsis
    local t_C_Apo is mod( TrueAnomalyToTime(180) - TrueAnomalyToTime(obt:trueAnomaly) + obt:period, obt:period ).


    // time of transition time
    local Period_trans is h_trans^3 * constant:pi/body:mu^2 * sqrt( .5*(( tgt_e+2 )/( tgt_e+1 ))^3 ).
    local t_trans is TrueAnomalyToTime(IntersectionTheta, tgt_e, Period_trans).

    // time of half ellipse after alignment
    local t_phase is constant:pi*sqrt( .125 * (Per_trans+Per_phase)^3/body:mu ).

    // minium time for orbit adjustment
    local t_align_min is constant:pi*sqrt( .5 * (Per_phase+r_min)^3/body:mu ).

    // time after which the orbit should be adjusted 
    // correcting t_tgt_I so that its periapsis is not lower than minimum
    local kTs_corr to tgt_T*ceiling( (t_trans + t_phase + t_C_Apo + t_align_min)/tgt_T ).
    set t_tgt_I to t_tgt_I + kTs_corr.
    set t_align to t_tgt_I - t_trans - t_phase - t_C_Apo.

local Per_align is ( (t_align)^2 * 2*body:mu/constant:pi^2 )^(1/3) - Per_phase.

// >>> SPEEDS <<<
    local dv_align      is dvViva( Per_phase, obt:semimajoraxis,       (Per_phase+Per_align)/2         ).
    local dv_phasing    is dvViva( Per_phase, (Per_phase+Per_align)/2, (Per_trans+Per_phase)/2         ).
    local dv_Transition is dvViva( Per_trans, (Per_trans+Per_phase)/2, h_trans^2/(body:mu*(1-tgt_e^2)) ).
    
    add node(time:seconds+t_C_Apo,                 0, 0, dv_align).
    add node(time:seconds+t_C_Apo+t_align,         0, 0, dv_phasing).
    add node(time:seconds+t_C_Apo+t_align+t_phase, 0, 0, dv_Transition).


log "===============================" to a.csv.
log "h_tgt:         " + h_tgt         to a.csv.
log "h_trans:       " + h_trans       to a.csv.
log "rI:            " + rI            to a.csv.
log "Per_trans:     " + Per_trans     to a.csv.
log "Period_trans:  " + Period_trans  to a.csv.
log "t_tgt_I:       " + t_tgt_I       to a.csv.
log "t_trans:       " + t_trans       to a.csv.
log "t_phase:       " + t_phase       to a.csv.
log "t_C_Apo:       " + t_C_Apo       to a.csv.
log "t_align:       " + t_align       to a.csv.
log "t_align_min:   " + t_align_min   to a.csv.
log "Per_align:     " + Per_align     to a.csv.
log "dv_align:      " + dv_align      to a.csv.
log "dv_phasing:    " + dv_phasing    to a.csv.
log "dv_Transition: " + dv_Transition to a.csv.

global vd is vecDraw(
    body:position,    
    positionAt(target, t_tgt_I + time:seconds) - body:position,
    red, "I", 1, true, .2
).


until terminal:input:haschar {
    set t_C_Apo to mod( TrueAnomalyToTime(180) - TrueAnomalyToTime(obt:trueAnomaly) + obt:period, obt:period ).
    set t_tgt_I to mod( TrueAnomalyToTime(IntersectionTheta, tgt_e, tgt_T) - TrueAnomalyToTime(target:orbit:trueAnomaly, tgt_e, tgt_T) + tgt_T, tgt_T).
    set t_tgt_I to t_tgt_I + tgt_T*ceiling( (t_trans + t_phase + t_C_Apo + t_align_min)/tgt_T ).
    set t_align to t_tgt_I - t_trans - t_phase - t_C_Apo.
    set Per_align to ( (t_align-0*obt:period)^2 * 2*body:mu/constant:pi^2 )^(1/3) - Per_phase.

    print "h_tgt:         " + h_tgt         at(5,  1).
    print "h_trans:       " + h_trans       at(5,  2).
    print "rI:            " + rI            at(5,  3).
    print "Per_phase:     " + Per_phase     at(5,  4).
    print "Per_trans:     " + Per_trans     at(5,  5).
    print "Period_trans:  " + Period_trans  at(5,  6).
    print "t_tgt_I:       " + t_tgt_I       at(5,  7).
    print "t_trans:       " + t_trans       at(5,  8).
    print "t_phase:       " + t_phase       at(5,  9).
    print "t_C_Apo:       " + t_C_Apo       at(5, 10).
    print "t_align:       " + t_align       at(5, 11).
    print "t_align_min:   " + t_align_min   at(5, 12).
    print "Per_align:     " + Per_align     at(5, 13).
    print "dv_align:      " + dv_align      at(5, 14).
    print "dv_phasing:    " + dv_phasing    at(5, 15).
    print "dv_Transition: " + dv_Transition at(5, 16).

    local cas is close_aproach_scan(ship, target, time:seconds+t_C_Apo+t_align+t_phase, target:orbit:period, 36, 1, true).
    print "CAS: DIST:     " + cas["dist"]   at(5, 18).
    print "CAS: UTS:      " + cas["UTS"]    at(5, 19).
}