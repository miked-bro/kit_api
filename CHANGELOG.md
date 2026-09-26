# Changelog

## 0.1.0 — Unreleased

- Initial release: full Kit v4 API surface (subscribers, tags, custom fields,
  forms, sequences, sequence emails, broadcasts, account, purchases, segments,
  snippets, posts, email templates, webhooks, bulk operations).
- High-level `Kit.subscribe` / `Kit.tag` (by name, create-if-missing, cached) /
  `Kit.unsubscribe` (by email, idempotent) conveniences.
- `Kit::Simulated` recording driver with an enforced surface-parity guarantee.
- Zero runtime dependencies.
