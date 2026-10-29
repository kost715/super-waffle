// [vehicle, hit point] -> which kind of part a component repair is on, for the window
// title: "engine", "fuel", "turret", "gun", "hull" or "other". Pure apart from reading the
// vehicle's hit point names.
params ["_vehicle", "_hitPoint"];
private _name = if (_hitPoint isEqualType 0) then {((getAllHitPointsDamage _vehicle) param [0, []]) param [_hitPoint, ""]} else {_hitPoint};
_name = toLower _name;
private _part = "other";
{if ((_name find (_x select 0)) >= 0) exitWith {_part = _x select 1}} forEach [["engine", "engine"], ["fuel", "fuel"], ["turret", "turret"], ["gun", "gun"],
    ["hull", "hull"], ["body", "hull"]];
_part
