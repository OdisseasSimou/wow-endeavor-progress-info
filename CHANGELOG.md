# Changelog

All notable changes to Endeavor Tracker addon will be documented in this file.

## [1.1.0] - 2026-01-24

### Added
- **Code Restructuring - MVC Architecture**
  - Refactored codebase into Model-View-Controller pattern
  - Better code organization and maintainability
  - Clean separation of concerns:
    - Model: `Core.lua` - Data layer, API interactions, calculations
    - View: `ProgressOverlay.lua`, `HouseFinderTooltips.lua`, `TaskTooltips.lua`, `SettingsPanel.lua` - UI layer
    - Controller: `EndeavorTracker.lua` - Business logic, event handling, commands

- **House Finder Tooltips** (`HouseFinderTooltips.lua`)
  - Hover over neighborhood entries in Blizzard's House Finder to see endeavor progress
  - Displays current endeavor name and milestone progress
  - Shows completion percentage for each neighborhood
  - Real-time updates via `NEIGHBORHOOD_LIST_UPDATED` and `HOUSE_FINDER_NEIGHBORHOOD_DATA_RECIEVED` events
  - Multi-neighborhood support using `C_Housing` API

- **Settings Panel UI** (`SettingsPanel.lua`)
  - Comprehensive settings interface for customization
  - Integrated with WoW's built-in settings system
  - Professional UI design with backdrops and styling

- **Text Format Presets**
  - 7 different text format options for XP tooltips:
    - Detailed (Default): "Milestone 2: 125 / 250 (125 XP needed)"
    - Simple: "125 XP to reach Milestone 2 (completed: M1)"
    - Progress Bar Style: "M2 Progress: 125/250 (50%) - 125 XP to go"
    - Short: "To Milestone 2: 125 XP remaining"
    - Minimal: "125 XP to next milestone"
    - Percentage Focus: "50% to M2 - 125 XP needed"
    - Next & Final: "Next: 125 XP | Final: 875 XP"
  - Preset buttons with example tooltips on hover
  - Real-time display updates when format changes

- **Color Customization**
  - Custom color picker for XP tooltip text
  - 12 color presets:
    - Gold (Default), Bright Gold, White, Light Blue
    - Cyan, Green, Light Green, Orange
    - Red, Pink, Purple, Yellow
  - Color preview box showing selected color
  - Reset to Default button
  - Persistent color storage in saved variables

- **Settings Persistence**
  - Saved variables system (`EndeavorTrackerDB`)
  - Persists color and text format preferences between sessions
  - Automatic initialization of defaults on first load

### Changed
- **Code Organization** 
  - Refactored files into organized folder structure (Model/, View/, Controller/)
  - Updated `.toc` file with new directory structure and comments
  - Improved code comments and documentation in `.toc` file

- **Settings System Enhancement** (`EndeavorTracker.lua`)
  - Now references new SettingsPanel.lua for UI handling
  - Updated initialization to create settings panel on addon load
  - Updated help message to reflect settings access

- **README Documentation**  
  - Added House Finder feature documentation
  - Updated API documentation to reference both `C_NeighborhoodInitiative` and `C_Housing`
  - Updated Housing Dashboard keyboard shortcut (H instead of Shift+P)
  - Added MVC Architecture to features list
  - Added detailed technical documentation for event listeners and API usage

### Improved
- **User Interface**
  - Better organization of customization options
  - Clearer visual feedback for selected options
  - Tooltip examples help users preview format changes

- **Code Quality**
  - Modular, maintainable architecture with MVC pattern
  - Better separation of concerns
  - More organized folder structure
  - Enhanced code documentation and comments

- **Multi-Neighborhood Support**
  - Integrated `C_Housing` API for neighborhood enumeration
  - Automatic neighborhood discovery and updates
  - Real-time event handling for neighborhood changes

### Release Notes

Version 1.1.0 represents a significant modernization of Endeavor Tracker with a complete architectural refactor and exciting new features. The codebase has been restructured following the Model-View-Controller (MVC) pattern, making the addon more maintainable and extensible for future development.

