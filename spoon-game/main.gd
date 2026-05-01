extends Node2D

# Ekranda vurulması gereken mükemmel Y koordinatı
const PERFECT_YPOS : float = 950
# Dişli (Gear) arayüzünün Y eksenindeki bitiş noktası
const GEAR_END : float = 1300
# Son nota bittikten sonra oyunun sonlanması için beklenecek ekstra süre
const ENDPOS_BIAS : float = +2.0
# Kılavuz çizgilerinin (Subline) arası boşluk (saniye)
const SUBLINE_LENGTH : float = 0.25
# Otomatik oynatma modu bayrağı
const AUTOPLAY : bool = false
# Kayıt modu (true yapılırsa basılan anlar konsola yazılır)
const RECORD_MODE : bool = false
# Kanalın tuş kodları (Input Map üzerinden eklenebilir)
@export var keycodes : PackedStringArray
# Müziği buradan veya Editor üzerinden seçebilirsin
@export var music : AudioStream
# Müzik ses seviyesi (0 ile 1 arası)
@export_range(0, 1) var music_volume : float = 1.0
# Efekt (Alkış) ses seviyesi (0 ile 1 arası)
@export_range(0, 1) var sfx_volume : float = 1.0

@export_group("Reverb Settings")
@export_range(0, 1) var music_reverb_wet : float = 0.4
@export_range(0, 1) var music_reverb_room : float = 0.8
@export_range(0, 1) var sfx_reverb_wet : float = 0.5
@export_range(0, 1) var sfx_reverb_room : float = 0.9

# Müzik çalar düğümünün (node) yolu
@export var audio_node_path : NodePath = NodePath("audio")
@onready var audio_node : AudioStreamPlayer = get_node_or_null(audio_node_path)

# Nota sahnesini önceden belleğe yükle
@onready var noteScene : PackedScene = preload("res://note.tscn")
# Alkış sesini önceden yükle
@onready var clap_stream : AudioStream = preload("res://assets/clap.mp3")

# Notanın (y=0)'dan (y=PERFECT_YPOS)'a inmesi için gereken süre
@export var speed : float = 1.0

