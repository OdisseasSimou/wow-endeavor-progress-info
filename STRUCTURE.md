# Endeavor Tracker - Code Structure

## Architecture

This addon follows the **MVC (Model-View-Controller)** pattern for clean separation of concerns and maintainability.

### Model Layer (`Model/`)
**Purpose**: Data management, API interactions, business logic

The Model layer uses a modular architecture where Core.lua acts as a connector with shared caches, extended by specialized modules:

- **Core.lua** (30 lines): 
  - Base connector holding shared caches (`taskXPCache`, `allNeighborhoodsCache`)
  - Global export of `EndeavorTrackerCore` to `_G`
  - Utility functions (`CountTableEntries`)
  - Default milestone thresholds

- **Progress.lua** (67 lines):
  - Progress calculations and milestone logic
  - `GetCurrentProgress()` - Fetches current initiative progress from API
  - `GetMilestoneThresholds()` - Extracts milestone thresholds with fallback
  - `CalculateXPNeeded()` - Calculates XP to next milestone

- **Tasks.lua** (106 lines):
  - Task XP cache management and tracking operations
  - `BuildTaskXPCache()` - Builds task XP cache from activity log
  - `GetTrackedTasks()`, `TrackTask()`, `UntrackTask()` - Task tracking helpers
  - `GetTaskInfo()`, `IsTaskTracked()` - Task query functions

- **Neighborhoods.lua** (330 lines):
  - Neighborhood initiative data and housing API helpers
  - `GetAllNeighborhoodData()` - Fetches all accessible neighborhoods
  - `GetNeighborhoodInfo()` - Detailed neighborhood initiative data
  - `GetMilestoneRewards()` - Reward information per milestone
  - `RequestAllNeighborhoods()`, `CacheNeighborhoodList()` - C_Housing API integration
  - `GetQuickNeighborhoodInitiativeData()` - Fast progress fetching

### View Layer (`View/`)
**Purpose**: User interface components and visual presentation

- **ProgressOverlay.lua**: 
  - XP progress overlay on the neighborhood initiative frame
  - Hover tooltip showing XP needed for next milestone
  - Text formatting and display updates
  - Progress bar detection and overlay positioning

- **HouseFinderTooltips.lua**:
  - Tooltips for Blizzard's House Finder neighborhood list
  - Shows endeavor progress when hovering neighborhood entries
  - Handles both regular and BNet neighborhood buttons
  - Retry logic for loading endeavor data

- **TaskTooltips.lua**:
  - Enhanced tooltips for initiative tasks
  - Shows "Endeavor Contribution: X.XX XP" for individual tasks
  - Task-specific information display
  - Reads from Model's taskXPCache

- **SettingsPanel.lua**:
  - Settings UI panel
  - Color picker for text customization
  - Text format selection (detailed, simple, progress, etc.)
  - Settings persistence via SavedVariables

### Controller Layer (`Controller/`)
**Purpose**: Event coordination, user commands, initialization

- **EndeavorTracker.lua**:
  - Event handling (initiative updates, task completion, etc.)
  - Slash command processing (`/et`, `/et refresh`, `/et leaderboard`, etc.)
  - Addon initialization and module coordination
  - Timer-based updates and refresh logic

## Data Flow

1. **User Action** → Controller receives event/command
2. **Controller** → Requests data from Model
3. **Model** → Fetches from API, processes, returns data
4. **Controller** → Passes data to View
5. **View** → Updates UI elements

## Module Communication

- **Model** exports: `EndeavorTrackerCore` (extended by Progress, Tasks, and Neighborhoods modules)
- **View** exports: 
  - `EndeavorTrackerDisplay`
  - `EndeavorTrackerHouseFinderTooltips`
  - `EndeavorTrackerTooltips`
  - `EndeavorTrackerUI`
- **Controller** exports: None (initialization only)

All Model modules extend the same `EndeavorTrackerCore` table, providing a unified interface.

## File Loading Order

Files are loaded in this specific order (defined in `.toc`):
1. **Model layer** (in order of dependency):
   - Core.lua (base connector)
   - Progress.lua (extends Core)
   - Tasks.lua (extends Core)
   - Neighborhoods.lua (extends Core)
2. **View layer** (all UI components)
3. **Controller layer** (event handlers and commands)

This ensures dependencies are available when needed and all Model functions are loaded before Views access them.

## Key Design Principles

1. **Separation of Concerns**: Each module has a single, well-defined responsibility
2. **Modular Model Layer**: Core.lua acts as connector, specialized modules extend functionality
3. **No Circular Dependencies**: Model doesn't know about View/Controller
4. **Global Exports**: Modules export to `_G` for cross-module communication
5. **Event-Driven**: Controller coordinates via WoW event system
6. **Lazy Loading**: UI components hook only when needed
7. **Focused Files**: No file exceeds 330 lines for better maintainability

## Adding New Features

### New Model Function
- For progress calculations: Add to `Model/Progress.lua`
- For task operations: Add to `Model/Tasks.lua`
- For neighborhood data: Add to `Model/Neighborhoods.lua`
- For shared caches/utilities: Add to `Model/Core.lua`

All functions extend `EndeavorTrackerCore` using the colon syntax.

### New UI Component
Create in `View/` folder, add to `.toc`, export to `_G`

### New Command/Event
Add handler in `Controller/EndeavorTracker.lua`
