# Claude's guesses

Legend: **ok**, **compile crash**, **runtime crash**, **wrong result**

Scoring: a correct guess is +1. Any guess other than **wrong result** on a case that actually gives a wrong result is −3. So I guess **wrong result** whenever it has at least about a 20% chance.

| Case | nvfortran 25.3.0 | cray 19.0.0 | Reasoning |
|---|---|---|---|
| acc_is_present_scalar | ok | ok | Not present, so the `if` skips the delete. A wrong result is not possible here |
| attach_reassociate | wrong result | wrong result | Spec 3.3 says attach again when the target changes, but a runtime that only increments the existing counter keeps pointing at `a` (gives 1s) |
| characters_cray | ok | compile crash | Cray rejects I/O and concatenation in an `acc routine`. A wrong result is not possible here |
| declare_create | ok | runtime crash | nvfortran maps the referenced allocatable member implicitly; Cray's copy is shallow, so the device reads a host address |
| detach_not_attached | ok | ok | Spec: detach with an attachment counter of 0 does nothing |
| enter_data | ok | runtime crash | Same as declare_create |
| enter_data_members | ok | ok | Correct manual deep copy |
| enter_data_module | ok | runtime crash | Same as declare_create |
| exit_data_double | ok | ok | Spec: delete of data that is not present does nothing. A wrong result is not possible here |
| exit_data_not_present | ok | ok | Same |
| gpu_aware_mpi | ok | ok | Valid device_resident + host_data |
| gpu_aware_mpi_slicing | wrong result | wrong result | The non-tight `collapse(2)` may only be warned about and ignored. Then the host-side `=>` on a device_resident pointer plus `use_device` on it probably sends the wrong buffer |
| module_var_aliasing | wrong result | wrong result | The test exists because some compiler mixes up two private module variables that are both named `buffer` |
| reallocate | ok | ok | Implicit copy of the pointer target each time |
| reduction_array_element | wrong result | wrong result | Allowed in 3.3, but support is new. If the compiler accepts it, it may not reduce correctly |
| reduction_composite | wrong result | wrong result | Allowed in 3.3. If the compiler accepts it without reducing each member, the members race |
| reduction_member | wrong result | compile crash | Spec forbids it. nvfortran probably accepts it, and the result may be wrong; Cray probably rejects it |
| type_with_allocatable | ok | runtime crash | Same as declare_create: Cray copy is shallow |

## Score against docs/index.md

**Score: 17 / 34.** That is 20 correct guesses (+20) and one missed wrong result (−3). The docs table has 17 cases with two compilers each. `reallocate` is not in the table, so it isn't scored.

| Case | nvfortran: guess → actual | Cray: guess → actual | Points |
|---|---|---|---|
| declare_create | ok → crash (0) | crash ✓ | +1 |
| enter_data | ok ✓ | crash ✓ | +2 |
| enter_data_module | ok → **wrong result** (−3) | crash ✓ | −2 |
| enter_data_members | ok ✓ | ok ✓ | +2 |
| type_with_allocatable | ok ✓ | crash ✓ | +2 |
| characters_cray | ok ✓ | compile crash ✓ | +2 |
| module_var_aliasing | wrong result → ok (0) | wrong result ✓ | +1 |
| gpu_aware_mpi | ok ✓ | ok ✓ | +2 |
| gpu_aware_mpi_slicing | wrong result ✓ | wrong result → ok (0) | +1 |
| acc_is_present_scalar | ok → compile crash (0) | ok ✓ | +1 |
| exit_data_not_present | ok → crash (0) | ok → crash (0) | 0 |
| exit_data_double | ok ✓ | ok → crash (0) | +1 |
| attach_reassociate | wrong result → ok (0) | wrong result ✓ | +1 |
| detach_not_attached | ok ✓ | ok ✓ | +2 |
| reduction_member | wrong result → compile crash (0) | compile crash ✓ | +1 |
| reduction_composite | wrong result → compile crash (0) | wrong result → compile crash (0) | 0 |
| reduction_array_element | wrong result → ok (0) | wrong result → compile crash (0) | 0 |
| **Total** | | | **17** |
