MODULE Render;
IMPORT Kernel, Objects, Random, Marsh,(* ALUT := OpenALUtil, XNXLAudio,*)
 Out := KernelLog, Math,XNXLMath, Base,  Retina, GLW := OGLWindow, 
	 GL:=OpenGL, GLC := OpenGLConst,  GLSL:= GLShaderUtils,
	 Inputs,  Raster, Strings, Streams, Debugging;

TYPE 
	Aperture = Base.Aperture;
	Ray = Base.Ray;
	Voxel = Base.Voxel; 
	PT = Base.PT;
	Float = GL.Float;
	Uint = GL.Uint;
    	Int = GL.Int;
    	Ushort = GL.Ushort;
    	
TYPE SNAP = RECORD
	lookphi, looktheta : REAL;
	aperture: Aperture;
	x,y,z,cdroll: REAL;		
	lookdxyz:PT;
END;	
TYPE Camera = OBJECT
VAR
	random: Random.Generator;
	rayschanged, ang1,filter: BOOLEAN;
	fovealeft, fovearight, foveabottom, foveatop: LONGINT;
	fovea: BOOLEAN;
	cam,worldcenter: PT; 
	d2c:REAL;
	W,H,pointerx,pointery:LONGINT;
	aperture: Aperture;
	iamalargecamera: BOOLEAN;
	lookdxyz:PT;
	cx, cy, cz, cvx, cvy, cvz, cvl, cvu: REAL;   
	xaxis,yaxis,zaxis,UP,down:PT; 
	croll: REAL;
	cdroll: REAL;
	cameratheta,cameraphi: REAL;
	world:Voxel;	
	positionlock, orientationlock, returntohorizon: BOOLEAN;	
	fisheye: REAL;	
	gravity: REAL;

PROCEDURE & init (width, height: INTEGER);
BEGIN
	W := width; H := height;
	filter:=FALSE;
	cameratheta := 0;
	cameraphi := 0;
	aperture.width :=1.5;
	aperture.height :=1.5;
	aperjust(1,1);
	Base.setPT(xaxis, 1,0,0);	
	Base.setPT(yaxis,0,1,0);	
	Base.setPT(zaxis,0,0,-1);	
	Base.setPT(worldcenter,1/2,1/2,1/2);	
	cx:=1/2; cy:=1/2; cz:=1/2;
	fisheye:=1;
	GLIDE:=0.98;
	hop; 
END init;

PROCEDURE aperjust(w,h: INTEGER);
BEGIN
	aperture.width :=aperture.width*(w/h);
END aperjust;

PROCEDURE hop;
BEGIN
	stop;
	cx :=cx+Base.rand.Uniform()/500-1/1000; 
	cy :=cy+Base.rand.Uniform()/500-1/1000; 
	cz :=cz+Base.rand.Uniform()/500-1/1000; 
END hop;

PROCEDURE move;
VAR
	face: INTEGER;
	x,y,z,d: REAL;
	v, target: Voxel;
	p,q,normal: PT;
	proberay: Ray;
	pass,slower: BOOLEAN;

PROCEDURE normalize(VAR x,y,z,d: REAL);
BEGIN
	d := Math.sqrt(x*x + y*y+z*z);
	x := x/d; y := y/d; z:=z/d
END normalize;	

PROCEDURE denormalize(VAR x,y,z,d: REAL);
BEGIN
	x := x*d; y := y*d; z:=z*d
END denormalize;	

PROCEDURE reflect(VAR x,y,z: REAL; nx,ny,nz:REAL);
VAR 
	dot: REAL;
BEGIN
	dot := x*nx+y*ny+z*nz;
	nx := 2*nx*dot; ny := 2*ny*dot; nz := 2*nz*dot;
	x := x-nx; y := y-ny; z := z-nz; 
END reflect;

