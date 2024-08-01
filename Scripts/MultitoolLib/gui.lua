function Multitool.toolBtnCallback(self, toolno)

end

function Multitool.tabCallback(self, tabName)
	if tabName == "ConnectToolsTab" then
		self.gui:setButtonState("ConnectToolsTab", true)
		self.gui:setButtonState("BlueprintToolsTab", false)
		self.gui:setButtonState("AdvancedToolFunctionsTab", false)
	elseif tabName == "BlueprintToolsTab" then
		self.gui:setButtonState("ConnectToolsTab", false)
		self.gui:setButtonState("BlueprintToolsTab", true)
		self.gui:setButtonState("AdvancedToolFunctionsTab", false)
	elseif tabName == "AdvancedToolFunctionsTab" then
		self.gui:setButtonState("ConnectToolsTab", false)
		self.gui:setButtonState("BlueprintToolsTab", false)
		self.gui:setButtonState("AdvancedToolFunctionsTab", true)
	end
	self.guidata.tab = tabName
end