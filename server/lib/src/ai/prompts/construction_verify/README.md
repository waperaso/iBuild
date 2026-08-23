# construction_verify

Versioned system prompts for the site-photo A→B vendor call.

- `v0.system.txt` in git is a placeholder (`PROMPT_NOT_SHIPPED`). Callers load
  the file from disk and never accept a client-supplied system prompt.
- The real PKM 321 + CORE AI Multiple-checks prompt lives in
  `v0.system.local.txt` (gitignored). Point the server at it with
  `CONSTRUCTION_VERIFY_PROMPT_FILE` in `server/.env`.
- `v0.schema.json` is the JSON contract the vendor response must match.
- `payload.example.json` is the user-payload shape (photo file metadata +
  expected state + `user_language` + integrity context). The vendor `summary`
  is Markdown written in `user_language`. Image **files** are uploaded to OpenAI
  Files API (`purpose=user_data`) and referenced by `file_id` on the Responses
  path; if that path fails, the client falls back to `data:` URLs. Bytes are
  never logged and never exposed as public signed URLs with secrets.

`prompt_sha256` in `vendor_ai_calls` is SHA-256 of the **loaded** system text.

Multiple checks (pitch): authenticity / same building / progress delta —
metadata + fingerprint + geotag are iBuild-local and **gate** the vendor call:
hard failures (`integrity_blocked`) skip OpenAI entirely; soft findings still
allow Vision, which always runs again when the gate passes.