BEGIN
	x := cx + cvx; y := cy + cvy; z := cz + cvz;
	p:=Base.mkPT(x,y,z);
	v := Base.world.probe(p,200);
	pass := Base.world.passprobe(p);

	IF ~pass THEN
	(*	XNXLAudio.LoadWav("grain.wav");
		XNXLAudio.Play ;	
		ALUT.Play(Base.grainsound);
		
		Out.String("grain!");*)
		x := cx + cvx; y := cy + cvy; z := cz;	
		q:=Base.mkPT(x,y,z);
		pass := Base.world.passprobe(q);
		IF pass THEN 
			cvz:=0 (* -cvz/2 *)
		ELSE
			x := cx + cvx; y := cy; z := cz+cvz;	
			q:=Base.mkPT(x,y,z);
			pass := Base.world.passprobe(q);
			IF pass THEN 
				cvy:=0
			ELSE			
				x := cx; y := cy + cvy; z := cz+cvz+0.001;	
				q:=Base.mkPT(x,y,z);
				pass := Base.world.passprobe(q);
				IF pass THEN 
					cvx:=0 
				END
			END
		END
	END;
	IF  pass THEN 
		cx:=x; cy:=y; cz:=z 
	ELSE
		Base.world.Shade(proberay);
		normalize(cvx,cvy,cvz,d);
		reflect(cvx, cvy, cvz, proberay.normal.x, proberay.normal.y, proberay.normal.z);
		denormalize(cvx,cvy,cvz,d);	
		cvx:=cvx/2; cvy:=cvy/2; cvz:=cvz/2; 
	END;
	IF cx<0 THEN cx:=cx+1
	ELSIF cx>1 THEN cx:=cx-1
	END;
	IF cy<0 THEN cy:=cy+1
	ELSIF cy>1 THEN cy:=cy-1
	END;
	IF cz<0 THEN cz:=cz+1
	ELSIF cz>1 THEN cz:=cz-1
	END;	
END move; 

PROCEDURE stop;
BEGIN
	cvx:=0;
	cvy:=0;
	cvz:=0;
END stop;

PROCEDURE glidetoggle;
BEGIN
	IF GLIDE<1/2 THEN GLIDE:=0.95 ELSE GLIDE:=0.3 END;
END glidetoggle;

PROCEDURE forward(x:REAL);
VAR
	fward,dward,rward:PT;
BEGIN
(*	fward:=Base.mkPT(1,0,0);
	dward:=Base.mkPT(0,0,1);
	rward:=Base.mkPT(0,1,0);	
	XNXLMath.orrot(fward, dward,cameraphi);   
	XNXLMath.orrot(rward, dward,cameraphi);   		
	XNXLMath.orrot(fward, rward,cameratheta);  	*)
	fward:=Retina.fward;
	cvx :=cvx+(x*fward.x); 
	cvy :=cvy+(x*fward.y); 	
	cvz :=cvz+(x*fward.z);
END forward;

PROCEDURE rightstrafe(x:REAL);
VAR
	rward,dward:PT;
	ray: Base.Ray;
BEGIN
	rward:=Retina.fward;
	dward:=Base.mkPT(0,1,0);
	XNXLMath.orrot(rward, dward,3.14159/2);   		
	cvx :=cvx+(x*rward.x); 
	cvy :=cvy+(x*rward.y); 	
	cvz :=cvz+(x*rward.z); 	
END rightstrafe;

PROCEDURE upstrafe(x:REAL); 
VAR
	rward,dward,fward:PT;
	ray: Base.Ray;
BEGIN
	dward:=Base.mkPT(0,0,1);
	rward:=Base.mkPT(0,1,0);	
	XNXLMath.orrot(rward, dward,cameratheta);   		
	XNXLMath.orrot(dward, rward,cameraphi);  		
	cvx :=cvx+(x*dward.x); 
	cvy :=cvy+(x*dward.y); 	
	cvz :=cvz+(x*dward.z); 	
END upstrafe;

PROCEDURE trace;
VAR
	t,p,h,w: REAL;
BEGIN
	Retina.go(cameratheta,cameraphi,aperture.width,aperture.height); 
