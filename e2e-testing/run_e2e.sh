#!/usr/bin/env bash
# E2E test: generate 3 stories via /v1/story, then narrate each via /v1/tts with different Gemini voices.
# Requires: wrangler dev running locally (edge/.dev.vars must have OPENAI_API_KEY + GOOGLE_SERVICE_ACCOUNT_JSON).
# Usage: ./e2e-testing/run_e2e.sh [base_url]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="${1:-http://127.0.0.1:8787}"
OUT_DIR="$SCRIPT_DIR/output"
mkdir -p "$OUT_DIR"

VOICES=("Achernar" "Algieba" "Fenrir")
VOICE_LABELS=("Achernar (female, Yumuşak Bulut)" "Algieba (male, Bilge Dede)" "Fenrir (male, Rüzgar)")

echo "============================================="
echo "  Masal Amca — E2E Test (Google Gemini TTS)"
echo "  Base URL: $BASE"
echo "============================================="
echo ""

for i in 1 2 3; do
  REQ="$SCRIPT_DIR/story_request_${i}.json"
  VOICE="${VOICES[$((i-1))]}"
  LABEL="${VOICE_LABELS[$((i-1))]}"

  echo "─── Test $i ───────────────────────────────────"
  echo "Payload: $(basename "$REQ")"
  echo "Voice:   $LABEL"
  echo ""

  # Step 1: Generate story
  echo "[1/2] Generating story via /v1/story ..."
  STORY_START=$(date +%s)
  STORY_RESP=$(curl -sS -w "\n%{http_code}" -X POST "$BASE/v1/story" \
    -H "Content-Type: application/json" \
    -H "X-Client-Version: 2" \
    --data-binary @"$REQ")

  STORY_HTTP=$(echo "$STORY_RESP" | tail -1)
  STORY_JSON=$(echo "$STORY_RESP" | sed '$d')
  STORY_END=$(date +%s)

  if [ "$STORY_HTTP" != "200" ]; then
    echo "  FAILED: HTTP $STORY_HTTP"
    echo "  Response: $(echo "$STORY_JSON" | head -c 500)"
    echo ""
    continue
  fi

  TITLE=$(echo "$STORY_JSON" | jq -r '.title // "?"')
  GENRE=$(echo "$STORY_JSON" | jq -r '.genre // "?"')
  WORD_COUNT=$(echo "$STORY_JSON" | jq -r '.word_count // "?"')
  BODY=$(echo "$STORY_JSON" | jq -r '.body // ""')
  BODY_LEN=${#BODY}

  echo "  Title:      $TITLE"
  echo "  Genre:      $GENRE"
  echo "  Words:      $WORD_COUNT"
  echo "  Body chars: $BODY_LEN"
  echo "  Time:       $((STORY_END - STORY_START))s"

  # Save story JSON
  echo "$STORY_JSON" | jq '.' > "$OUT_DIR/story_${i}.json"
  echo "  Saved:      output/story_${i}.json"
  echo ""

  # Step 2: TTS
  echo "[2/2] Narrating via /v1/tts (voice: $VOICE) ..."
  TTS_PAYLOAD=$(jq -n --arg text "$BODY" --arg voice "$VOICE" '{text: $text, voice_id: $voice, output_format: "mp3_44100_128"}')

  TTS_START=$(date +%s)
  TTS_HTTP=$(curl -sS -o "$OUT_DIR/narration_${i}_${VOICE}.mp3" -w "%{http_code}" \
    -X POST "$BASE/v1/tts" \
    -H "Content-Type: application/json" \
    -H "X-Client-Version: 2" \
    -d "$TTS_PAYLOAD")
  TTS_END=$(date +%s)

  if [ "$TTS_HTTP" != "200" ]; then
    echo "  FAILED: HTTP $TTS_HTTP"
    # If error, the output file contains JSON not audio
    if [ -f "$OUT_DIR/narration_${i}_${VOICE}.mp3" ]; then
      echo "  Response: $(head -c 500 "$OUT_DIR/narration_${i}_${VOICE}.mp3")"
      rm -f "$OUT_DIR/narration_${i}_${VOICE}.mp3"
    fi
    echo ""
    continue
  fi

  FILE_SIZE=$(wc -c < "$OUT_DIR/narration_${i}_${VOICE}.mp3" | tr -d ' ')
  FILE_TYPE=$(file -b "$OUT_DIR/narration_${i}_${VOICE}.mp3" | head -c 80)

  echo "  Status:     HTTP $TTS_HTTP"
  echo "  File size:  $FILE_SIZE bytes ($(( FILE_SIZE / 1024 )) KB)"
  echo "  File type:  $FILE_TYPE"
  echo "  Time:       $((TTS_END - TTS_START))s"
  echo "  Saved:      output/narration_${i}_${VOICE}.mp3"
  echo ""

  # Validate it's actually audio
  if echo "$FILE_TYPE" | grep -qi "audio\|mpeg\|mp3\|layer"; then
    echo "  ✅ Audio file valid"
  else
    echo "  ⚠️  File may not be valid audio: $FILE_TYPE"
  fi
  echo ""
done

echo "============================================="
echo "  All outputs saved to: $OUT_DIR/"
echo "============================================="
ls -lh "$OUT_DIR/"
