extends VBoxContainer
signal item_selected(index: int)
const Card = preload("res://scripts/ui/studio/choice_card.gd")
var selected := 0
var buttons: Array[Button] = []
var grid: GridContainer

func configure(labels: Array, initial: int, kind: String, colors: Array = []) -> void:
	if grid != null:
		remove_child(grid)
		grid.queue_free()
	buttons.clear()
	grid = GridContainer.new()
	grid.columns = 2 if kind == "hair" else (3 if labels.size() == 6 else 5)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	add_child(grid)
	var group := ButtonGroup.new()
	for index in range(labels.size()):
		var button = Card.new()
		button.configure(labels[index], "", kind if colors.is_empty() else "", index, Color(colors[index]) if not colors.is_empty() else Color.TRANSPARENT)
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(90 if colors.is_empty() else 64, 112 if kind.begins_with("hair") else (90 if colors.is_empty() else 78))
		button.pressed.connect(func():
			select(index)
			item_selected.emit(index)
		)
		grid.add_child(button)
		buttons.append(button)
	select(initial)

func select(index: int) -> void:
	if index < 0 or index >= buttons.size(): return
	selected = index
	for i in range(buttons.size()): buttons[i].set_pressed_no_signal(i == selected)
