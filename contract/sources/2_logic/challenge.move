//Module này dùng để quản lý thử thách 
module my_addr::challenge {
    use std::signer;
    use std::string::String;
    use std::option::{Self, Option};
    use std::error;
    use std::vector;
    use std::bcs;

    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_std::simple_map::{Self, SimpleMap};
     
    use aptos_framework::object::{Self, Object, ExtendRef};
    use aptos_framework::fungible_asset::{Self, Metadata, FungibleStore};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::aggregator_v2::{Self, Aggregator};
    use aptos_framework::event;
    use aptos_framework::timestamp;

    use my_addr::game_types::{Self, ChallengeStatus, ChallengeCategory, SubmissionStatus, ScoringMode, RewardDistribution, Phase};
    use my_addr::userprofile;
    //Pinata, irys, arweave, nft.storage 

    const MAX_JUDGES: u64 = 10;
    const MAX_CANDIDATES: u64 = 1000;
    const MAX_WINNERS: u64 = 20;

    const PLATFORM_FEE_BPS: u64 = 250; // 2.5%
    const MIN_REWARD: u64 = 1000000; // 1 ANANTA (assuming 6 decimals)

    // --- Errors ---
    ///Không có quyền 
    #[error]
    const E_NOT_AUTHORIZED: u64 = 1;  
    ///Trạng thái hiện tại không hợp lệ 
    #[error]
    const E_INVALID_STATE: u64 = 2;
    ///Đã quá thời hạn cho phép 
    #[error]
    const E_DEADLINE_PASSED: u64 = 3;
    ///Không đủ tiền/tài nguyên để thực hiện, số dư không đáp ứng yêu cầu 
    #[error]
    const E_INSUFFICIENT_FUND: u64 = 4;
    #[error]
    const E_CHALLENGE_NOT_FOUND: u64 = 5;
    #[error]
    const E_ALREADY_SUBMITTED: u64 = 6;
    #[error]
    const E_TOO_MANY_WINNERS: u64 = 7;
    #[error]
    const E_INVALID_REWARD: u64 = 8;
    ///Title quá dài
    #[error]
    const E_TITLE_TOO_LONG: u64 = 9;
    ///Metadata_uri quá dài
    #[error]
    const E_METADATA_URI_TOO_LONG: u64 = 10;
    /// Tổng phần trăm (100%)
    #[error]
    const TOTAL_PERCENT: u64 = 100;

    //Chỉ hiển thị thứ frontend cần nhất
    #[event] 
    struct ChallengeCreatedEvent has drop, store {
        challenge_id: u64,
        creator: address,
        title: String,
        reward_amount: u64,
        category: ChallengeCategory,
        end_at: u64,
        metadata_uri: String,
    }

    struct ChallengeRegistry has key {
        next_challenge_id: Aggregator<u64>,
        challenges: SmartTable<u64, address>,  // id -> object_address
        allowed_assets: vector<address>,
    }

    // Struct nhỏ để lưu tạm trong Leaderboard
    struct Candidate has store, drop, copy {
        addr: address,
        votes: u64,
    }
    //--- Struct Resource(Lưu trong object) ---
    struct Challenge has key {
        challenge_id: u64,

        status: ChallengeStatus,
        flags: u64,

        // Economy, chỉ lưu handle, rất nhẹ
        initial_reward: u64,
        reward_asset_store: Object<FungibleStore>,
        asset: Object<Metadata>,

        // Counters (Dùng Aggregator để update song song)
        total_sponsored: Aggregator<u64>, 
        sponsor_count: Aggregator<u64>,

        // Submissions
        submissions: SmartTable<address, bool>, //Submission là resource thường lưu vào account user
        submission_count: Aggregator<u64>,

        // Người thắng cuộc (Ban đầu là Option::none())
        top_candidates: vector<Candidate>,  // Hỗ trợ nhiều người thắng

        //Thời gian
        phase: Phase,
        create_at: u64,
        start_at: u64,
        submission_deadline: u64,
        voting_deadline: u64, //Hạn chót chấm điểm 

        // Biến động cho Tranh luận (Chỉ set khi Phase == ResultsPublished)
        dispute_start_at: u64,

        // Versioning
        version: u8,

        config_addr: address,

        extend_ref: ExtendRef,
    }

    struct ChallengeConfig has key {
        challenge_id: u64,
        creator: address,

        title: String, //Không cần dùng hash vì ưu tiên tốc độ tải 
        metadata_uri: String, //Lưu trên Pinata
        category: ChallengeCategory,

