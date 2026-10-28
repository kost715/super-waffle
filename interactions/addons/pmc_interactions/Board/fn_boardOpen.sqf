// [game, ACE callback args, "medical"|"repair"] -> nothing. Client. Starts a hands-on
// game in place of the rest of ACE's progress bar. Difficulty comes from the CBA
// setting; a trained medic or engineer gets a 20% easier game.
params ["_game", "_args", "_kind"];
if (!isNil "PMCI_board") then {[false] call PMCI_fnc_finish};
_args params ["_unit", "_target", "_part", "_class"];
private _ease = [1.35, 1, 0.75] select ((missionNamespace getVariable ["PMCI_difficulty", 1]) min 2 max 0);
private _trained = switch (_kind) do {
    case "medical": {!isNil "ace_medical_treatment_fnc_isMedic" && {[_unit, 1] call ace_medical_treatment_fnc_isMedic}};
    default {!isNil "ace_repair_fnc_isEngineer" && {[_unit, 1] call ace_repair_fnc_isEngineer}};
};
if (_trained) then {_ease = _ease * 1.2};
private _state = switch (_game) do {
    case "cpr": {["init", nil, [missionNamespace getVariable ["PMCI_cprDuration", 15], 0.05 * _ease, missionNamespace getVariable ["PMCI_cprMinQuality", 0.5]]] call PMCI_fnc_cprModel};
    case "tourniquet": {
        private _half = 0.09 * _ease;
        ["init", nil, [0.71 - _half, 0.71 + _half, 0.32, missionNamespace getVariable ["PMCI_tourniquetLimit", 25], [1, 2] select (_ease > 1)]] call PMCI_fnc_tourniquetModel
    };
    case "bandage": {
        private _width = 0.22 * _ease * (switch (_class) do {case "QuikClot": {1.3}; case "ElasticBandage": {1.1}; case "PackingBandage": {0.85}; default {1}});
        ["init", nil, [_width min 0.6, missionNamespace getVariable ["PMCI_bandageLimit", 30], 6, 0.25]] call PMCI_fnc_bandageModel
    };
    case "wheel": {["init", nil, [missionNamespace getVariable ["PMCI_nutTime", 0.8], missionNamespace getVariable ["PMCI_swapTime", 3]]] call PMCI_fnc_wheelModel};
};
PMCI_board = createHashMapFromArray [["game", _game], ["args", _args], ["kind", _kind], ["state", _state], ["ease", _ease],
    ["last", diag_tickTime], ["depth", 0], ["handler", -1]];
createDialog "PMCI_RscBoard";
PMCI_board set ["handler", [{call PMCI_fnc_boardTick}, 0] call CBA_fnc_addPerFrameHandler];
