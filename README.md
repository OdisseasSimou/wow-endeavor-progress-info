# Endeavor Tracker

A World of Warcraft addon that displays XP progress for housing endeavor milestones.

## Features

- Shows XP needed for the next housing endeavor milestone
- Displays on hover over the endeavor progress bar
- Clean, non-intrusive tooltip-style display
- Automatically updates when you earn XP

## Installation

1. Extract the `EndeavorTracker` folder to your WoW AddOns directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```

2. Restart WoW or type `/reload` in-game

## Usage

1. Open the Housing Dashboard (Press `Shift+P` or click the garrison icon)
2. Navigate to the **Endeavors** tab
3. Hover over the endeavor progress bar to see XP information

The tooltip will display:
- Current XP / Next Milestone Threshold
- Exact amount of XP needed to reach the next milestone

Example: `Next Milestone: 2754 / 5000 (2246 XP needed)`

## Commands

- `/et` - Open settings panel
- `/et refresh` - Manually refresh the XP display
- `/et debug` - Show detailed API milestone information
- `/etconfig` or `/etset` - Alternative commands to open settings
- `/endeavortracker` - Alternative command for settings

## Settings

Access the settings panel through:
- **Game Menu → Options → AddOns → Endeavor Tracker**
- Or use the command: `/et`, `/etconfig`, or `/etset`

You can customize:

### Text Format Options
Choose how the XP information is displayed:
1. **Detailed (Default)** - `Milestone 2: 125 / 250 (125 XP needed)`
2. **Simple** - `125 XP to reach Milestone 2 (completed: M1)`
3. **Progress Bar Style** - `M2 Progress: 125/250 (50%) - 125 XP to go`
4. **Short** - `To Milestone 2: 125 XP remaining`
5. **Minimal** - `125 XP to next milestone`
6. **Percentage Focus** - `50% to M2 - 125 XP needed`
7. **Next & Final** - `Next: 125 XP | Final: 875 XP`

### Color Options
- **Tooltip Text Color** - Change the color of the XP display text (default: golden)
  - Click the color box to open the color picker for custom colors
  - Click "Reset to Default" to restore the original golden color
  - Choose from 12 preset colors:
    - Gold (Default) - Classic WoW gold
    - Bright Gold - Brighter golden yellow
    - White - Clean white text
    - Light Blue - Soft blue
    - Cyan - Bright aqua
    - Green - Vibrant green
    - Light Green - Softer green
    - Orange - Warm orange
    - Red - Bold red
    - Pink - Soft pink
    - Purple - Rich purple
    - Yellow - Bright yellow

All changes take effect immediately and are saved across sessions.

## Milestones

The addon tracks all 4 housing endeavor milestones:
1. 250 XP
2. 500 XP
3. 750 XP
4. 1,000 XP (max)

## Compatibility

- **WoW Version**: 12.0.0 (The War Within)
- **Interface**: 110207, 120000
- **API**: Uses `C_NeighborhoodInitiative`

## Known Issues

- The overlay only appears on hover (this is intentional to keep the UI clean)
- If the progress bar is not detected automatically, try `/et` to refresh

## Support

If you encounter any issues, try:
1. `/reload` to reload the UI
2. `/et` to manually refresh the tracker
3. Close and reopen the Housing Dashboard

## License

Free to use and modify.
