Rock.Throw = function(self, Origin : Vector3, ThrowDirection : Vector3, Power) 
	local Velocity = GetVelocity(self.Player)  * Power
	
    local CurrentVerticalMultiplier = 20 - 0.2375 * (Velocity - 20)
	
	
	
	--Data tables--
	local KeyFrames : {KeyFrame} 							 = {} -- Stores the Vector 3 values of the keyframes for the rock to skip throughout
	local BallisticParabolasInfo : {BallisticParabolaInfo}   = {} -- Stores the time for each ballistic parabola to finish, and its initial velocity. 
	
	
	local InitialPosition = Origin

	
	local GoalDownwardVerticalDistance = -1 * Constants.LaunchHeight
	
	local CosBeta = math.cos(Constants.Beta)
	local SinBeta = math.sin(Constants.Beta)
	
	local Ux = Velocity * CosBeta
	local Uy = Velocity * SinBeta * -1 -- Multiply by -1 since the initial vertical velocity is downward -- 
	local InitialVerticalVelocity = Uy
	
	local FdragX = DragForceEnabled and (-1 * Physics.DragCalculator(Ux)) or 0 
	local FdragY = DragForceEnabled and (Physics.DragCalculator(math.abs(math.abs(Uy)))) or 0 
	
	local Ax = Physics.AccelerationCalculator(FdragX, Constants.StoneMass)
	local Ay = Physics.AccelerationCalculator(FdragY, Constants.StoneMass, true)
	
	--Handling rotational data--
	local W  = Physics.CalculateAngularVelocity(Ux) -- Capped at no more than 3 revolutions per second. 
	
	
	
	local StillMoving = true
	
	local FinalX = 0 
	local FinalY
	local TotalVerticalDistance
	local VerticalDisplacement 
	local HorizontalDisplacement
	local Angle  = 0
	local CurrentPathTime 
	local CurrentUx
	local Direction = 1 --upwards drag



	local FirstFrame = {
		FVector      = Vector2.new(0, Constants.LaunchHeight/0.28), -- starting position
		FDelay       = 0.01,
		FSpeed       = Ux/0.28,
		FAngle 		 = 0 
	}

	local SecondFrame = {
		FVector      = Vector2.new(2, Constants.LaunchHeight/0.28), -- tiny move to force tween
		FDelay       = 0.01,
		FSpeed       = Ux/0.28, 
		FAngle 		 = 1
	}

	table.insert(KeyFrames, FirstFrame)
	table.insert(KeyFrames, SecondFrame)
	

	CurrentUx 		= Ux --store the initial UX and the pathtime for each parabola to create realistic rotation that varies depending on speed. 
	while StillMoving do 
		 TotalVerticalDistance = 0
		 FinalY 			   = 0 
		 CurrentPathTime       = 0 
         
		 
		 --Calculate displacements at a constant delta time and continue to add them up until the 
		 
		 repeat 
			VerticalDisplacement = Physics.DisplacementEquation(Uy, Constants.DeltaTime, 0)
			TotalVerticalDistance += VerticalDisplacement
			HorizontalDisplacement = Physics.DisplacementEquation(Ux, Constants.DeltaTime, 0)
			
			local AngleIncrement =  Physics.CalculateAngle(W, Constants.DeltaTime)
			if AngleIncrement > 0.02 then 
				Angle += AngleIncrement
			end
		
			FinalX += HorizontalDisplacement
			
			Ux = Physics.VelocityEquation(Constants.DeltaTime, Ax, Ux)
			Uy = Physics.VelocityEquation(Constants.DeltaTime, Ay, Uy)
			W  = Physics.CalculateAngularVelocity(Ux)
			
			FdragY = DragForceEnabled and (Direction * Physics.DragCalculator(math.abs(Uy))) or 0 
			FdragX = DragForceEnabled and (-1* Physics.DragCalculator(math.abs(Ux))) or 0 
			
			Ay = Physics.AccelerationCalculator(FdragY, Constants.StoneMass, true)
			Ax = Physics.AccelerationCalculator(FdragX, Constants.StoneMass, false)
			
			CurrentPathTime += Constants.DeltaTime
				
		 until TotalVerticalDistance - (math.abs(GoalDownwardVerticalDistance) * -1) <= 1e-6 or (Physics.Round(Uy) == 0 and Direction == -1)
		 
		 Direction *= -1 
		 local CurrentX = FinalX * 100
		 FinalY *= 100
		 
		 if Physics.Round(Uy) == 0 then 
				--Ball is in the air at the maximum height of the ballistic parabola--
				TotalVerticalDistance *= (Constants.VerticalDistanceConstant * CurrentVerticalMultiplier)
				FinalY = math.clamp(TotalVerticalDistance, 0, Constants.MaxY)
		 elseif TotalVerticalDistance - (math.abs(GoalDownwardVerticalDistance) * -1) <= 1e-6 then
				
				Ux, Uy = Physics.WaterCollision(Ux, Uy)
			    
				StillMoving = Physics.IsStillMoving(Uy, Ux, FinalY)		
				
		     	local Temp = (Uy)^2 - (2 * Constants.g * Constants.StoneRadius * (math.sin(Constants.Alpha)))
				Uy = math.sqrt(Temp)
				

		 end
		 
		 
		 
		 local Pause = Physics.PauseCalculator(Direction, Ux)
		 local CurrentFrame : KeyFrame = {
				FVector = Vector2.new(CurrentX/Constants.ToStuds, FinalY/Constants.ToStuds),
				FSpeed = Physics.ResultantMagnitude(Ux, Uy) * Constants.AnimationSpeedConstant,
				FDelay = Pause,
				FAngle = math.round(Angle)
		 }
		 table.insert(KeyFrames, CurrentFrame)
	
	end
	KeyFrames[#KeyFrames].FDelay = Constants.FinalDelay -- This adds more weight at the end to give a realistic feeling.
	
	
	
	task.spawn(function()
		Progression.RockThrown(self.Player, KeyFrames, self.MoneyMultiplier)
	end)
	
	--Converting 2D vectors into 3D world Vectors.
	--Hit positions are the vector 3s where the rock hits the water in. 
	local HitInfos 
	KeyFrames, HitInfos = Physics.DirectionResolver(Origin,  ThrowDirection, KeyFrames)



    
	local Rock = InitiateRock(self.Player, self.RockNumber, Origin) 
	
	
	return KeyFrames, Rock, HitInfos
end
