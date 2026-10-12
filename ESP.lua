local Plrs = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local WS = game:GetService("Workspace")
local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local LP = Plrs.LocalPlayer
local Cam = WS.CurrentCamera

local TAG = "CW_ESP_V4_5"
local FILE = "coldwar_esp_cfg.json"
if _G[TAG] then pcall(_G[TAG]) end

local pal = {
	{n = "Red", c = Color3.fromRGB(255, 30, 30)},
	{n = "Green", c = Color3.fromRGB(30, 255, 30)},
	{n = "Blue", c = Color3.fromRGB(0, 150, 255)},
	{n = "Yellow", c = Color3.fromRGB(255, 215, 0)},
	{n = "Purple", c = Color3.fromRGB(180, 30, 255)},
	{n = "Cyan", c = Color3.fromRGB(0, 255, 220)},
	{n = "White", c = Color3.fromRGB(255, 255, 255)}
}

local cfg = {esp = true, team = true, scale = 1.0, dist = 700, nato = 3, pact = 1}

local function save() pcall(function() if writefile then writefile(FILE, HS:JSONEncode(cfg)) end end) end
local function load() pcall(function() if readfile and isfile and isfile(FILE) then local d = HS:JSONDecode(readfile(FILE)) if d then for k,v in pairs(d) do cfg[k] = v end end end end) end
load()

local run, open, idx = true, true, 1
local items = {
	{n = "Visuals: ESP Boxes", t = "bool", k = "esp"},
	{n = "Options: Team Check", t = "bool", k = "team"},
	{n = "Box Size", t = "num", k = "scale", mn = 0.5, mx = 2.0, st = 0.1},
	{n = "Max Distance", t = "num", k = "dist", mn = 100, mx = 1500, st = 50},
	{n = "Color: NATO Team", t = "col", k = "nato"},
	{n = "Color: PACT Team", t = "col", k = "pact"},
	{n = "System: Reconnect", t = "act", a = "rejoin"},
	{n = "System: Unload Script", t = "act", a = "unload"}
}

local ui = {bg = Drawing.new("Square"), title = Drawing.new("Text"), lines = {}}
local scr = Cam and Cam.ViewportSize or Vector2.new(1024, 768)
local mPos = Vector2.new(50, scr.Y / 3)

