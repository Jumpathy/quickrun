return function(configuration,psuedo,plugin)
	local widget = psuedo:CreateDockWidgetPluginGui("QuickRun Settings", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right,false,false,400,40,350,40)) --> Create the settings widget
	widget.Title = "Settings" --> Set the title
	widget.Name = "QuickRun Settings" --> Set the name
	local ui = script.Parent.Parent:WaitForChild("UI"):WaitForChild("WidgetUI"):Clone(); --> enable the settings ui
	local otherUI = script.Parent.Parent:WaitForChild("UI"):WaitForChild("WidgetUI_Cover"):Clone(); --> enable the settings ui cover
	ui.Parent = widget;
	otherUI.Parent = widget;

	configuration.Click:Connect(function() --> configuration button click
		widget.Enabled = not widget.Enabled; --> toggle the widget
	end)

	local toggles = {ui:WaitForChild("Disconnect"),ui:WaitForChild("Debug")}; --> Toggles
	local clickEvent = function(button,toggle) --> Toggle click event
		button.MouseButton1Click:Connect(function()
			local option = plugin:GetSetting(toggle.Name); --> Get existing option
			if(option ~= nil) then --> Does it exist?
				option = not option;
			else --> Guess not, setting to true.
				option = true;
			end
			plugin:SetSetting(toggle.Name,option); --> Override existing value
			toggle.Toggle.Main.Check.Visible = option; --> Make the actual UI visible.
		end)
	end

	for _,toggle in pairs(toggles) do --> loop through toggles
		local option = plugin:GetSetting(toggle.Name); --> see if the option is enabled
		if(option ~= nil) then
			toggle.Toggle.Main.Check.Visible = option; --> set it to true/false
		end
		clickEvent(toggle.Toggle.Main,toggle); --> connect click event
		clickEvent(toggle.Toggle.Main.Check,toggle); --> connect click event
	end
end