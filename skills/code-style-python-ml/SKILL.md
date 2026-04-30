---
name: code-style-python-ml
description: Python code style conventions for ML/AI code — type hints, error handling, paths, reproducibility. Auto-invoked when writing or editing Python files in ML/data science contexts.
---

# Python ML Code Style

When writing or editing Python code in ML/AI contexts, follow these conventions:

## Type hints
- Public functions and class methods MUST have type hints on parameters and return type
- Use `from __future__ import annotations` if targeting Python <3.10 with newer hint syntax
- For tensors, prefer hints like `torch.Tensor` or `np.ndarray` rather than generic `Any`

## Error handling
- Never use bare `except:` — always specify the exception type
- Catch specific exceptions, not `Exception`, unless re-raising
- When swallowing an exception is intentional, log at WARN level with context

## Paths
- Use `pathlib.Path` for filesystem paths, not strings
- Never concatenate paths with `+` or `os.path.join` in new code
- Use `Path.read_text()`, `Path.write_text()` for simple I/O

## Docstrings
- Public functions need docstrings
- Format: one-line summary, blank line, optional details, `Args:` / `Returns:` / `Raises:` sections when non-obvious
- Skip docstrings only on trivial private helpers

## Reproducibility (critical for ML)
- Pin random seeds in any training, sampling, or stochastic code
- Set seeds for: `random`, `numpy`, `torch` (CPU and CUDA if applicable)
- Document non-deterministic operations (`torch.use_deterministic_algorithms(True)` if reproducibility is required)
- Record framework versions and hardware in experiment configs

## What to avoid
- Mutable default arguments (`def foo(x=[]):` is a bug magnet)
- Global state for anything but constants
- `from module import *`
- Print statements for logging — use `logging` or `structlog`

## Example: minimal compliant function

```python
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

def load_dataset(path: Path, max_rows: int | None = None) -> list[dict]:
    """Load JSON-lines dataset from disk.
    
    Args:
        path: Path to .jsonl file
        max_rows: If set, return at most this many rows
    Returns:
        List of parsed records
    Raises:
        FileNotFoundError: If path does not exist
    """
    if not path.exists():
        raise FileNotFoundError(f"Dataset not found: {path}")
    rows = []
    with path.open() as f:
        for i, line in enumerate(f):
            if max_rows is not None and i >= max_rows:
                break
            rows.append(json.loads(line))
    return rows
```