ui.bg.Filled = true
ui.bg.Color = Color3.fromRGB(12, 12, 12)
ui.bg.Transparency = 0.9
ui.bg.Size = Vector2.new(270, #items * 24 + 45)
ui.bg.Position = mPos

ui.title.Size = 14
ui.title.Center = true
ui.title.Outline = true
ui.title.Color = Color3.fromRGB(0, 255, 150)
ui.title.Text = "★ ESP CONTROL PANEL ★"
ui.title.Position = Vector2.new(mPos.X + 135, mPos.Y + 12)

for i = 1, #items do
	ui.lines[i] = Drawing.new("Text")
	ui.lines[i].Size = 13
	ui.lines[i].Outline = true
	ui.lines[i].Position = Vector2.new(mPos.X + 15, mPos.Y + 18 + (i * 24))
end

local function upUI()
	if not run then return end
	local cS = Cam and Cam.ViewportSize or Vector2.new(1024, 768)
	local cP = Vector2.new(50, cS.Y / 3)
	ui.bg.Position = cP
	ui.bg.Visible = open
	ui.title.Position = Vector2.new(cP.X + 135, cP.Y + 12)
	ui.title.Visible = open
	for i, v in ipairs(items) do
		local l = ui.lines[i]
		l.Position = Vector2.new(cP.X + 15, cP.Y + 15 + (i * 24))
		l.Visible = open
		if open then
			local txt = ""
			if v.t == "bool" then txt = cfg[v.k] and "[ ON ]" or "[ OFF ]"
			elseif v.t == "num" then txt = v.k == "scale" and string.format("< %.1fx >", cfg[v.k]) or string.format("< %dm >", cfg[v.k])
			elseif v.t == "col" then txt = "< " .. pal[cfg[v.k]].n .. " >"
			elseif v.t == "act" then txt = "[ Press Enter ]" end
			l.Text = (i == idx and "-> " or "") .. v.n .. ": " .. txt
			l.Color = i == idx and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(235, 235, 235)
		end
	end
end

local function getChar(p)
	if not p or not p.Parent then return nil end
	if p.Character and (p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")) then return p.Character end
	for _, f in ipairs({"Players", "Ignore", "Entities"}) do
		local c = WS:FindFirstChild(f)
		if c then
			local ch = c:FindFirstChild(p.Name, true)
			if ch and ch:IsA("Model") and (ch:FindFirstChild("Head") or ch:FindFirstChild("Torso")) then return ch end
		end
	end
	return nil
end

local cache = {}
local function create(p)
	if cache[p] then return end
	local o = Drawing.new("Square")
	o.Thickness = 3
	o.Filled = false
	o.Color = Color3.fromRGB(0, 0, 0)
	o.Visible = false
	
	local b = Drawing.new("Square")
	b.Thickness = 1
	b.Filled = false
	b.Visible = false
	
	local l = Drawing.new("Text")
	l.Center = true
	l.Outline = true
	l.Color = Color3.fromRGB(255, 255, 255)
	l.Visible = false
	
	cache[p] = {o = o, b = b, l = l}
end

local function remove(p)
	if cache[p] then
		pcall(function() cache[p].o:Remove() cache[p].b:Remove() cache[p].l:Remove() end)
		cache[p] = nil
	end
end

local renderConnection
renderConnection = RS.RenderStepped:Connect(function()
	if not run then if renderConnection then renderConnection:Disconnect() end return end
	if not Cam then return end
	pcall(function()
		for p, v in pairs(cache) do
			local ch = getChar(p)
			local root = ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head"))
			if root and cfg.esp and (not cfg.team or (p.Team ~= LP.Team or LP.Team == nil)) and root:IsA("BasePart") then
				local sPos, on = Cam:WorldToViewportPoint(root.Position)
				if on then
					local dist = (Cam.CFrame.Position - root.Position).Magnitude
					if dist <= cfg.dist then
						local sY = math.clamp(2400 / dist, 6, 200) * cfg.scale
						local sX = sY * 0.65
						local col = Color3.fromRGB(255, 255, 255)
						if p.Team then
							col = string.find(string.upper(p.Team.Name), "NATO") and pal[cfg.nato].c or pal[cfg.pact].c
						end
						v.o.Size = Vector2.new(sX, sizeY)
						v.o.Position = Vector2.new(sPos.X - sX / 2, sPos.Y - sY / 2)
						v.o.Visible = true
						
						v.b.Size = v.o.Size
						v.b.Position = v.o.Position
						v.b.Color = col
						v.b.Visible = true
						
						v.l.Size = dist > 300 and 12 or 14
						v.l.Text = string.format("[%dm]", math.floor(dist * 0.3))
						v.l.Position = Vector2.new(sPos.X, sPos.Y - (sY / 2) - 15)
						v.l.Visible = true
						continue
					end
				end
			end
			v.o.Visible = false
			v.b.Visible = false
			v.l.Visible = false
		end
	end)
end)

task.spawn(function()
	while run do
		task.wait(0.25 + math.random() * 0.05)
		pcall(function()
			for _, p in ipairs(Plrs:GetPlayers()) do
				if p ~= LP then
					if getChar(p) then create(p) else remove(p) end
				end
			end
		end)
	end
end)

local inputConnection
inputConnection = UIS.InputBegan:Connect(function(inp, gpe)
	if not run then if inputConnection then inputConnection:Disconnect() end return end
	if gpe then return end
	if inp.KeyCode == Enum.KeyCode.Insert or inp.KeyCode == Enum.KeyCode.KeypadZero then open = not open upUI() return end
	if not open then return end
	
	if inp.KeyCode == Enum.KeyCode.Up then
		idx = idx - 1
		if idx < 1 then idx = #items end
		upUI()
	elseif inp.KeyCode == Enum.KeyCode.Down then
		idx = idx + 1
		if idx > #items then idx = 1 end
		upUI()
	elseif inp.KeyCode == Enum.KeyCode.Left or inp.KeyCode == Enum.KeyCode.Right or inp.KeyCode == Enum.KeyCode.Return then
		local item = items[idx]
		local isR = (inp.KeyCode == Enum.KeyCode.Right or inp.KeyCode == Enum.KeyCode.Return)
		if item.t == "bool" then
			cfg[item.k] = not cfg[item.k]
			save()
		elseif item.t == "num" then
			local st = item.k == "scale" and 0.1 or 50
			local mn = item.k == "scale" and 0.5 or 100
			local mx = item.k == "scale" and 2.0 or 1500
			cfg[item.k] = math.clamp(cfg[item.k] + (isR and st or -st), mn, mx)
			save()
		elseif item.t == "col" then
			local nI = cfg[item.k] + (isR and 1 or -1)
			if nI > #pal then nI = 1 end
			if nI < 1 then nI = #pal end
			cfg[item.k] = nI
			save()
		elseif item.t == "act" then
			if item.a == "rejoin" then
				if _G[TAG] then _G[TAG]() end
				task.wait(0.2)
				pcall(function()
					if game.JobId ~= "" then TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) else TS:Teleport(game.PlaceId, LP) end
				end)
			elseif item.a == "unload" then
				if _G[TAG] then _G[TAG]() end
			end
		end
		upUI()
	end
end)

_G[TAG] = function()
	run = false
	ui.bg:Remove()
	ui.title:Remove()
	for _, l in ipairs(ui.lines) do l:Remove() end
	for p, _ in pairs(cache) do remove(p) end
end

Plrs.PlayerRemoving:Connect(remove)
upUI()





print("======================================================")
print("          ★ ESP FRAMEWORK ACTIVATED ★")
print("======================================================")
print(" [Insert] or [KeypadZero] : Toggle Cheat Menu")
print(" [Arrow Up / Down]        : Navigate List")
print(" [Arrow Left / Right]     : Adjust Slider Values")
print(" [Enter Key]              : Quick Select / Action")
print("======================================================")
