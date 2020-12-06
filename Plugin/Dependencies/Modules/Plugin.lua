-- fake plugin environment to prevent giant errors on re-runs.
-- I'm really bad at explaining things, but I did my best for this.

local plugin = plugin; --> actual plugin variable
if(plugin == nil) then --> command bar / similar?
	pcall(function()	
		plugin = PluginManager():CreatePlugin(); --> create plugin
	end)
end

local log = function(text) --> log debug stuff
	if(plugin:GetSetting("Debug") == true) then --> check if it's enabled
		warn(text)
	end
end

local instanceMethods = {
	"ClearAllChildren","FindFirstChild","GetDebugId","GetChildren",
	"FindFirstAncestorOfClass","IsDescendantOf","SetAttribute","Destroy",
	"GetAttribute","WaitForChild","FindFirstChildWhichIsA","GetPropertyChangedSignal",
	"GetAttributeChangedSignal","GetDescendants","FindFirstAncestorWhichIsA","IsAncestorOf",
	"Clone","GetFullName","FindFirstAncestor","GetAttributes","IsA","FindFirstChildOfClass",
}

local pluginMethods = {
	"Activate","GetJoinMode","GetMouse","SetSetting","ImportFbxRig",
	"Deactivate","GetSetting","GetStudioUserId","ImportFbxAnimation",
	"Union","StartDrag","Separate","OpenWikiPage","SaveSelectedToRoblox",
	"SelectRibbonTool","PromptForExistingAssetId","CreatePluginMenu",
	"CreatePluginAction","IsActivated","PromptSaveSelection",
	"IsActivatedWithExclusiveMouse","OpenScript","Negate","GetSelectedRibbonTool",
}

local wrapped = {}; --> Fake "plugin" variable behavior
local behavior = {}; --> This will replace functions that I want to modify.
local toolbars = {}; --> Toolbars created with this
local toolbar_buttons = {}; --> Buttons created with this
local button_connections = {}; --> .Click connections.
local widgets = {}; --> Widgets created on here

local function wrapButton(button,key)
	local wrapped = {}; --> Fake button
	local behavior = {}; --> Button behavior / properties
	local fakeEvent = {}; --> Fake button.Click event.
	setmetatable(fakeEvent,{ --> Fake event tostring thing, ex: print(button.Click)
		__tostring = function()
			return tostring(button.Click);
		end
	})
	
	function register(callback) --> To prevent duplicating the code below.
		local connection = {}; --> Fake connection
		setmetatable(connection,{
			__tostring = function() --> Again with the fake tostring() thing.
				return "Connection";
			end
		})

		local signal;
		signal = button.Click:Connect(callback); --> Real signal

		function connection:Disconnect() --> Disconnect it, if needed.
			connection.Connected = false;
			return signal:Disconnect(); --> Disconnect real signal.
		end

		connection.Connected = true; --> Some people probably rely on this.

		if(callback ~= nil) then
			if(button_connections[key] == nil) then --> Do the button connections exist?
				button_connections[key] = {}; --> If not, create a connection table.
			end
			table.insert(button_connections[key],signal); --> Add the connection to the list. They can be bulk disconnected when ran again.
		end

		return connection;
	end
	
	function fakeEvent:Connect(callback) --> Fake event connect, to disconnect on new runs.
		register(callback);
	end
	
	function fakeEvent:connect(callback) --> Enable :connect AND :Connect
		register(callback);
	end
	
	function fakeEvent:Wait() --> never tested if this worked
		return button.Click:Wait();
	end
	
	behavior.Click = fakeEvent; --> Define the fake event
	function behavior:SetActive(bool)
		button:SetActive(bool);
	end
	
	setmetatable(behavior,{ --> If the behavior doesn't exist, it'll check the actual button object.
		__index = function(t,k)
			if(table.find(instanceMethods,k) ~= nil) then
				return function(...)
					return button[k](button,...);
				end
			else
				return button[k];
			end
		end;
	})
	
	setmetatable(wrapped,{ --> Create the wrapped object
		__index = behavior,
		__tostring = function() --> Fake tostring(), ex: print(button)
			return tostring(button);
		end,
		__newindex = function(t,k,v)
			button[k] = v;
		end
	})
	
	return wrapped; --> Return the wrapped button
end

