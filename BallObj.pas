unit BallObj;

interface

uses Windows, SysUtils, Classes, Graphics, Math;

type
  TBallType = (btEllipse, btRectangle, btBitmap);
              { Charge CPU pour les differents type avec 50 balles
                AMD Athlon 2700+ @2Ghz
                btEllipse   ~= 0..5%
                btRectangle ~= 0..5%
                btBitmap    ~= 40..55%
              }

  TBall = class(TObject)
  private
    fCanvas      : TCanvas;    // Canvas a assigner a partir d'une Paintbox ou Tbitmap.
    fMoveRect    : TRect;      // Zone de deplacement, prendre PaintBox.ClientRect par exemple

    fBallType    : TBallType;  // type du dessin de la balle
    fBitmap      : Tbitmap;    // Bitmap de la balle

    fCoord       : TPoint;     // Coordoonées au sommet haut-gauche de la balle
    fWidth       : integer;    // Taille en X de la balle
    fHeight      : integer;    // Taille en Y de la balle

    fSpeed       : single;     // Vitesse de deplacement -8..-4  4..8
    fDirection   : single;     // Direction en degrés -80..-20  20..80

    fColor       : integer;    // Couleur de la balle

    fEnabled     : boolean;    // True si Canvas assigné sinon False

    fBckPen      : TPen;       // Sauvegarde du Pen du canvas
    fBckBrush    : TBrush;     // Sauvegarde du Brush du canvas

    _SpCosMul    : integer;    // arrondis de fSpeed * Cos(fDirection)
    _SpSinMul    : integer;    // arrondis de fSpeed * Sin(fDirection)

    procedure SetEnabled(val : boolean);
    function GetEnabled : boolean;
    procedure SetSingle(index : integer; val : single);
    procedure SetBitmap(val : TBitmap);

  protected
    procedure ComputeSPD; virtual;    // Calcul direction vitesse
    procedure SwapSpeed; virtual;     // Inversion de vitesse
    procedure SwapDirection; virtual; // Inversion de direction
    procedure Move; virtual;          // Calcul du deplacement
    procedure CheckOut; virtual;      // Verification des limites de deplacement
  public
    constructor Create(ACanvas : TCanvas; AMoveRect : TRect);
    destructor Destroy; override;

    property Canvas      : TCanvas read fCanvas      write fCanvas;
    property MoveRect    : TRect   read fMoveRect    write fMoveRect;

    property Speed       : single  index 0 read fSpeed       write SetSingle;
    property Direction   : single  index 1 read fDirection   write SetSingle;

    property Coord       : TPoint  read fCoord       write fCoord;
    property Width       : integer read fWidth       write fWidth default 25;
    property Height      : integer read fHeight      write fHeight default 25;

    property Color       : integer read fColor       write fColor;

    property Enabled     : boolean read GetEnabled   write SetEnabled default true;

    property BallType    : TBallType read fBallType write fBallType default btEllipse;

    property BallBitmap  : TBitmap   read fBitmap   write SetBitmap;

    procedure Progress;  // Procedure a appeler pour effectuer le deplacement de la balle
    procedure Draw;      // Procedure a appeler pour dessiner la balle sur le canvas

    function GetRandomSpeed(const RandSign : boolean = false) : single;
      // Genere une vitesse aleatoire comprise dans l'interval -8..-4 4..8
      // RandSign permet de gerrer la generation aleatoire du signe (RandSign = true)

    function GetRandomDirection(const RandSign : boolean = false) : single;
      // Genere une direction aleatoire comprise dans l'interval -80°..-20° 20°..80°
      // RandSign permet de gerrer la generation aleatoire du signe (RandSign = true)

    function GetRandomColor : integer;
      // Genere une couleur BGR aleatoire dans l'interval 64..196 pour chaque byte couleur
  end;



implementation

function Middle(const ALeftOrTop, ARightOrBottom : integer) : integer;
begin
  {
   Calcul du millieu d'une droite.
   shr 1 = div 2
  }
  result := (ARightOrBottom-ALeftOrTop) shr 1;
end;


{ TBALL CLASS }

