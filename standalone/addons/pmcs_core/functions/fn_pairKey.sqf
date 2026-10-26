params [["_a", "", [""]], ["_b", "", [""]]];
if (_a == _b || {_a == ""} || {_b == ""}) exitWith {""};
private _pair = [_a, _b]; _pair sort true;
(_pair select 0) + "|" + (_pair select 1)
