// [] -> the oxygen factor of ACE Advanced Fatigue's main loop now: ACE Medical's SpO2 / 100
// when Medical simulates it, otherwise 1 - 0.131 x respiratoryRate^2.
if (missionNamespace getVariable ["ace_medical_enabled", false] && {missionNamespace getVariable ["ace_medical_vitals_simulateSpo2", false]}) exitWith {
    (ACE_player getVariable ["ace_medical_spo2", 97]) / 100
};
1 - 0.131 * (missionNamespace getVariable ["ace_advanced_fatigue_respiratoryRate", 0]) ^ 2
