
/*
loading definitions
*/
filein ("C:\projects\parametric array\FEM\Para3dFEM_Maxscript\Para3dFEM\Definitions\FEM_Materials.ms")

/*
loading the objects
*/
filein ("C:\projects\parametric array\FEM\Para3dFEM_Maxscript\Para3dFEM\Objects\FEM_Load.ms")
filein ("C:\projects\parametric array\FEM\Para3dFEM_Maxscript\Para3dFEM\Objects\FEM_Node.ms")
filein ("C:\projects\parametric array\FEM\Para3dFEM_Maxscript\Para3dFEM\Objects\FEM_Element1D.ms")

/*
loading assemblies 
*/
dotnet.loadassembly ("C:\projects\C#\Para3dFEM\FiniteElementMethod\bin\Debug\FiniteElementMethod.dll");
/* 
adding item to the para + menu
*/
append para3dAddonList #("Add-ons","FEM","FEM Solver","parametric_addon_base","parametric_array_FEM_solver" )
/*
plug-in definition
*/
plugin helper parametric_array_FEM_solver 
name:"FEM solver"
extends:parametric_addon_base
version:1
classID:#(0x42e006c0, 0x60256794)
replaceUI:true
category:"PARA_Addon"

(
		--------------------------------------------------------local variables------------------------------------------------------
	local Info_array = #(
		"Solves the FEM model", --description 
		"Add on",--type
		#() , --possible Outputs
		"FEM solver", -- name appears on controller button
		4.8, -- compatibility
		"fem_solver.jpg",
		#()
	)
	local update_transformations-- declare functions
	local model -- instance of FEM model
	local setElementGeometryAndLoad,updateNode,updateElement,resetData,Solve,exportData
	----- private functions ---------------
	
	
	/*
		this function creates a new parametric array from the given collection. 
		if paranode is laready exist in the channel then it will only set the members
	*/
	fn ParametricArrayFromCollecttion collection channelIndex paraName propFilter= (	
		local _pa = delegate.channels[channelIndex] 
		local newPara = false
		if not isvalidnode _pa do (			
			_pa = parametric_array array_type:1 array_count_1:collection.count  array_count_2:1 array_count_3:1 name:paraName prop_filter:propFilter
			
			parrayLayer = layermanager.getLayerFromName "Parametric Array"
			try(
				parrayLayer.addnode _pa
			)catch()
			newPara = true
		)
		_pa.array_nodes = collection
		--_pa.array_mainnode = _pa.array_nodes[1]
		_pa.setMainObject collection multi:true
		if newPara do (
			if not ::pArray_Setting_rollout.indialog do (
				_pa.delegate.openPara()								
			)		
			local tv_para = ::pArray_Setting_rollout.AddParametricNode _pa
			::pArray_Setting_rollout.AddControllerToChannel  ::para3dNodes[delegate.paraviewIndex] _pa channelIndex tv_para		
		)
	)
	fn CleanArray arrayValue = (
		local tmp = makeUniqueArray arrayValue
		local undefinedINdex = finditem tmp  undefined  
		if undefinedINdex > 0 do deleteitem tmp undefinedINdex
		tmp
	)		
	fn init = (
		model = dotnetobject "FiniteElementMethod.FEM_MAX"	
		model.SystemUnit = units.SystemType as string
		this._nodes = CleanArray (this._nodes as array)
		this._elements = CleanArray (this._elements as array)
	)
	
	
	/*
	fn filterTrussElement item = (
		if isvalidnode item then (
			item.elementType == "Truss" 
		)else(
			false
		)
	)
	fn filterFrameElement item = (
		if isvalidnode item then (
			item.elementType == "Frame" 
		)else(
			false
		)
	)
	*/
	fn swapItems ar item1 item2  = (
		local tmp = ar[item1.index]
		local index2 = item2.index
		ar[item1.index] = item2 ; item2.index = tmp.index
		ar[index2] = item1;item1.index = index2
	)
	/*
		function helps to find the closest point to the refpoint in an array
	*/
	fn compare_distances_from_point  a b refpoint:[0,0,0] = (
		dista = distance a.pos refpoint
		distb = distance b.pos refpoint
		d = dista-distb
		case of (
			(d<0) : -1
			(d>0) : 1
			default : 0
		)		
	)
	/*
		function returns the closest available item to the given point
	
	*/
	fn getItemByPosition itemArray pos startIndex filterFunc = (
		local availableItems = for i=startIndex to itemArray.count where (filterFunc itemArray[i]) collect itemArray[i]
	 
		if availableItems.count == 0 then (
			undefined 
		)else(
			qsort availableItems compare_distances_from_point refpoint:pos
			local tmp = availableItems[1] 		 
			if tmp.index != startIndex do (
				swapItems itemArray itemArray[startIndex] tmp			
			)
			tmp
		)
	)
	/*
		this method updates the given element in the model by setting the properties and lods
		if there is a load associated with the element it will return true 
		item : FEM_Element ( index must be set)
	*/
	fn updateElement item = (
		--format "-- item.index %\n" item.index
		isThereLoad = false
		item.transformProp = item.transform
		if (model.SetCurrentElement (item.index-1))do (
			mat = ::FEM_Materials[item.Element_Material]
			
			
			--string category,string name,double E,double G,int Eunit,double W,int Wunit, double fyc,double fyt,int fyunit
			model.SetElementMaterial mat.Category mat.MaterialName item.Elastic__Modulus item.Shear__Modulus item.Modulus__Unit item.Weight_Per_Unit item.Modulus__Unit item.Fcy item.Fty item.Modulus__Unit ;	-- setting the phtisical properites
			isThereLoad =  setElementGeometryAndLoad item; -- setting the loads and geomertry 						
			
			/*
			case item.elementType of (		
				"TrussElement" : model.SetFrameElement item.Elastic__Modulus item.Shear__Modulus item.Modulus__Unit item.A item.Area__Unit ;
				"FrameElement" : (
					model.SetFrameElement item.Elastic__Modulus item.Shear__Modulus item.Modulus__Unit item.A item.Area__Unit;	-- setting the phtisical properites
					isThereLoad =  setElementGeometryAndLoad item; -- setting the loads and geomertry 					
				)
			)
			*/
		)
		isThereLoad
	)
	/*
		this method updates the given node in the model by setting the positiin and constraints and loads
		if there is a load associated with the element it will return true 
		item : FEM_Element ( index must be set)
	*/
	fn updateNode item = (
		local isThereLoad = false
		
		if (model.SetCurrentNode (item.index-1)) do (
			model.SetNodePosition  item.pos.x item.pos.y item.pos.z 
			model.SetNodeConstraints  item.dx item.dy item.dz item.rx item.ry item.rz  
			--model.ClearNodeLoads()
			for _load in item.loads where isvalidnode _load do (
				model.AddNodalLoad  _load.FX _load.FY _load.FZ _load.MX _load.MY _load.MZ (_load.load_unit) ""
				isThereLoad = true;
			)
		)
		isThereLoad
	)
	/*
		add a new node or return a scene node for the given position
	*/
	fn addNode pos &newNodes &freshNodes = (
		local _n,newNode
		
		local nextNodeINdex = model.GetNodeCount()+1
		
		if nextNodeINdex<=this._nodes.count then ( -- node is available in scene we will choose  the closest one
			_n =  getItemByPosition this._nodes pos nextNodeIndex isvalidnode
			
			if isvalidnode _n then (
				newNode = false
				_n.pos = pos
				
			)else(
				_n  = FEM_Node pos:pos index:nextNodeINdex force_unit:this.forceUnit Force__Scale:this.ForceScale Displacement__Scale:this.DisplacementScale 
				
				newNode = true
				
			)
			
		)else( -- node is not available in scene we will create one
			_n  = FEM_Node pos:pos index:nextNodeINdex force_unit:this.forceUnit Force__Scale:this.ForceScale Displacement__Scale:this.DisplacementScale 
			newNode = true
			
		)
		local _modelNode = model.addNode pos.x pos.y pos.z 
		
		if _modelNode > 0 then ( -- node has been created succesfully
			if newNode do (this._nodes[_modelNode] = _n)
		)else if _modelNode< 0 then ( -- node exist  
			if newNode do (delete _n)
			_n = this._nodes[-1*_modelNode]					
		)else( -- could not create the node
			if newNode do delete _n
		)
		if isvalidnode _n do (
			newNodes[_n.index] = true
			freshNodes[_n.index]  = newNode;
			updateNode _n
		)
		_n
	)
	
	fn GetVectorsAngle v1 v2 v3=
	(
		theAngle = acos(dot (normalize v1) (normalize v2))			
		if ((dot (cross v1 v2)	v3)<0) then 
		(
			-theAngle
		)else(
			theAngle
		)
		
	)
 		
	/*
		set the geometry of the last element added to the model
	*/
	fn setElementGeometryAndLoad item = (
	 
		if  item.SectionTypeString.count == 0 then (
			delegate.errorLog+= "Cross section is not defined in element: " + item.name+"\n"
		)else(
			-- calculate the cross section rotation
			local XAxis = item.transformProp.Row1
			local YAxis = item.transformProp.Row2
			local ZAxis = item.transformProp.Row3
			local webAngle = 0
			if abs (dot ZAxis [0,0,1]) > 0.99 then ( -- in case the zaxis and yaxis are parallel (columns)
				 webAngle = GetVectorsAngle YAxis [1,0,0]  ZAxis
			)else( -- if zaxis and yaxis are not parallel
				 webAngle = GetVectorsAngle YAxis [0,0,1] ZAxis
				
			)
			model.SetSection item.W item.H item.TF item.TW  0 item.SectionTypeString ;
		)
		local tmp = false -- tmp flag will be set to true if at least one load is added to the model
		if this.selfWeight and item.elementType == "Frame" do ( -- for truss element we should ignore the self load on the element
			model.AddSelfLoad()
			tmp = true
		)
		for _load in item.loads where isvalidnode _load do ( 			 
			case _load.load_type of (
				1 : (-- consentrate load 
					model.AddConcentratedLoad _load.FX _load.FY _load.FZ _load.MX _load.MY _load.MZ (_load.getRelativeDistance (distance this._nodes[1].pos this._nodes[2].pos)) (_load.load_unit) 					 
				)
				2 : ( -- uniform load
					--format "-- adding load L: % to % \n"  _load item
					model.AddUnifromLoad _load.FX _load.FY _load.FZ (_load.load_unit) _load.load_coord_sys
				)
			)
			tmp = true;
		)
		tmp;
	)
	/*
		add a new element or return a scene element which is close to the midpoint of two given node
	*/
	fn addElement1D node1 node2 elementType &newElements ZAxis:[0,0,1] = (
		local _e -- the max node which represent the 1delement 
		local newNode -- this is a flag , if true then means we just created a max node otherwise it means we are using an exisiting one
		local pos = node1.pos--0.5*(node1.pos+node2.pos) -- claculate the midpoint 
		local nextElementIndex = model.GetElementCount()+1 -- get the next element index 
		-- setting the elementTypes in nodes
		if node1.elementType == "" do node1.elementType = elementType;
		if node2.elementType == "" do node2.elementType = elementType;
		-- we must add one more element to the number of elements in each node
		node1.NumberOFElements +=1;
		node2.NumberOFElements +=1;
		if nextElementIndex<=this._elements.count then ( -- we still have more elements in scene than it's required let's choose one from them
			/*
			_e =  if (elementType == "Truss" ) then (
				getItemByPosition this._elements pos nextElementIndex filterTrussElement
			)else(
				getItemByPosition this._elements pos nextElementIndex filterFrameElement
			)
			*/
			_e = getItemByPosition this._elements pos nextElementIndex isvalidnode -- choose element from the scene by finding the closest one 
			if isvalidnode _e then ( 
				newNode = false	-- set this flag so we know we did'nt create a new one			
				-- update the position and other properties of the scene element
				_e.pos = pos;_e.node1 = node1;_e.node2=node2;_e.Force__Scale=this.forcescale;_e.force_unit=this.ForceUnit;_e.elementType = elementType; _e.Displacement__Scale=this.displacementScale
			)else( -- we could'nt find an element from the scene ( maybe it was deleted)
				-- here we create a new element (FEM_ELEMENT1D)
				_e = 	FEM_Element1D node1:node1 node2:node2 pos:pos elementType:elementType index:nextElementIndex Force__Scale:this.forcescale force_unit:this.ForceUnit Displacement__Scale:this.displacementScale
				
				newNode = true -- set the flag so we know this is just created
			)
		)else( -- node is not available in scene we will create one
			_e = 	FEM_Element1D  node1:node1 node2:node2 pos:pos elementType:elementType index:nextElementIndex Force__Scale:this.forcescale force_unit:this.ForceUnit Displacement__Scale:this.displacementScale
			newNode = true-- set the flag so we know this is just created
		)
		XAxis = normalize (node2.pos-node1.pos) -- claculate the Zaxis of the element ( X axis in FEM)
		YAxis = [0,1,0] -- let's consider YAxis is always in Y direction 
		
		if abs (dot [0,0,1] Xaxis) > 0.99 then ( -- in case the zaxis and yaxis are parallel (columns)
						
			YAxis = 	normalize (cross [1,0,0] XAxis)
			ZAxis = 	normalize (cross XAxis YAxis)
			
		)else( -- if zaxis and yaxis are not parallel
			YAxis = normalize (cross ZAxis XAxis)
			ZAxis = 	normalize (cross XAxis YAxis)
			
		)
		local NodeTransformation =  matrix3 XAxis YAxis ZAxis pos -- here we comine all axis and positon to a transform matrix
		-- let's check again if YAxis is still upward 
		if (ZAxis.z<0) do (
			-- lets rotate the member around it's ZAxis to fix the direction
			NodeTransformation = (rotateXMatrix 180)*NodeTransformation
		)
		_e.transformProp = _e.transform =NodeTransformation
		model.AddFrameElement (node1.index-1) (node2.index-1) elementType
		-- to be changed from frame to truss
		/*
		if elementType ==  "TrussElement" then (
			model.AddFrameElement (node1.index-1) (node2.index-1) 
		)else(
			model.AddFrameElement (node1.index-1) (node2.index-1)  
			
		)
		*/
		if newNode do (
			append this._elements _e
			_e.index = this._elements.count
			updateElement _e
		)	
		newElements[_e.index] = true	
	
		
		
	)
	/*
		this function creats nodes from vertices and elements from edges of a mesh
		_mesh : the mesh
		newNodes : the indexes of created nodes in bitarray 
		newElements : the indexes of created elements in bitarray 
		freshNodes : index of nodes only created this time
	*/
	fn createElement1DFromMesh _mesh  &newNodes &newElements &freshNodes _transform = (
		elementType  = if this.meshConversion==1 then "Truss" else "Frame"
		local numFaces =  _mesh.numfaces
		local numVerts = _mesh.numverts
		 
		local tempNodes = #() -- a temporary array to hold the nodes
		tempNodes.count = numVerts; -- initialize the array
		for i=1 to numVerts do (
			local pos = (meshop.getvert _mesh i)*_transform
			_n = addNode pos &newNodes &freshNodes -- create or find the node at the position of POS
			tempNodes[i] = _n -- saving the node in temporary array 
		)
		local alreadyDone = #{} -- keep the index of vertices which has been already added to the model to avoid duplicates
		for i=1 to numFaces do (
			local edgeArray = meshop.getEdgesUsingFace   _mesh i  -- get the two vertices of the edge
			jj=1
			for j in edgeArray do (
				if (not alreadyDone[j]) and (getEdgeVis _mesh i jj) do (
					vertArray = (meshop.getVertsUsingEdge _mesh j) as array
					local node1 = tempNodes[vertArray[1]] -- first node
					local node2 = tempNodes[vertArray[2]] -- second node
					reverseEdge = meshop.getEdgesReverseEdge _mesh j 
					local faces = (meshop.getfacesusingedge _mesh (#{j}+reverseEdge)) as array
					local xAxis -- this is actually YAxis in FEM
					if faces.count == 1 then ( -- open edge						
						-- we consider XAxis ( Yaxis in FEM) as the face normal
						xAxis = (getFaceNormal  _mesh faces[1])*_transform.rotationPart 
						
					)else( -- closed edge
						-- we consider XAxis (Yaxis in FEM) is the same as normal vector of the edge 
						xAxis = ((getFaceNormal _mesh faces[1])+(getFaceNormal _mesh faces[2]))*_transform.rotationPart
					)
					--format "-- xaxis % \n" xAxis
					addElement1D node1 node2 elementType &newElements --ZAxis:xAxis -- add max element1d or update an exisitng one
					alreadyDone[j] = true; -- lets flag this edge so we will not create element on this again
					alreadyDone+= reverseEdge -- we also should avoid the reverse edge (remember working on MESH)
				)
				jj+=1 
			)			
		)
		
	)
	
	/*
		this function creats nodes from vertices and elements from edges of an editable poly object
		_poly : the editable poly object
		newNodes : the indexes of created nodes in bitarray 
		newElements : the indexes of created elements in bitarray 
	*/
	
	fn createElement1DFromPoly _poly  &newNodes &newElements &freshNodes = (
		elementType  = if this.meshConversion==1 then "Truss" else "Frame"
		local numEdges = polyop.getnumedges _poly 
		local numVerts = polyop.getnumverts _poly
		 
		local tempNodes = #()
		tempNodes.count = numVerts; -- initialize the list
		for i=1 to numVerts do (
			local pos = polyop.getvert _poly i
			_n = addNode pos &newNodes &freshNodes -- create or find the node at the position of POS
			tempNodes[i] = _n -- saving the node in temporary array 
		)
		for i=1 to numEdges do (
			local edgeArray = polyop.getedgeverts _poly i  -- get the two vertices of the edge
			local node1 = tempNodes[edgeArray[1]] -- first node
			local node2 = tempNodes[edgeArray[2]] -- second node
			local faces = polyop.getedgefaces _poly i 
			local xAxis 
			if faces.count == 1 then ( -- open edge
				xAxis = polyop.getfacenormal _poly faces[1]
			)else( -- closed edge
				xAxis = normalize ((polyop.getfacenormal _poly faces[1])+(polyop.getfacenormal _poly faces[2]))
			)
			addElement1D node1 node2 elementType &newElements --ZAxis:xAxis
		)
	)
	fn GetSplinePlane sh splNo vertNo = (
		local p0 = getKnotPoint sh splNo (vertNo-1)
		local p1 = getKnotPoint sh splNo (vertNo)
		local p2 = getKnotPoint sh splNo (vertNo+1)
		local v1 = normalize (p0-p1);
		local v2 = normalize (p2-p1);
		normalize (cross v1 v2) 
	)
	/*
		this function creats nodes from vertices and elements from segments of a spline shape 
		sh : object with splineshape basedobject 
		newNodes : the indexes of created nodes in bitarray 
		newElements : the indexes of created elements in bitarray 
	*/
	
	fn createElement1DFromShape sh &newNodes &newElements &freshNodes = (
		local splinesNo = numsplines sh 
		elementType  = if this.shapeConversion==1 then "Truss" else "Frame"
		for i=1 to splinesNo do (
			local verticesNo  = numknots sh i
			local preNode = undefined -- previously added node
			local firstNode  = undefined 
			local currentNode = undefined 
			local xAxis 
			if verticesNo==2 then (
				xAxis = sh.dir
			)else(
				xAxis = GetSplinePlane sh i 2 
			)
			for j =1 to verticesNo do (
				local pos = getKnotPoint sh i j 
				currentNode = addNode pos &newNodes &freshNodes
				if isvalidnode currentNode do (
					if isvalidnode  preNode do (
						if j>2 and j<verticesNo do (
							xAxis = GetSplinePlane sh i j
						)
						addElement1D currentNode preNode elementType &newElements --ZAxis:xAxis
					)
					preNode= currentNode
					if not isvalidnode firstNode do firstNode = currentNode
				)				
			)
			if isClosed sh i do ( -- close spline we need to add one extra element to close the ring
				addElement1D  firstNode currentNode elementType &newElements --ZAxis:xAxis
			)
		)
	)
	/*
		this function regenerate the model from scrach
	*/
	fn makeModel = (
		--if model == undefined do init()
		init() -- to make a new model
		local newNodes=#{}
		local newElements=#{}
		local freshNodes = #{}
		for i=5 to delegate.channels.count do (
			pa = delegate.channels[i]
			if isvalidnode pa do (
				for item in pa.array_nodes where isvalidnode item do (
					if superclassof item.baseobject == shape then (
						if classof item.baseobject == line or classof item.baseobject == SplineShape then (
							
							createElement1DFromShape item &newNodes &newElements &freshNodes
							
						)else( -- cannot convert shapes 
							delegate.errorLog += "Unable to convert "+item.name+" to 1D structural element"
							exit;
						)
					)else if classof item == Editable_Poly or classof item == PolyMeshObject  then (
						tempClone = copy item;
						converttopoly tempClone
						createElement1DFromPoly tempClone &newNodes &newElements &freshNodes
						try ( delete tempClone) catch()
					)else if isproperty item "mesh" do (
						createElement1DFromMesh item.mesh &newNodes &newElements  &freshNodes item.transform
					)
				)
			)
		)
		
		-- now we remove extra elements and nodes from the arrays 
		
		-- create a parametric array of new nodes and elements
		if not newNodes.isEmpty then (
			--local newNodeArray = for item in newNodes  collect this._nodes[item]
			for _n in freshNodes where isvalidnode this._nodes[_n] do this._nodes[_n].AutoConstraints();
			ParametricArrayFromCollecttion (this._nodes as array) 1 "Nodes" #("4,1","4,2","4,3","4,4","4,5","4,6","4,16")
		)else(
			delegate.errorLog += "No node has been generated.\n" 
		)
		if not newElements.isEmpty then (
			local newNodeArray = for item in this._elements where iskindof item FEM_Element1D collect item
			if newNodeArray.count>0 do ParametricArrayFromCollecttion newNodeArray 2 "Truss/Frame elements" #("4,2","4,3","4,4","4,5","4,6","4,7","4,8","4,9","4,10","4,11","4,12","4,18","4,19")
		)else(
			delegate.errorLog += "No element has been generated.\n" 
		)
		if not newNodes.isEmpty or not newElements.isEmpty do delegate.paranode.ArrangeChilds()
		this.needsReModel = false
		this.needsUpdate = true;
		--this.ModelSolved = false
		
		resetData()
	)
	/*
		this function updates all the nodes ( position mloads and constraints)
		return true if a load is assigned to at least one node
	*/
	fn updateNodes = (
		isThereLoad = false
		local count = model.GetNodeCount(); 
		for i =1 to count do (
			_n = this._nodes[i];
			tmp = updateNode _n
			isThereLoad  = (isThereLoad  or tmp)
		)
		isThereLoad 
	)
	
	/*
		updates all the elements
	*/
	fn updateElements = (
		isThereLoad = false
		local cc = model.GetElementCount(); 
		--format "-- count % \n" cc
		for i=1 to cc do (
			--format "-- i % \n" i
			item = this._elements[i]
			--updateElement item
			tmp =  (updateElement item)
			 
			isThereLoad = (isThereLoad or tmp)
		)
		isThereLoad
	)
	fn updateModel = (
		model.SystemUnit = units.SystemType as string		
		model.INIT();
		nodalLoadExist = updateNodes()
		elementLoadExist  = updateElements()
		if (nodalLoadExist == false and elementLoadExist == false) do delegate.errorLog += "No load found." 
		this.needsUpdate = false
		this.ModelSolved = false
	)
	/*
		this function reset all the loads
	*/
	fn ApplyLoads = (
		
	)
	fn resetData = (
	 
		for item in this._nodes where isvalidnode item do item.setModelElement undefined
		for item in this._elements where isvalidnode item do item.setModelElement undefined
		--model = undefined ;	
		this.ModelSolved = false;
	)
	fn Solve  = (
		--format "-- solving model \n"
		delegate.errorLog=""
		this.ModelSolved = false
		if this.needsReModel or this.model== undefined do (
			makeModel()
		)
		updateModel()
		
		if delegate.errorLog.count == 0 do (	
			
			--ApplyLoads()
			--model.CheckForErrors()
			if delegate.errorLog.count == 0 do (	
				try (
					model.solve this.solverType
				)catch (
					delegate.errorLog += getCurrentException()
				--	local tmperror =  getCurrentException()					
				--	format "-- error:%\n" tmperror
				--	case  of (
				--		(matchPattern tmperror pattern:"*specified argument was out of the range of valid values.*") : (							 
				--			delegate.errorLog += "Error in solving model\nTry removing some constrains and solving again."
				--		)
				--		default: (if delegate.errorLog.count == 0 do delegate.errorLog += "Error in solving model\n")
				--	)
				)
			 
					
				
				if delegate.errorLog.count == 0 do (
					-- updating the support reations 
					if model.Solved then (
						for i=1 to model.GetNodeCount() do (
							_n = this._nodes[i]
							
							if isvalidnode _n do (
								--format "-- setting node %  \n" _n
								_n.setModelElement (model.GetNode (i-1))
							)							
						)
						for i=1 to model.GetElementCount() do (
							_e = this._elements[i]
							if isvalidnode _e do _e.setModelElement (model.GetElement (i-1))						
						)
						this.ModelSolved = true
					)else(
						
						 
						if model.model.trace.Listeners.count==1 do (						
							_listener = model.model.trace.Listeners.item[0]
							
							if (_listener.Records.count>0) do (							
								clearselection()
								local tmp = ""
								local Toselect = for j=1 to _listener.Records.count collect (
									_record = _listener.Records.item[j-1]
									if not matchpattern tmp pattern:("*"+_record.Message+"*") do tmp+= "Error : "+ _record.Message +"\n"
									if (_record.TargetIdentifier != undefined) do
									(
										local targetIdent = substring _record.TargetIdentifier 1 1 
										if (targetIdent=="F" or targetIdent == "T") then 
										(
											this._elements[ (substring _record.TargetIdentifier 2 -1)  as number	]
										)else(
											this._nodes[ (substring _record.TargetIdentifier 2 -1)  as number	]
										)
									)
								)
								delegate.errorLog = tmp;
								 try(
									select Toselect
								 )catch()
								 
							)
						)
					)
				) 
			)
		)	
	)
	/*
		export the model to text file to be used from a relaiable software
	*/
	fn exportData = (
		if this.needsUpdate do this.updateModel()
		local dotnetExporter = dotnetclass "FiniteElementMethod.Exports";
		local tmpFileName = getSaveFileName caption:"Save FEM data"  types:#("Text|*.cs","SAP|*.s2k")[this.exportType]  
		
		if tmpFileName != undefined do (			
			case this.exportType of (
				1 : (
					dotnetExporter.Export_BFEM model tmpFileName
				)
				
				2 : (
					dotnetExporter.Export_S2K model tmpFileName
				)
				
			)
		)
		dotnetExporter = undefined 
	)
	-------------- common functions -----------------------------
	fn updateScript pa tr = (
		delegate.updateScript pa this tr
	)
 
	------------------------ local functions --------------------------
	
	--fn setmainObject obj = delegate.setmainObject obj
	fn setupChannels = (
		delegate.addchannel 1 "Nodes" "All,Model" 7 0
		delegate.addchannel 2 "Element 1D" "All,Model,Elements" 7 0
		delegate.addchannel 3 "Element 2D" "All,Model,Elements" 7 0
		delegate.addchannel 4 "Element 3D" "All,Model,Elements" 7 0
		/*
		delegate.addchannel 5 "Load 1D" "All,Model,Loads" 7 0
		delegate.addchannel 6 "Load 2D" "All,Model,Loads" 7 0
		delegate.addchannel 7 "Load 2D" "All,Model,Loads" 7 0
		*/
		delegate.addchannel 5 "Para node 1" "All,Para nodes" 7 0
		--if this.numberOfParaNodes > delegate.channels.count
 
		
	)
	--------------------------------------------------------------------
	--------------------------------------------------------------------------
	------------------------------------------------------ common functions -----------------------------------------------------
	fn setdefaults sb ctrl:undefined ChannelIndex:undefined  = ( -- set default values		
		
	)
	


	fn SetChannelByIndex chIndex ctrl = (
		delegate.SetChannelByIndex chIndex ctrl			
		------------------ additional operation if needed ----------------------
		
		--------------------------------------------------------------------------
	)
	fn getControllerInterface cp = (
		global pArray_Setting_rollout
		local addChannel=pArray_Setting_rollout.addChannel
		local addInterface = pArray_Setting_rollout.addInterface		
		CSR = delegate.interfaceStarted();	
		--------------------------------------		
		/*
		CSR.addtext "group \"Units\" (" 
			addInterface CSR 2 #AU caption:"Area"  needsUpdate:true params:"labels:#( \"mm2\",\"cm2\",\"m2\")"
			addInterface CSR 2 #FU caption:"Force"  needsUpdate:true params:"labels:#( \"N\",\"KN\")"
			addInterface CSR 2 #EMU caption:"Elastic Modulus"  needsUpdate:true params:"labels:#( \"PA\",\"GPA\")"
		CSR.addText ")"
		*/
		--CSR.addtext "local commonModel = ::pArray_Setting_rollout.getCommonValue \"model\";\n"
		::pArray_Setting_rollout.enableControlsFunction += "local commonModel = ::pArray_Setting_rollout.getCommonValue \"model\";\n"		
		::pArray_Setting_rollout.enableControlsFunction += "local commonSolved = ::pArray_Setting_rollout.getCommonValue \"ModelSolved\";\n"
		CSR.addtext "fn loadFilter obj = (classof obj ) as string == \"FEM_Load\";\n"
		CSR.addtext "group \"Conversion\" (" 
			--addInterface CSR 2 #shapeConversion caption:"Convert shapes to"  needsUpdate:true params:"labels:#( \"Truss\",\"Frame\")" moreevent:"::pArray_Setting_rollout.setcontrolValue \"needsReModel\" true;enablecontrols()"
			--addInterface CSR 2 #meshConversion caption:"Convert polygons to"  needsUpdate:true params:"labels:#( \"Truss\",\"Frame\")" moreevent:"::pArray_Setting_rollout.setcontrolValue \"needsReModel\" true;enablecontrols()"
			addInterface CSR 2 #Conversion caption:"Convert Polygons and Shapes to"  needsUpdate:true params:"labels:#( \"Truss\",\"Frame\")" moreevents:"::pArray_Setting_rollout.setcontrolValue \"needsReModel\" true;enablecontrols();"
			addInterface CSR 11 #makeModelNow caption:"Generate model"  size:[250,25] moreEvents:"for ctrl in pArray_Setting_rollout.selectedControllerNodes do ctrl.makeModel();enablecontrols()" 
		CSR.addText ")"
		CSR.addtext "group \"Nodes\" (" 
			addInterface CSR 5 #NodalLoad caption:"Pick a load" params:("width:200 message:\"Select and assign load to the selected nodes\" autoDisplay:true filter:loadFilter; ") moreevents:"enablecontrols();" needsUpdate:true  enabled:"(commonModel != undefined)" 
		CSR.addText ")"
		CSR.addtext "group \"Elements\" (" 
			addinterface CSR 3 #selfWeight caption:"Add Self-Weight" needsupdate:true  enabled:"(commonModel != undefined) "		
			addInterface CSR 5 #FrameLoad caption:"Pick a load" params:("width:200 message:\"Select and assign load to the selected frames\" autoDisplay:true filter:loadFilter; ") moreevents:"enablecontrols();" needsUpdate:true   enabled:"(commonModel != undefined)"
		CSR.addText ")"
		CSR.addtext "group \"Loads\" (" 
			addInterface CSR 2 #LoadUnit caption:"Unit"  needsUpdate:true params:"labels:#( \"N\",\"KN\") columns:2"	
		CSR.addText ")"
		CSR.addtext "group \"Solve\" (" 
			addInterface CSR 4 #solverType caption:"Solver type"  needsUpdate:true params:"items:#( \"default\",\"CholeskyDecomposition\",\"ConjugateGradient\")"
			
			addInterface CSR 11 #solveModelNow caption:"Solve" size:[250,25] moreEvents:"for ctrl in pArray_Setting_rollout.selectedControllerNodes do ctrl.solve();enablecontrols();redrawViews()" enabled:"(commonModel != undefined) "	 
			addInterface CSR 11 #ResetModel caption:"Clear data" size:[250,25] moreEvents:"for ctrl in pArray_Setting_rollout.selectedControllerNodes do ctrl.resetData()" 			
			addinterface CSR 3 #autoSolve caption:"Automatically solve the model after update" needsupdate:true 			
		CSR.addText ")"
		CSR.addtext "group \"Forces\" (" 
			addInterface CSR 2 #ForceUnit caption:"Unit"  needsUpdate:true params:"labels:#( \"N\",\"KN\") columns:2" enabled:"(commonModel != undefined) and commonSolved"	moreevents:"redrawViews()"
			addInterface CSR 10 #ForceScale caption:"Scale"  needsUpdate:true params:"range:[-5,5,0] type:#float" enabled:"(commonModel != undefined) and commonSolved" moreevents:"redrawViews()"		
			
			--CSR.addcontrol #gropubox #gb1 "Joints/Supports" paramstr:"height:58 width:80;"   
				addinterface CSR 3 #display_nodal_forces caption:"Display node reacrions" needsupdate:true moreevents:"redrawViews()"	enabled:"(commonModel != undefined) and commonSolved"		
			
			--CSR.addcontrol #gropubox #gb2 "Truss/Frames" paramstr:"height:58 width:80;"   
				addinterface CSR 3 #display_element_forces caption:"Display internal forces/moments" needsupdate:true moreevents:"redrawViews()"	enabled:"(commonModel != undefined) and commonSolved"		
				addInterface CSR 2 #component caption:""  needsUpdate:true params:"labels:#( \"Axial force\",\"Shear Y\",\"Shear Z\",\"Torsion\",\"Moment Y\",\"Moment Z\") columns:3" enabled:"(commonModel != undefined) and commonSolved"	moreevents:"redrawViews()"
				--addInterface CSR 2 #maxvalue caption:""  needsUpdate:true params:"labels:#( \"All values\",\"Absolute maximum\",\"Positive maximum\",\"Negative maximum\") columns:2" enabled:"(commonModel != undefined) and commonSolved"	moreevents:"redrawViews()"
			
		CSR.addText ")"
		CSR.addText "group \"Displacements\" (" 
			addinterface CSR 3 #display_deformedShapes caption:"Display nodal displacement" needsupdate:true moreevents:"redrawViews()"	enabled:"(commonModel != undefined) and commonSolved"	
			addInterface CSR 10 #DisplacementScale caption:"Scale"  needsUpdate:true params:"range:[-8,8,0] type:#float" enabled:"(commonModel != undefined) and commonSolved" moreevents:"redrawViews()"		
		CSR.addText ")"
		CSR.addtext "group \"Export\" (" 
			addInterface CSR 4 #exportType caption:"File type"  needsUpdate:true params:"items:#( \"C# BFEM (.cs)\",\"Sap(.s2K)\")"
			addInterface CSR 11 #ExportModel caption:"Export model" size:[250,25] moreEvents:"for ctrl in pArray_Setting_rollout.selectedControllerNodes do ctrl.exportData()" enabled:"(commonModel != undefined)	"	
		CSR.addText ")"
		-------------------------------------------------------------------------------------
		
		delegate.interfaceCompleted CSR CP;		
	)
	/*
	fn getControllerExpersion pa myc parent:undefined = (
		global pArray_Setting_rollout 
		local addTargetOrChannel = pArray_Setting_rollout.addTargetOrChannel
		local Expression  = ""
		delegate.expressionStarted(); 
		----------------------------------------------
					
		delegate.expressionCompleted this  Expression;
	)
	*/
	
	fn update_transformations selectedObjects:undefined  gage:undefined  = (
		delegate.errorlog = ""
		if this.autoSolve do (
			--makeModel();
			this.Solve()
		)
		 
	)		
	-------------------------------------------------------------------- parameters ------------------------------------------------------
		
	parameters exclusive   
	(
		needsReModel type:#boolean default:true 
		needsUpdate type:#boolean default:true 
		ModelSolved type:#boolean default:false 
		shapeConversion type:#integer default:1 -- 1 for truss 2 for frame
		meshConversion type:#integer default:1	-- 1 for truss 2 for frame 
		Conversion type:#integer default:1	-- 1 for truss 2 for frame 
		solverType type:#integer default:1	  --1 for default 2 for CholeskyDecomposition 3 : ConjugateGradient
		_nodes type:#nodeTab tabSize:0 tabSizeVariable:true	 -- array of FEM nodes within the scene
		_elements type:#nodeTab tabSize:0 tabSizeVariable:true	 -- array of FEM elements within the scene
		LoadUnit type:#integer default:1 -- labels:#("N","KN") columns:2
		ForceUnit type:#integer default:1 -- labels:#("N","KN") columns:2
		ForceScale type:#float default:0 -- labels:#("N","KN") columns:2
		NodalLoad type:#node 
		 
		FrameLoad type:#node
		SelfWeight type:#boolean default:true 
		display_element_forces  type:#boolean default:false 		
		display_nodal_forces  type:#boolean default:false
		component type:#integer default:0 
		exportType type:#integer default:1
		display_deformedShapes type:#boolean default:false
		DisplacementScale type:#float default:0
		--maxvalue type:#integer default:0
		on needsUpdate set val do (
			if not val and model == undefined do needsUpdate = true
		)
		on needsReModel set val do (
			if not val and model == undefined do needsReModel = true
		)
		on ModelSolved set val do (
			if val and model == undefined do ModelSolved = false
		)
		on Conversion set val do (
			shapeConversion = meshConversion = val
		)
		on ForceUnit set val do (
			for item in _nodes where isvalidnode item do (item.force_unit = val;) 
			for item in 	_elements where isvalidnode item do (item.force_unit = val)
		)
		on ForceScale set val do (
			for item in _nodes where isvalidnode item do (item.Force__Scale = 10.0^val;) 
			for item in _elements where isvalidnode item do (item.Force__Scale = 10.0^val;) 
		)
		on DisplacementScale set val do (
			for item in _nodes where isvalidnode item do (item.Displacement__Scale = 10.0^val;) 
			for item in _elements where isvalidnode item do (item.Displacement__Scale = 10.0^val;) 
		)
		on loadUnit set val do (
			for item in _nodes where isvalidnode item do (
				 item.setLoadUnit val
			)
			for item in _elements where isvalidnode item do (
				 item.setLoadUnit val
			)			
		)
		on NodalLoad set val do (
			local tmp = false
			if val != undefined do (
				for item in selection where finditem _nodes item>0 do (
					
					if item.loadFilter val do (
						--item.addload picked
						item.AddNodalLoad val
						tmp = true
					)
				)
			)
			/*
			if tmp == false and _nodes.count>0 do ( 
				this.NodalLoad = undefined 
				if selection.count == 0 then (
					messagebox "Unable to add loads.\nYou must select one or more node(s)" title:"Para 3d"
				)else(
					messagebox "Unable to add loads.\nThe selected nodes were not part of this model." title:"Para 3d"
				)
			)
			*/	
		)
		on FrameLoad set val do (
			local tmp = false
			if val != undefined do (
				for item in selection where finditem _elements item>0 do (
					
					if item.loadFilter val do (
						--item.addload picked
						item.addFrameLoad val
						tmp = true
					)
				)
			)
			/*
			if tmp == false and _elements.count>0 do ( 
				this.NodalLoad = undefined 
				if selection.count == 0 then (
					messagebox "Unable to add loads.\nYou must select one or more node(s)" title:"Para 3d"
				)else(
					messagebox "Unable to add loads.\nThe selected nodes were not part of this model." title:"Para 3d"
				)
			)
			*/	
		)
		on component set val do (
			for _e in this._elements where isvalidnode _e do (
				_e.component = val
			)			
		)
		/*
		on maxvalue set val do (
			for _e in this._elements where isvalidnode _e do (
				_e.maxvalue = val
			)
		)
		*/
		on display_element_forces set val do (
			for _e in this._elements  where isvalidnode _e do (
				_e.Display__Forces = val
			)
		)
		on display_nodal_forces set val do (
			for _n in this._nodes  where isvalidnode _n do (
				_n.Display__Forces = val
			)
		)
		on display_deformedShapes set val do (
			for _n in this._nodes  where isvalidnode _n do (
				_n.Display__Displacement = val
			)
			for _e in this._elements  where isvalidnode _e do (
				_e.Display__Displacement = val
			)
		)
		/*
		AU type:#integer default:1  
		EMU type:#integer default:1
		FU type:#integer default:1
		
		on AU set val do (
			if model != undefined do (
				model.SetAreaUnit val
			)
		)
		on EMU set val do (
			if model != undefined do (
				model.SetElasticModulusUnit val
			)
		)
		on FU  set val do (
			if model != undefined do (
				model.SetForceUnit val
			)
		) 
        */
	)
	parameters common
	(
		autoSolve type:#boolean default:false
		--array_nodes type:#nodeTab tabSize:0 tabSizeVariable:true	
	)
 
	----------- these events should apply on all controllers ------------------
	on load do (
	 
	)	
	on create do (
		--delegate.updateFirst = true
		delegate.firstAutoChannelIndex = 5;
		setupChannels() 
	)
 
)