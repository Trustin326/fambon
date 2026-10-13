# FamBon

**Small moments. Stronger bonds.** FamBon is a mobile-friendly family connection app prototype with daily conversation prompts, lightweight bonding games, a shared family-character drawing canvas, gentle trust-building activities, and a family memory scrapbook.

## Features in this build

- Responsive, warm, mobile-first dashboard and navigation.
- Daily question bank with multiple-choice starters, personal answers, and recent shares.
- Three activities: “Who would most likely…?”, “Two truths & a wish,” and “Remember when…”.
- Family character canvas with color/brush controls, rotating turns, turn notes, and local drawing save.
- Optional trust garden with gentle steps and non-coercive language.
- Memory scrapbook, individual deletion, JSON export, and local reset.
- Accessible labels, keyboard focus styling, and reduced-motion support.
- No embedded service-role keys, third-party AI keys, analytics, SMS, or payment secrets.

## Run or deploy

Open `index.html` in a browser or publish this repository with GitHub Pages.

1. Open the repository's **Settings → Pages**.
2. Select deployment from the `main` branch and `/(root)`, unless an existing workflow already handles deployment.
3. Save and wait for GitHub Pages to publish.
4. Test the published site on a phone and desktop.

## Important production status

**This is an interactive front-end prototype, not yet a complete production multi-user SaaS.** The present build saves information in the current browser's local storage. It does not yet have real accounts, secure shared family rooms, invitation links, multi-device synchronization, email/SMS notifications, or payments. The optional `config.js` has blank Supabase settings and `enableSupabase: false`; keep it disabled until the backend is built and tested.

Before inviting real families or charging customers, implement and verify:

1. **Authentication and authorization:** verified sign-in, account recovery, family invitations, roles, and server-side membership checks.
2. **Database and row-level security:** schema and migrations for families, members, answers, game sessions, drawings, memories, consent, and preferences. Test that one family cannot read another family's data.
3. **Children and family safety:** age-appropriate design, guardian consent where required, data minimization, safe invite controls, deletion/export workflows, and a process for handling concerns.
4. **Privacy and security:** publish accurate privacy/terms documents, retention rules and vendor disclosures; securely handle uploaded media; add rate limits, administrative audit logs, and incident response. Never expose a Supabase service-role key in frontend code.
5. **Notifications:** send email/SMS only after proper consent and verified provider configuration; implement opt-out and follow applicable messaging laws. No messages are sent by this prototype.
6. **Payments:** use a trusted payment provider with server-verified webhooks and server-enforced entitlements. A success-page visit or client-side flag is not proof of payment.
7. **Operations:** test mobile browsers, accessibility, error states, authorization boundaries, backup/restore, deletion, monitoring, dependency updates, and incident recovery.
8. **Trust-focused content:** the trust garden is for gentle reflection, not therapy. Never pressure anyone to disclose, forgive, reconcile, or remain in an unsafe relationship.

## Files

- `index.html` — app shell and dashboard
- `styles.css` — responsive visual system
- `app.js` — navigation, prompts, games, drawing, memories, and local persistence
- `config.js` — optional public backend configuration (disabled by default)

## Privacy note

Profile details, answers, and memories are stored in the current browser's local storage in this demo. They are not synced to other devices. Anyone with access to the same browser profile may be able to see them, and clearing browser data may remove them. Avoid entering highly sensitive disclosures on shared devices. Exported JSON files can contain personal information; store them securely.

## License

Choose and add the license that matches how you intend to distribute this project before public release.