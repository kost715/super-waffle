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
    ["BloodIV", ["iv", "ace_medical_treatment_treatmentTimeIV", "ace_medical_treatment_treatmentTimeTrainedIV", "ace_medical_treatment_fnc_ivBag", ""]],
    ["Splint", ["splint", "ace_medical_treatment_treatmentTimeSplint", "ace_medical_treatment_treatmentTimeTrainedSplint", "ace_medical_treatment_fnc_splint", ""]],
    // ACE stitches during its bar and has no success callback: PMCI_fnc_stitch does the stitching.
    ["SurgicalKit", ["suture", "ace_medical_treatment_fnc_getStitchTime", "", "PMCI_fnc_stitch", ""]],
    ["ReplaceWheel", ["wheel", "ace_repair_wheelChangeTime", "", "ace_repair_fnc_doReplaceWheel", ""]],
    // Removing a wheel is the same game, loosening the nuts only.
    ["RemoveWheel", ["wheel", "ace_repair_wheelChangeTime", "", "ace_repair_fnc_doRemoveWheel", ""]],
    // A component repair is, on the hull, a weld (PMCI_fnc_repairGame); elsewhere ACE's bar.
    ["MiscRepair", ["repair", "ace_repair_miscRepairTime", "", "ace_repair_fnc_doRepair", ""]],
    ["RepairTrack", ["track", "ace_repair_miscRepairTime", "", "ace_repair_fnc_doRepairTrack", ""]],
    ["ReplaceTrack", ["track", "ace_repair_miscRepairTime", "", "ace_repair_fnc_doReplaceTrack", ""]]
];
PMCI_hookTable
