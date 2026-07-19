import numpy as np
from .associative import AssociativeMemory
from .episodic import EpisodicMemory
from .cognitive_snapshot import CognitiveSnapshot

class MemoryExecutive:
    """The Hippocampus. Orchestrates both semantic and episodic memory."""
    def __init__(self, dim=384):
        self.dim = dim
        self.semantic = AssociativeMemory(dim)
        self.episodic = EpisodicMemory()
        
        # Start episode ID from the number of already loaded episodes
        self.next_episode_id = len(self.episodic.episodes)
        self.last_parent_id = self.next_episode_id - 1 if self.next_episode_id > 0 else None

    def process(self, stim_txt, resp_txt, stim_vec, resp_vec, use_associative=True, use_episodic=True) -> dict:
        """The core memory cycle, orchestrated by the Architect's Console."""
        
        resonance = 0.0
        learning_rate = 0.05 # Default if associative is off
        
        # 1. ASSOCIATIVE RECALL & DYNAMIC CURIOSITY
        if use_associative:
            assoc_field = self.semantic.recall(stim_vec)
            resonance = np.linalg.norm(assoc_field) / (np.linalg.norm(stim_vec) + 1e-9)
            # High resonance = Low LR. Low resonance = High LR.
            learning_rate = 0.01 + (0.1 * (1.0 - min(1.0, resonance / 100.0)))
        
        snapshot = None
        # 2. EPISODIC STORAGE (Factual Log)
        if use_episodic:
            snapshot = CognitiveSnapshot(
                id=self.next_episode_id, stimulus_text=stim_txt, response_text=resp_txt,
                stimulus_vector=stim_vec, response_vector=resp_vec, resonance=resonance,
                learning_rate=learning_rate, parent_id=self.last_parent_id
            )
            self.episodic.store(snapshot)
            self.last_parent_id = self.next_episode_id
            self.next_episode_id += 1
        
        # 3. SEMANTIC CONSOLIDATION (The Subconscious)
        if use_associative:
            self.semantic.store(stim_vec, resp_vec, learning_rate)
        
        return {
            "resonance": resonance,
            "learning_rate": learning_rate,
            "episode_id": snapshot.id if snapshot else -1
        }