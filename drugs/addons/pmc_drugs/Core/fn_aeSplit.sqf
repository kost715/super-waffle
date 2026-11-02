// [work W] -> [oxygen, AE1 power, AE2 power, AN power]: how ACE Advanced Fatigue's main
// loop splits the work between its pathways now (each pathway's power fatigued by its
// reserve, oxygen and muscle damage; what they cannot cover is anaerobic).
params ["_work"];
private _oxygen = [] call PMCD_fnc_oxygen;
private _muscleFactor = sqrt (1 - (missionNamespace getVariable ["ace_advanced_fatigue_muscleDamage", 0]));
private _ae1 = _work min ((missionNamespace getVariable ["ace_advanced_fatigue_ae1PathwayPower", 0])
    * sqrt ((missionNamespace getVariable ["ace_advanced_fatigue_ae1Reserve", 4000000]) / 4000000) * _oxygen * _muscleFactor);
private _ae2 = (_work - _ae1) min ((missionNamespace getVariable ["ace_advanced_fatigue_ae2PathwayPower", 0])
    * sqrt ((missionNamespace getVariable ["ace_advanced_fatigue_ae2Reserve", 84000]) / 84000) * _oxygen * _muscleFactor);
[_oxygen, _ae1, _ae2, 0 max (_work - _ae1 - _ae2)]
