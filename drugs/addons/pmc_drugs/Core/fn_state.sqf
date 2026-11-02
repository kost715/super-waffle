// [unit] -> the unit's drug state: a hashmap kept on the unit, on its own machine, never
// sent over the network or saved. A new body starts clean (nothing carries over a respawn);
// a Zeus re-assigns muscle damage with the module if the story needs it.
//   stimDoses   Stim1f doses taken by this body (each is numbered: PMCD_Stim1f_<n>)
//   doses       the Stim1f doses still acting: [[action pool left (equivalent seconds),
//               name of its pulse effect in ACE Medical, muscle damage it has added], ...];
//               each drains by wc per second (PMCD_fnc_step) and ends on its own
//   fenTaken    Fentropil doses taken by this body
//   fenDoses    mission times of the Fentropil doses still in the body (PMCD_fnc_fenLevel)
//   meldTaken   meldonium doses taken by this body
//   meld        [metabolite amount, at mission time, effect end time] (PMCD_fnc_meldLevel)
//   stimDebts   one debt pool per Stim1f dose: [[dose name, mmol, its dose ended], ...],
//               paid back from the AE2 reserve in order, each once its dose has ended
//   debtStim    the Stim1f pools together; debtFen the Fentropil pool (paid after them);
//               debt all of them
//   lastWork    [work now, nominal, savings, debt rate] of the last second (debug panel)
//   lastPay     [pool paid, mmol/s] of the last second (debug panel)
//   fenBase     ACE's own pathway powers [AE1, AE2, AN, AE] while Fentropil boosts them,
//               fenBoost the boost last applied (PMCD_fnc_fenApply); fenAnim: the
//               animation speed is Fentropil's
//   hemoTaken   hemostatic doses taken; hemoEnd when it stops acting; bleedSeen the last
//               [ACE blood loss, cut loss] (PMCD_fnc_hemoBleed)
//   painSeen    ACE Medical pain at the last second (PMCD_fnc_fenPain)
//   regen, meldBack  AE2 support mmol/s and meldonium's [muscle, acidosis] taken back per
//               second, last second (debug panel)
params ["_unit"];
private _state = _unit getVariable "PMCD_state";
if (isNil "_state") then {
    _state = createHashMapFromArray [["stimDoses", 0], ["doses", []], ["fenTaken", 0], ["fenDoses", []], ["meldTaken", 0], ["meld", [0, 0, -1]], ["hemoTaken", 0], ["hemoEnd", -1], ["debt", 0], ["stimDebts", []], ["debtStim", 0], ["debtFen", 0],
        ["lastWork", [0, 0, 0, 0]], ["lastPay", ["", 0]], ["fenBoost", 1], ["fenAnim", false], ["painSeen", 0]];
    _unit setVariable ["PMCD_state", _state];
};
_state
