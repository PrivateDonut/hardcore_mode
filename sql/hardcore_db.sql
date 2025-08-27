-- Hardcore Mode Database Schema
-- Run this SQL in your characters database
-- WARNING: This will DROP and recreate all hardcore tables!

-- Drop existing views
DROP VIEW IF EXISTS `v_hardcore_leaderboard_current`;

-- Drop existing procedures
DROP PROCEDURE IF EXISTS `sp_hardcore_death`;

-- Drop existing tables
DROP TABLE IF EXISTS `hardcore_pending_rewards`;
DROP TABLE IF EXISTS `hardcore_achievements`;
DROP TABLE IF EXISTS `hardcore_milestones`;
DROP TABLE IF EXISTS `hardcore_death_log`;
DROP TABLE IF EXISTS `hardcore_leaderboard`;
DROP TABLE IF EXISTS `character_hardcore`;
DROP TABLE IF EXISTS `hardcore_seasons`;

-- Main hardcore character tracking table
CREATE TABLE `character_hardcore` (
    `guid` INT UNSIGNED NOT NULL COMMENT 'Character GUID',
    `account_id` INT UNSIGNED NOT NULL COMMENT 'Account ID',
    `is_hardcore` TINYINT(1) DEFAULT 0 COMMENT 'Is character in hardcore mode',
    `ironman_mode` TINYINT(1) DEFAULT 0 COMMENT 'Is character in ironman variant',
    `start_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When hardcore mode was enabled',
    `death_time` TIMESTAMP NULL DEFAULT NULL COMMENT 'Time of permanent death',
    `killer_name` VARCHAR(255) NULL DEFAULT NULL COMMENT 'Name of creature/player that killed',
    `killer_entry` INT UNSIGNED NULL DEFAULT NULL COMMENT 'Entry ID of killer creature',
    `death_map` INT UNSIGNED NULL DEFAULT NULL COMMENT 'Map ID where death occurred',
    `death_zone` INT UNSIGNED NULL DEFAULT NULL COMMENT 'Zone ID where death occurred',
    `death_level` TINYINT UNSIGNED DEFAULT 0 COMMENT 'Level at time of death',
    `total_playtime` INT UNSIGNED DEFAULT 0 COMMENT 'Total playtime in seconds',
    `season` INT UNSIGNED DEFAULT 1 COMMENT 'Hardcore season number',
    `resurrection_tokens` TINYINT UNSIGNED DEFAULT 0 COMMENT 'Available resurrection tokens',
    `tokens_used` TINYINT UNSIGNED DEFAULT 0 COMMENT 'Resurrection tokens used',
    `highest_achievement` INT UNSIGNED DEFAULT 0 COMMENT 'Highest achievement points',
    PRIMARY KEY (`guid`),
    KEY `idx_account` (`account_id`),
    KEY `idx_season` (`season`),
    KEY `idx_death_time` (`death_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Hardcore mode character data';

-- Leaderboard for tracking top hardcore players
CREATE TABLE `hardcore_leaderboard` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `guid` INT UNSIGNED NOT NULL COMMENT 'Character GUID',
    `account_id` INT UNSIGNED NOT NULL COMMENT 'Account ID',
    `character_name` VARCHAR(255) NOT NULL COMMENT 'Character name',
    `level` TINYINT UNSIGNED NOT NULL COMMENT 'Character level',
    `class` TINYINT UNSIGNED NOT NULL COMMENT 'Character class',
    `race` TINYINT UNSIGNED NOT NULL COMMENT 'Character race',
    `gender` TINYINT UNSIGNED NOT NULL COMMENT 'Character gender',
    `playtime` INT UNSIGNED NOT NULL COMMENT 'Total playtime in seconds',
    `season` INT UNSIGNED NOT NULL COMMENT 'Season number',
    `death_date` TIMESTAMP NULL DEFAULT NULL COMMENT 'Date of death if applicable',
    `killer_name` VARCHAR(255) NULL DEFAULT NULL COMMENT 'What killed the player',
    `achievements_earned` INT UNSIGNED DEFAULT 0 COMMENT 'Number of achievements',
    `gold_earned` INT UNSIGNED DEFAULT 0 COMMENT 'Total gold earned',
    `monsters_killed` INT UNSIGNED DEFAULT 0 COMMENT 'Total monsters killed',
    `quests_completed` INT UNSIGNED DEFAULT 0 COMMENT 'Total quests completed',
    `dungeons_completed` INT UNSIGNED DEFAULT 0 COMMENT 'Total dungeons completed',
    `pvp_kills` INT UNSIGNED DEFAULT 0 COMMENT 'PvP kills if applicable',
    `ironman` TINYINT(1) DEFAULT 0 COMMENT 'Was in ironman mode',
    `rank_overall` INT UNSIGNED DEFAULT 0 COMMENT 'Overall rank',
    `rank_class` INT UNSIGNED DEFAULT 0 COMMENT 'Class-specific rank',
    `rank_season` INT UNSIGNED DEFAULT 0 COMMENT 'Season rank',
    PRIMARY KEY (`id`),
    UNIQUE KEY `idx_guid_season` (`guid`, `season`),
    KEY `idx_level` (`level`),
    KEY `idx_season_level` (`season`, `level` DESC),
    KEY `idx_class` (`class`),
    KEY `idx_account` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Hardcore mode leaderboard';

-- Death log for detailed death tracking
CREATE TABLE `hardcore_death_log` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `guid` INT UNSIGNED NOT NULL COMMENT 'Character GUID',
    `character_name` VARCHAR(255) NOT NULL COMMENT 'Character name',
    `level` TINYINT UNSIGNED NOT NULL COMMENT 'Level at death',
    `class` TINYINT UNSIGNED NOT NULL COMMENT 'Character class',
    `race` TINYINT UNSIGNED NOT NULL COMMENT 'Character race',
    `death_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Time of death',
    `killer_type` ENUM('creature', 'player', 'environmental', 'other') DEFAULT 'creature',
    `killer_name` VARCHAR(255) NOT NULL COMMENT 'Name of killer',
    `killer_entry` INT UNSIGNED NULL DEFAULT NULL COMMENT 'Creature entry if applicable',
    `killer_level` TINYINT UNSIGNED NULL DEFAULT NULL COMMENT 'Level of killer',
    `map_id` INT UNSIGNED NOT NULL COMMENT 'Map where death occurred',
    `zone_id` INT UNSIGNED NOT NULL COMMENT 'Zone where death occurred',
    `area_id` INT UNSIGNED NULL DEFAULT NULL COMMENT 'Area where death occurred',
    `position_x` FLOAT NOT NULL COMMENT 'X coordinate of death',
    `position_y` FLOAT NOT NULL COMMENT 'Y coordinate of death',
    `position_z` FLOAT NOT NULL COMMENT 'Z coordinate of death',
    `damage_school` TINYINT UNSIGNED DEFAULT 0 COMMENT 'School of killing blow',
    `damage_amount` INT UNSIGNED DEFAULT 0 COMMENT 'Amount of killing blow',
    `season` INT UNSIGNED DEFAULT 1 COMMENT 'Season number',
    `ironman` TINYINT(1) DEFAULT 0 COMMENT 'Was in ironman mode',
    PRIMARY KEY (`id`),
    KEY `idx_guid` (`guid`),
    KEY `idx_death_time` (`death_time`),
    KEY `idx_season` (`season`),
    KEY `idx_level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Detailed hardcore death log';

-- Hardcore achievements tracking
CREATE TABLE `hardcore_achievements` (
    `guid` INT UNSIGNED NOT NULL COMMENT 'Character GUID',
    `achievement_id` INT UNSIGNED NOT NULL COMMENT 'Achievement ID',
    `achievement_name` VARCHAR(255) NOT NULL COMMENT 'Achievement name',
    `earned_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Date earned',
    `season` INT UNSIGNED DEFAULT 1 COMMENT 'Season earned in',
    PRIMARY KEY (`guid`, `achievement_id`),
    KEY `idx_achievement` (`achievement_id`),
    KEY `idx_date` (`earned_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Hardcore-specific achievements';

-- Hardcore milestones (level 10, 20, 30, etc.)
CREATE TABLE `hardcore_milestones` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `guid` INT UNSIGNED NOT NULL COMMENT 'Character GUID',
    `character_name` VARCHAR(255) NOT NULL COMMENT 'Character name',
    `milestone_type` VARCHAR(50) NOT NULL COMMENT 'Type of milestone',
    `milestone_value` INT UNSIGNED NOT NULL COMMENT 'Value achieved',
    `achieved_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Date achieved',
    `season` INT UNSIGNED DEFAULT 1 COMMENT 'Season number',
    `rewarded` TINYINT(1) DEFAULT 0 COMMENT 'Has reward been given',
    PRIMARY KEY (`id`),
    KEY `idx_guid` (`guid`),
    KEY `idx_type` (`milestone_type`),
    KEY `idx_season` (`season`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Hardcore milestone tracking';

-- Pending rewards for when inventory is full
CREATE TABLE `hardcore_pending_rewards` (
    `guid` INT UNSIGNED NOT NULL COMMENT 'Character GUID',
    `item_id` INT UNSIGNED NOT NULL COMMENT 'Item ID to reward',
    `quantity` INT UNSIGNED DEFAULT 1 COMMENT 'Quantity of item',
    `added_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When reward was added',
    PRIMARY KEY (`guid`, `item_id`),
    KEY `idx_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Pending milestone rewards for hardcore players';

-- Season configuration
CREATE TABLE `hardcore_seasons` (
    `season_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `season_name` VARCHAR(100) NOT NULL COMMENT 'Season name',
    `start_date` TIMESTAMP NOT NULL COMMENT 'Season start',
    `end_date` TIMESTAMP NULL DEFAULT NULL COMMENT 'Season end',
    `is_active` TINYINT(1) DEFAULT 1 COMMENT 'Is currently active',
    `xp_bonus` FLOAT DEFAULT 1.15 COMMENT 'XP multiplier for season',
    `special_rules` TEXT NULL COMMENT 'Special season rules JSON',
    PRIMARY KEY (`season_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Hardcore season configuration';

-- Insert default season
INSERT INTO `hardcore_seasons` (`season_name`, `start_date`, `is_active`, `xp_bonus`) 
VALUES ('Season 1', NOW(), 1, 1.15)
ON DUPLICATE KEY UPDATE `season_id` = `season_id`;

-- Stored procedure to handle hardcore death
DELIMITER $$
CREATE PROCEDURE `sp_hardcore_death`(
    IN p_guid INT UNSIGNED,
    IN p_killer_name VARCHAR(255),
    IN p_killer_entry INT UNSIGNED,
    IN p_death_map INT UNSIGNED,
    IN p_death_zone INT UNSIGNED,
    IN p_death_level TINYINT UNSIGNED
)
BEGIN
    -- Update hardcore status
    UPDATE `character_hardcore` 
    SET 
        `death_time` = NOW(),
        `killer_name` = p_killer_name,
        `killer_entry` = p_killer_entry,
        `death_map` = p_death_map,
        `death_zone` = p_death_zone,
        `death_level` = p_death_level
    WHERE `guid` = p_guid;
    
    -- Update leaderboard
    UPDATE `hardcore_leaderboard`
    SET 
        `death_date` = NOW(),
        `killer_name` = p_killer_name
    WHERE `guid` = p_guid AND `death_date` IS NULL;
END$$
DELIMITER ;

-- View for current season leaderboard
CREATE OR REPLACE VIEW `v_hardcore_leaderboard_current` AS
SELECT 
    hl.*,
    ch.is_hardcore,
    ch.death_time,
    CASE 
        WHEN ch.death_time IS NULL THEN 'Alive'
        ELSE 'Dead'
    END AS status
FROM `hardcore_leaderboard` hl
JOIN `character_hardcore` ch ON hl.guid = ch.guid
WHERE hl.season = (SELECT MAX(season_id) FROM hardcore_seasons WHERE is_active = 1)
ORDER BY hl.level DESC, hl.playtime DESC;

-- Indexes for performance
CREATE INDEX `idx_hardcore_active` ON `character_hardcore` (`is_hardcore`, `death_time`);
CREATE INDEX `idx_leaderboard_ranking` ON `hardcore_leaderboard` (`season`, `level` DESC, `playtime` DESC);