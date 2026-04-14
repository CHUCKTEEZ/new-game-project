extends CharacterBody3D

## Walk speed on the ground (m/s).
@export var move_speed: float = 6.0
## Mouse sensitivity for third-person orbit (radians per pixel).
@export var mouse_sensitivity: float = 0.003
@export var min_pitch_deg: float = -55.0
@export var max_pitch_deg: float = 35.0

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _pitch_pivot: Node3D = $CameraPivot/PitchPivot

var _mouse_captured: bool = false
var _yaw: float = PI
var _pitch: float = 0.0


func _ready() -> void:
	_yaw = _camera_pivot.rotation.y
	_pitch = _pitch_pivot.rotation.x
	_capture_mouse()


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_capture_mouse()
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		_release_mouse()

	if _mouse_captured and event is InputEventMouseMotion:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
		_camera_pivot.rotation.y = _yaw
		_pitch_pivot.rotation.x = _pitch


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := _wasd_vector()
	var basis_yaw := Basis.from_euler(Vector3(0.0, _yaw, 0.0))
	var forward := -basis_yaw.z
	forward.y = 0.0
	var right := basis_yaw.x
	right.y = 0.0
	if forward.length_squared() > 0.0001:
		forward = forward.normalized()
	if right.length_squared() > 0.0001:
		right = right.normalized()

	var move_dir := forward * -input_dir.y + right * input_dir.x
	if move_dir.length_squared() > 0.0001:
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

	move_and_slide()


func _wasd_vector() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		dir.x += 1.0
	return dir.normalized() if dir.length_squared() > 0.0 else Vector2.ZERO


func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_mouse_captured = true


func _release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_mouse_captured = false
