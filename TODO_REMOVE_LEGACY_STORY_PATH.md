# TODO: Remove Legacy Story Path from Worker

## What

The Cloudflare Worker (`edge/src/index.ts`) currently supports **two** request
formats on `POST /v1/story`:

| Format | App version | Detection |
|--------|-------------|-----------|
| **New (v2)** — `{ child_name, age_group, themes }` | v1.3+ | Has `child_name` field |
| **Legacy** — `{ messages: [...] }` | v1.2 and earlier | Has `messages` array |

The auto-detection lives in `handleStory()`. If the payload contains a
`messages` array, it routes to `handleStoryLegacy()` which forwards the
pre-built messages to OpenAI as-is (pure proxy). Otherwise it routes to
`handleStoryV2()` which builds prompts server-side.

## Why it exists

To avoid breaking existing v1.2 users while the v1.3 update rolls out through
App Store review and user upgrades.

## When to remove

Once you're confident the vast majority of users have upgraded to v1.3+.
A reasonable timeline is **4–6 weeks after v1.3 ships**, or when App Store
analytics show <1% of sessions on v1.2.

## How to remove

1. In `edge/src/index.ts`:
   - Delete the `LegacyStoryRequest` interface.
   - Delete the `handleStoryLegacy()` function.
   - Simplify `handleStory()` to directly call `handleStoryV2()` logic
     (or inline it).
   - Remove the `messages` array detection branch.
2. Delete this file (`TODO_REMOVE_LEGACY_STORY_PATH.md`).
3. Deploy the worker with `wrangler deploy`.
