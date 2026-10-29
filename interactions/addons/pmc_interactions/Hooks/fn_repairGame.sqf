// [vehicle, hit point, game from the hook table] -> the game to play. A component repair
// ("repair") is a weld on the hull or body and a diagnosis on anything else; other games
// stay as they are.
params ["_vehicle", "_hitPoint", "_game"];
if (_game != "repair") exitWith {_game};
private _name = if (_hitPoint isEqualType 0) then {((getAllHitPointsDamage _vehicle) param [0, []]) param [_hitPoint, ""]} else {_hitPoint};
_name = toLower _name;
["diagnose", "weld"] select ((_name find "hull") >= 0 || {(_name find "body") >= 0})
