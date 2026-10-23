<p align="center"><img src="docs/icon.png" alt="Cloudflare DNS" width="96"></p>

<h1 align="center">Cloudflare DNS</h1>

<p align="center">Read-only desktop viewer for Cloudflare DNS records, built with Flutter.</p>

## Quick start

Requires Flutter 3.x with desktop support enabled.

```sh
export CLOUDFLARE_API_TOKEN=<your token>
flutter run -d macos   # or linux, windows
```

Launch from a terminal so the app inherits the environment variable.

## Usage

- Pick a zone from the dropdown at the top.
- Filter records with the search box (matches name, type and content).
- Use the reload button to refetch the current zone.

## Configuration

| Variable | Type | Default | Example |
|----------|------|---------|---------|
| `CLOUDFLARE_API_TOKEN` | string | none (required) | `export CLOUDFLARE_API_TOKEN=abc123` |

Create an [API token](https://dash.cloudflare.com/profile/api-tokens) with `Zone:Read` and `DNS:Read` permissions.

## Build and test

```sh
flutter test
flutter build macos --release
```

## Notes

- The app is read-only; it never creates, edits or deletes records.
- The token is read from the environment only and is never stored.
- macOS builds need the `com.apple.security.network.client` entitlement (already set).

---

Maintained by [Digitalis.io](https://digitalis.io), support at [digitalis.io/contact](https://digitalis.io/contact). Licensed under the Apache License 2.0, see [LICENSE](LICENSE).
