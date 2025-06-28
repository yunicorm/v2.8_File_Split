# Configuration Validation Rules and Dependencies

This document provides comprehensive documentation of the Config.ini validation rules, interdependencies, and configuration management mechanisms in the Path of Exile automation macro.

## Configuration Validation Specifications

### Core Validation System

The configuration validation system consists of three main components:

#### 1. ConfigManager.ahk - Core Validation Engine
- **Location**: `/Utils/ConfigManager.ahk`
- **Function**: `InitializeValidationRules()` (lines 32-78)
- **Purpose**: Defines validation rules for core configuration sections

#### 2. SettingsValidation.ahk - GUI Input Validation
- **Location**: `/UI/SettingsWindow/SettingsValidation.ahk`
- **Function**: `ValidateAllSettings()` (lines 7-25)
- **Purpose**: Real-time validation of user input in settings GUI

#### 3. Default Configuration Generation
- **Location**: `/Utils/ConfigManager.ahk`
- **Function**: `CreateDefaultConfig()` (lines 422-562)
- **Purpose**: Generates complete default configuration on first run

## Complete Configuration Sections and Validation Rules

### [General] Section
| Setting | Type | Range | Default | Purpose |
|---------|------|-------|---------|---------|
| DebugMode | boolean | true/false | false | Enables debug logging and displays |
| LogEnabled | boolean | true/false | true | Controls log file generation |
| MaxLogSize | integer | 1-100 | 10 | Maximum log file size (MB) |
| LogRetentionDays | integer | 1-365 | 7 | Days to retain log files |
| AutoStart | boolean | true/false | false | Auto-start macro on application launch |
| AutoStartDelay | integer | 0-30000 | 2000 | Delay before auto-start (ms) |
| AutoSaveConfig | string | - | true | Saves config changes automatically |

#### Hidden General Settings
- **SkillEnabled** - Used in Main.ahk:253 (not in default config)
- **FlaskEnabled** - Used in Main.ahk:261 (not in default config)

### [Resolution] Section
| Setting | Type | Range | Default | Purpose |
|---------|------|-------|---------|---------|
| ScreenWidth | integer | 800-7680 | 3440 | Current screen width (supports up to 8K) |
| ScreenHeight | integer | 600-4320 | 1440 | Current screen height (supports up to 8K) |

**Auto-correction Logic**: Invalid resolutions are automatically corrected to 3440x1440 (ultrawide base resolution).

### [Mana] Section
| Setting | Type | Range | Default | Purpose |
|---------|------|-------|---------|---------|
| CenterX | integer | 0-7680 | 3294 | Mana orb center X coordinate |
| CenterY | integer | 0-4320 | 1300 | Mana orb center Y coordinate |
| Radius | integer | 10-500 | 139 | Mana orb detection radius |
| BlueThreshold | integer | 0-255 | 40 | Blue color detection threshold |
| BlueDominance | integer | 0-255 | 20 | Blue dominance for mana detection |
| MonitorInterval | integer | 10-1000 | 100 | Mana monitoring frequency (ms) |
| OptimizedDetection | boolean | true/false | true | Enables performance optimization |

**Coordinate Scaling**: All coordinates automatically scale from base resolution (3440x1440) to current resolution.

### [Tincture] Section
| Setting | Type | Range | Default | Purpose |
|---------|------|-------|---------|---------|
| RetryMax | integer | 1-10 | 5 | Maximum retry attempts |
| RetryInterval | integer | 100-5000 | 500 | Interval between retries (ms) |
| VerifyDelay | integer | 100-5000 | 1000 | Delay before verification (ms) |
| DepletedCooldown | integer | 1000-10000 | 5410 | Cooldown when mana depleted (ms) |

### [Keys] Section
| Setting | Type | Range | Default | Purpose |
|---------|------|-------|---------|---------|
| Tincture | string | Valid key | 3 | Tincture activation key |
| ManaFlask | string | Valid key | 2 | Mana flask key |
| SkillE | string | Valid key | E | Skill E key |
| SkillR | string | Valid key | R | Skill R key |
| SkillT | string | Valid key | T | Skill T key |
| WineProphet | string | Valid key | 4 | Wine of the Prophet key |

**Key Validation**: Uses HotkeyValidator.ahk for conflict detection and normalization.

