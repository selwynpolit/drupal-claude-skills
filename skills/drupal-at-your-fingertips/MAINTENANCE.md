# Maintaining this skill (for Claude or a future developer)

This skill mirrors Selwyn Polit's [d9book](https://github.com/selwynpolit/d9book) ("Drupal at Your Fingertips") into `references/*.md` so the content is available locally instead of requiring a live web fetch. This doc explains how the mirror works, and the manual triage process to repeat if the source book changes significantly. It is written as a runbook — if you're an instance of Claude asked to "resync the d9book skill" or "re-run the general.md triage," follow it directly.

## How the mirror works

- Source: `selwynpolit/d9book`, `gh-pages` branch, `book/*.md` (this is the deployed docs site's raw markdown, not the repo's default branch — the sync script fetches from `raw.githubusercontent.com/selwynpolit/d9book/gh-pages/book/{topic}.md`).
- `.claude/scripts/sync-d9book.sh` discovers every topic in `book/` via the GitHub contents API, fetches each chapter's raw markdown, strips YAML frontmatter and the visitor-badge image, and writes it to `skills/drupal-at-your-fingertips/references/{topic}.md`.
- Files that already have **≥1500 bytes** of content are left alone on a normal run (the script assumes anything that size is real content, not a stub). Pass `--force` to refetch everything anyway — **except** topics listed in `SKIP_TOPICS`, which are never touched even with `--force` (see below).
- `SKILL.md` is regenerated from a static heredoc in the script on every run. If you hand-edit `SKILL.md` (e.g. fixing a broken reference link, adding the web-root callout), **make the same edit in the heredoc inside `sync-d9book.sh`**, or the next sync will silently revert it. This bit us once already — see the `bq.md`/`batch.md`/`queue.md` fix in git history for what that looks like.

## Why some chapters need manual triage

Most d9book chapters are one focused topic and fetch cleanly. A few — historically `general.md`, and at the time of writing `development.md`, `composer.md`, `nodes-and-fields.md`, `drush.md`, `modules.md`, `upgrade.md`, `blocks.md` — are unfocused grab-bags: dozens of unrelated one-off snippets dumped on a single page, some running 60–140KB. Since a skill reference file loads in full whenever an agent reads it, a 140KB "general" file being pulled in to answer one narrow question is a real token cost, not a hypothetical one. These chapters are worth manually triaging into smaller, better-homed pieces instead of shipping as one raw file.

**Check after every sync**: run `wc -c references/*.md | sort -rn | head -20`. Anything north of ~25–30KB is a candidate for this triage. `general.md` has already been done (see below); if `modules.md` or another large one starts actually being used, it deserves the same treatment.

## The triage process (worked example: `general.md`)

1. **Fetch the raw chapter and list its sections**:
   ```bash
   curl -s "https://raw.githubusercontent.com/selwynpolit/d9book/gh-pages/book/general.md" -o /tmp/raw.md
   grep -n '^## ' /tmp/raw.md
   ```

2. **Look for an existing home before inventing anything new.** For each `## ` section, ask: does an existing `references/*.md` file in this skill already cover this topic (e.g. routing → `routes.md`, preprocess/theming → `twig.md`, permissions/`.htaccess` → `security.md`)? Does an existing *sibling skill* in `skills/` cover it better (e.g. Config Split → `drupal-config-mgmt`, Solr relevance tuning → `drupal-search-api`)? Only fall back to keeping something in the original chapter file if nothing existing fits — **do not create new skills for a handful of loosely related snippets**; that was considered and rejected for `general.md` because most of its 67 sections were one-off tips, not a coherent domain.

3. **Extract by line range, not by rewriting from memory**:
   ```bash
   grep -n '^## ' /tmp/raw.md   # note the line number of every header
   sed -n 'START,ENDp' /tmp/raw.md > group_x.md   # one range per destination
   ```
   Watch for two mistakes made (and caught) during the `general.md` pass:
   - **Duplicate headers.** d9book chapters sometimes repeat a section (e.g. "Get the current user" appeared twice). Compare both copies; keep the more complete one, drop the other. Don't extract both.
   - **Overlapping ranges.** If one destination gets a big contiguous range (e.g. "everything from line 925 to 1849 goes to the misc bucket") and another destination separately extracted a smaller range that falls *inside* that span, you'll duplicate content across two files. After extracting, grep the destination files for a section title you know was moved elsewhere and confirm it only appears once across all destinations.

4. **Light cleanup while merging, not a full rewrite**:
   - Replace escaped markdown artifacts from the source generator: `\"` → `"`, `\_` → `_`.
   - Drop `![...](/images/...)` references — those images don't exist in this repo.
   - Generalize client-identifying names from the original book (real module/project names like `abc_search`, `txg`, `wecc_node_access`) to generic placeholders (`my_module`, etc.) — this is a public skill repo.
   - Fix obvious typos/truncated code blocks only when trivial and unambiguous; otherwise leave the author's content as-is. Don't over-polish — the goal is a usable merge, not a rewrite.
   - Label every merged section with a one-line attribution so a future reader knows why it's there, e.g.:
     ```
     _Merged from the d9book "general" chapter, which was too large to keep as a single reference file._
     ```

5. **Insert into the destination's existing structure.** Curated "quick reference" files (routes.md, twig.md, services.md, etc.) end with a `## Key Guidelines` ✅/❌ section — insert new content *before* that, not after. Raw-fetched files (security.md at the time of writing) don't have that structure; insert new subsections near the most related existing section (e.g. the `.htaccess` crawling-block snippet went inside the existing `.htaccess magic` section in `security.md`).

6. **Whatever's left with no better home stays in the original topic file**, trimmed down to just those sections, with a short header explaining what moved where (see the top of `general.md` for the pattern). This residual file is still allowed to be a "grab-bag" — that's fine, it just shouldn't be the *entire* original chapter anymore.

7. **Verify before finishing**:
   ```bash
   # Every file's code fences must balance.
   for f in references/*.md skills-you-touched/SKILL.md; do
     c=$(grep -c '^```' "$f"); [ $((c % 2)) -ne 0 ] && echo "UNBALANCED: $f ($c)"
   done
   ```
   Also re-read the destination files' new sections once, end to end, to catch anything that reads oddly out of context.

8. **Lock the source topic against future overwrites.** Add the topic to `SKIP_TOPICS` in `sync-d9book.sh` (it's a space-padded string match, e.g. `SKIP_TOPICS=" general modules "`) so a future sync — even with `--force` — never overwrites your hand-curated file with a fresh raw dump. Update the comment above `SKIP_TOPICS` if it goes stale.

## When to redo this

- After running `sync-d9book.sh` on a fresh clone, if a **new** chapter shows up oversized (check with the `wc -c` command above) and it's actually getting used, triage it the same way.
- If d9book's `general.md` (or another already-triaged chapter) gets substantial new content upstream, the merged copies here won't pick it up automatically (it's in `SKIP_TOPICS`). Re-fetch the raw chapter, diff it against what's already merged, and manually pull in anything new using the same process.
- This was last done for `general.md` on 2026-08-08 — see that date's commits for the full worked example if you need to see exact before/after diffs.
