#ifdef cl_khr_fp64
    #pragma OPENCL EXTENSION cl_khr_fp64 : enable
#elif defined(cl_amd_fp64)
    #pragma OPENCL EXTENSION cl_amd_fp64 : enable
#else
    #error "Double precision floating point not supported by OpenCL implementation."
#endif

__kernel void normsq(
     __global const double * vec1, __global const double * vec1,
      __global double *scratch, __global double * scale,
    unsigned int n, unsigned int work_per_item )
{
	// find local work group dimensions and location
	int gdim0 = get_local_size(0);
	int li = get_local_id(0);
	int gi = get_group_id(0);
	int si = (gi*gdim0+li)*work_per_item;
	int sl = li*work_per_item;
	int comp = n-si;
	__local double scale_l;
	if (li == 0){
		scale_l = scale[0];
	}
	__local double loc1 [LOC_SIZE];
	__local double loc2 [LOC_SIZE];

	for (int i=0; i < work_per_item; i++){
		loc1[sl+i] = (i < comp) ? vec1[si+i] : 0;
		loc2[sl+i] = (i < comp) ? vec2[si+i] : 0;
	}

	double s = 0;
	
	for (int i=0; i < work_per_item; i++){
		s += scale_l*loc1[sl+i]*loc2[sl+i];
	}
	
	barrier(CLK_LOCAL_MEM_FENCE);
	
	loc[li] = s;
	
	barrier(CLK_LOCAL_MEM_FENCE);
	
	for (int i=gdim0/2; i>0; i>>=1){
		if (li < i){
			loc[li] += loc[li+i];
		}
		barrier(CLK_LOCAL_MEM_FENCE);
	}

	// write to scratch
	if (li == 0)
		scratch[gi] = loc[0];


}