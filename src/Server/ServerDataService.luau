--!strict
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local HitboxService = {}
HitboxService.__index = HitboxService

export type HitboxConfig = {
	Size: Vector3,
	Offset: CFrame?,
	Lifetime: number,
	IgnoreList: { Instance }?,
	Debug: boolean?,
}

function HitboxService.CastBox(originCFrame: CFrame, config: HitboxConfig, onHit: (Humanoid, BasePart) -> ())
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = config.IgnoreList or {}

	local hitTargets: { [Model]: boolean } = {}
	local startTime = os.clock()
	local offset = config.Offset or CFrame.new()

	local debugPart: Part? = nil
	if config.Debug then
		debugPart = Instance.new("Part")
		debugPart.Size = config.Size
		debugPart.Anchored = true
		debugPart.CanCollide = false
		debugPart.Material = Enum.Material.ForceField
		debugPart.Color = Color3.fromRGB(240, 60, 60)
		debugPart.Parent = Workspace
	end

	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		local currentCFrame = originCFrame * offset

		if debugPart then
			debugPart.CFrame = currentCFrame
		end

		local parts = Workspace:GetPartBoundsInBox(currentCFrame, config.Size, overlapParams)
		for _, part in parts do
			local character = part.Parent
			if not character or not character:IsA("Model") then continue end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 and not hitTargets[character] then
				hitTargets[character] = true
				task.spawn(onHit, humanoid, part)
			end
		end

		if os.clock() - startTime >= config.Lifetime then
			connection:Disconnect()
			if debugPart then
				debugPart:Destroy()
			end
		end
	end)
end

return HitboxService
