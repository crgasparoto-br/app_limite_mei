#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "== Preflight de publicação Google Play =="

pass() { echo "✅ $1"; }
warn() { echo "⚠️  $1"; }
fail() { echo "❌ $1"; }

missing=0

if [[ -f android/key.properties ]]; then
  pass "android/key.properties encontrado"
else
  fail "android/key.properties ausente"
  missing=1
fi

if [[ -f android/upload-keystore.jks ]]; then
  pass "android/upload-keystore.jks encontrado"
else
  warn "android/upload-keystore.jks não encontrado no repositório (normal se armazenado fora)"
fi

if [[ -f build/app/outputs/bundle/release/app-release.aab ]]; then
  pass "AAB release encontrado"
else
  warn "AAB release ainda não gerado"
fi

if command -v flutter >/dev/null 2>&1; then
  pass "Flutter disponível no ambiente"
else
  warn "Flutter não disponível neste ambiente"
fi

if rg -n "applicationId = \"br.com.limitemei\"" android/app/build.gradle.kts >/dev/null; then
  pass "applicationId configurado para br.com.limitemei"
else
  fail "applicationId não está em br.com.limitemei"
  missing=1
fi

if [[ $missing -eq 1 ]]; then
  echo "\nStatus: ajustes obrigatórios pendentes."
  exit 1
fi

echo "\nStatus: pré-requisitos obrigatórios básicos atendidos (com avisos opcionais)."
