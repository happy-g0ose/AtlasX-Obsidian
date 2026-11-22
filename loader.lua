--[[
    AtlasX · Obsidian  —  loader
    Tested target: Delta (also works on most executors with file/HTTP APIs).

    Usage (Delta):
        1. Attach Delta to Roblox.
        2. Paste this whole file into the editor.
        3. Execute.

    Optional overrides (put before running, e.g. in the same editor):
        getgenv().ATLASX_URL   = "https://.../AtlasX.lua"   -- custom source
        getgenv().ATLASX_CACHE = false                       -- do not use disk cache
]]

local REPO    = "happy-g0ose/AtlasX-Obsidian"
local BRANCH  = "main"
local FILE    = "AtlasX.lua"
local VERSION = "1.1"

local g = (getgenv and getgenv()) or _G
local URL   = g.ATLASX_URL or string.format("https://raw.githubusercontent.com/%s/%s/%s", REPO, BRANCH, FILE)
local CACHE = "AtlasX-Obsidian-cache.lua"
local USE_CACHE = g.ATLASX_CACHE ~= false

local function notify(text)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "AtlasX",
			Text = tostring(text),
			Duration = 8,
		})
	end)
	print("[AtlasX] " .. tostring(text))
end

local function executorName()
	local ok, name = pcall(function()
		return (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"
	end)
	return (ok and tostring(name)) or "Unknown"
end

local function httpGet(url)
	local req = request or http_request or httprequest or (syn and syn.request) or (http and http.request)

	if type(req) == "function" then
		local ok, res = pcall(req, { Url = url, Method = "GET" })
		if ok and type(res) == "table" then
			local body = res.Body or res.body
			if type(body) == "string" and #body > 200 then
				return body
			end
		end
	end

	if setfflag then
		pcall(setfflag, "HttpEnabled", "True")
	end

	local ok2, body = pcall(function()
		return game:HttpGet(url, true)
	end)
	if ok2 and type(body) == "string" and #body > 200 then
		return body
	end

	return nil, "HTTP request failed on " .. executorName()
end

local function readCache()
	if not (USE_CACHE and isfile and readfile) then return nil end
	local ok, data = pcall(readfile, CACHE)
	if ok and type(data) == "string" and #data > 200 then
		return data
	end
	return nil
end

local function writeCache(src)
	if not (USE_CACHE and isfile and writefile) then return end
	pcall(writefile, CACHE, src)
end

local function run(source, origin)
	if _G.atlas then
		pcall(function() _G.atlas:Destroy() end)
		_G.atlas = nil
	end
	task.wait(0.3)

	local chunk, compileError = loadstring(source, "@AtlasX-Obsidian.lua")
	if not chunk then
		notify("Compile error: " .. tostring(compileError))
		return false
	end

	_G.loading = nil
	local ok, runError = pcall(chunk)
	if not ok then
		local trace = ""
		if debug and debug.traceback then
			local okTrace, t = pcall(debug.traceback)
			if okTrace then trace = tostring(t) end
		end
		notify("Runtime error: " .. tostring(runError))
		warn("[AtlasX] " .. tostring(runError) .. "\n" .. trace)
		return false
	end

	notify("Loaded " .. VERSION .. " (" .. tostring(origin) .. ")")
	return true
end

notify("Loading AtlasX " .. VERSION .. " · " .. executorName())

local source, err = httpGet(URL)
local origin = "remote"

if not source then
	source = readCache()
	origin = "cache"
end

if not source then
	notify(err or "Download failed and no cache found")
	return
end

if origin == "remote" then
	writeCache(source)
end

run(source, origin)
