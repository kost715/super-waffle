// postInit, every machine: a rib broken during CPR becomes, where the patient is local, an
// ACE wound of this mod's damage type "pmci_ribs" (config.cpp): a bruise on the chest that
// hurts but does not bleed.
["PMCI_ribFracture", {
    params ["_patient", "_medic"];
    if (!local _patient || {isNil "ace_medical_fnc_addDamageToUnit"}) exitWith {};
    [_patient, 0.2, "Body", "pmci_ribs", _medic] call ace_medical_fnc_addDamageToUnit;
}] call CBA_fnc_addEventHandler;
