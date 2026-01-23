# Changelog

All notable changes to Endeavor Tracker addon will be documented in this file.

## [1.0.4] - 2026-01-23

### Added
- **Task XP Tooltips** (`Tooltips.lua`)
  - Automatically displays XP contribution values when hovering over tasks
  - Builds task XP cache from activity log data
  - Shows task name and contribution amount (e.g., "3.25 XP")
  - Caches data for 5 minutes to reduce API calls
  - Global tooltip enhancement system

- **Activity Log Integration**
  - Automatic activity log requests when endeavors frame opens
  - Task XP data extracted from `C_NeighborhoodInitiative.GetInitiativeActivityLogInfo()`
  - Stores highest contribution amount for each task
  - Persistent cache with time-based refresh

### Changed
- **Code Architecture** - Refactored to MVC (Model-View-Controller) pattern
  - **Model** (`Core.lua`) - Data model with API interactions, XP calculations, and task cache
  - **View** - Separated display logic into three modules:
    - `Display.lua` - XP progress overlay on the endeavors frame
    - `Tooltips.lua` - Task tooltip enhancements showing contribution XP
    - `UI.lua` - Settings panel with customization options
  - **Controller** (`EndeavorTracker.lua`) - Main controller coordinating events and commands

- **File Organization** - TOC file now uses organized sections
  - Model section: Core.lua
  - View section: Display.lua, Tooltips.lua, UI.lua
  - Controller section: EndeavorTracker.lua
  - Clear separation of concerns with comments

- **Enhanced Command System**
  - `/et refresh` now also refreshes the task XP cache
  - Better coordination between display update and tooltip data

### Improved
- **Display Module** (`Display.lua`)
  - Moved all XP progress display logic to dedicated module
  - Cleaner separation from controller logic
  - Calls to Core module for data operations
  
- **Core Module** (`Core.lua`)
  - Extracted data operations from main addon file
  - All API interactions centralized
  - Reusable calculation functions
  - Task XP caching system with automatic refresh

- **Event Handling**
  - Streamlined event processing in controller
  - Display and tooltip modules initialized on frame show
  - Activity log requested automatically when needed

### Technical Details
- Task XP cache expires after 5 minutes
- Tooltip enhancement uses global GameTooltip hooks
- ScrollBox frame detection for dynamic task list
- Activity log data structure: `taskActivity` array with `taskID`, `amount`, `taskName`

### Files Modified
- `EndeavorTracker.lua` - Reduced to controller responsibilities only
- `EndeavorTracker.toc` - Added Core.lua, Display.lua, Tooltips.lua with organized sections
- `README.md` - Updated with task tooltip feature and MVC architecture documentation

### Files Added
- `Core.lua` - New data model module
- `Display.lua` - New display view module
- `Tooltips.lua` - New tooltip view module

---

## [1.0.3] - 2026-01-23

### Added
- **New Settings UI System** (`UI.lua`)
  - Complete settings panel accessible via Game Menu → Options → AddOns
  - Integrated with WoW's native settings API
  - Settings persist across sessions using `SavedVariables`

- **Text Format Options**
  - 7 different display formats for XP information:
    1. Detailed (Default) - Shows milestone progress with context
    2. Simple - Clean format with completed milestone info
    3. Progress Bar Style - Includes percentage and visual progress
    4. Short - Compact format with essential info
    5. Minimal - Ultra-compact display
    6. Percentage Focus - Emphasizes progress percentage
    7. Next & Final - Shows XP to next and final milestones
  - Hover tooltips on format buttons showing examples
  - Real-time preview when switching formats

- **Color Customization**
  - Custom color picker for tooltip text
  - 12 preset color options:
    - Gold (Default), Bright Gold, White, Light Blue, Cyan
    - Green, Light Green, Orange, Red, Pink, Purple, Yellow
  - Visual color preview box
  - "Reset to Default" button
  - Color changes apply immediately to display

- **Enhanced Slash Commands**
  - `/et` - Opens settings panel (previously only refreshed)
  - `/et refresh` - Manually refresh the XP display
  - `/et debug` - Show detailed API milestone information with full data dump
  - `/etconfig` and `/etset` - Alternative commands to open settings
  - `/endeavortracker` - Alternative command for settings

- **API Integration**
  - Dynamic milestone threshold detection from API data
  - Fallback to hardcoded values if API data unavailable
  - Full API data storage for debugging
  - Multiple field name checks for milestone thresholds

### Changed
- **Milestone Values Updated**
  - Changed from 10 milestones (500-27,500 XP) to 4 milestones (250-1,000 XP)
  - New thresholds: 250, 500, 750, 1,000 XP (matching current game data)
  - Updated all documentation to reflect correct milestone values

- **XP Display Calculation**
  - Now shows progress between milestones instead of total XP
  - Calculates XP from previous milestone to next
  - Includes percentage progress calculation
  - Dynamically adjusts to API-provided thresholds

- **Color Management**
  - Tooltip text color now respects user settings
  - Color updates applied in both creation and update cycles
  - Settings integration via `EndeavorTrackerUI:GetColor()`

- **TOC File Updates**
  - Added `SavedVariables: EndeavorTrackerDB` for persistent settings
  - Added `UI.lua` to file load order
  - Changed author field from specific name to generic "You"

### Improved
- **Command Handling**
  - Better command parsing with whitespace trimming
  - Case-insensitive command matching
  - More descriptive help messages
  - Improved user feedback with informative print statements

- **Debug Information**
  - Enhanced `/et debug` output with structured format
  - Complete milestone data dump from API
  - All milestone fields displayed for troubleshooting
  - Better error messaging when data unavailable

- **Code Organization**
  - Separated UI logic into dedicated `UI.lua` file
  - Improved function modularity
  - Better separation of concerns between core and UI
  - Enhanced code comments and documentation

### Technical Details
- Supports WoW Interface versions: 110207, 120000
- Uses `C_NeighborhoodInitiative` API
- Compatible with The War Within (12.0.0)
- Settings saved to `EndeavorTrackerDB` SavedVariable
- Color picker supports both new and legacy ColorPickerFrame APIs

### Files Modified
- `EndeavorTracker.lua` - Core functionality updates, API integration, command improvements
- `EndeavorTracker.toc` - Added SavedVariables and UI.lua
- `README.md` - Complete documentation overhaul with new features
- `UI.lua` - New file for settings panel and customization

---

## Release Notes

This release represents a major enhancement to the addon, transforming it from a simple display tool to a fully customizable experience. Users can now personalize both the appearance and format of XP information to match their preferences.

The milestone values have been corrected to match the current game data (4 milestones up to 1,000 XP instead of the previous 10 milestones). This ensures accurate tracking and display of endeavor progress.

All settings are persistent and take effect immediately, providing a seamless configuration experience.
