#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for archive in faiss_riscv64.tar.gz openblas_riscv64.tar.gz; do
  if [ -f "$SCRIPT_DIR/$archive" ]; then
    echo "Extracting $archive ..."
    tar xzf "$SCRIPT_DIR/$archive" -C /
  fi
done

export LD_LIBRARY_PATH="/usr/lib/riscv64-linux-gnu/openblas-pthread:${LD_LIBRARY_PATH:-}"
export PYTHONPATH="/usr/local/lib/python3.13/dist-packages/faiss-1.14.1-py3.13.egg:${PYTHONPATH:-}"

echo "Running FAISS smoke test on HPSC (RISC-V) ..."
python3 - <<'PYEOF'
import faiss
import numpy as np

d, n = 64, 1000
xb = np.random.rand(n, d).astype("float32")
xq = np.random.rand(5, d).astype("float32")

index = faiss.IndexFlatL2(d)
index.add(xb)
D, I = index.search(xq, 4)

assert I.shape == (5, 4)
print(f"✓ FAISS {faiss.__version__} running on HPSC (RISC-V)")
print(f"  index size: {index.ntotal} vectors, dim: {d}")
print(f"  search results shape: {I.shape}")
PYEOF
