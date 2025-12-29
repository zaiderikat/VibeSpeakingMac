#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WHISPER_DIR="$ROOT_DIR/third_party/whisper.cpp"
BUILD_DIR="$WHISPER_DIR/build"
OUT_INCLUDE="$ROOT_DIR/VoiceVibing/Whisper/include"
OUT_LIB="$ROOT_DIR/VoiceVibing/Whisper/lib"

cmake -S "$WHISPER_DIR" -B "$BUILD_DIR" -DGGML_METAL=OFF -DBUILD_SHARED_LIBS=OFF
cmake --build "$BUILD_DIR" --config Release

mkdir -p "$OUT_INCLUDE" "$OUT_LIB"

cp "$WHISPER_DIR/include/whisper.h" "$OUT_INCLUDE/"
cp "$WHISPER_DIR/ggml/include/ggml.h" "$OUT_INCLUDE/"
cp "$WHISPER_DIR/ggml/include/ggml-alloc.h" "$OUT_INCLUDE/"
cp "$WHISPER_DIR/ggml/include/ggml-backend.h" "$OUT_INCLUDE/"
cp "$WHISPER_DIR/ggml/include/ggml-cpu.h" "$OUT_INCLUDE/"

cp "$BUILD_DIR/src/libwhisper.a" "$OUT_LIB/"
cp "$BUILD_DIR/ggml/src/libggml.a" "$OUT_LIB/"
cp "$BUILD_DIR/ggml/src/libggml-base.a" "$OUT_LIB/"
cp "$BUILD_DIR/ggml/src/libggml-cpu.a" "$OUT_LIB/"
cp "$BUILD_DIR/ggml/src/ggml-blas/libggml-blas.a" "$OUT_LIB/" || true

echo "whisper.cpp build complete: $OUT_LIB"
