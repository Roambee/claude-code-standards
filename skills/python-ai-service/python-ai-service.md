# python-ai-service

Use when building or editing a FastAPI AI microservice in `packages/ai/`.

**Announce at start:** "Loading python-ai-service standards."

---

## Service Structure

Every AI service must follow this layout:

```
packages/ai/<service-name>/
├── main.py                  # FastAPI app instantiation + router registration
├── pyproject.toml           # Python version pin + dependencies
├── routers/
│   └── <resource>.py        # Route handlers — thin, no business logic
├── services/
│   └── <resource>_service.py  # Business logic + LLM calls
├── models/
│   ├── requests.py          # Pydantic request models
│   └── responses.py         # Pydantic response models
├── prompts/
│   └── <feature-name>.md    # Prompt files — versioned, not inline strings
└── tests/
    ├── unit/
    └── integration/
```

## Pydantic for Everything

No raw dicts in request/response handling.

```python
from pydantic import BaseModel, Field
from typing import Optional

class ClassifyShipmentRequest(BaseModel):
    description: str = Field(..., min_length=1, max_length=2000)
    tracking_number: Optional[str] = None

class ClassifyShipmentResponse(BaseModel):
    status: str
    confidence: float = Field(..., ge=0.0, le=1.0)
    reasoning: str
```

## Async/Await for All LLM Calls

Never block the event loop.

```python
# ✅ Correct
async def classify(request: ClassifyShipmentRequest) -> ClassifyShipmentResponse:
    result = await llm_service.complete(prompt, model=model)
    return ClassifyShipmentResponse(**result)

# ❌ Wrong — blocks the event loop
def classify(request: ClassifyShipmentRequest) -> ClassifyShipmentResponse:
    result = requests.post(openrouter_url, json=payload)  # blocking HTTP
    ...
```

## Health Check (Required)

Every service must expose `GET /health`:

```python
@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "shipment-classifier"}
```

## Python Version Pinning

`pyproject.toml`:
```toml
[project]
name = "shipment-classifier"
version = "0.1.0"
requires-python = "==3.11.*"

[tool.uv]
dev-dependencies = ["pytest", "pytest-asyncio", "httpx"]
```

Use `uv` for dependency management:
```bash
uv sync          # install dependencies
uv add httpx     # add a dependency
```

## Dependency Management

Use `uv` (preferred). If not available, use a pinned `requirements.txt`:
```bash
uv export --no-hashes > requirements.txt
```

Never use unpinned `requirements.txt` — it breaks reproducibility.
