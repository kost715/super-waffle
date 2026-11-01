// [muscle damage 0-1] -> the colour of the muscle icon [r, g, b, a], [] when hidden. Pure.
// A smooth gradient: hidden under 0.1; pale yellow to orange up to 0.3, orange to red up
// to 0.5, red to dark red up to 0.85; black from 0.85 on.
params ["_damage"];
if (_damage < 0.1) exitWith {[]};
if (_damage >= 0.85) exitWith {[0, 0, 0, 1]};
private _stops = [[0.1, [1, 0.95, 0.6]], [0.3, [1, 0.55, 0.1]], [0.5, [0.9, 0.1, 0.08]], [0.85, [0.35, 0.02, 0.02]]];
private _i = (_stops findIf {(_x select 0) > _damage}) max 1;
(_stops select (_i - 1)) params ["_from", "_low"];
(_stops select _i) params ["_to", "_high"];
private _u = (_damage - _from) / (_to - _from);
([0, 1, 2] apply {(_low select _x) + _u * ((_high select _x) - (_low select _x))}) + [1]
