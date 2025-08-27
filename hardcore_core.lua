-- Hardcore Mode System for AzerothCore with Eluna
-- Permanent death gameplay mode

local Config = require("hardcore_config")

HardcorePlayers = {}
local TEAM_ALLIANCE = 0
local TEAM_HORDE = 1
local function DebugLog(message)
    if Config.debug_mode then
        print("[Hardcore Debug] " .. message)
    end
end

local function GetPlayerIdentifier(player)
    return player:GetGUIDLow()
end

local function GetAccountId(player)
    return player:GetAccountId()
end

local function SendColoredMessage(player, message, color)
    color = color or "|cffff0000"
    player:SendBroadcastMessage(color .. "[Hardcore] |r" .. message)
end

local function GetClassName(classId)
    local classes = {
        [1] = "Warrior",
        [2] = "Paladin", 
        [3] = "Hunter",
        [4] = "Rogue",
        [5] = "Priest",
        [6] = "Death Knight",
        [7] = "Shaman",
        [8] = "Mage",
        [9] = "Warlock",
        [11] = "Druid"
    }
    return classes[classId] or "Unknown"
end

local function BroadcastHardcoreDeath(player, killer)
    if not Config.announce_deaths then
        return
    end
    
    local playerName = player:GetName()
    local level = player:GetLevel()
    local class = player:GetClass()
    local killerName = killer and killer:GetName() or "Unknown"
    
    local message
    if HardcorePlayers[GetPlayerIdentifier(player)].ironman then
        message = string.format(Config.messages.ironman_death_message, 
            playerName, level, GetClassName(class), killerName)
    else
        message = string.format(Config.messages.death_message,
            playerName, level, GetClassName(class), killerName)
    end
    
    SendWorldMessage("|cffff0000[HARDCORE DEATH] |r" .. message)
end
local function LoadHardcoreData(player)
    local guid = GetPlayerIdentifier(player)
    local query = CharDBQuery(string.format(
        "SELECT is_hardcore, ironman_mode, death_time, resurrection_tokens, season, total_playtime " ..
        "FROM character_hardcore WHERE guid = %d",
        guid
    ))
    
    if query then
        local data = {
            is_hardcore = query:GetBool(0),
            ironman = query:GetBool(1),
            death_time = query:GetString(2),
            resurrection_tokens = query:GetUInt32(3),
            season = query:GetUInt32(4),
            playtime = query:GetUInt32(5),
            login_time = os.time()
        }
        
        -- Check if death_time is actually set (not NULL)
        if data.death_time and 
           data.death_time ~= "" and 
           data.death_time ~= "NULL" and 
           data.death_time ~= "nil" and
           tostring(data.death_time) ~= "nil" then
            data.is_dead = true
            player:SetData("hardcore_dead", true)
            DebugLog("Player " .. player:GetName() .. " marked as dead, death_time: " .. tostring(data.death_time))
        else
            data.is_dead = false
            player:SetData("hardcore_dead", false)
            DebugLog("Player " .. player:GetName() .. " marked as alive, death_time: " .. tostring(data.death_time))
        end
        
        HardcorePlayers[guid] = data
        DebugLog("Loaded hardcore data for player " .. player:GetName())
        return data
    end
    
    return nil
end

local function SaveHardcoreData(player)
    local guid = GetPlayerIdentifier(player)
    local data = HardcorePlayers[guid]
    
    if not data then
        return
    end
    
    local playtime = data.playtime + (os.time() - data.login_time)
    
    CharDBExecute(string.format(
        "UPDATE character_hardcore SET total_playtime = %d WHERE guid = %d",
        playtime, guid
    ))
    
    DebugLog("Saved hardcore data for player " .. player:GetName())
end

