# SFM API: People

## Chart

`/people/:id/chart?` returns the person's superior and inferior posts to render in a chart. Parameters:

* `at`: **Required.** ISO 8601 format `YYYY-MM-DD`.

```json
@todo
```

## Detail

`/people/:id` returns a person dossier.

Append `.zip` or `.txt` to the path to export as `text/csv` or `text/plain`. *Returns 204 No Content for now.*

```json
{
@todo
}
```
