# AraXL + TeraNoC in GVSoC — model source map

Where to find the model files for building an AraXL (CVA6 + Ara) and TeraNoC
system in this GVSoC checkout.

All paths are links relative to the repo root (`.../third-party-repos/gvsoc/`).
In VS Code, click a link in the preview pane, or Ctrl/Cmd+Click it in the editor,
to open the file.


## Where the code lives

GVSoC is a superproject; all model source lives in two submodules:

- **`core/`** — the C++ CPU/ISS and compute models (CVA6, Ara, Snitch, vector unit).
- **`pulp/`** — the Python system generators plus the SoC-specific device and NoC C++.

Each hardware block is a pair of files that sit side by side: a `.py` generator
that builds the component and its config, and a `.cpp`/`.hpp` model with the
behavior. Navigate by component, and expect the C++ next to the Python.

> The path `pulp/pulp/…` is not a typo: the submodule directory is `pulp/`, and
> the Python package inside it is also named `pulp/`.


## Ara — runnable today

There is a ready-made target named `ara`:

- [pulp/ara_v2.py](pulp/ara_v2.py) — target `ara`: a single-node SoC = **CVA6 + 4-lane Ara, VLEN=4096**
  (`Cva6Config(nb_lanes=4, lane_width=8, vlen=4096)`), with DRAM, stdout, and control registers.
- [pulp/ara.py](pulp/ara.py) — the v1 equivalent.

So CVA6 + Ara runs out of the box. The scaled-up multi-cluster version is what you build.


## CVA6 + Ara — model files

### Python generators (in `pulp/`)

- [pulp/pulp/cpu/iss/cva6.py](pulp/pulp/cpu/iss/cva6.py) — the CVA6 + Ara composition point (calls `ara_v2.attach(...)`).
- [pulp/pulp/cpu/iss/cva6_config.py](pulp/pulp/cpu/iss/cva6_config.py) — `Cva6Config`: `nb_lanes`, `lane_width`, `vlen`, `isa`.
- [pulp/pulp/cva6/cva6.py](pulp/pulp/cva6/cva6.py) — CVA6 system wrapper.
- [pulp/pulp/ara/ara_v2.py](pulp/pulp/ara/ara_v2.py) — the active Ara vector attach: `attach(vlen, nb_lanes, use_spatz, …)`.
- [pulp/pulp/ara/ara.py](pulp/pulp/ara/ara.py) — the v1 Ara attach.

### C++ compute (in `core/`)

There are two ISS trees. `iss_v2/` is the active one used by `cva6.py`; `iss/` is legacy.

Active — `core/models/cpu/iss_v2/`:

- [src/cores/ara/ara.cpp](core/models/cpu/iss_v2/src/cores/ara/ara.cpp), [src/cores/ara/ara_vlsu.cpp](core/models/cpu/iss_v2/src/cores/ara/ara_vlsu.cpp)
- [src/cores/spatz/spatz.cpp](core/models/cpu/iss_v2/src/cores/spatz/spatz.cpp), [src/cores/spatz/spatz_vlsu.cpp](core/models/cpu/iss_v2/src/cores/spatz/spatz_vlsu.cpp)
- [src/vector.cpp](core/models/cpu/iss_v2/src/vector.cpp)
- [include/cores/ara/ara.hpp](core/models/cpu/iss_v2/include/cores/ara/ara.hpp), [include/vector.hpp](core/models/cpu/iss_v2/include/vector.hpp)

Legacy — `core/models/cpu/iss/`:

- [src/cva6/cva6.cpp](core/models/cpu/iss/src/cva6/cva6.cpp) — the CVA6 scalar core
- [src/ara/ara.cpp](core/models/cpu/iss/src/ara/ara.cpp), [src/ara/ara_vcompute.cpp](core/models/cpu/iss/src/ara/ara_vcompute.cpp), [src/ara/ara_vlsu.cpp](core/models/cpu/iss/src/ara/ara_vlsu.cpp)
- [src/spatz.cpp](core/models/cpu/iss/src/spatz.cpp), [src/vector.cpp](core/models/cpu/iss/src/vector.cpp)


