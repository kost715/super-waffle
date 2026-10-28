// [token, [[class, count], ...]] -> nothing. Server -> client for a deposit: hands
// the banknotes over, then tells the server, which credits what it sees removed.
params [["_token", -1, [0]], ["_rows", [], [[]]]];
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};
{
    _x params ["_class", "_count"];
    private _magazine = isClass (configFile >> "CfgMagazines" >> _class);
    for "_i" from 1 to _count do {
        if (_magazine) then {player removeMagazine _class} else {player removeItem _class};
    };
} forEach _rows;
[_token] remoteExecCall ["PMCB_fnc_depositSettle", 2];
