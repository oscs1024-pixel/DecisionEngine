# Converting decider-2b for MLX

The reference repository publishes standard Hugging Face safetensors for a Qwen3.5 text model. Current mlx-swift-lm registers both qwen3_5 and qwen3_5_text, and can load a local MLX model directory with ModelConfiguration(directory:).

Recommended conversion workflow on an Apple Silicon development machine:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -U mlx-lm transformers
mlx_lm.convert --hf-path Mapika/decider-2b --mlx-path Models/decider-2b-4bit -q --q-bits 4
```

Before using the converted checkpoint for routing or approval:

1. retain config.json and tokenizer files;
2. confirm model_type resolves to qwen3_5_text (or another registered Qwen3.5 type);
3. export BF16 reference fixtures with Scripts/export_parity.py;
4. run the same prompts through the Swift MLX backend;
5. compare token IDs, answer-slot positions, label-token IDs and probabilities;
6. do not enable semantic auto-approval unless parity is within the configured tolerance.

The reference model documents 2–10 options per question. Keep production questions inside that trained range even though LabelVocabulary can encode larger sets for future backends.
