# Type with allocatables

Types with allocatables are handled differently by compilers when using OpenACC. In C this would be equivalent to a struct with a pointer inside. According to the OpenACC specification it should not be possbile to write a type with allocatables to the gpu in one go. However, we noticed that it worked sometimes and thus we have listed the differences here

???+ info "OpenACC 3.3 section 2.6.4"

    ```quote
    When a data object is copied to device memory, the values are copied exactly. If the data is a data
    structure that includes a pointer, or is just a pointer, the pointer value copied to device memory
    will be the host pointer value. If the pointer target object is also allocated in or copied to device
    memory, the pointer itself needs to be updated with the device address of the target object before
    dereferencing the pointer in device memory
    ```

In the tables below, the **Correctness** column states whether each compiler's observed behaviour conforms to the OpenACC specification. Because copying a container does not attach its allocatable component, the data is not guaranteed on the device unless `container%values` is explicitly attached. Only the example that does so is expected to work; elsewhere a "correct" output relies on a non-portable automatic deep copy rather than on behaviour the specification mandates.

## Container with "declare create"

??? note "Code"

    ```fortran
    --8<-- "src/declare_create.f90"
    ```

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray | Crash | Per spec — copying the container does not attach `values` | Compiler warning (`Variable "(?)" is used before it is defined`); memory access fault at runtime. |
| Nvidia | Crash | Per spec — copying the container does not attach `values` | No warning; `CUDA_ERROR_ILLEGAL_ADDRESS` at runtime. |

## Container with "enter data"

??? note "Code with local variable"

    ```fortran
    --8<-- "src/enter_data.f90"
    ```

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray | Crash | Per spec — `values` is never attached | Memory access fault at runtime. |
| Nvidia | OK | Not per spec — relies on a non-portable automatic deep copy | Prints `Success 4.000000 2.000000`. |

??? note "Code with module variable"

    ```fortran
    --8<-- "src/enter_data_module.f90"
    ```

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray | Crash | Per spec — `values` is never attached | Memory access fault at runtime. |
| Nvidia | Wrong result | Not per spec — relies on a non-portable automatic deep copy | Prints `Success 4.000000 0.000000`; the second element should be `2.0`. The module variable case silently produces an incorrect value. |

??? note "Code with enter data for member variable"

    ```fortran
    --8<-- "src/enter_data_members.f90"
    ```

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray | Crash | Not per spec — the explicit attach of `values` should make this work | Memory access fault at runtime. |
| Nvidia | OK | Per spec — `values` is explicitly attached | Prints `Success 4.000000 2.000000` (correct). |

## Container with no data/declare statement

??? note "Code"

    ```fortran
    --8<-- "src/type_with_allocatable.f90"
    ```

| Compiler | Result | Correctness | Notes |
|----------|--------|-------------|-------|
| Cray | Crash | Per spec — `values` is never attached | No warning at compile time; memory access fault at runtime. |
| Nvidia | OK | Not per spec — relies on a non-portable automatic deep copy | Prints `Success 4.000000 2.000000`. |
