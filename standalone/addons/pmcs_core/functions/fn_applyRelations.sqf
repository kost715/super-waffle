if (!isServer) exitWith {};
private _combat = [west, east, resistance];
private _used = PMCS_plan apply {_x select 2};
// With three companies no independent combat side remains. Do not silently
// attach hostile world forces to a player company or turn civilians hostile.
PMCS_worldSide = sideUnknown;
{if !(_x in _used) exitWith {PMCS_worldSide = _x}} forEach _combat;
{
    private _from = _x;
    {
        private _to = _x;
        private _friend = 1;
        if (_from != _to && {_from != civilian} && {_to != civilian}) then {
            private _a = (PMCS_plan select {(_x select 2) == _from}) param [0, []];
            private _b = (PMCS_plan select {(_x select 2) == _to}) param [0, []];
            if (_a isNotEqualTo [] && {_b isNotEqualTo []}) then {
                if ((PMCS_relations getOrDefault [[_a select 0, _b select 0] call PMCS_fnc_pairKey, "neutral"]) == "hostile") then {_friend = 0};
            } else {
                if (PMCS_worldHostile && {(_from == PMCS_worldSide && {_to in _used}) || {_to == PMCS_worldSide && {_from in _used}}}) then {_friend = 0};
            };
        };
        _from setFriend [_to, _friend];
    } forEach (_combat + [civilian]);
} forEach (_combat + [civilian]);
