MODULE Ndogepearl;
IMPORT Base, TexVox, XNXLRotaVox;
  
VAR 
	cv: TexVox.AvaVox;
	rv: XNXLRotaVox.RVox;
	up,right: Base.PT;
	sabot, vox,v,sphere: Base.Voxel;
	center: Base.PT;
PROCEDURE thisvox*():Base.Voxel;
BEGIN
	IF vox=NIL THEN
		NEW(cv,"dogepearl.png");
		vox:=cv;
		vox.passable:=TRUE
	END;
	RETURN vox
END thisvox;

 END Ndogepearl. 
 
 XNXLMarsh.Rez Ndogepearl~