# Gap Injection Gate

注入 missing、out-of-order 或 broken prev sequence 时，ReplayRunner 必须返回 GapEvent 且最终 quality `reliable=false`。[FRAME, HIGH]

执行命令：

```bash
bash scripts/gap-injection-gate.sh
```

[RULES I BROKE]：无
