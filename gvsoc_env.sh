# Convenience wrapper — prefer just `conda activate gvsoc`.
#   source gvsoc_env.sh   ==   conda activate gvsoc
#   gvrun --target ara_v2 --param soc/binary=$PWD/pulp/examples/rvv_fconv2d run
#
# The `gvsoc` conda env (cloned 2026-07-08 from `teranoc`, which stays shared with
# the ising project) now self-configures on activation: its activate.d hook puts
# gvrun on PATH and sets LD_LIBRARY_PATH (conda's libstdc++/libz + this checkout's
# install/lib). So activation alone is sufficient — this file just does that.
source "$HOME/miniforge3/etc/profile.d/conda.sh"
conda activate gvsoc

# For rebuilding models:
#   export CMAKE_FLAGS='-j8' CXX=x86_64-conda-linux-gnu-g++ CC=x86_64-conda-linux-gnu-gcc
#   export LIBRARY_PATH="$CONDA_PREFIX/lib:$LIBRARY_PATH"
#   make build TARGETS='ara_v2 teranoc'

echo "GVSoC env ready (conda env: gvsoc, python $(python --version 2>&1 | awk '{print $2}'))."
echo "Run e.g.:  gvrun --target ara_v2 --param soc/binary=\$PWD/pulp/examples/rvv_fconv2d run"
