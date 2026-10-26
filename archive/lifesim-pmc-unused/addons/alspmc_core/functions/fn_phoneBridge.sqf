// One JSDialog dispatcher per native phone. Intercept only our namespace;
// every other raw message retains the native
// path, including ready/view and the requests that release busy buttons.
params [["_raw", "", [""]]];
private _message = fromJSON _raw;
if (_message isEqualType createHashMap && {(_message getOrDefault ["a", ""]) == "alspmc"}) exitWith {
    [_message] call ALSPMC_fnc_phoneMsg;
};
_this call ALSPMC_nativePhoneMsg
