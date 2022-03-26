
function step_launch {
	STAGE.
	SET thrott TO 1.
	WAIT 3.
	STAGE.
	LOCK STEERING TO HEADING(0,90). //Don't rotate until we clear tower
	WAIT 5.

	SET steeringDir TO DroneShip:HEADING.
	SET Vdeg to 90.

	LOCK STEERING TO HEADING(steeringDir,Vdeg).

	UNTIL SHIP:APOAPSIS>1000{
		wait 0.25.
	}
	

	UNTIL SHIP:AIRSPEED>airspeed_BECO{
		if(coreThrustLimited = false){
			SET coreThrustLimited TO true.
			setEngineThrustLimit("core",0).
		}
	
		SET Vdeg To Vdeg-launchPitchSpeed.
		wait 1.
	}.
	
	AG10 ON. //BECO.
	WAIT 1.
	SET genoutputmessage TO "Release Boosters".
	STAGE.

	wait 1.
	
	updateReadouts().
	
	SET step TO false. //kill step.
}

function step_fhCore {
	SET thrott TO 1.
	SET steeringDir TO DroneShip:HEADING.
	if(coreBoosterExpendMode=TRUE){
		LOCK STEERING TO HEADING(steeringDir,13).
		if(SHIP:AVAILABLETHRUST<10){
			SET thrott TO 0.
			wait 1.
			stage. // release stage 2.
			SET step TO false.
		}
	}else{
		LOCK STEERING TO HEADING(steeringDir,20).
		if SHIP:GROUNDSPEED>2800{
			SET thrott TO 0.
			wait 1.
			stage. // release stage 2.
			SET step TO false.
		}.
	}
}

function step_fhCoreBurnLoop {
	SET thrott TO 0.
	if(isShip("stage2")){
		SET SHIP:NAME TO "stage2".
		wait 1. //wait for vessel switch if needed.
		SET thrott TO 1.
	}else{
		SET SHIP:NAME TO "fhCore".
		WAIT 5.			
		//if(isShip("fhCore")){
			//kuniverse:forcesetactivevessel(VESSEL("stage2")).
		//}
		//wait 1.
	}
	SET step TO false.
}

function step_fhCoreWait4RetroBurn{
	if(ADDONS:TR:HASIMPACT) {
		AG10 ON.
		RCS ON.
		steerToTarget().
		WAIT 15.
		SET thrott TO 1.
		SET step TO false.
	}
}

function step_fhCoreRetroBurn{
	RCS OFF.
	steerToTarget(0, coreAdjustLatOffset, coreAdjustLngOffset).
	if(impactDist < 500){
		SET thrott TO 0.
		SET step to FALSE.
	}else if(impactDist < 30000){
		SET thrott TO 0.1.
		engineToggle("center").
	}else{
		SET thrott TO 1.
	}
}

function step_wait4coreEntryburn{
	LOCK STEERING TO getVectorSurfaceRetrograde().
	if SHIP:ALTITUDE < 70000 {
		BRAKES ON.
		RCS ON.
	}
	if SHIP:ALTITUDE < 55000 {			
		SET thrott to 1.
		engineToggle("three").
		if(SHIP:VERTICALSPEED > -850){
			SET thrott to 0.
			setHoverPIDLOOPS(). //you can manually set them, but these are some good defaults.
			setHoverTarget(landingTarget:LAT,landingTarget:LNG).
			activateBurnedTexture().
			SET step to false.
		}
	}
}

function step_prepBoostersForLanding {
	if(isShip("fhCore")){
		//SET step TO "fhCore".
		setEngineThrustLimit("core",100).
	}

	if(isShip("fhBooster1")){
		SET thrott TO 0.
		//setTorqueFactor("high").
		SET SHIP:NAME TO "fhBooster1".
		//SET step TO "fhBooster1".
		
		WAIT 3.
		engineToggle("three").
		RCS ON.
	}
	if(isShip("fhBooster2")){
		SET thrott TO 0.
		//setTorqueFactor("high").
		SET SHIP:NAME TO "fhBooster2".
		//SET step TO "fhBooster2".
		
		WAIT 3.
		engineToggle("three").
		RCS ON.
	}
	SET step TO false.
}

function step_fhBooster1{
	SET commTargetVessel TO VESSEL("fhBooster2").
		
	LOCK STEERING TO getVectorSurfaceRetrograde().
	
	if(boosterLandMode=true){
		kuniverse:forcesetactivevessel(SHIP).
	}
	SET step TO false.
}

function step_fhBooster2{
	SET boosterToCopy TO VESSEL("fhBooster1").
	LOCK STEERING TO boosterToCopy:facing:vector.
}

function step_wait4burntime{
	steerToTarget(boosterAdjustPitch,boosterAdjustLatOffset,boosterAdjustLngOffset).
	WAIT 15.
	SET thrott TO 1.
	SET step TO false.
}

function step_boosterAdjustBurn{
	if(isShip("fhBooster1")){
		SET controlPart TO SHIP:PARTSTAGGED("fhBooster1")[0].
	}
	if(isShip("fhBooster2")){
		SET controlPart TO SHIP:PARTSTAGGED("fhBooster2")[0].
	}
	controlPart:CONTROLFROM().
	steerToTarget(boosterAdjustPitch,boosterAdjustLatOffset,boosterAdjustLngOffset).
	
	if(impactDist < 500){		
		SET thrott TO 0.
		WAIT 1.
		
		if(isShip("fhBooster1")){
			if(boosterLandMode=true){
				kuniverse:forcesetactivevessel(commTargetVessel).
			}
			sendCommToVessel(commTargetVessel,list("step",false)).
		}
		RCS OFF.
		SET step TO false.
	}else if(impactDist < 20000){
		engineToggle("center").
		
		SET thrott TO 0.1.
		if(isShip("fhBooster1")){
			sendCommToVessel(commTargetVessel,list("thrott",0)).
		}
	}else{
		SET thrott TO 1.
		if(isShip("fhBooster1")){
			sendCommToVessel(commTargetVessel,list("thrott",thrott)).
		}
	}
}

