// [vehicle, hit point, game from the hook table] -> the game to play. A component repair
// ("repair") is a weld on the hull or body; anything else keeps ACE's own bar for now
// ("": the diagnosis game is switched off); other games stay as they are.
params ["_vehicle", "_hitPoint", "_game"];
if (_game != "repair") exitWith {_game};
private _name = if (_hitPoint isEqualType 0) then {((getAllHitPointsDamage _vehicle) param [0, []]) param [_hitPoint, ""]} else {_hitPoint};
_name = toLower _name;
["", "weld"] select ((_name find "hull") >= 0 || {(_name find "body") >= 0})
