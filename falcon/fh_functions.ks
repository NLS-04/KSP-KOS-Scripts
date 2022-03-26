function fh_init {
	CLEARSCREEN.

	WAIT 1.
	AG1 ON.
	WAIT 3. //wait so we can retract.

	//Auto open terminal.
	//CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").

	CLEARSCREEN.
	SET DroneShip TO VESSEL("DroneShipFH").
	
	SET DroneShipSB1 TO VESSEL("DroneShipFH").
	SET DroneShipSB2 TO VESSEL("DroneShipFH2").


	SET step TO false. // Holds the current program step.
	//SET looping TO true.
	SET coreThrustLimited TO false.
	SET thrott TO 0.
	LOCK THROTTLE TO thrott.
	SET shipPitch TO 0.
	SET geoDist TO 0.
	SET impactDist TO 0.
	SET steeringDir TO 0.
	SET targetDir TO 0.
	SET sBurnDist TO 0.
	SET fairingDeployed TO FALSE.
	SET burnedTextureSet TO FALSE.
	SET coreSepComplete TO FALSE.
	SET genoutputmessage TO "".
	SET g TO constant:G * BODY:Mass / BODY:RADIUS^2.

	set STEERINGMANAGER:ROLLTS to 50. // stop RCS from rolling (makes for terrible wasteful RCS).
	//set STEERINGMANAGER:PITCHTS to 10.
	//set STEERINGMANAGER:YAWTS to 10.   
}

function activateBurnedTexture {
	if(burnedTextureSet = FALSE){
		local maintank to ship:partstagged("maintank")[0].
		maintank:getModule("FStextureSwitch2"):doEvent("Next Paint").

		local octaweb to ship:partstagged("octaweb")[0].
		octaweb:getModule("FStextureSwitch2"):doEvent("Next Paint").
		
		SET burnedTextureSet TO TRUE.
	}
}

function limitGridFinAuthority {
  declare parameter limit.
  set gridfins to ship:partstagged("gridfin").
  for fin in gridfins {
    fin:getmodule("ModuleControlSurface"):setfield("authority limiter", limit).
  }
}

function gridFinSteer{
	if(geoDist>100){
		setHoverMaxSteerAngle(20).
	}else{
		setHoverMaxSteerAngle(15).
	}
	
	if(geoDist>1000 or SHIP:GROUNDSPEED<100) {
		SET minPitch to 0.
	}else{
		set minPitch TO 90 - ((geoDist/1000) * 90) + 5. // +5 to simply ensure it will stear 5 degrees towards teh target, any lower allows it to drift off.
	}
	print minPitch.
	setHoverMaxHorizSpeed(250). //booster will start reducing it's horizontal with limit of 200m/s
	updateHoverSteering(true,minPitch). //will automatically steer the vessel towards the target.
}


function debugDrawInit{
	SET targetDraw TO VECDRAW(
		SHIP:POSITION,
		DroneShip:POSITION,
		RGB(255,0,0),
		"",
		0.5,
		TRUE,
		0.5
	).
}

function runstep {
	parameter stepName.
	parameter stepFunction.
	if(step=false){
		SET step TO stepName.
	}
	if(step=stepName){
		UNTIL step = false {
			setLandingTarget(). //just keep landing target up to date depending on ship name.
			updateVars().
			updateReadouts().
			
			//debugDrawUpdate().
			processCommCommands().
			
			stepFunction:call(). //call main step function
		}
	}
}

function debugDrawUpdate{
	set targetDraw:vecupdater to { return Droneship:POSITION. }.
}

function updateVars { //Scalar projection of two vectors. Find component of a along b. a(dot)b/||b||
	SET geoDist TO calcDistance(landingTarget, SHIP:GEOPOSITION).
	SET shipPitch TO 90 - vang(SHIP:up:vector, SHIP:facing:forevector).
	SET distMargin TO 1300.
	SET maxVertAcc TO (SHIP:AVAILABLETHRUST) / SHIP:MASS - g. //max acceleration in up direction the engines can create
	SET vertAcc TO sProj(SHIP:SENSORS:ACC, UP:VECTOR).
	SET dragAcc TO g + vertAcc. //vertical acceleration due to drag. Same as g at terminal velocity
	SET sBurnDist TO (SHIP:VERTICALSPEED^2 / (2 * (maxVertAcc + dragAcc/2)))+distMargin.//-SHIP:VERTICALSPEED * sBurnTime + 0.5 * -maxVertAcc * sBurnTime^2.//SHIP:VERTICALSPEED^2 / (2 * maxVertAcc).	
}
function sendCommToVessel{
	parameter v.
	parameter msg.
	SET C TO v:CONNECTION.
	C:SENDMESSAGE(msg).
}
function processCommCommands{
	WHEN NOT SHIP:MESSAGES:EMPTY THEN{
	  SET RECEIVED TO SHIP:MESSAGES:POP.
	  SET cmd TO RECEIVED:CONTENT[0].
	  SET val TO RECEIVED:CONTENT[1].
	  if(cmd="thrott"){
		SET thrott TO val. //just make following vessel lag behind a little.
	  }
	  if(cmd="step"){
		SET step TO val.
	  }
	  if(cmd="AG"){
		setActionGroup(val).
	  }
	}
}
function raiseThrottle{
	parameter amount.
	parameter maxThrott is 1.
	SET thrott TO thrott+amount.
	if(thrott>maxThrott){
		SET thrott to 1. //we want to secondary vessel to keep pace but drop back a little to avoid overshooting too far
	}
}
function lowerThrottle{
	parameter amount.
	parameter min is 0.
	SET thrott TO thrott+amount.
	if(thrott<min){
		SET thrott to min.
	}	
}

