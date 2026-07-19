#!/usr/bin/env python3
import argparse
import os
import time
import torch
import numpy as np
from sentence_transformers import SentenceTransformer
from kailos_core.llm import ResponseGenerator
from kailos_core.memory.memory_executive import MemoryExecutive

# --- v13.2: ARCHITECT'S CONSOLE STATE ---
class ConsoleState:
    def __init__(self):
        self.verbose_logging = False
        self.associative_memory_on = True
        self.episodic_memory_on = True

def main():
    parser = argparse.ArgumentParser(
        description="Kailos-Omega Prime v13.2: Architect's Console.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("command", nargs='?', default="interact", help="Commands: interact, status, reset, run")
    parser.add_argument("-n", "--ticks", type=int, default=10, help="Ticks for 'run' simulation.")
    args = parser.parse_args()

    if args.command == "interact":
        run_interactive_loop()
    elif args.command == "status":
        run_status_check(None) # Call without a live instance just to show basic paths
    elif args.command == "reset":
        run_reset()
    elif args.command == "run":
        run_simulation(args.ticks)

def run_interactive_loop():
    print("Initializing Unified Memory Substrate (v13.2)...")
    encoder = SentenceTransformer('all-MiniLM-L6-v2')
    memory = MemoryExecutive()
    generator = ResponseGenerator()
    console_state = ConsoleState()
    
    print("\n" + "="*70)
    print(" KAILOS-OMEGA PRIME v13.2 (Architect's Console) IS AWAKE")
    print(" Type 'help' for a list of architect commands. Type 'exit' to hibernate.")
    print("="*70)

    while True:
        try:
            # VRAM Hygiene Protocol
            torch.cuda.empty_cache()
            
            user_input = input("\nArchitect> ").strip()
            if not user_input: continue
            
            # --- ARCHITECT COMMAND HANDLER ---
            if handle_architect_commands(user_input, memory, console_state):
                continue
            
            # --- PERCEPTION ---
            stimulus_vec = encoder.encode(user_input, normalize_embeddings=True)
            
            # --- CORTICAL GENERATION ---
            prompt = f"<|system|>You are Kailos v13.2. You possess a dual-memory cognitive architecture.<|end|><|user|>{user_input}<|end|><|assistant|>"
            response_text = generator.generate(prompt)
            response_vec = encoder.encode(response_text, normalize_embeddings=True)
            
            print(f"Kailos: {response_text}")

            # --- MEMORY EXECUTIVE CYCLE ---
            if console_state.associative_memory_on or console_state.episodic_memory_on:
                telemetry = memory.process(
                    stim_txt=user_input, resp_txt=response_text,
                    stim_vec=stimulus_vec, resp_vec=response_vec,
                    use_associative=console_state.associative_memory_on,
                    use_episodic=console_state.episodic_memory_on
                )
                
                # --- TELEMETRY REPORTING ---
                if console_state.verbose_logging:
                    print("\n--- [VERBOSE TELEMETRY] ---")
                    print(f"  Stimulus Vector Norm : {np.linalg.norm(stimulus_vec):.4f}")
                    print(f"  Response Vector Norm : {np.linalg.norm(response_vec):.4f}")
                    print(f"  Resonance            : {telemetry['resonance']:.4f}")
                    print(f"  Learning Rate        : {telemetry['learning_rate']:.4f}")
                    print(f"  New Episodic ID      : {telemetry['episode_id']}")
                    print("---------------------------")
                else:
                    ep_str = telemetry['episode_id'] if telemetry['episode_id'] != -1 else "OFF"
                    print(f"[Memory Cycle: Ep#{ep_str} | Res:{telemetry['resonance']:.2f} | LR:{telemetry['learning_rate']:.4f}]")

        except KeyboardInterrupt:
            break
    print("\n[System] Hibernation sequence initiated. Substrates secure.")

def handle_architect_commands(cmd: str, mem: MemoryExecutive, state: ConsoleState) -> bool:
    cmd_lower = cmd.lower()
    
    if cmd_lower in ["exit", "quit", "hibernate"]:
        raise KeyboardInterrupt

    if cmd_lower == 'help':
        print("\n--- Architect Console Commands ---")
        print("  help              - Show this help message.")
        print("  status            - Show detailed status of memory components.")
        print("  log on/off        - Toggle verbose telemetry logging.")
        print("  assoc on/off      - Toggle the Associative (Hebbian) memory.")
        print("  episodic on/off   - Toggle the Episodic (Snapshot) memory.")
        print("  tune decay <val>  - Set associative decay (e.g., 0.99).")
        print("  snapshot          - Save a .npz snapshot of the current memory matrix.")
        print("--------------------------------")
        return True
        
    if cmd_lower == 'status':
        run_status_check(mem)
        return True

    if cmd_lower == 'log on':
        state.verbose_logging = True
        print("[Console] Verbose logging ENABLED.")
        return True
    if cmd_lower == 'log off':
        state.verbose_logging = False
        print("[Console] Verbose logging DISABLED.")
        return True
        
    if cmd_lower == 'assoc on':
        state.associative_memory_on = True
        print("[Console] Associative Memory ENABLED.")
        return True
    if cmd_lower == 'assoc off':
        state.associative_memory_on = False
        print("[Console] Associative Memory DISABLED.")
        return True

    if cmd_lower == 'episodic on':
        state.episodic_memory_on = True
        print("[Console] Episodic Memory ENABLED.")
        return True
    if cmd_lower == 'episodic off':
        state.episodic_memory_on = False
        print("[Console] Episodic Memory DISABLED.")
        return True

    if cmd_lower.startswith('tune decay '):
        try:
            val = float(cmd.split(' ')[-1])
            if 0.0 <= val <= 1.0:
                mem.semantic.decay = val
                print(f"[Console] Associative decay tuned to {val:.4f}.")
            else: print("[Error] Decay must be between 0.0 and 1.0.")
        except ValueError: print("[Error] Invalid decay value.")
        return True
        
    if cmd_lower == 'snapshot':
        timestamp = time.strftime("%Y%m%d-%H%M%S")
        os.makedirs("data", exist_ok=True)
        path = f"data/snapshot_matrix_{timestamp}.npz"
        np.savez_compressed(path, H=mem.semantic.H)
        print(f"[Console] Snapshot of Associative Matrix saved to '{path}'.")
        return True

    return False

def run_status_check(mem_instance=None):
    print("\n--- Kailos v13.2 Substrate Status ---")
    if mem_instance:
        matrix_norm = np.linalg.norm(mem_instance.semantic.H, ord=2)
        print(f"  Associative Path      : {mem_instance.semantic.path}")
        print(f"  Associative Norm      : {matrix_norm:.6f}")
        print(f"  Associative Decay Rate: {mem_instance.semantic.decay:.4f}")
        print(f"  Episodic Path         : {mem_instance.episodic.path}")
        print(f"  Total Episodes Stored : {len(mem_instance.episodic.episodes)}")
    else:
        print("  Status: Offline (Launch 'interact' to load matrix into RAM).")
    print("------------------------------------")

def run_reset():
    assoc_path = "data/associative_matrix.npz"
    episodic_path = "data/episodic_log.jsonl"
    confirm = input("WARNING: This will delete ALL memory. Are you sure? (y/n): ")
    if confirm.lower() == 'y':
        if os.path.exists(assoc_path): os.remove(assoc_path)
        if os.path.exists(episodic_path): os.remove(episodic_path)
        print("[System] All cognitive substrates have been reset.")

def run_simulation(ticks):
    print(f"\n[System] Running non-interactive simulation for {ticks} ticks...")
    encoder = SentenceTransformer('all-MiniLM-L6-v2')
    memory = MemoryExecutive()
    for i in range(ticks):
        stim_text = f"Automated stimulus {i}: The sequence continues."
        resp_text = f"Internal response {i}: Observing the pattern."
        stim_vec = encoder.encode(stim_text, normalize_embeddings=True)
        resp_vec = encoder.encode(resp_text, normalize_embeddings=True)
        telemetry = memory.process(stim_text, resp_text, stim_vec, resp_vec)
        print(f"[Tick {i+1}] Ep#{telemetry['episode_id']} | Res: {telemetry['resonance']:.2f}")
    print("[System] Simulation complete.")

if __name__ == "__main__":
    main()