## TeraNoC — model files

TeraNoC is a Snitch-based manycore mesh (MemPool lineage).

Target: [pulp/teranoc.py](pulp/teranoc.py)   ·   Package: `pulp/pulp/teranoc/`

### Config / DSE knobs

- [pulp/pulp/teranoc/arch.py](pulp/pulp/teranoc/arch.py) — `CONFIGS` = `teranoc`, `mempool_noc`, `minpool_noc`
  (select with `--config` / `--system_config`).

### Topology generators (Python)

- [pulp/pulp/teranoc/teranoc_system.py](pulp/pulp/teranoc/teranoc_system.py) — `TeranocSoc` top level
- [pulp/pulp/teranoc/teranoc_group.py](pulp/pulp/teranoc/teranoc_group.py)
- [pulp/pulp/teranoc/teranoc_cluster.py](pulp/pulp/teranoc/teranoc_cluster.py)
- [pulp/pulp/teranoc/teranoc_tile.py](pulp/pulp/teranoc/teranoc_tile.py) — where the per-tile core is instantiated
- [pulp/pulp/teranoc/l1_subsystem.py](pulp/pulp/teranoc/l1_subsystem.py), [l2_subsystem.py](pulp/pulp/teranoc/l2_subsystem.py)

### NoC C++ — the L1 mesh (`pulp/pulp/teranoc/l1_interconnect/`)

- [floonoc.cpp](pulp/pulp/teranoc/l1_interconnect/floonoc.cpp) / [.hpp](pulp/pulp/teranoc/l1_interconnect/floonoc.hpp)
- [floonoc_router.cpp](pulp/pulp/teranoc/l1_interconnect/floonoc_router.cpp) / [.hpp](pulp/pulp/teranoc/l1_interconnect/floonoc_router.hpp)
- [floonoc_network_interface.cpp](pulp/pulp/teranoc/l1_interconnect/floonoc_network_interface.cpp) / [.hpp](pulp/pulp/teranoc/l1_interconnect/floonoc_network_interface.hpp)
- [l1_noc_itf.cpp](pulp/pulp/teranoc/l1_interconnect/l1_noc_itf.cpp), [l1_noc_router_remapper.cpp](pulp/pulp/teranoc/l1_interconnect/l1_noc_router_remapper.cpp), [l1_noc_endpoint_router.cpp](pulp/pulp/teranoc/l1_interconnect/l1_noc_endpoint_router.cpp) (each with a `.py`)

### L2 interconnect (Python only)

- [pulp/pulp/teranoc/l2_interconnect/l2_noc.py](pulp/pulp/teranoc/l2_interconnect/l2_noc.py)
- [pulp/pulp/teranoc/l2_interconnect/l2_address_scrambler.py](pulp/pulp/teranoc/l2_interconnect/l2_address_scrambler.py)

### Registers / checker

- [pulp/pulp/teranoc/ctrl_registers.cpp](pulp/pulp/teranoc/ctrl_registers.cpp) / [.py](pulp/pulp/teranoc/ctrl_registers.py)
- [pulp/pulp/teranoc/mempool_dpi_checker.cpp](pulp/pulp/teranoc/mempool_dpi_checker.cpp) / [.py](pulp/pulp/teranoc/mempool_dpi_checker.py)


## Snitch cores + MemPool blocks

These are what the TeraNoC tiles instantiate.

### Snitch core

Python (in `pulp/`):

