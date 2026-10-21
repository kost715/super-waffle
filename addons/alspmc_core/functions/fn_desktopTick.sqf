disableSerialization;
// Actions belong to the world computer, not the player. Each client attaches
// one action per streamed/JIP object; native ownership is checked again later.
{
    private _computer = _x select 1;
    if (!isNull _computer && {!(_computer getVariable ["ALSPMC_actionAdded", false])}) then {
        _computer setVariable ["ALSPMC_actionAdded", true];
        _computer addAction [
            localize "STR_ALSPMC_computer_action",
            {params ["_target"]; [_target] call ALSPMC_fnc_desktopOpen},
            nil, 2, true, true, "", "[_this, _target] call ALSPMC_fnc_terminalCanUse", 3.5
        ];
    };
} forEach (missionNamespace getVariable ["ALSPMC_terminalsPublic", []]);
private _disp = uiNamespace getVariable ["ALSPMC_desktopDisp", displayNull];
if (isNull _disp) exitWith {};
private _computer = _disp getVariable ["ALSPMC_computer", objNull];
if !([player, _computer] call ALSPMC_fnc_terminalCanUse) exitWith {_disp closeDisplay 2};
if !(_disp getVariable ["ALSPMC_ready", false]) exitWith {};
private _web = _disp displayCtrl 7410;
if !(_disp getVariable ["ALSPMC_installed", false]) then {
    _web ctrlWebBrowserAction ["ExecJS", ALSPMC_phoneCode + ";ALSPMCDesktop.start();"];
    _disp setVariable ["ALSPMC_installed", true];
    _disp setVariable ["ALSPMC_lastPoll", -10];
};
private _state = +(player getVariable ["ALSPMC_desktopState", createHashMap]);
if (count _state > 0 && {(_state getOrDefault ["terminalKey", ""]) == (_computer getVariable ["ALSPMC_terminalKey", ""])}) then {
    if !(_state getOrDefault ["valid", false]) exitWith {_disp closeDisplay 2};
    (player getVariable ["ALS_money", [0, 0]]) params ["_cash", "_bank"];
    _state set ["cash", _cash];
    _state set ["bank", _bank];
    private _json = toJSON _state;
    if (_json != (_disp getVariable ["ALSPMC_lastState", ""])) then {
        _web ctrlWebBrowserAction ["ExecJS", format ["ALSPMCPhone.set(%1)", _json]];
        _disp setVariable ["ALSPMC_lastState", _json];
    };
};
if (diag_tickTime - (_disp getVariable ["ALSPMC_lastPoll", -10]) >= 1) then {
    _disp setVariable ["ALSPMC_lastPoll", diag_tickTime];
    [player, "status", "", 0, _computer] remoteExecCall ["ALSPMC_fnc_desktopDo", 2];
};