local function CreateHardcoreEntry(player, ironman)
    local guid = GetPlayerIdentifier(player)
    local accountId = GetAccountId(player)
    
    local existsQuery = CharDBQuery(string.format(
        "SELECT is_hardcore FROM character_hardcore WHERE guid = %d",
        guid
    ))
    
    if existsQuery then
        DebugLog("Character already has hardcore entry, skipping creation")
        return false
    end
    
    CharDBExecute(string.format(
        "INSERT INTO character_hardcore (guid, account_id, is_hardcore, ironman_mode, season) " ..
        "VALUES (%d, %d, 1, %d, %d)",
        guid, accountId, ironman and 1 or 0, Config.current_season
    ))
    
    CharDBExecute(string.format(
        "INSERT IGNORE INTO hardcore_leaderboard " ..
        "(guid, account_id, character_name, level, class, race, gender, playtime, season, ironman) " ..
        "VALUES (%d, %d, '%s', %d, %d, %d, %d, 0, %d, %d)",
        guid, accountId, player:GetName(), player:GetLevel(), player:GetClass(),
        player:GetRace(), player:GetGender(), Config.current_season, ironman and 1 or 0
    ))
    
    HardcorePlayers[guid] = {
        is_hardcore = true,
        ironman = ironman,
        is_dead = false,
        resurrection_tokens = Config.starting_tokens,
        season = Config.current_season,
        playtime = 0,
        login_time = os.time()
    }
    
    DebugLog("Created hardcore entry for " .. player:GetName())
    return true
end

local function UpdateLeaderboard(player)
    local guid = GetPlayerIdentifier(player)
    local data = HardcorePlayers[guid]
    
    if not data then
        return
    end
    
    local playtime = data.playtime + (os.time() - data.login_time)
    
    CharDBExecute(string.format(
        "UPDATE hardcore_leaderboard SET " ..
        "level = %d, playtime = %d, gold_earned = %d " ..
        "WHERE guid = %d AND season = %d",
        player:GetLevel(), playtime, player:GetCoinage(),
        guid, Config.current_season
    ))
end

local function RecordDeath(player, killer)
    local guid = GetPlayerIdentifier(player)
    local killerName = killer and killer:GetName() or "Unknown"
    local killerEntry = killer and killer:GetEntry() or 0
    local mapId = player:GetMapId()
    local zoneId = player:GetZoneId()
    local level = player:GetLevel()
    local x, y, z = player:GetX(), player:GetY(), player:GetZ()
    
    CharDBExecute(string.format(
        "UPDATE character_hardcore SET " ..
        "death_time = NOW(), killer_name = '%s', killer_entry = %d, " ..
        "death_map = %d, death_zone = %d, death_level = %d " ..
        "WHERE guid = %d",
        killerName, killerEntry, mapId, zoneId, level, guid
    ))
    
    CharDBExecute(string.format(
        "INSERT INTO hardcore_death_log " ..
        "(guid, character_name, level, class, race, killer_name, killer_entry, " ..
        "map_id, zone_id, position_x, position_y, position_z, season) " ..
        "VALUES (%d, '%s', %d, %d, %d, '%s', %d, %d, %d, %f, %f, %f, %d)",
        guid, player:GetName(), level, player:GetClass(), player:GetRace(),
        killerName, killerEntry, mapId, zoneId, x, y, z, Config.current_season
    ))
    
    CharDBExecute(string.format(
        "UPDATE hardcore_leaderboard SET death_date = NOW(), killer_name = '%s' " ..
        "WHERE guid = %d AND season = %d",
        killerName, guid, Config.current_season
    ))
    
    HardcorePlayers[guid].is_dead = true
end
local function IsPlayerHardcore(player)
    local guid = GetPlayerIdentifier(player)
    return HardcorePlayers[guid] and HardcorePlayers[guid].is_hardcore
end

local function IsPlayerIronman(player)
    local guid = GetPlayerIdentifier(player)
    return HardcorePlayers[guid] and HardcorePlayers[guid].ironman
end

