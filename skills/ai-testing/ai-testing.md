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