### [Timing] Section (Legacy System)
| Setting | Type | Range | Default | Purpose |
|---------|------|-------|---------|---------|
| SkillER_Min | integer | 100-10000 | 1000 | Minimum E/R skill interval (ms) |
| SkillER_Max | integer | 100-10000 | 1100 | Maximum E/R skill interval (ms) |
| SkillT_Min | integer | 100-20000 | 4100 | Minimum T skill interval (ms) |
| SkillT_Max | integer | 100-20000 | 4200 | Maximum T skill interval (ms) |
| Flask_Min | integer | 100-20000 | 4500 | Minimum flask interval (ms) |
| Flask_Max | integer | 100-20000 | 4800 | Maximum flask interval (ms) |

**Min/Max Validation**: Ensures Min ≤ Max relationships with auto-correction.

### [Wine] Section (Dynamic Timing Stages)
| Setting | Type | Range | Default | Purpose |
|---------|------|-------|---------|---------|
| Stage1_Time | integer | 0-999999 | 60000 | Stage 1 start time (ms) |
| Stage1_Min | integer | 100-30000 | 22000 | Stage 1 min interval (ms) |
| Stage1_Max | integer | 100-30000 | 22500 | Stage 1 max interval (ms) |
| Stage2_Time | integer | 0-999999 | 90000 | Stage 2 start time (ms) |
| Stage2_Min | integer | 100-30000 | 19500 | Stage 2 min interval (ms) |
| Stage2_Max | integer | 100-30000 | 20000 | Stage 2 max interval (ms) |
| Stage3_Time | integer | 0-999999 | 120000 | Stage 3 start time (ms) |
| Stage3_Min | integer | 100-30000 | 17500 | Stage 3 min interval (ms) |
| Stage3_Max | integer | 100-30000 | 18000 | Stage 3 max interval (ms) |
| Stage4_Time | integer | 0-999999 | 170000 | Stage 4 start time (ms) |
| Stage4_Min | integer | 100-30000 | 16000 | Stage 4 min interval (ms) |
| Stage4_Max | integer | 100-30000 | 16500 | Stage 4 max interval (ms) |
| Stage5_Min | integer | 100-30000 | 14500 | Stage 5 min interval (ms) |
| Stage5_Max | integer | 100-30000 | 15000 | Stage 5 max interval (ms) |

**Progressive Validation**: Stage times must be in chronological order (Stage1_Time < Stage2_Time < Stage3_Time < Stage4_Time).

### [ClientLog] Section
| Setting | Type | Range | Default | Purpose |
|---------|------|-------|---------|---------|
| Enabled | boolean | true/false | true | Enables log file monitoring |
| Path | string | Valid path | Steam path | Path to Client.txt |
| CheckInterval | integer | 50-5000 | 250 | Log check frequency (ms) |
| RestartInTown | boolean | true/false | false | Restart automation in town |

### [LoadingScreen] Section
| Setting | Type | Range | Default | Purpose |
|---------|------|-------|---------|---------|
| Enabled | boolean | true/false | false | Enables loading screen detection |
| CheckInterval | integer | 50-5000 | 250 | Check frequency (ms) |
| GearAreaOffset | integer | 0-1000 | 200 | Gear area detection offset |
| DarkThreshold | integer | 0-255 | 50 | Dark pixel threshold |

### [UI] Section
| Setting | Type | Range | Default | Purpose |
|---------|------|-------|---------|---------|
| StatusWidth | integer | 100-1000 | 220 | Status display width |
| StatusHeight | integer | 50-500 | 150 | Status display height |
| StatusOffsetY | integer | 0-2000 | 250 | Vertical offset from top |
| OverlayFontSize | integer | 8-72 | 28 | Overlay text font size |
| OverlayDuration | integer | 500-10000 | 2000 | Overlay display duration (ms) |
| OverlayTransparency | integer | 0-255 | 220 | Overlay transparency (255=opaque) |

### [Performance] Section
| Setting | Type | Range | Default | Purpose |
|---------|------|-------|---------|---------|
| ManaSampleRate | integer | 1-50 | 5 | Mana detection sample rate |
| ColorDetectTimeout | integer | 10-500 | 50 | Color detection timeout (ms) |
| MonitoringEnabled | boolean | true/false | false | Performance monitoring |

#### Hidden Performance Settings
- **MonitoringEnabled** - Used in Main.ahk:403 but missing from validation rules

