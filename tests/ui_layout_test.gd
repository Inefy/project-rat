extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("UI LAYOUT FAIL: " + message)

func on_screen(control: Control, label: String) -> void:
	check(control.is_visible_in_tree(), label + " is visible")
	check(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(control.get_global_rect()), label + " stays inside the viewport")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	on_screen(game.hud.menu_start, "start button")
	game.start_game()
	paused = true
	var buffs: Array[String] = ["Power 6s"]
	for large in [false, true]:
		game.hud.large_text = large
		game.hud.update_stats(1234567, 10, 240, 85, 100, 0.5, buffs, 0.5)
		game.hud.update_combo(8, 0.6)
		await process_frame
		await process_frame
		for property in ["wave_label", "progress_label", "score_label", "kills_label", "combo_label", "combo_bar", "health_label", "health_bar", "dash_label", "dash_bar", "autofire_label", "control_hint", "buffs_label"]:
			on_screen(game.hud.get(property), property)
		check(game.hud.health_panel.get_global_rect().encloses(game.hud.dash_bar.get_global_rect()), "dash meter stays inside the vitals panel")
		for id in game.UPGRADES:
			var data: Dictionary = game.UPGRADES[id].duplicate()
			data["description"] = game._upgrade_description(id)
			var options: Array[Dictionary] = [data, data, data]
			game.hud.show_upgrade_draft(options)
			game.hud.set_draft_context("Next: Wave 100 / Junkyard Dog", "Your build: Bounce / Dash Bomb / Orbit / Light Trail / 42 other upgrade levels", 2, true)
			await process_frame
			await process_frame
			var card: Button = game.hud.upgrade_cards.get_child(0)
			var description: Label = card.find_child("MutationDescription", true, false)
			var choice: Label = card.find_child("MutationChoice", true, false)
			on_screen(card, id + " card")
			on_screen(game.hud.reroll_button, "reroll button")
			on_screen(game.hud.draft_context, "next encounter")
			on_screen(game.hud.draft_build, "build summary")
			check(card.get_global_rect().end.y <= game.hud.reroll_button.global_position.y, "reroll footer stays below cards")
			check(card.get_global_rect().encloses(choice.get_global_rect()), id + " choice stays inside its card")
			check(description.get_global_rect().end.y <= choice.global_position.y, id + " description does not overlap its choice")
		game.hud.hide_upgrade_draft()
	game.settings.show_settings()
	await process_frame
	on_screen(game.settings.close_button, "settings close button")
	game.settings.hide_settings()
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("UI LAYOUT PASS: visible HUD anchors, vitals, all upgrades in normal and large text, settings")
	quit(0 if failures.is_empty() else 1)
