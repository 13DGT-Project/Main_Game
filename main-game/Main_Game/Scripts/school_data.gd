## SchoolData.gd
## Autoload singleton (Project Settings -> Autoload -> add this as "SchoolData").
##
## Flavor dialogue for the school scene's NPCs, plus the pool used for the
## teacher's "extra credit" bonus question.
extends Node

var _student_lines: Array = [
	"\"Ugh, I did not study for that maths test at all.\"",
	"\"Did you hear the cafeteria's got a new lunch deal?\"",
	"\"I've been up till 2am doing physics homework, I'm dead.\"",
	"\"Are you going to the game on Friday?\"",
	"\"Honestly I think I'm just going to wing the exam.\"",
	"\"My part-time job is eating my whole weekend.\"",
	"\"Do you reckon this'll actually be useful after school?\"",
	"\"I heard the English essay topic got changed again.\"",
	"\"You look tired — you doing okay?\"",
	"\"Three more months till exams... no big deal, right?\"",
]

var _teacher_lines_intro: Array = [
	"\"Keen for some extra credit? Answer this one and I'll bump your grade.\"",
	"\"Here's a tougher question — good chance to prove yourself.\"",
	"\"Let's see if you've really been paying attention.\"",
]

var _teacher_lines_correct: Array = [
	"\"Nicely done — that's exactly the kind of thinking I want to see.\"",
	"\"Good work. Keep that up and you'll be in good shape.\"",
]

var _teacher_lines_incorrect: Array = [
	"\"Not quite, but don't stress — that's a common mistake.\"",
	"\"Close, but no. Worth reviewing that topic again.\"",
]


func get_random_student_line() -> String:
	return _student_lines[randi() % _student_lines.size()]


func get_teacher_intro_line() -> String:
	return _teacher_lines_intro[randi() % _teacher_lines_intro.size()]


func get_teacher_result_line(is_correct: bool) -> String:
	var pool: Array = _teacher_lines_correct if is_correct else _teacher_lines_incorrect
	return pool[randi() % pool.size()]
