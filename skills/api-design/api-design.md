# api-design

Use when designing or reviewing a new API endpoint in NestJS.

**Announce at start:** "Loading api-design standards."

---

## URL Conventions

- Versioning: `/v1/` for stable, `/v2/` for current generation. New endpoints start at `/v1/`.
- Kebab-case: `/v1/shipment-events`, not `/v1/shipmentEvents`
- Plural nouns for collections: `/v1/shipments`, not `/v1/shipment`
- Nested resources for ownership: `/v1/shipments/:id/events`

## Response Format

Always use `ResponseHandlerService`. Never call `res.json()` directly.

```typescript
import { ResponseHandlerService } from '@decklar/platform-utility';

@Get()
async getShipments(@Query() query: GetShipmentsDto) {
  const result = await this.shipmentService.findAll(query);
  return this.responseHandler.success(result);
}
```

Paginated response shape:
```typescript
{
  data: Shipment[],
  total: number,
  page: number,
  pageSize: number
}
```

Error response shape (handled by global exception filter — do not construct manually):
```typescript
{
  statusCode: number,
  message: string,
  error: string
}
```

## Auth Headers

All endpoints (except public health checks) require `Authorization: Bearer <JWT>`. The JWT is validated by the Central Authorization Service middleware — do not implement auth logic in individual services.

## Swagger Documentation (Required)

Every endpoint must have:
```typescript
@ApiTags('shipments')
@Controller('v1/shipments')
export class ShipmentsController {

  @Get()
  @ApiOperation({ summary: 'List all shipments with pagination' })
  @ApiResponse({ status: 200, description: 'Paginated shipment list', type: PaginatedShipmentDto })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  async getShipments() { ... }
}
```

## JSON Naming

Request and response bodies use camelCase:
```json
{ "trackingNumber": "RB12345", "estimatedDelivery": "2026-06-10" }
```

Never use snake_case in JSON bodies (TypeORM entity columns can be snake_case internally — use `@Column({ name: 'tracking_number' })` + a camelCase property name).