END trace; 

PROCEDURE left (th: REAL);
BEGIN
	IF ~orientationlock THEN
		cvl:=cvl+th;
		cameratheta:=cameratheta+cvl;
		IF cameratheta> 6.28 THEN cameratheta := cameratheta-6.28 END;
		IF cameratheta< -6.28 THEN cameratheta := cameratheta+6.28 END
	END
END left;

PROCEDURE up (ph: REAL);
BEGIN
	cvu:=cvu+ph;
	cameraphi := cameraphi + cvu;
	IF cameraphi > 1.6 THEN cameraphi := 1.6 END;
	IF cameraphi < -1.6 THEN cameraphi := -1.6 END 	
END up;

PROCEDURE tick;
VAR
	oldcam:PT;
	a,b,c,d,e,f: REAL;
	gravityvector: PT;
	gravity: REAL;
BEGIN
	move;	
	cam.x := cx; cam.y := cy; cam.z := cz;
	gravityvector:=Base.mkPT(0,0,1);		
	gravity:=Base.gravity;
	gravityvector:=Base.mulPT(gravityvector,Base.gravity);
	a:=Retina.fward.x*Base.cursordist; b:=Retina.fward.y*Base.cursordist; c:=Retina.fward.z*Base.cursordist;
	d:=Retina.fward.x*0.0021; e:=Retina.fward.y*0.0021;  f:=Retina.fward.z*0.0021; 
	Base.updatecamera(cx,cy,cz,a,b,c,d,e,f);	
	IF avaTF THEN Marsh.drawavatar END;
	GLIDE:=0.99;	
	cvz := cvz*GLIDE+gravityvector.z; 
	cvx := cvx*GLIDE+gravityvector.x; cvy := cvy*GLIDE+gravityvector.y; 
	cvl :=cvl*0.0; cvu := cvu*0.0;
	IF MOUSEDOWN THEN	
		IF GLW.ML IN MB THEN Marsh.draw;
		ELSIF  GLW.MM IN MB THEN Marsh.snipeinto; 
		ELSIF  GLW.MR IN MB THEN Marsh.snipeonto;
		END;	
	END;
	trace; 
	Base.tick
END tick;
 
END Camera;


(*! ************* XLTL AMALGAMATION FOLLOWS *)

TYPE GLWindow=OBJECT(GLW.Window)
VAR
	vertexbuffer, uvbuffer: Uint; (* GL buffers *)
	image: Uint; (* image texture name *)
	programs: ARRAY 13 OF Uint;
	curprogram: Uint;
	splashscreen, fullwindow: BOOLEAN;
	
PROCEDURE &openwincam(w,h: INTEGER);
BEGIN
	Init(w,h, 0,0, FALSE );
	NEW(camera,Retina.W, Retina.H); 
	camera.aperjust(w, h);
	SetTitle("SPASIM");

	SetGameMode(TRUE); 
	SetPrintFPS(TRUE); (* show frame time timing *)
	splashscreen := TRUE;
	
	(* cmdlinerun := TRUE;*)
END openwincam;

(* called when idling *)
PROCEDURE IdleDisplay;
BEGIN
	ReDisplay; (* calls Display proc when idle timer is expired *)
END IdleDisplay;

(* is called by OGLWindow before MainLoop started *)
PROCEDURE OnLoad ;
BEGIN
	
	IF ~InitGL() THEN Close; RETURN END;	
	Display; (* display splash screen *)
	
	NEW(Retina.image);
	Raster.Create(Retina.image,Retina.W,Retina.H,Raster.BGRA8888);
	
	splashscreen := FALSE;
		
	NEW(rand);
	foveasize := 100;
	multicore:=TRUE;
	camrotinertia:=100;
	Base.DTL:=25000;
	Base.DTL2:=2500;
	Base.gravity:=0.000001;
	Base.speed:=0.001;
	Base.maxspeed:=0.0001;
	Base.cursordist:=0.01;
	R1:=100;
	R2:=150;
	Base.worldalive := TRUE;	
	fogdensity:=0.11;
	leftsticky:=10.0;
	upsticky:=10.0;	
	Out.String('*line 1217!*');
	msd:=45;
