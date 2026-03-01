-- Nicecat EXE v1.0.0
-- Beautiful Roblox Executor UI with smooth animations
-- Cloud scripts now fetch LIVE from ScriptBlox.com API
-- Paste the entire script below into your executor and execute

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NicecatEXE"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("CoreGui")

-- ==================== MAIN FRAME ====================
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 920, 0, 560)
mainFrame.Position = UDim2.new(0.5, -460, 0.5, -280)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 100, 255)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 55)
titleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 16)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 300, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Nicecat EXE"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 26
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 100, 1, 0)
versionLabel.Position = UDim2.new(0, 320, 0, 0)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v1.0.0"
versionLabel.TextColor3 = Color3.fromRGB(100, 100, 255)
versionLabel.TextSize = 18
versionLabel.Font = Enum.Font.Gotham
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.Parent = titleBar

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -55, 0, 7)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
closeBtn.TextSize = 32
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

local closeHover = TweenService:Create(closeBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 80, 80)})
local closeLeave = TweenService:Create(closeBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(200, 200, 200)})

closeBtn.MouseEnter:Connect(function() closeHover:Play() end)
closeBtn.MouseLeave:Connect(function() closeLeave:Play() end)
closeBtn.MouseButton1Click:Connect(function()
	local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -460, 1.2, 0)})
	closeTween:Play()
	closeTween.Completed:Connect(function()
		screenGui:Destroy()
	end)
end)

-- Draggable
local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

titleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- ==================== SIDEBAR ====================
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 210, 1, -55)
sidebar.Position = UDim2.new(0, 0, 0, 55)
sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 16)
sidebarCorner.Parent = sidebar

local tabs = {"Home", "Executor", "Cloud", "Settings"}
local tabButtons = {}
local currentTab = "Home"

local function createTabButton(name, yOffset)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 55)
	btn.Position = UDim2.new(0, 10, 0, yOffset)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	btn.BorderSizePixel = 0
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(200, 200, 200)
	btn.TextSize = 18
	btn.Font = Enum.Font.GothamSemibold
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Parent = sidebar
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 12)
	btnCorner.Parent = btn
	
	local btnPadding = Instance.new("UIPadding")
	btnPadding.PaddingLeft = UDim.new(0, 20)
	btnPadding.Parent = btn
	
	local highlight = Instance.new("Frame")
	highlight.Name = "Highlight"
	highlight.Size = UDim2.new(0, 5, 1, 0)
	highlight.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
	highlight.BorderSizePixel = 0
	highlight.Visible = false
	highlight.Parent = btn
	
	local highlightCorner = Instance.new("UICorner")
	highlightCorner.CornerRadius = UDim.new(0, 3)
	highlightCorner.Parent = highlight
	
	local hoverTweenIn = TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(45, 45, 60)})
	local hoverTweenOut = TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(30, 30, 42)})
	
	btn.MouseEnter:Connect(function() hoverTweenIn:Play() end)
	btn.MouseLeave:Connect(function() if currentTab \~= name then hoverTweenOut:Play() end end)
	
	btn.MouseButton1Click:Connect(function()
		if currentTab == name then return end
		currentTab = name
		switchTab(name)
	end)
	
	tabButtons[name] = btn
	return btn
end

local y = 20
for _, tabName in ipairs(tabs) do
	createTabButton(tabName, y)
	y += 70
end

-- ==================== CONTENT AREA ====================
local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, -220, 1, -65)
contentFrame.Position = UDim2.new(0, 220, 0, 55)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local tabContents = {}

-- Home Tab (unchanged)
local homeFrame = Instance.new("Frame")
homeFrame.Name = "Home"
homeFrame.Size = UDim2.new(1, 0, 1, 0)
homeFrame.BackgroundTransparency = 1
homeFrame.Visible = true
homeFrame.Parent = contentFrame

local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.new(0, 180, 0, 180)
avatar.Position = UDim2.new(0.5, -90, 0, 30)
avatar.BackgroundTransparency = 1
avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
avatar.Parent = homeFrame

local avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(1, 0)
avatarCorner.Parent = avatar

local avatarStroke = Instance.new("UIStroke")
avatarStroke.Color = Color3.fromRGB(100, 100, 255)
avatarStroke.Thickness = 4
avatarStroke.Parent = avatar

