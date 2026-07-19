import json
import os
import numpy as np
from .cognitive_snapshot import CognitiveSnapshot

class EpisodicMemory:
    """The Symbolic Storage (BEHM Engine). Stores discrete events."""
    def __init__(self, path="data/episodic_log.jsonl"):
        self.path = path
        self.episodes = {}
        self._load()

    def store(self, snapshot: CognitiveSnapshot):
        """Stores a complete cognitive snapshot as a discrete event."""
        self.episodes[snapshot.id] = snapshot
        self._append_to_log(snapshot)

    def retrieve(self, episode_id: int) -> CognitiveSnapshot:
        return self.episodes.get(episode_id)

    def _append_to_log(self, snapshot: CognitiveSnapshot):
        os.makedirs(os.path.dirname(self.path), exist_ok=True)
        with open(self.path, 'a') as f:
            data = snapshot.__dict__.copy()
            data['stimulus_vector'] = data['stimulus_vector'].tolist()
            data['response_vector'] = data['response_vector'].tolist()
            f.write(json.dumps(data) + '\n')

    def _load(self):
        if not os.path.exists(self.path): return
        with open(self.path, 'r') as f:
            for line in f:
                data = json.loads(line)
                data['stimulus_vector'] = np.array(data['stimulus_vector'], dtype=np.float32)
                data['response_vector'] = np.array(data['response_vector'], dtype=np.float32)
                snapshot = CognitiveSnapshot(**data)
                self.episodes[snapshot.id] = snapshot