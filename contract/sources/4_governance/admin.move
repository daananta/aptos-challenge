module my_addr::admin {
    use std::signer;
    //Ghi chú, tương lai cần nâng cấp thêm chống ảnh vi phạm, ví dụ dùng server trung gian xử lý ảnh trước khi up lên ipfs, dùng AI, dùng chữ ký của server đảm bảo rằng bài nộp đi qua frontend

    use aptos_framework::object::{Self, Object};
    use aptos_framework::fungible_asset::{Self, FungibleStore};

    // --- Errors ---
    const E_NOT_AUTHORIZED: u64 = 1;
    // --- Platform Treasury ---
    struct PlatformConfig has key {
        //Địa chỉ nhận tiền phí
        treasury_addr: address,

        //Cấu hình phí 
        creation_fee: u64,  //Phí tạo 
        platform_fee_bps: u64, //Phí % (250 = 2,5%)
        min_reward_amount: u64, 
        dispute_fee: u64 //phí khiếu nại
    }

    fun init_module(admin: &signer) {
        move_to(admin, PlatformConfig {
            treasury_addr: signer::address_of(admin),
            creation_fee: 100_000_000, //(100 Ananta)
            platform_fee_bps: 250,
            min_reward_amount: 1_000_000, //1 Ananta
            dispute_fee: 1_000_000 
        });
    }

    // --- SETTERS (Chỉ Admin gọi được) ---
    public entry fun set_fees(
        admin: &signer,
        new_creation_fee: u64,
        new_bps: u64,
    ) acquires PlatformConfig {
        //Đảm bảo người gọi sở hữu PlatformConfig
        let admin_addr = signer::address_of(admin);
        assert!(exists<PlatformConfig>(admin_addr), 999);

        let config = borrow_global_mut<PlatformConfig>(admin_addr);

        config.creation_fee = new_creation_fee;
        config.platform_fee_bps = new_bps;
    }

    //--- GETTERS (Quan trọng: Để module khác đọc dữ liệu) ---
    //Lấy địa chỉ kho bạc
    #[view] 
    public fun get_treasury_addr(): address acquires PlatformConfig {
        borrow_global<PlatformConfig>(@my_addr).treasury_addr
    }

    //Lấy phí tạo 
    #[view]
    public fun get_creation_fee(): u64 acquires PlatformConfig {
        borrow_global<PlatformConfig>(@my_addr).creation_fee
    }

    //Lấy phí % 
    #[view]
    public fun get_platform_fee_bps(): u64 acquires PlatformConfig {
        borrow_global<PlatformConfig>(@my_addr).platform_fee_bps
    }

    //Lấy phí khiếu nại
    #[view]
    public fun get_dispute_fee(): u64 acquires PlatformConfig {
        borrow_global<PlatformConfig>(@my_addr).dispute_fee
    }
}