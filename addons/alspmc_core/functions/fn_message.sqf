if (!hasInterface) exitWith {};
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
params [["_id", "", [""]], ["_args", [], [[]]]];
if ((_id select [0, 11]) != "STR_ALSPMC_") exitWith {};
private _text = format ([localize _id] + _args);
systemChat _text;
disableSerialization;
private _desktop = uiNamespace getVariable ["ALSPMC_desktopDisp", displayNull];
if (!isNull _desktop && {_desktop getVariable ["ALSPMC_installed", false]}) exitWith {
    (_desktop displayCtrl 7410) ctrlWebBrowserAction ["ExecJS", format ["ALSPMCPhone.notice(%1)", str toArray _text]];
};
if (!isNil "ALS_phone" && {!isNull (uiNamespace getVariable ["ALS_phoneDisp", displayNull])} && {
    (uiNamespace getVariable ["ALS_phoneDisp", displayNull]) getVariable ["ALSPMC_installed", false]
}) exitWith {
    (ALS_phone get "web") ctrlWebBrowserAction ["ExecJS", format ["ALSPMCPhone.notice(%1)", str toArray _text]];
};
hint _text;
