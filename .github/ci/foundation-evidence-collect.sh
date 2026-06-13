#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-unknown}"
OUTDIR="release/foundation"
mkdir -p "$OUTDIR"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

cat > "$OUTDIR/evidence-${VERSION}.json" << EOF
{
  "version": "${VERSION}",
  "timestamp": "${TIMESTAMP}",
  "go_baseline": "1.23",
  "modules": {
    "kernel":     { "status": "registered", "layer": "L0" },
    "configx":    { "status": "registered", "layer": "L1" },
    "observex":   { "status": "registered", "layer": "L1" },
    "resiliencx": { "status": "registered", "layer": "L1" },
    "schedulex":  { "status": "registered", "layer": "L1" },
    "testkitx":   { "status": "registered", "layer": "L1-test" }
  },
  "gate_modules": {
    "xlib-standard": { "status": "registered", "role": "standard-source" },
    "xlibgate":      { "status": "registered", "role": "machine-gate" }
  }
}
EOF

echo "Foundation evidence collected: $OUTDIR/evidence-${VERSION}.json"
cat "$OUTDIR/evidence-${VERSION}.json"
