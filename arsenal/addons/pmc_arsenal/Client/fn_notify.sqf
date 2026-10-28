// Server -> client: localized arsenal message, optionally formatted.
params [["_key", "", [""]], ["_args", [], [[]]]];
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}} || {_key == ""}) exitWith {};
private _text = format ([localize _key] + _args);
hint _text;
systemChat _text;
