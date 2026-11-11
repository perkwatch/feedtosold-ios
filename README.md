# FeedToSold for iOS

The native merchant app for FeedToSold — the feed that sells.

A real SwiftUI app (no web wrapper): sign in with your FeedToSold account,
manage your storefront products, talk to the live sales agent, and see your
plan and your store's numbers. All data comes from the live FeedToSold
service at feedtosold.com via its mobile API (`/api/mobile/*`).

Billing follows the estate rule: plans are bought and managed on the web
through Stripe — never inside the app. The app unlocks and uses what was
bought on the web.

- Bundle ID: `com.getperkwatch.feedtosold`
- Version: 1.0 · Build base lives in `FeedToSold.xcodeproj/project.pbxproj`
  (`CURRENT_PROJECT_VERSION`); CI bumps it ephemerally per upload and the
  committed base is advanced to the uploaded number after each release
  (bookkeeping commits carry `[skip ci]`).
- Built by `.github/workflows/build-feedtosold.yml` in `perkwatch/perkwatch-ios`
  on the self-hosted Mac runner (dispatch-only; mode=compile / mode=release).

© 2026 BuckThem. All rights reserved. FeedToSold. Created November 5, 2026.
