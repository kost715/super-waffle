// Owner-only delivery of this player's PMC phone/desktop state. Only the
// owning client reads it; a public variable reached every client each second.
if (!hasInterface) exitWith {};
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
params [["_name", "", [""]], ["_state", createHashMap, [createHashMap]]];
if !(_name in ["ALSPMC_phoneState", "ALSPMC_desktopState"]) exitWith {};
player setVariable [_name, _state];