local function IsPlayerDead(player)
    local guid = GetPlayerIdentifier(player)
    
    if HardcorePlayers[guid] and HardcorePlayers[guid].is_dead then
        return true
    end
    
    if player:GetData("hardcore_dead") then
        return true
    end
    
    if not HardcorePlayers[guid] then
        local query = CharDBQuery(string.format(
            "SELECT death_time FROM character_hardcore WHERE guid = %d AND is_hardcore = 1",
            guid
        ))
        
        if query then
            local death_time = query:GetString(0)
            if death_time and death_time ~= "" and death_time ~= "NULL" and death_time ~= "nil" then
                if not HardcorePlayers[guid] then
                    HardcorePlayers[guid] = {}
                end
                HardcorePlayers[guid].is_dead = true
                player:SetData("hardcore_dead", true)
                return true
            end
        end
    end
    
    return false
end

local function ApplyHardcoreRestrictions(player)
    DebugLog("Applied hardcore restrictions to " .. player:GetName())
end

local function ApplyHardcoreBonuses(player)
    if not IsPlayerHardcore(player) then
        return
    end
    
    local multiplier = Config.xp_bonus_multiplier
    if IsPlayerIronman(player) then
        multiplier = Config.ironman_restrictions.xp_bonus
    end
    
    player:SetData("hardcore_xp_bonus", multiplier)
    DebugLog("Applied XP bonus to " .. player:GetName())
end

local function EnableHardcoreMode(player, ironman)
    if CreateHardcoreEntry(player, ironman) == false then
        SendColoredMessage(player, "You are already in hardcore mode!", "|cffff0000")
        return false
    end
    
    ApplyHardcoreRestrictions(player)
    ApplyHardcoreBonuses(player)
    
    if ironman then
        SendColoredMessage(player, Config.messages.ironman_enabled, "|cff00ff00")
    else
        SendColoredMessage(player, Config.messages.hardcore_enabled, "|cffffff00")
    end
    
    if Config.achievements.hardcore_enabled > 0 then
        player:AddAchievement(Config.achievements.hardcore_enabled)
    end
    
    if ironman and Config.achievements.ironman_enabled > 0 then
        player:AddAchievement(Config.achievements.ironman_enabled)
    end
end

local function CheckMilestoneRewards(player)
    local level = player:GetLevel()
    local milestone = Config.milestones[level]
    
    if not milestone then
        return
    end
    
    local guid = GetPlayerIdentifier(player)
    
    local query = CharDBQuery(string.format(
        "SELECT rewarded FROM hardcore_milestones " ..
        "WHERE guid = %d AND milestone_type = 'level' AND milestone_value = %d",
        guid, level
    ))
    
    if query and query:GetBool(0) then
        return
    end
    
    CharDBExecute(string.format(
        "INSERT INTO hardcore_milestones (guid, character_name, milestone_type, milestone_value, season) " ..
        "VALUES (%d, '%s', 'level', %d, %d)",
        guid, player:GetName(), level, Config.current_season
    ))
    
    -- Give rewards directly to hardcore/ironman players since they can't use mail
    if milestone.gold_reward > 0 then
        player:ModifyMoney(milestone.gold_reward)
        SendColoredMessage(player, string.format("You received %d gold as a milestone reward!", milestone.gold_reward / 10000), "|cfffff200")
    end
    
    if milestone.item_reward > 0 then
        -- Add item directly to player's inventory (returns Item object or nil)
        local item = player:AddItem(milestone.item_reward, 1)
        if item then
            SendColoredMessage(player, "Milestone reward added to your inventory!", "|cff00ff00")
        else
            -- If inventory is full, store as pending reward
            SendColoredMessage(player, "Your inventory is full! Use .hardcore claim when you have space.", "|cffff0000")
            -- Store the pending reward for later claim
            CharDBExecute(string.format(
                "INSERT INTO hardcore_pending_rewards (guid, item_id, quantity) VALUES (%d, %d, 1) " ..
                "ON DUPLICATE KEY UPDATE quantity = quantity + 1",
                guid, milestone.item_reward
            ))
        end
    end
    
    if milestone.achievement_id > 0 then
        player:AddAchievement(milestone.achievement_id)
    end
    
    if milestone.title_id and milestone.title_id > 0 then
        player:SetKnownTitle(milestone.title_id)
    end
    
    SendColoredMessage(player, "Congratulations on reaching level " .. level .. " in hardcore mode!", "|cff00ff00")
