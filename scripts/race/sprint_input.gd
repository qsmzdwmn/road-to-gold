extends RefCounted
var mode:="rhythm"
var held:Dictionary={}
var last_side:=0
var last_press:=-100.0
var quality:=1.0
var valid_presses:=0

func side(key:int) -> int:
	if key==KEY_A or key==KEY_LEFT:return -1
	if key==KEY_D or key==KEY_RIGHT:return 1
	return 0

func eligible(key:int) -> bool:
	return key==KEY_SPACE if mode=="hold" else side(key)!=0

func event(key:int,pressed:bool,echo:bool,time:float) -> bool:
	if not eligible(key):return false
	if not pressed:
		held.erase(key)
		return false
	if echo or held.has(key):return false
	held[key]=true
	if mode=="hold":
		valid_presses+=1
		return true
	var current:=side(key)
	if current==last_side or time-last_press<0.12:return false
	quality=1.0 if last_side==0 else clampf(1.0-absf((time-last_press)-0.25)/0.15,0.0,1.0)
	last_side=current;last_press=time;valid_presses+=1
	return true

func effort(time:float) -> float:
	if mode=="hold":return 1.0 if held.has(KEY_SPACE) else 0.0
	return (0.85+0.15*quality)*clampf(1.0-maxf(0.0,time-last_press-0.6)/0.5,0.0,1.0)