constructor TBall.Create(ACanvas : TCanvas; AMoveRect : TRect);
begin
  {
   Appel du constructeur ancetre de TObject
  }
  inherited Create;

  {
   Assignation du canvas et du rectangle de zone de deplacement
  }
  fCanvas      := ACanvas;
  fMoveRect    := AMoveRect;

  {
   Précalcul de la position de la balle, par defaut au millieu de AMoveRect
  }
  fCoord       := point(Middle(AMoveRect.Left,AMoveRect.Right),Middle(AMoveRect.Top,AMoveRect.Bottom));

  {
   Taille par defaut de la balle
  }
  fWidth       := 25;
  fHeight      := 25;

  {
   Generation d'une direction et vitesse aleatoire
  }
  Direction    := GetRandomDirection(true);
  Speed        := GetRandomSpeed(True);

  {
   Calcul Vitesse/Direction
  }
  ComputeSPD;

  {
   Generation d'une couleur aleatoire
  }
  fColor       := GetRandomColor;

  {
   Creation du bitmap
  }
  fBitmap      := TBitmap.Create;

  {
   Creation des objets de sauvegarde pour le canvas
  }
  fBckPen      := TPen.Create;
  fBckBrush    := TBrush.Create;

  {
   Verification de l'assignation de fCanvas pour eviter les ACanvas = nil
  }
  fEnabled     := Assigned(fCanvas);
end;

destructor TBall.Destroy;
begin
  {
   Liberation des objets de sauvegarde pour le canvas
  }
  fBckPen.Free;
  fBckBrush.Free;

  {
   Liberation du bitmap
  }
  fBitmap.Free;

  {
   Appel du destructeur de l'ancetre TObject
  }
  inherited destroy;
end;



procedure TBall.SetEnabled(val : boolean);
begin
  {
   On verifie l'assignation de fCanvas quand le developeur
   tente de modifier la propriété Enabled.
  }
  fEnabled := assigned(fCanvas) and val;
end;

function TBall.GetEnabled : boolean;
begin
  {
   On renvois un resultat en fonction de l'assignation de fCanvas
  }
  fEnabled := assigned(fCanvas);
  result   := fEnabled;
end;

procedure TBall.SetSingle(index : integer; val : single);
begin
  {
   fDirection est convertis en radian
   enfin, il faut appeler ComputeSPD pour recalculer les parametres
   vitesse/direction
  }
  case index of
    0 : fSpeed     := val;
    1 : fDirection := DegToRad(val);
  end;

  ComputeSPD;
end;

procedure TBall.SetBitmap(val : TBitmap);
begin
  {
   Assignation au bitmap
  }
  fBitmap.Assign(val);
end;

procedure TBall.ComputeSPD;
var ST,CT : extended;
begin
  {
   Rien de bien compliqué.
   ComputeSPD est placée de maniere strategique dans les methodes notament :
      -creation de l'objet
      -changement des valeurs Vitesse/Direction.
      -inversion Vitesse/Direction.
   On l'appelle donc le moins souvent possible, ce qui augmente les performances
   car Round, Sin, Cos et multiplication demande beaucoups de cycles CPU.
   Pour Sin et Cos on prefere l'utilisation de SinCos qui vas beaucoup plus vite.
  }
  SinCos(fDirection,ST,CT);
  _SpCosMul := round(fSpeed * CT);
  _SpSinMul := round(fSpeed * ST);
end;

procedure TBall.SwapSpeed;
var NewSpeed : extended;
begin
  {
   Inversion vitesse.
   On genere d'abord une vitesse aleatoire non signée,
   puis on inverse selon le signe de fSpeed,
   enfin on recalcul les parametres Vitesse/Direction
  }
  NewSpeed := GetRandomSpeed;
  if fSpeed >= 0 then
     fSpeed := -NewSpeed
  else
     fSpeed := NewSpeed;

  ComputeSPD;
end;

procedure TBall.SwapDirection;
var NewAngle : extended;
begin
  {
   Inversion direction.
   On genere d'abord une direction aleatoire non signée,
   puis on inverse selon le signe de fSpeed,
   enfin on recalcul les parametres Vitesse/Direction
  }
  NewAngle := DegToRad(GetRandomDirection);
  if fDirection >= 0 then
     fDirection := -NewAngle
  else
     fDirection := NewAngle;

  ComputeSPD;
end;



procedure TBall.Move;
begin
  {
   Calcul de la position de la balle.
   On reduit a sa plus simple expression la formule de deplacement.
   grace a ComputeSPD, le calcul se resume a 2 additions par passe.
  }
  fCoord.x := fCoord.x + _SpCosMul;
  fCoord.Y := fCoord.y + _SpSinMul;
end;

