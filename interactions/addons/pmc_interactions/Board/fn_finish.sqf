// [success] -> nothing. Client. Ends the board and applies the result the ACE way.
// Success: ACE's own success callback (a bandage, whatever the wound's game, with an
// effectiveness from the play quality). Failure or giving up: the used item comes back, as on ACE's own failure,
// and ACE's failure callback runs (CPR stops). A spare wheel is released either way.
params ["_success"];
if (isNil "PMCI_board") exitWith {};
private _board = PMCI_board;
PMCI_board = nil;
[_board get "handler"] call CBA_fnc_removePerFrameHandler;
private _display = uiNamespace getVariable ["PMCI_display", displayNull];
uiNamespace setVariable ["PMCI_display", displayNull];
if (!isNull _display) then {closeDialog 1};
private _args = +(_board get "args");
private _game = _board get "game";
private _quality = (_board get "state") get "quality";
private _root = [configFile >> "ACE_Repair" >> "Actions", configFile >> "ace_medical_treatment_actions"] select ((_board get "kind") == "medical");
(([_args select 3, _root] call PMCI_fnc_hookOf) param [1, []]) params ["", "", "", ["_successFn", ""], ["_failureFn", ""]];
if ((_board get "kind") == "medical") then {
    _args params ["", "", "", "", "_itemUser", "_usedItem"];
    if (_success) then {
        if ((_board getOrDefault ["action", _game]) == "bandage") then {
            private _effect = missionNamespace getVariable ["PMCI_bandageEffect", 0.4];
            _args set [7, 0.1 max (((1 - _effect) + _effect * 1.5 * _quality) min 1.5)];
        };
        [_successFn, _args] call PMCI_fnc_original;
    } else {
        if (!isNull _itemUser && {_usedItem != ""}) then {
            if (isClass (configFile >> "CfgMagazines" >> _usedItem)) then {
                [_itemUser, _usedItem, 1] call ace_common_fnc_adjustMagazineAmmo;
            } else {
                [_itemUser, _usedItem] call ace_common_fnc_addToInventory;
            };
        };
        [_failureFn, _args] call PMCI_fnc_original;
    };
} else {
    if (_success) then {[_successFn, _args] call PMCI_fnc_original};
    {[objNull, _x, false] call ace_common_fnc_claim} forEach (_args param [6, []]);
};
private _key = ["STR_PMCI_RESULT_FAIL", "STR_PMCI_RESULT_OK"] select _success;
private _text = format [localize _key, localize ("STR_PMCI_GAME_" + _game), round (_quality * 100)];
hint _text;
PMCI_lastResult = [_game, _success, _quality];
// Bring back ACE's medical menu if the treatment was started from it (PMCI_fnc_boardOpen).
if (_board getOrDefault ["reopenMenu", false] && {missionNamespace getVariable ["ace_medical_gui_openAfterTreatment", false]}
    && {!isNil "ace_medical_gui_fnc_openMenu"}) then {
    [ace_medical_gui_fnc_openMenu, _args select 1] call CBA_fnc_execNextFrame;
};
