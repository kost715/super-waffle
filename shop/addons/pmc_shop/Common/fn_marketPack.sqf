// [market, with journal] -> the market as plain arrays (network, profile):
// [2, items, custom, category discounts, market discount, journal].
params ["_market", ["_withLog", false]];
[2, (_market get "items") toArray false, (_market get "custom") toArray false, (_market get "cats") toArray false,
    _market get "global", [[], +(_market get "log")] select _withLog]
