# syntax=docker/dockerfile:1
# Builds Faiss C++ library (+ Python bindings) for RISC-V 64-bit (riscv64).
#
# Build:
#   docker buildx build --platform linux/riscv64 \
#     -t faiss:riscv64 -f docker/riscv64/Dockerfile .
#
# Run Python tests:
#   docker run --rm --platform linux/riscv64 faiss:riscv64 \
#     pytest /faiss/tests/test_*.py
#
# Interactive shell:
#   docker run --rm -it --platform linux/riscv64 faiss:riscv64 bash

FROM --platform=linux/riscv64 ubuntu:25.04

ENV DEBIAN_FRONTEND=noninteractive

# ── Build dependencies ────────────────────────────────────────────────────────
# cmake 3.28 ships with Ubuntu 24.04, satisfying Faiss's ≥3.24 requirement.
# OpenBLAS is the only viable BLAS on RISC-V (MKL is Intel-only).
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        libopenblas-dev \
        python3 \
        python3-dev \
        python3-numpy \
        python3-pytest \
        python3-scipy \
        python3-setuptools \
        swig \
    && rm -rf /var/lib/apt/lists/*

# ── Source ────────────────────────────────────────────────────────────────────
WORKDIR /faiss
COPY . .

# ── Configure ─────────────────────────────────────────────────────────────────
# FAISS_OPT_LEVEL=generic    — no AVX/SVE on baseline riscv64.
# FAISS_ENABLE_GPU=OFF       — CUDA/ROCm not available on riscv64.
# BLA_VENDOR=OpenBLAS        — use OpenBLAS instead of MKL.
# BUILD_TESTING=OFF          — skip C++ test and perf_test targets; those pull
#   googletest/googlebenchmark via git FetchContent which requires SSL certs not
#   present in the minimal QEMU-emulated build environment. Python tests
#   (pytest /faiss/tests/test_*.py) cover the same functionality.
# FAISS_ENABLE_EXTRAS=OFF    — skip demos/benchs/tutorial C++ targets.
RUN cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=OFF \
        -DBUILD_SHARED_LIBS=ON \
        -DFAISS_ENABLE_GPU=OFF \
        -DFAISS_ENABLE_PYTHON=ON \
        -DFAISS_ENABLE_C_API=ON \
        -DFAISS_ENABLE_EXTRAS=OFF \
        -DFAISS_OPT_LEVEL=generic \
        -DBLA_VENDOR=OpenBLAS \
        .

# ── Build C++ library ─────────────────────────────────────────────────────────
RUN make -C build -j"$(nproc)" faiss faiss_c

# ── Build Python extension ────────────────────────────────────────────────────
RUN make -C build -j"$(nproc)" swigfaiss \
    && cd build/faiss/python \
    && python3 setup.py install

# ── Smoke test ────────────────────────────────────────────────────────────────
RUN python3 - <<'EOF'
import faiss, numpy as np
d, n = 64, 1000
xb = np.random.rand(n, d).astype("float32")
xq = np.random.rand(5, d).astype("float32")
index = faiss.IndexFlatL2(d)
index.add(xb)
D, I = index.search(xq, 4)
assert I.shape == (5, 4), "unexpected result shape"
print(f"faiss {faiss.__version__} riscv64 smoke test passed — index size {index.ntotal}")
EOF

# Default command runs the Python test suite
CMD ["sh", "-c", "pytest /faiss/tests/test_*.py -v"]
