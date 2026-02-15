# Playing Guide

Complete guide to playing Isometry campaigns.

## Table of Contents

- [Single Player Mode](#single-player-mode)
- [Joining Multiplayer Games](#joining-multiplayer-games)
- [Controls](#controls)
- [Gameplay Mechanics](#gameplay-mechanics)
- [Chat and Communication](#chat-and-communication)

## Single Player Mode

Launch Isometry in offline mode to play solo:

```bash
./isometry --campaign=mycampaign --network=none
```

In single-player mode:
- No network connection required
- Full access to all campaign content
- Your progress is saved locally
- No authentication needed

### Saved Games

Your progress is automatically saved in:
- Linux: `~/.local/share/isometry/save/`
- Windows: `C:\Users\YourName\AppData\Roaming\isometry\save/`

Save files include:
- Character position
- Resource values (health, mana, gold, etc.)
- Discovered waypoints
- Map exploration state

## Joining Multiplayer Games

### Client Mode

To join a hosted or dedicated server:

```bash
./isometry --campaign=mycampaign \
  --network=client \
  --uri=server.example.com \
  --port=5000 \
  --username=myusername \
  --password=mypassword
```

**Parameters:**
- `--network=client` or `--network=3` - Join as a client
- `--uri=hostname` - Server hostname or IP address (default: localhost)
- `--port=5000` - Server port (default: 5000)
- `--username=name` - Your username for authentication
- `--password=pass` - Your password for authentication

### Authentication

Isometry uses RSA encryption for authentication:

1. Your client requests the server's public key
2. Your credentials are encrypted with the server's public key
3. The server decrypts and validates your credentials
4. If valid, the server spawns your character

**Important:**
- Usernames and passwords cannot contain: `<>:"/\|?*~!@#$%^&()={}[];.` or backticks
- The server operator manages user accounts
- Your credentials are never sent unencrypted

### Campaign Checksum

The client and server must have **identical campaign files**. Isometry calculates a SHA-256 checksum of the campaign ZIP to ensure compatibility.

If you receive a "Campaign mismatch" error:
- Download the exact campaign version from the server operator
- Verify the ZIP file isn't corrupted
- Ensure you're not using a modified campaign

### Connection Issues

**Cannot connect to server:**
- Verify the hostname/IP and port are correct
- Check your firewall allows outgoing connections
- Ask the server operator if the server is running
- Try `--uri=localhost` if connecting to a local server

**Authentication failed:**
- Verify your username and password with the server operator
- Check that your credentials don't contain invalid characters
- Ensure the server operator has created your account

**Campaign mismatch:**
- Download the correct campaign version
- Ask the server operator for the campaign ZIP file
- Don't modify campaign files

## Controls

### Movement

**Mouse Controls:**
- **Left Click (ground)** - Move to location
- **Left Click (actor)** - Target actor
- **Hold Left Click (actor)** - Follow actor
- **Right Click** - Context menu / interact

**Keyboard Movement:**
- Isometry uses click-to-move navigation
- Your character automatically pathfinds to the clicked location
- Movement respects terrain collision and obstacles

### Camera Controls

**Mouse:**
- **Middle Mouse + Drag** - Pan camera
- **Mouse Wheel Up** - Zoom in
- **Mouse Wheel Down** - Zoom out

**Keyboard:**
- **W** or **Up Arrow** - Pan camera up
- **A** or **Left Arrow** - Pan camera left
- **S** or **Down Arrow** - Pan camera down
- **D** or **Right Arrow** - Pan camera right

**Camera Tips:**
- The camera follows your character by default
- Panning temporarily unlocks the camera
- Click on your character to re-center the camera

### Skills and Actions

**Action Slots (1-9):**
- **1-9 Keys** - Activate skills in slots 1-9
- **Hold Key** - Charge skill (if charging is enabled)
- **Release Key** - Release charged skill

**Action Behavior:**
- Press: Executes the skill's `start` action
- Release: Executes the skill's `end` action (if defined)
- Some skills trigger on press, others on release
- Charging skills build power while held

### Targeting

**Tab Targeting:**
- **Tab** - Cycle to next target
- **Shift+Tab** - Cycle to previous target
- **Esc** - Clear target

**Focus Groups:**
Isometry supports 4 focus groups for tab-targeting:
- **Ctrl+1** - Add target to focus group 1
- **Ctrl+2** - Add target to focus group 2
- **Ctrl+3** - Add target to focus group 3
- **Ctrl+4** - Add target to focus group 4

Tab-targeting cycles through your focus groups first, then nearby actors.

**Target Priority:**
1. Actors in your focus groups
2. Hostile actors in perception range
3. Friendly actors in perception range
4. Neutral actors in perception range

### UI Controls

- **T** - Open chat window
- **M** - Toggle map (if campaign provides waypoints)
- **I** - Toggle inventory (campaign-dependent)
- **Esc** - Open options menu or close current UI

### Interaction

**Context Menus:**
- Right-click actors to open their interaction menu
- Right-click resources to see available actions
- Some objects provide custom menus defined by the campaign

## Gameplay Mechanics

### Resources

Resources are numeric values tracked per character:
- **Health** - Damage taken reduces health
- **Mana/Energy** - Consumed by skills
- **Stamina** - Used for physical actions
- **Gold/Currency** - Used for trading
- **Custom Resources** - Defined by campaign creators

**Resource Visibility:**
- **Public Resources** - Visible when targeting an actor
- **Private Resources** - Visible only on your own UI
- **Hidden Resources** - Not displayed (used for internal tracking)

### Perception and Vision

**Line of Sight:**
- Actors can only see other actors within their perception range
- Terrain and obstacles block vision
- Some campaigns implement fog of war

**Perception Range:**
Each actor has a perception value (in pixels) that determines:
- How far they can see other actors
- Which actors trigger `on_view` events
- Vision range for fog of war

**Salience:**
How easy an actor is to detect:
- Higher salience = easier to spot
- Used for stealth mechanics
- Defined per actor by campaign creators

### Combat

Combat mechanics are entirely campaign-defined using the action system:

**Typical Combat Flow:**
1. Target an enemy (Tab or left-click)
2. Activate skills (1-9 keys)
3. Skills execute actions (damage, healing, buffs, debuffs)
4. Resources update (health, mana, cooldowns)
5. Repeat until combat ends

**Campaign-Specific:**
- Turn-based vs real-time combat
- Damage calculations
- Status effects
- Death and respawning

All combat behavior is defined by actions in the campaign JSON files.

### Triggers and Automation

Campaigns can define automated behaviors:

**Triggers:**
- Resource-based triggers (e.g., when health drops below 25%)
- Automatically execute actions when conditions are met
- Used for effects like regeneration, death, low-health warnings

**Timers:**
- Execute actions at intervals
- Used for damage-over-time, healing-over-time
- Buff/debuff durations

**Event Hooks:**
- `on_touch` - When another actor touches you
- `on_view` - When another actor sees you
- `on_map_entered` - When entering a map
- `on_map_exited` - When leaving a map

### Map Transitions

**Changing Maps:**
- Some actions or interactions trigger map transitions
- Your character is teleported to the new map's spawn point
- Progress on the previous map is saved

**Waypoints:**
- Discoverable fast-travel locations
- Interact with waypoints to unlock them
- Use map UI (M key) to fast-travel

## Chat and Communication

### Opening Chat

Press **T** to open the chat window.

### Chat Channels

Isometry supports 8 chat channels:

| Channel | Command | Description |
|---------|---------|-------------|
| **Whisper** | `/w` or `/whisper` | Private message to your current target |
| **Say** | `/s` or `/say` | Actors who can see you |
| **Focus** | `/f` or `/focus` | Actors in your focus groups |
| **Group** | `/g` or `/group` | Members of your group/faction |
| **Public** | `/p` or `/public` | All players (broadcast) |
| **Map** | `/m` or `/map` | All players on your current map |
| **Yell** | `/y` or `/yell` | Actors within 2x(salience+perception) radius |
| **Log** | - | System messages (cannot send) |

### Chat Examples

```
/w Hello there!                  # Whisper to target
/s Anyone need a healer?         # Say to nearby actors
/g Ready for the boss fight?     # Group chat
/p Looking for group!            # Public broadcast
/m Is there a merchant on this map?  # Map chat
/y Help! I'm under attack!       # Yell to wide area
```

### Chat Tips

- **Default channel:** Type without a command to use your last channel
- **Target required:** Whisper requires a target actor
- **Range-based:** Say, Yell, and Focus only reach actors who can see/hear you
- **System messages:** Appear in the Log channel

### Emotes and Roleplay

Campaigns can implement custom emotes via the action system:
- `/wave`, `/dance`, `/laugh`, etc.
- Triggers animations on your character
- Visible to nearby players

Check your campaign's documentation for available emotes.

## Advanced Features

### Macros (Campaign-Dependent)

Some campaigns support macro systems:
- Bind multiple actions to a single key
- Create combat rotations
- Automate common tasks

### UI Customization

Isometry provides minimal UI by default. Campaigns can:
- Add custom UI panels
- Display campaign-specific information
- Create interactive dialogues and menus

### Multiplayer Etiquette

When playing multiplayer:
- **Respect other players** - Don't grief or harass
- **Follow server rules** - Each server may have specific guidelines
- **Report bugs to campaign creators** - Not to server operators
- **Ask before looting** - Respect shared resources
- **Communicate** - Use group chat for coordination

## Performance Tips

If you experience lag or low FPS:

1. **Reduce zoom level** - Zoom out to render fewer actors
2. **Lower resolution** - Change your display settings
3. **Close other programs** - Free up system resources
4. **Check network connection** - High ping impacts multiplayer
5. **Ask about actor count** - Too many NPCs can slow down clients

## Troubleshooting

### Controls not responding

- Click the game window to ensure it has focus
- Check that no modal dialogs are blocking input
- Verify your campaign has assigned skills to action slots
- Try restarting the game

### Can't see my character

- Press **Esc** to center camera
- Check that you're on the correct map
- Verify the campaign spawned your character correctly
- Look for error messages in chat

### Target switching doesn't work

- Ensure actors are within perception range
- Check that you're on the same map as targets
- Verify line-of-sight isn't blocked
- Try clicking directly on actors instead of using Tab

### Skills won't activate

- Check that your target is valid (if skill requires target)
- Verify you have sufficient resources (mana, stamina, etc.)
- Ensure skill cooldowns have expired
- Check for status effects preventing skill use

### Multiplayer desync

If your client state doesn't match the server:
- Disconnect and reconnect
- Clear your local cache
- Verify you have the correct campaign version
- Report persistent desyncs to the server operator

## Getting Help

- **Campaign-specific help** - Contact the campaign creator
- **Server issues** - Contact the server operator
- **Technical problems** - See [Troubleshooting](troubleshooting.md)
- **Bug reports** - Include `--log-level=trace` output

---

**Next:** [Hosting Games](hosting.md) | [Campaign Creation](campaign-basics.md) | [Back to Home](README.md)
