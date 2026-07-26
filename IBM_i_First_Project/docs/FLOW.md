# Data-Flow and Program Design Notes

## Call Flow

```
User types country → PROMPTRCD (DSPF)
        │
        ▼
STATEMAIN reads CTRYINPUT
        │
        ▼
GetStates(country, states[], count, errMsg)   [CTRYSVC module]
        │
        ├── errMsg ≠ blank ──► display errMsg on PROMPTRCD, loop back
        │
        ▼
HTTP_Get(url, response, errMsg)               [HTTPSVC service program]
        │
        ├── httpStatus = 0   ──► "Server could not be reached. Try after some time..."
        ├── httpStatus ≠ 200 ──► "HTTP Error <code>. Try after some time..."
        └── httpStatus = 200 ──► response contains raw JSON
        │
        ▼
JSON parser (inline in CTRYSVC)
  Scan for "states":[ ... ]
  Repeated scan for "name":"<value>"
  Populate StateEntry array
        │
        ▼
STATEMAIN loads subfile SFLRCD records
        │
        ▼
SFLCTL window displayed — user scrolls with PgUp/PgDn
F3 / F12 exits back to prompt or exits program
```

## Indicator Usage (STATELIST.DSPF)

| Indicator | Meaning                    |
|-----------|----------------------------|
| *IN03     | F3 pressed — exit program  |
| *IN12     | F12 pressed — cancel/back  |
| *IN31     | SFLDSP — show subfile rows |
| *IN32     | SFLDSPCTL — show SFL ctl   |
| *IN33     | SFLCLR — clear subfile     |
| *IN34     | SFLEND(*MORE)              |

## JSON Response Shape (countriesnow.space)

```json
{
  "error": false,
  "msg": "states for India retrieved",
  "data": {
    "name": "India",
    "iso3": "IND",
    "states": [
      { "name": "Andhra Pradesh", "state_code": "AP" },
      { "name": "Arunachal Pradesh", "state_code": "AR" }
    ]
  }
}
```

The parser in `CTRYSVC` skips to the `"states":[` section and extracts
every `"name":"<value>"` pair — ignoring `state_code` and any other keys.
