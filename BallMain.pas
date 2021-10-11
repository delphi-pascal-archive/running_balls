unit BallMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    PaintBox1: TPaintBox;
    ComboBox1: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}
{utilisation de la PNGLIB}
{.$DEFINE USEPNG}

{ on utilise notre unité BallObj }
uses BallObj;

{
 On declare un tableau de TBall, qui nous permet de créer N balle sur la scene.
 Par defaut on en genere 50, mais 1000 ou plus encore peut passé sur la plupart
 des processeurs de plus d'1 Ghz (AMD) ou 2Ghz (Intel).
}
var Balls  : array[0..19] of TBall; { attention en mode Bitmap la charge CPU est plus importante }
    AppDir : string;
    BMP    : TBitmap;

{ ONCREATE - TForm1 }
procedure TForm1.FormCreate(Sender: TObject);
var n : integer;
begin
  // on initialise le generateur de nombres aleatoire
  Randomize;

  // on fixe DoubleBuffered pour eviter les clignotements du dessin.
  DoubleBuffered := true;

  // on recupere le repertoire de l'application
  AppDir := ExtractFilePath(Application.ExeName);

  {
    On crée nos balles contenues dans le tableau Balls.
    High(Balls) permet de ne pas a avoir a modifier le code si on modifie la
    profondeur du tableau.
    On assigne le canvas de paintbox1 et sa zone client
  }
  { on charge le sprite de la balle }
  BMP := TBitmap.Create;
  BMP.LoadFromFile(AppDir+'ball.bmp');

  for n := 0 to high(Balls) do begin
      Balls[n] := TBall.Create(PaintBox1.Canvas, PaintBox1.ClientRect);
      with Balls[n] do begin
         { on parametre le sprite }
         BallType   := btBitmap;
         BallBitmap := BMP;
         BallBitmap.TransparentColor := $FFDDAA;
         BallBitmap.Transparent      := true;
         Width      := BallBitmap.Width;
         Height     := BallBitmap.Height;
      end;
  end;
end;


{ ONKEYDOWN - TForm1 }
procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
begin
  // si on appuis sur Espace, on active ou non le timer
  if key = vk_space then
     timer1.Enabled := not timer1.Enabled; // <-- ceci est un inverseur logique
     {
      principe de l'inverseur logique
       NOT TRUE  = FALSE
       NOT FALSE = TRUE
     }
end;


{ ONTIMER - Timer1 }
procedure TForm1.Timer1Timer(Sender: TObject);
var n : integer;
begin
  // On appel la methode progress de tout les objets TBall du tableau Balls
  for n := 0 to high(Balls) do
      Balls[n].Progress;
  // On appel la methode refresh de PaintBox1 pour declancher son evenement OnPaint
  PaintBox1.Refresh;
end;


{ ONPAINT - PaintBox1 }
procedure TForm1.PaintBox1Paint(Sender: TObject);
var n : integer;
begin
  // On efface le canvas
  with PaintBox1 do begin
       Canvas.Brush.Color := clWhite;
       Canvas.FillRect(ClientRect);
  end;
  // On dessine toutes les balles du tableau Balls
  for n := 0 to high(Balls) do
      Balls[n].Draw;
end;

{ ONRESIZE - TForm1 }
procedure TForm1.FormResize(Sender: TObject);
var n : integer;
begin
  {
   Si on redimensionne la fiche, on transmet a tout les objets TBall
   la nouvelle taille de la zone client de PaintBox1
  }
  for n := 0 to high(balls) do
      Balls[n].MoveRect := PaintBox1.ClientRect;
end;

{ ONDESTROY - TForm1 }
procedure TForm1.FormDestroy(Sender: TObject);
var n : integer;
begin
  // on libere le sprite
  BMP.Free;

  // On libere tout les objets TBall du tableau Balls.
  for n := 0 to high(balls) do
      Balls[n].Free;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
var n : integer;
begin
  {
   Quand on change la selection de la combobox, on transtype
   l'index de l'item selection en TBallType.
   0 = btEllipse
   1 = btRectangle
   2 = btBitmap
  }
  for n := 0 to high(balls) do
      Balls[n].BallType := TBallType(ComboBox1.ItemIndex);
end;

end.
