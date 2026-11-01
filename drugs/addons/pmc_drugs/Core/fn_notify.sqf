// [string key] -> nothing. Client: a one-line message to this player.
params ["_key"];
if (!hasInterface) exitWith {};
[localize _key, 1.5] call ace_common_fnc_displayTextStructured;
