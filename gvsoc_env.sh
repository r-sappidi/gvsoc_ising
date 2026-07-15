# Convenience wrapper: activate the build/run env + set up gvrun's runtime paths.
#   source gvsoc_env.sh
#   gvrun --target teranoc --param binary=<elf> run
#
# The `azilla` conda env (see ../AZilla-Sim/environment.yml) provides the conda gcc-15
# toolchain + Python. gvrun needs its install on PATH and conda's libstdc++ + the model
# .so's on LD_LIBRARY_PATH — set explicitly here (no reliance on a machine-local hook).
source "$(conda info --base 2>/dev/null || echo "$HOME/miniforge3")/etc/profile.d/conda.sh"
conda activate azilla

GVSOC_HOME="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$GVSOC_HOME/sourceme.sh" 2>/dev/null || export PATH="$GVSOC_HOME/install/bin:$PATH"
export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:$GVSOC_HOME/install/lib:$LD_LIBRARY_PATH"

# For rebuilding models:
#   export CMAKE_FLAGS='-j8' LIBRARY_PATH="$CONDA_PREFIX/lib:$LIBRARY_PATH"
#   make build TARGETS='teranoc'

echo "GVSoC env ready (conda env: azilla, python $(python --version 2>&1 | awk '{print $2}'))."
