--[[
Probably one of my most used modules. 
It helps facilitate the User interface creating process by a ton.

It logs open User interfaces, automatically creates open and close animations, automatically creates perfect grid layouts, and more.
It even has built-in functions for quick UI animations to make UIs look more dynamic.

its a little messy though since it is old. 
]]


--Services--
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
--Booleans--
local AllowInteraction = true

--Player--
local Player    = Players.LocalPlayer
local PlayerGui = Player.PlayerGui or Player:WaitForChild("PlayerGui")
local Camera    = workspace.CurrentCamera

local OriginalFOV = Camera.FieldOfView
local OpenedFOV   = OriginalFOV * 0.75


--Tweens--
local Tweens = {}
Tweens.TweenInfoOpen  = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
Tweens.TweenInfoClose = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
Tweens.ButtonClicked  = TweenInfo.new(0.08)
Tweens.ButtonReleased = TweenInfo.new(0.1)


--ModuleScripts--
local RModules     = ReplicatedStorage.ModuleScripts
local Janitor      = require(RModules.GoodPractices.Janitor)
local Signal       = require(RModules.GoodPractices.Signal)
local SoundManager = require(RModules.Data.SoundManager)
local CustomTypes  = require(RModules.GoodPractices.CustomTypes)
local Logs 		   = require(RModules.GoodPractices.Logs)


--Sounds--
local Sounds = ReplicatedStorage:FindFirstChild("Sounds") or Instance.new("Folder", ReplicatedStorage)
Sounds.Name  = "Sounds"
local GuiSounds = Sounds:FindFirstChild("GuiSounds") or Instance.new("Folder", Sounds)
GuiSounds.Name  = "GuiSounds"


local OpenSound  = SoundManager.CreateSound("Open", GuiSounds, SoundManager.GuiOpenSound)
local CloseSound = SoundManager.CreateSound("Close", GuiSounds, SoundManager.GuiCloseSound)
local ClickSound = SoundManager.CreateSound("ClickSound", GuiSounds, SoundManager.ClickSound)


local BasicSounds = {
	Open = OpenSound,
	Close = CloseSound,
	Click = ClickSound
}


--Constants--
local Factor = 0.95
local ClickFactor = 0.90


--Custom types --
type SoundSettings = CustomTypes.SoundSettings






--Tables--
--[[Idea behind this table: 
Every time a new UI object is created, you have to add a table of exceptions as a property, which accepts 
other UI that are allowed to be opened or interacted with simulatenously. 

The exceptions table can be empty, and if it is, it means that the no other UI is allowed to be opened 
the exception table will consist of a key (UI name), and the a table of Accepted UI as a value. 

Upon opening a new UI, iterate through the openUI table, and go through each exceptions table. if that UI name is not present even in a single one 
of those tables, then do not allow it to be opened. 

If this table is empty then there are no other UI open. 
This means you can open a new UI without a problem
]]
local OpenUI = {}

--[[
██████╗ ██████╗ ██╗██╗   ██╗ █████╗ ████████╗███████╗                         
██╔══██╗██╔══██╗██║██║   ██║██╔══██╗╚══██╔══╝██╔════╝                         
██████╔╝██████╔╝██║██║   ██║███████║   ██║   █████╗                           
██╔═══╝ ██╔══██╗██║╚██╗ ██╔╝██╔══██║   ██║   ██╔══╝                           
██║     ██║  ██║██║ ╚████╔╝ ██║  ██║   ██║   ███████╗                         
╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚═╝  ╚═╝   ╚═╝   ╚══════╝                         
                                                                              
    ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
    ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
    █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
    ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
    ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
    ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
                                                                              
]]

local function HasAnyOpenUI(): boolean
	return next(OpenUI) ~= nil
end


local function CanOpen(UI : string)
	if HasAnyOpenUI() == false then 
		return true 
	end
	local Ok = false
	
	for GUIName, Exceptions : {string} in OpenUI  do
		if table.find(Exceptions, UI) then
			Ok = true
		end
	end
	return Ok
end



