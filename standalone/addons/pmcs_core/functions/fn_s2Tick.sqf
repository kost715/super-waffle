// Once a second on the server: zone membership with hysteresis, gang control
// zone demask, aura refresh, desired state, shared colour inside vehicles, apply.
private _now = diag_tickTime;
private _hysteresis = {
    params ["_wasIn", "_distance", "_in", "_out"];
    if (_wasIn) then {_distance <= _out} else {_distance <= _in}
};
private _wants = [];
{
    private _p = _x;
    private _uid = getPlayerUID _p;
    if (alive _p && {_uid != ""}) then {
        private _r = PMCS2_records getOrDefault [_uid, createHashMap];
        if (count _r == 0) then {_r = [_p] call PMCS_fnc_s2Register};
        _r set ["unit", _p];
        private _distance = _p distance2D PMCS2_zone;
        private _in = [_r getOrDefault ["inZone", false], _distance, PMCS2_zoneIn, PMCS2_zoneOut] call _hysteresis;
        _r set ["inZone", _in]; _r set ["distance", round _distance];
        private _inGang = [_r getOrDefault ["inGang", false], _p distance2D PMCS2_gangZone, PMCS2_gangIn, PMCS2_gangOut] call _hysteresis;
        // Entering a gang's control area (its camp, the approach to a hideout)
        // strips civilian cover; inside it the combat colour is kept.
        if (_inGang && {!(_r getOrDefault ["inGang", false])}) then {[_r, "entered gang control zone"] call PMCS_fnc_s2Demask};
        _r set ["inGang", _inGang];
        private _contract = _r get "contract";
        if (_in && {_contract != "none"}) then {
            _r set ["combat", _contract];
            _r set ["auraUntil", _now + (PMCS2_settings get "aura")];
        };
        if (_inGang && {(_r get "auraUntil") > _now}) then {_r set ["auraUntil", (_r get "auraUntil") max (_now + 30)]};
        _wants pushBack [_p, _r, [_r, _in, _now, PMCS2_settings] call PMCS_fnc_s2Desired];
    };
} forEach (allPlayers select {!(_x isKindOf "HeadlessClient_F")});
// A vehicle has one side, its commander's. Player groups sharing a vehicle all
// take the most hostile colour aboard (GUER over WEST/EAST over CIV; a WEST/EAST
// tie goes to the commander's group), so nobody aboard is a hidden target.
private _rank = createHashMapFromArray [["civ", 0], ["west", 1], ["east", 1], ["guer", 2]];
private _byVehicle = createHashMap;
{
    private _vehicle = objectParent (_x select 0);
    if (!isNull _vehicle) then {
        private _key = netId _vehicle;
        private _list = _byVehicle getOrDefault [_key, []];
        _list pushBack _forEachIndex; _byVehicle set [_key, _list];
    };
} forEach _wants;
{
    if (count _y > 1) then {
        private _best = _y select 0;
        private _commander = effectiveCommander (objectParent ((_wants select _best) select 0));
        {
            private _color = ((_wants select _x) select 2) select 0;
            private _bestColor = ((_wants select _best) select 2) select 0;
            if ((_rank get _color) > (_rank get _bestColor) || {
                (_rank get _color) == (_rank get _bestColor) && {(group ((_wants select _x) select 0)) == group _commander}
            }) then {_best = _x};
        } forEach _y;
        private _shared = ((_wants select _best) select 2) select 0;
        {
            private _w = (_wants select _x) select 2;
            if ((_w select 0) != _shared) then {(_wants select _x) set [2, [_shared, false, "vehicle"]]};
        } forEach _y;
    };
} forEach _byVehicle;
{_x call PMCS_fnc_s2Apply} forEach _wants;
