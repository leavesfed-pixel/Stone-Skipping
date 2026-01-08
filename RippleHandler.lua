local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--Modules--
local PoolHandler = require(script.PoolHandler)


local function LoadVoxels(Voxels: {Part}, Positions: {Vector3}, PerFrame: number?)
	PerFrame = PerFrame or 30

	local Loaded = 0
	local Total = #Voxels
	if Total == 0 then
		return
	end

	local function Step()
		local EndIndex = math.min(Loaded + PerFrame, Total)
		for I = Loaded + 1, EndIndex do
			Voxels[I].Position = Positions[I]
		end
		Loaded = EndIndex
	end

	-- Do the first chunk immediately (helps “in time” issues)
	Step()

	while Loaded < Total do
		RunService.Heartbeat:Wait()
		Step()
	end
end




--[[
Previously, this function used the circle equation, but since the gradient is not constant, the voxel positions 
would collect at the top and bottom of the circle, leaving the sides sparse. 


This solution considers only one quadrant. 

Imagine two circles. 
One with radius R - 0.5, lets call this radius inner
Another with radius R + 0.5, lets call this radius outer.

The space in-between those two circle is what we want to fill. 

Note that the graphs are Z against X instead of the usual Y against X


so if X^2 + Z^2 < Outer^2 AND if X^2 + Z^2 > Inner^2 then the point (x, z) lies between those two circles
Check RipplePositionExplantion.Jpeg in the repositary underneath the ripples branch for an illustration.



]]
local function GetVoxelPositions(Center: Vector2, Radius: number): {Vector3}
	local H = Center.X
	local K = Center.Y

	local Inner = (Radius - 0.5)
	local Outer = (Radius + 0.5)

	local Inner2 = Inner * Inner
	local Outer2 = Outer * Outer

	local Positions: {Vector3} = {}
    local Y = -1.0
	-- Only scan first quadrant, and we can just make use of the circle's symmetry to fill the other points
	for dx = 0, Radius, 1 do
		local dx2 = dx * dx

		for dz = 0, Radius do
			local d2 = dx2 + dz * dz

			if d2 >= Inner2 and d2 <= Outer2 then
				-- Mirror to all 4 quadrants
				table.insert(Positions, Vector3.new(H + dx, Y, K + dz))
				if dx ~= 0 then
					table.insert(Positions, Vector3.new(H - dx, Y, K + dz))
				end
				if dz ~= 0 then
					table.insert(Positions, Vector3.new(H + dx, Y, K - dz))
				end
				if dx ~= 0 and dz ~= 0 then
					table.insert(Positions, Vector3.new(H - dx, Y, K - dz))
				end
			end
		end
	end

	return Positions
end




local function GetVoxels(CenterPosition : Vector2, Radius : number) : {Part}
	local VoxelPositions : {Vector3} = GetVoxelPositions(CenterPosition, Radius)
	local VoxelCount  				 = #VoxelPositions
	
	local Success, Voxels = PoolHandler.GetVoxels(VoxelCount)

	
	if not Success then 
		error("Failed to get voxels")
	end
	
	LoadVoxels(Voxels, VoxelPositions) -- Will yield until all the voxels are loaded into their positions
	
	
	return Voxels
end

--Converts the velocity into wavespeed by using a ratio
local function CalculateWaveSpeed(Velocity : number) : number
	return Velocity / 1
end

--Converts normal distance into voxel distance by using a ratio. 
local function CalculateVoxelDistance(Distance : number) : number
	return math.round(
		Distance/24
	)
end

--I used Ai for this function since I wasn't sure what would turn out the smoothest. 
local function EaseCubicInOut(t: number): number
	if t < 0.5 then
		return 4 * t * t * t
	else
		local u = -2 * t + 2
		return 1 - (u * u * u) / 2
	end
end


