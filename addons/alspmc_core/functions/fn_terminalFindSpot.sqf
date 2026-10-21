params ["_key"];
private _house = [_key] call ALS_fnc_houseObj;
if (isNull _house) exitWith {[]};
private _floors = [_house] call ALS_fnc_houseFloor;
if (_floors isEqualTo []) exitWith {[]};
private _doors = [];
for "_i" from 0 to 8 do {
    private _exit = _house buildingExit _i;
    if (_exit isEqualTo [0, 0, 0]) exitWith {};
    _doors pushBack (AGLToASL _exit);
};
private _deskClass = getText (configFile >> "ALSPMC_Settings" >> "terminalDesk");
private _probe = createSimpleObject [_deskClass, [0, 0, 5000], true];
private _box = boundingBoxReal _probe;
deleteVehicle _probe;
private _halfX = ((abs ((_box select 0) select 0)) max (abs ((_box select 1) select 0))) + 0.12;
private _halfY = ((abs ((_box select 0) select 1)) max (abs ((_box select 1) select 1))) + 0.15;
private _found = [];
private _best = [];
private _bestScore = -1;
// Native walkable ground-floor points are the primary source. Probe nearby
// positions to keep the desk off walls and exits, as LifeSim does for shops.
{
    private _origin = AGLToASL _x;
    {
        private _p = _origin vectorAdd _x;
        private _doorDist = if (_doors isEqualTo []) then {10} else {selectMin (_doors apply {_x distance2D _p})};
        private _furn = (missionNamespace getVariable ["ALS_furniture", createHashMap]) getOrDefault [_key, []];
        private _free = (_furn findIf {!isNull _x && {_x distance2D (ASLToAGL _p) < 1.7}}) < 0;
        if (_free && {_doorDist > 1.8}) then {
            // The fallback must remain an actual native walkable point;
            // offset candidates can lie beyond a wall when a mesh has no rays.
            if (_x isEqualTo [0,0,0] && {_doorDist > _bestScore}) then {_bestScore = _doorDist; _best = [_p, getDir _house]};
            for "_turn" from 0 to 3 do {
                private _dir = getDir _house + _turn * 90;
                private _right = [cos _dir, -sin _dir, 0];
                private _forward = [sin _dir, cos _dir, 0];
                private _points = [[0,0],[-_halfX,-_halfY],[_halfX,-_halfY],[-_halfX,_halfY],[_halfX,_halfY],[0,-(_halfY + 0.65)]];
                private _zs = [];
                private _ok = true;
                {
                    private _q = _p vectorAdd (_right vectorMultiply (_x select 0)) vectorAdd (_forward vectorMultiply (_x select 1));
                    private _down = lineIntersectsSurfaces [_q vectorAdd [0,0,0.65], _q vectorAdd [0,0,-1], objNull, objNull, true, 1, "GEOM", "NONE"];
                    if (_down isEqualTo []) exitWith {_ok = false};
                    private _hit = _down select 0;
                    if (!isNull (_hit select 2) && {(_hit select 2) != _house}) exitWith {_ok = false};
                    _zs pushBack ((_hit select 0) select 2);
                    if ((lineIntersectsSurfaces [_p vectorAdd [0,0,0.55], _q vectorAdd [0,0,0.55], objNull, objNull, true, 1, "GEOM", "NONE"]) isNotEqualTo []) exitWith {_ok = false};
                } forEach _points;
                if (_ok && {(selectMax _zs) - (selectMin _zs) < 0.12}) then {
                    private _roof = lineIntersectsSurfaces [_p vectorAdd [0,0,0.8], _p vectorAdd [0,0,30], objNull, objNull, true, 1, "GEOM", "NONE"];
                    if (_roof isNotEqualTo [] && {((_roof select 0) select 2) == _house}) then {
                        _found = [[_p select 0, _p select 1, selectMax _zs], _dir];
                    };
                };
                if (_found isNotEqualTo []) exitWith {};
            };
        };
        if (_found isNotEqualTo []) exitWith {};
    } forEach [[0,0,0],[0.7,0,0],[-0.7,0,0],[0,0.7,0],[0,-0.7,0]];
    if (_found isNotEqualTo []) exitWith {};
} forEach (_floors select [0, 24]);
// Some community models lack useful collision meshes. Keep the native
// walkable position as a fallback, rather than placing a computer at [0,0,0].
if (_found isEqualTo []) then {
    _found = if (_best isEqualTo []) then {[AGLToASL (_floors select 0), getDir _house]} else {_best};
};
_found
