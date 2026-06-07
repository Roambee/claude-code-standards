# Roambee Claude Plugin — P5: AI Standards Skills

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task.

**Goal:** Write the 4 AI developer standards skills: `python-ai-service`, `ai-testing`, `agentic-standards`, `provider-abstraction`.

**Architecture:** All skills are markdown files. These skills are context-injected when Claude detects AI-related work (Hook 9 fires on `packages/ai/**`). `provider-abstraction` is the most frequently used — it gates all LLM integration code.

**Prerequisite:** P1 complete — plugin directory structure exists.

**Design spec reference:** AI Developer Skills section of `2026-06-06-roambee-claude-standards-plugin-design.md`

---

## File Map

| Action | Path |
|--------|------|
| Create | `skills/python-ai-service/python-ai-service.md` |
| Create | `skills/ai-testing/ai-testing.md` |
| Create | `skills/agentic-standards/agentic-standards.md` |
| Create | `skills/provider-abstraction/provider-abstraction.md` |

---

## Task 1: `skills/python-ai-service/python-ai-service.md`

**Files:**
- Create: `skills/python-ai-service/python-ai-service.md`

- [ ] **Step 1: Create the file**

````markdown
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
````

- [ ] **Step 2: Commit**

```bash
git add skills/python-ai-service/
git commit -m "feat: add python-ai-service skill"
```

---

## Task 2: `skills/ai-testing/ai-testing.md`

**Files:**
- Create: `skills/ai-testing/ai-testing.md`

- [ ] **Step 1: Create the file**

````markdown
# ai-testing

Use before writing tests for AI services or LLM-powered features.

**Announce at start:** "Loading ai-testing standards."

---

## Core Rule

**Never hit a real LLM API in unit tests or CI.** Reasons:
1. Cost — every test run charges tokens
2. Non-determinism — tests that pass today may fail tomorrow with different model output
3. Latency — LLM calls make tests 10–100x slower

---

## Mocking LLM Calls (Python)

```python
from unittest.mock import patch, AsyncMock, MagicMock
import pytest

@pytest.mark.asyncio
@patch('app.services.llm_service.httpx.AsyncClient')
async def test_classify_returns_delayed_status(mock_client):
    # Arrange — mock the OpenRouter HTTP response
    mock_response = MagicMock()
    mock_response.json.return_value = {
        "choices": [{
            "message": {
                "content": '{"status": "delayed", "confidence": 0.95, "reasoning": "5 days overdue"}'
            }
        }],
        "usage": {"prompt_tokens": 120, "completion_tokens": 30}
    }
    mock_response.raise_for_status = MagicMock()
    mock_client.return_value.__aenter__.return_value.post = AsyncMock(return_value=mock_response)

    # Act
    result = await classify_shipment("Package not arrived after 5 days")

    # Assert on shape, not exact text
    assert result.status == "delayed"
    assert result.confidence > 0.9
    assert isinstance(result.reasoning, str)
    assert len(result.reasoning) > 0
```

## Golden Output Tests

Assert on **response shape**, not exact text. LLM output varies:

```python
# ✅ Shape assertion — passes regardless of exact wording
assert result.status in ["on_time", "delayed", "lost"]
assert 0.0 <= result.confidence <= 1.0
assert len(result.reasoning) > 10

# ❌ Exact text assertion — brittle, breaks on model updates
assert result.reasoning == "The package is 5 days overdue based on the estimated delivery date"
```

## Evaluation Harnesses

For measuring agent output quality, use a separate evaluation suite that runs on demand — never in CI:

```python
# tests/eval/test_classifier_quality.py
# Run with: pytest tests/eval/ -m eval --no-header -q
import pytest

@pytest.mark.eval
def test_classifier_accuracy_on_golden_set():
    """Run against real LLM. Measures accuracy on 50 labelled examples."""
    golden = load_golden_dataset('tests/eval/fixtures/shipment-labels.json')
    correct = 0
    for example in golden:
        result = asyncio.run(classify_shipment(example['description']))
        if result.status == example['expected_status']:
            correct += 1
    accuracy = correct / len(golden)
    assert accuracy >= 0.85, f"Accuracy {accuracy:.0%} below threshold 85%"
```

## Latency Budget Tests

In integration suite, not unit — require a running service:

```python
# tests/integration/test_latency.py
@pytest.mark.integration
@pytest.mark.asyncio
async def test_classify_latency_under_budget():
    import time
    start = time.monotonic()
    result = await classify_shipment("Test input")
    elapsed_ms = (time.monotonic() - start) * 1000
    assert elapsed_ms < 3000, f"Latency {elapsed_ms:.0f}ms exceeds 3s budget"
```
````

- [ ] **Step 2: Commit**

```bash
git add skills/ai-testing/
git commit -m "feat: add ai-testing skill"
```

---

## Task 3: `skills/agentic-standards/agentic-standards.md`

**Files:**
- Create: `skills/agentic-standards/agentic-standards.md`

- [ ] **Step 1: Create the file**

