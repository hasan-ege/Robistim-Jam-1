extends Node2D

# 스크린 상에서 눌러야 하는 완벽한 y좌표
const PERFECT_YPOS : float = 500
# 기어 UI의 Y축 끝부분
const GEAR_END : float = 520
# 마지막 노트가 끝난 후 이 여백동안 대기했다가 게임이 끝남
const ENDPOS_BIAS : float = +2.0
# 보조선 간격(초)
const SUBLINE_LENGTH : float = 0.25
# 자동 플레이 플래그
const AUTOPLAY : bool = false
# 기록 모드 (true로 설정하면 tuşa bastığın anlar konsola yazılır)
const RECORD_MODE : bool = false
# 채널의 키코드 (input map에서 추가 가능)
@export var keycodes : PackedStringArray
# Müziği buradan veya Editor'den seçebilirsin
@export var music : AudioStream
# Müzik ses seviyesi (0 ile 1 arası)
@export_range(0, 1) var music_volume : float = 1.0
# Efekt (Alkış) ses seviyesi (0 ile 1 arası)
@export_range(0, 1) var sfx_volume : float = 1.0
# 오디오 플레이어 노드 경로
@export_node_path("AudioStreamPlayer") var audio
# 노트 씬 미리 로드
@onready var noteScene : PackedScene = preload("res://note.tscn")
# 노트가 (y=0) 부터 (y=PERFECT_YPOS) 까지 내려오는 시간
var speed : float = 1.0
# 노트 정보 (이제 단일 채널로 통합됨)
var noteArray      : Array = [
	[[1.21], [1.76], [2.27], [3.81], [4.91], [6.01], [7.04], [8.11], [9.19], [10.22], [10.76], [11.36], [12.39], [13.47], [14.56], [15.57], [16.64], [17.76], [18.81], [19.84], [20.14], [20.27], [20.92], [21.51], [22.01], [22.24], [22.39], [23.02], [23.62], [24.07], [24.36], [25.09], [25.76], [26.26], [26.81], [27.31], [27.91], [28.44], [28.91], [29.44]]
]
# 보조선 정보
var subLineArray   : Array = []
# 현재 음원 재생 시간(초)
var currentSongPos : float   = 0.0
# 1프레임 당 노트가 내려오는 y좌표값
var coordPerFrame  : float
# 게임이 끝나는 시간(초)
var endPos         : float   = 0.0

# 현재 유효한 노트 씬이 담긴 큐
var queue          : Array   = [[]]
# 채널의 눌린 상태 확인
var pressed        : Array   = [false]
# 현재 누르고 있어야 하는지 확인
var shouldPress    : Array   = [false]
# 현재 누르고 있는 롱노트가 끝나는 시간 
var shouldPressEnd : Array   = [-1.0]
# 게임이 끝났는지 확인하는 플래그
var done           : bool    = false
# 현재 콤보 수
var combo          : int     = 0
# 최대 콤보 수
var comboMax       : int     = 0
# 현재 점수
var currentScore   : float   = 0.0
# 얻을 수 있는 최대 점수를 얻는다.
var maximumScore   : float   = 0.0

# 기록된 노트들을 저장할 배열
var recorded_notes : Array = []
# 기록 중인 롱노트의 시작 시간
var recording_start_time : float = 0.0

# 노트 시간 정보의 가장 끝 값을 얻는다.
func getEndPos(array : Array, sp : float, bias : float) -> float:
	var result : float  = -1.0
	for noteInfo in array:
		if (len(noteInfo) == 1):
			if (result < noteInfo[0]):
				result = noteInfo[0]
		elif (len(noteInfo) == 2):
			if (result < noteInfo[0] + noteInfo[1]):
				result = noteInfo[0] + noteInfo[1]
	return result + sp + bias

# 1프레임 당 노트가 내려와야 하는 좌표값을 얻는다.
func getCoordPerFrame(sp : float, perfectYpos : float) -> float:
	if (sp != 1.0):
		perfectYpos /= sp
		sp          /= sp
	perfectYpos /= 60.0
	return perfectYpos

# 모든 노트 시간 정보에 대해 speed값만큼 빼준다.
func getCorrectArr(array : Array, sp : float) -> Array:
	var result : Array = []
	for noteInfo in array:
		noteInfo[0] -= sp
		result.append(noteInfo)
	return result

# 보조선 리스트를 얻는다.
func getSubLineArr(endpos : float, sp : float, sec : float) -> Array:
	var arr : Array = []
	var index : float = sec
	while (index < endpos):
		arr.append(index)
		index += sec
	for i in range(len(arr)):
		arr[i] -= sp
	while (arr and arr[0] < sp):
		arr.pop_front()
	return arr