spawn(function()
	local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
	if isReady then avatar.Image = content end
end)

local usernameLabel = Instance.new("TextLabel")
usernameLabel.Size = UDim2.new(0, 400, 0, 40)
usernameLabel.Position = UDim2.new(0.5, -200, 0, 240)
usernameLabel.BackgroundTransparency = 1
usernameLabel.Text = "@" .. player.Name
usernameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
usernameLabel.TextSize = 26
usernameLabel.Font = Enum.Font.GothamBold
usernameLabel.Parent = homeFrame

local displayLabel = Instance.new("TextLabel")
displayLabel.Size = UDim2.new(0, 400, 0, 30)
displayLabel.Position = UDim2.new(0.5, -200, 0, 275)
displayLabel.BackgroundTransparency = 1
displayLabel.Text = player.DisplayName
displayLabel.TextColor3 = Color3.fromRGB(180, 180, 255)
displayLabel.TextSize = 20
displayLabel.Font = Enum.Font.Gotham
displayLabel.Parent = homeFrame

local idLabel = Instance.new("TextLabel")
idLabel.Size = UDim2.new(0, 400, 0, 30)
idLabel.Position = UDim2.new(0.5, -200, 0, 310)
idLabel.BackgroundTransparency = 1
idLabel.Text = "User ID: " .. player.UserId
idLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
idLabel.TextSize = 18
idLabel.Font = Enum.Font.Gotham
idLabel.Parent = homeFrame

local ageLabel = Instance.new("TextLabel")
ageLabel.Size = UDim2.new(0, 400, 0, 30)
ageLabel.Position = UDim2.new(0.5, -200, 0, 340)
ageLabel.BackgroundTransparency = 1
ageLabel.Text = "Account Age: " .. player.AccountAge .. " days"
ageLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
ageLabel.TextSize = 18
ageLabel.Font = Enum.Font.Gotham
ageLabel.Parent = homeFrame

tabContents["Home"] = homeFrame

-- Executor Tab (unchanged except colors)
local executorFrame = Instance.new("Frame")
executorFrame.Name = "Executor"
executorFrame.Size = UDim2.new(1, 0, 1, 0)
executorFrame.BackgroundTransparency = 1
executorFrame.Visible = false
executorFrame.Parent = contentFrame

local scriptBox = Instance.new("TextBox")
scriptBox.Size = UDim2.new(1, -40, 0, 320)
scriptBox.Position = UDim2.new(0, 20, 0, 20)
scriptBox.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
scriptBox.TextColor3 = Color3.fromRGB(255, 255, 255)
scriptBox.TextSize = 16
scriptBox.Font = Enum.Font.Code
scriptBox.TextXAlignment = Enum.TextXAlignment.Left
scriptBox.TextYAlignment = Enum.TextYAlignment.Top
scriptBox.TextWrapped = true
scriptBox.ClearTextOnFocus = false
scriptBox.MultiLine = true
scriptBox.PlaceholderText = "-- Paste or load your script here..."
scriptBox.Parent = executorFrame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 12)
boxCorner.Parent = scriptBox

local boxStroke = Instance.new("UIStroke")
boxStroke.Color = Color3.fromRGB(60, 60, 80)
boxStroke.Thickness = 1
boxStroke.Parent = scriptBox

local btnContainer = Instance.new("Frame")
btnContainer.Size = UDim2.new(1, -40, 0, 60)
btnContainer.Position = UDim2.new(0, 20, 0, 360)
btnContainer.BackgroundTransparency = 1
btnContainer.Parent = executorFrame

local function createExecButton(text, color, xOffset, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 180, 1, 0)
	btn.Position = UDim2.new(0, xOffset, 0, 0)
	btn.BackgroundColor3 = color
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.TextSize = 18
	btn.Font = Enum.Font.GothamBold
	btn.Parent = btnContainer
	
	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 12)
	bCorner.Parent = btn
	
	local scaleIn = TweenService:Create(btn, TweenInfo.new(0.15), {Size = UDim2.new(0, 190, 1.08, 0)})
	local scaleOut = TweenService:Create(btn, TweenInfo.new(0.15), {Size = UDim2.new(0, 180, 1, 0)})
	
	btn.MouseButton1Click:Connect(callback)
	btn.MouseEnter:Connect(function() scaleIn:Play() end)
	btn.MouseLeave:Connect(function() scaleOut:Play() end)
	return btn