### [Flask] Section (New System - Not in Default Config)
For each flask (1-5):
| Setting | Type | Range | Default | Purpose |
|---------|------|-------|---------|---------|
| Flask{n}_Enabled | boolean | true/false | varies | Enable/disable flask |
| Flask{n}_Key | string | Valid key | varies | Flask activation key |
| Flask{n}_Min | integer | 100-30000 | varies | Minimum interval (ms) |
| Flask{n}_Max | integer | 100-30000 | varies | Maximum interval (ms) |
| Flask{n}_Type | string | enum | varies | Life/Mana/Utility/Quicksilver/Unique |

**Critical Issue**: Flask section is not included in ConfigManager sections array, preventing automatic loading.

### [Skill] Section (New System - Not in Default Config)
For each skill (1_1 through 2_5):
| Setting | Type | Range | Default | Purpose |
|---------|------|-------|---------|---------|
| Skill_{g}_{n}_Enabled | boolean | true/false | varies | Enable/disable skill |
| Skill_{g}_{n}_Name | string | - | varies | Display name |
| Skill_{g}_{n}_Key | string | Valid key | varies | Skill activation key |
| Skill_{g}_{n}_Min | integer | 100-30000 | varies | Minimum interval (ms) |
| Skill_{g}_{n}_Max | integer | 100-30000 | varies | Maximum interval (ms) |
| Skill_{g}_{n}_Priority | integer | 1-5 | varies | Priority level (1=highest) |

**Critical Issue**: Skill section is not included in ConfigManager sections array, preventing automatic loading.

## Interdependent Configuration Items

### Min/Max Value Pairs
All Min/Max pairs are validated to ensure Min ≤ Max:
- **Flask intervals**: Flask{n}_Min ≤ Flask{n}_Max
- **Skill intervals**: Skill_{g}_{n}_Min ≤ Skill_{g}_{n}_Max
- **Legacy timing**: SkillER_Min ≤ SkillER_Max, etc.
- **Wine stages**: Stage{n}_Min ≤ Stage{n}_Max

### Resolution-Dependent Settings
**Primary Setting**: [Resolution] ScreenWidth/ScreenHeight
**Affected Settings**:
- [Mana] CenterX, CenterY, Radius (auto-scaled)
- [UI] StatusOffsetY (relative positioning)
- All coordinate-based validations

**Scaling Formula**:
```
ScaledX = Round(OriginalX * CurrentWidth / 3440)
ScaledY = Round(OriginalY * CurrentHeight / 1440)
```

### Wine Stage Progression
**Constraint**: Stage1_Time < Stage2_Time < Stage3_Time < Stage4_Time
**Auto-correction**: Invalid sequences reset with 30-second increments

### Settings That Affect Other Settings
- **OptimizedDetection**: Affects mana monitoring behavior
- **DebugMode**: Changes logging verbosity and display options
- **Enabled flags**: Flask/Skill enabled states control validation requirements

### Missing Interdependency Validations
1. **Duplicate key detection**: No validation for duplicate keys across flasks/skills
2. **Priority conflicts**: Multiple skills can have identical priorities
3. **Performance parameter relationships**: No cross-validation of timing parameters
4. **File path dependencies**: Client log path not validated for accessibility

## Dynamic Validation Rules

### HotkeyValidator Implementation
- **Key normalization**: Standardizes modifier key order (Ctrl→Alt→Shift→Win)
- **Conflict detection**: Maintains Map of registered hotkeys
- **Platform validation**: Windows-specific hotkey patterns
- **Modifier handling**: Supports ^(Ctrl), !(Alt), +(Shift), #(Win) combinations

### Context-Dependent Validation
- **Conditional requirements**: Empty keys only invalid when corresponding feature is enabled
- **Resolution-aware bounds**: Coordinate validation scales with screen resolution
- **Performance adaptation**: Validation strictness adjusts based on system performance

### Real-Time Validation
- **Input sanitization**: Type checking during user input
- **Range enforcement**: Immediate feedback for out-of-bounds values
- **Dependency updates**: Cascading validation when related settings change

## Hidden and Deprecated Configuration Items

### Configuration Loading Issue
**Critical Problem**: The sections array in ConfigManager.Load() excludes Flask and Skill sections:
```ahk
sections := ["General", "Resolution", "Mana", "Tincture", "Keys", 
            "Timing", "Wine", "LoadingScreen", "ClientLog", "UI", "Performance"]
```
**Missing**: "Flask", "Skill"
**Impact**: These sections are never automatically loaded, settings only available via default values

