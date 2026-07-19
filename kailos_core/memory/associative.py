import numpy as np
import os

class AssociativeMemory:
    """The Hebbian Manifold (Semantic Memory). Stores relationships."""
    def __init__(self, dim=384, decay=0.995, path="data/associative_matrix.npz"):
        self.dim = dim
        self.decay = decay
        self.path = path
        if os.path.exists(self.path):
            self.H = np.load(self.path)['H']
        else:
            self.H = np.zeros((dim, dim), dtype=np.float32)

    def store(self, stimulus_vec: np.ndarray, response_vec: np.ndarray, learning_rate: float):
        """Engraves the relationship between a stimulus and a response."""
        self.H = (self.decay * self.H) + (np.outer(response_vec, stimulus_vec) * learning_rate)
        self._save()

    def recall(self, stimulus_vec: np.ndarray) -> np.ndarray:
        """Given a stimulus, retrieves the associated response field."""
        return self.H @ stimulus_vec

    def _save(self):
        os.makedirs(os.path.dirname(self.path), exist_ok=True)
        np.savez_compressed(self.path, H=self.H)