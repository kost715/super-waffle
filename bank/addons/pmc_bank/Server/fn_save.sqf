// Writes balances, treasurers and the journal to the server profile.
if (!isServer || {isNil "PMCB_accounts"} || {PMCB_saveBlocked}) exitWith {false};
profileNamespace setVariable ["PMCB_bank_v1", [1, PMCB_group, (keys PMCB_accounts) apply {[_x] + (PMCB_accounts get _x)},
    PMCB_treasurers toArray false, PMCB_log, PMCB_seq]];
saveProfileNamespace;
PMCB_dirty = false;
true
