-- Кинематик режимде (тек жазушы клиентте) жарық пен пост-эффектілерді
-- "фильм" көрінісіне келтіреді. Lighting өзгерісі клиентте ғана — қалыпты
-- ойыншыларға әсер етпейді.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local CinematicLighting = {}

local applied: { Instance } = {}
local savedLighting: { [string]: any } = {}

local LIGHTING_TARGET = {
	Brightness = 2.2,
	ExposureCompensation = 0.15,
	EnvironmentDiffuseScale = 1,
	EnvironmentSpecularScale = 1,
	ShadowSoftness = 0.5,
	Ambient = Color3.fromRGB(70, 74, 90),
	OutdoorAmbient = Color3.fromRGB(120, 125, 150),
}

local function makeEffect(className: string, props: { [string]: any })
	local fx = Instance.new(className)
	for k, v in props do
		(fx :: any)[k] = v
	end
	fx.Parent = Lighting
	table.insert(applied, fx)
	return fx
end

function CinematicLighting.Init()
	local function activate()
		if LocalPlayer:GetAttribute("Cinematic") ~= true or CinematicLighting._on then
			return
		end
		CinematicLighting._on = true

		for key, value in LIGHTING_TARGET do
			savedLighting[key] = (Lighting :: any)[key]
			TweenService:Create(Lighting, TweenInfo.new(1.2), { [key] = value }):Play()
		end

		local bloom = makeEffect("BloomEffect", { Intensity = 0, Size = 24, Threshold = 0.9 })
		TweenService:Create(bloom, TweenInfo.new(1.2), { Intensity = 0.9 }):Play()

		local cc = makeEffect("ColorCorrectionEffect", {
			Brightness = 0,
			Contrast = 0,
			Saturation = 0,
			TintColor = Color3.fromRGB(255, 245, 235),
		})
		TweenService:Create(cc, TweenInfo.new(1.2), { Contrast = 0.12, Saturation = 0.18 }):Play()

		makeEffect("SunRaysEffect", { Intensity = 0.12, Spread = 0.85 })

		local dof = makeEffect("DepthOfFieldEffect", {
			FarIntensity = 0,
			FocusDistance = 55,
			InFocusRadius = 40,
			NearIntensity = 0,
		})
		TweenService:Create(dof, TweenInfo.new(1.2), { FarIntensity = 0.35 }):Play()
	end

	local function deactivate()
		if not CinematicLighting._on then
			return
		end
		CinematicLighting._on = false
		for key, value in savedLighting do
			(Lighting :: any)[key] = value
		end
		for _, fx in applied do
			fx:Destroy()
		end
		applied = {}
	end

	activate()
	LocalPlayer:GetAttributeChangedSignal("Cinematic"):Connect(function()
		if LocalPlayer:GetAttribute("Cinematic") == true then
			activate()
		else
			deactivate()
		end
	end)
end

return CinematicLighting
