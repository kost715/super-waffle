// [box, delivery point ID] -> true. Server. Goods bought for that point go into the box
// (the first one still standing when there are several).
params [["_box", objNull, [objNull]], ["_id", "", [""]]];
if (!isServer || {isNull _box} || {_id == ""}) exitWith {false};
call PMCS_fnc_serverLoad;
if !(_id in PMCS_points) then {PMCS_points set [_id, []]};
(PMCS_points get _id) pushBackUnique _box;
_box setVariable ["PMCS_pointId", _id, true];
true
