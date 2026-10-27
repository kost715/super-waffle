// Once a second on the server: zone membership with hysteresis, aura refresh,
// desired state, apply.
private _now = diag_tickTime;
{
    private _p = _x;
    private _uid = getPlayerUID _p;
    if (alive _p && {_uid != ""}) then {
        private _r = PMCS2_records getOrDefault [_uid, createHashMap];
        if (count _r == 0) then {_r = [_p] call PMCS_fnc_s2Register};
        _r set ["unit", _p];
        private _distance = _p distance2D PMCS2_zone;
        private _in = if (_r getOrDefault ["inZone", false]) then {_distance <= PMCS2_zoneOut} else {_distance <= PMCS2_zoneIn};
        _r set ["inZone", _in]; _r set ["distance", round _distance];
        private _contract = _r get "contract";
        // While in the zone on a contract the aura keeps being refreshed, so it
        // runs out "aura" seconds after leaving.
        if (_in && {_contract != "none"}) then {
            _r set ["combat", _contract];
            _r set ["auraUntil", _now + (PMCS2_settings get "aura")];
        };
        [_p, _r, [_r, _in, _now, PMCS2_settings] call PMCS_fnc_s2Desired] call PMCS_fnc_s2Apply;
    };
} forEach (allPlayers select {!(_x isKindOf "HeadlessClient_F")});
