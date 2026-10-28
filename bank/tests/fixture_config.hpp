// Minimal classes for the SQF-VM bank checks: banknotes as items and as a
// magazine, an ATM prop, a man and a logic (TEST_kinds stands in for isKindOf).
class CfgWeapons {
    class ItemCore {type = 131072;};
    class Money_100: ItemCore {displayName = "100 note";};
    class Money_50: ItemCore {displayName = "50 note";};
    class Money_20: ItemCore {displayName = "20 note";};
    class FirstAidKit: ItemCore {displayName = "First Aid Kit";};
    // ARPI banknote names (the default setting).
    class ar_money_5dollar: ItemCore {};
    class ar_money_25dollar: ItemCore {};
    class ar_money_50dollar: ItemCore {};
    class ar_money_100dollar: ItemCore {};
    class ar_money_200dollar: ItemCore {};
    class ar_money_500dollar: ItemCore {};
    class ar_money_1000dollar: ItemCore {};
};
class CfgMagazines {
    class CA_Magazine {count = 1;};
    class Money_Coins: CA_Magazine {displayName = "Coins";};
};
class CfgVehicles {
    class All {};
    class CAManBase: All {TEST_kinds[] = {"CAManBase", "All"};};
    class B_Soldier_F: CAManBase {};
    class Logic: All {TEST_kinds[] = {"Logic", "All"};};
    class Land_Atm_01_F: All {};
    class GroundWeaponHolder: All {};
};