end

createExecButton("EXECUTE", Color3.fromRGB(80, 220, 100), 0, function()
	local code = scriptBox.Text
	if code == "" then return end
	local success, err = pcall(function() loadstring(code)() end)
	if success then
		showNotification("Executed successfully!", Color3.fromRGB(80, 220, 100))
	else
		showNotification("Error: " .. tostring(err), Color3.fromRGB(255, 80, 80))
	end
end)

createExecButton("CLEAR", Color3.fromRGB(255, 100, 100), 200, function()
	scriptBox.Text = ""
	showNotification("Script cleared", Color3.fromRGB(200, 200, 200))
end)

createExecButton("EXECUTE + CLEAR", Color3.fromRGB(100, 180, 255), 400, function()
	local code = scriptBox.Text
	if code == "" then return end
	local success, err = pcall(function() loadstring(code)() end)
	scriptBox.Text = ""
	if success then
		showNotification("Executed & cleared", Color3.fromRGB(80, 220, 100))
	else
		showNotification("Error: " .. tostring(err), Color3.fromRGB(255, 80, 80))
	end
end)

tabContents["Executor"] = executorFrame

-- Cloud Tab - LIVE ScriptBlox API
local cloudFrame = Instance.new("Frame")
cloudFrame.Name = "Cloud"
cloudFrame.Size = UDim2.new(1, 0, 1, 0)
cloudFrame.BackgroundTransparency = 1
cloudFrame.Visible = false
cloudFrame.Parent = contentFrame

-- Search Bar
local searchContainer = Instance.new("Frame")
searchContainer.Size = UDim2.new(1, -40, 0, 50)
searchContainer.Position = UDim2.new(0, 20, 0, 20)
searchContainer.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
searchContainer.Parent = cloudFrame

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 12)
searchCorner.Parent = searchContainer

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -140, 1, -10)
searchBox.Position = UDim2.new(0, 10, 0, 5)
searchBox.BackgroundTransparency = 1
searchBox.PlaceholderText = "Search ScriptBlox scripts..."
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.TextSize = 18
searchBox.Font = Enum.Font.Gotham
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent = searchContainer

local searchBtn = Instance.new("TextButton")
searchBtn.Size = UDim2.new(0, 120, 1, -10)
searchBtn.Position = UDim2.new(1, -130, 0, 5)
searchBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
searchBtn.Text = "SEARCH"
searchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBtn.TextSize = 16
searchBtn.Font = Enum.Font.GothamBold
searchBtn.Parent = searchContainer

local searchBtnCorner = Instance.new("UICorner")
searchBtnCorner.CornerRadius = UDim.new(0, 10)
searchBtnCorner.Parent = searchBtn

local cloudScroll = Instance.new("ScrollingFrame")
cloudScroll.Size = UDim2.new(1, -40, 1, -90)
cloudScroll.Position = UDim2.new(0, 20, 0, 80)
cloudScroll.BackgroundTransparency = 1
cloudScroll.ScrollBarThickness = 6
cloudScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 255)
cloudScroll.Parent = cloudFrame

local cloudLayout = Instance.new("UIListLayout")
cloudLayout.Padding = UDim.new(0, 15)
cloudLayout.SortOrder = Enum.SortOrder.LayoutOrder
cloudLayout.Parent = cloudScroll

cloudScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
cloudLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	cloudScroll.CanvasSize = UDim2.new(0, 0, 0, cloudLayout.AbsoluteContentSize.Y + 40)
end)

