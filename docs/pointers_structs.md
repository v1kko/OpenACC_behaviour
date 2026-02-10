# Type with allocatables

Types with allocatables are handled differently by compilers when using OpenACC. 

OpenACC states: 

```quote
When a data object is copied to device memory, the values are copied exactly. If the data is a data
structure that includes a pointer, or is just a pointer, the pointer value copied to device memory
will be the host pointer value. If the pointer target object is also allocated in or copied to device
memory, the pointer itself needs to be updated with the device address of the target object before
dereferencing the pointer in device memory
```

Therefore it is should not be possbile to write a type with allocatables to the gpu in one go (according to the specification).

However, Compilers each interpret this differently for different cases, thus we list some differences here:

## Combined with "declare create"

- Cray: compiler warning, runtime crash
- Nvidia: no warning, runtime crash

## Combined with "enter data"

- Cray: runtime crash
- Nvidia: works

## Combined with no data/declare statement, only parallel loop
- Cray: no warning, runtime crash
- Nvidia: works