- [pulp/pulp/cpu/iss/snitch_mempool.py](pulp/pulp/cpu/iss/snitch_mempool.py) — the `SnitchMempool` tile core; can attach Ara/Spatz
- [pulp/pulp/cpu/iss/spatz.py](pulp/pulp/cpu/iss/spatz.py), [spatz_mempool.py](pulp/pulp/cpu/iss/spatz_mempool.py)
- [pulp/pulp/snitch/](pulp/pulp/snitch) — `snitch_core.py`, `snitch_isa.py`, `sequencer.py`, `l1_subsystem.py`, and more

C++ (in `core/models/cpu/iss/src/`):

- [snitch_bare/snitch.cpp](core/models/cpu/iss/src/snitch_bare/snitch.cpp)
- [snitch_fast/snitch.cpp](core/models/cpu/iss/src/snitch_fast/snitch.cpp), [sequencer.cpp](core/models/cpu/iss/src/snitch_fast/sequencer.cpp), [fpu_lsu.cpp](core/models/cpu/iss/src/snitch_fast/fpu_lsu.cpp), [ssr.cpp](core/models/cpu/iss/src/snitch_fast/ssr.cpp)
- [snitch_fp_ss/iss.cpp](core/models/cpu/iss/src/snitch_fp_ss/iss.cpp), [exec_inorder.cpp](core/models/cpu/iss/src/snitch_fp_ss/exec_inorder.cpp)

### MemPool blocks (`pulp/pulp/mempool/`)

C++:

- [xbar/mempool_xbar.cpp](pulp/pulp/mempool/xbar/mempool_xbar.cpp), [xbar/mempool_xbar_selector.cpp](pulp/pulp/mempool/xbar/mempool_xbar_selector.cpp)
- [dma/mempool_dma_ctrl.cpp](pulp/pulp/mempool/dma/mempool_dma_ctrl.cpp)
- [idma/mempool_dma.cpp](pulp/pulp/mempool/idma/mempool_dma.cpp) plus the iDMA model under `idma/be/`, `idma/fe/`, `idma/me/`
- [l1_interconnect/l1_remote_itf.cpp](pulp/pulp/mempool/l1_interconnect/l1_remote_itf.cpp), [l1_remote_itf_async.cpp](pulp/pulp/mempool/l1_interconnect/l1_remote_itf_async.cpp)
- [l2_interconnect/cache_filter.cpp](pulp/pulp/mempool/l2_interconnect/cache_filter.cpp)
- [common/address_scrambler/address_scrambler.cpp](pulp/pulp/mempool/common/address_scrambler/address_scrambler.cpp)

Python topology: `mempool_system.py`, `mempool_group.py`, `mempool_sub_group.py`,
`mempool_cluster.py`, `mempool_tile.py`, `l1_subsystem.py`, `l2_subsystem.py`.


## FlooNoC base model

The NoC family TeraNoC descends from — useful as reference.

- [pulp/pulp/floonoc/](pulp/pulp/floonoc) — FlooNoC v1 (`floonoc.cpp/.hpp`, `floonoc_router.*`, `floonoc_network_interface.*`, `floonoc.py`)
- [pulp/pulp/floonoc_v2/](pulp/pulp/floonoc_v2) — FlooNoC v2 (narrow/wide split, AR/AW vs data phases)
- Tests: [pulp/tests/floonoc_v2/](pulp/tests/floonoc_v2)


## Notes for building the combined system

- To put CVA6 + Ara cores inside a TeraNoC mesh, the drop-in point is the core
  instantiation in [pulp/pulp/teranoc/teranoc_tile.py](pulp/pulp/teranoc/teranoc_tile.py). A second route is
  [snitch_mempool.py](pulp/pulp/cpu/iss/snitch_mempool.py), which can already attach an Ara/Spatz vector unit.
- Check how far the built-in Ara config scales (max lanes / multi-cluster) in
  [pulp/ara_v2.py](pulp/ara_v2.py) and [pulp/pulp/cpu/iss/cva6_config.py](pulp/pulp/cpu/iss/cva6_config.py).
- Build and run the `ara` and `teranoc` targets first to confirm the tree compiles.


