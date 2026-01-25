# EndeavorTracker - Refactoring Summary

## Overview
Refactored the addon from a flat file structure to a clean MVC (Model-View-Controller) architecture with organized folders by functionality.

## Changes Made

### Folder Structure
```
EndeavorTracker/
├── Model/              # Data layer (modular)
│   ├── Core.lua
│   ├── Progress.lua
│   ├── Tasks.lua
│   └── Neighborhoods.lua
├── View/               # UI layer
│   ├── ProgressOverlay.lua
│   ├── HouseFinderTooltips.lua
│   ├── TaskTooltips.lua
│   └── SettingsPanel.lua
├── Controller/         # Business logic
│   └── EndeavorTracker.lua
├── STRUCTURE.md        # Architecture documentation
├── README.md           # User documentation
├── CHANGELOG.md        # Version history
└── EndeavorTracker.toc # Load order definition
```

### File Changes

#### Moved & Renamed
- `Core.lua` → `Model/Core.lua`
- `Tooltips.lua` → `View/TaskTooltips.lua`
- `UI.lua` → `View/SettingsPanel.lua`
- `EndeavorTracker.lua` → `Controller/EndeavorTracker.lua`

#### Split
- `Display.lua` split into:
  - `View/ProgressOverlay.lua` (XP overlay on initiative frame)
  - `View/HouseFinderTooltips.lua` (tooltips for House Finder)
- `Model/Core.lua` refactored into modular structure:
  - `Model/Core.lua` (30 lines - base connector with shared caches)
  - `Model/Progress.lua` (67 lines - progress calculations and milestone logic)
  - `Model/Tasks.lua` (106 lines - task XP cache management and tracking)
  - `Model/Neighborhoods.lua` (330 lines - neighborhood API helpers)

#### Removed
- `Neighborhoods.lua` (browser UI, no longer needed)
- `Display.lua` (split into focused modules)

### Code Improvements

1. **Separation of Concerns**
   - Model: Pure data/API logic, no UI dependencies
   - View: Pure UI logic, no business logic
   - Controller: Coordinates between Model and View

2. **Modular Model Layer**
   - **Core.lua**: Minimal connector holding shared caches (taskXPCache, allNeighborhoodsCache) and utility functions
   - **Progress.lua**: Progress calculations (GetCurrentProgress, GetMilestoneThresholds, CalculateXPNeeded)
   - **Tasks.lua**: Task operations (BuildTaskXPCache, GetTrackedTasks, TrackTask, UntrackTask)
   - **Neighborhoods.lua**: Neighborhood helpers (GetAllNeighborhoodData, GetNeighborhoodInfo, GetMilestoneRewards)

3. **Module Exports**
   - Model exports: `EndeavorTrackerCore` (extended by Progress, Tasks, Neighborhoods modules)
   - View exports: `EndeavorTrackerDisplay`, `EndeavorTrackerHouseFinderTooltips`, `EndeavorTrackerTooltips`, `EndeavorTrackerUI`
   - Controller: Initialization only, no exports

4. **Clear Responsibilities**
   - Each model file has focused functionality (533 lines → 4 focused modules)
   - `ProgressOverlay.lua`: Endeavor frame XP display only
   - `HouseFinderTooltips.lua`: House Finder tooltips only
   - Each file has one focused purpose

5. **Better Maintainability**
   - Easy to locate features by folder and file name
   - Clear data flow: Model → Controller → View
   - No circular dependencies
   - Reduced file complexity (largest file now ~330 lines vs 533)

### TOC Update
Load order now explicitly shows layer separation with modular model:
```lua
# Model - Data layer (modular structure)
Model\Core.lua
Model\Progress.lua
Model\Tasks.lua
Model\Neighborhoods.lua

# View - UI layer
View\ProgressOverlay.lua
View\HouseFinderTooltips.lua
View\TaskTooltips.lua
View\SettingsPanel.lua

# Controller - Business logic
Controller\EndeavorTracker.lua
```

### Documentation Added
- `STRUCTURE.md`: Complete architecture guide
- Updated `README.md`: Reflects current features and structure
- Inline comments: Clearer module descriptions

## Benefits

1. **Easier Navigation**: Find code by responsibility (Model/View/Controller) and by functionality within Model layer
2. **Better Testing**: Isolated modules can be tested independently
3. **Simpler Debugging**: Clear boundaries between layers and focused files
4. **Easier Feature Addition**: Know exactly where new code belongs
5. **Team Collaboration**: Clear structure helps multiple developers
6. **Reduced Coupling**: Modules depend only on contracts, not implementations
7. **Improved Readability**: No file exceeds 330 lines, down from 533-line monolithic Core.lua
8. **Focused Functionality**: Each model file has a single responsibility

## Breaking Changes
None - all functionality remains the same, only internal structure changed.

## Future Improvements
- ~~Consider splitting Core.lua into smaller focused modules~~ ✓ **COMPLETED**
  - Core.lua refactored into Core (connector), Progress, Tasks, and Neighborhoods modules
- Add unit tests for Model layer modules
- Add integration tests for View components
- Consider further optimization of Neighborhoods.lua if needed