local function PlayButtonEffects(Button : GuiObject)
	if not Button:IsA("GuiButton") then 
		Logs.warn("Expected button got %s", Button.Name)
	end
	
	local ButtonSize = Button.Size
	local T1 = TweenService:Create(Button, 
		Tweens.ButtonClicked, 
		{Size = UDim2.new(Factor * Button.Size.X.Scale, Factor * Button.Size.X.Offset, 
			Button.Size.Y.Scale * Factor, Button.Size.Y.Offset * Factor)})
	local T2 = TweenService:Create(Button, Tweens.ButtonReleased, {Size = ButtonSize})
	T1:Play()
	T1.Completed:Wait()
	T2:Play()
	ClickSound:Play()
	T1:Destroy()
	T2:Destroy()
end


local function CountDimensions(ScrollingFrame : ScrollingFrame)
	if not ScrollingFrame:IsA("ScrollingFrame") then 
		error("No scrolling frame found")
	end
	
	
	local Grid = ScrollingFrame:FindFirstChildWhichIsA("UIGridLayout")
	
	if not Grid then 
		error("No UI grid layout found ")
	end
	local Children = ScrollingFrame:GetChildren()

	
	local Slots = 0
	for _, Child in Children  do
		if Child:IsA("GuiObject")  and Child.Visible and Child ~= Grid then
			Slots += 1
		end
	end

	
	local FrameWidth  = ScrollingFrame.AbsoluteSize.X
	local FrameHeight = ScrollingFrame.AbsoluteSize.Y

	
	local CellWidth  = Grid.AbsoluteCellSize.X
	local CellHeight = Grid.AbsoluteCellSize.Y
	local PaddingX   = Grid.CellPadding.X.Offset
	local PaddingY   = Grid.CellPadding.Y.Offset

	--checking how many columns or rows fit WHILE still including the cell padding
	local Columns = math.floor((FrameWidth + PaddingX) / (CellWidth + PaddingX)) 
	local Rows    = math.ceil(Slots / Columns)

	print(Rows, Columns)
	return Rows, Columns

end 

local function GetTotalContentSize(ScrollingFrame : ScrollingFrame)
	local Grid = ScrollingFrame:FindFirstChildWhichIsA("UIGridLayout")
	local UiPadding = ScrollingFrame:FindFirstChildWhichIsA("UIPadding")
	if not Grid then
		warn("No UIGridLayout found inside ScrollingFrame")
		return 0, 0
	end

	local Rows, Columns = CountDimensions(ScrollingFrame)

	local CellWidth  = Grid.CellSize.X.Offset
	local CellHeight = Grid.CellSize.Y.Offset
	local PaddingX   = Grid.CellPadding.X.Offset
	local PaddingY   = Grid.CellPadding.Y.Offset

	local TotalWidth  = Columns * CellWidth + (Columns -1 ) * PaddingX
	local TotalHeight = (Rows * CellHeight + (Rows - 1) * PaddingY)

	if UiPadding then 

		TotalHeight += UiPadding and (UiPadding.PaddingTop.Offset + UiPadding.PaddingBottom.Offset)
	end

	return TotalWidth, TotalHeight
end

--Disables every other ScreenGui's frames interactable property, except for the current one we are using, and other exceptions
local function DisableInteract(WantedScreenGui : ScreenGui, Exceptions : {string})
	print("Exceptions table", Exceptions)
	for _, OtherScreenGui in PlayerGui:GetChildren() do
		if OtherScreenGui:IsA("ScreenGui") then
			if OtherScreenGui.Enabled == false        then continue end 
			if OtherScreenGui == WantedScreenGui      then continue end 
			if table.find(Exceptions, OtherScreenGui.Name) then print("Not disabling this", OtherScreenGui.Name)continue end 

			for _, Frame in OtherScreenGui:GetChildren() do
				if Frame:IsA("Frame") or Frame:IsA("ScrollingFrame") then
					Frame.Interactable = false
					Frame.Active = false
				end
			end
		end
	end 
end

