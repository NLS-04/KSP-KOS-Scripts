copypath("0:/functions_common.ks","").
copypath("0:/fh_functions.ks","").
copypath("0:/fh_steps.ks","").
RUN functions_common.ks. //Includes the function library
RUN fh_functions.ks.
RUN fh_steps.ks.

fh_init().

SET step TO "launch".
//SET step TO "prepBoostersForLanding". //test landing booster.
//SET step TO "wait4entryburn". 
//SET step TO "fhCoreWait4RetroBurn". 
//SET step TO "wait4coreEntryburn".
//SET step TO "stage2".

//SET boosterLandMode TO false.
SET boosterLandMode TO true.

SET coreBoosterLandMode TO false.
//SET coreBoosterLandMode TO true.

SET coreBoosterExpendMode TO true.



SET launchPitchSpeed TO 0.55. // How fast to pitch on ascent (depending on payload this may change).
SET airspeed_BECO TO 1900. // Booster airspeed at BECO

SET boosterAdjustPitch TO 0. //Boost back to LZ1 , should be 10, Droneship should be 0.
SET boosterAdjustLatOffset TO -0.015. // Positive (further noth), negative (further south).
SET boosterAdjustLngOffset TO 0.31. //-0.11 LZ1/LZ2,  0.11 droneship
SET boosterEnterVelocity TO 1400.
SET boosterSburnStart TO 3200.

SET coreAdjustLatOffset TO 0.
SET coreAdjustLngOffset TO 0.071.
SET coreSburnStart TO 1900.





//debugDrawInit().	

runstep("launch",step_launch@).
runstep("prepBoostersForLanding",step_prepBoostersForLanding@).
// Ship will have been split and named at this point.

if(isShip("fhCore")){
	runstep("fhCore",step_fhCore@).
	runstep("fhCoreBurnLoop",step_fhCoreBurnLoop@).
}

// Stage 2 will have been split and named at this point.
if(isShip("fhCore")){
	runstep("fhCoreWait4RetroBurn",step_fhCoreWait4RetroBurn@).
	runstep("fhCoreRetroBurn",step_fhCoreRetroBurn@).
	runstep("wait4coreEntryburn",step_wait4coreEntryburn@).
}

if(isShip("fhBooster1")){
	runstep("fhBooster1",step_fhBooster1@).
	runstep("wait4burntime",step_wait4burntime@).
	runstep("boosterAdjustBurn",step_boosterAdjustBurn@).
	runstep("wait4entryburn",step_wait4entryburn@).
}

if(isShip("fhBooster2")){
	runstep("fhBooster2",step_fhBooster2@).
	runstep("wait4burntimeBooster2",step_wait4burntimeBooster2@).
	runstep("boosterAdjustBurn",step_boosterAdjustBurn@).
	runstep("wait4entryburn",step_wait4entryburn@).
}


if(isShip("fhBooster1") OR isShip("fhBooster2") OR isShip("fhCore")){
	runstep("entry",step_entry@).
	runstep("suicideburn",step_suicideburn@).
	runstep("touchdown",step_touchdown@).
	runstep("end",step_end@).
}

if(isShip("stage2")){
	runstep("stage2",step_stage2@).
	runstep("stage2InOrbit",step_stage2InOrbit@).
}