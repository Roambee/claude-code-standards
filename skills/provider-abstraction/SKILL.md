# provider-abstraction

Use when writing any LLM integration code. Read fully before writing a single line.

**Announce at start:** "Loading provider-abstraction standards."

---

## Rule 1: Always Use OpenRouter

No direct Anthropic SDK (`anthropic`) or OpenAI SDK (`openai`) calls in production services. The only exception is Claude Code tooling itself (skills, hooks — not application services).

Check `~/.claude/decklar-config.json` for `openrouter.baseUrl` and `openrouter.keyEnvVar`. If missing, check the monorepo root `.env.example`. If still not found, ask the user:
- "What is your OpenRouter base URL?"
- "What environment variable holds the API key? (e.g. OPENROUTER_API_KEY)"

Save the answers to `~/.claude/decklar-config.json`.

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
