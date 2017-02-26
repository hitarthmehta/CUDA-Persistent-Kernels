// Hitarth Mehta
// University of Florida
// UFID - 1195 3926


#define PBM    "P1"
#define PGM    "P2" 
#define PPM1   "P3"
#define RED    0
#define GREEN  1
#define BLUE   2

typedef struct image
{
	int *data;
	int h;
	int w;
	char format[4];
	char name[30];
	int maxV;
	int Vpp;
} image;

image* loadImage(char *);
image* createImage(char *, char *, int, int, int);
int saveImage(image*);
static int getNumPixels(char * format);
int deleteImage(image *);
void displayImage(image * temp);
int getPixelR(image * A, int x, int  y);
int getPixelG(image * A, int x, int  y);
int getPixelB(image * A, int x, int  y);
int getPixelBW(image * A, int x, int  y);
void setPixelR(image *A, int x, int y, int val);
void setPixelG(image *A, int x, int y, int val);
void setPixelB(image *A, int x, int y, int val);
void setPixelBW(image *A, int x, int y, int val);
