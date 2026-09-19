# MLX backend integration

The upstream `Mapika/decider-2b` checkpoint is based on Qwen3.5-2B-Base and performs classification by reading logits at each `Answer: (` slot. Each option is mapped to a label token (A, B, C, ...), and probabilities are computed only over those label-token logits.

## Compatibility status

As of September 2026, current `mlx-swift-lm` 3.x documents Qwen families it supports, but a production `Qwen3.5` text model path should be verified against the exact converted checkpoint before adding it as a package dependency. The repository therefore keeps `DecisionEngineCore` independent from MLX and does not pretend a normal chat-generation API is equivalent to decider inference.

## Required MLX adapter contract

A concrete `MLXDecisionEngine` must:

1. load an MLX-converted decider checkpoint;
2. validate that every option label maps to exactly one token;
3. render all questions with stable `Answer N: (` slots;
4. tokenize the complete prompt once;
5. identify answer-slot token indices from tokenized structure, not character offsets;
6. run one model forward pass;
7. gather the logits at every answer slot;
8. select only valid label-token logits and softmax those values;
9. map distributions to `DecisionAnswer`;
10. normalize Score values to 0...1 before routing;
11. evaluate lazy MLX arrays before reading results;
12. keep model/container/cache state actor-isolated.

Do not substitute text generation + JSON parsing: that changes the decision mechanism and calibration characteristics.

## Model conversion

The Hugging Face checkpoint is BF16. Conversion to MLX must preserve the Qwen3.5 architecture. Validate the converted model with parity fixtures against the reference Python implementation before enabling automatic safety approval.

Recommended parity fixture fields:

- exact rendered prompt
- token IDs
- answer-slot token positions
- label token IDs
- probability distribution per question
- argmax choice and confidence

Safety approval should remain fail-closed until parity tests pass.
