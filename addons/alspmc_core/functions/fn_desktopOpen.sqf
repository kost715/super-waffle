params [["_computer", objNull, [objNull]]];
if (!hasInterface || {!([player, _computer] call ALSPMC_fnc_terminalCanUse)}) exitWith {};
disableSerialization;
if (!isNull (uiNamespace getVariable ["ALSPMC_desktopDisp", displayNull])) exitWith {};
private _phone = uiNamespace getVariable ["ALS_phoneDisp", displayNull];
if (!isNull _phone) then {_phone closeDisplay 2};
private _disp = (findDisplay 46) createDisplay "RscDisplayEmpty";
if (isNull _disp) exitWith {};
// A previous session may have ended after a denied request or a sale. Fetch
// fresh authorization instead of closing immediately on that stale response.
player setVariable ["ALSPMC_desktopState", createHashMap];
uiNamespace setVariable ["ALSPMC_desktopDisp", _disp];
_disp setVariable ["ALSPMC_computer", _computer];
_disp setVariable ["ALSPMC_ready", false];
_disp setVariable ["ALSPMC_installed", false];
private _web = _disp ctrlCreate ["ALS_RscPhoneWeb", 7410];
_web ctrlSetPosition [safeZoneX + safeZoneW * 0.04, safeZoneY + safeZoneH * 0.06, safeZoneW * 0.92, safeZoneH * 0.88];
_web ctrlCommit 0;
_web ctrlAddEventHandler ["JSDialog", {
    params ["_ctrl", "", "_raw"];
    private _msg = fromJSON _raw;
    if !(_msg isEqualType createHashMap) exitWith {true};
    private _disp = ctrlParent _ctrl;
    switch (_msg getOrDefault ["a", ""]) do {
        case "alspmcDesktop": {
            switch (_msg getOrDefault ["op", ""]) do {
                case "ready": {_disp setVariable ["ALSPMC_ready", true]};
                case "close": {_disp closeDisplay 2};
            };
        };
        case "alspmc": {[_msg, _disp getVariable ["ALSPMC_computer", objNull]] call ALSPMC_fnc_phoneMsg};
    };
    true
}];
_disp displayAddEventHandler ["Unload", {
    uiNamespace setVariable ["ALSPMC_desktopDisp", displayNull];
    if (missionNamespace getVariable ["ALSPMC_desktopCamera", false]) then {
        if (!isNil "ALS_propCam") then {[""] call ALS_fnc_propView};
        ALSPMC_desktopCamera = false;
    };
}];
_web ctrlWebBrowserAction ["LoadFile", "\alspmc_core\ui\desktop.html"];
