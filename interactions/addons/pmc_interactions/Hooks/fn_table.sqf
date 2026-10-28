// -> hashmap ACE action class -> [game, original time, original trained time, original
// success, original failure]. The ACE actions this mod takes over, with what ACE itself
// configures for them (ACE 3, medical_treatment and repair). Times and callbacks are
// names of missionNamespace variables: a number or a function.
if (!isNil "PMCI_hookTable") exitWith {PMCI_hookTable};
PMCI_hookTable = createHashMapFromArray [
    ["FieldDressing", ["bandage", "ace_medical_treatment_fnc_getBandageTime", "", "ace_medical_treatment_fnc_bandage", ""]],
    ["PackingBandage", ["bandage", "ace_medical_treatment_fnc_getBandageTime", "", "ace_medical_treatment_fnc_bandage", ""]],
    ["ElasticBandage", ["bandage", "ace_medical_treatment_fnc_getBandageTime", "", "ace_medical_treatment_fnc_bandage", ""]],
    ["QuikClot", ["bandage", "ace_medical_treatment_fnc_getBandageTime", "", "ace_medical_treatment_fnc_bandage", ""]],
    ["ApplyTourniquet", ["tourniquet", "ace_medical_treatment_treatmentTimeTourniquet", "ace_medical_treatment_treatmentTimeTrainedTourniquet",
        "ace_medical_treatment_fnc_tourniquet", ""]],
    ["CPR", ["cpr", "ace_medical_treatment_treatmentTimeCPR", "", "ace_medical_treatment_fnc_cprSuccess", "ace_medical_treatment_fnc_cprFailure"]],
    ["ReplaceWheel", ["wheel", "ace_repair_wheelChangeTime", "", "ace_repair_fnc_doReplaceWheel", ""]]
];
PMCI_hookTable