# Nota verileri (Artık tek kanal üzerinden akıyor)
@export var noteArray      : Array = [
	[[0.03, 0], [0.19, 1], [0.45, 1], [0.84, 1], [0.99, 1], [1.38, 1], [2.98, 1], [3.38, 1], [3.65, 1], [4.18, 1], [4.45, 1], [4.71, 1], [5.12, 1], [5.38, 0], [5.64, 1], [5.91, 0], [6.44, 0], [6.85, 1], [7.26, 1], [7.78, 1], [8.72, 1], [8.99, 1], [9.66, 0], [11.8, 0], [12.2, 1], [12.86, 0], [13.4, 0], [13.93, 0], [14.2, 1], [14.47, 0], [15.0, 1], [15.41, 0], [16.34, 1], [16.6, 0], [16.88, 0], [17.28, 1], [18.22, 0], [18.61, 1], [19.02, 0], [20.09, 1], [20.61, 1], [20.87, 0], [21.15, 1], [21.82, 1], [22.22, 1], [22.49, 1], [22.89, 1], [23.56, 0], [23.82, 1], [24.09, 0], [24.62, 1], [24.89, 1], [25.16, 0], [25.57, 0], [26.23, 0], [26.63, 1], [27.03, 1], [28.36, 0], [28.9, 0], [29.16, 1], [29.43, 0], [29.71, 0], [29.97, 1], [30.37, 1], [31.3, 1], [31.57, 0], [32.1, 0], [32.51, 0], [33.44, 1], [34.25, 0], [34.64, 0], [36.65, 1], [36.92, 0], [37.19, 0], [37.45, 1], [37.99, 0], [38.52, 0], [39.06, 0], [39.59, 0], [39.86, 1], [40.12, 0], [40.66, 1], [41.19, 0], [41.6, 1], [41.99, 1], [42.26, 0], [42.67, 1], [42.93, 1], [43.2, 1], [43.73, 1], [44.4, 0], [44.66, 0], [45.74, 0], [46.27, 1], [46.81, 1], [47.21, 1], [47.47, 0], [47.88, 1], [48.13, 0], [48.4, 1], [48.95, 0], [49.21, 0], [49.48, 0], [50.02, 1], [50.54, 0], [51.08, 0], [51.62, 1], [54.02, 1], [54.56, 1], [54.82, 0], [56.16, 0], [56.44, 0], [56.69, 0], [56.96, 1], [58.17, 0], [58.83, 0], [59.09, 1], [60.04, 1], [60.98, 0], [61.37, 1], [61.78, 1], [62.58, 0], [62.84, 1], [63.11, 0], [64.18, 0], [64.57, 1], [64.98, 1], [66.32, 1], [66.58, 0], [66.85, 1], [67.38, 0], [67.65, 1], [67.92, 0], [68.45, 0], [68.99, 0], [69.39, 1], [69.79, 1], [71.4, 1], [71.92, 1], [72.19, 0], [72.72, 0], [73.13, 1], [74.06, 1], [74.33, 0], [74.86, 0], [75.27, 1], [75.67, 1], [76.2, 1], [77.01, 1], [77.4, 1], [78.08, 1], [78.34, 1], [79.68, 1], [80.21, 0], [80.48, 0], [80.75, 1], [81.82, 0], [82.62, 1], [82.88, 0], [84.75, 1], [85.02, 0], [85.96, 0], [86.37, 1], [86.89, 1], [90.37, 0], [90.64, 1], [91.17, 1], [91.44, 0], [91.97, 0], [92.51, 0], [93.04, 0], [93.31, 1], [93.58, 0], [94.11, 0], [94.38, 1], [94.64, 0], [94.91, 1], [95.18, 0], [96.78, 1], [97.31, 0], [97.58, 1], [97.85, 0], [98.26, 1], [98.92, 0], [99.45, 0], [99.72, 1], [99.99, 0], [100.39, 1], [100.93, 1], [101.33, 0], [101.73, 1], [101.99, 1], [102.53, 1], [102.79, 0], [103.06, 1], [103.47, 1], [103.72, 0], [103.99, 1], [104.8, 0], [105.34, 0], [105.6, 1], [105.87, 0], [106.13, 1], [106.94, 0], [107.33, 1], [108.01, 0], [108.27, 1], [108.54, 0], [108.95, 1], [109.34, 1], [109.61, 0], [109.88, 1], [110.14, 0], [110.41, 0], [110.68, 0], [111.08, 1], [111.35, 1], [112.69, 1], [114.68, 0], [114.95, 0], [115.23, 0], [115.89, 1], [116.3, 1], [116.82, 1], [117.09, 0], [117.62, 0], [118.03, 1], [118.96, 1], [119.77, 1], [120.16, 0], [120.57, 1], [120.84, 0], [121.1, 1], [121.9, 0], [122.44, 0], [122.71, 0], [122.97, 0], [123.24, 1], [123.51, 0], [124.04, 0], [124.58, 0], [124.84, 1], [125.11, 0], [125.38, 1], [125.64, 0], [126.18, 0], [126.44, 1], [126.71, 0], [127.25, 1], [127.51, 1], [127.78, 1], [129.13, 1], [129.65, 1], [130.46, 0], [130.86, 1], [131.26, 1], [131.53, 0], [131.78, 1], [132.05, 0], [132.33, 1], [132.59, 1], [132.86, 1], [133.4, 0], [133.92, 1], [134.73, 0], [135.27, 0], [136.07, 1], [136.34, 0], [136.87, 0], [137.26, 1], [138.21, 1], [138.47, 0], [138.74, 1], [139.54, 1], [140.07, 0], [140.34, 1], [140.88, 1], [141.28, 1], [141.55, 1], [142.21, 0], [142.48, 1], [143.81, 1], [144.09, 0], [144.35, 1], [144.61, 0], [145.16, 0], [145.55, 1], [146.49, 1], [146.89, 1], [147.3, 0], [148.1, 1], [148.36, 0], [148.89, 0], [149.43, 1], [150.09, 1], [151.03, 1], [151.57, 0], [152.23, 1], [152.9, 0], [153.17, 1], [154.11, 1], [155.45, 0], [156.51, 1], [157.18, 0], [157.44, 0], [157.71, 0], [158.24, 1], [158.52, 1], [159.06, 1], [159.32, 0], [159.58, 0], [159.85, 0], [160.39, 1], [160.66, 0], [160.93, 0], [161.19, 0], [161.46, 0], [161.72, 1], [161.98, 1], [162.8, 1], [163.6, 0], [164.4, 1], [165.07, 0], [165.73, 0], [166.0, 1], [166.27, 0], [166.8, 1], [167.2, 1], [168.14, 1], [168.4, 1], [168.81, 1], [169.47, 0], [170.0, 0], [170.27, 1], [170.54, 0], [170.82, 1], [171.07, 0], [172.15, 0], [172.55, 0], [172.95, 1]]
]

