plugin simpleObject FEM_Load
name:"FEM_Load"
classID:#(0x9288d9b, 0x2fb4a373)
category:"Para3d"
Version:1 
(
	-------------------------------- geometry functions --------------------------------------
	local _one
	
	fn getRelativeDistance barLength = (
		if (this.DistType == 1) then (
			-- relative 
			(2*this.Dist-1)
		)else(
			(2*this.Dist/barLength -1)
		)
		
	)
	/*
		this function takes the mesh me as input and then it tranform all vertices by matrix ma
	*/
	fn transformMesh me ma = (
		local res = copy me
		for vert in res.vertices do ( 
			vert.pos = vert.pos*ma
		)
		update res
		res
	)
	fn Make_cylinder x = (	 
		local _cylinder = createInstance cylinder
		_cylinder.height  = -x
		_cylinder.radius = _one;
		_cylinder.sides =12;
		_cylinder.heightsegs = 1;
		_cylinder.mesh
		if (x>0) then (
			transformMesh (_cylinder.mesh) (transmatrix [0,0,-3*_one])
		)else(
			transformMesh (_cylinder.mesh) (transmatrix [0,0,3*_one])
		)
	)
	fn Make_cone x = (
		local _m = createInstance cone
		_m.height  = 3*_one
		_m.radius1 = 2*_one;
		_m.radius2 =0;
		_m.sides = 12;
		_m.heightsegs = 1;
		
		if (x>0) then (
			transformMesh (_m.mesh) (transmatrix [0,0,-3*_one])
			--_m.mesh
		)else(
			--transformMesh (_m.mesh) ((rotateXmatrix 180)*(transmatrix [0,0,x]))
			transformMesh (_m.mesh) ((transmatrix [0,0,-3*_one])*(rotateXmatrix 180))
		)
	)
	fn Make_tube x = (
		local _m = createInstance tube
		_m.height = x
		_m.sides = 12
		_m.slice = true
		_m.radius1 = 5*_one
		_m.radius2 = 4*_one
		_m.capsegs = 1;
		_m.heightSegs = 1;
		_m.slicefrom = 0;
		_m.sliceTo = 90;
		_m.mesh
		transformMesh (_m.mesh) (transmatrix [0,0,2*this._one])
	)
	fn Make_pyramid x = (
		local _m = createinstance pyramid 
		_m.height = _m.width = 3*_one;
		_m.depth  = x
		_m.heightsegs = _m.depthSegs = 1 
		transformMesh (_m.mesh) (matrix3 [0,1,0] [0,0,-1] [-1,0,0] [0,4.5*_one,.5*x+2*_one])
	)
	/*
		create an array of 9 arrows 
		tmpMesh: the reference mesh which the result will be attach to it
		L : half of the length of the memeber (length/2)
		Trans : if provided the arrows will be align to the global coordinate system 
	*/
	fn uniformLoadGeom tmpMesh L Trans:(matrix3 1) = (
		
		_h  = [this.fx,this.fy,this.fz]*this.Force__Scale
		_l = length _h
		
		if (_l !=0) do (	
		--if (not dx) or (Display__Forces and fx>0) do (			
			_n = normalize _h 
			_m= matrixfromnormal _n;
			_m = _m*Trans
			_v = transformMesh (Make_Cylinder _l) _m
			--meshop.attach tmpMesh (transformMesh (Make_Cylinder _l) _m)
			meshop.attach _v (transformMesh (Make_Cone _l) _m)	
			for i=0 to 8 do (
				meshop.attach tmpMesh (transformMesh _v (transmatrix [i*L/8,0,0]))
			)
		)
	 
		tmpMesh
		
	)
	fn nodalLoadGeom tmpMesh  L Trans:(matrix3 1) = (

		local offsetMatrix  
		if this.DistType == 1 then ( -- relative distance (L is from 0 to 1)
			if this.FromNode == 1 then ( -- from first node 
				offsetMatrix = transMatrix [(this.Dist)*L,0,0]
			)else( -- from the end node
				offsetMatrix = transMatrix [(this.Dist)*L,0,0]
			)
		)else( -- absolute distance 
			if this.FromNode == 1 then ( -- from first node 
				offsetMatrix = transMatrix [(this.Dist),0,0]
			)else( -- from the end node
				offsetMatrix = transMatrix [(-this.Dist),0,0]
			)
		)

		_h  = [this.fx,this.fy,this.fz]*this.Force__Scale
		_l = length _h
		if (_l)>0 do (
			_n = normalize _h 
			_m= (matrixfromnormal _n)*Trans*offsetMatrix;			
			meshop.attach tmpMesh ( transformMesh (Make_Cylinder _l) _m)
			meshop.attach tmpMesh ( transformMesh (Make_Cone _l) _m)
		)
		
		/*
		_h  = _fx*this.Force__Scale
		if (_h!=0) do (	
		--if (not dx) or (Display__Forces and fx>0) do (			
			meshop.attach tmpMesh (transformMesh (Make_Cylinder _h) (rotateYMatrix 90 ))
			meshop.attach tmpMesh (transformMesh (Make_Cone _h ) (rotateYMatrix 90 ))	
		)
		_h  = _fy*this.Force__Scale 
		if (_h!=0) do (
			meshop.attach tmpMesh (transformMesh (Make_Cylinder _h) (rotateXMatrix -90 ))
			meshop.attach tmpMesh (transformMesh (Make_Cone _h) (rotateXMatrix -90 ))
		)
		_h  = _fz*this.Force__Scale 
		if (_h!=0) do (
			meshop.attach tmpMesh (Make_Cylinder _h)
			meshop.attach tmpMesh (Make_Cone _h)  
		)
		*/
		_h  =  this.mz*this.Force__Scale
		_d = 	if this.fz>=0 then 0 else 1 
		if (_h!=0) do (
			meshop.attach tmpMesh (transformMesh (Make_Tube _h) ((rotateYMatrix (_d*180) )*offsetMatrix)) 
			meshop.attach tmpMesh (transformMesh (Make_Pyramid _h) ((rotateYMatrix (_d*180) )*offsetMatrix))  
		)
		_h  = this.mx*this.Force__Scale
		_d = 	if this.fx>=0 then 1 else -1 
		if (_h!=0) do (
			meshop.attach tmpMesh (transformMesh (Make_Tube _h) ((rotateYMatrix (_d*90) )*offsetMatrix)) 
			meshop.attach tmpMesh  (transformMesh (Make_Pyramid _h) ((rotateYMatrix (_d*90))*offsetMatrix))  
		)
		_h  = this.my*this.Force__Scale 
		_d = 	if this.fy>=0 then -1 else 1 
		if (_h!=0) do (
			meshop.attach tmpMesh (transformMesh (Make_Tube _h) ((rotateXMatrix (90*_d) )*offsetMatrix)) 
			meshop.attach tmpMesh  (transformMesh (Make_Pyramid _h) ((rotateXMatrix (90*_d) )*offsetMatrix))  
		)
		tmpMesh
		
	)
	
	
	
	----------------------- end of geometry functions -------------------------------------
		
  parameters structure rollout:structrue
  (
    _case type:#integer
	--_force type:#matrix3Tab tabSize:0 tabSizeVariable:true	 
	Load_unit type:#integer default:1 ui:load_unit
	Load_type type:#integer default:1 ui:load_type
	load_coord_sys type:#integer default:1 ui:load_coord_sys -- 1 : Global 2 : local  
	FX type:#float default:0 ui:FX
	FY type:#float default:0 ui:FY
	FZ type:#float default:-1 ui:FZ
	MX type:#float default:0  ui:MX
	MY type:#float default:0  ui:MY
	MZ type:#float default:0  ui:MZ
	FromNode type:#integer default:1 ui:FromNode	
	DistType type:#integer default:1 ui:DistType
	Dist type:#worldUnits default:0 ui:Dist
	
  )
    parameters basic rollout:disp 
  (
	  index type:#integer default:0
	  Display__Size type:#worldUnits default:10  ui:displaySize
	  Force__Scale type:#float default:1  ui:Force__Scale
	  --uniqueId type:#string 
	  
  )

  /*
  parameters displayParams rollout:displayParams
  (
    size type:#worldunits ui:size    
    --depth type:#worldUnits ui:depth default:0
	on size set val do (
		delegate.size = val;
	)
  )
*/

 
  rollout structrue "Structural Parameters"
  (
		group "Type" (
			radiobuttons load_type  ""	labels:#("Point load","Unfirom load") columns:1
		)
		group "Point Load" (
			radiobuttons FromNode  "" labels:#("First node","End Node") columns:1
			radiobuttons DistType  "" labels:#("Relative","Absolute") columns:1
			spinner Dist "Distance" range:[-1000000,1000000,0] type:#worldUnits 			
		)
		group "Unit" (
		radiobuttons load_unit  ""	labels:#("N","KN") columns:2 
		)
		group "Coordinate System" (
			radiobuttons load_coord_sys  ""	labels:#("Global","Local") columns:2 
		)
		group "Force" (
			spinner FX "X" range:[-1000000,1000000,0] type:#float 
			spinner FY "Y" range:[-1000000,1000000,0] type:#float 
			spinner FZ "Z" range:[-1000000,1000000,0] type:#float 			
		)
		group "Moment" (
			spinner MX "X" range:[-1000000,1000000,0] type:#float 
			spinner MY "Y" range:[-1000000,1000000,0] type:#float 
			spinner MZ "Z" range:[-1000000,1000000,0] type:#float 			
		)
		on structrue open do (
			FromNode.enabled = Dist.enabled = load_type.state==1;
		)
		on load_type changed val do (
			FromNode.enabled = Dist.enabled = (val ==1);
		)
  )
  rollout 	disp "Display"
	(
		spinner displaySize "Display size" type:#worldUnits range:[0.00001,1000000,0] 		
		spinner Force__Scale "Scale" type:#float range:[0.00001,1000000,0] 
		--checkbox Display__Forces "Display reactions"
	)
 	on buildMesh do
  (
		--updateDisplay()
			this._one  = .1*this.Display__Size
		tmpMesh = trimesh()
		case this.Load_type of (
			
			1: (
				nodalLoadGeom tmpMesh (this.Display__Size*2)
			)
			2 : (
				uniformLoadGeom tmpMesh (this.Display__Size*2)
			)
		)
	  
		if tmpMesh.numverts == 0 then (
			_box = createInstance box
			_box.Length = this._one 
			_box.Height = this._one 
			_box.Width = this._one 	
			mesh = _box.mesh
		)else(
			mesh = tmpMesh;
		)
	  
	  
	
		
	  --mesh= MeshFunction()
		
  )
	on load do (
		this._one  = .1*this.Display__Size
	)
	/*
	on create do (
		-- set the unique id after node has been created (5 characters)
		this.uniqueID =formattedPrint  (random 0 99999) format:"05i" 
	)
	*/
  tool create
  (
    on mousePoint click do
      case click of
      (
        1: nodeTM.translation = gridPoint
        3: #stop
       )
    on mouseMove click do
      case click of
      (
        2: (
			this.Display__Size = abs(gridDist.x);  --this.Display__Size = gridDist.y
			this._one = 0.1*this.Display__Size 
			)
        3: (
			this.Force__Scale = abs(gridDist.z)
		)
      )
  )

)