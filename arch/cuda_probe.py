import ctypes as C, json, time
c=C.CDLL('/usr/lib/wsl/lib/libcuda.so.1')
def call(name,*args):
    r=getattr(c,name)(*args)
    if r: raise RuntimeError(f'{name}: CUDA error {r}')
call('cuInit',0)
dev=C.c_int(); call('cuDeviceGet',C.byref(dev),0)
name=C.create_string_buffer(256); call('cuDeviceGetName',name,256,dev)
ctx=C.c_void_p(); call('cuCtxCreate_v2',C.byref(ctx),0,dev)
ptx=b'''.version 7.0
.target sm_52
.address_size 64
.visible .entry fill(.param .u64 out) {
.reg .u64 p; .reg .u32 v;
ld.param.u64 p,[out]; mov.u32 v,42; st.global.u32 [p],v; ret;
}'''
mod=C.c_void_p(); call('cuModuleLoadData',C.byref(mod),C.c_char_p(ptx))
fn=C.c_void_p(); call('cuModuleGetFunction',C.byref(fn),mod,b'fill')
ptr=C.c_uint64(); call('cuMemAlloc_v2',C.byref(ptr),C.c_size_t(4))
params=(C.c_void_p*1)(C.addressof(ptr))
t=time.perf_counter(); call('cuLaunchKernel',fn,1,1,1,1,1,1,0,None,params,None)
call('cuCtxSynchronize')
out=C.c_uint32(); call('cuMemcpyDtoH_v2',C.byref(out),ptr,C.c_size_t(4))
assert out.value==42,out.value
print(json.dumps({'gpu':name.value.decode(),'kernel_result':out.value,'compute_verified':True,'launch_sync_copy_ms':(time.perf_counter()-t)*1000}))
call('cuMemFree_v2',ptr); call('cuModuleUnload',mod); call('cuCtxDestroy_v2',ctx)
