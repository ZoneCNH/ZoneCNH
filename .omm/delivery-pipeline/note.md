可执行入口 goal-workflow.sh 提供 5 种剖面：preflight（工具/规则自检，不推进状态）、validate（+ 控制面严格校验 + Matrix check-only）、gate（+ Gate 制品就绪检查）、ci（+ 工具链自测，PR/CI 默认）、release（+ Release hard blocker，通过后可写 Release Gate manifest）。

gate-check.sh（9.6k）执行单 Gate 检查；goal-validate.py（55k）做控制面校验；matrix-gen.py（22k）生成追溯矩阵；rule-drift-check.py（32k）检测规则漂移；rsi-trigger.py（18k）触发受控递归改进；spec-lint.py（9.4k）规格 lint。控制面数据落 .config/goal/{gates,matrix,pipeline,registry,schema,eval,evidence,metrics}。
