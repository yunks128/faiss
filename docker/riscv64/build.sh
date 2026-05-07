#!/usr/bin/env bash
# Build and optionally run the Faiss RISC-V Docker image.
# Must be run from the repository root.
#
# Usage:
#   ./docker/riscv64/build.sh            # build image
#   ./docker/riscv64/build.sh test       # build + run C++ & Python tests
#   ./docker/riscv64/build.sh shell      # build + interactive shell

set -euo pipefail

IMAGE="faiss:riscv64"
PLATFORM="linux/riscv64"
DOCKERFILE="docker/riscv64/Dockerfile"

cd "$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

echo "==> Building $IMAGE for $PLATFORM …"
docker buildx build \
    --platform "$PLATFORM" \
    --load \
    -t "$IMAGE" \
    -f "$DOCKERFILE" \
    .

echo "==> Build complete: $IMAGE"

case "${1:-}" in
  test)
    echo "==> Running Python tests …"
    docker run --rm --platform "$PLATFORM" "$IMAGE" \
        sh -c "pytest /faiss/tests/test_*.py -v"
    ;;
  shell)
    docker run --rm -it --platform "$PLATFORM" "$IMAGE" bash
    ;;
esac
