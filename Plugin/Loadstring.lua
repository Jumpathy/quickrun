-- prevent use of loadstring(code)() 
-- this is a simple VM which replicates loadstring()() in it's entirety
-- not written by me

local waitDeps = {
	'Rerubi';
	'LuaK';
	'LuaP';
	'LuaU';
	'LuaX';
	'LuaY';
	'LuaZ';
}

local holder = script.Parent:WaitForChild("Dependencies"):WaitForChild("VM");
for i,v in pairs(waitDeps) do holder:WaitForChild(v) end

local luaX = require(holder.LuaX)
local luaY = require(holder.LuaY)
local luaZ = require(holder.LuaZ)
local luaU = require(holder.LuaU)
local rerubi = require(holder.Rerubi)

luaX:init()
local LuaState = {}

getfenv().script = nil

return function(str,env)
	local f,writer,buff,name
	local env = env or getfenv(2)
	local name = (env.script and env.script:GetFullName())
	local ran,error = pcall(function()
		local zio = luaZ:init(luaZ:make_getS(str), nil)
		if not zio then return error() end
		local func = luaY:parser(LuaState, zio, nil, name or "Plugin_Env")
		writer, buff = luaU:make_setS()
		luaU:dump(LuaState, func, writer, buff)
		f = rerubi(buff.data, env)
	end)
	
	if ran then
		return f,buff.data
	else
		return nil,error
	end
end