local function EnableInteract()
	if #OpenUI ~= 0 then 
		warn("Other UI is open, interaction is only enabled once all UI is closed")
		return
	end 
	
	
	for _, ScreenGui in PlayerGui:GetChildren() do
		if ScreenGui:IsA("ScreenGui") then
			if ScreenGui.Enabled == false then continue end
			for _, Frame in ScreenGui:GetChildren() do
				if Frame:IsA("Frame") or Frame:IsA("ScrollingFrame") then
					Frame.Interactable = true
					Frame.Active = false
				end
			end
		end
	end
end


local function AddTemplate(Template : GuiObject, ChildrenTable)
	local NewTemplate = Template:Clone()
	NewTemplate.Visible = true

	NewTemplate.Parent = Template.Parent -- or wherever it should go

	for ChildName, PropertyTable in ChildrenTable  do 
		local Child = NewTemplate:FindFirstChild(ChildName, true) 
		if Child then
			for Property, Value in PropertyTable do 
				if Property ~= "Callback" then 
					Child[Property] = Value

				else
					Child.Activated:Connect(function()
						Value(Child)
					end)
				end 
			end
		end 
	end 

	if ChildrenTable["Name"] then 
		NewTemplate.Name = ChildrenTable["Name"](NewTemplate)

	end


	return NewTemplate
end

local function AddTemplateConnectors(Child : GuiObject, TemplateName : string, GuiObject)
	local Connectors = {}
	if Child:IsA("GuiButton") then
		table.insert(Connectors, Child.Activated:Connect(function()
			if GuiObject[TemplateName .. "AnimationsEnabled"] then 
			 print("Looks like the animations are available to play")
			 PlayButtonEffects(Child)
			end 
		end))
	end

	for _, Descendent in Child:GetDescendants() do 
		if Descendent:IsA("GuiButton") then
			table.insert(Connectors, Descendent.Activated:Connect(function()
				if GuiObject[TemplateName .. "AnimationsEnabled"] then 
					print("Looks like the animations are available to play")
					PlayButtonEffects(Descendent)
				end 
				    
			end))
		end
	end

	Child.Destroying:Once(function()
		local Janitor = Janitor.new()
		print("Button destroyed, disconnecting all signals. ")
		Janitor:GiveChore(table.unpack(Connectors))
		Janitor:Destroy()
	end)
end

local function SetUpSounds(Sounds : SoundSettings, Name)
	return {
		Open  = SoundManager.CreateSound("Open" ..  Name, GuiSounds, Sounds.OpenSound ),
		Close = SoundManager.CreateSound("Close" .. Name, GuiSounds, Sounds.CloseSound),
		Click = SoundManager.CreateSound("Click" .. Name, GuiSounds, Sounds.ClickSound)
	}
end

--[[
███╗   ███╗ ██████╗ ██████╗ ██╗   ██╗██╗     ███████╗
████╗ ████║██╔═══██╗██╔══██╗██║   ██║██║     ██╔════╝
██╔████╔██║██║   ██║██║  ██║██║   ██║██║     █████╗  
██║╚██╔╝██║██║   ██║██║  ██║██║   ██║██║     ██╔══╝  
██║ ╚═╝ ██║╚██████╔╝██████╔╝╚██████╔╝███████╗███████╗
╚═╝     ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝╚══════╝
                                                     
                                                    ]]



local GuiMaker2 = {}
GuiMaker2.__index = GuiMaker2

