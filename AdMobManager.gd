extends Node

# Signals for ad events
signal rewarded_ad_earned_reward(reward_item)
signal rewarded_ad_loaded
signal rewarded_ad_failed_to_load(error)
signal rewarded_ad_dismissed

var _banner : AdView
var _interstitial : InterstitialAd
var _rewarded : RewardedAd
var _banner_id : String = "ca-app-pub-3940256099942544/9214589741"
var _interstitial_id: String = "ca-app-pub-3940256099942544/1033173712"
var _rewarded_id: String = "ca-app-pub-3940256099942544/5224354917"

var is_rewarded_ready: bool = false
var _full_screen_content_callback: FullScreenContentCallback

func _ready() -> void:
	_setup_full_screen_callback()

func _setup_full_screen_callback() -> void:
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
		_interstitial.destroty()
		_interstitial = null
		
	var interstitial_ad_load_callback := InterstitialAdLoadCallback.new()
	interstitial_ad_load_callback.on_ad_failed_to_load = func(adError : LoadAdError) -> void:
		print(adError.message)
	
	interstitial_ad_load_callback.on_ad_loaded = func(interstitial_ad : InterstitialAd) -> void:
		#print("interstitial ad loaded" + str(interstitial_ad._uid))
		_interstitial = interstitial_ad
		_interstitial.show()

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
