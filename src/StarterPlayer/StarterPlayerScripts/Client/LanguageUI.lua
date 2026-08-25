local MenuUI = require(script.Parent.MenuUI)
local Localization = require(script.Parent.Localization)

-- Батырма атаулары әрқашан өз тілінде көрсетіледі (ағымдағы тілге қарамастан) —
-- ойыншы өз тілін оңай тауып алуы үшін.
local LANGUAGES = { "kk", "ru" }
local LANGUAGE_LABELS = { kk = "Қазақша", ru = "Русский" }

local LanguageUI = {}

function LanguageUI.Init()
	local holder = MenuUI.AddSection("Тіл / Язык")
	local buttons = {}

	local function refreshHighlight()
		local active = Localization.GetLanguage()
		for language, button in buttons do
			MenuUI.SetSelected(button, language == active)
		end
	end

	for _, language in LANGUAGES do
		local button = MenuUI.CreateButton(holder, LANGUAGE_LABELS[language])
		buttons[language] = button

		button.MouseButton1Click:Connect(function()
			Localization.SetLanguage(language)
		end)
	end

	Localization.OnChanged(refreshHighlight)
	refreshHighlight()
end

return LanguageUI
