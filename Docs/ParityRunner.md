# Reference parity runner

Use the checkpoint's bundled Python helper as the reference implementation.

The published model contract specifies Qwen3.5-2B-Base, one forward pass for all question slots, logits read at each open-parenthesis answer slot, option labels mapped through the tokenizer, and softmax only across valid label-token logits. The published calibration temperature is 1.05 and the trained context limit is 1536 tokens.

A parity fixture should export the rendered prompt, token IDs, answer positions, label token IDs and calibrated probabilities. Swift must match those values within fixture tolerance before semantic auto-approval is enabled.

Do not compare only argmax labels: probability parity matters because routing and approval thresholds consume confidence directly.
