extends Node3D
## Review-only scene. Does not change production cameras or save data.
const Model = preload("res://scripts/customization/procedural_athlete.gd")
const Appearance = preload("res://scripts/data/appearance_data.gd")
var models: Array = []
var appearances: Array = []
var caption: Label
var frame_samples: Array[float] = []
var angle := 0
var ticks := 0

func _ready() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("101820")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("dedee8")
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	light.light_energy = 1.1
	light.shadow_enabled = false
	add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.35
	camera.position = Vector3(0, 1.05, -5)
	add_child(camera)
	camera.look_at(Vector3(0, 1.05, 0))
	for index in range(2):
		var model = Model.new()
		add_child(model)
		model.position.x = 0.65 if index == 0 else -0.65
		var appearance = Appearance.new()
		appearance.hairstyle = 1 if index == 0 else 3
		appearance.skin = 2 if index == 0 else 4
		model.apply_appearance(appearance, "male" if index == 0 else "female")
		models.append(model)
		appearances.append(appearance)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	caption = Label.new()
	caption.position = Vector2(24, 20)
	caption.add_theme_font_size_override("font_size", 20)
	canvas.add_child(caption)
	_update_caption()

func _update_caption() -> void:
	caption.text = "ATHLETE LAB / GLB FEASIBILITY\nMale (left) • Female (right)\n1 Front   2 Side   3 Three-quarter | H hairstyle  C hair color  S skin tone  F fallback\nView: " + ["Front", "Side", "Three-quarter"][angle]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode in [KEY_1, KEY_2, KEY_3]:
		angle = event.keycode - KEY_1
		for model in models: model.rotation.y = [0.0, PI * 0.5, -PI / 6][angle]
	elif event.keycode == KEY_F:
		for index in range(models.size()):
			models[index].use_fallback = not models[index].use_fallback
			models[index].apply_appearance(appearances[index], "male" if index == 0 else "female")
	elif event.keycode in [KEY_H, KEY_C, KEY_S]:
		for index in range(models.size()):
			var appearance = appearances[index]
			if event.keycode == KEY_H: appearance.hairstyle = (appearance.hairstyle + 1) % 4
			if event.keycode == KEY_C: appearance.hair_color = (appearance.hair_color + 1) % 5
			if event.keycode == KEY_S: appearance.skin = (appearance.skin + 1) % 6
			models[index].apply_appearance(appearance, "male" if index == 0 else "female")
	_update_caption()

func _process(delta: float) -> void:
	frame_samples.append(delta * 1000.0)
	if frame_samples.size() > 300: frame_samples.pop_front()
	ticks += 1
	if ticks % 6 == 0 and OS.has_feature("web"):
		var stats := []
		for model in models:
			stats.append(model.geometry_stats() if model.has_method("geometry_stats") else {})
		var payload := {"models": stats, "appearance": appearances.map(func(a): return a.to_dict()), "skin_colors": models.map(func(m): return m.skin_material.albedo_color.to_html(false)), "hair_colors": models.map(func(m): return m.hair_material.albedo_color.to_html(false)), "frame_ms": frame_samples, "draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), "rendered_primitives": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)}
		JavaScriptBridge.eval("window.athleteReviewMetrics=" + JSON.stringify(payload), true)
