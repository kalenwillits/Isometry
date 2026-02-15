# Playing Isometry

## Controls

### Movement
- **Right Click** - Move to a destination (pathfinding)
- **Arrow Keys** - Move directly in a direction (hold to keep moving)
- **W / A / S / D** - Change facing direction (bearing)
- Characters navigate automatically using pathfinding around obstacles

### Camera
- **Space** - Toggle camera lock on your character (hold to temporarily recenter)
- **Page Up / Mouse Wheel Up** - Zoom in
- **Page Down / Mouse Wheel Down** - Zoom out

### Targeting
- **Tab** - Cycle to next target
- **Shift + Tab** - Cycle to previous target
- **F** - Target self
- **Esc** - Clear current target
- **=** / **-** - Cycle target groups

### Skills
- **Q / W / E / R / T / Y / U / I / O** - Activate skills in slots 1-9
- Skills may require a target to be selected
- Some skills are instant, others have casting animations
- Hold a skill key to charge (if the skill supports charging)

### Menus
- **` (Backtick)** - Open context menu for current target
- **Home** - Open global menu
- **Esc** - Close current menu

### Chat
- **Enter** - Open the chat input
- **C** - Cycle chat channel
- Type your message and press **Enter** to send

## Gameplay Mechanics

### Resources
Resources are numeric values tracked on your character (health, mana, gold, etc.). They display on your data plate and can be viewed by right-clicking your resource bar.

- Resources have minimum and maximum values
- Resources can regenerate via timers
- Resources can trigger actions when they change (e.g., death on 0 health)

### Skills & Actions
Skills are bound to Q/W/E/R/T/Y/U/I/O by default. Pressing a skill key executes its associated action, which may:

- Deal damage to a target
- Heal yourself
- Move to a location
- Display information
- Trigger conditional logic

### Perception & Vision
Characters have a perception radius. You can only see actors within your perception range. Actors also have a salience value that determines how visible they are.

### Groups & Factions
Actors belong to groups (players, enemies, neutral). Group membership affects targeting and determines the colored outline on characters.

## Multiplayer

### Hosting a Game
1. Launch with `--network=host` or click **HOST** in the launcher
2. Share your IP address and port with players
3. Players connect with `--network=client` pointing to your address

### Joining a Game
1. Obtain the server's IP and port from the host
2. Launch with `--network=client --uri=SERVER_IP --port=PORT`
3. Enter the same campaign name and your credentials

### Authentication
Isometry uses RSA encryption for password authentication. Each server generates a keypair on first launch. Players authenticate with username/password to spawn.

## Troubleshooting

### Campaign won't load
- Verify the ZIP file exists in your campaign directory
- Check the campaign name matches (case-sensitive, no .zip extension)
- Run with `--log-level=trace` for detailed error output

### Can't connect to server
- Verify the server is running and the port is open
- Check firewall settings (UDP port must be accessible)
- Ensure both client and server use the same campaign version

### Performance issues
- Reduce zoom level
- Lower the number of visible actors
- Check `--log-level=trace` for bottleneck information
