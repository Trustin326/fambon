# FamBon

**Small moments. Stronger bonds.** FamBon is a family connection app with conversation prompts, bonding games, a shared family-character activity, gentle trust-building reflections, and a memory scrapbook.

## Current application

- Responsive dashboard and navigation.
- Daily question bank, multiple-choice starters, personal answers, and recent shares.
- “Who would most likely…?”, “Two truths & a wish,” and “Remember when…” games.
- Family-character drawing canvas with brush/color controls, rotating turns, notes, and local save.
- Gentle Trust Garden activities.
- Member Spotlight planner for birthdays, graduations, new jobs, new babies, personal milestones, anniversaries, and difficult seasons. Save dates, personal support preferences, suggested ways to show up, and mark moments as celebrated.
- Memory scrapbook, individual deletion, JSON export, and local reset.
- “Memories we haven’t made yet” idea library with practical steps, time/cost guidance, member-attributed suggestions, idea/planned/made status, and conversion of completed ideas into scrapbook memories.
- Accessible focus states and reduced-motion support.
- No embedded service-role keys or payment secrets.

## Run / GitHub Pages

Open \`index.html\` in a browser, or publish the repository through **Settings → Pages** using the \`main\` branch and \`/(root)\` if no Pages workflow is already configured.

## Shared-family backend foundation

A Supabase SQL foundation is now included at \`supabase/schema.sql\`. It defines:

- Families and family-member roles (\`owner\`, \`adult\`, \`member\`).
- Expiring, single-use family invitations. Only a SHA-256 hash is stored; the raw invite token is returned once.
- Family answers with private/family visibility.
- Shared memories, game sessions, character drawing metadata, Trust Garden steps, and member spotlights for birthdays and life events.
- Row Level Security policies and membership/manager helper functions.
- Transactional RPCs to create a family, issue an invite, and redeem an invite.

### Configure Supabase

1. Create a Supabase project.
2. Open **SQL Editor** and run the complete \`supabase/schema.sql\` file.
3. In **Authentication → URL Configuration**, set the production Site URL and allowed redirect URLs for your GitHub Pages domain.
4. Enable only sign-in methods you intend to support; configure email confirmation and recovery.
5. Copy the project URL and publishable/anon key into \`config.js\`. These are public client values; never put a service-role key in the repository.
6. Keep \`enableSupabase: false\` until the frontend authentication, family selection, invitation redemption, and CRUD flows have been connected and tested against the schema.
7. Test with two separate accounts: verify each invited member sees only their own family, private answers are visible only to their author, expired/reused invite tokens fail, and a non-manager cannot issue invites or change family membership.

Example public config (replace with your own project values):

\`\`\`js
window.FAMBON_CONFIG = {
  supabaseUrl: "https://YOUR_PROJECT.supabase.co",
  supabaseAnonKey: "YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY",
  enableSupabase: false
};
\`\`\`

**Current integration boundary:** The new cloud-account panel in `cloud-account.js` supports Supabase email sign-up/sign-in, session persistence, listing joined family spaces, creating a family through the RPC, issuing a single-use invite token, and redeeming an invite. The rest of the app (answers, games, drawings, Trust Garden, scrapbook, and the Member Spotlight planner and future-memory suggestion board) still uses browser local storage and is not yet synced to family tables. The SQL has not been executed or security-tested in a live Supabase project. Do not treat this milestone as production-ready or as proof that all family content is shared.

## Production launch checklist

Before real families or paid customers use FamBon:

1. Connect and test authentication, account recovery, family creation, family switching, invitations, role management, and sign-out.
2. Connect every feature to the correct family-scoped tables and verify RLS with separate accounts and families.
3. Add secure media storage rules if drawing uploads are introduced; validate file types and sizes.
4. Add guardian/age-appropriate safeguards, data minimization, deletion/export workflows, retention rules, and a process for handling safety concerns.
5. Publish accurate privacy and terms documents, vendor disclosures, and contact information.
6. Add email notifications only with appropriate consent and opt-out controls. No email or SMS is sent by this prototype.
7. If monetization is added, verify payments server-side with signed webhooks and enforce entitlements on trusted backend operations. A browser success page is not proof of payment.
8. Test mobile browsers, keyboard accessibility, authorization boundaries, backup/restore, deletion, monitoring, and incident response.

The Trust Garden is for gentle reflection, not therapy. Never pressure anyone to disclose, forgive, reconcile, or remain in an unsafe relationship.

## Privacy in the current demo

Until Supabase integration is complete, profile details, answers, drawings, and memories remain in the current browser's local storage and are not shared across devices. Anyone with access to that browser profile may be able to see them; clearing browser data may remove them. Avoid entering highly sensitive disclosures on shared devices. Exported JSON files can contain personal information; store them securely.

## Project files

- \`index.html\` — application shell and dashboard
- \`styles.css\` — responsive visual system
- \`app.js\` — navigation, prompts, games, drawing, memories, and local persistence
- \`config.js\` — public backend configuration (disabled by default)
- \`supabase/schema.sql\` — shared-family database schema, RLS policies, and invitation RPCs

## License

Choose and add the license that matches how you intend to distribute this project before public release.