        //Setting, Rules 
        platform_fee_bps: u64, //Phí nền tảng(2,5%)
        scoring_mode: ScoringMode, //Cơ chế chấm điểm
        max_winners: u64, //Số người thắng tối đa
        distribution: RewardDistribution, //Cách phân phối phần thưởng

        // Dispute Settings
        dispute_duration: u64,
        dispute_fee: u64,

        // Judges (Thường ít thay đổi)
        judges: vector<address>,
        
        // Versioning
        version: u8,
    }

    /// --- Submission Resource ---
    struct Submission has copy, store {
        challenge_id: u64,
        submitter: address,
        proof_uri: String,
        // proof_has: vector<u8> có vẻ không cần hash vì link trên pinata là hash 
        submitted_at: u64,
        status: SubmissionStatus,
        verified_by: Option<address>,
        verified_at: u64,
    }


    fun init_module(admin: &signer) {
        move_to(admin, ChallengeRegistry{
            next_challenge_id: aggregator_v2::create_aggregator(18446744073709551615),
            challenges: smart_table::new(),
            allowed_assets: vector::empty();
        })
    }

    public entry fun create_challenge(
        creator: &signer, //Người tạo
        //Tiêu đề
        title: String, //Tiêu đề 
        metadata_uri: String, //Link nội dung cụ thể
        //luật chơi
        category_val: u8, //Loại thử thách 
        scoring_mode_val: u8, // Frontend gửi u8, loại chấm điểm 
        distribution_val: u8, //cách chia thưởng
        max_winners: u64, //Số người thắng tối đa
        distribution_params: vector<u64>, //theo %
        //Thời gian
        start_delay: u64,         // 0 nếu muốn bắt đầu luôn. >0 nếu muốn lên lịch (Upcoming)
        submission_duration: u64, // Thời gian cho nộp bài (VD: 7 ngày)
        voting_duration: u64,     // Thời gian cho chấm điểm (VD: 3 ngày)
        dispute_duration: u64,    // Thời gian cho khiếu nại (VD: 1 ngày)
        initial_reward: u64, // số tiền thưởng ban đầu
        //Giám khảo 
        additional_judges: vector<address> //mặc định giám khảo là creator, thêm ai thì điền vào
    ) acquires ChallengeRegistry {
        let creator_addr = signer::address_of(creator);

        //Assert 
        assert!(title.length() <= 64, E_TITLE_TOO_LONG);
        assert!(metadata_uri.length() <= 256, E_METADATA_URI_TOO_LONG);
        assert!(distribution_params.length() == max_winners, 999);
        assert!(max_winners <= 20, 999);
        validate_distribution_params(distribution_val, distribution_params);

        let category = game_types::u8_to_category(category_val);
        let scoring_mode = game_types::u8_to_scoring(scoring_mode_val);
        let distribution = game_types::u8_to_distribution(distribution_val);


        let challenge_registry = borrow_global_mut<ChallengeRegistry>(@my_addr);

        let next_challenge_id = aggregator_v2::read(&challenge_registry.next_challenge_id);
        let asset_address = challenge_registry.allowed_assets.borrow()

        let challenge_object = object::create_named_object(, bcs::to_bytes(&next_challenge_id));
        let challenge_object_signer = object::generate_signer(&challenge_object);
        move_to(&challenge_object_signer, Challenge {
            challenge_id: next_challenge_id,
            status: ChallengeStatus::Upcoming,
            flags: 0,
            initial_reward,
            reward_asset_store: 
        })
    }

    public entry fun add_whitelist_asset(
        admin: &signer,
        asset: address,
    ) acquires ChallengeRegistry {
        assert!(@my_addr == signer::address_of(admin), 999);
        let challenge_registry = borrow_global_mut<ChallengeRegistry>(@my_addr);
        challenge_registry.allowed_assets.
    }

    fun validate_distribution_params(
        distribution_val: u8,
        distribution_params: vector<u64>,
    ) {
        // 1. Kiểm tra Type = RankedPercentage (1)
        if (distribution_val == 1) {
            let sum: u64 = 0;
            let i = 0;
            let len = distribution_params.length();

            // Bắt buộc phải có ít nhất 1 phần trăm
            assert!(len > 0, error::invalid_argument(999));

            while (i < len) {
                let val = *vector::borrow(&distribution_params, i);
                
                // Validate từng phần tử
                assert!(val > 0 && val <= 100, error::invalid_argument(999));
                
                sum = sum + val;
                i = i + 1;
            };

            // Validate tổng
            assert!(sum == 100, error::invalid_argument(999));
        };
    }
}