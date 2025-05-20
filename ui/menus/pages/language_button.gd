class_name LanguageButton
extends OptionButton


func _ready() -> void :
	for language in ProgressData.languages:
		add_item(Utils.get_lang_key(language))
