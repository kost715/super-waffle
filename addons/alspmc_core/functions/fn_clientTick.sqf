disableSerialization;
call ALSPMC_fnc_questMarker;
call ALSPMC_fnc_desktopTick;
private _office = uiNamespace getVariable ["ALS_licDisp", displayNull];
if (!isNull _office && {!isNil "ALS_lic"} && {ALS_lic getOrDefault ["ready", false]} && {
    !(_office getVariable ["ALSPMC_phoneOnly", false])
}) then {
    (ALS_lic get "web") ctrlWebBrowserAction ["ExecJS", ALSPMC_licenseCode];
    _office setVariable ["ALSPMC_phoneOnly", true];
    ALS_lic set ["last", ""];
};

private _disp = uiNamespace getVariable ["ALS_phoneDisp", displayNull];
if (isNull _disp || {isNil "ALS_phone"} || {!(ALS_phone getOrDefault ["ready", false])}) exitWith {};
private _web = ALS_phone get "web";
if (isNull _web) exitWith {};
if !(_disp getVariable ["ALSPMC_installed", false]) then {
    // LifeSim 0.10.1 phoneOpen adds its first JSDialog handler immediately
    // after ctrlCreate (ID 0). Replace only that handler with one dispatcher
    // that forwards ALL native messages. Do not stack competing handlers or
    // remove unrelated handlers, and do not overwrite ALS_fnc_phoneMsg.
    _web ctrlRemoveEventHandler ["JSDialog", 0];
    _web ctrlAddEventHandler ["JSDialog", {
        params ["_ctrl", "_isConfirm", "_raw"];
        [_raw] call ALSPMC_fnc_phoneBridge;
        true
    }];
    _web ctrlWebBrowserAction ["ExecJS", ALSPMC_phoneCode];
    _disp setVariable ["ALSPMC_installed", true];
    _disp setVariable ["ALSPMC_lastPoll", -10];
};
private _state = +(player getVariable ["ALSPMC_phoneState", createHashMap]);
if (count _state > 0) then {
    (player getVariable ["ALS_money", [0, 0]]) params ["_cash", "_bank"];
    _state set ["cash", _cash];
    _state set ["bank", _bank];
    private _json = toJSON _state;
    if (_json != (_disp getVariable ["ALSPMC_lastState", ""])) then {
        _web ctrlWebBrowserAction ["ExecJS", format ["window.ALSPMCPhone && ALSPMCPhone.set(%1)", _json]];
        _disp setVariable ["ALSPMC_lastState", _json];
    };
};
if ((ALS_phone getOrDefault ["view", "home"]) == "alspmc" && {
    diag_tickTime - (_disp getVariable ["ALSPMC_lastPoll", -10]) >= 1
}) then {
    _disp setVariable ["ALSPMC_lastPoll", diag_tickTime];
    [player, "status", "", 0] remoteExecCall ["ALSPMC_fnc_phoneDo", 2];
};
