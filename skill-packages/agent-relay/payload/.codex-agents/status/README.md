# Status Files

Each worker gets one JSON file in this directory.

Suggested shape:

```json
{
  "task_id": "task-001-implementer",
  "role": "implementer",
  "state": "in_progress",
  "summary": "Implementing the requested slice.",
  "updated_at": "2026-03-13T00:00:00Z"
}
```

Keep these files short. They are for the main agent to scan quickly.