local function createCloudCard(scriptData)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -20, 0, 110)
	card.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
	card.Parent = cloudScroll
	
	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 14)
	cCorner.Parent = card
	
	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(60, 60, 80)
	cStroke.Parent = card
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.65, 0, 0, 40)
	title.Position = UDim2.new(0, 20, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = scriptData.title
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card
	
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(0.65, 0, 0, 40)
	desc.Position = UDim2.new(0, 20, 0, 50)
	desc.BackgroundTransparency = 1
	desc.Text = (scriptData.game and scriptData.game.name or "Universal") .. (scriptData.verified and " • Verified" or "")
	desc.TextColor3 = Color3.fromRGB(160, 160, 180)
	desc.TextSize = 16
	desc.Font = Enum.Font.Gotham
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Parent = card
	
	local loadBtn = Instance.new("TextButton")
	loadBtn.Size = UDim2.new(0, 110, 0, 40)
	loadBtn.Position = UDim2.new(1, -130, 0, 15)
	loadBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
	loadBtn.Text = "LOAD"
	loadBtn.TextColor3 = Color3.fromRGB(255,255,255)
	loadBtn.TextSize = 16
	loadBtn.Font = Enum.Font.GothamBold
	loadBtn.Parent = card
	
	local loadCorner = Instance.new("UICorner")
	loadCorner.CornerRadius = UDim.new(0, 10)
	loadCorner.Parent = loadBtn
	
	loadBtn.MouseButton1Click:Connect(function()
		scriptBox.Text = scriptData.script or "-- Script code not available"
		switchTab("Executor")
		showNotification("Loaded \"" .. scriptData.title .. "\"", Color3.fromRGB(100, 100, 255))
	end)
	
	local execBtn = Instance.new("TextButton")
	execBtn.Size = UDim2.new(0, 110, 0, 40)
	execBtn.Position = UDim2.new(1, -130, 0, 60)
	execBtn.BackgroundColor3 = Color3.fromRGB(80, 220, 100)
	execBtn.Text = "EXECUTE"
	execBtn.TextColor3 = Color3.fromRGB(255,255,255)
	execBtn.TextSize = 16
	execBtn.Font = Enum.Font.GothamBold
	execBtn.Parent = card
	
	local execCorner = Instance.new("UICorner")
	execCorner.CornerRadius = UDim.new(0, 10)
	execCorner.Parent = execBtn
	
	execBtn.MouseButton1Click:Connect(function()
		if not scriptData.script then
			showNotification("Script code not loaded", Color3.fromRGB(255, 80, 80))
			return
		end
		local success, err = pcall(function()
			loadstring(scriptData.script)()
		end)
		if success then
			showNotification(scriptData.title .. " executed!", Color3.fromRGB(80, 220, 100))
		else
			showNotification("Error: " .. tostring(err), Color3.fromRGB(255, 80, 80))
		end
	end)
end

local function fetchScripts(query)
	-- Clear old cards
	for _, child in pairs(cloudScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	local url
	if query and query \~= "" then
		url = "https://scriptblox.com/api/script/search?q=" .. HttpService:UrlEncode(query) .. "&max=15&mode=free"
	else
		url = "https://scriptblox.com/api/script/fetch?max=15&mode=free"
	end
	
	local success, response = pcall(function()
		return HttpService:GetAsync(url, true)
	end)
	
	if not success then
		showNotification("Failed to connect to ScriptBlox", Color3.fromRGB(255, 80, 80))
		return
	end
	
	local data = HttpService:JSONDecode(response)
	local scriptsList = data.result and data.result.scripts or {}
	
	for _, scriptData in ipairs(scriptsList) do
		createCloudCard(scriptData)
	end
	
	if #scriptsList == 0 then
		showNotification("No scripts found", Color3.fromRGB(200, 200, 200))
	end
end

searchBtn.MouseButton1Click:Connect(function()
	fetchScripts(searchBox.Text)
end)

searchBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		fetchScripts(searchBox.Text)
	end
end)

-- Load initial scripts (free recent scripts)
spawn(function()
	wait(0.5)
	fetchScripts("")
end)

tabContents["Cloud"] = cloudFrame

-- Settings Tab (unchanged)
local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "Settings"
settingsFrame.Size = UDim2.new(1, 0, 1, 0)
settingsFrame.BackgroundTransparency = 1
settingsFrame.Visible = false
settingsFrame.Parent = contentFrame

local settingsTitle = Instance.new("TextLabel")
settingsTitle.Size = UDim2.new(1, 0, 0, 50)
settingsTitle.Position = UDim2.new(0, 0, 0, 20)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "Settings"
settingsTitle.TextColor3 = Color3.fromRGB(255,255,255)
settingsTitle.TextSize = 28
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.Parent = settingsFrame

local function createToggle(name, default, yPos, callback)
	local toggleFrame = Instance.new("Frame")
	toggleFrame.Size = UDim2.new(0.9, 0, 0, 60)
	toggleFrame.Position = UDim2.new(0.05, 0, 0, yPos)
	toggleFrame.BackgroundTransparency = 1
	toggleFrame.Parent = settingsFrame
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.fromRGB(220,220,220)
	label.TextSize = 20
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = toggleFrame
	
	local switch = Instance.new("TextButton")
	switch.Size = UDim2.new(0, 70, 0, 36)
	switch.Position = UDim2.new(1, -90, 0.5, -18)
	switch.BackgroundColor3 = default and Color3.fromRGB(80, 220, 100) or Color3.fromRGB(60, 60, 70)
	switch.Text = ""
	switch.Parent = toggleFrame
	
	local switchCorner = Instance.new("UICorner")
	switchCorner.CornerRadius = UDim.new(1, 0)
	switchCorner.Parent = switch
	
	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 28, 0, 28)
	knob.Position = default and UDim2.new(1, -34, 0.5, -14) or UDim2.new(0, 4, 0.5, -14)
	knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
	knob.Parent = switch
	
	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob
	
	local toggled = default
	switch.MouseButton1Click:Connect(function()
		toggled = not toggled
		local goalColor = toggled and Color3.fromRGB(80, 220, 100) or Color3.fromRGB(60, 60, 70)
		local goalPos = toggled and UDim2.new(1, -34, 0.5, -14) or UDim2.new(0, 4, 0.5, -14)
		TweenService:Create(switch, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = goalColor}):Play()
		TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = goalPos}):Play()
		if callback then callback(toggled) end
	end)
