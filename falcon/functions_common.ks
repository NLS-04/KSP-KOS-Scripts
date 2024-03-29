function setHoverPIDLOOPS{

	SET bodyRadius TO 17000. //note Kerbin is around 1700
	
	//Controls altitude by changing climbPID setpoint
	SET hoverPID TO PIDLOOP(1, 0.01, 0.0, -50, 50). 
	//Controls vertical speed
	SET climbPID TO PIDLOOP(0.1, 0.3, 0.005, 0, 1). 
	//Controls horizontal speed by tilting rocket
	SET eastVelPID TO PIDLOOP(3, 0.01, 0.0, -20, 20).
	SET northVelPID TO PIDLOOP(3, 0.01, 0.0, -20, 20). 
	 //controls horizontal position by changing velPID setpoints
	SET eastPosPID TO PIDLOOP(bodyRadius, 0, 100, -40,40).
	SET northPosPID TO PIDLOOP(bodyRadius, 0, 100, -40,40).
}

function writeToLogFile {
	parameter txt.
	log txt TO "0:/log.txt".
}

function sProj { //Scalar projection of two vectors.
	parameter a.
	parameter b.
	if b:mag = 0 { PRINT "sProj: Divide by 0. Returning 1". RETURN 1. }
	RETURN VDOT(a, b) * (1/b:MAG).
}
function isShip{
	parameter tagName.
	SET thisParts TO SHIP:PARTSTAGGED(tagName).
	if(thisParts:LENGTH>0){
		return true.
	}
	return false.
}

function setEngineThrustLimit{
	parameter engineName.
	parameter engineThrustLimit. // 0 - 100

	for e IN ship:partstagged("center_core") { SET e:THRUSTLIMIT TO engineThrustLimit. }.
	for e IN ship:partstagged("three_core") { SET e:THRUSTLIMIT TO engineThrustLimit. }.
	for e IN ship:partstagged("full_core") { SET e:THRUSTLIMIT TO engineThrustLimit. }.
}

// Used for communication
function setActionGroup {
  parameter groupIndex.
  if groupIndex = 0 {
    TOGGLE AG0.
  } else if groupIndex = 1 {
    TOGGLE AG1.
  }else if groupIndex = 2 {
    TOGGLE AG2.
  }else if groupIndex = 3 {
    TOGGLE AG3.
  }else if groupIndex = 4 {
    TOGGLE AG4.
  }else if groupIndex = 5 {
    TOGGLE AG5.
  }else if groupIndex = 6 {
    TOGGLE AG6.
  }else if groupIndex = 7 {
    TOGGLE AG7.
  }else if groupIndex = 8 {
    TOGGLE AG8.
  }else if groupIndex = 9 {
    TOGGLE AG9.
  }else if groupIndex = 10 {
    TOGGLE AG10.
  }
}

function cVel {
	local v IS SHIP:VELOCITY:SURFACE.
	local eVect is VCRS(UP:VECTOR, NORTH:VECTOR).
	local eComp IS sProj(v, eVect).
	local nComp IS sProj(v, NORTH:VECTOR).
	local uComp IS sProj(v, UP:VECTOR).
	RETURN V(eComp, uComp, nComp).
}
function updateHoverSteering{
	parameter reverse is false.
	parameter minPitch is 0.
	SET cVelLast TO cVel().
	SET eastVelPID:SETPOINT TO eastPosPID:UPDATE(TIME:SECONDS,  addons:tr:impactPos:LNG).
	SET northVelPID:SETPOINT TO northPosPID:UPDATE(TIME:SECONDS,addons:tr:impactPos:LAT).
	LOCAL eastVelPIDOut IS eastVelPID:UPDATE(TIME:SECONDS, cVelLast:X).
	LOCAL northVelPIDOut IS northVelPID:UPDATE(TIME:SECONDS, cVelLast:Z).
	LOCAL eastPlusNorth is MAX(ABS(eastVelPIDOut), ABS(northVelPIDOut)).
	
	LOCAL steeringDirNonNorm IS ARCTAN2(eastVelPID:OUTPUT, northVelPID:OUTPUT). //might be negative
	if steeringDirNonNorm >= 0 {
		SET steeringDir TO steeringDirNonNorm.
	} else {
		SET steeringDir TO 360 + steeringDirNonNorm.
	}
	if(reverse) {
		SET steeringDir TO steeringDir - 180.
		if steeringDir < 0 {
			SET steeringDir TO 360 + steeringDir.
		}
	}
	SET shipPitch TO 90 - eastPlusNorth.
	if(shipPitch < minPitch) {
		SET shipPitch TO minPitch.
	}
	
	LOCAL thisHeading TO HEADING(steeringDir,shipPitch).
	LOCK STEERING TO lookdirup(thisHeading:vector, ship:facing:topvector).
}

