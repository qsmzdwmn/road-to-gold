extends Control
## Tiny procedural 2D pictograms; no extra textures or 3D viewports.
var kind := "hair"
var index := 0

func _draw() -> void:
	var center := size * Vector2(0.5, 0.48)
	var ink := Color("c6a66b")
	var quiet := Color("89969e")
	if kind.begins_with("hair"):
		draw_circle(center, 12, quiet)
		if kind == "hair_female":
			draw_arc(center,13,PI,TAU,16,ink,5)
			if index == 5: draw_circle(center+Vector2(0,-19),7,ink)
			elif index == 1: draw_line(center+Vector2(12,-9),center+Vector2(18,22),ink,6)
			else:
				for side in [-1,1]:
					var length := 14 if index == 4 else 24
					if index == 3:
						for y in range(-2,length,5): draw_circle(center+Vector2(side*13,y),3,ink)
					elif index == 2:
						var points := PackedVector2Array()
						for y in range(-8,length,3): points.append(center+Vector2(side*(13+sin(y*.3)*3),y))
						draw_polyline(points,ink,4)
					else: draw_line(center+Vector2(side*13,-6),center+Vector2(side*13,length),ink,5)
		else:
			if index == 0: draw_arc(center,12,PI,TAU,12,ink,3)
			elif index == 1: draw_rect(Rect2(center+Vector2(-13,-15),Vector2(26,8)),ink)
			elif index in [2,5]:
				for x in [-9,-3,3,9]: draw_circle(center+Vector2(x,-12),4 if index==2 else 6,ink)
			elif index == 3: draw_arc(center+Vector2(0,-3),11,PI,TAU,12,ink,7)
			else:
				draw_line(center+Vector2(-12,-8),center+Vector2(3,-16),ink,7)
				draw_line(center+Vector2(8,-14),center+Vector2(13,-8),ink,5)
		draw_line(center+Vector2(-17,27),center+Vector2(17,27),quiet,3)
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
