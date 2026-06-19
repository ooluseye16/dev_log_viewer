# Changelog

## 0.1.0

- Initial release.
- `LogForwarder` — raw log sender with auto-discovery across ports 8181–8185.
- `DevLogInterceptor` — zero-config Dio interceptor for automatic API traffic logging.
- `AppLog` — named tag shortcuts (`auth`, `nav`, `store`, `api`, `error`, `log`).
- All output suppressed automatically in release builds via `dart.vm.product`.
