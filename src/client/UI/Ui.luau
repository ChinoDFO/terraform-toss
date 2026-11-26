--!strict
-- Ayudante mínimo para crear interfaz por código (la versión final la puede rehacer Dev B en Studio).

local Ui = {}

function Ui.make(className: string, props: { [string]: any }, parent: Instance?): Instance
	local instance = Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function Ui.label(parent: Instance, name: string, position: UDim2, size: UDim2, text: string): TextLabel
	local label = Ui.make("TextLabel", {
		Name = name,
		Position = position,
		Size = size,
		Text = text,
		TextScaled = true,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
	}, parent) :: TextLabel
	Ui.make("UITextSizeConstraint", { MaxTextSize = 28 }, label)
	Ui.make("UIStroke", { Thickness = 2, Transparency = 0.3 }, label)
	return label
end

function Ui.button(
	parent: Instance,
	name: string,
	position: UDim2,
	size: UDim2,
	text: string,
	color: Color3
): TextButton
	local button = Ui.make("TextButton", {
		Name = name,
		Position = position,
		Size = size,
		Text = text,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = color,
		AutoButtonColor = true,
	}, parent) :: TextButton
	Ui.make("UICorner", { CornerRadius = UDim.new(0, 12) }, button)
	Ui.make("UITextSizeConstraint", { MaxTextSize = 26 }, button)
	return button
end

return Ui