# Kılavuz çizgilerinin verisi
var subLineArray   : Array = []
# Mevcut şarkının çalma süresi (saniye cinsinden)
var currentSongPos : float   = 0.0
# Kare (frame) başına notanın ineceği Y miktarı
var coordPerFrame  : float
# Oyunun tamamen biteceği an (saniye)
var endPos         : float   = 0.0

# Ekranda aktif olarak bulunan notaları tutan kuyruk
var queue          : Array   = [[]]
# Tuşa basılıp basılmadığını takip eden dizi
var pressed        : Array   = [false]
# Kayıt başlangıç zamanını tutar
var recordStart    : float   = 0.0
# Uzun nota için tuşun basılı tutulması gerekip gerekmediğini izler
var shouldPress    : Array   = [false]
# Basılı tutulan uzun notanın bitiş zamanı
var shouldPressEnd : Array   = [-1.0]
# Oyunun bitip bitmediğini belirten bayrak
var done           : bool    = false
# Mevcut kombo sayısı
var combo          : int     = 0
# Ulaşılan maksimum kombo
var comboMax       : int     = 0
# Mevcut puan
var currentScore   : float   = 0.0
# Ulaşılabilecek maksimum toplam puan
var maximumScore   : float   = 0.0

# Kaydedilen notaları tutan dizi
var recorded_notes : Array = []
# Dinamik olarak yüklenen alkış ikonu
var clap_texture : Texture2D

# Nota zaman verileri içindeki en son zamanı hesaplar
func getEndPos(array : Array, sp : float, bias : float) -> float:
	var result : float  = -1.0
	for noteInfo in array:
		if (len(noteInfo) <= 2):
			if (result < noteInfo[0]):
				result = noteInfo[0]
		elif (len(noteInfo) == 3):
			if (result < noteInfo[0] + noteInfo[2]):
				result = noteInfo[0] + noteInfo[2]
	return result + sp + bias

# Kare başına inilecek koordinat miktarını hesaplar
func getCoordPerFrame(sp : float, perfectYpos : float) -> float:
	if (sp != 1.0):
		perfectYpos /= sp
		sp          /= sp
	perfectYpos /= 60.0
	return perfectYpos

# Zaman uyumu için nota sürelerinden hız (speed) miktarını çıkarır
func getCorrectArr(array : Array, sp : float) -> Array:
	var result : Array = []
	for noteInfo in array:
		noteInfo[0] -= sp
		result.append(noteInfo)
	return result

# Ekranda görünen ritim kılavuz çizgilerini oluşturur
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

