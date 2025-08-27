-- Hardcore Mode Configuration File
-- Adjust these settings to customize your hardcore experience

HardcoreConfig = {
    enabled = true,                    -- Enable/disable hardcore mode globally
    debug_mode = true,                  -- Enable debug messages
    
    current_season = 1,                 -- Current season number
    season_name = "Season 1",           -- Season display name
    
    xp_bonus_multiplier = 1.15,         -- 15% XP bonus for hardcore players
    safe_level_threshold = 1,           -- Players are safe from hardcore death until this level
    grace_period_seconds = 5,           -- Immunity period after login (seconds)
    combat_logout_timer = 30,           -- Time before logout in combat (seconds)
    
    trade_level_difference = 3,         -- Maximum level difference for hardcore trading
    allow_hardcore_to_normal_trade = false, -- Can hardcore trade with normal players
    
    allow_resurrection_tokens = true,   -- Enable resurrection token system
    starting_tokens = 0,                -- Number of tokens players start with
    max_tokens = 3,                     -- Maximum tokens a player can have
    token_item_entry = 0,               -- Item ID for resurrection tokens (0 = disabled)
    
    ironman_enabled = true,             -- Allow ironman mode selection
    ironman_restrictions = {
        no_groups = true,               -- Cannot join groups/raids
        no_mail = true,                 -- Cannot use mail at all
        no_auction_house = true,        -- Cannot use AH at all
        no_trade = true,                -- Cannot trade with anyone
        no_bank_sharing = true,         -- Cannot share bank with alts
        self_found_only = true,         -- Must find/craft all gear themselves
        xp_bonus = 1.25                 -- 25% XP bonus for ironman
    },
    
    announce_deaths = true,             -- Broadcast hardcore deaths server-wide
    death_log_enabled = true,           -- Log all hardcore deaths to database
    allow_ghost_spectate = true,        -- Dead players can spectate as ghosts
    leaderboard_size = 100,             -- Number of entries to show
    leaderboard_update_interval = 300,  -- Update interval in seconds
    show_dead_on_leaderboard = true,    -- Include dead characters
    
        milestones = {
        [10] = {
            item_reward = 0,         -- Item ID to reward (0 = none)
            gold_reward = 10000,        -- Gold reward in copper (1g)
            achievement_id = 0          -- Achievement to grant
        },
        [20] = {
            item_reward = 0,
            gold_reward = 50000,        -- 5g
            achievement_id = 0
        },
        [30] = {
            item_reward = 0,
            gold_reward = 100000,       -- 10g
            achievement_id = 0
        },
        [40] = {
            item_reward = 0,
            gold_reward = 250000,       -- 25g
            achievement_id = 0
        },
        [50] = {
            item_reward = 0,
            gold_reward = 500000,       -- 50g
            achievement_id = 0
        },
        [60] = {
            item_reward = 0,
            gold_reward = 1000000,      -- 100g
            achievement_id = 0,
            title_id = 0                -- Title reward
        },
        [70] = {
            item_reward = 0,
            gold_reward = 2000000,      -- 200g
            achievement_id = 0,
            title_id = 0
        },
        [80] = {
            item_reward = 0,            -- Special mount/pet
            gold_reward = 5000000,      -- 500g
            achievement_id = 0,
            title_id = 0                -- Hardcore Legend title
        }
    },
    
    -- Achievement IDs
    achievements = {
        hardcore_enabled = 0,           -- Achievement for enabling hardcore
        first_death = 0,                -- Achievement for first hardcore death
        reach_level_10 = 0,
        reach_level_20 = 0,
        reach_level_30 = 0,
        reach_level_40 = 0,
        reach_level_50 = 0,
        reach_level_60 = 0,
        reach_level_70 = 0,
        reach_level_80 = 0,
        ironman_enabled = 0,            -- Achievement for ironman mode
        season_top_10 = 0,              -- Reach top 10 in season
        survived_week = 0,
        survived_month = 0
    },
    
    messages = {
        confirm_hardcore = "Are you SURE? Hardcore mode means PERMANENT DEATH! This cannot be undone!",
        confirm_ironman = "Ironman mode is EXTREME difficulty! No groups, no trading, no help! Are you CERTAIN?",
        hardcore_enabled = "You have entered HARDCORE MODE! Death is permanent. Good luck!",
        ironman_enabled = "You have entered IRONMAN MODE! You stand alone. May fortune favor you!",
        death_message = "%s (Level %d %s) has died permanently in hardcore mode to %s!",
        ironman_death_message = "IRONMAN %s (Level %d %s) has fallen to %s! A true warrior's death!",
        trade_not_hardcore = "You can only trade with other hardcore players!",
        trade_level_difference = "Level difference too high! Can only trade within %d levels.",
        trade_ironman = "Ironman players cannot trade with anyone!",  
        mail_blocked = "Hardcore players cannot use the mail system!",
        ah_blocked = "Hardcore players cannot use the Auction House!",
        token_available = "You have %d resurrection token(s). Use command .hardcore resurrect to use one.",
        token_used = "Resurrection token used! You have %d token(s) remaining.",
        no_tokens = "You have no resurrection tokens! This death is permanent.",
        info_text = [[
|cffff0000HARDCORE MODE RULES:|r
- Death is PERMANENT - no respawning!
- Can only trade with other hardcore players within 3 levels
- Cannot use mail system or auction house
- %d%% XP bonus as risk/reward
- Special rewards at milestone levels
- Compete on the hardcore leaderboard
- Resurrection tokens may save you once

|cff00ff00IRONMAN MODE (Ultra Hardcore):|r
- All hardcore rules PLUS:
- Cannot join groups or raids
- Cannot trade with anyone
- Must find/craft all gear yourself
- %d%% XP bonus for extreme difficulty

Choose wisely - this decision cannot be reversed!]]
    },
    
    commands = {
        enabled = true,                 -- Enable chat commands
        prefix = "hardcore",            -- Command prefix (.hardcore)
        permissions = {
            info = 0,
            leaderboard = 0,
            resurrect = 0,
            admin_grant_token = 3,      -- GM level to grant tokens
            admin_reset = 3,            -- GM level to reset hardcore
            admin_season = 4            -- Admin level to manage seasons
        }
    },
    
    database = {
        use_transactions = true,
        batch_size = 100,
        connection_pool = true
    }
}

local function ValidateConfig()
    if HardcoreConfig.xp_bonus_multiplier < 1.0 then
        print("[Hardcore] Warning: XP bonus multiplier is less than 1.0!")
    end
    
    if HardcoreConfig.trade_level_difference < 1 then
        print("[Hardcore] Warning: Trade level difference is less than 1!")
    end
    
    if HardcoreConfig.safe_level_threshold > 10 then
        print("[Hardcore] Warning: Safe level threshold is very high!")
    end
    
    if HardcoreConfig.debug_mode then
        print("[Hardcore] Debug mode is enabled!")
    end
    
    print("[Hardcore] Configuration loaded successfully!")
end

ValidateConfig()

return HardcoreConfig