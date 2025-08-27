# Hardcore Mode for AzerothCore

A thrilling game mode where death is permanent! Test your skills and survive as long as you can.

## Features

### Core Features
- **Permanent Death** - When your character dies, it's game over (with optional resurrection tokens)
- **XP Bonus** - Get 15% extra experience for taking on the challenge
- **Milestone Rewards** - Earn gold and item rewards directly at levels 10, 20, 30, 40, 50, 60, 70, and 80 (no mail required!)
- **Leaderboard** - Compete with other players for the top spots
- **Season System** - Fresh starts with new seasons

### Game Modes

#### Standard Hardcore Mode
- Permanent death after your safe level (level 1 by default)
- Can only trade with other hardcore players within 3 levels
- 15% XP bonus
- Access to resurrection tokens (if enabled)

#### Ironman Mode (Ultra Hardcore)
- All standard hardcore rules PLUS:
- Cannot join groups or raids - you're completely solo
- Cannot trade with anyone at all
- Cannot use mail or auction house
- Must find or craft all your own gear
- 25% XP bonus for the extreme difficulty

## How to Use

### Getting Started
1. Create a new character
2. Type `.hardcore menu` to see your options
3. Choose your mode:
   - `.hardcore enable` - Start standard hardcore mode
   - `.hardcore ironman` - Start ironman mode (ultra hardcore)

### Commands
- `.hardcore menu` - Show the mode selection menu
- `.hardcore info` - Learn about the different modes
- `.hardcore status` - Check your current mode and tokens
- `.hardcore leaderboard` - View the top hardcore players
- `.hardcore resurrect` - Use a resurrection token (if you have any)
- `.hardcore claim` - Claim pending milestone rewards if your inventory was full

## Configuration Options

Your server admin can customize:
- **XP Bonus** - How much extra XP you get (default 15%)
- **Safe Level** - Protected from permanent death until this level (default level 1)
- **Resurrection Tokens** - Number of extra lives you start with (default 0)
- **Trading Rules** - Whether hardcore players can trade with normal players
- **Milestone Rewards** - Gold rewards at specific levels
- **Death Announcements** - Server-wide death notifications
- **Ghost Mode** - Whether dead players can spectate as ghosts

## Installation

### For Server Administrators

1. **Database Setup**
   - Run the SQL file in your characters database:
   ```
   mysql -u your_user -p your_characters_db < sql/hardcore_db.sql
   ```
   - This creates all necessary tables for tracking hardcore characters

2. **Install Lua Scripts**
   - Place `hard_core_mode.lua` and `hardcore_config.lua` in your server's Lua scripts folder inside a folder named hardcore_mode for easier storing and locating. 
   - The scripts will auto-load when the server starts

3. **Configure Settings**
   - Edit `hardcore_config.lua` to customize:
     - XP bonuses
     - Safe levels
     - Resurrection tokens
     - Milestone rewards
     - Trade restrictions

4. **Restart Server**
   - Restart your AzerothCore server for changes to take effect

## Tips for Players

- Start carefully! Every death counts
- Stock up on food before adventuring
- Avoid dangerous areas until you're properly geared
- Consider playing a self-sufficient class for Ironman mode
- Group with other hardcore players for safety (standard mode only)
- Check the leaderboard to see how you compare
- Keep inventory space available for milestone rewards
- Use `.hardcore claim` if you missed a reward due to full inventory

## Frequently Asked Questions

**Q: Can I convert my existing character to hardcore?**
A: No, only new level 1 characters can enable hardcore mode.

**Q: What happens when I die?**
A: Your character becomes permanently dead. You cannot resurrect unless you have resurrection tokens.

**Q: Can I disable hardcore mode?**
A: No, once enabled it cannot be disabled. Choose carefully!

**Q: Can hardcore players group together?**
A: Yes in standard mode, but not in Ironman mode.

**Q: Do I keep my rewards if I die?**
A: Your character remains dead, but any achievements or rewards already earned are kept.

**Q: How do milestone rewards work for hardcore/ironman players?**
A: Milestone rewards are given directly to your character instead of via mail. Gold is added instantly, and items go to your inventory. If your inventory is full, use `.hardcore claim` later to get pending item rewards.

## Support

For issues or questions about this script, server administrators can:
- Open an issue on GitHub: https://github.com/PrivateDonut/eluna-scripts
- Check the `hardcore_mode` folder in the repository for updates

Enjoy your hardcore adventure and may fortune favor the brave!