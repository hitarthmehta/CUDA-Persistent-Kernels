// Hitarth Mehta
// University of Florida
// UFID - 1195 3926


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "image.h"

image* loadImage(char * name)
{
	FILE* fp;
	image * temp;
	int i, j, h, w, v, maxV;
	char inp[10] = "#";
	fp = fopen(name, "r");
	fscanf(fp, " %s ", inp);
	if (!strcmp(inp, PBM))
	{
		fscanf(fp, " %s ", inp);
		w = strtol(inp, NULL, 10);
		fscanf(fp, " %s ", inp);
		h = strtol(inp, NULL, 10);
		strcpy(inp, PBM);
		temp = createImage(name, inp, h, w, 1);
		for (i = 0; i < temp->h; i++)
		{
			for (j = 0; j < temp->w; j++)
			{

				fscanf(fp, " %d ", &v);
				setPixelBW(temp, i, j, v);
			}
		}
		strcpy(temp->format, PBM);
		temp->maxV = 1;
		fclose(fp);
		return temp;
	}
	else if (!strcmp(inp, PGM))
	{
		fscanf(fp, " %s ", inp);
		w = strtol(inp, NULL, 10);
		fscanf(fp, " %s ", inp);
		h = strtol(inp, NULL, 10);
		fscanf(fp, " %s ", inp);
		maxV = strtol(inp, NULL, 10);
		strcpy(inp, PGM);
		temp = createImage(name, inp, h, w, maxV);
		for (i = 0; i < temp->h; i++)
		{
			for (j = 0; j < temp->w; j++)
			{
				fscanf(fp, " %d ", &v);
				setPixelBW(temp, i, j, v);
			}
		}
		strcpy(temp->format, PGM);
		fclose(fp);
		return temp;
	}
	else if (!strcmp(inp, PPM1))
	{
		fscanf(fp, " %s ", inp);
		w = strtol(inp, NULL, 10);
		fscanf(fp, " %s ", inp);
		h = strtol(inp, NULL, 10);
		fscanf(fp, " %s ", inp);
		maxV = strtol(inp, NULL, 10);
		strcpy(inp, PPM1);
		temp = createImage(name, inp, h, w, maxV);
		for (i = 0; i < temp->h; i++)
		for (j = 0; j < temp->w; j++)
		{
			fscanf(fp, " %d ", &v);
			setPixelR(temp, i, j, v);
			fscanf(fp, " %d ", &v);
			setPixelG(temp, i, j, v);
			fscanf(fp, " %d ", &v);
			setPixelB(temp, i, j, v);
		}
		strcpy(temp->format, PPM1);
		fclose(fp);
		return temp;
	}
	else
	{
		printf("FATAL: Unknown file format\n");
		fclose(fp);
		return NULL;
	}
}
image* createImage(char * name, char * format, int h, int w, int maxV)
{
	image * temp = (image*)malloc(sizeof(image));
	strcpy(temp->format, format);
	temp->h = h;
	temp->w = w;
	strcpy(temp->name, name);
	int pixelC;
	temp->Vpp = getNumPixels(format);
	temp->data = (int *)malloc(h*w*temp->Vpp*sizeof(int));
	temp->maxV = maxV;
	return temp;
}
int deleteImage(image* temp)
{
	free(temp->data);
	free(temp);
	return 1;
}

int saveImage(image* temp)
{
	int i, j;
	FILE * fp;
	fp = fopen(temp->name, "w");
	fprintf(fp, "%s\n", temp->format);
	fprintf(fp, "%d %d\n", temp->w, temp->h);
	if (!strcmp(temp->format, PPM1) || !strcmp(temp->format, PGM))
		fprintf(fp, "%d\n", temp->maxV);
	if (!strcmp(temp->format, PBM) || !strcmp(temp->format, PGM))
	{
		for (i = 0; i < temp->h; i++)
		{
			for (j = 0; j < temp->w; j++)
				fprintf(fp, "%d ", getPixelBW(temp, i, j));
			fprintf(fp, "\n");
		}
	}
	else if (!strcmp(temp->format, PPM1))
	{
		for (i = 0; i < temp->h; i++)
		{
			for (j = 0; j < temp->w; j++)
			{
				fprintf(fp, "%d ", getPixelR(temp, i, j));
				fprintf(fp, "%d ", getPixelG(temp, i, j));
				fprintf(fp, "%d ", getPixelB(temp, i, j));
			}
			fprintf(fp, "\n");
		}
	}
	fclose(fp);
	return 1;
}

void displayImage(image * temp)
{
	int i, j;
	printf("%s\n", temp->name);
	printf("%s\n", temp->format);
	printf("%d %d\n", temp->w, temp->h);
	if (!strcmp(temp->format, PPM1) || !strcmp(temp->format, PGM))
		printf("%d\n", temp->maxV);
	if (!strcmp(temp->format, PBM) || !strcmp(temp->format, PGM))
	{
		//printf("chu\n");
		for (i = 0; i < temp->h; i++)
		{
			for (j = 0; j < temp->w; j++)
				printf("%d\t", getPixelBW(temp, i, j));
			printf("\n");
		}
	}
	else if (!strcmp(temp->format, PPM1))
	{
		for (i = 0; i < temp->h; i++)
		{
			for (j = 0; j < temp->w; j++)
			{
				printf("%d ", getPixelR(temp, i, j));
				printf("%d ", getPixelG(temp, i, j));
				printf("%d ", getPixelB(temp, i, j));
			}
			printf("\n");
		}
	}
}

static int getNumPixels(char * format)
{
	if (!strcmp(format, PBM))
		return 1;
	if (!strcmp(format, PGM))
		return 1;
	if (!strcmp(format, PPM1))
		return 3;
}

int getPixelR(image * A, int x, int  y)
{
	return A->data[x*A->w * 3 + y * 3 + RED];
}

int getPixelG(image * A, int x, int y)
{
	return A->data[x*A->w * 3 + y * 3 + GREEN];
}

int getPixelB(image *A, int x, int y)
{
	return (A->data[x*A->w * 3 + y * 3 + BLUE]);
}

int getPixelBW(image *A, int x, int y)
{
	return (A->data[x*A->w + y]);
}

void setPixelR(image *A, int x, int y, int val)
{
	(A)->data[x*A->w * 3 + y * 3 + RED] = val;
}

void setPixelG(image *A, int x, int y, int val)
{
	(A)->data[x*A->w * 3 + y * 3 + GREEN] = val;
}

void setPixelB(image *A, int x, int y, int val)
{
	(A)->data[x*A->w * 3 + y * 3 + BLUE] = val;
}

void setPixelBW(image *A, int x, int y, int val)
{
	(A)->data[x*((A)->w) + y] = val;
}

