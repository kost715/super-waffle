// Test posts in the combat zone: four standing AI of one side. They pick
// targets by the engine's own rules (no scripted fire orders); their shots at
// and detections of player groups are measured from the group's last change.
params ["_faction"];
if (_faction == "clear") exitWith {
    {(_y select 1) apply {if (!isNull _x) then {deleteVehicle _x}}; if (!isNull (_y select 0)) then {deleteGroup (_y select 0)}} forEach PMCS2_posts;
    PMCS2_posts = createHashMap;
    true
};
private _old = PMCS2_posts getOrDefault [_faction, []];
if (_old isNotEqualTo []) then {(_old select 1) apply {if (!isNull _x) then {deleteVehicle _x}}};
private _spec = createHashMapFromArray [
    ["west", [west, "B_Soldier_F", [-40, 0]]], ["east", [east, "O_Soldier_F", [40, 0]]],
    ["guer", [resistance, "I_G_Soldier_F", [0, 60]]], ["civ", [civilian, "C_man_1", [0, -40]]]] get _faction;
_spec params ["_side", "_class", "_offset"];
private _g = createGroup [_side, true];
if (isNull _g) exitWith {false};
private _units = [];
for "_i" from 0 to 3 do {
    private _at = [(PMCS2_zone select 0) + (_offset select 0) + _i * 4, (PMCS2_zone select 1) + (_offset select 1), 0] findEmptyPosition [0, 15, _class];
    if (_at isNotEqualTo []) then {
        private _u = _g createUnit [_class, _at, [], 0, "NONE"];
        if (!isNull _u) then {
            _u setVariable ["PMCS2_role", "post " + _faction, true];
            _u disableAI "PATH"; _u allowFleeing 0;
            _u addRating 100000; _u addEventHandler ["HandleRating", {0}];
            _u addEventHandler ["Fired", {_this call PMCS_fnc_s2PostFired}];
            _units pushBack _u;
        };
    };
};
_g setBehaviour "AWARE"; _g setCombatMode "RED";
_g addEventHandler ["EnemyDetected", {_this call PMCS_fnc_s2PostDetected}];
PMCS2_posts set [_faction, [_g, _units]];
[format ["post %1: %2 units, side %3", _faction, count _units, side _g]] call PMCS_fnc_s2Log;
_units isNotEqualTo []
