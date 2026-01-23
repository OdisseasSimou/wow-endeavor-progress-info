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

- `/et` or `/endeavortracker` - Manually refresh the display

## Milestones

The addon tracks all 10 housing endeavor milestones:
1. 500 XP
2. 1,500 XP
3. 3,000 XP
4. 5,000 XP
5. 7,500 XP
6. 10,500 XP
7. 14,000 XP
8. 18,000 XP
9. 22,500 XP
10. 27,500 XP

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