end

local function HandleHardcoreDeath(player, killer)
    if not IsPlayerHardcore(player) then
        return
    end
    
    if IsPlayerDead(player) then
        return
    end
    
    if player:GetLevel() < Config.safe_level_threshold then
        SendColoredMessage(player, "You are protected from hardcore death until level " .. Config.safe_level_threshold)
        return false
    end
    
    local guid = GetPlayerIdentifier(player)
    local data = HardcorePlayers[guid]
    
    if Config.allow_resurrection_tokens and data.resurrection_tokens > 0 then
        data.resurrection_tokens = data.resurrection_tokens - 1
        CharDBExecute(string.format(
            "UPDATE character_hardcore SET resurrection_tokens = %d, tokens_used = tokens_used + 1 " ..
            "WHERE guid = %d",
            data.resurrection_tokens, guid
        ))
        
        SendColoredMessage(player, string.format(Config.messages.token_used, data.resurrection_tokens), "|cffffff00")
        return false
    end
    
    RecordDeath(player, killer)
    BroadcastHardcoreDeath(player, killer)
    UpdateLeaderboard(player)
    
    HardcorePlayers[guid].is_dead = true
    player:SetData("hardcore_dead", true)
    
    SendColoredMessage(player, Config.messages.no_tokens, "|cffff0000")
    SendColoredMessage(player, "Your hardcore journey has ended. You cannot respawn.", "|cffff0000")
    
    return true
end


local function ShowLeaderboard(player)
    local query = CharDBQuery(string.format(
        "SELECT character_name, level, class, death_date FROM hardcore_leaderboard " ..
        "WHERE season = %d ORDER BY level DESC, playtime DESC LIMIT %d",
        Config.current_season, Config.leaderboard_size
    ))
    
    if not query then
        SendColoredMessage(player, "No hardcore players found this season!", "|cffffff00")
        return
    end
    
    SendColoredMessage(player, "=== HARDCORE LEADERBOARD SEASON " .. Config.current_season .. " ===", "|cff00ff00")
    
    local rank = 1
    repeat
        local name = query:GetString(0)
        local level = query:GetUInt32(1)
        local class = query:GetUInt32(2)
        local isDead = query:GetString(3) ~= nil
        
        local status = isDead and "|cffff0000[DEAD]|r" or "|cff00ff00[ALIVE]|r"
        local message = string.format("#%d: %s - Level %d %s %s",
            rank, name, level, GetClassName(class), status)
        
        player:SendBroadcastMessage(message)
        rank = rank + 1
    until not query:NextRow()
end

local function EnforceDeathState(player)
    if player:IsAlive() then
        player:KillPlayer()
    end
    
    player:SetData("hardcore_dead", true)
    
    
    if not Config.allow_ghost_spectate then
        local level = player:GetLevel()
        SendColoredMessage(player, string.format("Thank you for your hardcore journey. You reached level %d.", level), "|cffffff00")
        SendColoredMessage(player, "Ghost spectating is not allowed on this server.", "|cffff0000")
        SendColoredMessage(player, "You will be disconnected in 15 seconds.", "|cffffff00")
        
        player:RegisterEvent(function(eventId, delay, repeats, player)
            if player and player:IsInWorld() then
                SendColoredMessage(player, "Disconnecting in 5 seconds...", "|cffffff00")
            end
        end, 10000, 1)
        
        player:RegisterEvent(function(eventId, delay, repeats, player)
            if player and player:IsInWorld() then
                SendColoredMessage(player, "Thank you for playing hardcore mode. Goodbye!", "|cff00ff00")
                player:KickPlayer()
            end
        end, 15000, 1)
    end
    
    if Config.kick_dead_on_login and Config.allow_ghost_spectate then
        player:RegisterEvent(function(eventId, delay, repeats, player)
            if player and player:IsInWorld() then
                SendColoredMessage(player, "Dead hardcore characters are not allowed on this server.", "|cffff0000")
                player:KickPlayer()
            end
        end, 10000, 1)
    end