local function PlayRippleAnimation(Voxels: {BasePart}, WaveSpeed: number)
	local Duration = 0.25
	local GoalHeight = WaveSpeed * 0.09

	local Count = #Voxels
	if Count == 0 then
		return
	end

	
	local BasePositions = table.create(Count)
	local BaseRotations = table.create(Count)
	for i = 1, Count do
		local cf = Voxels[i].CFrame
		BasePositions[i] = cf.Position
		BaseRotations[i] = cf.Rotation
	end

	
	local TargetCFrames = table.create(Count)

	local TotalTime = Duration * 2
	local Elapsed = 0

	while Elapsed < TotalTime do
		local dt = RunService.Heartbeat:Wait() -- waits for a frame.
		Elapsed += dt

		
		local alpha = math.clamp(Elapsed / TotalTime, 0, 1)

		-- Triangle wave: 0->1->0
		local tri = 1 - math.abs(2 * alpha - 1)

	
		local eased = EaseCubicInOut(tri)

		local y = GoalHeight * eased

		for i = 1, Count do
			local pos = BasePositions[i] + Vector3.new(0, y, 0)
			TargetCFrames[i] = CFrame.new(pos) * BaseRotations[i]
		end

		workspace:BulkMoveTo(Voxels, TargetCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end

	
	for i = 1, Count do
		TargetCFrames[i] = CFrame.new(BasePositions[i]) * BaseRotations[i]
	end
	workspace:BulkMoveTo(Voxels, TargetCFrames, Enum.BulkMoveMode.FireCFrameChanged)

	PoolHandler.ReturnVoxels(Voxels)
end




local RippleHandler = {}

function RippleHandler.Init(Player : Player)
	PoolHandler.Init(Player)
end

--Accepts the CollisionPosition between water and rock as the center of the ripple and uses the velocity as the magnitude. 
function RippleHandler.CreateRipple(CollisionPosition: Vector3, Velocity: number)
	local CenterPosition = Vector2.new(CollisionPosition.X, CollisionPosition.Z)

	local Radius = 1
	local LastWholeRadius = math.floor(Radius)

	local WaveSpeed = CalculateWaveSpeed(Velocity)

	local IsAlive = true
	
	--[[
	Each succesive circle of voxels needs to be preloaded before its up&down animation can be played, otherwise
	it won't look smooth due to loading delay.]]


	local PreloadedRadius: number? = nil
	local PreloadedGroup: {Part} = {}
	local IsPreloading = false

	local function ReturnGroupIfAny(Group: {Part})
		if Group and #Group > 0 then
			PoolHandler.ReturnVoxels(Group)
		end
	end

	local function ClearPreload(ReturnIt: boolean)
		if ReturnIt then
			ReturnGroupIfAny(PreloadedGroup)
		end
		PreloadedRadius = nil 
		PreloadedGroup = {}
		IsPreloading = false
	end

	local function Preload(TargetRadius: number)
		if not IsAlive then return end
		if IsPreloading then return end
		if PreloadedRadius == TargetRadius then return end

		IsPreloading = true

		task.spawn(function() -- This is in a separate thread, preventing the yield of GetVoxels from blocking the main thread.
			local Group = GetVoxels(CenterPosition, TargetRadius) -- yields here, not on Heartbeat thread

			-- If ripple died while loading, do NOT leave voxels out.
			if not IsAlive then
				PoolHandler.ReturnVoxels(Group)
				IsPreloading = false
				return
			end

			-- If we no longer need this radius (we advanced), return it.
			if TargetRadius <= LastWholeRadius then
				PoolHandler.ReturnVoxels(Group)
				IsPreloading = false
				return
			end

			-- Replace any previous preload (return old one to avoid leaks)
			if PreloadedRadius ~= nil and PreloadedRadius ~= TargetRadius then
				ReturnGroupIfAny(PreloadedGroup)
			end

			PreloadedRadius = TargetRadius
			PreloadedGroup = Group
			IsPreloading = false
		end)
	end

	local function PlayRing(TargetRadius: number)
		if not IsAlive then return end

		
		if PreloadedRadius == TargetRadius and #PreloadedGroup > 0 then
			local Group = PreloadedGroup
			ClearPreload(false)

			task.spawn(function()
				if IsAlive then
					PlayRippleAnimation(Group, WaveSpeed) 
				else
					PoolHandler.ReturnVoxels(Group)
				end
			end)
		else
			task.spawn(function()
				local Group = GetVoxels(CenterPosition, TargetRadius)
				if IsAlive then
					PlayRippleAnimation(Group, WaveSpeed)
				else
					PoolHandler.ReturnVoxels(Group)
				end
			end)
		end
	end


	Preload(LastWholeRadius + 1)

	local Connection: RBXScriptConnection
	Connection = RunService.Heartbeat:Connect(function(dt) -- this is a connection that signals the following function every frame on roblox dt is the time the frame lasted. 
		if not IsAlive then return end

		Radius += WaveSpeed * dt
		local CurrentWholeRadius = math.floor(Radius)

		-- Good old catch up loop: if we skipped multiple radii, play each one
		while CurrentWholeRadius > LastWholeRadius do
			LastWholeRadius += 1
			PlayRing(LastWholeRadius)
			Preload(LastWholeRadius + 1)
		end

		-- If each frame is 1/120 of a second, then in two frames, the wavespeed should have been multiplied by an overall 0.95. 
		-- X * X = 0.95, so X = 0.95 ^ 0.5
		
		-- If each frame is 1/240 of a second, then in 4 frames, the wavespeed should have been multiplied by an overall 0.95. 
		-- X * X * X * X = 0.95. So X = 0.95 ^ 0.25
		WaveSpeed *= math.pow(0.95, dt * 60) -- keeps it at 60fps. so when dt = 1/60, 0.95 ^1, if it dt is 1/120, 0.95 ^ 0.5

		if WaveSpeed < 0.25 then
			IsAlive = false
			Connection:Disconnect()
			-- Return any preloaded-but-never-used voxels
			ClearPreload(true)
		end
	end)
end







return RippleHandler



