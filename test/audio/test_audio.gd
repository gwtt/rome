extends Node
	
func _input(event):
	if event is InputEventKey:
		var keycode = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
		if keycode == KEY_F1:
			AudioSystem.play_audio_omni("背景音乐1")
		if keycode == KEY_F2:
			AudioSystem.pause_audio_omni("背景音乐1")
		if keycode == KEY_F3:
			AudioSystem.continue_audio_omni("背景音乐1")
		if keycode == KEY_F4:
			AudioSystem.stop_audio_omni("背景音乐1")	
