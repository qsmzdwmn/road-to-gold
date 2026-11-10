extends Control
## Tiny procedural 2D pictograms; no extra textures or 3D viewports.
var kind := "hair"
var index := 0

func _draw() -> void:
	var center := size * Vector2(0.5, 0.48)
	var ink := Color("c6a66b")
	var quiet := Color("89969e")
	if kind == "hair":
		draw_circle(center, 12, quiet)
		if index == 1: draw_rect(Rect2(center + Vector2(-13,-14), Vector2(26,9)), ink)
		if index == 2:
			for x in [-9,0,9]: draw_circle(center + Vector2(x,-11), 7, ink)
		if index == 3:
			draw_arc(center, 13, PI, TAU, 16, ink, 6)
			draw_line(center + Vector2(12,-3), center + Vector2(17,17), ink, 7)
		draw_line(center + Vector2(-17,22), center + Vector2(17,22), quiet, 3)
	elif kind == "athlete":
		center = Vector2(size.x * 0.5, 50)
		draw_circle(center + Vector2(0,-26), 12, ink)
		var shoulders := 32.0 if index == 0 else 27.0
		var hips := 20.0 if index == 0 else 25.0
		draw_polygon(PackedVector2Array([center+Vector2(-shoulders/2,-7),center+Vector2(shoulders/2,-7),center+Vector2(hips/2,34),center+Vector2(-hips/2,34)]), PackedColorArray([quiet]))
		for side: float in [-1,1]:
			draw_line(center+Vector2(side*(shoulders/2+7),-2),center+Vector2(side*(shoulders/2+8),32),quiet,7)
			draw_line(center+Vector2(side*7,35),center+Vector2(side*9,64),ink,8)
	else:
		draw_arc(center, 17, -PI*0.75, PI*0.75, 24, ink, 2)
		for i in range(index+1): draw_circle(center + Vector2((i-index*0.5)*9,0), 2.5, ink)