### Hidden Settings (Used in Code but Not in Default Config)
- **General.SkillEnabled** - Used in Main.ahk:253
- **General.FlaskEnabled** - Used in Main.ahk:261
- **General.AutoSaveConfig** - Referenced in validation
- **Performance.MonitoringEnabled** - Used in Main.ahk:403

### Future/Planned Configuration Items
#### Flask Conditions System (TODO Implementation)
- Health detection settings
- Movement detection parameters
- Combat state detection
- Boss fight detection
- Status effect detection (curse, burning, chilled, etc.)

#### Tincture Verification Methods
- **g_tincture_verification_method** - Currently "mana", supports "buff" (future)
- Buff icon verification settings (planned)

### Legacy vs New System
- **Legacy Timing Section**: Still in default config for compatibility
- **New Skill/Flask Sections**: Used extensively but not in default config
- **Fallback Mechanism**: Code falls back to legacy if new system unavailable

## Validation Error Handling and Fallbacks

### Error Collection and Reporting
**Japanese Localization**: All error messages in Japanese with clear descriptions
**Error Aggregation**: Collects all validation errors before displaying to user
**Structured Display**: Formatted message box with bullet points and context

### Fallback Value Hierarchy
1. **Current Configuration**: Existing user settings
2. **Function Defaults**: Explicit defaults in Get() calls
3. **System Defaults**: Hard-coded values from CreateDefaultConfig()

### Auto-Correction Mechanisms
**Automatic Fixes Applied**:
- Resolution bounds correction (800-7680 width, 600-4320 height → 3440x1440)
- Min/Max relationship fixes (when Min > Max)
- Wine stage progression corrections
- Priority value clamping (1-5 range)

**Requires User Intervention**:
- Empty required keys (cannot auto-assign)
- File path specification (Client.txt path)
- Coordinate adjustments for different game setups

### Error Classification
- **DEBUG (0)**: Detailed diagnostic information
- **INFO (1)**: General information messages
- **WARN (2)**: Auto-correctable issues
- **ERROR (3)**: Issues affecting functionality
- **CRITICAL (4)**: Issues requiring immediate attention

## Configuration Auto-Generation and Migration

### Initial Configuration Generation
**Trigger**: Automatic when Config.ini doesn't exist
**Function**: CreateDefaultConfig() generates complete configuration
**Sections**: Creates all 11+ configuration sections with optimized defaults

### Migration Limitations
**Current State**: Limited migration capabilities
- **No version tracking**: No ConfigVersion or versioning system
- **No automatic updates**: New settings require manual config deletion
- **Section exclusion**: Flask/Skill sections not auto-loaded

### Backup and Recovery System
**Automatic Backups**:
- Created before every configuration load
- Timestamped format: Config_backup_YYYYMMDD_HHMMSS.ini
- 7-day retention with automatic cleanup

**Profile Management**:
- Multiple profile support (Config_profilename.ini)
- Profile switching with automatic backup
- Import/export functionality with validation

### Coordinate Scaling System
**Base Resolution**: 3440x1440 (ultrawide reference)
**Auto-scaling**: Proportional coordinate scaling for different resolutions
**Bounds Checking**: Ensures scaled coordinates remain within screen bounds

## Recommended Improvements

### Critical Issues to Address
1. **Add Flask and Skill sections** to ConfigManager sections array
2. **Implement validation rules** for Flask and Skill sections
3. **Add duplicate key detection** across all key bindings
4. **Implement priority conflict checking** for skills
5. **Add version tracking** for configuration migration

### Enhanced Validation Features
1. **Cross-parameter validation** for performance settings
2. **File path accessibility checking** for Client.txt
3. **Resolution boundary validation** after coordinate scaling
4. **Comprehensive key conflict detection** across all sections

### Migration System Improvements
1. **Version-based migration scripts** for configuration updates
2. **Incremental setting addition** for existing configurations
3. **Backward compatibility** support for older configurations
4. **Configuration repair** mechanisms for corrupted files

This comprehensive validation system demonstrates sophisticated configuration management with multi-layered validation, automatic error correction, and graceful degradation, though it would benefit from enhanced migration capabilities and cross-parameter validation improvements.