end
local function OnPlayerLogin(event, player)
    local data = LoadHardcoreData(player)
    
    if not data then
        if player:GetLevel() == 1 then
            SendColoredMessage(player, "========================================", "|cff00ff00")
            SendColoredMessage(player, "Welcome! Choose your destiny:", "|cffffff00")
            SendColoredMessage(player, "Type |cff00ffff.hardcore menu|r to select your game mode", "|cffffff00")
            SendColoredMessage(player, "Type |cff00ffff.hardcore info|r for more information", "|cffffff00")
            SendColoredMessage(player, "========================================", "|cff00ff00")
        end
        return
    end
    
    if data.is_hardcore then
        if data.is_dead then
            if Config.allow_ghost_spectate then
                SendColoredMessage(player, "Your hardcore journey has ended. You may explore as a ghost, but cannot resurrect.", "|cffff0000")
            end
            EnforceDeathState(player)
            player:SetData("hardcore_suppress_resurrect_message", true)
        else
            ApplyHardcoreRestrictions(player)
            ApplyHardcoreBonuses(player)
            SendColoredMessage(player, "Welcome back to HARDCORE mode! Death is permanent.", "|cffffff00")
            
            if data.resurrection_tokens > 0 then
                SendColoredMessage(player, string.format("You have %d resurrection token(s) remaining.", 
                    data.resurrection_tokens), "|cff00ff00")
            end
        end
    end
end

local function OnPlayerLogout(event, player)
    if IsPlayerHardcore(player) then
        SaveHardcoreData(player)
        UpdateLeaderboard(player)
    end
    
    player:SetData("hardcore_confirm_hardcore", false)
    player:SetData("hardcore_confirm_ironman", false)
end

local function OnPlayerKilledByCreature(event, killer, player)
    DebugLog("OnPlayerKilledByCreature called for " .. player:GetName())
    
    if not IsPlayerHardcore(player) then
        DebugLog("Player is not hardcore, skipping death handling")
        return
    end
    
    DebugLog("Handling hardcore death (creature kill) for " .. player:GetName())
    HandleHardcoreDeath(player, killer)
end

local function OnPlayerKillPlayer(event, killer, killed)
    DebugLog("OnPlayerKillPlayer called for " .. killed:GetName())
    
    if not IsPlayerHardcore(killed) then
        DebugLog("Killed player is not hardcore, skipping death handling")
        return
    end
    
    DebugLog("Handling hardcore death (PvP) for " .. killed:GetName())
    HandleHardcoreDeath(killed, killer)
end

local function OnCanResurrect(event, player)
    DebugLog("OnCanResurrect called for " .. player:GetName())
    
    local guid = GetPlayerIdentifier(player)
    
    local is_hardcore = false
    local data = HardcorePlayers[guid]
    
    if not data then
        local query = CharDBQuery(string.format(
            "SELECT is_hardcore, death_time, resurrection_tokens FROM character_hardcore WHERE guid = %d",
            guid
        ))
        
        if query then
            is_hardcore = query:GetBool(0)
            local death_time = query:GetString(1)
            local tokens = query:GetUInt32(2)
            
            data = {
                is_hardcore = is_hardcore,
                is_dead = (death_time and death_time ~= "" and death_time ~= "NULL" and death_time ~= "nil"),
                resurrection_tokens = tokens
            }
            HardcorePlayers[guid] = data
        end
    else
        is_hardcore = data.is_hardcore
    end
    
    if is_hardcore then
        DebugLog("Player is hardcore: " .. player:GetName())
        
        if IsPlayerDead(player) then
            DebugLog("Player is permanently dead, preventing resurrection")
            
            local suppressMessage = player:GetData("hardcore_suppress_resurrect_message")
            
            if suppressMessage then
                player:SetData("hardcore_suppress_resurrect_message", false)
            else
                SendColoredMessage(player, "You cannot resurrect in hardcore mode.", "|cffff0000")
                
                if not Config.allow_ghost_spectate then
                    player:RegisterEvent(function(eventId, delay, repeats, player)
                        if player and player:IsInWorld() then
                            SendColoredMessage(player, "Thank you for playing hardcore mode.", "|cff00ff00")
                            player:KickPlayer()
                        end
                    end, 15000, 1)
                end
            end
            
            player:SetData("hardcore_dead", true)
            
            return false
        end
        
        DebugLog("Hardcore player attempting to resurrect, checking tokens")
        
        if data then
            if player:GetLevel() < Config.safe_level_threshold then
                DebugLog("Player is below safe level threshold, allowing resurrection")
                SendColoredMessage(player, "You are protected from hardcore death until level " .. Config.safe_level_threshold)
                return true
            end
            
            if Config.allow_resurrection_tokens and data.resurrection_tokens > 0 then
                data.resurrection_tokens = data.resurrection_tokens - 1
                CharDBExecute(string.format(
                    "UPDATE character_hardcore SET resurrection_tokens = %d, tokens_used = tokens_used + 1 " ..
                    "WHERE guid = %d",
                    data.resurrection_tokens, guid
                ))
                SendColoredMessage(player, string.format(Config.messages.token_used, data.resurrection_tokens), "|cffffff00")
                return true
            end
            
            HandleHardcoreDeath(player, nil)
            SendColoredMessage(player, "Your hardcore journey has ended. You cannot respawn.", "|cffff0000")
            return false
        end
    end
    
    return true
