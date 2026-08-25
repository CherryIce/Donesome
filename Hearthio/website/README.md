# Hearthio website

This directory contains the static marketing/support website and the privacy
policy for Hearthio (家务志).

## Pages

- `index.html`: marketing page and App Store support page
- `privacy.html`: bilingual privacy policy

Both pages share `styles.css`, `site.js`, and the optimized project-owned assets
under `assets/`. They do not require a build step, external fonts, analytics, or
third-party JavaScript.

## Replace before publishing

The operator is listed as `Hearthio 独立开发者` / `Hearthio Independent
Developer`, the public contact address is `djl13333995679@163.com`, and the
policy effective date is August 25, 2026.

The public privacy page uses general website-infrastructure wording and does not
show an internal hosting reminder. After the production host is selected, record
the provider in the release checklist and optionally name it in the policy with
a link to its privacy notice.

Then re-audit the privacy wording against the final release binary and App
Privacy answers. Do not submit the placeholder values to App Store Connect.

## App and App Store wiring

- Marketing URL / Support URL: public HTTPS URL for `index.html`
- Privacy Policy URL: public HTTPS URL for `privacy.html`
- In-app policy page: build with
  `--dart-define=PRIVACY_POLICY_URL=https://<your-domain>/privacy.html`

The final URLs must be publicly reachable without sign-in.

## Local preview

From the repository root:

```sh
python3 -m http.server 4173 --directory Hearthio/website
```

Then open `http://localhost:4173/`.
