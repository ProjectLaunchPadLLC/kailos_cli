from dataclasses import dataclass, field
from typing import List, Optional
import numpy as np
import time

@dataclass
class CognitiveSnapshot:
    """A complete, discrete record of a single cognitive event."""
    id: int
    timestamp: float = field(default_factory=time.time)
    stimulus_text: str
    response_text: str
    stimulus_vector: np.ndarray
    response_vector: np.ndarray
    resonance: float
    learning_rate: float
    importance: float = 0.5
    tags: List[str] = field(default_factory=list)
    parent_id: Optional[int] = None