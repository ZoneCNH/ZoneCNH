# orderbook Gate Standard

`orderbook` v0.1.0 gate 以 runtime 本地命令为准。[FRAME, HIGH]

```bash
cd /home/workspace/orderbook
GOWORK=off go vet ./...
GOWORK=off go test ./...
bash scripts/boundary-gates.sh
bash scripts/replay-determinism-gate.sh
bash scripts/gap-injection-gate.sh
```

任一命令失败时，registry lifecycle 保持 proposed，不得升级 active。[FRAME, HIGH]

[RULES I BROKE]：无
