local keys = {}; 
local ui = require(script.Parent:WaitForChild("Dependencies"):WaitForChild("UI"))(script.Parent:WaitForChild("Dependencies"));
local run = require(script.Parent:WaitForChild("Loadstring")); --> loadstring() alternative
local psuedoPlugin = require(script.Parent:WaitForChild("Dependencies"):WaitForChild("Modules"):WaitForChild("Plugin")); --> psuedo plugin thing
local initializeSettings = require(script.Parent:WaitForChild("Dependencies"):WaitForChild("Modules"):WaitForChild("Settings")); --> settings widget

getfenv().quick_run_plugin_scripts = {}; --> the "script" variable container, ex: script.Parent
getfenv().quick_run_plugin_env = { --> some variables that'll be added to each run script
	["plugin"] = psuedoPlugin;
}

local addEnv = function(source,key)
	local template = string.format([[
		local script = quick_run_plugin_scripts[%q]; 
		local plugin = quick_run_plugin_env['plugin']
	]],key); --> adds a psuedo plugin environment

	return template.."\n"..source; --> add the environment to the source code
end

local createGUID = function()
	return game:GetService("HttpService"):GenerateGUID():match("{(.-)}") --> generate a unique ID and remove the "{}" from it.
end

local getScripts = function(holder) --> get all the scripts in a certain object
	local tbl = {}; --> scripts holder
	local check = function(obj) --> check if it's a valid script
		local guid = createGUID(); --> generate a unique ID to enable the "script" variable seen earlier.
		if(obj.ClassName:find("Script") and obj.ClassName ~= "ModuleScript") then --> Check if it's a valid "Script" but not a "ModuleScript"
			table.insert(tbl,obj); --> add to the valid scripts to return
			getfenv().quick_run_plugin_scripts[guid] = obj; --> add the "script" variable thing
			keys[obj] = guid; --> define the object's identifier to be found later
		end
	end
	check(holder); --> let's see if the object that you ran is a script
	for _,v in pairs(holder:GetDescendants()) do --> check if every descendant of the object you ran is a script
		check(v);
	end
	return tbl; --> return :)
end

local init = function(object) --> initialize a plugin that's selected
	if(object ~= nil) then --> make sure that whatever is sent isn't nil
		local scripts = getScripts(object); --> get all scripts for the object
		for i = 1,#scripts do --> loop through the scripts
			coroutine.wrap(function() 
				run(addEnv(scripts[i].Source,keys[scripts[i]]))(); --> load the code and add the environment
			end)();
		end
	end
end

local toolbar = plugin:CreateToolbar("QuickRun"); --> create the toolbar
local button = toolbar:CreateButton("Run","Quickly run a plugin for testing.","rbxassetid://6050898162"); --> add the run button
local configuration = toolbar:CreateButton("Settings","Configure:tm:","rbxassetid://6051237663");

button.Click:Connect(function() --> detect clicks
	init(game:GetService("Selection"):Get()[1]); --> quick-run
end)

if(plugin:GetSetting("Disconnect") == nil) then --> Does the disconnect setting not exist? (First-install)
	plugin:SetSetting("Disconnect",true); --> Enable it
end

initializeSettings(configuration,psuedoPlugin,plugin); --> Run the settings module