procedure TBall.CheckOut;
begin
  {
   Verification du deplacement a l'interrieur de la zone fMoveRect.
   Si on atteint la limite haute ou basse on n'inverse que la direction.
   Si on atteint la limite droite et gauche on inverse la direction et la vitesse.
   A chaque condition on fixe la position selon la limite atteinte pour eviter les debordements.
  }
  if (fCoord.Y+Height) >= fMoveRect.Bottom then begin
     fCoord.Y := fMoveRect.Bottom-fHeight;
     SwapDirection;
  end;

  if (fCoord.X+Width) >= fMoveRect.Right then begin
     fCoord.X := fMoveRect.Right-fWidth;
     SwapSpeed;
     SwapDirection;
  end;

  if fCoord.Y <= fMoveRect.Top then begin
     fCoord.Y := fMoveRect.Top;
     SwapDirection;
  end;

  if fCoord.X <= fMoveRect.Left then begin
     fCoord.X := fMoveRect.Left;
     SwapSpeed;
     SwapDirection;
  end;
end;

procedure TBall.Draw;
begin
  {
   Dessin de la balle sur le canvas.
   Si la balle est invactive (voulus ou fCanvas non assigné) on sort de la methode.
   grace a Exit.
  }
  if not fEnabled then exit;

  with fCanvas do begin
       // sauvegarde Pen et Brush
       fBckPen.Assign(Pen);
       fBckBrush.Assign(Brush);

       // dessin de la balle
       case fBallType of
         btEllipse : begin
           Pen.Color   := fColor;
           Brush.Color := fColor;
           Ellipse(fCoord.X,fCoord.Y,fCoord.X+fWidth,fCoord.Y+fHeight);
         end;
         btRectangle : begin
           Pen.Color   := fColor;
           Brush.Color := fColor;
           Rectangle(fCoord.X,fCoord.Y,fCoord.X+fWidth,fCoord.Y+fHeight);
         end;
         btBitmap : begin
           Draw(fCoord.X,fCoord.Y,fBitmap);
         end;
       end;

       // restauration Pen et Brush
       Pen.Assign(fBckPen);
       Brush.Assign(fBckBrush);
  end;
end;

procedure TBall.Progress;
begin
  {
   Animation de la balle.

   Appelez Progress dans l'evenement OnTimer d'un timer de votre fiche pour effectuer
   un deplacement automatique. Reglez ce timer a 25ms pour obtenir un mouvement fluide.

   Si la balle est inactive (voulus ou fCanvas non assigné) on sort de la methode.
   On appel d'abord Move pour effectuer le deplacement.
   On appel ensuite CheckOut pour verifier que le deplacement est bien effectué dans la zone
   fMoveRect, au quel cas, CheckOut fixerat une position correcte a la balle.
  }
  if not fEnabled then exit;
  Move;
  CheckOut;
end;

function TBall.GetRandomSpeed(const RandSign : boolean = false) : single;
begin
  {
   Genere une vitesse aleatoire signée ou non.

   On genere d'abord une vitesse.
   Puis si RandSign = true on genere un signe qui serat negatif selon la valeur
   obtenue par Random(100), si cette valeur est presente dans l'un des interval
   definit dans le switch, on renvois -result.
  }
  result := RandomRange(4000,8001)/1000;

  if RandSign then
     case Random(100) of
       10..19,30..39,50..59,70..79,90..99 : result := -result;
     end;
end;

function TBall.GetRandomDirection(const RandSign : boolean = false) : single;
begin
  {
   Genere une direction aleatoire signée ou non.

   On genere d'abord une direction.
   Puis si RandSign = true on genere un signe qui serat negatif selon la valeur
   obtenue par Random(100), si cette valeur est presente dans l'un des interval
   definit dans le switch, on renvois -result.
  }
  result := RandomRange(20000,80001)/1000;
  if RandSign then
     case Random(100) of
       10..19,30..39,50..59,70..79,90..99 : result := -result;
     end;
end;

function TBall.GetRandomColor : integer;
var R,G,B : byte;
begin
  {
   Genere une couleur aleatoire.
   On genere chaque octet un a un, puis on les renvois dans un entier 32bits
   en decalant chaque octets de couleurs grace a SHL (voir l'aide delphi).
   le resultat obtenus est celuici : 00 BB GG RR
  }
  R := RandomRange(64,197);
  G := RandomRange(64,197);
  B := RandomRange(64,197);
  result := (B shl 16) + (G shl 8) + R;
end;


end.
 