MODULE WMGLDemo; (** AUTHOR "fnecati"; PURPOSE "opengl demo: uses simple primitives, quad and a cube"; *)

IMPORT
	WMRectangles, WMGraphics, Strings, Kernel,
	WM := WMWindowManager,  WMMessages, WMDialogs,
	GL := OpenGL, GLC := OpenGLConst, GLU, WMGL := WMGLWindow;

CONST waittime = 50;
TYPE
	KillerMsg = OBJECT
	END KillerMsg;

	GLWindow* =  OBJECT(WMGL.Window)
	VAR
		 timer: Kernel.MilliTimer;
		alive, animated: BOOLEAN;
		eyeposz: LONGREAL;
		anglez: REAL;

		PROCEDURE &New(w, h: LONGINT);
		BEGIN

			Init(w, h, TRUE); (* use alpha, for 32bpp img *)
			WM.DefaultAddWindow(SELF);

			SetTitle(Strings.NewString("WMGLDemo: Cube"));

			animated := FALSE;
			anglez := 30.0;
			eyeposz := 10.0;

			Reshape(w, h);
			UpdateImage;

			alive := TRUE;
		END New;

		PROCEDURE KeyEvent (ucs: LONGINT; flags: SET; keysym: LONGINT);
		BEGIN

		CASE CHR(ucs) OF
			"a", "A": animated := ~ animated;
			| "-" : anglez := anglez - 5.0; UpdateImage;
			| "+" : anglez := anglez + 5.0; UpdateImage;
			| "s": SaveImage;
			| "q" : Close;
		ELSE

		END;
		END KeyEvent;

		PROCEDURE WheelMove*(dz : LONGINT);
		BEGIN
			eyeposz := eyeposz + dz;
			IF eyeposz < 0 THEN eyeposz:=0.0; END;
			IF eyeposz > 99 THEN eyeposz:=99; END;
			Reshape(GetWidth(), GetHeight());
			UpdateImage;
		END WheelMove;

		PROCEDURE Handle(VAR m: WMMessages.Message);
		BEGIN
			IF (m.msgType = WMMessages.MsgExt) & (m.ext # NIL) & (m.ext IS KillerMsg) THEN
				Close;
			ELSE Handle^(m)
			END
		END Handle;

		PROCEDURE Close*;
		BEGIN {EXCLUSIVE}
			alive := FALSE;
			Close^;
		END Close;

		PROCEDURE UpdateImage;
		BEGIN
			MakeCurrent();
			GL.Clear(GLC.GL_COLOR_BUFFER_BIT + GLC.GL_DEPTH_BUFFER_BIT);
				DrawAQuad();
				Cube();
			SwapGLBuffer();
			DeActivate();
			Swap();
			Invalidate(WMRectangles.MakeRect(0, 0, GetWidth(), GetHeight()));
		END UpdateImage;

		PROCEDURE SaveImage;
		VAR res: LONGINT;
			fname: ARRAY 128 OF CHAR;
		BEGIN

		fname:="mywmgltest.bmp";
		IF WMDialogs.QueryString(" Save File name: ",fname)=WMDialogs.ResOk THEN
				WMGraphics.StoreImage(img, fname,res);
		END;

		END SaveImage;

PROCEDURE Reshape(w, h: LONGINT);

BEGIN

 MakeCurrent();
  GL.Viewport(0, 0, w, h);
  GL.ClearColor(0.3, 0.3, 0.0, 1.0);
  GL.Enable(GLC.GL_DEPTH_TEST);


 GL.MatrixMode(GLC.GL_PROJECTION);
 GL.LoadIdentity();
 GLU.Perspective(45, 1, 0.1, 100);

 GL.MatrixMode(GLC.GL_MODELVIEW);
 GL.LoadIdentity();
 GLU.LookAt(0.0, 0.0, eyeposz, 0., 0., 0., 0., 1., 0.);

DeActivate;
END Reshape;

PROCEDURE DrawAQuad();
BEGIN
 GL.PushMatrix();

	GL.Rotatef(anglez, 0.0, 0.0, 1.0);

 GL.Begin(GLC.GL_QUADS);
 GL.Color3f(1., 0., 0.); GL.Vertex3f(-0.75, -0.75, 1.);
 GL.Color3f(0., 1., 0.); GL.Vertex3f( 0.75, -0.75, 1.);
 GL.Color3f(0., 0., 1.); GL.Vertex3f( 0.75,  0.75, 1.);
 GL.Color3f(1., 1., 0.); GL.Vertex3f(-0.75,  0.75, 1.);
 GL.End();

 GL.PopMatrix();

END DrawAQuad;

PROCEDURE  Cube*;
BEGIN

GL.PushMatrix();

	GL.Rotatef(anglez, 1.0, 1.0, 0.0);


GL.Begin(GLC.GL_POLYGON); (* top face oriented toward y *)
	GL.Color3f(0.0,0.0,1.0);
	GL.Vertex3f(-1.0, 1.0, 1.0);
	GL.Vertex3f(1.0, 1.0, 1.0);
	GL.Vertex3f(1.0, 1.0, -1.0);
	GL.Vertex3f(-1.0, 1.0, -1.0);
GL.End();

GL.Begin(GLC.GL_POLYGON); (* back face oriented toward -z *)
	GL.Color3f(0.0,1.0,0.0);
	GL.Vertex3f(-1.0, 1.0, -1.0);
	GL.Vertex3f(1.0, 1.0, -1.0);
	GL.Vertex3f(1.0, -1.0, -1.0);
	GL.Vertex3f(-1.0, -1.0, -1.0);
GL.End();

GL.Begin(GLC.GL_POLYGON); (* right face oriented toward x *)
	GL.Color3f(1.0,0.0,0.0);
	GL.Vertex3f(1.0, 1.0, 1.0);
	GL.Vertex3f(1.0, -1.0, 1.0);
	GL.Vertex3f(1.0, -1.0, -1.0);
	GL.Vertex3f(1.0, 1.0, -1.0);
GL.End();

GL.Begin(GLC.GL_POLYGON); (* left face oriented toward -x *)
	GL.Color3f(1.0,0.0,0.0);
	GL.Vertex3f(-1.0, -1.0, 1.0);
	GL.Vertex3f(-1.0, 1.0, 1.0);
	GL.Vertex3f(-1.0, 1.0, -1.0);
	GL.Vertex3f(-1.0, -1.0, -1.0);
GL.End();

GL.Begin(GLC.GL_POLYGON); (* bottom face oriented toward -y *)
	GL.Color3f(0.0,0.0,1.0);
	GL.Vertex3f(-1.0, -1.0, 1.0);
	GL.Vertex3f(-1.0, -1.0, -1.0);
	GL.Vertex3f(1.0, -1.0, -1.0);
	GL.Vertex3f(1.0, -1.0, 1.0);
GL.End();

GL.Begin(GLC.GL_POLYGON); (* front face oriented toward z*)
	GL.Color3f(0.0,1.0,0.0);
	GL.Vertex3f(1.0, 1.0, 1.0);
	GL.Vertex3f(-1.0, 1.0, 1.0);
	GL.Vertex3f(-1.0, -1.0, 1.0);
	GL.Vertex3f(1.0, -1.0, 1.0);
GL.End();

GL.PopMatrix;
END Cube;

BEGIN {ACTIVE}

	Kernel.SetTimer(timer, waittime);
	WHILE alive DO
		IF animated THEN
			 IF Kernel.Expired(timer) THEN
			 	 UpdateImage();
 			 	 anglez := anglez + 5;
				Kernel.SetTimer(timer, waittime);
			END;
		END;
	END;
END GLWindow;

PROCEDURE Open*;
VAR
	window: GLWindow;
BEGIN
	NEW(window, 256, 256);
END Open;

BEGIN

END WMGLDemo.

SystemTools.Free  WMGLDemo  WMGLWindow~ ~

WMGLDemo.Open ~
