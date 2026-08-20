## SchoolData.gd
## Autoload singleton (Project Settings -> Autoload -> add this as "SchoolData").
##
## Dialogue for the school scene's NPCs. Students and the teacher both have
## full multi-line conversations (not just one-liners) picked as a whole set,
## plus the teacher's separate "extra credit" bonus-question flow.
extends Node

var _student_conversations: Array = [
	[
		"\"Ugh, I did not study for that maths test at all.\"",
		"\"I kept meaning to, and then it was midnight and I hadn't opened the book once.\"",
		"\"Please tell me you at least looked at it.\"",
	],
	[
		"\"Did you hear the cafeteria's got a new lunch deal?\"",
		"\"Two dollars for a pie and a drink. Genuinely might be the best part of my week.\"",
		"\"Low bar, but here we are.\"",
	],
	[
		"\"I've been up till 2am doing physics homework, I'm dead.\"",
		"\"The projectile motion questions took me like an hour each.\"",
		"\"Worth it though — I think I actually get it now.\"",
	],
	[
		"\"Are you going to the game on Friday?\"",
		"\"I said I'd go but I've also got that English essay due Monday...\"",
		"\"Yeah, we'll see how that goes.\"",
	],
	[
		"\"Honestly I think I'm just going to wing the exam.\"",
		"\"Not like, no effort. Just... realistic effort.\"",
		"\"There's a difference. A small one. But a difference.\"",
	],
	[
		"\"My part-time job is eating my whole weekend.\"",
		"\"Money's good though. Actual money, not just 'ask my parents' money.\"",
		"\"Still trying to figure out when I'm supposed to study.\"",
	],
	[
		"\"Do you reckon this'll actually be useful after school?\"",
		"\"Like, genuinely, when am I going to need half of this.\"",
		"\"...Okay fine, probably the maths. Just not all of it.\"",
	],
	[
		"\"I heard the English essay topic got changed again.\"",
		"\"Third time this term. I've basically got three half-essays now.\"",
		"\"At this point I could just staple them together and call it a trilogy.\"",
	],
	[
		"\"You look tired — you doing okay?\"",
		"\"No judgment, I look exactly the same. Just checking in.\"",
		"\"Anyway. Want to sit down for a sec before next period?\"",
	],
	[
		"\"Three more months till exams... no big deal, right?\"",
		"\"Right?\"",
		"\"...Right?\"",
	],
]

var _teacher_conversations: Array = [
	[
		"\"How's the study going? Keeping on top of everything?\"",
		"\"Don't burn yourself out trying to do it all at once — steady's better than frantic.\"",
	],
	[
		"\"I noticed a few of you looking pretty tired lately.\"",
		"\"A short break now and then genuinely helps more than people think. So does sleep, believe it or not.\"",
	],
	[
		"\"You know, the ones who do best aren't always the ones who work the most hours.\"",
		"\"It's the ones who actually understand what they're doing, rather than just grinding through it.\"",
	],
	[
		"\"If you're ever stuck on something, come find me before it becomes a bigger problem.\"",
		"\"Nobody expects you to have it all figured out. That's rather the point of being here.\"",
	],
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


func get_random_student_conversation() -> Array:
	return _student_conversations[randi() % _student_conversations.size()]


func get_random_teacher_conversation() -> Array:
	return _teacher_conversations[randi() % _teacher_conversations.size()]


func get_teacher_intro_line() -> String:
	return _teacher_lines_intro[randi() % _teacher_lines_intro.size()]


func get_teacher_result_line(is_correct: bool) -> String:
	var pool: Array = _teacher_lines_correct if is_correct else _teacher_lines_incorrect
	return pool[randi() % pool.size()]
