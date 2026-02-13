# Changelog

All notable changes to Endeavor Tracker addon will be documented in this file.

## [1.1.7] - 2026-02-13

### Fixed
- Fixed background to match text width

## [1.1.6] - 2026-02-13

### Fixed
- Fixed forbidden table errors when accessing protected WoW UI frames during frame scanning in `ProgressOverlay.lua`
  - Added `SafeCall`, `SafeGetName`, and `SafeGetObjectType` helper functions to safely access frame properties
  - Improved error handling for protected frame access during candidate collection

## [1.1.5] - 2026-01-30

### UI Improvements
- Removed text on frame (caused bad interactions)
- Added black background to the text

### Credits
- **Contributors**: Added `n17r091` to the Contributors field in `EndeavorTracker.toc` for proper credit.

### Technical
- **Robustness Improvements** (`ProgressOverlay.lua`):
  - Added `SafeCall`, `SafeGetName`, and `SafeGetObjectType` helper functions to safely access frame properties and methods, preventing errors from protected or missing methods.
  - Refactored candidate collection logic to use these helpers, improving error resilience when scanning UI frames.



## [1.1.4] - 2026-01-26

### Bugfix
- Fixed issue with tooltip hooking on wrong frames

## [1.1.3] - 2026-01-25

### Bugfix
- Fixed lua error due to leftover quote

## [1.1.2] - 2026-01-25

### Added
- **Modular Code Architecture**
  - Split Model layer into separate specialized modules:
    - `Progress.lua` - Milestone thresholds and XP calculations
    - `Tasks.lua` - Task XP cache management and tracking operations
    - `Neighborhoods.lua` - Neighborhood initiative data and housing API helpers
  - Updated `EndeavorTracker.toc` to load new Model files in correct order
  - Improved code organization and maintainability

### Changed
- **Core.lua Refactoring**
  - Reduced `Core.lua` to base connector with shared caches only
  - Moved all neighborhood-related functions to `Neighborhoods.lua`
  - Moved all task tracking functions to `Tasks.lua`
  - Moved progress calculation functions to `Progress.lua`
  - Maintains backward compatibility with global `EndeavorTrackerCore` export
  - Cache variables now use `or` operator for safer initialization

- **Controller Simplification** (`EndeavorTracker.lua`)
  - Removed debug and neighborhood browsing slash commands:
    - `/et neighborhoods`, `/et nbh` - moved to dedicated module
    - `/et nbhdebug`, `/et nbd` - debug commands removed
    - `/et tracked`, `/et mytasks` - task listing removed
    - `/et requirements`, `/et reqs` - requirements check removed
    - `/et list`, `/et allnbh` - neighborhood list removed
    - `/et show`, `/et show list` - cached list display removed
  - Reduced command handler from 507 lines to 307 lines
  - Focus on core leaderboard and task logging functionality

- **UI Improvements**
  - Standardized tooltip text in `TaskTooltips.lua`: Changed "Contribution:" to "Endeavor Contribution:"
  - Applies consistently across all tooltip display methods
  - More descriptive XP contribution label

### Improved
- **Documentation** (`README.md`)
  - Reorganized Commands section with clear categories: Settings, Data Management, Leaderboard, Debug
  - Added slash command aliases and descriptions
  - Updated Code Structure section with detailed module breakdown
  - Added debugging tips section with specific commands
  - Clarified functionality and command purposes

### Technical Details
- Model layer now follows single-responsibility principle with specialized modules
- All cache initialization prevents nil reference errors with safer patterns
- Reduced controller complexity for easier maintenance and future extensions
- Better separation of concerns: Core connector, Progress logic, Task management, Neighborhood data

### Files Modified
- `Model/Core.lua` - Refactored to base connector (131 lines → 32 lines)
- `Controller/EndeavorTracker.lua` - Removed 200+ lines of debug/neighborhood commands
- `EndeavorTracker.toc` - Added new Model file loads
- `View/TaskTooltips.lua` - Standardized tooltip labels
- `README.md` - Improved documentation and command reference
- (New) `Model/Progress.lua` - Milestone and XP calculation functions
- (New) `Model/Tasks.lua` - Task cache and tracking operations
- (New) `Model/Neighborhoods.lua` - Neighborhood initiative and housing API support

### Files Added
- `Model/Progress.lua` - Progress calculations and milestone logic
- `Model/Tasks.lua` - Task XP cache management and tracking
- `Model/Neighborhoods.lua` - Neighborhood data and housing API interaction

---

## [1.1.1] - 2026-01-24

### Fixed
- **Protected Frame Handling** (`TaskTooltips.lua`)
  - Added `pcall()` wrapping for tooltip text access to prevent errors during combat/raids
  - Safely handles protected frame data when accessing tooltip text
  - Prevents addon from breaking when tooltips are shown in protected contexts
  - Applies protection to both duplicate detection and task name matching

### Improved
- **Error Resilience**
  - Tooltip enhancement now gracefully handles WoW's protected value restrictions
  - No more "cannot read a protected value" errors during combat or raids
  - Maintains full functionality in non-protected contexts

### Technical Details
- Wrapped `GetText()` calls with `pcall()` for safe access to potentially protected values
- Three protected access points: duplicate line detection and task name comparison
- Documentation updated in README to reflect protected value handling

### Files Modified
- `View/TaskTooltips.lua` - Added pcall() protection for tooltip text access
- `README.md` - Added Protected Value Handling to Technical Details section

---

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