function step_wait4burntimeBooster2{
	SET thrott TO 1.
	engineToggle("center").
	WAIT 1.
	SET step TO false.
}

function step_wait4entryburn{
	AG10 ON.
	if SHIP:ALTITUDE < 62000 {
		RCS ON.
	}
	if SHIP:ALTITUDE < 56000 {
		BRAKES ON.
		engineToggle("three").
		
		SET thrott to 1.
		
		if(SHIP:AIRSPEED < boosterEnterVelocity) {
			SET thrott to 0.
			setHoverPIDLOOPS(). //you can manually set them, but these are some good defaults.
			setHoverTarget(landingTarget:LAT,landingTarget:LNG).
			limitGridFinAuthority(70).
			SET step to false.
		}
	} else {
		LOCK STEERING TO getVectorSurfaceRetrograde().
	}
}

function step_entry{
	if(SHIP:ALTITUDE<10000){
		RCS ON.
	}else{
		RCS OFF.
	}
	
	if(SHIP:ALTITUDE<20000){
		activateBurnedTexture().
	}
	if(isShip("fhBooster1")){
		SET sBurnStart TO boosterSburnStart.
	}else if(isShip("fhBooster2")){
		SET sBurnStart TO boosterSburnStart.
	}else if(isShip("fhCore")){
		SET sBurnStart TO coreSburnStart.
	}
	SET thrott TO 0.
	
	gridFinSteer().
	
	if SHIP:ALTITUDE < sBurnStart {
		SET step TO false.
	}	
}


function step_suicideburn{
	LOCK STEERING TO getVectorSurfaceRetrograde().
	
	if sBurnDist > SHIP:ALTITUDE OR SHIP:ALTITUDE<300 {
		raiseThrottle(0.05).
	}else{
		lowerThrottle(-0.05,0.5).
	}
	
	SET vSpeedLimit TO -125.
	if(isShip("fhCore")){
		SET vSpeedLimit TO -65.
	}
	
	if SHIP:VERTICALSPEED>vSpeedLimit {
		GEAR ON. //landing legs
		LIGHTS ON.
		engineToggle("center").		
		SET step TO false.
	}
}

function step_touchdown{
	engineToggle("center").
	GEAR ON.
	SET minLandVelocity TO 3.
	
	setHoverMaxSteerAngle(5).
	setHoverMaxHorizSpeed(8).

	if(geoDist<5 AND shipPitch>85 AND SHIP:GROUNDSPEED<3){
		setHoverAltitude(landingAltitude-5). //set altitude to hover at.
	}else{
		setHoverAltitude(landingAltitude+20). //set altitude to hover at.
	}
	SET maxDescendSpeed TO 45.
	
	if(SHIP:ALTITUDE<500){
		setHoverDescendSpeed(20,0.1).
	}else if(SHIP:ALTITUDE<landingAltitude+20){
		setHoverDescendSpeed(2,0.1).
	}else{
		setHoverDescendSpeed(maxDescendSpeed,0.1).
	}
	
	updateHoverSteering(). //will automatically steer the vessel towards the target.

	SET genoutputmessage TO "Distance from target: "+CEILING(geoDist)+" "+steeringDir+" "+shipPitch.
	
	if(SHIP:STATUS="LANDED"){
		SET step TO false.
	}
}

function step_end{
	SET thrott TO 0.
	BRAKES OFF.
	LIGHTS OFF.
	SET genoutputmessage TO "LANDED!".
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	lockSteeringToStandardVector(UP:VECTOR).
	wait 8.
	SET genoutputmessage TO "MISSION COMPLETE".
	RCS OFF.
}

function step_stage2{
	if(fairingDeployed=FALSE and SHIP:ALTITUDE>130000){
		stage. // drop fairings
		SET fairingDeployed TO TRUE.
	}
	SET thrott TO 1.
	
	SET pitchCorrectionAmount TO 23.
	if(SHIP:GROUNDSPEED>6500) {
		SET pitchCorrectionAmount TO 10.
	}
	if(SHIP:GROUNDSPEED>7000) {
		SET pitchCorrectionAmount TO 4.
	}
	if(SHIP:GROUNDSPEED<5000 OR ETA:APOAPSIS<10 OR ETA:APOAPSIS>1000){ // >1000 if AP is behind us.
		LOCK STEERING TO HEADING(90,pitchCorrectionAmount).
	}else{
		LOCK STEERING TO HEADING(90,0).
	}
	
	if(SHIP:APOAPSIS > 400000 OR SHIP:AVAILABLETHRUST<10) {
		SET thrott TO 0.
		SET step TO false.
	}

	if(coreBoosterLandMode) {
		if(coreSepComplete=FALSE){
			WAIT 5.
			SET coreSepComplete TO true.
			kuniverse:forcesetactivevessel(VESSEL("fhCore")).
		}
	}
}

function step_stage2InOrbit{
	WAIT 2.
	print "Stage 2 in Orbit!".
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	WAIT 2.
	SET step TO false.
}