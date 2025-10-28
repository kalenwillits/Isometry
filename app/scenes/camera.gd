extends Camera2D

# TODO - allow custom optio ns
const CAMERA_ZOOM_MIN: int = 1
const CAMERA_ZOOM_DEFAULT: int = 3
const CAMERA_ZOOM_MAX: int = 11

@export var zoom_level: int = CAMERA_ZOOM_DEFAULT

# Base resolution for margin calculation
const BASE_RESOLUTION: Vector2 = Vector2(800, 600)
const CAMERA_MARGIN_RATIO: float = 33.33 / 600.0  # Proportion of screen height
const CAMERA_SPEED: float = 111.1
const CAMERA_TOLERANCE: float = 100.0

# Dynamic margin based on current resolution
func get_camera_margin() -> float:
	var viewport_size = get_viewport().get_visible_rect().size
	return viewport_size.y * CAMERA_MARGIN_RATIO

var _target: WeakRef
var _has_target: bool = false
var _lock: bool = true
func _ready() -> void:
	add_to_group(Group.CAMERA)
	make_current()
	zoom_update()

func pan_to(vec: Vector2, delta: float) -> void:
	var direction = (vec - position)
	var acceleration: float = vec.distance_to(position) / CAMERA_TOLERANCE
	position += acceleration * (direction.normalized() * delta * CAMERA_SPEED)
	
func smooth_pan_to(vec: Vector2, delta: float) -> void:
	var direction = (vec - position)
	position += (direction.normalized() * delta * CAMERA_SPEED / zoom_level)

func set_target(node: Node2D) -> void:
	clear_target()
	_has_target = true
	_target = weakref(node)
	
func get_target():
	return _target.get_ref()
	
func clear_target() -> void:
	_has_target = false
	_target = null

func snap_to(vec: Vector2) -> void:
	position = vec

func use_margin_panning(delta: float) -> void:
	var cursor = get_viewport().get_mouse_position()
	var viewsize = get_viewport().get_visible_rect().size
	var margin = get_camera_margin()
	if (cursor.x < margin) or (cursor.x > (viewsize.x - margin)):
		smooth_pan_to(get_global_mouse_position(), delta)
	elif (cursor.y < margin) or (cursor.y > (viewsize.y - margin)):
		smooth_pan_to(get_global_mouse_position(), delta)

func _physics_process(delta: float) -> void:
	if get_viewport_rect().has_point(get_viewport().get_mouse_position()):
		handle_focus_events(delta)
		handle_zoom_events()
		handle_camera_lock()
		handle_recenter(delta)
		
func handle_recenter(delta: float) -> void:
	if Input.is_action_pressed("camera_recenter"):
		use_target(delta)

func handle_focus_events(delta: float) -> void:
	if _has_target and _lock:
		use_target(delta)
	else:
		use_margin_panning(delta)
		
func handle_zoom_events() -> void:
	if Input.is_action_just_pressed("zoom_in"):
		zoom_in()
	elif Input.is_action_just_pressed("zoom_out"):
		zoom_out()

func use_target(delta: float) -> void:
	if get_target():
		pan_to(get_target().get_relative_camera_position(), delta)
	
func handle_camera_lock() -> void:
	if Input.is_action_just_pressed("camera_lock"):
		_lock = !_lock

func zoom_in() -> void:
	zoom_level = min(CAMERA_ZOOM_MAX, zoom_level + 1)
	zoom_update()

func zoom_out() -> void:
	zoom_level = max(CAMERA_ZOOM_MIN, zoom_level - 1)
	zoom_update()
	
func zoom_update() -> void:
	zoom.x = zoom_level
	zoom.y = zoom_level
