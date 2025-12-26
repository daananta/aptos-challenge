module my_addr::game_types {
    
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