function setTorqueFactor{
	parameter val.
	if(val="high"){
		set STEERINGMANAGER:pitchtorquefactor to 5.
		set STEERINGMANAGER:yawtorquefactor to 5.
		set STEERINGMANAGER:rolltorquefactor to 5.
		set STEERINGMANAGER:MAXSTOPPINGTIME to 1.
	}else{
		//back to defaults
		set STEERINGMANAGER:pitchtorquefactor to 1.
		set STEERINGMANAGER:yawtorquefactor to 1.
		set STEERINGMANAGER:rolltorquefactor to 1.
		set STEERINGMANAGER:MAXSTOPPINGTIME to 2.
	}
}
function setHoverTarget{
	parameter loc.
	SET eastPosPID:SETPOINT TO loc:lng.
	SET northPosPID:SETPOINT TO loc:lat.
}
function setHoverAltitude{ //set just below landing altitude to touchdown smoothly
	parameter a.
	SET hoverPID:SETPOINT TO a.
}
function setHoverDescendSpeed{
	parameter a.
	parameter minThrott is 0.
	SET hoverPID:MAXOUTPUT TO a.
	SET hoverPID:MINOUTPUT TO -1*a.
	SET climbPID:SETPOINT TO hoverPID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE). //control descent speed with throttle
	SET calcThrott TO climbPID:UPDATE(TIME:SECONDS, SHIP:VERTICALSPEED).
	if(calcThrott<minThrott){
		SET calcThrott TO minThrott.
	}
	
	if(SHIP:VERTICALSPEED>-1) {
		SET calcThrott TO 0.
	}
	SET thrott TO calcThrott.	
}
function setHoverMaxSteerAngle{
	parameter a.
	SET eastVelPID:MAXOUTPUT TO a.
	SET eastVelPID:MINOUTPUT TO -1*a.
	SET northVelPID:MAXOUTPUT TO a.
	SET northVelPID:MINOUTPUT TO -1*a.
}
function setHoverMaxHorizSpeed{
	parameter a.
	SET eastPosPID:MAXOUTPUT TO a.
	SET eastPosPID:MINOUTPUT TO -1*a.
	SET northPosPID:MAXOUTPUT TO a.
	SET northPosPID:MINOUTPUT TO -1*a.
}
function setThrottleSensitivity{
	parameter a.
	SET climbPID:KP TO a.
}
function lockSteeringToStandardVector{
	parameter v.
	LOCK STEERING TO lookdirup(v, ship:facing:topvector).
}

function calcDistance { //Approx in meters
	parameter geo1.
	parameter geo2.
	return (geo1:POSITION - geo2:POSITION):MAG.
}
function geoDir {
	parameter geo1.
	parameter geo2.
	return ARCTAN2(geo1:LNG - geo2:LNG, geo1:LAT - geo2:LAT).
}
function updateMaxAccel {
	SET g TO constant:G * BODY:Mass / BODY:RADIUS^2.
	SET maxAccel TO (SHIP:AVAILABLETHRUST) / SHIP:MASS - g. //max acceleration in up direction the engines can create
}
function getPhaseAngleToTargetOLD{
	parameter targetBody.
	set shippos to SHIP:VELOCITY:ORBIT.
	set targetpos to targetBody:orbit:position.
	return vang(shippos,targetpos).
}
function getPhaseAngleToTarget{
	parameter targetBody.
	set targetPos to (targetBody:orbit:position - ship:body:position):normalized.
	set shipPos to (ship:position - ship:body:position):normalized.
	set phaseAngle to ARCTAN2(targetPos:z,targetPos:x) - ARCTAN2(shipPos:z,shipPos:x).
	if(phaseAngle<0){
		set phaseAngle to phaseAngle +360.
	}
	return phaseAngle.
}
function getInterceptAngle{
	parameter phaseAndle.
	set interceptAngle to phaseAngle - 110.6713.
	if interceptAngle < 0{
		set interceptAngle to interceptAngle+360.
	}
	return interceptAngle.
}
function getKerbinOrbitAngleToTarget{
	parameter targetBody.
	set kerbinpos to Body("Kerbin"):position.
	set targetpos to targetBody:orbit:position.
	return vang(kerbinpos,targetpos).
}

function getVectorRadialin{
	SET normalVec TO getVectorNormal().
	return vcrs(ship:velocity:orbit,normalVec).
}
function getVectorRadialout{
	SET normalVec TO getVectorNormal().
	return -1*vcrs(ship:velocity:orbit,normalVec).
}
function getVectorNormal{
	return vcrs(ship:velocity:orbit,-body:position).
}
function getVectorAntinormal{
	return -1*vcrs(ship:velocity:orbit,-body:position).
}
function getVectorSurfaceRetrograde{
	return -1*ship:velocity:surface.
}
function getVectorSurfacePrograde{
	return ship:velocity:surface.
}
function getOrbitLongitude{
	return MOD(OBT:LAN + OBT:ARGUMENTOFPERIAPSIS + OBT:TRUEANOMALY, 360).
}
function getBodyAscendingnodeLongitude{
	return SHIP:ORBIT:LONGITUDEOFASCENDINGNODE.
}
function getBodyDescendingnodeLongitude{
	return SHIP:ORBIT:LONGITUDEOFASCENDINGNODE+180.
}
function getPitch{
	return 90 - vang(facing:vector, up:vector).
}
function getTerrainAltitude{
	return SHIP:ALTITUDE-ALT:RADAR.
}