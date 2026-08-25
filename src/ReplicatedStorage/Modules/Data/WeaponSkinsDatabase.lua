-- Скин-деңгейлер барлық қаруға (Sword/Bow/Staff/Daggers/Hammer/Spear) бірдей қолданылады —
-- олар сол қарудың бөлшектерін осы Color/Material-ге бояйды. Default = өзгеріссіз (тегін).
return {
	{ Id = "Default", Name = "Әдепкі", Price = 0, Color = nil, Material = nil },
	{ Id = "Crimson", Name = "Қызыл алау", Price = 120, Color = Color3.fromRGB(200, 45, 45), Material = Enum.Material.Metal },
	{ Id = "Azure", Name = "Көк мұз", Price = 120, Color = Color3.fromRGB(60, 140, 240), Material = Enum.Material.Ice },
	{ Id = "Toxic", Name = "Улы жасыл", Price = 200, Color = Color3.fromRGB(110, 230, 60), Material = Enum.Material.Neon },
	{ Id = "Gold", Name = "Алтын", Price = 350, Color = Color3.fromRGB(240, 195, 60), Material = Enum.Material.Metal },
}
