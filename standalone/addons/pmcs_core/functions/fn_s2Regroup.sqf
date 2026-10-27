// Runs on the machine that owns the group (the player's): after a move into a
// new side's group, restore the old group's formation, combat mode and
// behaviour, and send the bots back to their leader (their orders were reset).
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
params [["_g", grpNull, [grpNull]], ["_formation", "WEDGE", [""]], ["_combat", "YELLOW", [""]], ["_behaviour", "AWARE", [""]]];
[_g, _formation, _combat, _behaviour] spawn {
    params ["_g", "_formation", "_combat", "_behaviour"];
    private _until = diag_tickTime + 5;
    waitUntil {sleep 0.1; isNull _g || {local _g} || {diag_tickTime > _until}};
    if (isNull _g || {!local _g}) exitWith {};
    _g setFormation _formation;
    _g setCombatMode _combat;
    _g setBehaviour _behaviour;
    private _leader = leader _g;
    {if (local _x && {_x != _leader}) then {_x doFollow _leader}} forEach units _g;
};
