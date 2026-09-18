#!/usr/bin/env python3
"""Export reference decider probabilities for Swift parity tests."""
import argparse, json, torch
from transformers import AutoModelForCausalLM, AutoTokenizer

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--model", default="Mapika/decider-2b")
    p.add_argument("--input", required=True, help="JSON containing prompt and slots")
    p.add_argument("--output", required=True)
    p.add_argument("--temperature", type=float, default=1.05)
    args=p.parse_args()
    spec=json.load(open(args.input))
    tok=AutoTokenizer.from_pretrained(args.model)
    model=AutoModelForCausalLM.from_pretrained(args.model, dtype=torch.bfloat16).eval()
    ids=tok(spec["prompt"], return_tensors="pt")["input_ids"]
    with torch.no_grad():
        logits=model(input_ids=ids).logits[0]
    out={"model":args.model,"prompt":spec["prompt"],"tokenIds":ids[0].tolist(),"questions":[],"temperature":args.temperature}
    for slot in spec["slots"]:
        prefix=spec["prompt"][:slot["characterEnd"]]
        pos=len(tok(prefix, add_special_tokens=True)["input_ids"])-1
        label_ids=[]
        for label in slot["labels"]:
            encoded=tok.encode(label, add_special_tokens=False)
            if len(encoded)!=1: raise ValueError(f"label {label!r} is not one token: {encoded}")
            label_ids.append(encoded[0])
        selected=logits[pos, label_ids].float()/args.temperature
        probs=torch.softmax(selected,-1).tolist()
        out["questions"].append({"id":slot["id"],"answerSlotTokenIndex":pos,"labels":slot["labels"],"labelTokenIds":label_ids,"referenceProbabilities":probs})
    json.dump(out,open(args.output,"w"),indent=2)

if __name__=="__main__": main()
