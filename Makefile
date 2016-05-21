NVCC = /usr/local/cuda/bin/nvcc
CUDAPATH = /usr/local/cuda
NVCCFLAGS = -I$(CUDAPATH)/include
LFLAGS = -L$(CUDAPATH)/lib64 -lcuda -lcudart -lm
RS: RS.cu
	$(NVCC) $(NVCCFLAGS) -o RS RS.cu $(LFLAGS)