## Setup & run — DONE 2026-07-07 (`ara_v2` + `teranoc` build and run)

Both targets are **built and installed**. `ara_v2` runs a real workload end-to-end;
`teranoc` builds, configures, and elaborates (a real teranoc workload needs an external
toolchain — see caveat).

### Environment (the traps)
- **Interpreter:** system `python3` is **3.6** (no `dataclasses`) → cannot import the
  runner. Correct env is the dedicated **`teranoc` conda env** (Python **3.11**).
- **Deps:** `conda run -n teranoc pip install -r requirements.txt -r core/requirements.txt -r gapy/requirements.txt`
  (env originally had only `rich`).
- **Compiler:** system gcc is **8.5** (below GVSoC's known-good range; incomplete C++17).
  Installed **`gxx_linux-64` (gcc 15.2)** + **`zlib`** into the env (engine links `-lz`;
  conda's `ld` searches only the conda sysroot). `/opt/rh/gcc-toolset-12,14` are an alternative.
- **Shortcut:** `source gvsoc_env.sh` (repo root) activates the env + sets `LD_LIBRARY_PATH`
  (conda libstdc++/libz + `install/lib`) + PATH.

### Build
```bash
source ~/miniforge3/etc/profile.d/conda.sh && conda activate teranoc
export CMAKE_FLAGS='-j8' CXX=x86_64-conda-linux-gnu-g++ CC=x86_64-conda-linux-gnu-gcc \
       LIBRARY_PATH=$CONDA_PREFIX/lib:$LIBRARY_PATH
make build TARGETS='ara_v2 teranoc'      # NOT `make all` (that also re-checks out submodules)
```
Installs `install/lib/libplatform_tree_{ara_v2,teranoc}.so` + 68 model `.so` under `install/models/`.

### ⚠️ Local patch to pinned `pulp` submodule (required for teranoc)
[`pulp/pulp/teranoc/arch.py`](pulp/pulp/teranoc/arch.py) — added field
**`l2_axi_interleave: int = 16`** to `TeranocConfig`. Upstream commit `664ea862` referenced
`arch.l2_axi_interleave` in `teranoc_system.py:120` (passed to `MempoolDpiChecker`) but never
added the field, so config generation crashed with `AttributeError`. Value **16** mirrors the
sibling `L2AddressScrambler(interleave=16)` for the same L2 (`teranoc_system.py:144`); the C++
checker only requires it be non-zero. **This is a local edit to a frozen SHA — report/upstream.**

### Run
```bash
source gvsoc_env.sh
# cva6 + Ara (single cluster) — PASSES (154631 cycles, ~99% vector util):
gvrun --target ara_v2 --param soc/binary=$PWD/pulp/examples/rvv_fconv2d run
# teranoc — pick a profile with --target-opt system_config={teranoc|mempool_noc|minpool_noc}:
gvrun --target teranoc --target-opt system_config=minpool_noc --param binary=<elf> run
```
Param paths: `ara_v2` → `soc/binary`; `teranoc` → `binary` + `system_config` (both on the
`TeranocSoc` root). Handy CMDs: `tree` (dump params, no sim), `config`, `diagram`, `targets`.

### Caveat — teranoc workload
No teranoc-compiled program ships in this repo. The bundled
[`pulp/examples/mempool/mempool_test`](pulp/examples/mempool/mempool_test) targets the separate
**`mempool`** target (different memory map / boot flow); on teranoc the Snitch cores fetch garbage
and **spin forever** (`run` times out, but `gvsoc_config.json` is generated — proving
build+config+elaboration are fine). The default `teranoc` profile is **1024 Snitch cores / 256
tiles**; Python construction alone takes minutes — use `minpool_noc` (16 cores) or `mempool_noc`
(256) to iterate. A real teranoc run needs a MemPool/Snitch SW-stack ELF (RISC-V toolchain +
runtime + matching linker script) — a separate lift.
