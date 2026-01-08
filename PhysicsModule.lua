--Services--
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--modules--
local SModules = ServerScriptService.ModuleScripts	
local RModules = ReplicatedStorage.ModuleScripts
local Constants = require(SModules.GoodPractices.Constants)
local t=require(SModules.GoodPractices.T)
local CustomTypes = require(RModules.GoodPractices.CustomTypes)


--CustomTypes--
type KeyFrame = CustomTypes.KeyFrame
type HitInfo  = CustomTypes.HitInfo



--[[
██╗      ██████╗  ██████╗ █████╗ ██╗                                      
██║     ██╔═══██╗██╔════╝██╔══██╗██║                                      
██║     ██║   ██║██║     ███████║██║                                      
██║     ██║   ██║██║     ██╔══██║██║                                      
███████╗╚██████╔╝╚██████╗██║  ██║███████╗                                 
╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝                                 
                                                                          
███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
                                                                         
]]



local function FindMin_i(CurveRatio : number, FinalDistance : number)
	local T = 0.5

	local Divisor  = math.abs(math.log10(T) * FinalDistance * (1 - CurveRatio))
	local MinValue = Constants.MapRadius / Divisor
	local AdjustedMinValue = 0 
	if FinalDistance > Constants.MapRadius then 
	  AdjustedMinValue = MinValue
	  warn("Took min value of i", MinValue)
	end 
	--if the min value is lower than 1.5, then the min value should be 1.5
	
	return 0 -- This section was removed, might update later
end

local function Find_i(CurveRatio : number, FinalDistance : number)
	local MinValue = FindMin_i(CurveRatio, FinalDistance)
	local MaxValue = MinValue + 1 
	
	
	local RandomNumber = MinValue + math.random() * (MaxValue - MinValue)

	warn("I is ", RandomNumber)
	return RandomNumber
end












local Physics = {}
--Rounds a number to 4 dp
function Physics.Round(number)
	return math.round(number * 10^4) / 10^4
end 

--returns direction of Vector2 from Vector1
function Physics.GetDirection(Vector_1: Vector3, Vector_2 : Vector3)
	return (Vector_2 - Vector_1).Unit
end




--[[                                                                      
                                                                            
                                                                                                                 
██╗  ██╗██╗███╗   ██╗███████╗███╗   ███╗ █████╗ ████████╗██╗ ██████╗███████╗
██║ ██╔╝██║████╗  ██║██╔════╝████╗ ████║██╔══██╗╚══██╔══╝██║██╔════╝██╔════╝
█████╔╝ ██║██╔██╗ ██║█████╗  ██╔████╔██║███████║   ██║   ██║██║     ███████╗
██╔═██╗ ██║██║╚██╗██║██╔══╝  ██║╚██╔╝██║██╔══██║   ██║   ██║██║     ╚════██║
██║  ██╗██║██║ ╚████║███████╗██║ ╚═╝ ██║██║  ██║   ██║   ██║╚██████╗███████║
╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝╚══════╝


                                                                            ]]

--Returns the MAGNITUDE of drag force (Drag is currently disabled)
function Physics.DragCalculator(Velocity : number, Area : number?)
	Area = Area or Constants.StoneArea
	if not t.number(Velocity) then warn("Velocity is invalid") end 
	
	local DragForce =  0.5 * Constants.AirDensity  *  Area * (Velocity) ^ 2 * 0.4
	if DragForce ~= DragForce then 
		warn(DragForce)
		task.wait(100)
	end
	return DragForce -- I currently have the drag force disabled
end
--Returns the MAGNITUDE of acceleration
function Physics.AccelerationCalculator(Force : number, Mass : number, IncludeWeight : boolean?)
	if IncludeWeight == nil then IncludeWeight = false end 
	Mass = Mass or Constants.StoneMass
	
	if IncludeWeight then 
		Force = Force - (Mass * Constants.g)
		--So now we need to add the weight of the object with the resultant force.
	end
	
	
	return Physics.Round((Force/Mass))
end

--Returns the magnitude of velocity 
function Physics.VelocityEquation(DeltaTime : number, Acceleration : number, InitialVelocity : number) 
	local NewVelocity = (InitialVelocity + Acceleration   * DeltaTime)
	if not t.number(NewVelocity) then
		warn("INVALID VELOCITY")
		print("InitialVelocity is " , InitialVelocity)
		print("Acceleration is ", Acceleration)
		print("DeltaTime is ", DeltaTime)
	end
	return  NewVelocity
