#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <time.h>
#include <cuda.h>
#include <string.h>
#include "image.h"

#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#define DEBUG

#define BLOCKSIZE 960
#define WIDTH 1920
#define HEIGHT 1080

#define BufferNum 2
#define StreamNum 3

#define VALID   1
#define INVALID 0

typedef struct rowFlag
{
  unsigned short flag;
  int row_data[WIDTH];
}rowFlag;

cudaStream_t stream[StreamNum];
volatile int* done1;
volatile int* done2;
volatile int* processDone;

cudaError_t checkCuda(cudaError_t result)
{
    if(result != cudaSuccess)
    {
        fprintf(stderr,"CUDA Runtime Error: %s\n",cudaGetErrorString(result));
    }
return result;
}

void computeCPU(int * src, int * des, int size)
{
    int i;
    for(i = 0; i < size; i++)
    {
          des[i] = src[i] + 155;
    }
}
  
int verifyResults(int * d_result, int* cpu_result, int size)
{
  int i, er = 1;
  for (i = 0; i < size; i++)
  {
    if (d_result[i] != cpu_result[i])
    {
      er = 0;
      break;
    }
  }
  return er;
}


void printArray(int * a, int size)
{
  int i;
  for (i = 0; i < size; i++)
    printf("i: %d val: %d\n", i, a[i]);
}


void initArray(int * a, int size)
{
  int i;
  for (i = 0; i < size; i++)
    a[i] = 0;
}

__global__ void
ComputeKernel(struct rowFlag *devInPtr,int *devOutPtr,volatile int *processDone,volatile int * done1,volatile int * done2)
{
  // poll on received flag
  // if it is 1, then the previous row is received and process on the row
  // copy that row in output buffer and set done (mapped memory)
  int id1 = blockIdx.x * blockDim.x + threadIdx.x;
  int id2 = id1 + blockDim.x;
  
  unsigned short receivedFlag1,receivedFlag2;
  
  while(*processDone != 1)
  {
      receivedFlag1 = devInPtr[1].flag;
      receivedFlag2 = devInPtr[0].flag;
           
      if(receivedFlag1 == 1)
      {
          devOutPtr[(0 * WIDTH) + id1] = devInPtr[0].row_data[id1] + 155;
          devOutPtr[(0 * WIDTH) + id2] = devInPtr[0].row_data[id2] + 155;
          __syncthreads();
          if(id1 == 0)
          {  
            *done1 = VALID;
            receivedFlag1 = INVALID;
          }  
      }
      
      // set the received flag zero
      

      if(receivedFlag2 == 1 )
      {
          devOutPtr[(1 * WIDTH) + id1] = devInPtr[1].row_data[id1] + 155;
          devOutPtr[(1 * WIDTH) + id2] = devInPtr[1].row_data[id2] + 155;
          __syncthreads();
      
          // set the received flag zero
          if(id1 == 0)
          {  
            *done2 = VALID;
            receivedFlag2 = INVALID;
          }
      }
      
  }
}

__global__ void
StopKernel(volatile int *d_processDone)
{
    *d_processDone = 1;
}


