# Sync Protocol

## Push

`POST /v1/sync/push`

```json
{
  "deviceId": "device-1",
  "ops": [
    {
      "opId": "uuid",
      "entity": "task",
      "action": "upsert",
      "entityId": "uuid",
      "payload": {"title": "Task"},
      "clientTs": "2026-02-19T10:00:00Z"
    }
  ]
}
```

Response includes applied count and rejected ops with reasons.

## Pull

`GET /v1/sync/pull?cursor=0&deviceId=device-1&limit=500`

Returns ordered change list with next cursor.

## Idempotency

`opId` is unique per user and stored in `applied_ops` to avoid duplicate application.
