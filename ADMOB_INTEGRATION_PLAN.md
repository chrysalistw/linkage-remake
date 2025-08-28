# AdMob Integration Plan for Linkage Game

## Overview
This document outlines the complete integration strategy for AdMob ads into the Linkage game. The AdMobManager singleton has been created and can be tested using the AdMobTestScreen.

## Current Implementation Status ✅

### Completed Components
1. **AdMobManager.gd** - Centralized singleton for all ad operations
   - Handles rewarded videos, interstitials, and banner ads
   - Proper initialization and error handling
   - Pre-loading and cleanup mechanisms
   - Uses test ad unit IDs (safe for testing)

2. **AdMobTestScreen** - Testing interface
   - Load/Show buttons for each ad type
   - Real-time status monitoring
   - Reward callback testing
   - Navigation back to title screen

3. **Project Configuration**
   - AdMobManager added to autoloads
   - AdMob plugin already enabled

## Integration Strategy (Future Implementation)

### Phase 1: Rewarded Video Integration 🎯
**Target**: Replace placeholder reward system with real rewarded ads

#### Files to Modify:
- **PlayScreen.gd** - `_on_reward_button_pressed()` method
- **GameState.gd** - Add ad-related signals

#### Implementation Steps:
```gdscript
# In PlayScreen.gd
func _on_reward_button_pressed():
    if not game_active:
        return
    
    # Check if rewarded ad is ready
    if AdMobManager.is_rewarded_ad_ready():
        # Show ad and wait for completion
        AdMobManager.show_rewarded_ad()
    else:
        # Fallback: use existing reward system or show message
        print("Ad not ready - loading...")
        AdMobManager.load_rewarded_ad()

# Connect to reward signal in _ready():
AdMobManager.rewarded_ad_earned_reward.connect(_on_reward_ad_completed)

func _on_reward_ad_completed(reward_item):
    # Apply existing reward logic
    GameState._on_reward_earned()
    GameState._on_reward_requested()
```

### Phase 2: Strategic Interstitial Placement 📱
**Target**: Add monetization without disrupting gameplay

#### Strategic Placement Points:
1. **Game Over Screen** - When user clicks "Fine" to quit
2. **Theme Selection** - After selecting and applying a new theme
3. **App Launch** - Occasionally on title screen (with frequency cap)

#### Frequency Management:
- Maximum 1 interstitial per game session
- Cooldown period between interstitials
- Skip if ad not ready (graceful fallback)

#### Implementation Example:
```gdscript
# In PlayScreen.gd
func _on_fine_button_pressed():
    _enable_controls()
    game_lost_dialog.hide()
    
    # Show interstitial before returning to title
    if AdMobManager.is_interstitial_ad_ready():
        AdMobManager.show_interstitial_ad()
        # Navigate after ad closes (handled by AdMobManager callback)
        AdMobManager.interstitial_ad_dismissed.connect(_navigate_to_title)
    else:
        get_tree().change_scene_to_file("res://TitleScreen.tscn")

# In TilesetSelection.gd  
func _on_theme_applied():
    # Show interstitial after theme change
    if AdMobManager.is_interstitial_ad_ready() and should_show_interstitial():
        AdMobManager.show_interstitial_ad()
```

### Phase 3: Banner Ad Integration (Optional) 🎯
**Target**: Persistent revenue stream

#### Placement Strategy:
- Bottom banner during gameplay
- Top banner on menu screens
- Hide during animations and critical gameplay moments

#### Implementation:
```gdscript
# In PlayScreen.gd _ready()
func _ready():
    # Load banner ad
    AdMobManager.load_banner_ad()
    AdMobManager.banner_ad_loaded.connect(_on_banner_loaded)

func _on_banner_loaded():
    # Show banner at bottom of game screen
    AdMobManager.show_banner_ad()
```

## Testing Instructions

### Using AdMobTestScreen:
1. Launch game and navigate to AdMobTestScreen
2. Wait for "AdMob Initialized: true"
3. Test each ad type:
   - **Load** buttons: Request ads from AdMob
   - **Show** buttons: Display loaded ads
   - **Status labels**: Monitor ad readiness
4. Test reward callback by watching rewarded video

### Ad Unit IDs:
- **Rewarded**: `ca-app-pub-3940256099942544/1712485313` (Test)
- **Interstitial**: `ca-app-pub-3940256099942544/1033173712` (Test)  
- **Banner**: `ca-app-pub-3940256099942544/6300978111` (Test)

**⚠️ Important**: These are Google's official test ad units. Replace with your actual AdMob ad unit IDs for production.

## Configuration for Production

### 1. Replace Test Ad Unit IDs
In `AdMobManager.gd`, update these variables:
```gdscript
var rewarded_ad_unit_id = "ca-app-pub-YOUR-PUBLISHER-ID/YOUR-REWARDED-ID"
var interstitial_ad_unit_id = "ca-app-pub-YOUR-PUBLISHER-ID/YOUR-INTERSTITIAL-ID"
var banner_ad_unit_id = "ca-app-pub-YOUR-PUBLISHER-ID/YOUR-BANNER-ID"
```

### 2. Update Request Configuration
Remove test device IDs and adjust content ratings as needed:
```gdscript
# In AdMobManager.gd initialize_admob()
request_configuration.test_device_ids = []  # Remove for production
request_configuration.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G
```

### 3. Add Real AdMob App ID
In Android export settings, add your AdMob App ID to the manifest.

## Integration Benefits

### User Experience:
- ✅ **Non-intrusive**: Ads enhance existing reward system
- ✅ **Value-driven**: Rewarded ads provide tangible game benefits
- ✅ **Strategic placement**: Interstitials at natural break points
- ✅ **Graceful fallback**: Game works even when ads fail

### Revenue Optimization:
- ✅ **High-value placement**: Rewarded ads when players need help
- ✅ **Strategic interstitials**: Between natural game sessions
- ✅ **Persistent banners**: Continuous revenue stream
- ✅ **Frequency management**: Prevents ad fatigue

### Technical Architecture:
- ✅ **Centralized management**: Single AdMobManager handles all ads
- ✅ **Signal-based**: Clean integration with existing GameState
- ✅ **Error resilient**: Proper error handling and cleanup
- ✅ **Testable**: Dedicated test screen for validation

## Next Steps

1. **Test AdMobManager**: Use AdMobTestScreen to verify all ad types work
2. **Integrate Rewarded Ads**: Connect to existing reward button
3. **Add Interstitials**: Implement at strategic transition points
4. **Replace Test IDs**: Use your actual AdMob ad units
5. **Test Production Build**: Verify ads work in release APK
6. **Monitor Performance**: Track ad fill rates and user engagement

## Troubleshooting

### Common Issues:
- **Ads not loading**: Check internet connection and ad unit IDs
- **"Ad not ready" errors**: Implement proper loading states
- **App crashes**: Ensure proper cleanup in `_exit_tree()`
- **No test ads**: Verify device is added to test devices list

### Debug Logging:
AdMobManager includes extensive console logging. Monitor Godot's debug output for detailed ad lifecycle information.