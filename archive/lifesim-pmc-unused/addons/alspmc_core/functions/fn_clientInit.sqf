if (missionNamespace getVariable ["ALSPMC_clientStarted", false]) exitWith {};
ALSPMC_clientStarted = true;
// Keep the loaded original/RU dispatcher (including any earlier wrapper) as
// the delegate. Its function variable remains untouched.
ALSPMC_nativePhoneMsg = ALS_fnc_phoneMsg;
ALSPMC_companyCode = loadFile "\alspmc_core\ui\company.js";
ALSPMC_phoneCode = loadFile "\alspmc_core\ui\phone.js";
ALSPMC_licenseCode = loadFile "\alspmc_core\ui\licensePhoneOnly.js";
"ALSPMC_basesPublic" addPublicVariableEventHandler {call ALSPMC_fnc_applyValues};
call ALSPMC_fnc_applyValues;
[{call ALSPMC_fnc_clientTick}, 0.25] call CBA_fnc_addPerFrameHandler;