# Tamamı mükemmel vurulduğunda alınacak toplam puanı hesaplar
func getMaximumScore(notearr : Array) -> float:
	var result : float = 0.0
	for i in notearr:
		for note in i:
			if (len(note) <= 2):
				result += 1.0
			else:
				result += note[2] * 10.0
	return result

# Komboyu ve skoru artırır, animasyonu tetikler
func addCombo(score_type : String) -> void:
	combo += 1
	if combo > comboMax:
		comboMax = combo
	if (score_type == "Perfect"):
		currentScore += 1.0
	elif (score_type == "Good"):
		currentScore += 0.7
	$combo.text = str(combo)
	
	# Update score feedback text and color
	if get_node_or_null("score"):
		$score.text = score_type
		match score_type:
			"Perfect": $score.add_theme_color_override("font_color", Color.GOLD)
			"Good": $score.add_theme_color_override("font_color", Color.AQUAMARINE)
			"Bad": $score.add_theme_color_override("font_color", Color.CRIMSON)

	$anim.play(score_type)
	await $anim.animation_finished
	$anim.play("combo")
	await $anim.animation_finished

# Hatalı vuruşta komboyu sıfırlar
func resetCombo() -> void:
	combo = 0
	$combo.text = str(combo)
	if get_node_or_null("score"):
		$score.text = "Miss"
		$score.add_theme_color_override("font_color", Color.GRAY)
	$anim.play("Bad")
	await $anim.animation_finished
	$anim.play("combo")
	await $anim.animation_finished

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process(false)
	
	# İkonu yükle (SVG veya PNG)
	if FileAccess.file_exists("res://assets/clap.svg"):
		clap_texture = load("res://assets/clap.svg")
		print("Clap SVG loaded")
	elif FileAccess.file_exists("res://assets/clap_icon.png"):
		clap_texture = load("res://assets/clap_icon.png")
		print("Clap PNG loaded")
	
	if clap_texture and get_node_or_null("ui/target_circle/target_icon"):
		get_node("ui/target_circle/target_icon").texture = clap_texture
	
	print("NoteArray size: ", noteArray.size())
	if noteArray.size() == 0:
		print("ERROR: noteArray is empty!")
		return
	
	# Tuş atamalarını garantiye al
	if keycodes.size() < 2:
		keycodes = PackedStringArray(["D", "K"])
	
	# Nota verilerini kronolojik olarak sıralar
	if noteArray.size() > 0 and noteArray[0].size() > 0:
		noteArray[0].sort_custom(func(a, b): return a[0] < b[0])

	
	# Girdi hassasiyetini artır (saniyede 240 fiziksel kontrol)
	Engine.physics_ticks_per_second = 240
	Input.use_accumulated_input = false
	
	if get_node_or_null("pressed1"):
		get_node("pressed1").visible = false
	
	if (audio_node == null):
		print("ERROR: AudioStreamPlayer node not found at path: ", audio_node_path)
		return
		
	# Müziği değişkenden yükle
	if (music != null):
		audio_node.stream = music
	
	if (audio_node.stream == null):
		print("ERROR: No music stream assigned!")
		return

	# Ses seviyelerini ayarla
	audio_node.volume_db = linear_to_db(music_volume)
	
	# Audio Bus işlemleri (MusicReverb)
	var reverb_bus_idx = AudioServer.get_bus_index("MusicReverb")
	if reverb_bus_idx == -1:
		reverb_bus_idx = AudioServer.bus_count
		AudioServer.add_bus(reverb_bus_idx)
		AudioServer.set_bus_name(reverb_bus_idx, "MusicReverb")
		AudioServer.set_bus_send(reverb_bus_idx, "Master")
		var reverb_effect = AudioEffectReverb.new()
		reverb_effect.room_size = music_reverb_room
		reverb_effect.damping = 0.3
		reverb_effect.wet = music_reverb_wet
		reverb_effect.dry = 0.8
		AudioServer.add_bus_effect(reverb_bus_idx, reverb_effect)
	
	audio_node.bus = "MusicReverb"

	# Audio Bus işlemleri (SFXReverb)
	var sfx_bus_idx = AudioServer.get_bus_index("SFXReverb")
	if sfx_bus_idx == -1:
		sfx_bus_idx = AudioServer.bus_count
		AudioServer.add_bus(sfx_bus_idx)
		AudioServer.set_bus_name(sfx_bus_idx, "SFXReverb")
		AudioServer.set_bus_send(sfx_bus_idx, "Master")
		var sfx_reverb = AudioEffectReverb.new()
		sfx_reverb.room_size = sfx_reverb_room
		sfx_reverb.damping = 0.2
		sfx_reverb.wet = sfx_reverb_wet
		AudioServer.add_bus_effect(sfx_bus_idx, sfx_reverb)
		
	print("Audio setup complete.")
		
	if noteArray.size() > 0:
		noteArray[0] = getCorrectArr(noteArray[0], speed)
		coordPerFrame = getCoordPerFrame(speed, PERFECT_YPOS)
		endPos = getEndPos(noteArray[0], speed, ENDPOS_BIAS)
		subLineArray = getSubLineArr(endPos, speed, SUBLINE_LENGTH)
		maximumScore = getMaximumScore(noteArray)
	else:
		print("ERROR: noteArray is empty!")
		return
	
	# Apply flash theme to game UI if possible
	var flash_theme = load("res://flash_theme.tres")
	if flash_theme:
		if get_node_or_null("combo"): $combo.theme = flash_theme
		if get_node_or_null("score"): $score.theme = flash_theme
		if get_node_or_null("level_complete_ui/CenterContainer/PanelContainer"):
			$level_complete_ui/CenterContainer/PanelContainer.theme = flash_theme
	
	if get_node_or_null("level_complete_ui/CenterContainer/PanelContainer/VBoxContainer/MenuButton"):
		$level_complete_ui/CenterContainer/PanelContainer/VBoxContainer/MenuButton.pressed.connect(func(): get_tree().change_scene_to_file("res://addons/maaacks_game_template/scenes/menus/main_menu/main_menu.tscn"))

	# Müziği 4 saniye sonra başlatacak şekilde süreci hemen başlat
	currentSongPos = -4.0
	print("Game initialized, starting countdown...")
	set_process(true)


