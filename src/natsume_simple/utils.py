import random
import numpy as np  # type: ignore
import torch  # type: ignore


def set_random_seed(seed: int = 42):
    """Set random seed for reproducibility across multiple libraries."""
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)
