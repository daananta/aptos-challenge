//Module này dùng để quản lý thử thách 
module my_addr::challenge {
    use std::signer;
    use std::string::String;
    use std::option::{Self, Option};

    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_std::simple_map::{Self, SimpleMap};
     
    use aptos_framework::object::{Self, Object, ExtendRef};
    use aptos_framework::fungible_asset::{Self, Metadata, FungibleStore};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::aggregator_v2::{Self, Aggregator};
    use aptos_framework::event;
    use aptos_framework::timestamp;

    use my_addr::game_types::{Self, ChallengeStatus, ChallengeCategory, SubmissionStatus, ScoringMode};
    use my_addr::userprofile;
    //Pinata, irys, arweave, nft.storage 

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
    const E_TOO_MANY_WINNERS: u64 = 7;
    const E_INVALID_REWARD: u64 = 8;


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
        // active_challenges: SmartTable<u64, address>,  // id -> object_address

        // ❌ ĐÃ XÓA: user_challenges (Dùng Event + Indexer)
        // ❌ ĐÃ XÓA: category_index (Dùng Event + Indexer)
    }

    // Struct nhỏ để lưu tạm trong Leaderboard
    struct Candidate has store, drop, copy {
        addr: address,
        votes: u64,
    }
    //--- Struct Resource(Lưu trong object) ---
    struct Challenge has key {
        challenge_id: u64,

        //Danh tính 
        creator: address,

        // Content commitment
        title: String,  //Không cần dùng hash vì ưu tiên tốc độ
        metadata_uri: String,  // ipfs / arweave / https, có lẽ lưu trên ipfs cái link là hash rồi

        // Phân loại để filter (Speedrun, PvP...)
        category: ChallengeCategory,
        
        //State
        status: ChallengeStatus,
        flags: u64,

        // Economy
        reward_amount: u64,
        reward_asset_store: Object<FungibleStore>,
        asset: Object<Metadata>,
        total_sponsored: Aggregator<u64>, //Số tiền donate
        sponsor_count: Aggregator<u64>, //số người donate
        sponsors_map: SmartTable<address, u64>,
        platform_fee_bps: u64,

        // 🔥 QUYẾT ĐỊNH LUẬT CHƠI
        scoring_mode: ScoringMode,

        // Danh sách các địa chỉ có quyền chấm điểm.
        // Mặc định lúc tạo: judges = vector[creator]
        judges: vector<address>,

        // Người thắng cuộc (Ban đầu là Option::none())
        top_candidates: vector<Candidate>,  // Hỗ trợ nhiều người thắng
        max_winners: u64,  // Giới hạn số người thắng
        min_vote_threshold: u64, //Điểm của người thấp nhất
        reward_per_winner: u64,

        // Submissions
        submissions: SmartTable<address, Submission>, //Submission là resource thường lưu vào account user
        submission_count: u64,

        // Timing
        created_at: u64,
        start_at: u64,
        end_at: u64,
        submission_deadline: u64,  // Có thể khác end_at
        dispute_period_end: u64,   // Thời gian tranh chấp

        // Versioning
        version: u8,

        extend_ref: ExtendRef,
    }

    /// --- Submission Resource ---
    struct Submission has copy, store {
        challenge_id: u64,
        submitter: address,
        proof_uri: String,
        // proof_has: vector<u8> có vẻ không cần hash vì link trên ipfs là hash 
        submitted_at: u64,
        status: SubmissionStatus,
        verified_by: Option<address>,
        verified_at: u64,
    }







    fun init_module(admin: &signer) {
        move_to(admin, ChallengeRegistry{
            next_challenge_id: aggregator_v2::create_aggregator(18446744073709551615),
        })
    }

    public entry fun create_challenge(
        creator: &signer,
        title: String,
        metadata_uri: String,
        category: u8,
        scoring_mode_val: u8, // Frontend gửi u8,
        duration_seconds: u64,
    )

}