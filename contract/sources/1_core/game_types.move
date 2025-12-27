module my_addr::game_types {
    use std::string::String;
    
    // --- 1. Social Types ---
    // Chuyển từ const u8 sang Enum để dùng làm Key trong SimpleMap
    public enum SocialType has copy, drop, store {
        Twitter,
        Github,
        Telegram,
        Discord,
        Youtube,
        Facebook,
        Unknown // Dùng khi input không hợp lệ
    }

    // --- 2. Server Region ---
    public enum ServerRegion has copy, drop, store {
        Unknown,
        Asia,
        NA,     // North America
        EU,     // Europe
        SEA     // South East Asia
    }

    // --- 3. Rank Level ---
    public enum RankLevel has copy, drop, store {
        Bronze,
        Silver,
        Gold,
        Platinum
    }

    public enum ChallengeStatus has copy, drop, store {
        Draft,      // Mới nháp, chưa nạp tiền
        Active,     // Đã nạp tiền, đang nhận bài thi
        Validation, // Hết hạn nộp, đang chấm điểm
        Completed,  // Đã trả thưởng xong
        Cancelled,  // Đã hủy, hoàn tiền
        Disputed    // Đang có tranh chấp
    }

    public enum ChallengeCategory has copy, drop, store {
        // 1. Đua tốc độ (VD: Phá đảo Elden Ring dưới 2 tiếng)
        Speedrun,      
        
        // 2. Kỹ năng PvP (VD: Thắng 10 trận CS:GO liên tiếp, Leo rank Thách đấu)
        PvP_Combat,    
        
        // 3. Săn thành tựu (VD: Giết Boss ẩn, Sưu tầm đủ 100 món đồ)
        Achievement,   
        
        // 4. Sáng tạo nội dung (VD: Làm video highlight, Vẽ fanart, Cosplay)
        ContentCreation, 
        
        // 5. Viết hướng dẫn (VD: Viết bài hướng dẫn build đồ, Mẹo qua màn)
        Strategy_Guide, 
        
        // 6. Sự kiện cộng đồng (VD: Tổ chức giải đấu ao làng, Mời bạn bè)
        CommunityEvent,

        //7 Tìm bug 
        BugBounty,

        //8 Khác 
        Other,
    }

    // Định nghĩa luật chơi
    public enum ScoringMode has copy, drop, store {
        // Mode 1: Giám khảo toàn quyền (Verified -> Judge Pick)
        JudgePick,      
        
        // Mode 2: Cộng đồng bầu chọn (Verified -> Voting -> Top Vote Wins)
        CommunityVote,
    }

    public enum SubmissionStatus has copy, drop, store {
        Pending,                // Đang chờ
        Approved,               // Đã duyệt
        
        // 🔥 Rejected chứa luôn lý do (String). 
        // Đây là điều u8 không bao giờ làm được.
        Rejected(String),       
        
        Disputed                // Đang khiếu nại (mở rộng sau này dễ dàng)
    }

    // --- HELPER FUNCTIONS ---
    // Giúp chuyển đổi từ số (Frontend gửi lên) sang Enum (Logic Move)

    public fun u8_to_social(kind: u8): SocialType {
        if (kind == 1) { SocialType::Twitter }
        else if (kind == 2) { SocialType::Github }
        else if (kind == 3) { SocialType::Telegram }
        else if (kind == 4) { SocialType::Discord }
        else if (kind == 5) { SocialType::Youtube }
        else if (kind == 6) { SocialType::Facebook }
        else { SocialType::Unknown }
    }

    public fun u8_to_region(code: u8): ServerRegion {
        if (code == 1) { ServerRegion::Asia }
        else if (code == 2) { ServerRegion::NA }
        else if (code == 3) { ServerRegion::EU }
        else if (code == 4) { ServerRegion::SEA }
        else { ServerRegion::Unknown }
    }
}