// [wound type] -> the bandaging game for it. Gunshot, puncture and anything else: packing
// ("bandage"); avulsion and crush: direct pressure; cut and laceration: closing the edges;
// abrasion: cleaning. A game switched off in the settings falls back to packing.
params ["_type"];
private _game = "bandage";
if (_type in ["Avulsion", "Crush"]) then {_game = "pressure"};
if (_type in ["Cut", "Laceration"]) then {_game = "edges"};
if (_type == "Abrasion") then {_game = "clean"};
if (_game != "bandage" && {!(missionNamespace getVariable ["PMCI_enable_" + _game, true])}) then {_game = "bandage"};
_game
