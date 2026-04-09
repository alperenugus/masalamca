#!/usr/bin/env bash
# E2E test: generate 3 stories via /v1/story, then narrate each via /v1/tts; then legacy /v1/story + /v1/tts.
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

echo ""
echo "─── Legacy format test ────────────────────────"
echo "Payload: story_request_legacy.json (v1.2 messages format)"
echo ""
LEGACY_REQ="$SCRIPT_DIR/story_request_legacy.json"
LEGACY_VOICE="${VOICES[0]}"
echo "[1/2] Generating story via /v1/story (legacy path) ..."
LEGACY_START=$(date +%s)
LEGACY_RESP=$(curl -sS -w "\n%{http_code}" -X POST "$BASE/v1/story" \
  -H "Content-Type: application/json" \
  --data-binary @"$LEGACY_REQ")
LEGACY_HTTP=$(echo "$LEGACY_RESP" | tail -1)
LEGACY_JSON=$(echo "$LEGACY_RESP" | sed '$d')
LEGACY_END=$(date +%s)

if [ "$LEGACY_HTTP" != "200" ]; then
  echo "  ❌ FAILED: HTTP $LEGACY_HTTP"
  echo "  Response: $(echo "$LEGACY_JSON" | head -c 500)"
else
  TITLE=$(echo "$LEGACY_JSON" | jq -r '.title // "?"')
  echo "  ✅ Story OK — Title: $TITLE  Time: $((LEGACY_END - LEGACY_START))s"
  echo "$LEGACY_JSON" | jq '.' > "$OUT_DIR/story_legacy.json"
  echo "  Saved: output/story_legacy.json"

  LEGACY_BODY=$(echo "$LEGACY_JSON" | jq -r '.body // ""')
  echo ""
  echo "[2/2] Narrating legacy story via /v1/tts (voice: $LEGACY_VOICE) ..."
  LEGACY_TTS_PAYLOAD=$(jq -n --arg text "$LEGACY_BODY" --arg voice "$LEGACY_VOICE" '{text: $text, voice_id: $voice, output_format: "mp3_44100_128"}')
  LEGACY_TTS_START=$(date +%s)
  LEGACY_TTS_HTTP=$(curl -sS -o "$OUT_DIR/narration_legacy_${LEGACY_VOICE}.mp3" -w "%{http_code}" \
    -X POST "$BASE/v1/tts" \
    -H "Content-Type: application/json" \
    -d "$LEGACY_TTS_PAYLOAD")
  LEGACY_TTS_END=$(date +%s)

  if [ "$LEGACY_TTS_HTTP" != "200" ]; then
    echo "  ❌ TTS FAILED: HTTP $LEGACY_TTS_HTTP"
    if [ -f "$OUT_DIR/narration_legacy_${LEGACY_VOICE}.mp3" ]; then
      echo "  Response: $(head -c 500 "$OUT_DIR/narration_legacy_${LEGACY_VOICE}.mp3")"
      rm -f "$OUT_DIR/narration_legacy_${LEGACY_VOICE}.mp3"
    fi
  else
    LEGACY_FILE_SIZE=$(wc -c < "$OUT_DIR/narration_legacy_${LEGACY_VOICE}.mp3" | tr -d ' ')
    LEGACY_FILE_TYPE=$(file -b "$OUT_DIR/narration_legacy_${LEGACY_VOICE}.mp3" | head -c 80)
    echo "  Status:     HTTP $LEGACY_TTS_HTTP"
    echo "  File size:  $LEGACY_FILE_SIZE bytes ($(( LEGACY_FILE_SIZE / 1024 )) KB)"
    echo "  File type:  $LEGACY_FILE_TYPE"
    echo "  Time:       $((LEGACY_TTS_END - LEGACY_TTS_START))s"
    echo "  Saved:      output/narration_legacy_${LEGACY_VOICE}.mp3"
    if echo "$LEGACY_FILE_TYPE" | grep -qi "audio\|mpeg\|mp3\|layer"; then
      echo "  ✅ Audio file valid"
    else
      echo "  ⚠️  File may not be valid audio: $LEGACY_FILE_TYPE"
    fi
  fi
fi
echo ""

echo "============================================="
echo "  Complete. All outputs in: $OUT_DIR/"
echo "============================================="
ls -lh "$OUT_DIR/"
