import torch
from transformers import AutoTokenizer, AutoModelForCausalLM

class ResponseGenerator:
    """The Cortical Engine. Translates math into human narrative."""
    def __init__(self, model_id="microsoft/Phi-3.5-mini-instruct"):
        print("[System] Loading Cortical Engine (Phi-3.5)...")
        self.tokenizer = AutoTokenizer.from_pretrained(model_id)
        self.model = AutoModelForCausalLM.from_pretrained(
            model_id,
            device_map="auto",
            torch_dtype=torch.float16,
            trust_remote_code=True,
            low_cpu_mem_usage=True
        )
        if self.tokenizer.pad_token is None:
            self.tokenizer.pad_token = self.tokenizer.eos_token
        print("[System] Cortical Engine Online.")

    def generate(self, prompt: str, max_tokens=250) -> str:
        inputs = self.tokenizer(prompt, return_tensors="pt").to(self.model.device)
        with torch.no_grad():
            outputs = self.model.generate(
                **inputs,
                max_new_tokens=max_tokens,
                temperature=0.7,
                do_sample=True,
                pad_token_id=self.tokenizer.eos_token_id
            )
        response = self.tokenizer.decode(outputs[0][inputs.input_ids.shape[1]:], skip_special_tokens=True)
        return response