/*
this file contains the materials property used in FEM element1D object

*/
struct FEM_Material (
	
	Category,MaterialName,WeightPerUnit,modulusOfElasiticity,ShearModulus,Fcy,Fty, 
	WeightPerUnit_Unit = #KNM3,
	elasiticity_Unit = #GPa,
	fn getFullName = Category+"/"+MaterialName,
	fn getElasiticity_Unit = case elasiticity_Unit of (
		#GPa : 1 
		#MPa : 2
		#Pa :3 
	)
)

---------------------------Category ---- Name ------------ Weight per unit (KN/m3) ---- modulus of elasiticity (E), GPA ------- Shear Modulus (G) , compressive yeild stress (Fyc), Tnesile yeild stress (Fyt) 
FEM_Materials = #(	
	FEM_Material "Steel" "A992Fy50"  76.9729 199.9 76.903069 0.3447 0.3447,
	FEM_Material "Aluminum" "6061T6" 26.6018 69.6371 26.1793 0.2413 0.2413, 
	FEM_Material "Concrete" "4000Psi"  23.5631 24.8556 10.3565 0.0276 0.0276 ,
	FEM_Material "Custom" ""  76.97 210 80.76 0.25 0.25
	
)
FEM_MaterialList = for item in FEM_Materials collect item.getFullName();