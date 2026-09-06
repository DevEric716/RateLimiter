--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

local InventoryController = {}
local activeTweens: { [GuiObject]: Tween } = {}

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function InventoryController.AnimateSlot(slotFrame: Frame, targetScale: number)
	if activeTweens[slotFrame] then
		activeTweens[slotFrame]:Cancel()
	end

	local targetSize = UDim2.fromScale(targetScale, targetScale)
	local tween = TweenService:Create(slotFrame, TWEEN_INFO, { Size = targetSize })
	activeTweens[slotFrame] = tween
	tween:Play()
end

function InventoryController.BindGridEvents(gridContainer: Frame)
	for _, slot in gridContainer:GetChildren() do
		if not slot:IsA("GuiObject") then continue end

		slot.MouseEnter:Connect(function()
			InventoryController.AnimateSlot(slot, 1.06)
		end)

		slot.MouseLeave:Connect(function()
			InventoryController.AnimateSlot(slot, 1.0)
		end)
	end
end

return InventoryController
