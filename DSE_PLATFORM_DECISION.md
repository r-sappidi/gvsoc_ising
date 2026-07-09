# DSE platform decision — GVSoC-native vs. extracting C++ models into SST

**Question:** For design-space exploration (DSE) of our custom accelerator with TeraNoC
(and AraXL = CVA6+Ara), should we (A) use GVSoC natively, or (B) take GVSoC's C++
models and integrate them into SST?

**Decision (2026-07-06):** **Use GVSoC natively (A) as the primary DSE engine. Reject
extracting the C++ into SST (B). Anchor fidelity with GVSoC's *own* Verilator RTL
co-sim (`--platform rtl`), not SST. Involve SST only for narrow cases below, and if so,
*embed* GVSoC (don't port).**

Reached via 4 research subagents + 3 adversarial subagents (steelman-SST, attack-GVSoC,
fact-check). The decision survived the adversarial pass but was sharpened by it — the
caveats in §3 are load-bearing, not boilerplate.

---

## 1. Why not "extract C++ models into SST"

- **A GVSoC model is an engine plugin, not a library.** Every model inherits `vp::Component`/
  `vp::Block` and `#include <vp/vp.hpp>`, pulling in the whole engine (clock, time, trace,
  power, register, stats). Timing *is* engine events: the FlooNoC router drives its per-cycle
  FSM through `vp::ClockEvent fsm_event.enqueue()` (8 enqueue sites across
  `floonoc_router.cpp` + `l1_noc_router_remapper.cpp`) over the `vp::IoReq` port protocol.
  Models can't advance time without the engine. *(fact-checked: CONFIRMED)*
- **So literal source-lifting = forking the whole engine + config_tree + systree generators.**
  That buys nothing.
- **Nuance (adversarial correction):** not *every* piece is welded. The **address scrambler**
  (`mempool/common/address_scrambler/address_scrambler.cpp`, stateless bit-swap) and the
  **endpoint router** (`teranoc/l1_interconnect/l1_noc_endpoint_router.cpp`, ~15 lines) are
  engine-neutral arithmetic and *would* port cheaply. Only the **remapper** (cycle-varying
  port permutation, `remap_pos += clock.get_cycles()`) and the **router FSM** are genuinely
  coupled. A hybrid (SST `kingsley` mesh + 2 small custom SubComponents) is a *possible*
  fallback — but see §3, because it still can't reproduce the calibrated congestion behavior.

## 2. Why not "SST-native (merlin) instead"

- `merlin` gives a generic parametric mesh (topology, link/xbar bandwidth, VCs, flit flow
  control) — but it does **not** model TeraNoC's specific L1 remapper / endpoint-router /
  banked-TCDM scrambler, which is usually the *point* of a TeraNoC study. Those mechanisms
  shape congestion and can **reorder** a DSE ranking, not just offset it.
- SST's headline advantage (MPI scale-out) is **muted for a single tightly-coupled die** —
  a cycle-coupled L1 mesh has tiny inter-rank lookahead, the worst case for conservative
  PDES. It only pays off with a multi-die/chiplet partition boundary.
- Our SST investment is **partial anyway**: `rev` not built, `verilator-sst` source-only,
  AraXL-in-SST is a design note with no code. *(fact-checked: CONFIRMED)*

## 3. The load-bearing caveat: what GVSoC-native CANNOT do

The native FlooNoC/TeraNoC NoC model is **cycle-approximate AND structurally blind** to
several NoC-microarchitecture knobs — it emits *identical* numbers regardless of the setting,
so it has **zero discriminating power** on those axes (worse than "approximate"):

| NoC-DSE knob | Native GVSoC discriminating power |
|---|---|
| Mesh dimension / hop count | ✅ yes (under fixed XY, size-independent hops) |
| Tile / cluster count, mapping | ✅ yes |
| Gross endpoint bandwidth | ✅ yes (modeled at NIs) |
| **Link / bisection width** | ❌ none — `narrow_width` read but never used in fabric timing; bursts never split |
| **Virtual channels** | ❌ none — one FIFO per input; `router_output_queue_size` is dead config |
| **Routing algorithm** | ❌ none — XY hardcoded (+ self-noted TODO bug for mesh gaps) |
| **Flow control scheme** | ❌ none — boolean stall/unstall, not credit-based |
| **Fine buffer depth** | ⚠️ coarse — input-only, packet-granular; close points tie |

Additional gaps:
- **The multi-cluster AraXL under study doesn't exist in the model.** Built-in `ara`
  (`pulp/ara_v2.py`) is a *single* CVA6+4-lane Ara on a trivial static-latency router — no
  NoC, one cluster. The RTL (`../../AZilla/hardware/`, NrClusters=4/NrLanes=4/512-bit AXI,
  `ara_dispatcher.sv` ~3288 lines) has no model counterpart. Budget **~1.5k–3k LOC net-new
  C++** + Python topology + validation. Behavioral timing is hand-picked (`set_latency(1/3)`
  literals) = designer intent, not RTL microarchitecture.
- **No NoC/DMA/vector power instrumentation** — running `teranoc`/`ara` reports 0 W / 0 J.
  A power framework exists in `engine/` but is unwired. *(fact-checked: CONFIRMED)* (SST
  doesn't give power for free either — shared gap, not a reason to switch.)
- **Immaturity / moving target:** `io_v2` port convention churning weekly, `GV_API_VERSION`
  at 6, no release tags, thin docs. TeraNoC L1 landed 2026-06-26. Pin SHAs for a campaign.

## 4. Mandatory conditions for proceeding with GVSoC-native

1. **Scope every DSE claim to knobs the model can see.** Green: topology, hop count, tile/
   cluster count, gross bandwidth, workload/mapping, functional correctness. **Red (do not
   publish native rankings): VC count, link/bisection width, routing algorithm, fine buffer
   depth, flow-control scheme.**
2. **Keep an RTL/Verilator fidelity anchor.** GVSoC *can* run a **self-contained** RTL SoC
   testbench (`VerilatorBoard`/`verilator.cpp`: firmware loaded via ELF→hex, memory internal
   to the RTL — matches `ara_tb_verilator.sv` **as-is**) under its own clock/GUI, no AXI
   surgery. Use that to validate the accelerator core **in isolation** on representative points.
   ⚠️ **Correction (verified):** GVSoC's Verilator glue exposes trace/VCD **signals**, *not*
   bindable AXI/IO ports into the interconnect. So co-simulating the RTL accelerator **against
   TeraNoC's memory system** needs the *same* AXI-exposure rework as the SST "A2" path
   (`../../modeling/ARAXL_SST_INTEGRATION.md §A2`). For that bound-in anchor, GVSoC and SST
   cost roughly the same — GVSoC does **not** obviate SST for the coupled-anchor role.
3. **Pin & freeze** all submodule SHAs for the campaign; re-validate the anchor if bumped.
4. **Power out of scope** unless funded (instrument + import measured pJ coefficients).
5. **Budget the accelerator model honestly** (~1.5k–3k LOC net-new; independently RTL-validated).
6. **Build a parallel sweep harness** (N processes across cores; `gvrun -j` is build-only) and
   time real workloads in the mode you'll actually run (stats/trace/power modes are multiples
   slower than the ~25 MIPS optimized figure).

## 5. When to (partially) involve SST — and how

- **If the DSE's *central* questions are VC / link-width / routing / fine-buffer NoC-micro-
  architecture rankings:** GVSoC-native is blind to these. Either extend the FlooNoC model,
  drive the axis via RTL (`--platform rtl`), or use SST `merlin` for a *generic* mesh (losing
  TeraNoC specificity). Decide by running a **remap-on/off sweep**: if the DSE winner does not
  reorder, TeraNoC's microarchitecture isn't load-bearing and generic merlin suffices.
- **If a multi-die / chiplet boundary enters the roadmap:** SST's MPI scale-out becomes relevant.
- **If you use SST with GVSoC, EMBED — don't port.** GVSoC ships a co-sim seam
  (`core/models/interco/router_proxy.cpp`, instantiated as `axi_proxy` in real chips;
  `gv/gvsoc.hpp` embedding API; `systemc_driver.cpp` precedent). This is post-DSE RTL
  verification, not DSE (RTL-in-SST is slow — wrong for sweeps). ⚠️ Verify a bindable proxy
  can sit at the **L1-mesh/tile** boundary (`teranoc_tile.py`) — it's proven only at the
  SoC-AXI boundary today. Note: the shipped SystemC embedding also reaches into engine-internal
  `Controller` APIs beyond the public `gvsoc.hpp`.

## 6. One-line bottom line

**Model natively in GVSoC for fast functional + coarse-timing sweeps (topology, tile count,
mapping, functional); validate the accelerator core against its RTL in isolation (GVSoC can
host the standalone RTL testbench directly); do not port the C++ models into SST. Reach for
SST only if your central DSE axis is NoC microarchitecture the FlooNoC model can't see
(VC/width/routing/buffer) or a multi-die scale-out — and even then, co-simulating RTL against
TeraNoC needs AXI surgery in either host, so pick the framework on other grounds, and if you
combine with GVSoC, embed it rather than extract it.**

> **Scope assumption:** this analysis treats "the custom accelerator" as the AraXL (CVA6+Ara)
> line, since that's the RTL in `../../AZilla/hardware/`. If the accelerator is a *distinct*
> block, the accelerator-modeling cost estimates (§3) change, but the platform decision does not.