end

function Physics.ResultantMagnitude(Num1 : number, Num2: number)
	return math.sqrt((Num1)^2 + (Num2)^2)
end

--Returns the magnitude of the displacement
function Physics.DisplacementEquation(Velocity : number, DeltaTime : number, Acceleration : number)
	return (Velocity * DeltaTime) +( 0.5 * Acceleration * DeltaTime ^ 2)
end


--Expects angular velocity (w) in rad, and returns angle in rad. 
function Physics.CalculateAngle(w : number, DeltaTime : number)
	return w * DeltaTime
end

--Returns angular velocity based on ratio between normal velocity and angular velocity (not linear velocity)
function Physics.CalculateAngularVelocity(PartVelocity : number)
	return math.clamp(PartVelocity * Constants.RotationConstant, Constants.MinAngularVelocity, Constants.MaxAngularVelocitiy)
end





--[[
 ██████╗ ██████╗ ██╗     ██╗     ██╗███████╗██╗ ██████╗ ███╗   ██╗
██╔════╝██╔═══██╗██║     ██║     ██║██╔════╝██║██╔═══██╗████╗  ██║
██║     ██║   ██║██║     ██║     ██║███████╗██║██║   ██║██╔██╗ ██║
██║     ██║   ██║██║     ██║     ██║╚════██║██║██║   ██║██║╚██╗██║
╚██████╗╚██████╔╝███████╗███████╗██║███████║██║╚██████╔╝██║ ╚████║
 ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚═╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝
                                                                  ]]

--Ripples are handled in a different script--

--Accepts Ux, Uy before collision and returns diminished values (respectively) due to energy loss after collision with water--
function Physics.WaterCollision(Ux : number, Uy: number)
	local Vresultant = Physics.ResultantMagnitude(Ux, Uy)
	local Feta = Constants.Alpha + Constants.Beta
	local CosF = math.cos(Feta)
	
	local Vxout = Constants.EnergyMultiplier * Ux
	local Vyout = Vresultant * CosF * math.sin(Constants.Alpha)
	
	return Vxout, Vyout
end

--Direction must be either -1 or 1. Returns a time delay for the water Collision (Short pause for realism)
function Physics.PauseCalculator(Direction : number, Ux : number)
	assert(Direction == 1 or Direction == -1)
	local Pause = ((Direction == 1 and math.clamp(0.003 + 0.0005 * Ux, 0.008, 0.02)))  or 0 
	return Pause
end


--Checks if the rock should still be moving--
function Physics.IsStillMoving(Vyout, Vxout, CurrentY)
	local MinimumValue = (Vyout)^2 - (2 * Constants.g * Constants.StoneRadius * (math.sin(Constants.Alpha) + Constants.YLegal))
	local IsMoving = true
	
	if MinimumValue < 0 or Vxout < 0.5 or (CurrentY <= Constants.YLegal and CurrentY ~= 0) then
		--END CRITERIA MET--
		IsMoving = false
	end
	
	
	return IsMoving
end




--[[
██████╗  █████╗ ████████╗██╗  ██╗
██╔══██╗██╔══██╗╚══██╔══╝██║  ██║
██████╔╝███████║   ██║   ███████║
██╔═══╝ ██╔══██║   ██║   ██╔══██║
██║     ██║  ██║   ██║   ██║  ██║
╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
                                 ]]


