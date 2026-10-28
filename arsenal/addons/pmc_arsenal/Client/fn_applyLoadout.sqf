// Server -> client: the arsenal could not cover what was taken; restore the
// loadout recorded when the arsenal opened.
params [["_loadout", [], [[]]]];
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}} || {count _loadout < 10}) exitWith {};
player setUnitLoadout _loadout;
