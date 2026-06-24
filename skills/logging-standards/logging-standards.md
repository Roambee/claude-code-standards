# logging-standards

Use when adding any logging, error handling, or user-facing notifications.

**Announce at start:** "Loading logging-standards."

---

## NestJS Services

Use `Logger` from `@nestjs/common`. Never use `console.log`.

```typescript
import { Logger, Injectable } from '@nestjs/common';

@Injectable()
export class ShipmentService {
  private readonly logger = new Logger(ShipmentService.name);

  async createShipment(dto: CreateShipmentDto): Promise<Shipment> {
    this.logger.log(`Creating shipment for tracking: ${dto.trackingNumber}`);
    try {
      const result = await this.repository.save(dto);
      this.logger.log(`Shipment created: ${result.id}`);
      return result;
    } catch (error) {
      this.logger.error(`Failed to create shipment: ${error.message}`, error.stack);
      throw error;
    }
  }
}
```

---

## React Frontend

User-facing errors use `EventEmitter`, not `console.error`.

```typescript
import { EventEmitter } from '@decklar/client-utility';

// Error notification
EventEmitter.emit('showSnackbar', {
  message: 'Failed to load shipments. Please try again.',
  severity: 'error',
});

// Success notification
EventEmitter.emit('showSnackbar', {
  message: 'Shipment exported successfully.',
  severity: 'success',
});
```

Never show raw error messages from the API to the user. Map them to human-readable text.

---

## Python AI Services

Structured JSON logging. Every log entry must include `request_id`, `service`, `level`.

```python
import logging, json, sys

def get_logger(service_name: str):
    logger = logging.getLogger(service_name)
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter('%(message)s'))
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    return logger

logger = get_logger('shipment-classifier')

# Usage
logger.info(json.dumps({
    "level": "INFO",
    "service": "shipment-classifier",
    "request_id": request_id,
    "model": model_name,
    "tokens_in": response.usage.input_tokens,
    "tokens_out": response.usage.output_tokens,
    "latency_ms": latency,
    "event": "llm_call_complete"
}))
```

---

## Never Log

- Raw user input or full prompt content
- PII fields: email, phone, name, address, location, national ID
- Auth tokens, API keys, session tokens
- Full request/response bodies from external APIs (log metadata only)
