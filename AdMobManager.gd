extends Node

var _banner : AdView
var _interstitial : InterstitialAd
var _rewarded : RewardedAd
var _banner_id : String = "ca-app-pub-3940256099942544/9214589741"
var _interstitial_id: String = "ca-app-pub-3940256099942544/1033173712"
var _rewarded_id: String = "ca-app-pub-3940256099942544/5224354917"

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
		_rewarded.destroty()
		_rewarded = null
	
	var on_user_earned_reward_listener := OnUserEarnedRewardListener.new()
	on_user_earned_reward_listener.on_user_earned_reward = func(rewarded_item : RewardedItem):
		print("on_user_earned_reward, rewarded_item: rewarded", rewarded_item.amount, rewarded_item.type)
	
	var rewarded_ad_load_callback := RewardedAdLoadCallback.new()
	rewarded_ad_load_callback.on_ad_failed_to_load = func(adError : LoadAdError) -> void:
		print(adError.message)

	rewarded_ad_load_callback.on_ad_loaded = func(rewarded_ad : RewardedAd) -> void:
		print("rewarded ad loaded" + str(rewarded_ad._uid))
		_rewarded = rewarded_ad
		
		_rewarded.show(on_user_earned_reward_listener)

	RewardedAdLoader.new().load(_rewarded_id, AdRequest.new(), rewarded_ad_load_callback)
