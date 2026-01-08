local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local RModules = ReplicatedStorage.ModuleScripts
local Queue   = require(RModules.GoodPractices.Queue)

-- Constants
local MaxWaveSpeed       = 200 -- studs/s
local VelocityMultiplier = 0.95
local PoolSizeConstant   = 1.15
local ToVoxel            = 1

local PoolPosition = Vector3.new(0, -100000, 0)

local MaxRadius: number
local PoolSize: number
local VoxelPool: Folder

local Returning: boolean
local Getting: boolean

local GetQueue = Queue.New(64) 

type GetRequest = {
	Count: number,
	DoneEvent: BindableEvent,
	Ok: boolean?,
	Voxels: { Part }?,
}


local function CalculateMaximumRadius()
	return math.round(
		MaxWaveSpeed / (50 * math.abs(math.log(VelocityMultiplier)))
	)
end

local function CalculatePoolSize(MaxRadiusValue: number)
	return math.round(
		(20 * math.pi * MaxRadiusValue * PoolSizeConstant) / ToVoxel
	)
end

local function EnterPool(Voxel: Part)
	Voxel.Parent = VoxelPool
	Voxel.Position = PoolPosition
end

local function ExitPool(Voxel: Part)
	Voxel.Parent = workspace
end

local function CreateVoxelPool(PoolSizeValue: number, VoxelPoolFolder: Folder, ReferenceVoxel: Part)
	local Created = 0
	local Connection

	Connection = RunService.Heartbeat:Connect(function()
		local BatchCount = math.min(50, PoolSizeValue - Created)
		if BatchCount <= 0 then
			Connection:Disconnect()
			return
		end

		for _ = 1, BatchCount do
			local Voxel = ReferenceVoxel:Clone()
			Voxel.Anchored = true
			Voxel.CanCollide = false
			Voxel.Transparency = 0
			Voxel.CanQuery = false
			Voxel.CanTouch = false
			Voxel.Name = "Voxel"
			Voxel.Position = PoolPosition
			Voxel.Parent = VoxelPoolFolder
		end

		Created += BatchCount
	end)
end

local function ReturnVoxelsInternal(Voxels: { Part })
	Returning = true
	

	for _, Voxel: Part in Voxels do
		if Voxel:IsA("Part") and Voxel.Name == "Voxel" then
			EnterPool(Voxel)
		else
			warn("Attempted to return a non-voxel part to the pool " .. tostring(Voxel))
		end
	end

	Returning = false
end

local function GetVoxelsInternal(Count: number): (boolean, {Part})
	local AvailableVoxels = VoxelPool:GetChildren()

	if #AvailableVoxels < Count then
		warn(("Not enough voxels available in the pool. Requested: %d, Available: %d"):format(Count, #AvailableVoxels))
		return false, {}
	end

	local Voxels = table.create(Count)
	for Index = 1, Count do
		local Voxel : Part= AvailableVoxels[Index] 
		Voxels[Index] = Voxel
		ExitPool(Voxel)
	end
     
	return true, Voxels
end

-- Single worker that processes requests ONE AT A TIME!!
local WorkerWakeEvent = Instance.new("BindableEvent")
local WorkerRunning = false

local function StartWorker()
	if WorkerRunning then
		return
	end
	WorkerRunning = true

	
	GetQueue:OnEnqueued(function()
		WorkerWakeEvent:Fire()
	end)

	task.spawn(function()
		while WorkerRunning do
			-- Sleep until there is work to do.
			while GetQueue:IsEmpty() do
				WorkerWakeEvent.Event:Wait()
				if not WorkerRunning then
					return
				end
			end

			
			while not GetQueue:IsEmpty() do
				-- Perhaps after returning there might be more voxels available to get, which is why we also wait for returns to complete.
				-- You can't get while you're already getting voxels for a prior request. 
				while Returning or Getting do
					RunService.Heartbeat:Wait()
				end

				Getting = true

				local Ok, Request = GetQueue:Dequeue()
				if Ok and Request then
					local TypedRequest : GetRequest = Request 
					TypedRequest.Result, TypedRequest.Voxels = GetVoxelsInternal(TypedRequest.Count)
					TypedRequest.DoneEvent:Fire() -- So this fires back to Line A so the code continues executing from there.
				end

				Getting = false
			end
		end
	end)
end

local PoolHandler = {}

function PoolHandler.Init(Player: Player)
	VoxelPool = Instance.new("Folder")
	VoxelPool.Name = "VoxelPool"
	VoxelPool.Parent = workspace

	local ReferenceVoxel = workspace:WaitForChild("ReferenceVoxel", 5)
	if not ReferenceVoxel then
		error("Unable to find ReferenceVoxel")
	end

	MaxRadius = CalculateMaximumRadius()
	PoolSize = CalculatePoolSize(MaxRadius)

	Returning = false
	Getting = false

	CreateVoxelPool(PoolSize, VoxelPool, ReferenceVoxel)
	StartWorker()
end

function PoolHandler.ReturnVoxels(Voxels: { Part })
	ReturnVoxelsInternal(Voxels)
end

function PoolHandler.GetVoxels(Count: number): { Part }
	local Request: GetRequest = {
		Count = Count,
		DoneEvent = Instance.new("BindableEvent"),
		Result = nil,
		Voxels = nil
	}

	local Ok, ErrorMessage = GetQueue:Enqueue(Request)
	if not Ok then
		Request.DoneEvent:Destroy()
		warn(ErrorMessage)
		return {}
	end

	Request.DoneEvent.Event:Wait() -- Line A
	Request.DoneEvent:Destroy()

	return Request.Result, Request.Voxels
end

return PoolHandler