--[[
Expects main frame to be called MainFrame (Could be frame or scrolling frame)
Expects close button to be called Close
A frame called "ScreenLocker" can be added to serve as a background to the UI when opened
If this is an Activations GUI, it will ignore some of the rules set to make it work. 

]]--
GuiMaker2.New = function(ScreenGui : ScreenGui, Exceptions : {string}?, Sounds : SoundSettings?, IsActivation : boolean?)
	local self = setmetatable({}, GuiMaker2)

	self.ParentFrames = {}
	self.OpenTweens   = {}
	self.CloseTweens  = {}
	self.ScreenGui    = ScreenGui
	self.Name  		  = ScreenGui.Name
	self.Exceptions   = Exceptions or {}
	self.Sounds 	  = (Sounds and SetUpSounds(Sounds, self.Name)) or BasicSounds
	self.DynamicFov   = true
	self.IsActivation = (IsActivation ~= nil and IsActivation) or false 


	if ScreenGui:FindFirstChild("ScreenLocker", true) then 
		self.ScreenLocker = ScreenGui.ScreenLocker
	end

	for I, Frame : Frame in ScreenGui:GetChildren() do 
		if Frame:IsA("Frame") or Frame:IsA("ScrollingFrame") then
			table.insert(self.ParentFrames, Frame)
			if Frame.Name == "MainFrame" then 
				self.MainFrame = Frame
			end
		end
	end
	assert(self.MainFrame, "Expected MainFrame, got nil. Did you forget to name the primary frame as MainFrame?")
	if IsActivation then return self end 
	
	
	self.MainFramePos = self.MainFrame.Position.Y.Scale
	--[[One frame might be higher or lower than the other by default, but we need them to tween as if they were 
	connected. So we use the MainFrame as a reference, and calculate the Vertical offsets of the others.]]--
	for I, Frame : Frame in self.ParentFrames do 
		if Frame.Name == "ScreenLocker" then continue end 
		local Offset = Frame.Position.Y.Scale - self.MainFramePos
		--If the offset is in the negatives, then the current frame is HIGHER than the MainFrame.
		
		local InitialPosition = UDim2.new(Frame.Position.X.Scale, 0, 2 + Offset, 0)
		local OpenTween = TweenService:Create(Frame, Tweens.TweenInfoOpen, {Position = Frame.Position})
		
		local CloseTween = TweenService:Create(Frame, Tweens.TweenInfoClose, {Position = InitialPosition})
		Frame.Position = InitialPosition
		table.insert(self.OpenTweens, OpenTween)
		table.insert(self.CloseTweens, CloseTween)

	end


	local CloseButton : GuiButton = ScreenGui:FindFirstChild("Close", true)
	if CloseButton then 
		CloseButton.Activated:Connect(function()
			
			self:Close()

		end)
	else
		warn("It is good practice to have your close button named 'Close'")
	end



	return self
end

--Opens uyi, tweening it to the position it was set to initially
GuiMaker2.Open = function(self)
	if self.IsActivation then warn("Cannot open or close Activations Gui") return end 
	if not CanOpen(self.Name) then return end 
	
	
	if self.ScreenLocker then self.ScreenLocker.Visible = true end
	
	
	OpenUI[self.Name] = self.Exceptions
	

	DisableInteract(self.ScreenGui, self.Exceptions)
	self.ScreenGui.Enabled= true
    

	self.Sounds.Open:Play()
	
	
	if self.DynamicFov then 
	local FovTweenInfo = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	local FovTween = TweenService:Create(
		Camera,
		FovTweenInfo,
		{ FieldOfView = OpenedFOV }
	)
    
	 FovTween:Play()
	 FovTween.Completed:Once(function()
			FovTween:Destroy()
	 end)
	end 
	
	for I, Tween : Tween in self.OpenTweens do 
		Tween:Play()
	end
	
	



end



