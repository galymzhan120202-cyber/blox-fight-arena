local classes = {
	Warrior = require(script.Parent.Warrior),
	Archer = require(script.Parent.Archer),
	Mage = require(script.Parent.Mage),
	Assassin = require(script.Parent.Assassin),
}

local ClassDefinitions = {}

function ClassDefinitions.Get(className: string)
	return classes[className]
end

return ClassDefinitions
