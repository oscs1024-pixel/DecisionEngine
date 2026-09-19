# DecisionEngine

Swift 6 local decision layer for coding agents: model routing, fail-closed tool approval, structured quality review, decision logging, and an MCP integration surface.

## Status

Initial implementation. The core is backend-neutral and testable with a mock decision actor. A production MLX adapter should be bound to the exact tokenizer, answer-slot convention, and MLX Swift APIs of the checkpoint/version you deploy.

## Architecture

```
Coding Agent (Think -> Do -> See)
          |
          v
+-----------------------------+
| Decision Router             |
| 1. Hard deterministic rules |
| 2. Local semantic decision  |
| 3. Confidence route policy  |
+-----------------------------+
     |                 |
     v                 v
Approval Gate      Model Tier
                 Luna / Sol / Astra
```

Low-confidence routing falls back to the middle tier. Safety is fail-closed: hard policy violations never reach the semantic model and uncertain semantic approvals are not auto-approved.

## Run tests

```bash
swift test
```

See `Config/` for example routing and safety policies.


## MCP server

The feature branch includes the official Model Context Protocol Swift SDK and registers `route_turn`, `approve_command`, and `score_quality` over stdio. Until a compatible local inference backend is configured, semantic calls return an explicit error; deterministic hard safety blocks remain available.

## decider-2b integration

See `Docs/MLXIntegration.md`. The reference checkpoint uses Qwen3.5-2B-Base and classifies from option-label logits at answer slots rather than generating JSON. The MLX adapter must preserve that mechanism and pass parity fixtures before semantic auto-approval is enabled.
