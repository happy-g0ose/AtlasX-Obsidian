--[[
    AtlasX · Obsidian — private loader

    Адрес скрипта закодирован и не лежит в файле открытым текстом.
    Передай этот файл тому, кому доверяешь; публиковать его не стоит.

    Использование: вставить целиком в редактор инжектора → Execute.
    Переопределения (до запуска):
        getgenv().ATLASX_CACHE = false   -- не кэшировать на диск
]]
local KEY = 90
local DATA = "C2CECECACD948989CCBBD188C1C3CEC2CFBCCFCDBFCCBDC9C8CEBFC8CE88BDC9C789C2BBCACAD387C18AC9CDBF899BCEC6BBCDB287A9BCCDC3BEC3BBC889CCBFC0CD89C2BFBBBECD89C7BBC3C8899BCEC6BBCDB288C6CFBB"

local function decode(hex)
	local out = {}
	for i = 1, #hex, 2 do
		local b = tonumber(hex:sub(i, i + 1), 16)
		if not b then return nil end
		out[#out + 1] = string.char((b - KEY) % 256)
	end
	return table.concat(out)
end

local URL = decode(DATA)
if not URL then return warn("[AtlasX] bad loader data") end

local g = (getgenv and getgenv()) or _G
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
	return nil, "HTTP failed on " .. executorName()
end

local function readCache()
	if not (USE_CACHE and isfile and readfile) then return nil end
	local ok, data = pcall(readfile, CACHE)
	if ok and type(data) == "string" and #data > 200 then return data end
	return nil
end

local function writeCache(src)
	if not (USE_CACHE and isfile and writefile) then return end
	pcall(writefile, CACHE, src)
end

notify("Loading AtlasX · " .. executorName())

local source, err = httpGet(URL)
local origin = "remote"
if not source then
	source = readCache()
	origin = "cache"
end
if not source then
	notify(err or "Download failed, no cache found")
	return
end
if origin == "remote" then writeCache(source) end

if _G.atlas then
	pcall(function() _G.atlas:Destroy() end)
	_G.atlas = nil
end
task.wait(0.3)

local chunk, compileError = loadstring(source, "@AtlasX-Obsidian.lua")
if not chunk then
	notify("Compile error: " .. tostring(compileError))
	return
end

_G.loading = nil
local ok, runError = pcall(chunk)
if not ok then
	notify("Runtime error: " .. tostring(runError))
	if debug and debug.traceback then
		local okTrace, trace = pcall(debug.traceback)
		if okTrace then warn("[AtlasX] " .. tostring(trace)) end
	end
	return
end

notify("Loaded " .. tostring(origin))