function setLandingTarget{
	// Launchpad
	// SET targetLaunchpadAlt TO 105.
	// SET targetLaunchpadGeo TO Earth:GEOPOSITIONLATLNG(28.6083235902199,-80.5997405614707).
	
	// SideBooster LZ1
	//SET sBooster1_alt TO 105.
	//SET sBooster1_geo TO Earth:GEOPOSITIONLATLNG(28.6079018169203,-80.5974524550663).
	SET sBooster1_alt TO 40.
	SET sBooster1_geo TO DroneShipSB1:GEOPOSITION.
	
	// SideBooster LZ2
	//SET sBooster2_alt TO 105.
	//SET sBooster2_geo TO Earth:GEOPOSITIONLATLNG(28.6088638923253,-80.597462410286).
	SET sBooster2_alt TO 40.
	SET sBooster2_geo TO DroneShipSB2:GEOPOSITION.
	
	
	//Droneship
	SET core_alt TO 40.
	SET core_geo TO DroneShip:GEOPOSITION.
	
	if(isShip("fhBooster1")) {
		SET landingAltitude TO sBooster1_alt.
		SET landingTarget TO sBooster1_geo.	
	} else if(isShip("fhBooster2")) {
		SET landingAltitude TO sBooster2_alt.
		SET landingTarget TO sBooster2_geo.	
	} else {
		//Landing target is droneship by default
		SET landingAltitude TO core_alt.
		SET landingTarget TO core_geo.
	}
}

function steerToTarget{
	parameter pitch is 1.
	parameter overshootLatModifier is 0.
	parameter overshootLngModifier is 0.
	SET overshootLatLng TO LATLNG(landingTarget:LAT + overshootLatModifier, landingTarget:LNG + overshootLngModifier).
	SET targetDir TO geoDir(ADDONS:TR:IMPACTPOS,overshootLatLng).
	SET impactDist TO calcDistance(overshootLatLng, ADDONS:TR:IMPACTPOS).
	SET steeringDir TO targetDir - 180.
	
	LOCK STEERING TO HEADING(steeringDir,pitch).
	//lockSteeringToStandardVector(HEADING(steeringDir,pitch):VECTOR).
}

SET lastEngCmd TO FALSE.
function engineToggle{
	parameter command.
	
	if(lastEngCmd<>command){
		SET lastEngCmd TO command.
		
		SET engineGroup_center to ship:partstagged("center").
		SET engineGroup_three to ship:partstagged("three").
		SET engineGroup_full to ship:partstagged("full").
		
		SET engineGroup_centerCore to ship:partstagged("center_core").
		SET engineGroup_threeCore to ship:partstagged("three_core").
		SET engineGroup_fullCore to ship:partstagged("full_core").
		
		if(command="fullshutdown"){
			for e in engineGroup_center { e:shutdown(). }
			for e in engineGroup_three { e:shutdown(). }
			for e in engineGroup_full { e:shutdown(). }
			for e in engineGroup_centerCore { e:shutdown(). }
			for e in engineGroup_threeCore { e:shutdown(). }
			for e in engineGroup_fullCore { e:shutdown(). }
		}else if(command="center"){
			for e in engineGroup_center { e:activate(). }
			for e in engineGroup_three { e:shutdown(). }
			for e in engineGroup_full { e:shutdown(). }
			for e in engineGroup_centerCore { e:activate(). }
			for e in engineGroup_threeCore { e:shutdown(). }
			for e in engineGroup_fullCore { e:shutdown(). }
		}else if(command="three"){
			for e in engineGroup_center { e:activate(). }
			for e in engineGroup_three { e:activate(). }
			for e in engineGroup_full { e:shutdown(). }
			for e in engineGroup_centerCore { e:activate(). }
			for e in engineGroup_threeCore { e:activate(). }
			for e in engineGroup_fullCore { e:shutdown(). }
		}else if(command="full"){
			for e in engineGroup_center { e:activate(). }
			for e in engineGroup_three { e:activate(). }
			for e in engineGroup_full { e:activate(). }
			for e in engineGroup_centerCore { e:activate(). }
			for e in engineGroup_threeCore { e:activate(). }
			for e in engineGroup_fullCore { e:activate(). }
		}
	}
}

function updateReadouts{
	print "Step: "+step+"                           " AT(0,0).
	print "Target Direction = "+round(targetDir,3)+", Steering direction = "+round(steeringDir,3)+"                           " AT(0,2).
	print "Ground distance from target = "+round(geoDist,3)+"                           " AT(0,3).
	print "Impact distance from target = "+round(impactDist,3)+"                           " AT(0,4).
	print "Vessel Pitch = "+round(shipPitch,3)+"                           " AT(0,6).
	print "Ground speed = "+round(SHIP:GROUNDSPEED,3)+"                           " AT(0,7).
	print genoutputmessage+"                           " AT(0,9).
}