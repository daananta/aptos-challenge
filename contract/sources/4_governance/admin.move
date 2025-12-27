module my_addr::admin {

    use aptos_framework::object::{Self, Object};
    use aptos_framework::fungible_asset::{Self, FungibleStore};
    
    // --- Platform Treasury ---
    struct PlatformConfig has key {
        admin: address,
        treasury_store: Object<FungibleStore>,
        platform_fee_bps: u64,
        min_reward_amount: u64,
    }
}