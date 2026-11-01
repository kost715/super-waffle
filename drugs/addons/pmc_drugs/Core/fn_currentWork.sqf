// [unit] -> the unit's work now in W, as ACE Advanced Fatigue's main loop counts it this
// second: the metabolic cost of moving on foot on the ground (ACE's own getMetabolicCosts,
// which applies every duty factor, the drugs' included), at least the resting work REE
// (18.83 W); just REE standing, in a vehicle or in the air. Client, for the player's unit.
params ["_unit"];
private _ree = 18.83;
private _velocity = velocity _unit;
private _speed = (vectorMagnitude _velocity) min 6;
if (!isNull objectParent _unit || {_speed <= 0.1} || {!(isTouchingGround _unit || {underwater _unit})}
    || {isNil "ace_advanced_fatigue_fnc_getMetabolicCosts"}) exitWith {_ree};
private _swimming = missionNamespace getVariable ["ace_advanced_fatigue_isSwimming", false];
private _fwdAngle = 0;
private _sideAngle = 0;
if (!_swimming) then {
    private _movement = vectorNormalized _velocity;
    _fwdAngle = asin (_movement select 2);
    if (((getPosATL _unit) select 2) <= 0.01) then {
        _sideAngle = asin ((vectorNormalized (_movement vectorCrossProduct (surfaceNormal getPosWorld _unit))) select 2);
    };
};
// Diving to the ground counts as prone at running speed: ACE caps it.
if (stance _unit == "PRONE") then {_speed = _speed min 1.5};
private _gradient = abs _fwdAngle;
private _terrain = 1;
if (!_swimming) then {
    if (_fwdAngle < 0) then {_gradient = 0.15 * _gradient};
    if (_sideAngle != 0) then {_terrain = 1 + ((abs (_sideAngle / 45) min 1) ^ 4)};
};
private _load = _unit getVariable "ace_movement_totalLoad";
if (isNil "_load") then {_load = loadAbs _unit};
private _gear = 0 max ((_load / 22.046 - 3.5) * (missionNamespace getVariable ["ace_advanced_fatigue_loadFactor", 1]));
(([_gear, _gradient * (missionNamespace getVariable ["ace_advanced_fatigue_terrainGradientFactor", 1]) * 0.1, _terrain, _speed]
    call ace_advanced_fatigue_fnc_getMetabolicCosts) max _ree)