# 얻을 수 있는 최대 점수를 얻는다.
func getMaximumScore(notearr : Array) -> float:
	var result : float = 0.0
	for i in notearr:
		for note in i:
			if (len(note) == 1):
				result += 1.0
			else:
				result += note[1] * 10.0
	return result

# 콤보를 더한다.
func addCombo(score_type : String) -> void:
	combo += 1
	if combo > comboMax:
		comboMax = combo
	if (score_type == "Perfect"):
		currentScore += 1.0
	elif (score_type == "Good"):
		currentScore += 0.7
	$combo.text = str(combo)
	$anim.play(score_type)
	await $anim.animation_finished
	$anim.play("combo")
	await $anim.animation_finished

# 콤보를 리셋한다.
func resetCombo() -> void:
	combo = 0
	$combo.text = str(combo)
	$anim.play("Bad")
	await $anim.animation_finished
	$anim.play("combo")
	await $anim.animation_finished

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process(false)
	
	# 노트 데이터 정렬 (단일 채널로 합침)
	noteArray[0].sort_custom(func(a, b): return a[0] < b[0])
	
	if (get_node_or_null("pressed1")):
		get_node("pressed1").visible = false
	
	var noteStart : float = INF
	if len(noteArray[0]) > 0:
		noteStart = noteArray[0][0][0]
	
	if (noteStart <= speed):
		print("Warning: Note starts very early")
	
	if (len(keycodes) < 1):
		OS.alert("Please assign at least one keycode")
	
	if (audio == null):
		OS.alert("Please assign a AudioStreamPlayer node")
	
	# Müziği değişkenden yükle
	if (music != null):
		get_node(audio).stream = music
	
	# Ses seviyelerini ayarla
	get_node(audio).volume_db = linear_to_db(music_volume)
	if has_node("clap_sound"):
		$clap_sound.volume_db = linear_to_db(sfx_volume)
		
	if (get_node(audio).stream == null):
		OS.alert("Please assign a music")
		
	noteArray[0] = getCorrectArr(noteArray[0], speed)
	coordPerFrame = getCoordPerFrame(speed, PERFECT_YPOS)
	
	endPos = getEndPos(noteArray[0], speed, ENDPOS_BIAS)
	
	if (get_node(audio).stream.get_length() < endPos):
		print("Warning: Music is shorter than track")
		
	subLineArray = getSubLineArr(endPos, speed, SUBLINE_LENGTH)
	maximumScore = getMaximumScore(noteArray)
	
	if (AUTOPLAY):
		$isautoplay.visible = true
		print("AUTO PLAYING...")
	
	await get_tree().create_timer(1.0).timeout
	print("Game Start")
	get_node(audio).play()
	set_process(true)

func _process(_delta) -> void:
	# 현재 음원 재생 시간 얻기
	currentSongPos = get_node(audio).get_playback_position()
	currentSongPos -= AudioServer.get_output_latency()
	
	# 게임 종료 확인
	if (currentSongPos >= endPos):
		done = true
		if (get_node_or_null("pressed1")): get_node("pressed1").visible = false
		for i in $sublinecontainer.get_children(): i.queue_free()
		
		if (RECORD_MODE):
			print("--- RECORDED CHART ---")
			print(recorded_notes)
			print("--- END ---")
			
		print("Game Finished")
		print("Score : ", snapped(currentScore / maximumScore * 100.0, 0.1), "%")
		print("Maximum Combo : ", comboMax)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		set_process(false)
		return
	
	# 유효하지 않은 노드 제거 (메모리 관리 및 에러 방지)
	for i in range(len(queue)):
		var j = 0
		while j < len(queue[i]):
			if not is_instance_valid(queue[i][j]):
				queue[i].remove_at(j)
			else:
				j += 1
		
	# 롱노트 완료 확인
	if shouldPressEnd[0] != -1.0 and shouldPressEnd[0] <= currentSongPos:
		shouldPress[0] = false
		shouldPressEnd[0] = -1.0
		if len(queue[0]) > 0:
			queue[0].pop_front()
		
	# 노트 생성
	if (noteArray[0] and noteArray[0][0][0] <= currentSongPos):
		var note : Note = noteScene.instantiate()
		var info : Array = noteArray[0].pop_front()
		if (len(info) == 1):
			# 일반 노트 생성
			note.setNote(1, speed, coordPerFrame)
		else:
			# 롱노트 생성
			note.setNote(1, speed, coordPerFrame, info[1])
		
		var container = $container1
		container.add_child(note)
		note.position.x = 100 # Moved to top (local X)
		note.position.y = 0   # Start position (local Y)
		# 시간 오차 보정
		note.position.y += coordPerFrame * (currentSongPos - info[0]) / (1.0/60.0)
		queue[0].append(note)
		
	# 보조선 생성
	if (subLineArray and subLineArray[0] <= currentSongPos):
		subLineArray.pop_front()
		var line : Line2D = Line2D.new()
		line.width = 1
		line.points = [Vector2(50, 0), Vector2(150, 0)]
		line.default_color = Color(1, 1, 1, 0.1) # Daha şık, hafif şeffaf beyaz
		$sublinecontainer.add_child(line)
		
	# 보조선 이동 & 삭제
	for line in $sublinecontainer.get_children():
		if line.position.y >= PERFECT_YPOS:
			line.queue_free()
		line.position.y += coordPerFrame
		
	# 자동 플레이 확인
	if (AUTOPLAY):
		autoplay()
		killGarbage()
		return
		
	updateQueue()
	updateInputState()
	dequeue()
	killGarbage()

