# Masal Amca — Financial Analysis

Last updated: April 2026

> **Note:** The app migrated from ElevenLabs to Google Gemini Flash TTS in April 2026, reducing per-story TTS cost by ~75%. ElevenLabs figures below are historical. Current production cost: ~$0.10–0.12/story (OpenAI + Gemini TTS).

## Revenue Model


| Plan       | Price     | Apple (15%) | Net revenue              |
| ---------- | --------- | ----------- | ------------------------ |
| Monthly    | $9.99/mo  | $1.50       | **$8.49/mo**             |
| Yearly     | $99.99/yr | $15.00      | **$84.99/yr ($7.08/mo)** |
| Free trial | 3 days    | —           | —                        |


Free tier: 2 stories lifetime (customer acquisition cost).

## Cost Structure

### Per-Story Costs


| Service                | Model                         | Cost per story       |
| ---------------------- | ----------------------------- | -------------------- |
| OpenAI                 | GPT-4o-mini                   | ~$0.001 (negligible) |
| ElevenLabs             | Flash v2.5 (Pro overage)      | **$0.42**            |
| ElevenLabs             | Multilingual v2 (Pro overage) | $0.84                |
| Cloudflare Workers     | Free tier                     | $0                   |
| **Total (Flash v2.5)** |                               | **~$0.42/story**     |


### Assumptions

- Average story: ~635 words, ~3,500 Turkish characters
- ElevenLabs Pro plan: $99/mo, 1M chars included (Flash), $0.12/1K overage
- OpenAI GPT-4o-mini: ~$0.15/1M input tokens, ~$0.60/1M output tokens
- Premium users: up to 2 stories/day (60/month max)

## ElevenLabs Plan Comparison (Flash v2.5)


|                   | Pro       | Scale (monthly) | Scale (yearly) |
| ----------------- | --------- | --------------- | -------------- |
| Base cost         | $99/mo    | $330/mo         | **$275/mo**    |
| Included chars    | 1,000,000 | 4,000,000       | 4,000,000      |
| Included stories  | ~286      | ~1,143          | ~1,143         |
| Overage per 1K    | $0.12     | $0.09           | $0.09          |
| Overage per story | $0.42     | $0.315          | $0.315         |


## Usage Scenarios


| Scenario      | Stories/user/month | Description              |
| ------------- | ------------------ | ------------------------ |
| Best (light)  | 8                  | ~2 stories/week          |
| Average       | 20                 | ~5 stories/week          |
| Worst (power) | 60                 | 2 stories/day, every day |


## Profitability Analysis — Pro Plan ($99/mo, Flash v2.5)

Using net monthly revenue of $8.49/subscriber:


| Subscribers | Scenario | TTS chars/mo | ElevenLabs cost | Revenue | Profit/Loss | Margin |
| ----------- | -------- | ------------ | --------------- | ------- | ----------- | ------ |
| 10          | Best     | 280K         | $99             | $85     | **-$14**    | -16%   |
| 10          | Average  | 700K         | $99             | $85     | **-$14**    | -16%   |
| 25          | Best     | 700K         | $99             | $212    | **+$113**   | 53%    |
| 25          | Average  | 1.75M        | $189            | $212    | **+$23**    | 11%    |
| 50          | Best     | 1.4M         | $147            | $424    | **+$277**   | 65%    |
| 50          | Average  | 3.5M         | $399            | $424    | **+$25**    | 6%     |
| 100         | Best     | 2.8M         | $315            | $849    | **+$534**   | 63%    |
| 100         | Average  | 7.0M         | $819            | $849    | **+$30**    | 4%     |


## Profitability Analysis — Scale Yearly ($275/mo, Flash v2.5)


| Subscribers | Scenario | TTS chars/mo | ElevenLabs cost | Revenue | Profit/Loss | Margin |
| ----------- | -------- | ------------ | --------------- | ------- | ----------- | ------ |
| 25          | Best     | 700K         | $275            | $212    | **-$63**    | -30%   |
| 25          | Average  | 1.75M        | $275            | $212    | **-$63**    | -30%   |
| 35          | Best     | 980K         | $275            | $297    | **+$22**    | 7%     |
| 35          | Average  | 2.45M        | $275            | $297    | **+$22**    | 7%     |
| 50          | Best     | 1.4M         | $275            | $424    | **+$149**   | 35%    |
| 50          | Average  | 3.5M         | $275            | $424    | **+$149**   | 35%    |
| 75          | Best     | 2.8M         | $275            | $637    | **+$362**   | 57%    |
| 75          | Average  | 5.25M        | $388            | $637    | **+$249**   | 39%    |
| 100         | Best     | 2.8M         | $275            | $849    | **+$574**   | 68%    |
| 100         | Average  | 7.0M         | $545            | $849    | **+$304**   | 36%    |


## Break-Even Analysis

### Per-User Break-Even (stories/month)


| TTS Model             | Overage/story | Max stories to stay profitable |
| --------------------- | ------------- | ------------------------------ |
| Flash v2.5 (Pro)      | $0.42         | ~20 stories/month              |
| Flash v2.5 (Scale)    | $0.315        | ~27 stories/month              |
| Multilingual v2 (Pro) | $0.84         | ~10 stories/month              |


### Subscriber Break-Even (when revenue covers ElevenLabs base + overage)


| Plan                   | Average usage break-even | Light usage break-even |
| ---------------------- | ------------------------ | ---------------------- |
| Pro ($99/mo)           | ~13 subscribers          | ~12 subscribers        |
| Scale yearly ($275/mo) | ~35 subscribers          | ~33 subscribers        |


### Plan Crossover Point

At **~35 average-usage subscribers**, Scale yearly becomes cheaper than Pro. Below that, Pro wins due to lower base cost.

## Recommended Strategy


| Phase  | Subscribers | ElevenLabs Plan            | Rationale                               |
| ------ | ----------- | -------------------------- | --------------------------------------- |
| Launch | 0-34        | **Pro ($99/mo)**           | Lower base cost; overage manageable     |
| Growth | 35-50+      | **Scale yearly ($275/mo)** | 4M included chars absorbs average usage |
| Scale  | 100+        | Scale yearly or Business   | Higher included chars, lower overage    |


## Free Tier Cost

Each free user gets 2 stories lifetime:

- Cost: 2 × $0.42 = **$0.84 per free user**
- This is a reasonable customer acquisition cost

## Cost Reduction Levers

1. **TTS model**: Flash v2.5 vs Multilingual v2 (already using Flash — 50% savings)
2. **Daily limit**: Currently 2/day; reducing to 1/day halves worst-case cost
3. **Audio caching**: Stories are cached locally; replays cost $0
4. **Story length**: Shorter stories = fewer characters = lower TTS cost
5. **Price increase**: $14.99/mo would make average usage profitable even on Multilingual v2

## Monthly Projection (50 subscribers, average usage, Scale yearly)


| Item                             | Amount          |
| -------------------------------- | --------------- |
| Revenue (50 × $8.49)             | $424.50         |
| ElevenLabs (within 4M included)  | -$275.00        |
| OpenAI (~1,000 stories × $0.001) | -$1.00          |
| Cloudflare                       | $0              |
| **Net profit**                   | **+$148.50/mo** |
| **Annual profit**                | **+$1,782/yr**  |

## See also

- **[TTS_ALTERNATIVES_REPORT.md](TTS_ALTERNATIVES_REPORT.md)** — Comparison of non–ElevenLabs TTS options (Turkish, custom voices, relative economics).