GuiMaker2.Close = function(self)
	if self.IsActivation then warn("Cannot open or close Activations Gui") return end 
	OpenUI[self.Name] = nil
	
	if self.ScreenLocker then
		self.ScreenLocker.Visible = false
	end
	
	

	self.Sounds.Close:Play()
	EnableInteract()

	for I, Tween : Tween in self.CloseTweens do 
		Tween:Play()
	end
	
    if self.DynamicFov then 
	local FovTweenInfo = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	local FovTween = TweenService:Create(
		Camera,
		FovTweenInfo,
		{ FieldOfView = OriginalFOV}
	)
   
	FovTween:Play()
	
	FovTween.Completed:Once(function()
		FovTween:Destroy()
	end)
	end 

	self.CloseTweens[#self.CloseTweens].Completed:Wait()

	self.ScreenGui.Enabled = false
	AllowInteraction = true

	
end
--If for whatever reason, you don't want to play the Effects of a button, you can Add a BoolValue called "NoEffects" as a direct child of the button.
GuiMaker2.RegisterButton = function(self, Button : GuiButton, PlaySfx : boolean, CallBack : (any) -> ())
	
	
	local ButtonSize = Button.Size
	local T1 = TweenService:Create(Button, 
		Tweens.ButtonClicked, 
		{Size = UDim2.new(Factor * Button.Size.X.Scale, Factor * Button.Size.X.Offset, 
			Button.Size.Y.Scale * Factor, Button.Size.Y.Offset * Factor)})
	local T2 = TweenService:Create(Button, Tweens.ButtonReleased, {Size = ButtonSize})
	
	local T3 = TweenService:Create(Button, 
		Tweens.ButtonClicked, 
		{Size = UDim2.new(ClickFactor * Button.Size.X.Scale, ClickFactor* Button.Size.X.Offset, 
			Button.Size.Y.Scale * ClickFactor, Button.Size.Y.Offset * ClickFactor)})
	
	
	
	if Button:IsA("GuiButton") then
		local Pressed = false
		local Wrapper = Button.Activated:Connect(function()
			

			if PlaySfx then 
				if not Button:FindFirstChild("NoEffects") then
					T3:Play()
					T3.Completed:Wait()
					T2:Play()
					ClickSound:Play()
					
				end 
			end 

			if not Pressed then 
				Pressed = true 
				task.spawn(function()
					CallBack()
					Pressed = false
				end)
			end

		end )
		
		local Wrapper2 = Button.MouseEnter:Connect(function()
			if not Button:FindFirstChild("NoEffects") then
				if T2.PlaybackState == Enum.PlaybackState.Playing then T2.Completed:Wait() end 
				T1:Play()
				
			end
		end)
		
		local Wrapper3 = Button.MouseLeave:Connect(function()
			if not Button:FindFirstChild("NoEffects") then
				if T1.PlaybackState == Enum.PlaybackState.Playing then T1.Completed:Wait() end 
				T2:Play()
			end 
		end)

		Button.Destroying:Once(function()
			print("The button has been destroyed, disconnecting all signals.")
			Wrapper:Disconnect()
			Wrapper2:Disconnect()
		end)
	else
		warn("Object is not a button")
	end 
end


--[[
Templates are used to define reusable GUI elements for grid layouts. To create a template, pass a sample UI element (such as a frame or button) and assign it a name. This allows you to easily replicate and customize the element later.

When calling GuiMaker2.AddSlots(), simply provide:

The name of the template you want to use (TemplateName)

A dictionary containing the properties you want to modify for each descendent instance (e.g., Text, Image, Callback, Name) inside of a table: 

ALL DESCENDENTS MUST HAVE UNIQUE NAMES
Dictionary = {
   [1] = {
         ["ImageLable"] = {Image = "rbxassetId://123", BackgroundColor = Color3.new()}
         ["TextLable"] = {Text = "Hello word", Font = "Fredrick"}
         ["TextButton"] = {Text = "Button", BackgroundTransparency = 1, Callback = function}, --callback is what the button should do once pressed
         ["Name"] == NamingAlgorithm --function that describes how the template name should be made, and only accepts the Template as an argument
         },
         
   [2] = {...},
   
}

You can then access all the cells using GuiMaker2.TemplateName
]]
GuiMaker2.AddCells = function(self, Template : GuiObject, TemplateName : string, Dictionary, NamingAlgorithm : (number, GuiObject) -> string, ExtraFunction : (GuiObject) -> any?)
	local ScrollingFrame = Template.Parent
	assert(ScrollingFrame:IsA("ScrollingFrame"), "Template's parent must be a scrolling frame")
	self[TemplateName .. "ScrollingFrame"] = ScrollingFrame
	self[TemplateName] = {}
	self[TemplateName .. "AnimationsEnabled"] = true

	table.insert(self[TemplateName],Template)
	for Index, Child in Dictionary do 
		local NewTemplate = AddTemplate(Template, Child)
   
		table.insert(self[TemplateName], NewTemplate)
		
		
		if ExtraFunction then
			ExtraFunction(NewTemplate)
		end
	
	end

	for Index, Template : GuiObject in self[TemplateName] do 
		AddTemplateConnectors(Template, TemplateName, self)
	end
	
	


	task.wait(0.1)
	local UiGridLayout : UIGridLayout = ScrollingFrame:FindFirstChildWhichIsA("UIGridLayout")
	local UiPadding : UIPadding = ScrollingFrame:FindFirstChildWhichIsA("UIPadding")
	local X, Y = GetTotalContentSize(ScrollingFrame)

	ScrollingFrame.CanvasSize = UDim2.new(0, X, 0, Y)
end

GuiMaker2.AddCell = function(self, TemplateName : string, ChildrenTable, NamingAlgorithm : (GuiObject) -> string)
	assert(self[TemplateName], "You must have a valid template before adding an individual cell.")
	local ScrollingFrame : ScrollingFrame = self[TemplateName .. "ScrollingFrame"]
	local Template = self[TemplateName][1]
	local NewTemplate = AddTemplate(Template, ChildrenTable )
	AddTemplateConnectors(NewTemplate)
	table.insert(self[TemplateName], NewTemplate)

	NewTemplate.Name = NamingAlgorithm(NewTemplate)
	task.wait(0.1)
	local UiGridLayout : UIGridLayout = ScrollingFrame:FindFirstChildWhichIsA("UIGridLayout")
	local UiPadding : UIPadding = ScrollingFrame:FindFirstChildWhichIsA("UIPadding")
	local X, Y = GetTotalContentSize(ScrollingFrame)

	ScrollingFrame.CanvasSize = UDim2.new(0, X, 0, Y)
end

--Might add other features, if needed. For now it only allows you to edit the layout to top or bottom
GuiMaker2.EditLayout = function( GuiObject , Goal : "Top" | "Bottom")
	local ParentObject : GuiObject = GuiObject.Parent
	local UiGridLayout = ParentObject:FindFirstChildWhichIsA("UIGridLayout")
	local ObjectType = GuiObject.ClassName 

	local Children = {}
	local OriginalLayouts = {}

	for I, Child in ParentObject:GetChildren() do 
		if Child:IsA(ObjectType)  then 
			table.insert(Children, Child)

		end
	end

	table.sort(Children, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	for I, Child in Children do 
		--Normalize the layout orders 
		table.insert(OriginalLayouts, Child.LayoutOrder)
		Child.LayoutOrder = -1 * (#Children-I)

	end


	local GoalOrder = ((Goal == "Top") and (Children[1].LayoutOrder -1)) or (Children[#Children].LayoutOrder + 1)
	local CurrentOrder = GuiObject.LayoutOrder
	local Step = math.sign(GoalOrder - CurrentOrder)

	--	local ChildrenClone = table.clone(Children)
	for I = CurrentOrder, GoalOrder, Step do 
		task.wait()
		GuiObject.LayoutOrder += Step
	end
	GuiObject.LayoutOrder = GoalOrder

	for I, Child in Children do
		if Child == GuiObject then continue end 
		Child.LayoutOrder = OriginalLayouts[I]
	end

end




GuiMaker2.CreateScrollBar = function(self, ScrollFrame : ScrollingFrame, Attachment: ImageLabel, SuspensionLine : ImageLabel | TextLabel, AttchOffset : number?, SuspensionOffset : number?, AnimationName:String)
	AttchOffset = AttchOffset or 0
	SuspensionOffset = SuspensionOffset or 0
	self.StoppedScrolling = Signal.new()
	local InitialAttchPos = Attachment.Position.Y.Scale
	local InitalSuspensionLineSize = SuspensionLine.Size.Y.Scale
	local LastScroll = 0
	local ScrollCooldown = 0 -- Seconds to wait after scrolling stops
	local ScreenGui = ScrollFrame:FindFirstAncestorWhichIsA("ScreenGui")

	-- Track scroll movement using CanvasPosition change
	ScrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		local ContentHeight = ScrollFrame.CanvasSize.Y.Offset
		local ViewHeight = ScrollFrame.AbsoluteSize.Y
		local ScrollY = ScrollFrame.CanvasPosition.Y

		self["CanPlay" .. AnimationName] = false

		local ScrollPercent = math.clamp((ScrollY / (ContentHeight - ViewHeight)), 0, 1)
		local NewSize = (ScrollPercent > InitalSuspensionLineSize and ScrollPercent) or InitalSuspensionLineSize
		SuspensionLine.Size = UDim2.new(SuspensionLine.Size.X.Scale, SuspensionLine.Size.X.Offset, NewSize + SuspensionOffset, SuspensionLine.Size.Y.Offset)
		Attachment.Position = UDim2.new(Attachment.Position.X.Scale, Attachment.Position.X.Offset, ScrollPercent + InitialAttchPos + AttchOffset, Attachment.Position.Y.Offset)


		LastScroll = os.time()
	end)

	-- Timer that checks for inactivity in scrolling
	local function checkScrollingStopped()
		while ScreenGui.Enabled do
			task.wait(0.01) 


			if os.time() - LastScroll >= ScrollCooldown and LastScroll ~= 0 then

				self.StoppedScrolling:Call()



				-- Reset LastScroll to avoid triggering the stop message multiple times
				LastScroll = 0
			end
		end

	end

	ScreenGui:GetPropertyChangedSignal("Enabled"):Connect(function()

		if ScreenGui.Enabled then 
			spawn(checkScrollingStopped)
		end
	end)

	spawn(checkScrollingStopped)



end


GuiMaker2.ScrollByASlot = function(ScrollingFrame : ScrollingFrame, Left : boolean)
	local Layout = ScrollingFrame:FindFirstChildOfClass("UIListLayout")
	if not Layout then
		warn("No UIListLayout found inside the ScrollingFrame!")
		return
	end
	
	-- Uses the first visible item to calculate the width (Absolute size)
	
	local FirstItem 
	for _, Child in ScrollingFrame:GetChildren() do
		if Child:IsA("GuiObject") and Child.Visible and Child ~= Layout then
			FirstItem = Child
			break
		end
	end
	if not FirstItem then 
		warn("No visible items to scroll to!")
		return
	end
	
	
	local Step = FirstItem.AbsoluteSize.X
		  + Layout.Padding.Offset
		  + Layout.Padding.Scale
	Step = Step * (Left and -1 or 1) -- you need to put the or 1 otherwise you'd be multiplying a boolean with a number
	
	local TargetX = ScrollingFrame.CanvasPosition.X + Step
	local MaxX    = ScrollingFrame.AbsoluteCanvasSize.X - ScrollingFrame.AbsoluteSize.X
	--Naturally, you cannot go beyond the Size of the canvas - the size of the scroll wheel. 
	
	local TweenInformation = TweenInfo.new(
		0.35,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	
	local Tween = TweenService:Create(
		ScrollingFrame, 
		TweenInformation, 
		{CanvasPosition = Vector2.new(TargetX, 0)}
	)
	Tween:Play()
end














--Magnitude is a percentage of the current size.
--[[
	if it is shake, it will tilt to the right and then to the left, almost like a seesaw
	if it is fade, then it's transparency will increment with the value of magnitude 
	if it is Shrink, then it's size will shrink by the value of magnitude
	if it is UpNDown, then it will move up and down (It will move up by its height * magnitude and down by its height * magnitude)
	if it is Enlarge, then it will enlarge by the value of magnitude
	]]
GuiMaker2.Animate = function (GuiObject : GuiObject, AnimationType : "Shake" | "UpNDown" | "Enlarge" | "Shrink" | "Fade" | "LeftNRight", Reverses : BoolValue?, Magnitude : number?, Duration : number?, Repeat : number?)

	assert(GuiObject, "Must enter valid GuiObject to animate")
	assert(AnimationType, "AnimationType == nil. Did you forget to input an animation type?")
	assert(
		AnimationType == "Shake" or AnimationType == "UpNDown" or AnimationType == "Enlarge" or
			AnimationType == "Shrink" or AnimationType == "Fade" or AnimationType == "LeftNRight",
		"Animation type is invalid. Did you misspell something?"
	)

	Magnitude = Magnitude or 25
	Duration = Duration or 0.15
	Repeat = Repeat or 1
	Reverses = (Reverses ~= false) -- default true



	Magnitude = Magnitude / 100

	local tweenInfo = TweenInfo.new(Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local originalSize = GuiObject.Size
	local originalPos = GuiObject.Position
	local originalAnchor = GuiObject.AnchorPoint
	local originalTransparency
	if GuiObject:IsA("ImageLabel") or GuiObject:IsA("ImageButton") then
		originalTransparency = GuiObject.ImageTransparency
	else
		originalTransparency = GuiObject.BackgroundTransparency
	end
	
	-- THIS SECTION WAS AI GENERATED (I ain't doing all that)
	--But, it basically just makes some cool effects that I can implement easily anywhere to avoid redundancy. I very frequently need to make a small shake/size animation throughout my user interfaces. 

	-- Helper: create and play tween, return completed event
	local function PlayTween(props)
		local tw = TweenService:Create(GuiObject, tweenInfo, props)
		tw:Play()
		return tw.Completed:Wait()
	end

	for _ = 1, Repeat do
		if AnimationType == "Shake" then
			
			local goalRight = { Rotation = 5 * Magnitude * 10 }
			local goalLeft = { Rotation = -5 * Magnitude * 10 }
			local goalReset = { Rotation = 0 }

			PlayTween(goalRight)
			PlayTween(goalLeft)
			if Reverses then
				PlayTween(goalReset)
			end

		elseif AnimationType == "UpNDown" then
			local offset = UDim2.fromScale(0, -GuiObject.Size.Y.Scale * Magnitude)
			local goalUp = { Position = originalPos + offset }
			local goalDown = { Position = originalPos - offset }

			PlayTween(goalUp)
			PlayTween(goalDown)
			if Reverses then
				PlayTween({ Position = originalPos })
			end

		elseif AnimationType == "Enlarge" then
			local goalBig = { Size = originalSize + UDim2.fromScale(originalSize.X.Scale * Magnitude, originalSize.Y.Scale * Magnitude) }
			PlayTween(goalBig)
			if Reverses then
				PlayTween({ Size = originalSize })
			end

		elseif AnimationType == "Shrink" then
			local goalSmall = { Size = originalSize - UDim2.fromScale(originalSize.X.Scale * Magnitude, originalSize.Y.Scale * Magnitude) }
			PlayTween(goalSmall)
			if Reverses then
				PlayTween({ Size = originalSize })
			end
		elseif AnimationType == "LeftNRight" then
			local offset = UDim2.fromScale(GuiObject.Size.X.Scale * Magnitude, 0)
			local goalLeft  = { Position = originalPos - offset }
			local goalRight = { Position = originalPos + offset }

			PlayTween(goalRight)
			PlayTween(goalLeft)
			if Reverses then
				PlayTween({ Position = originalPos })
			end

		elseif AnimationType == "Fade" then
			local goalFade
			if GuiObject:IsA("ImageLabel") or GuiObject:IsA("ImageButton") then
				goalFade = { ImageTransparency = math.clamp(originalTransparency + Magnitude, 0, 1) }
			else
				goalFade = { BackgroundTransparency = math.clamp(originalTransparency + Magnitude, 0, 1) }
			end
			PlayTween(goalFade)
			if Reverses then
				if GuiObject:IsA("ImageLabel") or GuiObject:IsA("ImageButton") then
					PlayTween({ ImageTransparency = originalTransparency })
				else
					PlayTween({ BackgroundTransparency = originalTransparency })
				end
			end
		end
	end
end












return GuiMaker2
