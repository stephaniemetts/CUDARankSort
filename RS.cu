//MatrixMult.cu
#include <stdio.h>
#include <cuda.h>
#include <stdlib.h>

__global__ void gpu_sort(int *a,int *b,int *c, int N) {
	int tid = threadIdx.x + blockDim.x * blockIdx.x; 
	int count = 0;
	int d;
		for(d=0;d<N;d++) {
			if(a[d] < a[tid]) {
				count++;
			}
		}
		c[count] = a[tid];
	
}


int main(int argc, char *argv[])  {
	int i, j; 							// loop counters
	int Grid_Dim_x=1, Grid_Dim_y=1;		//Grid structure values
	int Block_Dim_x=1, Block_Dim_y=1;		//Block structure values
	int noThreads_x, noThreads_y;			// number of threads available in device, each dimension
	int noThreads_block;					// number of threads in a block
	int N = 10;  						// size of array in each dimension
	int B;
	int T;
	int *a,*b,*c,*d;
	int *dev_a, *dev_b, *dev_c;
	int size;							// number of bytes in arrays
	cudaEvent_t start, stop;     				// using cuda events to measure time
	float elapsed_time_ms;       			// which is applicable for asynchronous code also
	cudaEventCreate(&start);		
	cudaEventCreate(&stop);


/* --------------------ENTER INPUT PARAMETERS AND ALLOCATE DATA -----------------------*/
							// keyboard input

	printf("Enter the value for N: ");
	scanf("%d", &N);
//takes in input
	int valid = 0;
	while(valid == 0) {

		printf("Enter the number of blocks: ");
		scanf("%d", &B);

		printf("Enter the number of threads: ");
		scanf("%d", &T);

		if(B > 1024 || T > 1024 || B*T < N) {
			printf("Invlaid input entered.\n");
		} else {
			valid = 1;
			Grid_Dim_x = B;
			Block_Dim_x = T;		//puts the size of blocks and thread in for the dim3
		}
	}


	
	dim3 Grid(Grid_Dim_x, Grid_Dim_x);	//Grid structure
	dim3 Block(Block_Dim_x,Block_Dim_y);	//Block structure, threads/block limited by specific device
	size = N * N * sizeof(int);				// number of bytes in total in arrays

	a = (int*) malloc(size);					//dynamically allocated memory for arrays on host
	b = (int*) malloc(size);
	c = (int*) malloc(size);					// results from GPU
	d = (int*) malloc(size);				// results from CPU
							// load arrays with some numbers

	srand(3); //initialize random number generator
	
	for (i=0; i < N; i++) { //load array with numbers
		a[i] = (int)rand(); 
	}


	cudaMalloc((void**)&dev_a, size);			// allocate memory on device
	cudaMalloc((void**)&dev_b, size);
	cudaMalloc((void**)&dev_c, size);

	cudaMemcpy(dev_a, a , size ,cudaMemcpyHostToDevice);
	cudaMemcpy(dev_b, b , size ,cudaMemcpyHostToDevice);

	cudaEventRecord(start, 0); 			// here start time, after memcpy

	gpu_sort<<<Grid,Block>>>(dev_a,dev_b,dev_c,N);
	cudaMemcpy(c, dev_c, size , cudaMemcpyDeviceToHost);

	cudaEventRecord(stop, 0);     			// measuse end time
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&elapsed_time_ms, start, stop );

	printf("Time to calculate results on GPU: %f ms.\n", elapsed_time_ms);
	double gpuTime = elapsed_time_ms; 

/* ------------- COMPUTATION DONE ON HOST CPU ----------------------------*/

	cudaEventRecord(start, 0);			// use same timing*

	//cpu_matrixmult(a,b,d,N);				// do calculation on host
//sequential rank sort
	int k;
	for(k=0;k<N;k++) {
		int count = 0;
		int d;
		for(d=0;d<N;d++) {
			if(a[d] < a[k]) {
				count++;
			}
		}
		b[count] = a[k];
		count = 0;
	}


	cudaEventRecord(stop, 0);     		// measure end time
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&elapsed_time_ms, start, stop );

	printf("Time to calculate results on CPU: %f ms.\n", elapsed_time_ms);  // exe. time
	double cpuTime = elapsed_time_ms;

/* ------------------- check device creates correct results -----------------*/
/*
	printf("Initial Array: \n");
	int h;
	for(h=0;h<N;h++) {
		printf("%d ", a[h]);
	}

	printf("\n");
/*
	printf("Sequential Rank Sort: \n");
	
	for(k=0;k<N;k++) {
		int count = 0;
		int d;
		for(d=0;d<N;d++) {
			if(a[d] < a[k]) {
				count++;
			}
		}
		b[count] = a[k];
		count = 0;
	}

	for(h=0;h<N;h++) {
		printf("%d ", b[h]);
	}

printf("Parallel Rank Sort\n");
	for(h=0;h<N;h++) {
		printf("%d ", c[h]);
	}
*/

int error = 0;
int r;
for(r=0;r<N;r++) {
	if(b[r] != c[r]) {
		error = 1;
		break;
	}
}
if(error == 1) {
	printf("Parallel and sequential do not match.\n");
} else {
	printf("Seqential and parallel match.\n");
}
	printf("Speedup Factor: %lf\n", cpuTime/gpuTime);


/* --------------------- repeat program  ----------------------------------------*/
 								//  while loop to repeat calc with different parameters
/* --------------  clean up  ---------------------------------------*/
	free(a); free(b); free(c);
	cudaFree(dev_a);
	cudaFree(dev_b);
	cudaFree(dev_c);
	cudaEventDestroy(start);
	cudaEventDestroy(stop);
	return 0;
}