end

local function OnPlayerLevelUp(event, player, oldLevel)
    if IsPlayerHardcore(player) then
        CheckMilestoneRewards(player)
        UpdateLeaderboard(player)
    end
end

local function OnCanInitTrade(event, player, target)
    if not IsPlayerHardcore(player) and not IsPlayerHardcore(target) then
        return
    end
    
    if IsPlayerHardcore(player) ~= IsPlayerHardcore(target) then
        if not Config.allow_hardcore_to_normal_trade then
            SendColoredMessage(player, Config.messages.trade_not_hardcore, "|cffff0000")
            return false
        end
    end
    
    if IsPlayerIronman(player) or IsPlayerIronman(target) then
        if IsPlayerIronman(player) then
            SendColoredMessage(player, Config.messages.trade_ironman, "|cffff0000")
        end
        if IsPlayerIronman(target) then
            SendColoredMessage(target, Config.messages.trade_ironman, "|cffff0000")
        end
        return false
    end
    
    local levelDiff = math.abs(player:GetLevel() - target:GetLevel())
    if levelDiff > Config.trade_level_difference then
        SendColoredMessage(player, string.format(Config.messages.trade_level_difference, 
            Config.trade_level_difference), "|cffff0000")
        return false
    end
    
    return true
end

local function OnCanSendMail(event, player, receiverGuid, mailbox, subject, body, money, cod, item)
    if IsPlayerHardcore(player) then
        SendColoredMessage(player, Config.messages.mail_blocked, "|cffff0000")
        return false
    end
end

local function OnGiveXP(event, player, amount, victim)
    if IsPlayerHardcore(player) then
        local multiplier = player:GetData("hardcore_xp_bonus") or Config.xp_bonus_multiplier
        local bonusXP = math.floor(amount * (multiplier - 1))
        if bonusXP > 0 then
            return amount + bonusXP
        end
    end
    return amount
