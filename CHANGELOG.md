# Changelog

## 0.1.3

- Raise `Vend::UnprocessableEntity` on 422.
- Raise `Vend::HttpError` on any other non-2xx status without its own error class.
- `Vend::HttpError` carries `status` and `body`.
