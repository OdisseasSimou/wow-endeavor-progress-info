# Endeavor Tracker

A World of Warcraft addon that displays XP progress for housing endeavor milestones with customizable display options and automatic tooltips.

## Features

- **XP Progress Display** - Shows XP needed for the next milestone on hover over the progress bar
- **House Finder Tooltips** - Hover neighborhood entries in Blizzard's House Finder to see endeavor progress
- **Task XP Tooltips** - Automatically displays contribution XP values when hovering over tasks
- **7 Display Formats** - Choose from detailed, simple, progress bar, short, minimal, percentage, or next & final formats
- **12 Color Presets** - Customize text color with preset options or custom color picker
- **Decimal Precision** - All values display with 1 decimal place for accuracy
- **Dynamic API Integration** - Automatically reads milestone data from the game API
- **Clean UI** - Non-intrusive tooltip-style overlays that appear only when needed
- **Automatic Updates** - Refreshes when you earn XP or complete tasks
- **MVC Architecture** - Clean, maintainable code structure following Model-View-Controller pattern

## Installation

1. Extract the `EndeavorTracker` folder to your WoW AddOns directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```

2. Restart WoW or type `/reload` in-game

## Usage

### XP Progress Display
1. Open the Housing Dashboard (Press `H` or click the Housing icon)
2. Navigate to the **Endeavors** tab
3. Hover over the endeavor progress bar to see your XP progress

### House Finder Tooltips
1. Open the House Finder (social menu or housing button)
2. Hover over any neighborhood in the list
3. View the current endeavor name, milestone progress, and completion percentage

### Task XP Tooltips
- Hover over any task in the Endeavors tab to see its contribution XP value
- The addon automatically reads XP data from your activity log (most recent completion)
- Tooltips show the task name and contribution amount (e.g., "0.65 XP")
- Data updates automatically when the activity log changes

## Commands

- `/et` - Open settings panel

## Settings

Access the settings panel through:
- **Game Menu → Options → AddOns → Endeavor Tracker**
- Or use the command: `/et`

### Text Format Options
Choose how the XP information is displayed (all values show 1 decimal place):

1. **Detailed (Default)** - `Milestone 2: 125.0 / 250.0 (125.0 XP needed)`
2. **Simple** - `125.0 XP to reach Milestone 2 (completed: M1)`
3. **Progress Bar Style** - `M2 Progress: 125.0/250.0 (50.0%) - 125.0 XP to go`
4. **Short** - `To Milestone 2: 125.0 XP remaining`
5. **Minimal** - `125.0 XP to next milestone`
6. **Percentage Focus** - `50.0% to M2 - 125.0 XP needed`
7. **Next & Final** - `Next: 125.0 XP | Final: 875.0 XP`

### Color Options
- **Tooltip Text Color** - Change the color of the XP display text (default: golden)
  - Click the color box to open the color picker for custom colors
  - Click "Reset to Default" to restore the original golden color
  - Choose from 12 preset colors:
    - Gold (Default), Bright Gold, White, Light Blue
    - Cyan, Green, Light Green, Orange
    - Red, Pink, Purple, Yellow

All changes take effect immediately and are saved across sessions.

## Milestones

The addon tracks all 4 housing endeavor milestones:
1. **250 XP** - First milestone
2. **500 XP** - Second milestone
3. **750 XP** - Third milestone
4. **1,000 XP** - Maximum (final milestone)

Milestone values are automatically read from the game API with fallback to these hardcoded values if API data is unavailable.

## Code Structure

The addon follows an MVC (Model-View-Controller) architecture:

- **Model** - `Core.lua` - Data model with API interactions, XP calculations, and task cache
- **View**
  - `Display.lua` - XP progress overlay on the endeavors frame
  - `Tooltips.lua` - Task tooltip enhancements showing contribution XP
  - `UI.lua` - Settings panel with customization options
- **Controller** - `EndeavorTracker.lua` - Main controller coordinating events and commands

## Compatibility

- **WoW Version**: 12.0.1 (The War Within)
- **Interface**: 110207, 120000
- **APIs**: Uses `C_NeighborhoodInitiative` and `C_Housing` APIs
  - C_NeighborhoodInitiative for active neighborhood initiative data
  - C_Housing for multi-neighborhood enumeration and discovery

## Technical Details

- **SavedVariables**: `EndeavorTrackerDB` stores color and text format preferences
- **Task XP Cache**: Built from activity log using most recent completion time for each task
- **Cache Behavior**: Rebuilds automatically from activity log when needed for real-time accuracy
- **Percentage Calculations**: Shows progress between milestones (not total progress)
- **Decimal Precision**: All numeric values display with 2 decimal places
- **Tooltip Enhancement**: Automatically detects and enhances task tooltips without duplicate entries
- **Protected Value Handling**: Uses pcall() wrapping for safe tooltip text access during combat/raids where frame data is protected by WoW
- **Multi-Neighborhood API**: Uses C_Housing.HouseFinderRequestNeighborhoods() to enumerate accessible neighborhoods
- **Real-Time Events**: Listens to NEIGHBORHOOD_LIST_UPDATED and HOUSE_FINDER_NEIGHBORHOOD_DATA_RECIEVED events
- **Event Listeners**: Monitors 8 events for real-time updates (NEIGHBORHOOD_INITIATIVE_UPDATED, INITIATIVE_ACTIVITY_LOG_UPDATED, INITIATIVE_TASK_COMPLETED, INITIATIVE_COMPLETED, INITIATIVE_TASKS_TRACKED_LIST_CHANGED, NEIGHBORHOOD_LIST_UPDATED, HOUSE_FINDER_NEIGHBORHOOD_DATA_RECIEVED, PLAYER_ENTERING_WORLD)

## Known Issues

- The XP overlay only appears on hover (intentional design to keep UI clean)
- Task tooltips show XP based on your most recent completion of each task from the activity log
- If the progress bar is not detected automatically, try `/et refresh`

## Support

If you encounter any issues, try:
1. `/reload` to reload the UI
2. `/et refresh` to manually refresh the tracker and task cache
3. Close and reopen the Housing Dashboard

## License

Free to use and modify.
