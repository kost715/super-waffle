// [string key, arguments] -> nothing. Client: a message about a lock.
params [["_key", "", [""]], ["_args", [], [[]]]];
if (!hasInterface) exitWith {};
hint format ([localize _key] + _args);
