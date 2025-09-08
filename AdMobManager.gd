extends Node

# Signals for ad events
signal rewarded_ad_earned_reward(reward_item)
signal rewarded_ad_loaded
signal rewarded_ad_failed_to_load(error)
signal rewarded_ad_dismissed
signal interstitial_ad_loaded
signal interstitial_ad_failed_to_load(error)

var _banner : AdView
var _interstitial : InterstitialAd
var _rewarded : RewardedAd
var _banner_id : String
var _interstitial_id: String
var _rewarded_id: String

var is_rewarded_ready: bool = false
var is_interstitial_ready: bool = false
var _full_screen_content_callback: FullScreenContentCallback
var _interstitial_callback: FullScreenContentCallback

func _ready() -> void:
	_load_admob_config()
	_setup_full_screen_callbacks()
	prints("banner id: ", _banner_id)

func _load_admob_config() -> void:
	var config_path = "res://admob_config.json"
	
	if not FileAccess.file_exists(config_path):
		push_error("AdMob config file not found at: " + config_path)
		# Use test ad IDs as fallback
		_banner_id = "ca-app-pub-3940256099942544/9214589741"
		_interstitial_id = "ca-app-pub-3940256099942544/1033173712"
		_rewarded_id = "ca-app-pub-3940256099942544/5224354917"
		return
	var file = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		push_error("Failed to open AdMob config file")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse AdMob config JSON: " + str(parse_result))
		return
	
	var config_data = json.data
	_banner_id = config_data.get("banner_id", "")
	_interstitial_id = config_data.get("interstitial_id", "")
	_rewarded_id = config_data.get("rewarded_id", "")
	
	print("AdMob config loaded successfully")

func _setup_full_screen_callbacks() -> void:
	# Setup rewarded ad callback
	_full_screen_content_callback = FullScreenContentCallback.new()
	_full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("Rewarded ad dismissed")
		is_rewarded_ready = false
		_rewarded = null
		rewarded_ad_dismissed.emit()
		# Pre-load next ad
		load_rewarded()
	
	_full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(ad_error: AdError) -> void:
		print("Rewarded ad failed to show: ", ad_error.message)
		is_rewarded_ready = false
	
	# Setup interstitial ad callback
	_interstitial_callback = FullScreenContentCallback.new()
	_interstitial_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("Interstitial ad dismissed")
		is_interstitial_ready = false
		_interstitial = null
	
	_interstitial_callback.on_ad_failed_to_show_full_screen_content = func(ad_error: AdError) -> void:
		print("Interstitial ad failed to show: ", ad_error.message)
		is_interstitial_ready = false

func _create_banner() -> void:
	 #free memory
	if _banner:
		_banner.destroy()
		_banner = null

	_banner = AdView.new(_banner_id, AdSize.BANNER, AdPosition.Values.BOTTOM)
func load_banner():
	if _banner == null:
		_create_banner()
	var ad_request := AdRequest.new()
	_banner.load_ad(ad_request)
func load_interstitial() -> void:
	if _interstitial:
		_interstitial.destroy()
		_interstitial = null
		
	is_interstitial_ready = false
	
	var interstitial_ad_load_callback := InterstitialAdLoadCallback.new()
	interstitial_ad_load_callback.on_ad_failed_to_load = func(adError : LoadAdError) -> void:
		print("Interstitial ad failed to load: ", adError.message)
		is_interstitial_ready = false
		interstitial_ad_failed_to_load.emit(adError)
	
	interstitial_ad_load_callback.on_ad_loaded = func(interstitial_ad : InterstitialAd) -> void:
		print("Interstitial ad loaded successfully")
		_interstitial = interstitial_ad
		_interstitial.full_screen_content_callback = _interstitial_callback
		is_interstitial_ready = true
		interstitial_ad_loaded.emit()

	InterstitialAdLoader.new().load(_interstitial_id, AdRequest.new(), interstitial_ad_load_callback)

func load_rewarded() -> void:
	if _rewarded:
		_rewarded.destroy()
		_rewarded = null
	
	is_rewarded_ready = false
	
	var rewarded_ad_load_callback := RewardedAdLoadCallback.new()
	rewarded_ad_load_callback.on_ad_failed_to_load = func(adError : LoadAdError) -> void:
		print("Rewarded ad failed to load: ", adError.message)
		is_rewarded_ready = false
		rewarded_ad_failed_to_load.emit(adError)

	rewarded_ad_load_callback.on_ad_loaded = func(rewarded_ad : RewardedAd) -> void:
		print("Rewarded ad loaded successfully")
		_rewarded = rewarded_ad
		_rewarded.full_screen_content_callback = _full_screen_content_callback
		is_rewarded_ready = true
		rewarded_ad_loaded.emit()

	RewardedAdLoader.new().load(_rewarded_id, AdRequest.new(), rewarded_ad_load_callback)

func show_rewarded() -> void:
	if not is_rewarded_ready or not _rewarded:
		print("Rewarded ad not ready")
		return
		
	var on_user_earned_reward_listener := OnUserEarnedRewardListener.new()
	on_user_earned_reward_listener.on_user_earned_reward = func(rewarded_item : RewardedItem):
		print("User earned reward: ", rewarded_item.amount, " ", rewarded_item.type)
		rewarded_ad_earned_reward.emit(rewarded_item)
	
	_rewarded.show(on_user_earned_reward_listener)

func is_rewarded_ad_ready() -> bool:
	return is_rewarded_ready and _rewarded != null

func show_interstitial() -> void:
	if not is_interstitial_ready or not _interstitial:
		print("Interstitial ad not ready")
		return
	
	_interstitial.show()

func is_interstitial_ad_ready() -> bool:
	return is_interstitial_ready and _interstitial != null
