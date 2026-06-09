# OpenACC Behaviour

This site explores OpenACC pragmas in combination with valid but seldomly used Fortran statements and 
different compilers.
The aim of this site is to document this behaviour for various use cases and compilers, thus providing
a knowledge database for those who need it. This site should allow Programmers to save time debugging OpenACC. It can also serve as a basis for compiler providers to "fix" or 
implement other behaviour for certain cases, such that the same OpenACC pragmas execute more similarily for the different compilers.

## Layout

Every chapter describes a problem and how each compiler handles it.

## Results overview

| Case | Cray Fortran 19.0.0 | nvfortran 25.3-0 | Expected according to spec |
|------|---------------------|------------------|----------------------------|
| [Pointers in structs — `declare create`](pointers_structs.md#container-with-declare-create) | ❌ Crash | ❌ Crash | ❌ Crash |
| [Pointers in structs — `enter data`, local variable](pointers_structs.md#container-with-enter-data) | ❌ Crash | ✅ OK | ❌ Crash |
| [Pointers in structs — `enter data`, module variable](pointers_structs.md#container-with-enter-data) | ❌ Crash | 🟡 Wrong result | ❌ Crash |
| [Pointers in structs — `enter data` for member](pointers_structs.md#container-with-enter-data) | ✅ OK | ✅ OK | ✅ OK |
| [Pointers in structs — no data/declare](pointers_structs.md#container-with-no-datadeclare-statement) | ❌ Crash | ✅ OK | ❌ Crash |
| [Characters in host routines](characters.md#compiler-behaviour) | ❌ Compile error | ✅ OK | — |
| [Module variable aliasing](module_double_alloc.md#compiler-behaviour) | 🟡 Wrong result | ✅ OK | — |
| [GPU-aware MPI — without slicing](gpu_aware_mpi.md#without-slicing) | ✅ OK | ✅ OK | — |
| [GPU-aware MPI — with slicing](gpu_aware_mpi.md#with-slicing) | ✅ OK | 🟡 Wrong result | — |
| [`acc_is_present` on a scalar](acc_is_present_scalar.md#compiler-behaviour) | ✅ OK | ❌ Compile error | ✅ OK |
| [`exit data delete` — never present](exit_data_delete.md#exit-data-delete-on-never-present-data) | ❌ Crash | ❌ Crash | ✅ OK |
| [`exit data delete` — twice](exit_data_delete.md#double-exit-data-delete) | ❌ Crash | ✅ OK | ✅ OK |