END OnLoad;

PROCEDURE Reshape(w, h: LONGINT);
BEGIN	
	GL.Viewport(0, 0, w, h);
	centerx:= w DIV 2; centery:= h DIV 2;	
END Reshape;

PROCEDURE Close;
VAR i: LONGINT;
BEGIN
	Base.worldalive:=FALSE;
	Out.String("Spasim Closing.."); Out.Ln;
	
	(* cleanup gl buffers *)
	
	FOR i:=0 TO LEN(programs)-1 DO
		GL.DeleteProgram(programs[i]);
	END;
	
	GL.DisableVertexAttribArray(0);
	GL.DisableVertexAttribArray(1);
	
	GL.DeleteTextures(1, ADDRESSOF(image));
	GL.DeleteBuffers(1, ADDRESSOF(vertexbuffer));
	GL.DeleteBuffers(1, ADDRESSOF(uvbuffer));
	
	Close^;
END Close;
  
PROCEDURE KeyEvent (ucs : LONGINT; flags : SET; keysym : LONGINT);

VAR
	v: Voxel;   
	s: Strings.String;
	c: CHAR;
BEGIN
	IF keysym=Inputs.KsControlL THEN
		chatvoxel:=Marsh.sniprobe(); 
		chatting:=TRUE;
	ELSIF chatting=TRUE THEN
		IF keysym#Inputs.KsControlL THEN 
			chatting:=FALSE
		END;
		Out.String(chatvoxel.chat(CHR(ucs))^)
	ELSE
		CASE CHR(ucs) OF		
			   "s" : camera.forward(-0.51*Base.speed)
			| "w" :camera.forward(0.51*Base.speed) 
			| "a" :camera.rightstrafe(-0.5*Base.speed)	
			| "d" :camera.rightstrafe(0.5*Base.speed)
			| "e": camera.upstrafe(-0.51*Base.speed)
			| "q": camera.upstrafe(0.51*Base.speed)	
			| "n": leftsticky:=leftsticky*1.3; upsticky:=upsticky*1.3;
			| "m": leftsticky:=leftsticky/1.3; upsticky:=upsticky/1.3;
			| "o": GL.TexParameterf(GLC.GL_TEXTURE_2D, GLC.GL_TEXTURE_MAG_FILTER, GLC.GL_NEAREST)
			| "t": GL.TexParameterf(GLC.GL_TEXTURE_2D, GLC.GL_TEXTURE_MAG_FILTER, GLC.GL_LINEAR)
			| "v":Marsh.engrain
			| "c": Marsh.sprout 
			| "x": Marsh.incVN
			| "z": Marsh.decVN		
			| "p":  camera.stop	
			| "1": Marsh.lighten		
			| "2" : Marsh.darken
			| "3" : Base.gravity:= Base.gravity/1.5	
			| "4" : Base.gravity:= 1.5*Base.gravity		
			| "5" : Base.STOPGO
			| "6" : avaTF:=~avaTF
			| "h" : camera.hop	
			| " " :  IF hidecursor THEN HideMousePointer(FALSE) ELSE HideMousePointer(TRUE) END; AVATAR:=~AVATAR;
			| "]": camera.aperture.width := camera.aperture.width * 101/99; camera.aperture.height := camera.aperture.height *101/99;
				(*    Out.String("] pressed"); Out.Ln; *)
			| "[":  camera.aperture.width := camera.aperture.width * 99/101;  camera.aperture.height := camera.aperture.height *99/101;
				(*Out.String("[ pressed"); Out.Ln;*)
			| "9": IF Marsh.cursorsize<999999 THEN Marsh.cursorsize:=Marsh.cursorsize * 2; Base.cursordist:=Base.cursordist/2 END
			| "0": IF Marsh.cursorsize>1 THEN Marsh.cursorsize:=Marsh.cursorsize DIV 2; Base.cursordist:=Base.cursordist*2 END
			| "7": Base.cursordist:=Base.cursordist*1.3
			| "8": Base.cursordist:=Base.cursordist/1.3
			| "l": Marsh.lines:=~Marsh.lines
			| "b": Marsh.showcode;		
			| "f": curprogram := (curprogram +1 ) MOD 13; 
					Out.String("curprogram="); Out.Int(curprogram,0); Out.Ln;			
		ELSE (* use keysm *)
			Out.String("ucs: "); Out.Hex(ucs,4); Out.String("keysym: "); Out.Hex(keysym,4); Out.Ln;
			CASE keysym OF
			| Inputs.KsEscape (*1BH*) : IF CAPTUREMOUSE THEN 
								CAPTUREMOUSE := FALSE;
								PAUSE:=TRUE;
								HideMousePointer(FALSE);
								SetIdleTime(1000);
							ELSE
								(* alive:=FALSE *)
							END;
							(* Out.String("KsEscape.."); Out.Ln;*)
			|	Inputs.KsF1:
					Out.String("F1- Close"); Out.Ln;
					Marsh.engrain; 
					Close();	
					
					
			| Inputs.KsF11: fullwindow:=~fullwindow; SetFullWindow(fullwindow); 
			| Inputs.KsF2: Base.gravity:= -Base.gravity;

			| Inputs.KsControlL: AVATAR:=~AVATAR; 

			(*? KsControlR does not work on LinuxAos  *)
			| Inputs.KsControlR (* Inputs.KsInsert*): Marsh.SNIPEINTO:=~Marsh.SNIPEINTO;
			ELSE
				Out.String("keysym: "); Out.Hex(keysym,4); Out.Ln;
			END;
		END
	END
