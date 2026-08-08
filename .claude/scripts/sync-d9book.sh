#!/bin/bash
# Sync Selwyn Polit's D9 Book content into the drupal-at-your-fingertips skill.
# Usage: ./sync-d9book.sh [--force]
#
#   --force   Re-fetch and overwrite ALL reference files, including ones that
#             already have substantial hand-curated content (size > $MIN_REAL_BYTES).
#             Without --force, those are left alone so curated "quick reference"
#             files (e.g. dtt.md, services.md) aren't clobbered with raw book prose.
#
# Auto-discovers all topics from the d9book repository and pulls each chapter's
# real markdown content (not just a link to it), lightly cleaned (frontmatter and
# visitor-badge image stripped). Falls back to a link-stub only if a chapter can't
# be fetched.

set -e

UPSTREAM_URL="https://drupalatyourfingertips.com"
UPSTREAM_REPO="https://github.com/selwynpolit/d9book"
BOOK_RAW_BASE="https://raw.githubusercontent.com/selwynpolit/d9book/gh-pages/book"
SKILLS_DIR="skills"
SKILL_NAME="drupal-at-your-fingertips"
SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"
MIN_REAL_BYTES=1500
# Upstream chapters that are unfocused grab-bags (many unrelated snippets on
# one page) rather than a single topic. These have been manually triaged:
# the broadly useful sections were merged into routes.md/twig.md/security.md
# and the drupal-config-mgmt/drupal-search-api skills, and what's left is a
# hand-curated (not raw-fetched) references/{topic}.md. Never auto-overwrite
# these, even with --force — re-run the triage by hand if upstream changes.
SKIP_TOPICS=" general "

FORCE=0
if [ "${1:-}" = "--force" ]; then
  FORCE=1
fi

