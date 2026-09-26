# Changelog

## 0.1.1 — Unreleased

- Security: URL-escape ids interpolated into request paths, so a hostile
  id like `"42/unsubscribe"` can no longer splice the request into a
  different endpoint.

## 0.1.0 — 2026-09-26

- Initial release: full Kit v4 API surface (subscribers, tags, custom fields,
  forms, sequences, sequence emails, broadcasts, account, purchases, segments,
  snippets, posts, email templates, webhooks, bulk operations).
- High-level `Kit.subscribe` / `Kit.tag` (by name, create-if-missing, cached) /
  `Kit.unsubscribe` (by email, idempotent) conveniences.
- `Kit::Simulated` recording driver with an enforced surface-parity guarantee.
- Zero runtime dependencies.
