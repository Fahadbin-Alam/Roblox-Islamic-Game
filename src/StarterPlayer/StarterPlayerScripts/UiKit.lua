--!strict

-- Small helpers shared by the Journeys book and HUD: consistent colours, rounded frames,
-- labels and buttons that work with mouse, touch, and gamepad.

local UiKit = {}

UiKit.Colors = {
    Panel = Color3.fromRGB(28, 34, 30),
    PanelLight = Color3.fromRGB(44, 52, 46),
    Text = Color3.fromRGB(246, 240, 224),
    Muted = Color3.fromRGB(196, 190, 172),
    Gold = Color3.fromRGB(226, 186, 96),
    Green = Color3.fromRGB(73, 112, 74),
    Red = Color3.fromRGB(150, 70, 60),
    Blue = Color3.fromRGB(62, 96, 128),
    Purple = Color3.fromRGB(96, 76, 112),
}

function UiKit.Round(instance: GuiObject, radius: number?)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = instance
end

function UiKit.Frame(parent: Instance, name: string, size: UDim2, position: UDim2, anchor: Vector2?, color: Color3?): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.AnchorPoint = anchor or Vector2.zero
    frame.BackgroundColor3 = color or UiKit.Colors.Panel
    frame.BackgroundTransparency = 0.06
    frame.BorderSizePixel = 0
    frame.Parent = parent
    UiKit.Round(frame, 12)

    local stroke = Instance.new("UIStroke")
    stroke.Color = UiKit.Colors.Gold
    stroke.Transparency = 0.55
    stroke.Thickness = 1
    stroke.Parent = frame

    return frame
end

function UiKit.Label(parent: Instance, text: string, size: UDim2, position: UDim2, textSize: number?, bold: boolean?, color: Color3?): TextLabel
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = size
    label.Position = position
    label.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = color or UiKit.Colors.Text
    label.TextSize = textSize or 16
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.RichText = true
    label.Parent = parent

    return label
end

-- A label that grows to fit its text inside a list layout.
function UiKit.Paragraph(parent: Instance, text: string, textSize: number?, bold: boolean?, color: Color3?): TextLabel
    local label = UiKit.Label(parent, text, UDim2.new(1, -8, 0, 0), UDim2.new(), textSize, bold, color)
    label.AutomaticSize = Enum.AutomaticSize.Y

    return label
end

function UiKit.Button(parent: Instance, text: string, size: UDim2, position: UDim2, color: Color3?, onClick: () -> ()): TextButton
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = color or UiKit.Colors.Green
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.TextColor3 = UiKit.Colors.Text
    button.TextSize = 15
    button.TextWrapped = true
    button.Selectable = true
    button.Parent = parent
    UiKit.Round(button, 8)

    local last = 0

    button.Activated:Connect(function()
        local now = os.clock()

        if now - last < 0.25 then
            return
        end

        last = now
        onClick()
    end)

    return button
end

function UiKit.Clear(container: Instance)
    for _, child in ipairs(container:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UIGridLayout") then
            child:Destroy()
        end
    end
end

function UiKit.Scroller(parent: Instance, size: UDim2, position: UDim2): ScrollingFrame
    local scroller = Instance.new("ScrollingFrame")
    scroller.BackgroundTransparency = 1
    scroller.BorderSizePixel = 0
    scroller.Size = size
    scroller.Position = position
    scroller.CanvasSize = UDim2.new()
    scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroller.ScrollBarThickness = 6
    scroller.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroller

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 4)
    padding.Parent = scroller

    return scroller
end

-- A full-width row with a title, a description, and up to two buttons on the right.
function UiKit.Row(parent: Instance, order: number, title: string, body: string, buttons: { { Text: string, Color: Color3?, OnClick: () -> () } }?): Frame
    local row = Instance.new("Frame")
    row.BackgroundColor3 = UiKit.Colors.PanelLight
    row.BorderSizePixel = 0
    row.Size = UDim2.new(1, 0, 0, 64)
    row.LayoutOrder = order
    row.Parent = parent
    UiKit.Round(row, 8)

    local buttonCount = if buttons then #buttons else 0
    local textWidth = -16 - buttonCount * 116
    UiKit.Label(row, title, UDim2.new(1, textWidth, 0, 22), UDim2.fromOffset(10, 6), 16, true)
    UiKit.Label(row, body, UDim2.new(1, textWidth, 0, 32), UDim2.fromOffset(10, 28), 13, false, UiKit.Colors.Muted)

    if buttons then
        for index, spec in ipairs(buttons) do
            UiKit.Button(row, spec.Text, UDim2.fromOffset(108, 40), UDim2.new(1, -(116 * (buttonCount - index + 1)), 0, 12), spec.Color, spec.OnClick)
        end
    end

    return row
end

return UiKit