````markdown
# agentic-standards

Use when building any agentic workflow, multi-step agent, or tool-using LLM feature.

**Announce at start:** "Loading agentic-standards. Read the rules section fully before writing agent code."

---

## Rules (Non-Negotiable)

### 1. Every tool call must have a timeout and retry limit

```python
TOOL_TIMEOUT_SECONDS = 30
MAX_RETRIES = 3

async def call_tool_with_guard(tool_fn, *args, **kwargs):
    for attempt in range(MAX_RETRIES):
        try:
            return await asyncio.wait_for(tool_fn(*args, **kwargs), timeout=TOOL_TIMEOUT_SECONDS)
        except asyncio.TimeoutError:
            if attempt == MAX_RETRIES - 1:
                raise ToolTimeoutError(f"{tool_fn.__name__} timed out after {MAX_RETRIES} attempts")
        except Exception as e:
            if attempt == MAX_RETRIES - 1:
                raise
```

### 2. Log at start AND end of every agent step

```python
logger.info(json.dumps({"event": "step_start", "step": step_name, "request_id": request_id}))
try:
    result = await execute_step()
    logger.info(json.dumps({"event": "step_complete", "step": step_name, "request_id": request_id}))
    return result
except Exception as e:
    logger.error(json.dumps({"event": "step_failed", "step": step_name, "error": str(e), "request_id": request_id}))
    raise
```

### 3. Irreversible actions require human confirmation

Actions that cannot be undone: DB writes, sending emails, deploying, calling external mutation APIs.

```python
async def execute_irreversible_action(action_description: str, action_fn):
    print(f"\n⚠️  About to perform: {action_description}")
    print("This cannot be undone. Type 'confirm' to proceed or anything else to cancel: ", end="")
    response = input().strip()
    if response.lower() != 'confirm':
        raise ActionCancelledError("User cancelled irreversible action")
    return await action_fn()
```

### 4. Define maximum loop depth

```python
MAX_AGENT_ITERATIONS = 10

async def run_agent_loop(initial_state):
    state = initial_state
    for iteration in range(MAX_AGENT_ITERATIONS):
        result = await agent_step(state)
        if result.is_terminal:
            return result
        state = result.next_state
    raise MaxIterationsError(f"Agent exceeded {MAX_AGENT_ITERATIONS} iterations without reaching terminal state")
```

### 5. Tool descriptions are for the model

Every tool definition must have a clear `description`. The model reads this to decide when to call it — you don't:

```python
tools = [
    {
        "name": "get_shipment_status",
        "description": "Retrieves the current status and location of a shipment by tracking number. Use this when the user asks where their package is or whether it has been delivered.",
        "input_schema": {
            "type": "object",
            "properties": {
                "tracking_number": {"type": "string", "description": "The shipment tracking number, e.g. RB12345"}
            },
            "required": ["tracking_number"]
        }
    }
]
```

### 6. Handle `tool_use` errors gracefully

```python
if tool_result.get("is_error"):
    error_msg = tool_result.get("content", "Unknown tool error")
    logger.error(json.dumps({"event": "tool_error", "tool": tool_name, "error": error_msg}))
    # Surface to user, do not silently retry forever
    return AgentResponse(
        success=False,
        error=f"Tool '{tool_name}' failed: {error_msg}. Please try again or contact support."
    )
```
````

- [ ] **Step 2: Commit**

```bash
git add skills/agentic-standards/
git commit -m "feat: add agentic-standards skill"
```

---

## Task 4: `skills/provider-abstraction/provider-abstraction.md`

**Files:**
- Create: `skills/provider-abstraction/provider-abstraction.md`

- [ ] **Step 1: Create the file**

````markdown
# provider-abstraction

Use when writing any LLM integration code. Read fully before writing a single line.

**Announce at start:** "Loading provider-abstraction standards."

---

## Rule 1: Always Use OpenRouter

No direct Anthropic SDK (`anthropic`) or OpenAI SDK (`openai`) calls in production services. The only exception is Claude Code tooling itself (skills, hooks — not application services).

Check `~/.claude/roambee-config.json` for `openrouter.baseUrl` and `openrouter.keyEnvVar`. If missing, check the monorepo root `.env.example`. If still not found, ask the user:
- "What is your OpenRouter base URL?"
- "What environment variable holds the API key? (e.g. OPENROUTER_API_KEY)"

Save the answers to `~/.claude/roambee-config.json`.

---

## Rule 2: Ask the User Which Model Before Writing Code

Present this table and ask: "Which model fits this task?"

| Model | Best for | Est. cost / 1k calls |
|-------|----------|----------------------|
| `anthropic/claude-haiku-4-5` | Classification, extraction, short Q&A | ~$0.08 |
| `anthropic/claude-sonnet-4-6` | Reasoning, code gen, multi-step tasks | ~$0.90 |
| `anthropic/claude-opus-4-5` | Complex agentic workflows, long context | ~$4.50 |
| `openai/gpt-4o-mini` | Simple summarisation, cheap fallback | ~$0.04 |
| `openai/gpt-4o` | Vision tasks, structured extraction | ~$1.50 |