func _process(_delta) -> void:
	# Müziğin oynatıldığı anki zamanı alır veya geri sayımı yönetir
	if currentSongPos < 0:
		currentSongPos += _delta
		if currentSongPos >= 0:
			print("Oyun Başladı")
			audio_node.play()

	else:
		currentSongPos = audio_node.get_playback_position()

		currentSongPos -= AudioServer.get_output_latency()
	
	# Oyunun bitişini kontrol eder
	if (currentSongPos >= endPos):
		done = true
		if (get_node_or_null("pressed1")): get_node("pressed1").visible = false
		for i in $sublinecontainer.get_children(): i.queue_free()
		if (RECORD_MODE):
			print("--- KAYDEDİLEN BEATMAP ---")
			print(recorded_notes)
			print("--- SON ---")
		
		# Show level complete UI
		if get_node_or_null("level_complete_ui"):
			$level_complete_ui.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
		set_process(false)
		return
	
	# Geçersiz (silinmiş) notaları kuyruktan temizler
	for i in range(len(queue)):
		var j = 0
		while j < len(queue[i]):
			if not is_instance_valid(queue[i][j]):
				queue[i].remove_at(j)
			else:
				j += 1
		
	# Uzun notanın (Long Note) basılı tutma süresinin bitişini kontrol eder
	if shouldPressEnd[0] != -1.0 and shouldPressEnd[0] <= currentSongPos:
		shouldPress[0] = false
		shouldPressEnd[0] = -1.0
		if len(queue[0]) > 0:
			queue[0].pop_front()
		
	# Zamanı gelen notaları ekranda oluşturur
	if (noteArray[0].size() > 0 and noteArray[0][0][0] <= currentSongPos):

		var note : Note = noteScene.instantiate()
		var info : Array = noteArray[0].pop_front()
		if (len(info) == 2):
			note.setNote(1, speed, coordPerFrame, info[1], -1.0, clap_texture)
		else:
			note.setNote(1, speed, coordPerFrame, info[1], info[2], clap_texture)
		
		$container1.add_child(note)
		note.position.x = 100
		note.position.y = 0
		# Gecikme telafisi (Zamanlama hassasiyeti için pozisyon düzeltme)
		note.position.y += coordPerFrame * (currentSongPos - info[0]) / (1.0/60.0)
		queue[0].append(note)
		
	# Zamanı gelen kılavuz çizgilerini ekranda oluşturur
	if (subLineArray and subLineArray[0] <= currentSongPos):
		subLineArray.pop_front()
		var line : Line2D = Line2D.new()
		line.width = 1
		line.points = [Vector2(50, 0), Vector2(150, 0)]
		line.default_color = Color(1, 1, 1, 0.1)
		$sublinecontainer.add_child(line)
		
	# Kılavuz çizgilerini aşağı hareket ettirir ve vurma çizgisini geçerse siler
	for line in $sublinecontainer.get_children():
		if line.position.y >= PERFECT_YPOS:
			line.queue_free()
		line.position.y += coordPerFrame * (_delta * 60.0)
		
	if (AUTOPLAY):
		autoplay()
		killGarbage()
		return
		
	updateQueue()
	updateInputState()
	dequeue()
	killGarbage()

