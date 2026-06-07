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
