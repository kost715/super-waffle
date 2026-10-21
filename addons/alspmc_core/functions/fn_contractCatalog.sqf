// key, category, scenario, minimum rating, base reward, XP per success.
// Prices are captured on acceptance; the client cannot submit a reward/level.
private _catalog = [
    ["gov_bandits", "government", "bandits", 1, 4000, 10],
    ["gov_convoy", "government", "convoy", 1, 5000, 15],
    ["gov_guard", "government", "guard", 1, 4500, 10],
    ["gov_base", "government", "base", 4, 18000, 25],
    ["gov_patrol", "government", "enemyPatrol", 3, 10000, 15],
    ["gov_sector", "government", "sector", 1, 3500, 10],
    ["gov_mines", "government", "mines", 1, 3000, 10],
    ["private_convoy", "private", "convoy", 1, 4500, 15],
    ["private_guard", "private", "guard", 1, 4000, 10],
    ["private_vip", "private", "vip", 1, 6000, 15]
];
{
    // Defaults above match config.cpp; a missing class/value keeps the default
    // instead of silently paying 0.
    private _config = configFile >> "ALSPMC_ContractRewards" >> (_x select 0);
    if (isNumber (_config >> "reward")) then {_x set [4, (round getNumber (_config >> "reward")) max 0 min 250000]};
    if (isNumber (_config >> "xp")) then {_x set [5, (round getNumber (_config >> "xp")) max 0 min 10000]};
} forEach _catalog;
_catalog
