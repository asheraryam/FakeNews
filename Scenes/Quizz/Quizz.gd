extends Node2D

onready var dialogue_box_scene = preload("res://Scenes/Bubble/Bubble.tscn")
onready var answer_scene = preload("res://Scenes/Button/Answer/Answer.tscn")
onready var submit_scene = preload("res://Scenes/Button/Submit/Submit.tscn")

var good_answer_scene = preload("res://Scenes/Button/Answer/GoodAnswer.tscn")
var bad_answer_scene = preload("res://Scenes/Button/Answer/BadAnswer.tscn")

onready var speaker_name_node = $GUI/UI/Separation/SpeakerName
onready var portrait_node = $GUI/UI/Portrait

var dialogue_index : int = 0
var nb_questions : int = 9

var question_index_array : Array = []

var speakers_dic = {
	"Raoult" : "Didier Raoult (Microbiologiste)",
	"Montagnier" : "Luc Montagnier (Prix Nobel de medecine)",
	"Casasnovas" : "Thierry Casasnovas (Vidéaste)",
	"JJCC" : "Jean-Jacques Crèvecoeur (Conférencier)"
}


func _ready():
	var _err = $Timer.connect("timeout", self, "on_timer_timeout")
	
	
	for i in range(nb_questions):
		question_index_array.append(i + 1)
	
	randomize()
	
	generate_question()


func get_portait_key(index: int) -> String:
	return "PORT_QUIZZ_" + String(index)



func instanciate_reaction():
	var feedback : Label = null
	var answer_group = $GUI/UI/Answers
	
	# Feedbacks
	for answer in answer_group.get_children():
		if answer is AnswerButton and answer.is_pressed:
			if answer.is_valid:
				feedback = good_answer_scene.instance()
			else:
				feedback = bad_answer_scene.instance()
			
			feedback.set_position(Vector2(answer.get_size().x / 2, 0))
			answer.call_deferred("add_child", feedback)
	
	# Add points
	var new_points = answer_group.count_good_answers()
	$GUI/Points.add_to_points(new_points)
	
	# Play the sound accordingly to the situation
	if new_points > 0:
		$GoodSound.play()
	else:
		$BadSound.play()
	
	yield(feedback.get_node("AnimationPlayer"), "animation_finished")
	
	next_question()


func next_question():
	destroy_current_question()
	yield(portrait_node.get_node("AnimationPlayer"), "animation_finished")
	
	generate_question()


func destroy_current_question():
	for answer in $GUI/UI/Answers.get_children():
		answer.queue_free()
	
	for question in $GUI/UI/Questions.get_children():
		question.queue_free()
	
	portrait_node.disappear()
	
	speaker_name_node.text = ""


func generate_question():
	var rng = randi() % question_index_array.size()
	dialogue_index = question_index_array[rng]
	question_index_array.remove(rng)
	
	instanciate_dialogue_box(dialogue_index)
	instanciate_responses(dialogue_index)
	$Timer.start()


func instanciate_dialogue_box(index : int):
	# Change the portrait accordingly
	var portrait_name = DIALOGUE.get_current_translation().get_message(get_portait_key(index))
	portrait_node.set_portrait(portrait_name)
	portrait_node.appear()
	
	yield(portrait_node.get_node("AnimationPlayer"), "animation_finished")
	
	speaker_name_node.text = speakers_dic.get(portrait_name)
	
	# Instanciate the question
	var box_node = dialogue_box_scene.instance()
	box_node.dialogue_key = DIALOGUE.get_dialogue_key(index)
	
	var questions_node = get_tree().get_current_scene().find_node("Questions")
	var container_size : Vector2 = questions_node.get_size()
	var box_size : Vector2 = box_node.get_size()
	
	box_node.set_position(container_size / 2 - box_size / 2)
	box_node.rect_position.x += 10
	box_node.rect_position.y -= 20
	
	questions_node.call_deferred("add_child", box_node)


func instanciate_responses(dial_index : int):
	var answer_container_node = get_tree().get_current_scene().find_node("Answers")
	var container_size : Vector2 = answer_container_node.get_size()
	
	instanciate_submit(answer_container_node, container_size)
	
	var index_array : Array = [0, 1, 2, 3]
	
	for i in range(2):
		for j in range(2):
			var answer_button = answer_scene.instance()
			
			var rng = randi() % index_array.size()
			var index = index_array[rng]
			index_array.remove(rng)
			
			var answer_key = DIALOGUE.get_answer_key(dial_index, index)
			answer_button.set_key(answer_key)
			
			var button_size = answer_button.get_size()
			var button_pos = Vector2(container_size.x / 2 * (j + 0.5), container_size.y / 3 * (i + 1))- button_size / 2
			
			answer_button.set_position(button_pos)
			answer_container_node.call_deferred("add_child", answer_button) 


func instanciate_submit(answer_container_node: Node, container_size: Vector2):
	var submit_node = submit_scene.instance()
	var submit_size = submit_node.get_size()
	submit_node.set_position(Vector2(container_size.x / 2 - submit_size.x / 2, container_size.y - container_size.y/6))
	answer_container_node.call_deferred("add_child", submit_node)


func on_submit():
	instanciate_reaction()


func on_timer_timeout():
	next_question()
