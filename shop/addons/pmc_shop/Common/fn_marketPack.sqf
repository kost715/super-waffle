// [market, with journal] -> the market as plain arrays (network, profile):
// [1, items, custom, categories, global discount, box discount, journal].
params ["_market", ["_withLog", false]];
[1, (_market get "items") toArray false, (_market get "custom") toArray false, (_market get "cats") toArray false,
    _market get "global", _market get "box", [[], +(_market get "log")] select _withLog]
