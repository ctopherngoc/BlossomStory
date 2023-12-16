extends HBoxContainer

onready var ResolutionOptionButton = $VideoOptions/RESO/ResolutionOptionButton
onready var FullscreenToggle = $VideoOptions/Windowed/ResoToggle
onready var VsyncToggle = $VideoOptions/VSYNC/VsyncToggle
onready var MSAASlider = $VideoOptions/MSAA/MSAASLIDER
onready var FXAAToggle = $VideoOptions/FXAA/FxaaToggle

var Resolutions: Dictionary = {"3840x2160":Vector2(3840,2160),
								"2560x1440":Vector2(2560,1080),
								"1920x1080":Vector2(1920,1080),
								"1366x768":Vector2(1366,768),
								"1536x864":Vector2(1536,864),
								"1280x720":Vector2(1280,720),
								"1440x900":Vector2(1440,900),
								"1600x900":Vector2(1600,900),
								"1024x600":Vector2(1024,600),
								"800x600": Vector2(800,600)}

var FullScreen: bool
# Called when the node enters the scene tree for the first time.

func _ready():
	FullscreenToggle.set_pressed_no_signal(OS.is_window_fullscreen())
	VsyncToggle.set_pressed_no_signal(OS.is_vsync_enabled())
	FXAAToggle.set_pressed_no_signal(get_viewport().get_use_fxaa())
	MSAASlider.set_value(get_viewport().get_msaa())
	ResolutionOptionButton.set_disabled(OS.is_window_fullscreen())
	AddResolutions()

func AddResolutions():
	var CurrentResolution = get_viewport().get_size()

	var index = 0
	
	for r in Resolutions:
		ResolutionOptionButton.add_item(r, index)
		
		if Resolutions[r] == CurrentResolution:
			ResolutionOptionButton._select_int(index)
		index += 1

func _on_ResolutionOptionButton_item_selected(index):
	var size = Resolutions.get(ResolutionOptionButton.get_item_text(index))
	OS.set_window_size(size)
	OS.center_window()
	
func _on_ResoToggle_toggled(button_pressed):
	OS.set_window_fullscreen(button_pressed)

	
	ResolutionOptionButton.set_disabled(button_pressed)
	ResolutionOptionButton.set_text(String(OS.get_screen_size().x)+"x"+String(OS.get_screen_size().y))

	if button_pressed == false:
		
		ResolutionOptionButton._select_int(5)
		ResolutionOptionButton.set_text(ResolutionOptionButton.get_item_text(5))
		var size = Resolutions["1280x720"]
		
		OS.set_window_size(size)
		OS.center_window()

	OS.set_window_resizable(button_pressed)# Disable for linux(buggy)/Enable for Windows

func _on_VsyncToggle_toggled(button_pressed):
	OS.set_use_vsync(button_pressed)

func _on_HSlider_value_changed(value):
	print(value)
	get_viewport().set_msaa(value)

func _on_FxaaToggle_toggled(button_pressed):
	get_viewport().set_use_fxaa(button_pressed)
