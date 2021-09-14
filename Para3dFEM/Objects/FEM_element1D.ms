plugin simpleObject FEM_Element1D
replaceUI:true
name:"FEM_Element1D"
classID:#(0x39670b08, 0x30a298d9)
category:"Para3d"
invisible:true
Version:1
(
	
	local MeshFunction-- holds the instance of making mesh function
	local GenerateDiagram,FrameForceDiagram,loadDiagram
	local model_Element -- hold an instance of dotnet object represeting the same element in FEM model
	local setModelElement,updateInternalForces,updateFarme,updateTruss,FindClosetPointToLoad -- function declaration
	--local TotalXforces,TotalYforces,TotalZforces,TotalXmoments,TotalYmoments,TotalZmoments
	
	fn overrideScalarParaInterface myRoll allchecked &HasIndeterminate =(
		myRoll.addText "group @Settings@ (\n"  filter:on						
		if allchecked.count ==1 then (
			tr = allchecked.item[0]
			case tr of (
				"4,2" : (
					myRoll.addcontrol #dropdownlist #s_val "Section type" paramStr:" items:#(\"Box\",\"I/ Wide flage\",\"Channel\",\"Tee\",\"Angle\")"				
					myRoll.addhandler #s_val #selected paramstr:"val " codeStr:"setprop val; "
					HasIndeterminate = false
				)
				"4,8" : (
					myRoll.addcontrol #dropdownlist #s_val "Material" paramStr:" items:::FEM_MaterialList"				
					myRoll.addhandler #s_val #selected paramstr:"val " codeStr:"setprop val; "
					HasIndeterminate = false
				)
				"4,10" : (
					myRoll.addcontrol #radiobuttons #s_val "Modulus unit" paramStr:" labels:#(\"GPA\",\"PA(n/m2)\") columns:2"				
					myRoll.addhandler #s_val #selected paramstr:"val " codeStr:"setprop val; "
					HasIndeterminate = false
				)
				"4,18" : (
					myRoll.addcontrol #radiobuttons #s_val "Internal force unit" paramStr:" labels:#(\"N\",\"KN\") columns:2"				
					myRoll.addhandler #s_val #selected paramstr:"val " codeStr:"setprop val; "
					HasIndeterminate = false
				)
				"4,19" : (
					myRoll.addcontrol #spinner #s_val "Divisions" paramStr:" type:#integer range:[3,1000,0] fieldwidth:100 across:2 offset:[50,0]; "
					myRoll.addControl #button #s_val_set "Ok" paramStr:"width:20 Height:20"
				)
				default : (
					myRoll.addcontrol #spinner #s_val "Value" paramStr:" type:#float range:[-1000000000,1000000000,0] fieldwidth:100 across:2 offset:[50,0]; "
					myRoll.addControl #button #s_val_set "Ok" paramStr:"width:20 Height:20"
				)
			)			
		)else(
			myRoll.addcontrol #spinner #s_val "Value" paramStr:" type:#float range:[-1000000000,1000000000,0] fieldwidth:100 across:2 offset:[50,0]; "
			myRoll.addControl #button #s_val_set "Ok" paramStr:"width:20 Height:20"
		)	
		myRoll.addText ")\n" -- end of value gropup 
	
	)
		
	fn defaultMesh = (
		local _box = createInstance box 
		_box.height=1 ; _box.width=1;_box.length=1; _box.widthsegs=1;_box.lengthsegs=1;_box.heightsegs=1
		_box.mesh		
	)
	fn setModelElement dotNetObj  = (
	 
		model_Element = dotNetObj
		updateFarme()
		/*
		case this.elementType of (
			"TrussElement" : (
				updateTruss()
			)
			"FrameElement" : (
				updateFarme()	
			)
			
		)
		*/
	)
 
	/*
		finding maximum absolute/positive/negative values
	*/
	/*
	fn findMaximum input paramName =  (
		
 
		if input > 0 then ( 
			-- checking for positive maximum
			tmpstr = ("Maximum_Positive_" + paramName)
			tmp = getproperty this tmpstr
			if input>tmp do setproperty this tmpstr input;
		)else(
			-- checking for negative maximum
			tmpstr = ("Maximum_Negative_" + paramName)
			tmp = getproperty this tmpstr
		 
			if input<tmp do setproperty this tmpstr input;
		)
		tmpstr = ("Maximum_Absolute_" + paramName)
		tmp = getproperty this tmpstr	
		if abs(input)>tmp do setproperty this tmpstr (abs input);
		input
	)
	*/
	/*
		below function will updates all parameters realted to the internal forces
	*/
	fn updateFarme = (
		disableSceneRedraw() 
		if model_Element == undefined then (			
			for i=1 to this.division do (
				this.Xmoments[i] = this.Ymoments[i] =  this.Zmoments[i] = this.Xforces[i]  = this.Yforces[i]  = this.Zforces[i]  = 0
			)
			--this.Display__Forces = true;
		)else(
			--this.Maximum_Absolute_Torsion=this.Maximum_Absolute_Y_Moment =this.Maximum_Absolute_Z_Moment=this.Maximum_Absolute_Axial_Force=this.Maximum_Absolute_Y_Shear=this.Maximum_Absolute_Z_Shear =0  
			--this.Maximum_Positive_Torsion=this.Maximum_Positive_Y_Moment =this.Maximum_Positive_Z_Moment=this.Maximum_Positive_Axial_Force=this.Maximum_Positive_Y_Shear=this.Maximum_Positive_Z_Shear =0 
			--this.Maximum_Negative_Torsion=this.Maximum_Negative_Y_Moment =this.Maximum_Negative_Z_Moment=this.Maximum_Negative_Axial_Force=this.Maximum_Negative_Y_Shear=this.Maximum_Negative_Z_Shear =0 
			model_Element.Reset();
			--model_Element.CalculateInternalForces();
			
			for i=1 to this.division do (				
				local tmpForce = model_Element.GetFrameInternalForce ((i-1.0)/(this.division-1.0)) this.Force_unit 
				--this.XMoments[i] = findMaximum tmpForce.mx "Torsion" 
				--this.YMoments[i] = findMaximum tmpForce.my "Y_Moment"  
				--this.ZMoments[i] = findMaximum tmpForce.mz "Z_Moment"
				
				--this.Xforces[i] = findMaximum tmpForce.fx "Axial_Force"
				--this.Yforces[i] = findMaximum tmpForce.fy "Y_Shear"
				--this.Zforces[i] = findMaximum tmpForce.fz "Z_Shear"
				this.XMoments[i] =  tmpForce.mx  
				this.YMoments[i] =  tmpForce.my  
				this.ZMoments[i] =  tmpForce.mz 
				
				this.Xforces[i] =  tmpForce.fx  
				this.Yforces[i] =  tmpForce.fy  
				this.Zforces[i] =  tmpForce.fz  

			)
				
			--local MF = model_Element.GetMaximumInternalForce this.Force_unit ; -- returns a jagged array of maximum values
			this.Maximum_Absolute_Torsion= model_Element.GetMaximumInternalForce  1 3 this.Force_unit --MF[1][3] 
			this.Maximum_Absolute_Y_Moment = model_Element.GetMaximumInternalForce 2 3 this.Force_unit --MF[2][3]
			this.Maximum_Absolute_Z_Moment= model_Element.GetMaximumInternalForce 3 3 this.Force_unit --MF[3][3] 
			this.Maximum_Absolute_Axial_Force= model_Element.GetMaximumInternalForce  4 3 this.Force_unit-- MF[4][3] 
			this.Maximum_Absolute_Y_Shear=model_Element.GetMaximumInternalForce  5 3 this.Force_unit --MF[5][3] 
			this.Maximum_Absolute_Z_Shear = model_Element.GetMaximumInternalForce  6 3 this.Force_unit --MF[6][3]  
			
			this.Maximum_Positive_Torsion=model_Element.GetMaximumInternalForce  1 1 this.Force_unit --MF[1][1] 
			this.Maximum_Positive_Y_Moment =model_Element.GetMaximumInternalForce  2 1 this.Force_unit --MF[2][1] 
			this.Maximum_Positive_Z_Moment= model_Element.GetMaximumInternalForce  3 1 this.Force_unit --MF[3][1]  
			this.Maximum_Positive_Axial_Force=model_Element.GetMaximumInternalForce  4 1 this.Force_unit --MF[4][1]  
			this.Maximum_Positive_Y_Shear=model_Element.GetMaximumInternalForce 5 1 this.Force_unit --MF[5][1]  
			this.Maximum_Positive_Z_Shear =model_Element.GetMaximumInternalForce  6 1 this.Force_unit --MF[6][1]  
			
			this.Maximum_Negative_Torsion=model_Element.GetMaximumInternalForce  1 2 this.Force_unit --MF[1][2]  
			this.Maximum_Negative_Y_Moment = model_Element.GetMaximumInternalForce  2 2 this.Force_unit --MF[2][2] 
			this.Maximum_Negative_Z_Moment= model_Element.GetMaximumInternalForce  3 2 this.Force_unit --MF[3][2] 
			this.Maximum_Negative_Axial_Force= model_Element.GetMaximumInternalForce  4 2 this.Force_unit --MF[4][2] 
			this.Maximum_Negative_Y_Shear= model_Element.GetMaximumInternalForce  5 2 this.Force_unit --MF[5][2] 
			this.Maximum_Negative_Z_Shear =model_Element.GetMaximumInternalForce  6 2 this.Force_unit --MF[6][2] 
			
			
		)
		
		
		enableSceneRedraw()
	)
	/*
	fn updateTruss = (
		if model_Element == undefined then (
			
			this.TrussInternalForce =  0;
			this.Display__Forces = false;
		)else(
			this.TrussInternalForce = model_Element.GetTrussInternalForce this.Force_unit
			this.Display__Forces = true;

		)
	)
	*/
		--------------- load related functions ---------------------------
	/*
		set the unit of loads within load array
	*/
	fn setLoadUnit val = (
		for item in this.loads where isvalidnode item do item.Load_unit = val;
	)	
	/*
		this function is used in addload pickbutton 
	*/
	fn loadFilter obj = ( 
		if (classof obj ) as string == "FEM_Load" then (
			finditem this.loads obj == 0  
		)else(
			false
		)
	)
	/*
		add uniform on this element
		obj is fem_load of type of uniform
	*/
	fn addFrameLoad obj = (
		append this.loads obj
		append this.loadsName obj.name 
		this.Display__Loads = true
	)
	/*
		this is to populate the load list in modify panel
	*/
	fn populateLoadList  _r = (		
		_r.loadnames.items = this.loadsName  as array
		_r.removeLoad.enabled = this.loads.count > 0 and _r.loadnames.selection>0
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
	

	/*
		returns the matrix3 value representing the coordinate system of frame 
		note that the Zaxis is align with the element and origin is the position of node1
	*/
	fn getLocalCoordSys1 = (
		inverse (translate (matrixfromnormal (normalize (this.node2.pos-this.node1.pos))) this.node1.pos)
	)
	
	/*
		return the closest point on the member to the given point (load) in local coordsys
		node1 is the origin of the local coordsys
		p is point3 location of the load in global coordsys
	*/	
	fn FindClosetPointToLoad p = (
		p*getLocalCoordSys1()
	)		
	/*
		this function generates a graph using a plane (XY) and given values 
		values: array of values 
	*/
	
	fn GenerateDiagram values = (
		_p = createinstance plane
		_p.width = (distance this.node1.pos this.node2.pos)
		_p.length  = 0;
		_p.lengthsegs = 1;
		_p.widthsegs = this.division-1
		tempMesh = copy _p.mesh
		_shift = _p.width/2.0
		for i= 1 to  this.division do (
			_v = getvert tempMesh (this.division+i) 
			-- move the top vertex in Z direction by value*scale , 
			meshop.movevert tempMesh (i)  [_shift,0,0]
			meshop.movevert tempMesh (this.division+i)  [_shift,0,values[i]*this.Force__Scale] -- 
		)
		tempMesh
		
	)
	
	/*
		attach the mesh for momen diagram to input mesh (_m)
		_m : mesh to be displayed 
	*/
	/*
	fn MomenDiagram _m = (
		case this.display__moments of (
			2: meshop.attach _m (transformMesh (GenerateDiagram this.Xmoments) (rotateYmatrix (-90)))
			3: meshop.attach _m (transformMesh (GenerateDiagram this.Ymoments) (rotateYmatrix (-90)))
			4: meshop.attach _m (transformMesh (GenerateDiagram this.Zmoments) (rotateYmatrix (-90)))
		)
	)
	*/
	/*
		attach the mesh for force diagram to input mesh (_m)
		_m : mesh to be displayed 
	*/
	fn FrameForceDiagram _m = (		
		case this.component of (
			1: meshop.attach _m (GenerateDiagram this.XForces) --(transformMesh (GenerateDiagram this.XForces) (rotateYmatrix (-90)))
			2: meshop.attach _m (GenerateDiagram this.YForces) --(transformMesh (GenerateDiagram this.YForces) (rotateYmatrix (-90)))
			3: meshop.attach _m (GenerateDiagram this.ZForces) --(transformMesh (GenerateDiagram this.ZForces) (rotateYmatrix (-90)))
			4: meshop.attach _m (GenerateDiagram this.XMoments) --(transformMesh (GenerateDiagram this.XMoments) (rotateYmatrix (-90)))
			5: meshop.attach _m (GenerateDiagram this.YMoments) --(transformMesh (GenerateDiagram this.YMoments) (rotateYmatrix (-90)))
			6: meshop.attach _m (GenerateDiagram this.ZMoments) --(transformMesh (GenerateDiagram this.ZMoments) (rotateYmatrix (-90)))
		)
	)
	/*
	fn TrusseForceDiagram _m = (
		meshop.attach _m (transformMesh (GenerateDiagram (for i=1 to this.division collect this.TrussInternalForce)) (rotateYmatrix (-90)))
	)
	*/
	
	/*
		creates a geomerty representing the loads applied on this element
	*/
	fn loadDiagram _m = (
		-- first check if both nodes are valid
		if isvalidnode this.Node1 and isvalidnode this.Node2 do ( 			
			 
			for _l in this.Loads do (
				tmpMesh = trimesh()
				rotMatrix = rotateYmatrix 90
				case _l.Load_type of (
					1: ( -- for point loads we create a line (one face ) from the load to the closest point on the element						
						if _l.load_coord_sys==2 then (
							-- if load is in local coordinate system
							_l.nodalLoadGeom tmpMesh (distance this.Node1.pos this.Node2.pos)
							meshop.attach _m tmpMesh --(transformMesh tmpMesh rotMatrix)								
						)else(
							-- if load is in global coordinate system 
							--_l.nodalLoadGeom tmpMesh (distance this.Node1.pos this.Node2.pos) Trans: ((inverse (this.transformProp.rotationPart as matrix3))*((rotateXmatrix (0))))														
							--meshop.attach _m (transformMesh tmpMesh ((scalematrix [1,1,1])*(rotateXmatrix 0)))	
							_l.nodalLoadGeom tmpMesh (distance this.Node1.pos this.Node2.pos) Trans: ((inverse (this.transformProp.rotationPart as matrix3)))														
							meshop.attach _m tmpMesh --(transformMesh tmpMesh )	
						)
						/*
						v1 = _l.pos*(inverse this.transformProp)  -- position of the laod in local coordsys						
						v3 = [0,0,v1.z] -- closest point to the load on the member						
						setmesh tmpMesh verts:#(v1,v3,v1) faces:#([1,2,3])
						meshop.attach _m tmpMesh				
						*/
					)
					2 : ( -- uniform load.
						--local rotMatrix = (rotatexmatrix (180))*(rotateZmatrix (90)) -- this is to rotate align the mesh from XZ plane to XY plane 
						--rotMatrix = matrix3 1
						
						if _l.load_coord_sys==2 then (
							-- if load is in local coordinate system
							_l.uniformLoadGeom tmpMesh ((distance this.Node1.pos this.Node2.pos))
							meshop.attach _m tmpMesh --(transformMesh tmpMesh rotMatrix)								
						)else(
							-- if load is in global coordinate system 
							_l.uniformLoadGeom tmpMesh ((distance this.Node1.pos this.Node2.pos)) Trans: ((inverse (this.transformProp.rotationPart as matrix3)))--*((rotateYmatrix (-90))))														
							meshop.attach _m tmpMesh--(transformMesh tmpMesh (rotateYmatrix 90))	 --(transformMesh tmpMesh ((scalematrix [-1,-1,-1])*(rotateYmatrix 90)))	
						)
						
					)
				)
			)
		)
	)
	/*
	return the matrix which is used to tranformed the mesh internally so that the member follows the displacement of its nodes
	*/
	fn ComputedisplacementMatrix = (
		local _h =(distance this.node1.pos this.node2.pos) 
		local n1g = this.node1.getDisplacementMatrix()
		local n2g = this.node2.getDisplacementMatrix()
		local inv = inverse this.transformProp
		
		--local n1l = inv*n1g*this.transformProp
		--local n2l = inv*n2g*this.transformProp
		
		local t1 = n1g.TranslationPart*inv-inv.TranslationPart
		local t2 = n2g.TranslationPart*inv-inv.TranslationPart
		local xaxis = [1,0,0] + (t2-t1)/_h
		local yaxis = normalize (cross [0,0,1] (normalize xaxis) )
		local tr = t1--(t1+t2)/2.0
		(matrix3 xaxis yaxis [0,0,1] tr)
		
	)
	
	
	/*
		this function extrude the faces given in mesh (_m) by height of _h in z direction
		_m : the planar mesh
		_h : extrusion height
	*/
	fn ExtrudeProfile _m _h = (
		local tmp1 = copy _m
		
		if (this.Display__Displacement and model_Element!= undefined  and this.elementType =="Frame" ) then 
		(
			
			local previous = [0,0,0]
			local originPoint = [0,0,0]
			local inv= (inverse this.transformProp.rotationpart)
			local axisState = 1.0
			
			if not (close_enough (1+this.transformProp.row1.X) 1.0 10) do (axisState*= this.transformProp.row1.X)
			if not (close_enough (1+this.transformProp.row2.Y) 1.0 10) do (axisState*= this.transformProp.row2.Y)
			if not (close_enough (1+this.transformProp.row3.Z) 1.0 10) do (axisState*= this.transformProp.row3.Z)
		
			--print inv
			for i=1 to (this.division+1) do (
				local xi = ((2.0*(i-1.0)/this.division)-1)
			
				local dispVector = model_Element.GetInternalDisplacement xi				
				--print [dispVector.X ,dispVector.Y, dispVector.Z]
				local flip = if axisState > 0 then 1 else -1
				local d =  this.Displacement__Scale*[dispVector.X ,flip*dispVector.Y,flip*dispVector.Z]
				
				--if (axisState<0) do 	(d = -1.0*d)
				
				--d = d*inv
				local directionVector = [(_h/this.division),0,0]+d- previous --[0,0,1.0-this.Displacement__Scale]+(this.Displacement__Scale*(_h/this.division)/t.Z)*t
				
				previous = d
				local l = (length directionVector)
				if (i>1) then (
					meshop.extrudeedges tmp1 (meshop.getopenedges tmp1) l dir:(normalize directionVector)
					originPoint=originPoint+directionVector
				)else(
					tmp1 =  transformMesh tmp1 (transmatrix  d)
					--meshop.moveVert _m #all (d)
				)
				
			)
			meshop.createPolygon  tmp1 ((meshop.getVertsUsingEdge tmp1 (meshop.getopenedges tmp1) ) as array)
			--_m = transformMesh _m (transmatrix  originPoint)
			
			setmesh _m tmp1
			meshop.weldVertsByThreshold _m #all 0.00001
			meshop.unifyNormals _m #all
			
			
		)else(
		
			meshop.extrudeFaces tmp1 #all _h 0 dir:[1,0,0] 	
			meshop.attach _m tmp1			
		
		)
		
		--meshop.extrudeFaces tmp1 #all _h 0 dir:[0,0,1] 	
		
		
		meshop.autoEdge _m #all 24 type:#SetClear
		
	)
	---------------------------------------------- sections -------------------------------------------
	/*
		these functions are related to geometry making for different sections
	*/
	fn BoxSection = (
		local tmp = trimesh()
		local _h =(distance this.node1.pos this.node2.pos) 
		local p=[0,-0.5*this.W,-0.5*this.H]	
		setmesh tmp vertices: #(
			p,(p+=[0,this.W,0]),(p+=[0,0,this.H]),(p+=[0,-This.W,0])			
		) Faces: #(
			[1,2,3],[1,3,4]
		)
		ExtrudeProfile tmp _h
		tmp
		
	)
	fn RectangleSection = (
		local tmp = trimesh()
		local _h =(distance this.node1.pos this.node2.pos) 
		local p=[0,-0.5*this.W,-0.5*this.H]
	
		setmesh tmp vertices: #(
			p,(p+=[0,this.W,0]),(p+=[0,0,this.H]),(p+=[0,-This.W,0]),
			(p=[0,-0.5*this.W+this.tw,-0.5*this.H+this.TF]),(p+=[0,this.W-2*this.TW,0]),(p+=[0,0,this.H-2*this.TF]),(p+=[0,-this.W+2*this.TW,0])
		) Faces: #(
			[1,2,6],[1,6,5],[2,3,6],[6,3,7],[7,3,4],[8,7,4],[1,5,8],[1,8,4]
		)
		ExtrudeProfile tmp _h
		tmp
 
	)
	fn ISection = (
		local tmp = trimesh()
		local _h =(distance this.node1.pos this.node2.pos) 
		local p=[0,-0.5*this.W,-0.5*this.H]
	
		setmesh tmp vertices: #(
			p,(p+=[0,this.W,0]),(p+=[0,0,this.TF]),(p+=-0.5*[0,This.W-this.TW,0]),(p+=[0,0,this.H-2*this.TF]),(p+=0.5*[0,this.W-This.TW,0]),(p+=[0,0,this.TF]),
			(p+=[0,-this.W,0]),(p+=[0,0,-this.TF]),(p+=0.5*[0,this.W-This.TW,0]),(p+=-1.0*[0,0,this.H-2*this.TF]),(p+=-0.5*[0,this.W-This.TW,0])
		) Faces: #(
			[1,2,3],[1,3,4],[1,4,11],[1,11,12],[11,4,5],[11,5,10],[5,6,7],[10,5,7],[9,10,7],[9,7,8]
		)
		ExtrudeProfile tmp _h
		tmp
 
	)
	fn CSection = (
		local tmp = trimesh()
		local _h =(distance this.node1.pos this.node2.pos) 
		local p=[0,-0.5*this.W,-0.5*this.H]
		
		setmesh tmp vertices: #(
			p,(p+=[0,this.W,0]),(p+=[0,0,this.TF]),(p+=-1.0*[0,This.W-this.TW,0]),(p+=[0,0,this.H-2*this.TF]),(p+=1.0*[0,this.W-This.TW,0]),(p+=[0,0,this.TF]),
			(p+=[0,-this.W,0]),(p+=[0,0,-this.H])
		) Faces: #(
			[1,2,3],[1,3,4],[1,4,5],[1,5,8],[5,6,7],[5,7,8]
		)
		ExtrudeProfile tmp _h
		tmp
	)
	fn TSection = (
		local tmp = trimesh()
		local _h =(distance this.node1.pos this.node2.pos) 
		local p=[0,-0.5*this.TW,-0.5*this.H]
		
		setmesh tmp vertices: #(
			p,(p+=[0,this.TW,0]),(p+=[0,0,this.H-this.TF]),(p+=0.5*[0,This.W-this.TW,0]),(p+=[0,0,this.TF]),(p+=-1.0*[0,this.W,0]),(p+=[0,0,-this.TF]),
			(p+=0.5*[0,this.W-this.TW,0])
		) Faces: #(
			[1,2,3],[1,3,8],[3,4,5],[8,3,5],[7,8,5],[7,5,6]
		)
		ExtrudeProfile tmp _h
		tmp
	)
	fn LSection = (
		local tmp = trimesh()
		local _h =(distance this.node1.pos this.node2.pos) 
		local p=[0,-0.5*this.W,-0.5*this.H]		
		setmesh tmp vertices: #(
			p,(p+=[0,this.W,0]),(p+=[0,0,this.TF]),(p+=-1.0*[0,This.W-this.TW,0]),(p+=[0,0,this.H-this.TF]),(p+=-1.0*[0,this.TW,0])			
		) Faces: #(
			[1,2,3],[1,3,4],[1,4,5],[1,5,6]
		)
		ExtrudeProfile tmp _h
		tmp
	)
	/*
	fn setMeshFunction = (
		if isvalidnode this.node1 and isvalidnode this.node2 then (
			case this.Section__Type of (
				1 : this.MeshFunction = BoxSection
				default :  this.MeshFunction = BoxSection
			)
		)else(
			this.MeshFunction = defaultMesh
		)
		
	)
	*/
	-- in case user wants to pick a node 
	fn FEM_node_Filter obj = (
		(classof obj ) as string == "FEM_Node"  and obj != this.node1 and obj != this.node2
	)
 
	-- to be updated
	fn updateFrameInternalForce forceObject= (
	 
	)
	
	parameters basic rollout:basic
  (
    node1 type:#node ui:node1 
    node2 type:#node ui:node2 
    index type:#index default:0
	 /*
	  on node1 set val do ( 
		 setMeshFunction()
	 )
	 on node2 set val do ( 
		 setMeshFunction()
	 )
	  */
	--depth type:#worldUnits ui:depth default:0
  )
  parameters geom rollout:geom
  (
	Section__Type type:#integer ui:Section__Type	 default:1
	SectionTypeString type:#string default:""
	--A Type:#float ui:crossSectionArea default:10
	--Area__Unit Type:#integer ui:AreaUnit default:2
	W type:#worldUnits default:0.24 ui:W
	H  type:#worldUnits default:0.52 ui:H
	L type:#worldUnits default:1	ui:L  
	
	TW type:#worldUnits default:0.006 ui:TW -- web thickness 
	TF type:#worldUnits default:0.01 ui:TF -- flange thickness
 
	  on Section__Type set val do (
		if val>0 do (
			SectionTypeString = #("B","I","C","T","L","R")[val]
		)
	)
	transformProp type:#matrix3 default:(matrix3 1)
  )
  parameters structure rollout:structrue
  (
    Element_Material type:#integer ui:Element_Material default:1
	Elastic__Modulus type:#float ui:elastic_module default:210
	Modulus__Unit type:#integer ui:module_unit default:1
    Shear__Modulus type:#float ui:shear_module default:210	
	Fcy type:#float ui:Fcy  default:0.25	  
	Fty type:#float ui:Fty default:0.25	  
	Weight_Per_Unit type:#float ui:Weight_Per_Unit default:210	 
    needsMaterialUpdate type:#boolean default:false
	loads type:#nodetab tabSize:0 tabSizeVariable:true
	loadsName type:#stringtab tabSize:0 tabSizeVariable:true  
	elementType type:#string   
	on Element_Material set val do (
		--format "-- val % \n" val
		tmpMaterial = ::FEM_Materials[val]
		if  tmpMaterial.MaterialName != "Custom" do (
			tmpMaterial = ::FEM_Materials[val]
			needsMaterialUpdate = false
			Elastic__Modulus = tmpMaterial.modulusOfElasiticity
			Shear__Modulus = tmpMaterial.ShearModulus
			Weight_Per_Unit = tmpMaterial.WeightPerUnit
			Modulus__Unit = tmpMaterial.getElasiticity_Unit()
			Fcy = tmpMaterial.Fcy
			Fty = tmpMaterial.Fty
			needsMaterialUpdate = true
		)			
	)
	on Modulus__Unit set val do (
		tmpMaterial = ::FEM_Materials[Element_Material]	
		if(tmpMaterial.Category != "Custom" and needsMaterialUpdate) do Element_Material =1
	)
	on Elastic__Modulus set val do (
		tmpMaterial = ::FEM_Materials[Element_Material]
		if(tmpMaterial.Category != "Custom" and needsMaterialUpdate) do Element_Material =1
	)
	on Shear__Modulus set val do (
		tmpMaterial = ::FEM_Materials[Element_Material]
		if(tmpMaterial.Category != "Custom" and needsMaterialUpdate) do Element_Material =1
	)
	on Weight_Per_Unit set val do (
		tmpMaterial = ::FEM_Materials[Element_Material]
		if(tmpMaterial.Category != "Custom" and needsMaterialUpdate) do Element_Material =1
	)
	on Fcy set val do (
		tmpMaterial = ::FEM_Materials[Element_Material]
		if(tmpMaterial.Category != "Custom" and needsMaterialUpdate) do Element_Material =1
	)
	on Fty set val do (
		tmpMaterial = ::FEM_Materials[Element_Material]
		if(tmpMaterial.Category != "Custom" and needsMaterialUpdate) do Element_Material =1
	)
    --depth type:#worldUnits ui:depth default:0
  )
  /*
  parameters trussInternalForces rollout:truss
  (
	  --
	  --TrussInternalForce type:#float ui:TrussInternalForce
		
  )
  */
  parameters displayParams rollout:displayParams
  (
		Force__Scale type:#float default:1  ui:Force__Scale
		Display__Forces type:#boolean default:false  ui:Display__Forces
		Component type:#integer default:5  ui:Component
		--maxvalue type:#integer default:5  ui:maxvalue
		Display__Loads type:#boolean default:false  ui:Display__Loads
	  	Force_unit type:#integer default:1 ui:Force_unit
		division type:#integer default:10 ui:division
		Xmoments type:#floatTab tabsizevariable:true
		Ymoments type:#floatTab tabsizevariable:true
		Zmoments type:#floatTab tabsizevariable:true
		Xforces type:#floatTab tabsizevariable:true
		Yforces type:#floatTab tabsizevariable:true
		Zforces type:#floatTab tabsizevariable:true
		Display__Displacement type:#boolean default:false  ui:Display__Displacement
		Displacement__Scale type:#float default:1  --ui:Force__Scale
	  	on division set val do (
			Xforces.count=Yforces.count=Zforces.count=Zmoments.count=Ymoments.count=Xmoments.count = val
			updateFarme()
		)
		on Force_unit set val do (
			setModelElement this.model_element	
		)
  )
  parameters MaximumParams rollout:reactions
  (
	  	Maximum_Absolute_Torsion type:#float default:0 ui:Maximum_Absolute_Torsion
		Maximum_Absolute_Y_Moment type:#float default:0 ui:Maximum_Absolute_Y_Moment
		Maximum_Absolute_Z_Moment type:#float default:0 ui:Maximum_Absolute_Z_Moment
		Maximum_Absolute_Axial_Force type:#float default:0 ui:Maximum_Absolute_Axial_Force
		Maximum_Absolute_Y_Shear type:#float default:0 ui:Maximum_Absolute_Y_Shear
		Maximum_Absolute_Z_Shear type:#float default:0 ui:Maximum_Absolute_Z_Shear
		
		Maximum_Positive_Torsion type:#float default:0 ui:Maximum_Positive_Torsion
		Maximum_Positive_Y_Moment type:#float default:0 ui:Maximum_Positive_Y_Moment
		Maximum_Positive_Z_Moment type:#float default:0 ui:Maximum_Positive_Z_Moment
		Maximum_Positive_Axial_Force type:#float default:0 ui:Maximum_Positive_Axial_Force
		Maximum_Positive_Y_Shear type:#float default:0 ui:Maximum_Positive_Y_Shear
		Maximum_Positive_Z_Shear type:#float default:0 ui:Maximum_Positive_Z_Shear
		
		Maximum_Negative_Torsion type:#float default:0 ui:Maximum_Negative_Torsion
		Maximum_Negative_Y_Moment type:#float default:0 ui:Maximum_Negative_Y_Moment
		Maximum_Negative_Z_Moment type:#float default:0 ui:Maximum_Negative_Z_Moment
		Maximum_Negative_Axial_Force type:#float default:0 ui:Maximum_Negative_Axial_Force
		Maximum_Negative_Y_Shear type:#float default:0 ui:Maximum_Negative_Y_Shear
		Maximum_Negative_Z_Shear type:#float default:0 ui:Maximum_Negative_Z_Shear

		
		--TrussInternalForce type:#float 
	
		
  )

  rollout basic "Node Parameters"
  (
    pickbutton node1 "Start" message:"Select a FEM_Node object" filter:FEM_node_Filter toolTip:"Set the first node of this element" autoDisplay:true
	pickbutton node2 "End" message:"Select a FEM_Node object" filter:FEM_node_Filter toolTip:"Set the second node of this element" autoDisplay:true
  )
  rollout geom "Sectional Parameters"
  (
    dropdownlist  Section__Type "Section" items:#("Box","I/ Wide flage","Channel","Tee","Angle"/*,"Rectangle"*/) tooltip:"Select a profile section"    
	/*
	group "Section area"(
		radiobuttons AreaUnit  "Unit"	labels:#("mm2","cm2","m2") columns:3
		spinner crossSectionArea "Cross section area" type:#float range:[-1000,1000,0] 
	)
	*/
	group "Dimensions"(
		spinner W "Width" type:#worldUnits default:0.1
		spinner H  "Height" type:#worldUnits default:0.1
		spinner L "Length "type:#worldUnits default:1	enabled:false  
		spinner TW "TW" type:#worldUnits  
		spinner TF "TF" type:#worldUnits  		
	)
	on geom open do (
		TW.enabled = TF.enabled = Section__Type.selection>1
	)
	on Section__Type selected val do (
		TW.enabled = TF.enabled = val>1
	)
  )
  rollout structrue "Structural Parameters"
  (
    group "Physical properties" (
		dropdownlist Element_Material "Material" items:::FEM_MaterialList  tooltip:"Select a material from the library"
		radiobuttons module_unit  "Unit"	labels:#("GPa","MPa","PA") columns:3 align:#left
		spinner elastic_module "Elastic Module" type:#float range:[0.000001,100000000,0]
		spinner shear_module "Shear Module" type:#float range:[0.000001,100000000,0]
		spinner Fcy "Fcy" type:#float range:[0.000001,100000000,0] toolTip:"Compressive Yeild Strength"
		spinner Fty "Fty" type:#float range:[0.000001,100000000,0] toolTip:"Tensile Yeild Strength"
		spinner Weight_Per_Unit "Weight/Unit" type:#float range:[0.000001,1000000,0]
		
    )
	
  )
  rollout loadParameters "Loads" (
	  local numberOfLoads
	  
		pickbutton addload "Add load" message:"Select a load from the scene" filter:loadFilter autoDisplay:false
		button removeLoad "Remove load"
		listbox loadnames "Loads" height:5
		on addload picked obj do (
			addFrameLoad obj
			populateLoadList loadParameters
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
			populateLoadList loadParameters
		)
		on loadParameters open do (
			populateLoadList loadParameters
		)	  
  )
  /*
  rollout truss "Truss internal forces"
  (
	
	group "Forces" (
		spinner TrussInternalForce  "Internal force" type:#float range:[-1000000,1000000,0] scale:0.0001 enabled:false
	)
  )
  */
  rollout displayParams "Display"
	(
		
		 
		checkbox Display__Loads "Display external loads"
		checkbox Display__Displacement "Display nodal displacement"
		group "Internal forces"  (
			checkbox Display__Forces "Display internal forces"
			radiobuttons Component "Force/Moment component" labels:#("SX","SY","SZ","MX","MY","MZ") columns:3
			--radiobuttons maxvalue "Value" labels:#("All values","Absolute maximum","Positive maximum","Negative maximum") columns:1
			radiobuttons Force_unit  ""	labels:#("N","KN") columns:2 
			spinner Force__Scale "Scale" type:#float range:[0.00001,1000000,0]
			spinner division "Resolution" type:#integer range:[3,100,10] 
		)
	)
	rollout reactions "Internal Forces" (
		group "Maximum Absolute" (
			spinner Maximum_Absolute_Torsion "Torsion" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Absolute_Y_Moment "Moment Y" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Absolute_Z_Moment "Moment Z" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Absolute_Axial_Force "Axial" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Absolute_Y_Shear "Shear Y" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Absolute_Z_Shear "Shear Z" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
		)
		group "Maximum Positive" (
			spinner Maximum_Positive_Torsion "Torsion" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Positive_Y_Moment "Moment Y" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Positive_Z_Moment "Moment Z" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Positive_Axial_Force "Axial" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Positive_Y_Shear "Shear Y" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Positive_Z_Shear "Shear Z" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
		)
		group "Maximum Negative" (
			spinner Maximum_Negative_Torsion "Torsion" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Negative_Y_Moment "Moment Y" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Negative_Z_Moment "Moment Z" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Negative_Axial_Force "Axial" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Negative_Y_Shear "Shear Y" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
			spinner Maximum_Negative_Z_Shear "Shear Z" type:#float range:[-10000000,10000000,0] scale:0.0001 enabled:false
		)
		
	)
  on buildMesh do
  (
		--local tmpMesh = this.MeshFunction()
		local tmpMesh = trimesh()
		if isvalidnode node1 and isvalidnode node2 do (
			case this.SectionTypeString of (
				"R" : tmpMesh = RectangleSection()
				"I" : tmpMesh = Isection()
				"C" : tmpMesh = Csection()
				"T" : tmpMesh = Tsection()
				"L" : tmpMesh = Lsection()
				"B" : tmpMesh = boxsection()
				default: 	tmpMesh = boxsection()
			)
		 
			if this.Display__Forces do (				
				FrameForceDiagram tmpMesh
				/*
				if this.elementType == "FrameElement" then (
					FrameForceDiagram tmpMesh
				)else(
					TrussForceDiagram tmpMesh
				)
				*/
			)
			if this.Display__Loads do (
				loadDiagram tmpMesh
			)
		)
		if (this.Display__Displacement) then
		(
			if ( this.elementType == "Truss") then (
				-- for truss we must use nodal displacmenets
				local dm = ComputedisplacementMatrix()		
				mesh =  transformMesh  tmpMesh dm	
			)else(
				mesh = tmpMesh	-- defirmation of the frame is already calculated
			)
			--meshop.moveVert tmpMesh #all dm.translationPart
			--print dm.scalepart
			 -- transformMesh  tmpMesh dm	
		)else(
			mesh= tmpMesh;			
		)
  )
  /*
  rollout displayParams "Display parameters"
  (
     spinner size "Display size" type:#worldunits range:[-1000,1000,0]
    
  )
  */
  /*
  on create do (
	  delegate.centermarker = true;
	  delegate.axistripod= false;
		delegate.cross = false 
		delegate.box = false;
		delegate.constantscreensize = true
	delegate.drawontop = true
  )
*/
  /*
  on create do (
	  setMeshFunction()
  )

  on clone do (
	  setMeshFunction()
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
        2: (width = gridDist.x; depth = gridDist.y)
        3: height = gridDist.z
      )
  )
)