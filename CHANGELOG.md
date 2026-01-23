# Changelog

All notable changes to Endeavor Tracker addon will be documented in this file.

## [1.0.0] - 2026-01-23

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