--[[The vector2s found inside of "KeyFrames" don't actually store the x value. Instead, it stores the distance from point of launch. Meaning 
we need to convert this distance from point of launch to actual X, Z coordinates. The Y coordinates remain the same.

The naming is sort of confusing, which is a mistake from my part. 

KeyFrames only become actual keyframes after their directions are resolved with this function.
]]
function Physics.DirectionResolver(Origin : Vector3, Direction : Vector3, KeyFrames : {KeyFrame})
	local HitInfos : {HitInfo} = {} -- stores the positions where the rock hit the water in (The troughs)
	
	-- Flatten and normalize main horizontal direction
	local FlatDirection = Vector3.new(Direction.X, 0, Direction.Z)
	if FlatDirection.Magnitude < 1e-6 then
		FlatDirection = Vector3.new(0, 0, -1) 
	end
	FlatDirection = FlatDirection.Unit

	-- Perpendicular sideways (right) vector
	local RightVector = FlatDirection:Cross(Vector3.yAxis) -- left hand rule
	if RightVector.Magnitude < 1e-6 then
		RightVector = Vector3.new(1, 0, 0)
	end
	RightVector =   RightVector.Unit

    
	local FinalDistance = KeyFrames[#KeyFrames].FVector.X 
	if FinalDistance <= 0 then
		FinalDistance = 1
	end
	
	--[[
	So far, the rock has been moving in a straight sinusoidal pattern
     
     Meaning although it curves up and down, the horizontal path itself remains straight. 
     
     This next section aims to change that by adding horizontal curvuture. 
     
	]]


	local CurveRatio          = math.random(10, Constants.MaxCurveRatio * 100)/100
	local FinalSidewaysOffset = FinalDistance * CurveRatio
	

    --[[
 
    
    The axis are in respect to the rock itself. Not world coordinates. 
    The Z axis is in the direction the rock is moving in. 
    The X axis is in the direction the rock is curving in. 
    
    Initially Keyframes is a table of Vector 2's that store the distance from origin, Z, and The vertical distance from sea respectively, Y.
    
    Now we want to convert those Z values into X and Z values, effectively adding horizontal curvuture. 
    The FinalDistance is the distance we calculated for the rock to travel horizontally in total. 
    
    The CurveRatio is what percentage of that distance should be on the X axis.
    FinalSidewaysOffset is the absolute distance that should be on the X axis. 
    Remaining distance will be for the Z axis. 
    
	 
    Z
    ^
    |          *
    |       *               
    |    *
    |  *
    | *
    +--------------------> x
	
	
    so some paths can look like this 
    
    
       Z
    ^
    |     * 
    |    *              
    |   *
    |  *
    | *
    +--------------------> x
    or like this
    
      ^
    |                  * 
    |            *              
    |       *
    |   *
    | *
    +--------------------> x
    
    or even like this depending on the ratio. 
    
    
    The last thing we need to determine is "when does the rock start bending?"
    
     see the next section 👇
	
]]

	-- Randomize left / right per throw
	local CurveSign     = (math.random(1, 10) <= 5 ) and -1 or 1
	
    local i  			= Find_i(CurveRatio, FinalDistance, FinalDistance)
	for _, Frame in KeyFrames do
		local Local2D = Frame.FVector
		local dist    = Local2D.X         -- forward distance from launch. This behaves as the Z. 
		local height  = Local2D.Y * 5   
		
		-- Normalized progress 0 → 1
		local t = dist / FinalDistance

		--[["Exponential-ish (parabola with domain x > 0)" ease-out curve (starts straight, bends more later)
	
		
		i  >         B
		     -----------------------
		       log( t ) ⋅ F( 1 - r )
		       
		B is the radius of the map (boundary), t is the normalized progress which is 0.9999 in this equation, and F is the 
		Final distance 
		
		The equation is for the minimum value of i, and I will explain where it comes from shortly
		
		
	]]
		
		
		local curveFactor = t^i

		local ForwardOffset = FlatDirection * (1- CurveRatio) * dist
		local SidewaysMag   = dist * CurveRatio * curveFactor 
		local SidewaysOffset = RightVector * SidewaysMag * CurveSign 
		
		--[[
           As you can see, the SidwaysMag is the Y of an exponential equation. 
           Y = dat^i, where a is the max curve ratio and d is the current frame's distance from origin. So as t increases, 
           the Sidways mag will grow exponentially. 
           
           The greater than i is, the more delayed the bend is. 
           Try it on desmos. 
           
           Y = dax^i {x > 0} 
           Add sliders for d, a, and i 
           Imagine the rock originally moving along the X axis (not exactly true), and you'll notice the greater that i is, the later it starts to bend!
           
          
           
           

		]]

		local WorldPosition = Origin + ForwardOffset + SidewaysOffset

		-- Keep the Y from the simulation, only inject sideways curve
		Frame.FVector = Vector3.new(WorldPosition.X, height, WorldPosition.Z)
		
		if height == 0 then
			table.insert(HitInfos, {Frame.FVector, Frame.FSpeed})
			
		
		end 
		
	end
	
	
	

	return KeyFrames, HitInfos
end




return Physics