END KeyEvent;

	PROCEDURE PointerDown(x, y: LONGINT; keys: SET);
	BEGIN
		IF ~CAPTUREMOUSE THEN SetIdleTime(0); HideMousePointer(TRUE); CAPTUREMOUSE:=TRUE;	 END;
		PAUSE:=FALSE;
		MOUSEDOWN:=TRUE;	
		MB := keys;
		IF GLW.ML IN MB THEN Out.String("ML");
		ELSIF  GLW.MM IN MB THEN Out.String("MM");
		ELSIF  GLW.MR IN MB THEN Out.String("MR");
		END;	
	END PointerDown;

		(** called when mouse button up  *)
	PROCEDURE PointerUp(x, y: LONGINT; keys: SET);
	BEGIN
		MOUSEDOWN:=FALSE
	END PointerUp;
		
	PROCEDURE PointerMove (x, y : LONGINT; keys : SET);
	VAR
		up,left: REAL;
		xr,yr: LONGINT;
		temporaljust: REAL;
	BEGIN
			MB := keys;
			temporaljust := msd/GetCurrentFrameMs();
			
			xr := ENTIER((x-centerx)*temporaljust); yr :=ENTIER((y-centery)*temporaljust);
		
		
			IF CAPTUREMOUSE & (ABS(xr)+ABS(yr)>5) THEN
				left:=ABS(xr)*xr;
				up:=-ABS(yr)*yr; 
				camera.up(-up/(60000*leftsticky)); 
				camera.left(left/(30000*leftsticky));
				
				WarpPointer(1000,1000, centerx,centery);
			END
	END PointerMove;
	 
	PROCEDURE WheelMove(dz: LONGINT);
	BEGIN
	IF TRUE  THEN
		IF dz > 0 THEN slowdown; Out.String("slowdown dz="); Out.Int(dz, 0); Out.Ln;
		ELSE speedup; Out.String("speedup dz="); Out.Int(dz, 0); Out.Ln;
		END;
	END;	
	END WheelMove;

	PROCEDURE InitShader(CONST vertexShaderPath, fragmentShaderPath: ARRAY OF CHAR): Uint;
	VAR program: Uint;
		location: Int;
		w, h: REAL;
	BEGIN
		Out.String("Loading Shaders: "); Out.String(vertexShaderPath);
		Out.String(" and "); Out.String(fragmentShaderPath); Out.Ln;
		
		program := GLSL.LoadShadersFromFile(vertexShaderPath, fragmentShaderPath);
		GL.UseProgram(program);

		location := GL.GetUniformLocation(program, "u_image");
		IF location # -1 THEN GL.Uniform1i(location, 0); END;

		location := GL.GetUniformLocation(program, "u_step") ;
		w :=1.0/Retina.W; h := 1.0/ Retina.H;
		IF location # -1 THEN GL.Uniform2f(location, w, h);  END;

		RETURN program;
	END InitShader;

	(* init Vertex Array Objects *)
	PROCEDURE InitVAO();
	VAR
		vertices, texcoords: ARRAY [8] OF Float;
		indices: ARRAY [6] OF Ushort;
		vao:  Uint;
		vertexBufferObjID: ARRAY [3] OF Uint;
		positionLocation, texcoordsLocation: Uint;
	BEGIN
		(* A2 Image origin is top-left, opengl's image left-bottom; so, flip indices in horizontal  *)
		vertices := [-1.0, -1.0, 	1.0, -1.0, 1.0, 1.0, -1.0, 1.0  ];
		texcoords := [0.0, 1.0,  1.0, 1.0,  1.0, 0.0,	0.0, 0.0 ];
		indices := [ 0, 1, 3, 3, 1, 2 ]; 

		positionLocation := 0;
		texcoordsLocation := 1;
				
		GL.GenVertexArrays(1, ADDRESSOF(vao));
		GL.BindVertexArray(vao);

		GL.GenBuffers(3, ADDRESSOF(vertexBufferObjID[0]));

		GL.BindBuffer(GLC.GL_ARRAY_BUFFER, vertexBufferObjID[0]);
		GL.BufferData(GLC.GL_ARRAY_BUFFER, LEN(vertices,0)*SIZEOF(Float), ADDRESSOF(vertices[0]), GLC.GL_STATIC_DRAW);
		GL.VertexAttribPointer(positionLocation, 2, GLC.GL_FLOAT, GLC.GL_FALSE, 0, 0);
		GL.EnableVertexAttribArray(positionLocation);

		GL.BindBuffer(GLC.GL_ARRAY_BUFFER, vertexBufferObjID[1]);
		GL.BufferData(GLC.GL_ARRAY_BUFFER, LEN(texcoords,0)*SIZEOF(Float), ADDRESSOF(texcoords[0]), GLC.GL_STATIC_DRAW);
		GL.VertexAttribPointer(texcoordsLocation, 2, GLC.GL_FLOAT, GLC.GL_FALSE, 0, 0);
		GL.EnableVertexAttribArray(texcoordsLocation);

		GL.BindBuffer(GLC.GL_ELEMENT_ARRAY_BUFFER, vertexBufferObjID[2]);
		GL.BufferData(GLC.GL_ELEMENT_ARRAY_BUFFER, LEN(indices,0)*SIZEOF(Ushort), ADDRESSOF(indices[0]), GLC.GL_STATIC_DRAW);

	END InitVAO;


	PROCEDURE  InitGL(): BOOLEAN;
	BEGIN
	GL.ReadCoreVersion(); (* read default version of opengl *)

	IF ~GL.GL_VERSION_2_0 THEN
		Out.String("Error: your graphic card does not support OpenGL 2.0"); 
		Out.Ln;

	 	RETURN FALSE;
	 END;
         GL.ReadExtensions(); (* read all opengl extension functions *)	
		GL.ReadImplementationProperties;


		GL.ClearColor(0.0, 0.0, 0.0, 0.0);

		(* create texture object for image *)
		GL.GenTextures(1, ADDRESSOF(image));
		GL.BindTexture(GLC.GL_TEXTURE_2D, image); 
		(* These determine how interpolation is made when image scaled down on up *)
		GL.TexParameterf(GLC.GL_TEXTURE_2D, GLC.GL_TEXTURE_MAG_FILTER,  GLC.GL_LINEAR);
		GL.TexParameterf(GLC.GL_TEXTURE_2D, GLC.GL_TEXTURE_MIN_FILTER, GLC.GL_NEAREST);
		GL.TexImage2D(GLC.GL_TEXTURE_2D, 0, GLC.GL_RGBA, Retina.image.width, Retina.image.height, 0, GLC.GL_BGRA, GLC.GL_UNSIGNED_BYTE, Retina.image.adr);
		
		InitVAO();
			(* load shader programs *)
			programs[0] := InitShader("passthroughVS.glsl", "passthroughFS.glsl");
			programs[1] := InitShader("passthroughVS.glsl", "boxBlurFS.glsl");
			programs[2] := InitShader("passthroughVS.glsl", "negativeFS.glsl");
			programs[3] := InitShader("passthroughVS.glsl", "gaussianBlurFS.glsl");
			programs[4] := InitShader("passthroughVS.glsl", "grayscaleFS.glsl");
			programs[5] := InitShader("passthroughVS.glsl", "edgeDetectionFS.glsl");
			programs[6] := InitShader("passthroughVS.glsl", "toonShadingFS.glsl");
			programs[7] := InitShader("passthroughVS.glsl", "vintageFS.glsl");
			programs[8] := InitShader("passthroughVS.glsl", "brightnessFS.glsl");
			programs[9] := InitShader("passthroughVS.glsl", "unsharpMaskFS.glsl");
			programs[10] := InitShader("passthroughVS.glsl", "sharpenFS.glsl");
			programs[11] := InitShader("passthroughVS.glsl", "nightVisionFS.glsl");
			programs[12] := InitShader("weirdVS.glsl", "passthroughFS.glsl");
			curprogram := 0;
			  
		RETURN TRUE;
	END InitGL;

	PROCEDURE Display();
	BEGIN
		IF ~splashscreen THEN	camera.tick; END;
		GL.Clear(GLC.GL_COLOR_BUFFER_BIT + GLC.GL_DEPTH_BUFFER_BIT) ;
		
		GL.TexImage2D(GLC.GL_TEXTURE_2D, 0, GLC.GL_RGBA, Retina.image.width, Retina.image.height,  0, GLC.GL_BGRA, GLC.GL_UNSIGNED_BYTE, Retina.image.adr);
		GL.UseProgram(programs[curprogram]);
			GL.DrawElements(GLC.GL_TRIANGLES, 6, GLC.GL_UNSIGNED_SHORT, 0);
		GL.UseProgram(0);	
		SwapBuffers();	
	END Display;

	(* change detail according to frame speed, called in GLWindow.MainLoop *)
	PROCEDURE GameLogic();
	BEGIN
		IF GetCurrentFrameMs() <msd THEN 
			Retina.moredetail;
		ELSIF GetCurrentFrameMs() >(msd+10) THEN 
			Retina.lessdetail;
		END; 
	END GameLogic;

	BEGIN {ACTIVE}
		MainLoop; 
	END GLWindow;


VAR
	FRAMERATE: REAL;
	rand: Random.Generator;
	wcount: INTEGER;
	frame, tickframe: LONGINT;
	movierecording, movieplaying: BOOLEAN; 
	frtrace, foveate: BOOLEAN;
	foveasize, fovealeft, fovearight, foveadown, foveaup: LONGINT;
	DEATH, wLOOK, PAUSE: BOOLEAN;
	tracetiled,avaTF, capturethemouse: BOOLEAN;
	framecount: LONGINT;
	multicore,filtor,uplock,rollcam,suppressz: BOOLEAN;
	camrotinertia:REAL;
	framedt: REAL;
	pkeys: SET;	
	pointerx, pointerdx, pointery, pointerdy: LONGINT;
	R1,R2: REAL;
	update: LONGINT;
	MLseen, MMseen, MRseen: BOOLEAN;	
	chatting: BOOLEAN;
	chatvoxel: Voxel;
	warpedthemouse: BOOLEAN;	
	
	MB : SET;	(* 0, 1, 2 *)

	MOUSEDOWN, CAPTUREMOUSE, GO,TRAIL,AVATAR,SCULL,METASLASH: BOOLEAN;	
	camera:Camera;
	fogdensity:REAL;
	leftsticky,upsticky: REAL;
	centerx,centery: LONGINT;

	GLIDE:REAL;
		
	msd: REAL;	
	

PROCEDURE angletoray(VAR ray: Base.Ray; theta,phi: REAL);
VAR d: REAL;
BEGIN
	ray.dxyz.x := Math.cos(theta) * Math.cos(phi);
	ray.dxyz.y := Math.sin(theta) * Math.cos(phi);
	ray.dxyz.z := Math.sin(phi);
	d := Math.sqrt(ray.dxyz.x*ray.dxyz.x + ray.dxyz.y* ray.dxyz.y+ray.dxyz.z*ray.dxyz.z);  (* Norma! Liza! Ray! Front and center, oh dark thirty!*)
	ray.dxyz.x := ray.dxyz.x/d;
	ray.dxyz.y := ray.dxyz.y/d;
	ray.dxyz.z := ray.dxyz.z/d; 
END angletoray; 

PROCEDURE carttosph(VAR p: PT; theta, phi: REAL);
BEGIN
	p.x := Math.cos(theta) * Math.cos(phi);
	p.y := Math.sin(theta) * Math.cos(phi);
	p.z := Math.sin(phi);
END carttosph; 

PROCEDURE sphtocart( p: PT; VAR theta, phi: REAL);
VAR
	x,y, z: REAL;
BEGIN
	x := p.x; y := p.y; z := 0;
	Base.normalize(x,y,z);
	theta := XNXLMath.arccos(x);	
	phi := XNXLMath.arccos(1-p.z);
END sphtocart;

PROCEDURE ddray(VAR ray: Base.Ray); 
BEGIN
	ray.ddxyz.x := ray.dxyz.x/10000;
	ray.ddxyz.y := ray.dxyz.y/10000;
	ray.ddxyz.z := ray.dxyz.z/10000; 
END ddray; 

PROCEDURE gray(VAR ray: Ray);
VAR
	gray: REAL;
BEGIN
	gray := (ray.r + ray.g + ray.b)/3;
	ray.r := gray; ray.g := gray; ray.b := gray;
END gray;

PROCEDURE speedup;
BEGIN
	IF Base.speed < 	Base.maxspeed THEN Base.speed := Base.speed * 1.5 END
END speedup;

PROCEDURE slowdown;
BEGIN
	IF Base.speed > 0.00000000001 THEN Base.speed := Base.speed/1.5 END
END slowdown;

PROCEDURE cursorpush;
BEGIN
	Base.cursordist:=Base.cursordist*1.1
END cursorpush;

PROCEDURE cursorpull;
BEGIN
	Base.cursordist:=Base.cursordist*0.9 
END cursorpull;

PROCEDURE vlnext;
BEGIN
	Marsh.incVN;
END vlnext;

PROCEDURE vllast;
BEGIN
	Marsh.decVN;
END vllast;

PROCEDURE cursorsizeplus;
BEGIN
	Marsh.cursorsize:=ENTIER(Marsh.cursorsize/1.5)
END cursorsizeplus;

PROCEDURE cursorsizeminus;
BEGIN
	Marsh.cursorsize:=ENTIER(Marsh.cursorsize*1.5)
END cursorsizeminus;

PROCEDURE Open* ;
VAR w: GLWindow;
BEGIN
	NEW(w, Retina.W*2,Retina.H*2);
(*	Debugging.DisableGC; *)
	Base.STOPGO
END Open;

BEGIN

END Render.

Render.Open ~ 

SystemTools.Free Render ~ 