The star feature of this release is the new **House Finder Tooltips**, which brings endeavor progress information directly to the House Finder interface. Players can now hover over neighborhoods in the House Finder to instantly see the current endeavor milestone progress and completion percentage, making neighborhood selection more informed and efficient.

Additionally, the settings system has been significantly enhanced with improved UI/UX, giving users full control over how they want to display their XP information. All customizations are persistent and take effect immediately.

This release focuses on code quality and user experience improvements while laying the groundwork for future feature additions.

---


## [1.0.6] - 2026-01-23

### Added
- **Leaderboard Command** (`/et leaderboard`, `/et top`, `/et top10`)
  - Shows top 10 contributors based on activity log
  - Aggregates total XP contribution per player
  - Displays player rankings with total XP amounts
  - Shows total number of activity log entries analyzed

- **Neighborhood Scanner** (`/et neighborhood`, `/et neighborhoods`, `/et nbh`)
  - Scans all neighborhood IDs (1-100) for active initiatives
  - Displays information for each found neighborhood:
    - Neighborhood title and ID
    - Current progress vs required progress
    - Milestone completion status
    - Active neighborhood indicator
  - Automatically resets to active neighborhood after scanning

- **Task Log Debug Command** (`/et tasklog`, `/et logdebug`)
  - Shows detailed activity log analysis
  - Lists all unique tasks with their details:
    - Task ID, name, and XP contribution
    - Completion count from activity log
    - Most recent player who completed the task
  - Formatted table output for easy reading
  - Displays total number of unique tasks

### Changed
- **Task XP Cache Behavior** (`Core.lua`)
  - Removed 5-minute cache duration limit
  - Now always rebuilds from fresh activity log data
  - Ensures real-time accuracy of task XP values
  - Eliminates stale cache issues

- **README Documentation**
  - Updated cache behavior description (no longer time-based)
  - Clarified that data updates automatically from activity log
  - Removed references to 5-minute cache expiration
  - Simplified Known Issues section

### Improved
- **Command System**
  - Added three new debug/information commands
  - Better organization of command handling logic
  - More informative output formatting
  - Enhanced data visualization with structured reports

- **Activity Log Usage**
  - More comprehensive utilization of activity log data
  - Player name aggregation for leaderboards
  - Neighborhood switching for multi-neighborhood support
  - Task-level detail inspection

### Files Modified
- `Core.lua` - Removed time-based cache expiration logic
- `EndeavorTracker.lua` - Added leaderboard, neighborhood scanner, and task log commands
- `README.md` - Updated cache behavior documentation

---

## [1.0.5] - 2026-01-23

### Added
- **Cache Purge Functionality**
  - Manual cache clearing with `/et refresh` command
  - Ensures fresh task XP data on demand

### Changed
- **Task XP Cache Logic** (`Core.lua`)
  - Now uses most recent completion time instead of highest amount
  - Stores `completionTime` field for each cached task
  - Ensures task XP reflects most recent completion, not highest contribution
  - Requests fresh activity log data when building cache

- **Refresh Command Enhancement** (`EndeavorTracker.lua`)
  - Now purges task XP cache before refreshing
  - Explicitly requests activity log data
  - Extended wait time to 1 second for API data to be ready
  - Rebuilds cache after API request completes
  - Updated feedback message to indicate cache purge

### Fixed
- **Task XP Accuracy**
  - Fixed issue where cache stored highest XP amount instead of most recent
  - Task tooltips now accurately reflect current XP values based on last completion
  - Prevents outdated XP values from being displayed

### Improved
- **Cache Reliability**
  - More robust cache refresh mechanism
  - Better coordination between API requests and cache building
  - Documentation clarifies cache uses most recent completion

### Files Modified
- `Core.lua` - Updated task cache to use completion time instead of highest amount
- `EndeavorTracker.lua` - Enhanced refresh command with cache purge
- `EndeavorTracker.toc` - Author field updated
- `README.md` - Clarified cache behavior and decimal precision documentation

---

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
