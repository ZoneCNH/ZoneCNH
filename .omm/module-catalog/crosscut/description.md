横切 crosscut，2 模块。alertx（策略异常、风控触发告警）和 x.go（治理/工具 CLI，点号为设计标识，命名例外）。二者贯穿所有领域。observex 同时作为基座组件（foundation）提供底层 metrics/tracing/logging 能力，故其横切角色与基座角色重叠。
