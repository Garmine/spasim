MODULE NtxxZorqH5oWxECOCwH59AQ;(*anonymous module created by saboteur*)
  

IMPORT Base,  Noise;

TYPE Ray = Base.Ray;
	Voxel = Base.Voxel;  
	
TYPE NoiseVox*=OBJECT(Base.Voxel);
PROCEDURE Shade (VAR ray: Ray);
VAR
	n,m,o,dot,fade:REAL;
BEGIN
	dot := ABS(ray.fnormal.x*ray.dxyz.x + ray.fnormal.y*ray.dxyz.y+ ray.fnormal.z*ray.dxyz.z);
	n:= Noise.noise3dperlinabs(ENTIER(ray.xyz.x*100), ENTIER(ray.xyz.y*100),ENTIER(ray.xyz.z*100),666,4,4);
	n:=n-ENTIER(n);
	ray.r:= ray.r + ray.ra*dot*n;
	ray.g:= ray.g + ray.ga*dot*n;	
	ray.b:= ray.b +ray.ba*dot*n;
	ray.terminate:=TRUE
END Shade;
END NoiseVox;  
VAR 
	sky: NoiseVox;
PROCEDURE thisvox*():Voxel;
BEGIN
	IF sky=NIL THEN 
		NEW(sky)
	END;
	RETURN sky
END thisvox;
END NtxxZorqH5oWxECOCwH59AQ. 