# Generate main SKILL.md (static index — update this heredoc by hand if the
# curated topic list or web-root callout needs to change).
create_d9book_skill() {
  mkdir -p "$SKILL_DIR/references"

  cat > "$SKILL_DIR/SKILL.md" <<'EOT'
---
name: drupal-at-your-fingertips
description: Comprehensive Drupal patterns from "Drupal at Your Fingertips" by Selwyn Polit. Covers 50+ topics including services, hooks, forms, entities, caching, testing, and more.
---

# Drupal at Your Fingertips

> **Web root:** Examples use `docroot/` (the web root Acquia Cloud requires). If your project uses the Composer `drupal/recommended-project` default, the web root is `web/` — substitute it in the paths below (other setups may use `html/`, `public_html/`, or the project root). Check the `docroot:` key in `.ddev/config.yaml` if unsure.

**Source**: [drupalatyourfingertips.com](https://drupalatyourfingertips.com)
**Author**: Selwyn Polit
**License**: Open access documentation

## When This Skill Activates

Activates when working with Drupal development topics covered in the d9book including:
- Core APIs (services, hooks, events, plugins)
- Content (nodes, fields, entities, paragraphs, taxonomy)
- Forms and validation
- Routing and controllers
- Theming (Twig, render arrays, preprocess)
- Caching and performance
- Testing (PHPUnit, DTT)
- Common patterns and best practices

---

## Available Topics

All topics are available as references in the `/references/` directory.

Each reference contains the full chapter content pulled from drupalatyourfingertips.com:
- Detailed explanations and code examples
- Best practices and common patterns
- Step-by-step guides
- Troubleshooting tips

### Core Concepts
- @references/services.md - Dependency injection and service container
- @references/hooks.md - Hook system and implementations
- @references/events.md - Event subscribers and dispatchers
- @references/plugins.md - Plugin API and annotations
- @references/entities.md - Entity API and custom entities

### Content Management
- @references/nodes-and-fields.md - Node and field API
- @references/forms.md - Form API and validation
- @references/paragraphs.md - Paragraphs module patterns
- @references/taxonomy.md - Taxonomy and vocabularies
- @references/menus.md - Menu system

### Development Tools
- @references/composer.md - Dependency management
- @references/drush.md - Drush commands
- @references/debugging.md - Debugging techniques
- @references/logging.md - Logging and monitoring
- @references/dtt.md - Drupal Test Traits

### Advanced Topics
- @references/bq.md - Batch API and Queue API for long-running/background operations
- @references/cron.md - Cron jobs and scheduling
- @references/ajax.md - AJAX framework
- @references/javascript.md - JavaScript in Drupal

See `/references/` directory for complete list of 50+ topics.

---

---

**To update**: Run `.claude/scripts/sync-d9book.sh` (add `--force` to refresh every file, including curated ones)
EOT

  echo "✓ drupal-at-your-fingertips SKILL.md written"
}

# Fetch + clean one chapter's raw markdown. Prints the cleaned body to stdout.
# Returns non-zero if the fetch failed.
fetch_and_clean_topic() {
  local topic=$1
  local raw
  raw=$(curl -sf "$BOOK_RAW_BASE/${topic}.md") || return 1

  if [ -z "$raw" ]; then
    return 1
  fi

  # Strip leading YAML frontmatter (--- ... ---) and the visitor-badge image line.
  printf '%s\n' "$raw" | awk '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---" { infm=0; next }
    infm { next }
    /^!\[views\]/ { next }
    { print }
  '
}

# Write a reference file, preferring real fetched content and falling back to a
# link-stub only when the fetch fails (e.g. topic renamed/removed upstream).
create_topic_reference() {
  local topic=$1
  local target="$SKILL_DIR/references/${topic}.md"

  case "$SKIP_TOPICS" in
    *" $topic "*)
      echo "  - $topic (skipped, listed in SKIP_TOPICS)"
      return 0
      ;;
  esac

  if [ "$FORCE" -eq 0 ] && [ -f "$target" ]; then
    local existing_size
    existing_size=$(wc -c < "$target" | tr -d ' ')
    if [ "$existing_size" -ge "$MIN_REAL_BYTES" ]; then
      echo "  = $topic (skipped, already has $existing_size bytes of curated content)"
      return 0
    fi
  fi

  local body
  if ! body=$(fetch_and_clean_topic "$topic"); then
    echo "  ⚠ $topic (fetch failed, writing link-stub)"
    cat > "$target" <<EOT
# $topic

**Source**: [Drupal at Your Fingertips - $topic]($UPSTREAM_URL/$topic)
**Author**: Selwyn Polit

---

## Full Documentation

**View online**: $UPSTREAM_URL/$topic

Could not auto-fetch this chapter's content (page may have moved). Fetch it
manually and re-run this script, or update the topic slug if it changed.

---

**Last verified**: $(date -u +%Y-%m-%d)
EOT
    return 0
  fi

  # Pull the first H1 out of the body as the display title, and drop it from
  # the body so it isn't duplicated under our own header.
  local title
  title=$(printf '%s\n' "$body" | grep -m1 '^# ' | sed 's/^# //')
  [ -z "$title" ] && title="$topic"

  local body_no_title
  body_no_title=$(printf '%s\n' "$body" | awk '!done && /^# / { done=1; next } { print }')

  # Collapse runs of blank lines and trim leading blank lines.
  local body_clean
  body_clean=$(printf '%s\n' "$body_no_title" | awk 'BEGIN{blank=0} /^[[:space:]]*$/{blank++; if(blank<=1) print; next} {blank=0; print}' | sed '/./,$!d')

  {
    echo "# $title"
    echo ""
    echo "**Source**: [Drupal at Your Fingertips - $topic]($UPSTREAM_URL/$topic)"
    echo "**Author**: Selwyn Polit"
    echo ""
    echo "---"
    echo ""
    printf '%s\n' "$body_clean"
    echo ""
    echo "---"
    echo ""
    echo "**Last synced**: $(date -u +%Y-%m-%d)"
  } > "$target"

  echo "  ✓ $topic ($(wc -c < "$target" | tr -d ' ') bytes)"
}

# Discover all .md files from d9book repository
discover_d9book_topics() {
  local files=$(curl -s "https://api.github.com/repos/selwynpolit/d9book/contents/book" | \
    jq -r '.[] | select(.name | endswith(".md")) | .name' | \
    sed 's/\.md$//')

  if [ -z "$files" ]; then
    echo "⚠ Could not discover files via API"
    return 1
  fi

  echo "$files"
}

# Main execution
echo "Auto-discovering all topics from d9book repository..."
echo ""

discovered_topics=$(discover_d9book_topics)

if [ -z "$discovered_topics" ]; then
  echo "❌ Could not discover topics from d9book"
  exit 1
fi

topic_count=$(echo "$discovered_topics" | wc -l | xargs)
echo "Found $topic_count topics in d9book"
echo ""

create_d9book_skill
echo ""

echo "Fetching topic references..."
echo "$discovered_topics" | while read topic; do
  if [ -n "$topic" ]; then
    create_topic_reference "$topic"
  fi
done

# Sync metadata (kept alongside the skill, not shipped as skill content)
echo "Last synced: $(date -u +%Y-%m-%d)" > "$SKILL_DIR/.sync-metadata"
echo "Upstream: $UPSTREAM_REPO" >> "$SKILL_DIR/.sync-metadata"
echo "Topics synced: $topic_count" >> "$SKILL_DIR/.sync-metadata"

echo ""
echo "✅ Done! drupal-at-your-fingertips skill updated"
echo ""
echo "Skill: $SKILL_DIR/"
echo "References: $topic_count topic reference files"