func autoplay():
	if len(queue[0]) > 0:
		var n = queue[0][0]
		if not is_instance_valid(n):
			queue[0].pop_front()
			return
			
		if (n.isLongnote == false):
			if (n.position.y >= PERFECT_YPOS):
				n.score = "Perfect"
				addCombo(n.score)
				n.queue_free()
				queue[0].pop_front()
		elif (n.isLongnote == true and n.longnoteScore == ""):
			if (n.position.y >= PERFECT_YPOS):
				n.score = "Perfect"
				shouldPress[0] = true
				shouldPressEnd[0] = currentSongPos + n.longnoteTime
				n.longnoteStart()

# 키가 눌렸을 시 호출됨
func keyPressed() -> void:
	if len(queue[0]) != 0:
		var n = queue[0][0]
		if is_instance_valid(n) and n.score != "Default":
			$hit_particles.global_position = n.global_position
			$hit_particles.restart()
			$hit_particles.emitting = true
			$clap_sound.play()
			if n.score == "Bad":
				resetCombo()
				if n.isLongnote == false:
					n.queue_free()
				else:
					n.longnoteFailed()
				queue[0].pop_front()
			else:
				if (n.isLongnote == false):
					addCombo(n.score)
					n.queue_free()
					queue[0].pop_front()
				else:
					shouldPress[0] = true
					shouldPressEnd[0] = currentSongPos + n.longnoteTime
					n.longnoteStart()

func updateQueue() -> void:
	for n in queue[0]:
		if not is_instance_valid(n): continue
		var m = n.position.y
		if (m < 400): continue
		if (400 <= m and m < 440): 
			n.score = "Bad"
		elif (440 <= m and m < 480):
			n.score = "Good"
		elif (480 <= m and m < 520):
			n.score = "Perfect"

func updateInputState() -> void:
	if (get_node_or_null("pressed1")):
		get_node("pressed1").visible = pressed[0]
	
	# 첫 번째 키코드 또는 스페이스바 사용
	var key = keycodes[0] if len(keycodes) > 0 else "ui_accept"
	
	if (Input.is_action_just_pressed(key)):
		pressed[0] = true
		if (RECORD_MODE):
			recording_start_time = currentSongPos
		else:
			keyPressed()
	if (Input.is_action_just_released(key)):
		pressed[0] = false
		if (RECORD_MODE):
			var duration = currentSongPos - recording_start_time
			if duration > 0.2: # 0.2 saniyeden uzunsa 롱노트
				recorded_notes.append([snapped(recording_start_time, 0.01), snapped(duration, 0.01)])
			else: # normal nota
				recorded_notes.append([snapped(recording_start_time, 0.01)])
			print("Recorded: ", recorded_notes[-1])
		
	if (pressed[0] == false and shouldPress[0]):
		resetCombo()
		if len(queue[0]) > 0 and is_instance_valid(queue[0][0]):
			queue[0][0].longnoteFailed()
			queue[0].pop_front()
		shouldPressEnd[0] = -1.0
		shouldPress[0] = false

func dequeue() -> void:
	while len(queue[0]) > 0:
		var n = queue[0][0]
		if is_instance_valid(n) and n.position.y >= GEAR_END:
			if (n.isLongnote == true):
				if (not shouldPress[0]):
					n.longnoteFailed()
					queue[0].pop_front()
					resetCombo()
				else:
					break # Still pressing, don't remove yet
			else:
				queue[0].pop_front()
				resetCombo()
		else:
			break

func killGarbage() -> void:
	for n in $container1.get_children():
		if is_instance_valid(n):
			var size_offset = n.effect.size.y if n.isLongnote else 0
			if (n.position.y - size_offset >= 600):
				n.queue_free()