# Otomatik oynatma fonksiyonu
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

# Tuşa basıldığı an tetiklenen çekirdek fonksiyon
func keyPressed(key_index: int) -> void:
	if len(queue[0]) != 0:
		# Professional visual punch for the target circle
		if get_node_or_null("ui/target_circle"):
			var tc = get_node("ui/target_circle")
			tc.pivot_offset = Vector2(30, 30)
			var tw = get_tree().create_tween()
			tw.tween_property(tc, "scale", Vector2(1.3, 1.3), 0.05).set_trans(Tween.TRANS_SINE)
			tw.tween_property(tc, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
			
		var n = queue[0][0]
		if is_instance_valid(n) and n.score != "Default":
			if n.note_type != key_index:
				n.score = "Bad" # Yanlış tuş cezası
			
			# Target circle color flash
			if get_node_or_null("ui/target_circle"):
				var tc = get_node("ui/target_circle")
				var flash_color = Color("#F34728") if key_index == 0 else Color("#45C1E9")
				var tw_c = get_tree().create_tween()
				tw_c.tween_property(tc, "self_modulate", flash_color, 0.05)
				tw_c.tween_property(tc, "self_modulate", Color.WHITE, 0.1)

			if get_node_or_null("hit_particles"):
				$hit_particles.global_position = n.global_position
				var p_color = Color("#F34728") if key_index == 0 else Color("#45C1E9")
				$hit_particles.color = p_color
				$hit_particles.restart()
				$hit_particles.emitting = true
			play_clap()
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

# Notaların y pozisyonuna göre hangi skoru alacağını belirler (Yargı sistemi)
func updateQueue() -> void:
	for n in queue[0]:
		if not is_instance_valid(n): continue
		var m = n.position.y
		if (m < 810): 
			n.score = "Default"
		elif (m >= 810 and m < 860):
			n.score = "Bad"
		elif (m >= 860 and m < 910):
			n.score = "Good"
		elif (m >= 910 and m < 990): # Merkez nokta (950)
			n.score = "Perfect"
		elif (m >= 990 and m < 1040):
			n.score = "Good"
		elif (m >= 1040 and m < 1090):
			n.score = "Bad"
		else:
			n.score = "Default"


# Sistem girdilerini (Input) en yüksek hassasiyetle yakalar
func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.is_echo():
		for i in range(len(keycodes)):
			var k = OS.find_keycode_from_string(keycodes[i])
			if event.keycode == k:
				if event.is_pressed():
					keyPressed(i)
					if (RECORD_MODE):
						recordStart = currentSongPos
				else:
					if (RECORD_MODE):
						var duration = currentSongPos - recordStart
						if duration < 0.2:
							recorded_notes.append([snapped(recordStart, 0.01), i])
						else:
							recorded_notes.append([snapped(recordStart, 0.01), i, snapped(duration, 0.01)])
						print("Kaydedildi: ", recorded_notes[-1])

# Tuşun basılı tutulup tutulmadığını görsel geri bildirim için kontrol eder
func updateInputState() -> void:
	pressed[0] = false
	for i in range(len(keycodes)):
		var key_code = OS.find_keycode_from_string(keycodes[i])
		if Input.is_key_pressed(key_code):
			pressed[0] = true
			break

	# Ekranda parlayan basılma göstergesi
	if (get_node_or_null("pressed1")):
		get_node("pressed1").visible = pressed[0]
		
	# Uzun nota basılı tutulurken tuş erken bırakılırsa komboyu sıfırlar
	if (pressed[0] == false and shouldPress[0]):
		resetCombo()
		if len(queue[0]) > 0 and is_instance_valid(queue[0][0]):
			queue[0][0].longnoteFailed()
			queue[0].pop_front()
		shouldPressEnd[0] = -1.0
		shouldPress[0] = false

# Notalar ekranın alt sınırını geçtiğinde (Miss olduğunda) kuyruktan çıkarır
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
					break # Halen basılı tutuluyor, silme
			else:
				queue[0].pop_front()
				resetCombo()
		else:
			break

# Milyonlarca kişi alkışlıyormuş hissi yaratan stadyum efekti
func play_clap() -> void:
	# 1. KUVVETLİ ANA VURUŞ: Tıkladığın an tam güçte, sıfır gecikmeyle çalar.
	_spawn_clap_instance(1.0, 0.0) 
	_spawn_clap_instance(0.9, 0.0) # Sesi daha da toklatmak için ikinci bir eşzamanlı vuruş
	
	# 2. KALABALIK DESTEĞİ (Kuyruk): Geriye kalan sesler yankı hissi vermek için daha kısık çalar.
	for i in range(12):
		var delay = randf_range(0.01, 0.06) # Gecikmeyi daralttık (şişme hissini yok etmek için)
		var volume_multiplier = randf_range(0.3, 0.6) # Kalabalık sesleri ana vuruştan daha kısık
		get_tree().create_timer(delay).timeout.connect(func(): _spawn_clap_instance(volume_multiplier, delay))

# Tekil bir alkış objesi yaratır
func _spawn_clap_instance(vol_mult: float, _delay: float) -> void:
	var p = AudioStreamPlayer.new()
	p.stream = clap_stream
	p.bus = "SFXReverb" 
	
	p.pitch_scale = randf_range(0.8, 1.2) 
	
	# Ana ses seviyesini volume_multiplier ile çarparak uygula
	p.volume_db = linear_to_db(sfx_volume * vol_mult)
	
	add_child(p)
	p.play(0.01) # MP3 padding'i hafifçe atla
	p.finished.connect(func(): p.queue_free())

# Ekrandan çok uzağa giden (çöp) objeleri silerek bellek sızıntısını önler
func killGarbage() -> void:
	for n in $container1.get_children():
		if is_instance_valid(n):
			var size_offset = n.effect.size.y if n.isLongnote else 0
			if (n.position.y - size_offset >= 1100):
				n.queue_free()