local function createToolbar(name) --> Create a wrapped toolbar
	local original = name; --> Original toolbar name
	local actual = plugin:CreateToolbar(name); --> Create the real toolbar
	local wrapped = {}; --> Returned toolbar
	local behavior = {}; --> Toolbar behavior
	
	function behavior:CreateButton(...) --> Custom :CreateButton() function.
		local key = tostring(name).."-"..tostring(original); --> Ex: button-toolbar
		local tuple = {...}; --> Arguments
		local name = tuple[1]; --> Hopefully the name exists
		if(name ~= nil) then --> Just making sure
			if(toolbar_buttons[key] ~= nil) then --> Does the toolbar button already exist?
				pcall(function() --> Disconnect .Click events if enabled
					if(plugin:GetSetting("Disconnect") == true) then
						local tbl = button_connections[key]; --> Defined at line "73"
						for i = 1,#tbl do --> Loop through .Click connections
							tbl[i]:Disconnect(); --> Disconnect them
							tbl[i] = nil; --> Remove from the table
						end
					end
				end)
				
				log(string.format("Button %q already exists in toolbar %q!",tostring(name),tostring(original))); --> Log debug data
				return toolbar_buttons[key]; --> Prevent the game from creating another button (will error)
			end
		end
		local old;
		local s,e = pcall(function()
			old = actual:CreateButton(unpack(tuple)); --> Create a button with the passed arguments
		end)
		if(old == nil) then --> Did something go wrong?
			if(not s) then --> Did it fail?
				error(e); --> Error display
			end
		else
			old = wrapButton(old,key); --> Wrap the button and create the fake .Click event defined above.
			toolbar_buttons[key] = old; --> Define the button foro future reference.
		end
		return old; --> Provide the wrapped button.
	end
	
	setmetatable(behavior,{ --> If the behavior doesn't exist, rely on the actual toolbar object.
		__index = actual;
	})
	
	setmetatable(wrapped,{ --> Set up the wrapped behavior 
		__index = behavior;
		__tostring = function() --> Ex: print(toolbar)
			return tostring(actual);
		end,
		__newindex = function(t,k,v)
			actual[k] = v;
		end
	})
	
	return wrapped; --> Provide the wrapped object
end

function behavior:CreateToolbar(name) --> Wrapped toolbar method
	if(name ~= nil) then --> Did you for some reason not pass the name? 
		if(toolbars[tostring(name)] ~= nil) then --> Check if you already created a toolbar w/ that name.
			log(string.format("Toolbar %q already exists!",tostring(name))); --> Log to debug
			return toolbars[tostring(name)]; --> Return the existing toolbar
		end
	end
	local old; 
	local s,e = pcall(function()
		old = createToolbar(name); --> Create the wrapped toolbar specified above.
	end)
	if(old == nil) then --> Did something go wrong?
		if(not s) then --> Did it fail?
			error(e); --> Error display
		end
	else
		toolbars[tostring(name)] = old; --> Define the toolbar for future reference
	end
	return old; --> Return the created toolbar
end

function behavior:CreateDockWidgetPluginGui(name,details) --> Wrapped DockWidget method.
	if(name ~= nil) then --> Did you for some reason not pass the name?
		if(widgets[tostring(name)] ~= nil) then --> Check if you already made a widget with that name.
			pcall(function()
				widgets[tostring(name)]:Destroy(); --> Destroy the existing widget (usable with refreshing)
				widgets[tostring(name)] = nil; --> Remove it's existance in the table
			end)
		end
	end
	local old;
	local s,e = pcall(function()
		old = plugin:CreateDockWidgetPluginGui(name,details); --> Create the widget (no wrapping)
	end)
	if(old == nil) then --> Did something go wrong?
		if(not s) then --> Did it fail?
			error(e); --> Error display
		end
	else
		widgets[tostring(name)] = old; --> Define the widget for reference
	end
	return old; --> Return the created widget
end

setmetatable(behavior,{ --> If the method doesn't exist in the "behavior" table, check the "plugin" object.
	__index = function(t,k)
		if(table.find(pluginMethods,k) ~= nil or table.find(instanceMethods,k) ~= nil) then --> check if the method is a : one
			return function(...) --> return a false function
				local args = {...}; --> fetch passed arguments
				table.remove(args,1); --> remove the first argument (it breaks things lol)
				return plugin[k](plugin,unpack(args)); --> call actual function with arguments
			end
		else
			return plugin[k]; --> just return the property/function
		end
	end;
})

setmetatable(wrapped,{ --> Finalize wrapped behavior
	__index = behavior; --> Index
	__tostring = function() --> Ex: print(plugin)
		return tostring(plugin);
	end;
	__newindex = function(t,k,v) --> ex: plugin.Name = "hi"
		plugin[k] = v;
	end
})

return wrapped;