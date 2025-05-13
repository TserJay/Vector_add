﻿
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cuda.h>

#include <stdio.h>



__global__ void reduce_baseline(const int * input, int *output, size_t n){
    //由于只有一个block和thread，相当于串行的程序
    int sum = 0;
    //累加
    for (int i = 0; i < n; i++)
    {
        sum += input[i];
    }
    *output = sum;
}
  
bool CheckResult(int* out, int groudtruth) 
{
    if (*out != groudtruth) {
        return false;
    }
    return true;
}

int main()
{
    float milliseconds = 0;

    // const int N = 32 * 256 *256
    const int N = 25600000;
    cudaSetDevice(0);
    cudaDeviceProp deviceProp;
    cudaGetDeviceProperties(&deviceProp, 0);

    //const int blockSize = 256;
    const int blockSize = 1;

    int GridSize = 1;

    //分配内存和显存并初始化数据
    int *a = (int*)malloc(N * sizeof(int));
    int *d_a;
    cudaMalloc((void**)&d_a, N * sizeof(int));

    int* out = (int*)malloc(GridSize * sizeof(int));
    int* d_out;
    cudaMalloc((void**)&d_out, GridSize * sizeof(int));

    //初始化
    for (size_t i = 0; i < N; i++)
    {
        a[i] = 1;
    }

    int groudtruth = N * 1;
    //将初始化后的数据拷贝到GPU
    cudaMemcpy(d_a, a, N * sizeof(int), cudaMemcpyHostToDevice);
    //定义分配的block数量和threads的数量
    dim3 grid(GridSize);
    dim3 block(blockSize);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);


    //分配1个block和1个thread
    reduce_baseline << <1, 1 >> > (d_a, d_out, N);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&milliseconds, start, stop);
    //将结果拷贝回cpu并check正确性
    cudaMemcpy(out, d_out, GridSize * sizeof(int), cudaMemcpyDeviceToHost);

    printf("allcated %d block,data counts are %d\n", GridSize, N);
    bool is_right = CheckResult(out, groudtruth);
    if (is_right) {
        printf("the ans is right\n");

    }
    else
    {
        printf("ans is wrong\n");
        for (int i = 0; i < GridSize; i++)
        {
            printf("res per block : %lf ", out[i]);
        }
        printf("\n");
        printf("groudtruth is: %f \n", groudtruth);
    }

    printf("reduce_baseline latency = %f ms\n", milliseconds);

    cudaFree(d_a);
    cudaFree(d_out);
    free(a);
    free(out);


    return 0;
}