end

createToggle("Enable Animations", true, 100, nil)
createToggle("Show Notifications", true, 180, nil)
createToggle("Auto-Execute Clipboard", false, 260, nil)
createToggle("Dark Theme (Default)", true, 340, nil)

tabContents["Settings"] = settingsFrame

-- Tab Switcher
function switchTab(tabName)
	for name, frame in pairs(tabContents) do
		frame.Visible = (name == tabName)
	end
	
	for name, btn in pairs(tabButtons) do
		local highlight = btn:FindFirstChild("Highlight")
		if highlight then highlight.Visible = (name == tabName) end
		if name == tabName then
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 60)}):Play()
		else
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 42)}):Play()
		end
	end
end

-- Notification System
local notificationFrame = Instance.new("Frame")
notificationFrame.Size = UDim2.new(0, 320, 0, 70)
notificationFrame.Position = UDim2.new(1, -340, 1, -100)
notificationFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
notificationFrame.BorderSizePixel = 0
notificationFrame.Visible = false
notificationFrame.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 14)
notifCorner.Parent = notificationFrame

local notifStroke = Instance.new("UIStroke")
notifStroke.Color = Color3.fromRGB(100, 100, 255)
notifStroke.Thickness = 2
notifStroke.Parent = notificationFrame

local notifLabel = Instance.new("TextLabel")
notifLabel.Size = UDim2.new(1, -20, 1, -20)
notifLabel.Position = UDim2.new(0, 10, 0, 10)
notifLabel.BackgroundTransparency = 1
notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifLabel.TextSize = 18
notifLabel.Font = Enum.Font.GothamSemibold
notifLabel.TextWrapped = true
notifLabel.Parent = notificationFrame

function showNotification(text, color)
	notificationFrame.BackgroundColor3 = color or Color3.fromRGB(28, 28, 38)
	notifLabel.Text = text
	notificationFrame.Visible = true
	
	local slideIn = TweenService:Create(notificationFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -340, 1, -100)})
	slideIn:Play()
	
	wait(3)
	local slideOut = TweenService:Create(notificationFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Position = UDim2.new(1, -340, 1, 20)})
	slideOut:Play()
	slideOut.Completed:Connect(function() notificationFrame.Visible = false end)
end

-- Keybind
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		screenGui.Enabled = not screenGui.Enabled
	end
end)

-- Initial setup
switchTab("Home")
showNotification("Nicecat EXE v1.0.0 loaded successfully! Press RightShift to toggle", Color3.fromRGB(100, 100, 255))

-- Open animation
mainFrame.Position = UDim2.new(0.5, -460, 1.2, 0)
TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -460, 0.5, -280)}):Play()