end
local function HandleHardcoreCommand(event, player, command)
    if not Config.commands.enabled then
        return
    end
    
    local args = {}
    for word in command:gmatch("%S+") do
        table.insert(args, word:lower())
    end
    
    if args[1] ~= Config.commands.prefix then
        return
    end
    
    if not args[2] then
        SendColoredMessage(player, "Usage: ." .. Config.commands.prefix .. " [menu|enable|ironman|info|status|leaderboard|resurrect|claim]", "|cffffff00")
        return false
    end
    
    if args[2] == "menu" or args[2] == "start" then
        if IsPlayerHardcore(player) then
            SendColoredMessage(player, "You are already in hardcore mode!", "|cffff0000")
            return false
        end
        
        SendColoredMessage(player, "===== HARDCORE MODE SELECTION =====", "|cff00ff00")
        SendColoredMessage(player, "Choose your game mode:", "|cffffff00")
        SendColoredMessage(player, "|cff00ffff.hardcore enable|r - Enable Hardcore Mode (permanent death)", "|cffffff00")
        if Config.ironman_enabled then
            SendColoredMessage(player, "|cff00ffff.hardcore ironman|r - Enable Ironman Mode (ultra hardcore)", "|cffffff00")
        end
        SendColoredMessage(player, "|cff00ffff.hardcore info|r - Learn about the modes", "|cffffff00")
        SendColoredMessage(player, "|cff00ffff.hardcore normal|r - Continue in normal mode", "|cffffff00")
        SendColoredMessage(player, "====================================", "|cff00ff00")
        
    elseif args[2] == "enable" then
        if IsPlayerHardcore(player) then
            SendColoredMessage(player, "You are already in hardcore mode!", "|cffff0000")
            return false
        end
        
        if args[3] == "confirm" then
            EnableHardcoreMode(player, false)
            player:SetData("hardcore_confirm_hardcore", false)
        else
            SendColoredMessage(player, Config.messages.confirm_hardcore, "|cffff0000")
            SendColoredMessage(player, "Type |cff00ffff.hardcore enable confirm|r to confirm", "|cffffff00")
            player:SetData("hardcore_confirm_hardcore", true)
        end
        
    elseif args[2] == "ironman" then
        if not Config.ironman_enabled then
            SendColoredMessage(player, "Ironman mode is not enabled on this server.", "|cffff0000")
            return false
        end
        
        if IsPlayerHardcore(player) then
            SendColoredMessage(player, "You are already in hardcore mode!", "|cffff0000")
            return false
        end
        
        if args[3] == "confirm" then
            EnableHardcoreMode(player, true)
            player:SetData("hardcore_confirm_ironman", false)
        else
            SendColoredMessage(player, Config.messages.confirm_ironman, "|cffff0000")
            SendColoredMessage(player, "Type |cff00ffff.hardcore ironman confirm|r to confirm", "|cffffff00")
            player:SetData("hardcore_confirm_ironman", true)
        end
        
    elseif args[2] == "normal" then
        SendColoredMessage(player, "You will continue in normal mode. You can enable hardcore later if desired.", "|cff00ff00")
        
    elseif args[2] == "info" then
        local info = string.format(Config.messages.info_text,
            math.floor((Config.xp_bonus_multiplier - 1) * 100),
            math.floor((Config.ironman_restrictions.xp_bonus - 1) * 100))
        player:SendBroadcastMessage(info)
        
    elseif args[2] == "leaderboard" then
        ShowLeaderboard(player)
        
    elseif args[2] == "resurrect" then
        if not IsPlayerHardcore(player) then
            SendColoredMessage(player, "You are not in hardcore mode!", "|cffff0000")
        elseif not IsPlayerDead(player) then
            SendColoredMessage(player, "You are not dead!", "|cffff0000")
        else
            local guid = GetPlayerIdentifier(player)
            local data = HardcorePlayers[guid]
            if data.resurrection_tokens > 0 then
                SendColoredMessage(player, "Resurrection token feature requires GM assistance.", "|cffffff00")
            else
                SendColoredMessage(player, Config.messages.no_tokens, "|cffff0000")
            end
        end
        
    elseif args[2] == "claim" then
        -- Claim any pending milestone rewards
        if not IsPlayerHardcore(player) then
            SendColoredMessage(player, "You are not in hardcore mode!", "|cffff0000")
            return false
        end
        
        local guid = GetPlayerIdentifier(player)
        local query = CharDBQuery(string.format(
            "SELECT item_id, quantity FROM hardcore_pending_rewards WHERE guid = %d",
            guid
        ))
        
        if not query then
            SendColoredMessage(player, "You have no pending rewards to claim.", "|cffffff00")
            return false
        end
        
        local claimed = 0
        local failed = 0
        
        repeat
            local itemId = query:GetUInt32(0)
            local quantity = query:GetUInt32(1)
            local item = player:AddItem(itemId, quantity)
            
            if item then
                claimed = claimed + 1
                CharDBExecute(string.format(
                    "DELETE FROM hardcore_pending_rewards WHERE guid = %d AND item_id = %d",
                    guid, itemId
                ))
                SendColoredMessage(player, string.format("Claimed reward: Item %d x%d", itemId, quantity), "|cff00ff00")
            else
                failed = failed + 1
            end
        until not query:NextRow()
        
        if claimed > 0 then
            SendColoredMessage(player, string.format("Successfully claimed %d pending reward(s)!", claimed), "|cff00ff00")
        end
        
        if failed > 0 then
            SendColoredMessage(player, string.format("Failed to claim %d reward(s) - inventory full!", failed), "|cffff0000")
        end
        
    elseif args[2] == "status" then
        if IsPlayerHardcore(player) then
            local guid = GetPlayerIdentifier(player)
            local data = HardcorePlayers[guid]
            SendColoredMessage(player, "You are in HARDCORE mode!", "|cff00ff00")
            if data.ironman then
                SendColoredMessage(player, "You are also in IRONMAN mode!", "|cffff00ff")
            end
            SendColoredMessage(player, string.format("Resurrection tokens: %d", data.resurrection_tokens), "|cffffff00")
            SendColoredMessage(player, string.format("Season: %d", data.season), "|cffffff00")
        else
            SendColoredMessage(player, "You are not in hardcore mode.", "|cffffff00")
            SendColoredMessage(player, "Type |cff00ffff.hardcore menu|r to see options", "|cffffff00")
        end
    else
        SendColoredMessage(player, "Unknown command. Type |cff00ffff.hardcore|r for help", "|cffff0000")
    end
    
    return false
