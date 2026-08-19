extends Node



var selected_university: String = ""

# GameBackend.universities[GameBackend.selected_university]

var universities = {
	"Auckland": {
		"money_needed": 35000,
		"grades_needed": 80,
		"location": "Auckland"
	},

	"Canterbury": {
		"money_needed": 36500,
		"grades_needed": 75,
		"location": "Christchurch"
	},

	"Waikato": {
		"money_needed": 27000,
		"grades_needed": 70,
		"location": "Hamilton"
	}
}
