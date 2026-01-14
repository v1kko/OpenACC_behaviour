# Pointers in structs

Pointers in structs are handled differently by compilers when using OpenACC. 

OpenACC states: The host_data construct makes the address of data in device memory available on the host.

Therefore it is ambiguous if data that is pointed to within a struct should be available on the GPU