end

local function OnPlayerResurrect(event, player)
    DebugLog("OnPlayerResurrect called for " .. player:GetName())
    
    if IsPlayerHardcore(player) and IsPlayerDead(player) then
        DebugLog("Dead hardcore player was resurrected, killing them again")
        SendColoredMessage(player, "You cannot be resurrected - your hardcore character has permanently died!", "|cffff0000")
        
        player:KillPlayer()
        
        player:RegisterEvent(function(eventId, delay, repeats, player)
            if player and player:IsInWorld() then
                if player:IsAlive() then
                    player:KillPlayer()
                end
                player:KickPlayer()
            end
        end, 3000, 1)
    end
end
local function RegisterHardcoreEvents()
    RegisterPlayerEvent(3, OnPlayerLogin)
    RegisterPlayerEvent(4, OnPlayerLogout)
    RegisterPlayerEvent(6, OnPlayerKillPlayer)
    RegisterPlayerEvent(8, OnPlayerKilledByCreature)
    RegisterPlayerEvent(59, OnCanResurrect)
    RegisterPlayerEvent(36, OnPlayerResurrect)
    RegisterPlayerEvent(13, OnPlayerLevelUp)
    RegisterPlayerEvent(12, OnGiveXP)
    RegisterPlayerEvent(55, OnCanInitTrade)
    RegisterPlayerEvent(21, OnCanSendMail)
    
    RegisterPlayerEvent(42, HandleHardcoreCommand)
    
    print("[Hardcore Mode] System initialized successfully!")
    print("[Hardcore Mode] Season " .. Config.current_season .. " is active")
end
local function InitializeHardcoreMode()
    RegisterHardcoreEvents()
    
    print("[Hardcore Mode] Loading configuration...")
    print("[Hardcore Mode] XP Bonus: " .. math.floor((Config.xp_bonus_multiplier - 1) * 100 + 0.5) .. "%")
    print("[Hardcore Mode] Trade Level Difference: " .. Config.trade_level_difference)
    print("[Hardcore Mode] Safe Level: " .. Config.safe_level_threshold)
    
    if Config.ironman_enabled then
        print("[Hardcore Mode] Ironman mode is enabled")
    end
    
    if Config.allow_resurrection_tokens then
        print("[Hardcore Mode] Resurrection tokens are enabled")
    end
end
InitializeHardcoreMode()