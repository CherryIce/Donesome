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

Search this directory for the following visible placeholders:

- `<开发者或运营主体名称>` / `<Developer or operator name>`
- `<example@email.com>`
- `<YYYY-MM-DD>`
- `<网站托管服务商>` / `<Website hosting provider>`

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