int main()
{
//send the row with received flag of previous row
//poll on the received flag on GPU
//As soon as the received flag is 1,process the image and put it in another buffer and send back to CPU
//On CPU,set the done flag which is mapped memory,
  image *input,*output;
  int *h_a,*h_b,*cpu_b;
  int didIsendRow1=0,didIsendRow2=0;
  int numRowR=0,numRowS=0;
  int /**d_a,*/*d_b;
  rowFlag *d_a;
  int i,j;
  
  int rowSize = WIDTH;
  int imageSize = WIDTH * HEIGHT;
  int bufferSize = BufferNum * WIDTH;
  size_t rowByteSize = rowSize * sizeof(int);
  size_t imageByteSize = imageSize * sizeof(int);
  size_t bufferByteSize = bufferSize * sizeof(int);
  
  for(i = 0; i < StreamNum; i++)
    {
        checkCuda(cudaStreamCreateWithFlags(&stream[i],cudaStreamNonBlocking));
    }
  
  checkCuda(cudaMallocHost((void**)&h_a,imageByteSize));
  checkCuda(cudaMallocHost((void**)&h_b,imageByteSize));
  cpu_b = (int*)malloc(imageByteSize);
  
  checkCuda(cudaMalloc((void**)&d_a,BufferNum * sizeof(rowFlag)));
  checkCuda(cudaMalloc((void**)&d_b,bufferByteSize));
  checkCuda(cudaMalloc((void**)&processDone,sizeof(int)));
  checkCuda(cudaHostAlloc((void**)&done1,sizeof(int),cudaHostAllocMapped));
  checkCuda(cudaHostAlloc((void**)&done2,sizeof(int),cudaHostAllocMapped));
  checkCuda(cudaMemset((void*)processDone,0,sizeof(int)));
  checkCuda(cudaMemset((void*)done1,0,sizeof(int)));
  checkCuda(cudaMemset((void*)done2,0,sizeof(int)));
  initArray(h_a,imageSize);
  initArray(h_b,imageSize); 
  initArray(cpu_b,imageSize);
  
  #ifdef DEBUG
  printf("device buffers allocated\n");
  #endif
  
  ComputeKernel<<<1,BLOCKSIZE,0,stream[1]>>>(d_a,d_b,processDone,done1,done2);
  checkCuda(cudaMemcpyAsync(d_a,h_a,sizeof(rowFlag)*2,cudaMemcpyHostToDevice,stream[0]));
        
  #ifdef DEBUG
  printf("ComputeKernel launched\n");
  #endif
  rowFlag *temp;
  temp = (rowFlag*)malloc(sizeof(rowFlag));
        
  while(numRowR < HEIGHT)
  {
      //printf("numRowR: %d, numRowS: %d\n",numRowR,numRowS);
      //printf("d1: %d, d2: %d, s1: %d, s2: %d\n",*done1,*done2,didIsendRow1,didIsendRow2);
      if(*done1 == 1&&numRowR<HEIGHT)
      {
        //get(1);
        //printf("get1\n");
        checkCuda(cudaMemcpyAsync(h_b+numRowR*WIDTH,d_b,rowByteSize,cudaMemcpyDeviceToHost,stream[0]));
        numRowR++;
        didIsendRow1=0;
        *done1 = 0;
      }
      if(!didIsendRow1&&!(*done1)&&numRowS<HEIGHT)
      {
        //send row1
        //printf("send1\n");
        temp->flag=didIsendRow2;
        memcpy(temp->row_data,h_a+numRowS*WIDTH,rowByteSize);
        checkCuda(cudaMemcpyAsync(d_a,temp,sizeof(temp),cudaMemcpyHostToDevice,stream[0]));
        didIsendRow1=1;
        numRowS++;
        
      }
  
      
      if(*done2 == 1&&numRowR<HEIGHT)
      {
        //get(2);
        //printf("get2\n");
        checkCuda(cudaMemcpyAsync(h_b+numRowR*WIDTH,d_b+WIDTH,rowByteSize,cudaMemcpyDeviceToHost,stream[0]));
        numRowR++;
        *done2 = 0;
        didIsendRow2=0;
      }
  
      if(!didIsendRow2&&!(*done2)&&numRowS<HEIGHT)
      {
        //send row2
        //printf("send2\n");
        temp->flag=didIsendRow1;
        memcpy(temp->row_data,h_a+numRowS*WIDTH,rowByteSize);
        rowFlag * faltu=d_a+1;
        checkCuda(cudaMemcpyAsync(faltu,temp,sizeof(temp),cudaMemcpyHostToDevice,stream[0]));
        didIsendRow2=1;
        numRowS++;
      }
  }
  free(temp);
  StopKernel<<<1,1,0,stream[2]>>>(processDone);
  
  #ifdef DEBUG
  printf("StopKernel allocated\n");
  #endif
   
  computeCPU(h_a,cpu_b,imageSize);
  
  if(verifyResults(h_b,cpu_b,imageSize) == 1)
          printf("CPU Result and GPU  Result same;!!!\n");
      else
          printf("CPU Result and GPU  Result not same;!!!\n");
  
  input = loadImage("red.pgm");
  char newName[40] = "out";
  strcat(newName,input->name);
  output = createImage(newName,input->format,input->h,input->w,input->maxV);
  long x = 0;
  
  for(i = 0; i < input->h; i++)
  {
      for(j = 0; j < input->w; j++)
      {
          setPixelBW(input,i,j,h_a[x]);
          setPixelBW(output,i,j,h_b[x]);
          x++;
      }
  }
  
  saveImage(input);
  saveImage(output);
  deleteImage(input);
  deleteImage(output);
   return 0;
}