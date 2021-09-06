plugin simpleObject FEM_Node

replaceUI:true
name:"FEM_Node"
classID:#(0x6d5bd90e, 0x37a6fc5a)
category:"Para3d"
invisible:true
Version:1
(
	local MeshFunction -- holds the instance of making mesh function 
	local setMeshFunction -- set the mesh function
	local model_Node -- hold an instance of dotnet object represeting the same node in FEM model
	local setModelElement 
	--local updateDisplay
	local _one
	local displacementMatrix = Matrix3 1
	
	/*
		function below provide a certain interface for para3d 
	*/
	fn overrideBooleanParaInterface myRoll trs = (
		
		
		local tmp = ""		
		local other = false;
		for i=0 to trs.count-1 do (
			tr = trs.item[i]			
			case tr of (
				"4,dx" : tmp+= " DX"				
				"4,1" : tmp+= " DX"				
				"4,dy" : tmp+= " DY"				
				"4,2" : tmp+= " DY"				
				"4,dz" : tmp+= " DZ"					
				"4,3" : tmp+= " DZ"					
				"4,rx" : tmp+= " RX"					
				"4,4" : tmp+= " RX"					
				"4,ry" : tmp+= " RY"					
				"4,5" : tmp+= " RY"					
				"4,rz" : tmp+= " RZ"
				"4,6" : tmp+= " RZ"
				default: other=true		
			)
		)
		if tmp == "" or other then (
			myRoll.addText "group @Settings@ (\n"  filter:on				
			tmp="Enable"	
		)else(
			myRoll.addText "group @Set constraints@ (\n"  filter:on	
		)
		myroll.addcontrol #checkBox #onoffControl tmp
		myRoll.addText ")\n" -- end of value gropup 
		
	)
	
	
	--local _fx,_fy,_fz,_mx,_my,_mz -- display sizes
	fn setModelElement dotNetObj  = (
	 
		model_Node = dotNetObj
		if model_Node == undefined then (
			this.fx = this.fy = this.fz =this.mx = this.my = this.mz = 0			
			--this.Display__Forces = false;
		)else(
			
			local forceObject = model_Node.GetInternalForce this.force_unit
			this.fx = forceObject.fx
			this.fy = forceObject.fy
			this.fz = forceObject.fz		
			this.mx = forceObject.mx
			this.my = forceObject.my
			this.mz = forceObject.mz
			local displacementObject = model_Node.GetDefaultNodalDisplacement();
			this.d_x = displacementObject.DX
			this.d_y = displacementObject.DY
			this.d_z = displacementObject.DZ
			this.r_x = displacementObject.RX*180.0/pi
			this.r_y = displacementObject.RY*180.0/pi
			this.r_z = displacementObject.RZ*180.0/pi
			--this.Display__Forces = true;
			
		)
	)
	--------------- load related functions ---------------------------
	/*
		set the constraints based on element type and number of element
	*/
	fn AutoConstraints = (
		if this.NumberOFElements ==1 then (
			--end joint 
			if this.elementType == "Truss" then (
				-- for truss elements we fix the end joints 
				
			)else if  this.elementType == "Frame" do (
				-- release the rotation
				this.rx=this.ry=this.rz = false
			)
		)else(
			if this.elementType == "Truss" then (
				-- for truss elements we release the movement 
				this.dx=this.dy=this.dz = false				
			)else if  this.elementType == "Frame" do (				
				this.rx=this.ry=this.rz = false
			)
		)
	)
	/*
		set the unit of loads within load array
	*/
	fn setLoadUnit val = (
		for item in this.loads where isvalidnode item do item.Load_unit = val;
	)
	/*
		add a nodal load 
		obj is a fem_load of type of nodal 
	*/
	fn addNodalLoad obj = (
		append this.loads obj
		append this.loadsName obj.name 		
		this.display__Loads = true
	)
	/*
		this function is used in addload pickbutton 
	*/
	fn loadFilter obj = ( 
		if (classof obj ) as string == "FEM_Load" then (
			obj.load_type==1 and finditem this.loads obj == 0 
		)else(
			false
		)
	)
	/*
		this is to populate the load list in modify panel
	*/
	fn populateLoadList  _r = (		
		_r.loadnames.items = this.loadsName  as array
		_r.removeLoad.enabled = this.loads.count > 0 and _r.loadnames.selection>0
	)
	/*
		return the matrix representing the displacement
	*/
	fn getDisplacementMatrix = (
		if (this.Display__Displacement) then
		(		
			(transmatrix [this.d_x*this.Displacement__Scale,this.d_y*this.Displacement__Scale,this.d_z*this.Displacement__Scale])--*(rotateXMatrix this.r_x)*(rotateXMatrix this.r_y)*(rotateXMatrix this.r_z)
		)else(
			matrix3 1
		)
	)
	
	------------- end of load functions -----------------------------
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
		_cylinder.height  = x
		_cylinder.radius = _one;
		_cylinder.sides =12;
		_cylinder.heightsegs = 1;
		_cylinder.mesh
 
	)
	fn Make_cone x = (
		local _m = createInstance cone
		_m.height  = 3*_one
		_m.radius1 = 2*_one;
		_m.radius2 =0;
		_m.sides = 12;
		_m.heightsegs = 1;
		if (x>0) then (
			transformMesh (_m.mesh) (transmatrix [0,0,x])
		)else(
			transformMesh (_m.mesh) ((rotateXmatrix 180)*(transmatrix [0,0,x]))
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
		transformMesh (_m.mesh) (transmatrix [0,0,0.5*(this.display__size+_one)])
	)
	fn Make_pyramid x = (
		local _m = createinstance pyramid 
		_m.height  = 2*_one;
		_m.width = 4*_one;
		_m.depth  = x
		_m.heightsegs = _m.depthSegs = 1 
		transformMesh (_m.mesh) (matrix3 [0,1,0] [0,0,-1] [-1,0,0] [0,4.5*_one,.5*(x+this.display__size)+.5*_one])
	)
	
	/*
		set the meshfunction which generates the mesh 
	*/
	fn setMeshFunction = (
		MeshFunction = fx1fy1fz1rz0ry0rz0
	)
	
	
 
  
	parameters structure rollout:structrue
  (
    loads type:#nodetab tabSize:0 tabSizeVariable:true
	loadsName type:#stringtab tabSize:0 tabSizeVariable:true  
	Displacement type:#matrix3 
	
  )
  parameters Constraint rollout:Constraints	
	(
	dx type:#boolean default:true ui:dx
	dy type:#boolean default:true ui:dy
	dz type:#boolean default:true ui:dz 
	rx type:#boolean default:true  ui:rx
	ry type:#boolean default:true  ui:ry
	rz type:#boolean default:true  ui:rz
		
	elementType type:#string default:"" -- what type of element connects to this node ("Frame" or "Truss)
	NumberOFElements type:#integer default:0 		
	on dx set val do (
		this.Display__Forces = false;
	)
	on dy set val do (
			this.Display__Forces = false;
		)
	on dz set val do (
			this.Display__Forces = false;
		)
	on rx set val do (
			this.Display__Forces = false;
		)
	on ry set val do (
			this.Display__Forces = false;
		)
	on rz set val do (
			this.Display__Forces = false;
		)	
	--depth type:#worldUnits ui:depth default:0
  )
  parameters reactions rollout:Reactions
  (
	force_unit type:#integer default:1 ui:force_unit
		
	fx type:#float default:0 ui:fx
	fy type:#float default:0 ui:fy  
	fz type:#float default:0 ui:fz
	mx type:#float default:0 ui:mx
	my type:#float default:0 ui:my  
	mz type:#float default:0 ui:mz
	  
	 on  force_unit set val do (
		
		if this.model_Node != undefined then this.setModelElement this.model_Node
		
	 )
  )
  Parameters displacements 
  (
		d_x type:#float default:0  
		d_y type:#float default:0  
		d_z type:#float default:0 
		r_x type:#float default:0  
		r_y type:#float default:0 
		r_z type:#float default:0  
	  
	  
  )
  parameters basic rollout:disp 
  (
	  index type:#integer default:0
	  Display__Size type:#worldUnits default:1  ui:displaySize
	  Force__Scale type:#float default:1  ui:Force__Scale
	  Display__Forces type:#boolean default:false  ui:Display__Forces
	  Display__Loads type:#boolean default:false  ui:Display__Loads
		Display__Displacement type:#boolean default:false  ui:Display__Displacement
	  Displacement__Scale type:#float default:1  --ui:Force__Scale
	  
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

  rollout Constraints "Node Constraints"
  (
    group "Fixed movement"(
		checkbox dx "X"  across:3
		checkbox dy "Y"   
		checkbox dz "Z"   
	)
	group "Fixed rotation"(
		checkbox rx "X" across:3   
		checkbox ry "Y" 
		checkbox rz "Z" 
	)
  )
  rollout structrue "Loads"
  (
		local numberOfLoads
	  
		pickbutton addload "Add load" message:"Select a load from the scene" filter:loadFilter autoDisplay:false
		button removeLoad "Remove load"
		listbox loadnames "Loads" height:5
		on addload picked obj do (
			addNodalLoad obj
			--append this.loads 
			--append this.loadsName obj.name 
			populateLoadList structrue
		)
		on loadnames  selected no do (
			removeLoad.enabled = no>0
		)
		on loadnames doubleClicked no do (
			local selectedLoad  = this.loads[no]
			if isvalidnode selectedLoad do select selectedLoad
		)
		on removeLoad pressed do (
			
			deleteitem this.loadsName loadnames.selection 
			deleteitem this.loads loadnames.selection 
			populateLoadList structrue
			this.display__loads = this.loads.count>0 
			 
		)
		on structrue open do (
			populateLoadList structrue
		)
  )
rollout reactions "Reactions" (
	radiobuttons force_unit  ""	labels:#("N","KN") columns:2 
	spinner fx  "Fx" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
	spinner fy "Fy" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
	spinner fz "Fz" type:#float range:[-10000000,10000000,0] scale:0.0001  enabled:false
	spinner mx "Mx" type:#float range:[-10000000,10000000,0] scale:0.0001  enabled:false
	spinner my "My" type:#float range:[-10000000,10000000,0] scale:0.0001  enabled:false
	spinner mz "Mz" type:#float range:[-10000000,10000000,0] scale:0.0001  enabled:false
	on force_unit changed arg do (
		if (this.model_node == undefined ) do 
		(
			messagebox "Please update the analysis result by running the solver." title:"Para3d FEM"
		)
	)		
)
	rollout 	disp "Display"
	(
		spinner displaySize "Display size" type:#worldUnits range:[0.00001,1000000,0] 		
		
		checkbox Display__Forces "Display reactions"
		checkbox Display__Loads "Display loads"
		spinner Force__Scale "Force scale" type:#float range:[0.00001,1000000,0] scale:0.001
		
		checkbox Display__Displacement "Display displacement"
		--spinner Displacement__Scale "Displacement scale" type:#float range:[0.00001,1000000,0] 
	)
  /*
  rollout displayParams "Display parameters"
  (
     spinner size "Display size" type:#worldunits range:[-1000,1000,0]
    
  )
  */
	on buildMesh do
  (
		--updateDisplay()
		this._one = 0.1*this.Display__Size
		tmpMesh = trimesh()
		
		_h  = if this.Display__Forces then (fx*this.Force__Scale) else (if (not dx) then 0 else this.Display__Size)
		
		if (_h!=0) do (	
		--if (not dx) or (Display__Forces and fx>0) do (			
			meshop.attach tmpMesh (transformMesh (Make_Cylinder _h) (rotateYMatrix 90 ))
			meshop.attach tmpMesh (transformMesh (Make_Cone _h ) (rotateYMatrix 90 ))	
		)
		_h  = if this.Display__Forces then fy*this.Force__Scale else if (not dy) then 0 else this.Display__Size
		if (_h!=0) do (
			meshop.attach tmpMesh (transformMesh (Make_Cylinder _h) (rotateXMatrix -90 ))
			meshop.attach tmpMesh (transformMesh (Make_Cone _h) (rotateXMatrix -90 ))
		)
		_h  = if this.Display__Forces then fz*this.Force__Scale else if (not dz) then 0 else this.Display__Size
		if (_h!=0) do (
			meshop.attach tmpMesh (Make_Cylinder _h)
			meshop.attach tmpMesh (Make_Cone _h)  
		)
		_h  = if this.Display__Forces then mz*this.Force__Scale else if (not rz) then 0 else this._one
		if (_h!=0) do (
			meshop.attach tmpMesh (Make_Tube _h)
			meshop.attach tmpMesh (Make_Pyramid _h)
		)
		_h  = if this.Display__Forces then mx*this.Force__Scale else if (not rx) then 0 else this._one
		if (_h!=0) do (
			meshop.attach tmpMesh (transformMesh (Make_Tube _h) (rotateYMatrix 90 )) 
			meshop.attach tmpMesh  (transformMesh (Make_Pyramid _h) (rotateYMatrix 90 ))  
		)
		_h  = if this.Display__Forces then my*this.Force__Scale else if (not ry) then 0 else this._one
		if (_h!=0) do (
			meshop.attach tmpMesh (transformMesh (Make_Tube _h) (rotateXMatrix 90 )) 
			meshop.attach tmpMesh  (transformMesh (Make_Pyramid _h) (rotateXMatrix 90 ))  
		)
		if this.Display__Loads do (
			_fx = _fy=_fz=_mx=_my=_mz =0
			local _ll = undefined 
			for _l in this.loads where isvalidnode _l do (
				_fx += _l.fx;_fy += _l.fy;_fz += _l.fz
				_mx += _l.mx;_my += _l.my;_mz += _l.mz
				_ll = _l
			)
			if isvalidnode _ll do _ll.nodalLoadGeom tmpMesh 1 --_fx _fy _fz _mx _my _mz	 
		)
		
		if tmpMesh.numverts == 0 do (
			_box = createInstance box
			
			_box.Length = this._one 
			_box.Height = this._one 
			_box.Width = this._one 	
			tmpMesh = _box.mesh 
		) 
		if (this.Display__Displacement) then
		(
			displacementMatrix = getDisplacementMatrix()
			mesh = transformMesh tmpMesh displacementMatrix
		)else(
			mesh = tmpMesh
		)		
	  --mesh= MeshFunction()
		
  )
 
	tool create
	(
		on mousePoint click do
		  case click of
		  (
			1: nodeTM.translation = gridPoint
			3: #stop
		   )
		on mouseMove click do
		(
		   case click of
			(
				2: (
					this.Display__Size = gridDist.x;  --this.Display__Size = gridDist.y
		
					)
				3: (
					this.Force__Scale = gridDist.z
				)
			)
		)

	)
)