Costs are approximate blended input+output. Always confirm with the user — never default to the most capable (most expensive) model.

---

## Rule 3: Use the Provider Wrapper

Define a thin wrapper so the model can be swapped without rewriting feature logic:

```python
# services/llm_provider.py
import httpx, json, time, logging
from typing import Optional

logger = logging.getLogger(__name__)

class LLMProvider:
    def __init__(self, base_url: str, api_key: str, default_model: str):
        self.base_url = base_url
        self.api_key = api_key
        self.default_model = default_model

    async def complete(
        self,
        prompt: str,
        model: Optional[str] = None,
        max_tokens: int = 1024,
        request_id: Optional[str] = None,
    ) -> str:
        model = model or self.default_model
        start = time.monotonic()

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": model,
                    "messages": [{"role": "user", "content": prompt}],
                    "max_tokens": max_tokens,
                },
                timeout=30.0,
            )
            response.raise_for_status()

        data = response.json()
        latency_ms = (time.monotonic() - start) * 1000
        usage = data.get("usage", {})

        logger.info(json.dumps({
            "event": "llm_call_complete",
            "model": model,
            "tokens_in": usage.get("prompt_tokens", 0),
            "tokens_out": usage.get("completion_tokens", 0),
            "latency_ms": round(latency_ms),
            "request_id": request_id,
        }))

        return data["choices"][0]["message"]["content"]
```

Instantiate once and inject:
```python
import os
from services.llm_provider import LLMProvider

llm = LLMProvider(
    base_url=os.environ["OPENROUTER_BASE_URL"],
    api_key=os.environ["OPENROUTER_API_KEY"],
    default_model="anthropic/claude-haiku-4-5",
)
```

---

## Rule 4: Prompts Are Files

Prompts longer than ~100 characters must live in `prompts/<feature-name>.md`, not inline:

```python
# ✅ Correct
from pathlib import Path

PROMPT_TEMPLATE = (Path(__file__).parent.parent / "prompts" / "classify-shipment.md").read_text()

async def classify(description: str) -> dict:
    prompt = PROMPT_TEMPLATE.replace("{{description}}", description)
    return await llm.complete(prompt)
```

```python
# ❌ Wrong — inline prompt, not versioned
async def classify(description: str) -> dict:
    prompt = f"""You are a logistics expert. Given the following shipment description,
    classify the delivery status as one of: on_time, delayed, lost.
    Respond in JSON format with fields: status, confidence (0-1), reasoning.

    Description: {description}"""
    return await llm.complete(prompt)
```

---

## Rule 5: Surface Provider Errors — Don't Silently Retry

```python
# ✅ Surface the error
except httpx.HTTPStatusError as e:
    if e.response.status_code == 429:
        raise LLMRateLimitError("OpenRouter rate limit exceeded. Please try again in a few seconds.")
    raise LLMProviderError(f"OpenRouter returned {e.response.status_code}: {e.response.text}")

# ❌ Silent retry with different model — hides the real problem
except Exception:
    return await self.complete(prompt, model="openai/gpt-4o-mini")  # No.
```
````

- [ ] **Step 2: Commit**

```bash
git add skills/provider-abstraction/
git commit -m "feat: add provider-abstraction skill"
```

---

## Task 5: End-to-End Verification

- [ ] **Step 1: Verify all 4 AI skill files exist**

```bash
for skill in python-ai-service ai-testing agentic-standards provider-abstraction; do
  FILE=$(ls skills/$skill/*.md 2>/dev/null | head -1)
  [ -n "$FILE" ] && echo "✅ $skill" || echo "❌ $skill MISSING"
done
```

Expected: 4 ✅

- [ ] **Step 2: Verify Hook 9 fires for AI files**

In a Claude Code session, ask Claude to write a file in `packages/ai/`. Expected: Hook 9 outputs the AI observability reminder before Claude writes the file.

- [ ] **Step 3: Invoke `provider-abstraction` and verify cost table appears**

In a Claude Code session, type `/provider-abstraction`. Expected: Claude displays the model cost table and asks which model to use.

- [ ] **Step 4: Final commit**

```bash
git status
git commit -m "chore: P5 complete — AI standards skills implemented"
```

---

## P5 Complete — Plugin is Fully Implemented

At this point all 5 plans are done. Run the full plugin verification:

```bash
# 1. Re-run /init to confirm all hooks and plugins install cleanly
# /init

# 2. Run /doctor and confirm all 8 checks pass
# /doctor

# 3. Check total file count
find ~/roambee-claude/skills -name "*.md" | wc -l
```

Expected: 21 skill files (3 setup + 5 workflow + 5 migrated Decklar + 4 app standards + 4 AI standards).

```bash
find ~/roambee-claude/hooks -name "*.sh" | wc -l
```

Expected: 16 hook scripts + 1 lib.sh = 17 files.
