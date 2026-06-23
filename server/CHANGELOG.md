# Changelog

## 0.2.0

- `/ping` now reports `startedAt`, used by the client's discovery logic to
  prefer the most recently started server when several are running for the
  same project.
- Tag filter chips now have a working click handler for `ALL` — previously
  the static `ALL` button never had a listener attached, so the only way
  back to "show everything" was untoggling every other active tag by hand.
- Tags with no dedicated colour (anything outside `API`/`AUTH`/`NOTIF`/`NAV`/
  `STORE`/`PAY`/`ERR*`) get a deterministic colour from the existing accent
  palette, applied consistently to both the filter chip and the inline
  badge — previously they fell back to a flat grey with no active-state
  styling at all.
- Sensitive JSON values (`password`, `pin`, `token`, `authorization`,
  `access_token`, `refresh_token`, `client_secret`, `cvv`) render masked by
  default in the body viewer; click to reveal. The Copy button always
  copies the real value regardless of the on-screen mask state.
- Copy button now reconstructs a clean request/response summary for `API`
  entries (`--> METHOD url` / `CODE <-- url`, with the real JSON body)
  instead of just the bare arrow line with no body.

## 0.1.1

- Documentation only — dartdoc comments added across the public API, no
  behavioural changes.

## 0.1.0

- Initial release.
- Shelf HTTP server with SSE live stream, log store, and built-in web UI.
- Auto-increments port (8181–8190) when the default is already in use.
- `dev_log_viewer` CLI: starts the server.
- `dev_log_setup` CLI: one-command onboarding wizard for Flutter/Dart projects.
