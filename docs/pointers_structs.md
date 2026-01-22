# Pointers in structs

Pointers in structs are handled differently by compilers when using OpenACC. 

OpenACC states: 
When a data object is copied to device memory, the values are copied exactly. If the data is a data
structure that includes a pointer, or is just a pointer, the pointer value copied to device memory
will be the host pointer value. If the pointer target object is also allocated in or copied to device
memory, the pointer itself needs to be updated with the device address of the target object before
dereferencing the pointer in device memory

Therefore it is should not be possbile to write a struct with pointers to the gpu in one go
