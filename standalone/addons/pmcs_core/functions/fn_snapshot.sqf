params ["_unit", ["_reply", ""], ["_ok", true], ["_notice", ""]];
private _member = [_unit] call PMCS_fnc_registerPlayer;
private _rows = [];
// Explicit indices avoid dependence on nested forEach's private index scope.
for "_i" from 0 to ((count PMCS_plan) - 1) do {
    for "_j" from (_i + 1) to ((count PMCS_plan) - 1) do {
        private _a = (PMCS_plan select _i) select 0;
        private _b = (PMCS_plan select _j) select 0;
        private _sideA = (PMCS_plan select _i) select 2;
        private _sideB = (PMCS_plan select _j) select 2;
        _rows pushBack [_a, _b, PMCS_relations getOrDefault [[_a, _b] call PMCS_fnc_pairKey, "neutral"],
            _sideA getFriend _sideB, _sideB getFriend _sideA];
    };
};
createHashMapFromArray [
    ["session", PMCS_session], ["revision", PMCS_revision], ["companies", PMCS_plan apply {[_x select 0, _x select 1]}],
    ["member", _member param [1, ""]], ["assignmentOK", _member isNotEqualTo [] && {side group _unit == (_member select 2)}],
    ["admin", [_unit] call PMCS_fnc_isAdmin], ["relations", _rows],
    ["actors", PMCS_actors apply {[_x getVariable ["PMCS_actorRole", ""], alive _x]}],
    ["worldEnemyAvailable", PMCS_worldSide != sideUnknown],
    ["worldHostile", PMCS_worldHostile],
    ["reply", _reply], ["ok", _ok], ["notice", _notice]
]
