// [laptop] -> nothing. Client. Opens the laptop (desktop first; the browser asks the
// server for the market when it opens).
params [["_terminal", objNull, [objNull]]];
if (isNull _terminal || {!isNil "PMCS_ui"} || {dialog}) exitWith {};
PMCS_ui = createHashMapFromArray [
    ["terminal", _terminal], ["mode", _terminal getVariable ["PMCS_mode", "shop"]], ["view", "desk"], ["tab", "weapons"],
    ["offTypes", []], ["offCals", []], ["search", ""], ["sort", 0], ["sel", ""], ["variant", ""], ["qty", 1], ["pack", "box"], ["ammoType", ""], ["mag", ""], ["magQty", 1], ["magPack", "box"],
    ["cart", []], ["cartRow", 0], ["account", "personal"], ["cartOpen", false],
    ["apage", "items"], ["asection", "weapon"], ["ashow", 0], ["asearch", ""], ["acal", ""], ["asel", ""], ["acat", ""], ["aadd", false], ["aresetAt", -100]
];
createDialog "PMCS_RscLaptop";
