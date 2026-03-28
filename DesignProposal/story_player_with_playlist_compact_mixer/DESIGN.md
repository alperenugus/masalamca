```markdown
# Design System Document: The Dreamscape Narrative

## 1. Overview & Creative North Star: "The Digital Starlit Blanket"
This design system is engineered to transform a mobile device into a soothing, magical companion for children’s bedtime. Our Creative North Star is **"The Digital Starlit Blanket."** 

Unlike standard utility apps, this system avoids rigid grids and harsh transitions. It embraces **Intentional Asymmetry** and **Soft Depth** to mimic the feeling of flipping through a high-end, physical storybook under a soft lamp. We break the "template" look by layering translucent surfaces and using expansive typography scales that prioritize legibility and wonder over information density.

## 2. Colors: The Midnight Palette
The palette is rooted in the transition from dusk to deep sleep. We use deep navies to ground the experience and soft purples to evoke a sense of magic.

### Color Tokens
*   **Background / Surface:** `#041329` (The infinite night sky).
*   **Primary (Magic):** `#c8bfff` (Soft Lavender). Use for high-priority interactive elements.
*   **Secondary (Cozy):** `#b9c7e4` (Dusty Blue). Use for supporting elements.
*   **Tertiary (Star):** `#e9c400` (Warm Gold). Reserved strictly for "Magical" moments, progress, and star-based rewards.

### The "No-Line" Rule
**1px solid borders are strictly prohibited.** To define boundaries between sections (e.g., a story category and the main feed), use background color shifts. Place a `surface_container_low` section atop the `surface` background. The contrast should be felt, not seen as a line.

### Surface Hierarchy & Nesting
Treat the UI as a series of stacked, frosted glass sheets.
1.  **Base Layer:** `surface` (#041329)
2.  **Navigation/Content Blocks:** `surface_container` (#112036)
3.  **Individual Cards:** `surface_container_high` (#1c2a41)

### The "Glass & Gradient" Rule
To elevate the experience, use **Glassmorphism** for floating controls (like the Audio Player). Apply a `primary_container` color at 40% opacity with a `20px` backdrop blur. 
*   **Signature Texture:** Main CTA buttons should not be flat. Use a linear gradient from `primary_container` (#6A5ACD) to `primary` (#c8bfff) at a 135° angle to give the button a "glowing" soul.

## 3. Typography: The Editorial Voice
We utilize **Plus Jakarta Sans** for high-impact headlines to provide a modern, friendly character, while **Manrope** handles body text for peak legibility during nighttime reading.

*   **Display Large (3.5rem):** Use for "Once Upon a Time" style intros. (Plus Jakarta Sans)
*   **Headline Medium (1.75rem):** Use for Story Titles (*Örn: Uykucu Tavşan*).
*   **Title Medium (1.125rem):** Use for Category headers.
*   **Body Large (1rem):** The primary reading size for parents and children. Increased line-height (1.6) is mandatory for readability in low light. (Manrope)
*   **Label Medium (0.75rem):** Used for metadata like "5 Dakika" (Duration) or "3-6 Yaş".

## 4. Elevation & Depth: Tonal Layering
Traditional drop shadows are too "industrial" for a bedtime app. We use **Tonal Layering** to create a soft, natural lift.

*   **The Layering Principle:** Instead of shadows, place a `surface_container_lowest` card on a `surface_container_low` background. This creates a "recessed" look that feels like an etched star in the sky.
*   **Ambient Shadows:** If an element must float (e.g., a "Play" button), use a shadow color tinted with the primary purple: `rgba(106, 90, 205, 0.15)` with a blur of `24px` and a Y-offset of `8px`.
*   **The "Ghost Border" Fallback:** If a container is lost against the background, use the `outline_variant` token at **15% opacity**. Never use 100% opacity for outlines.

## 5. Components: Practical Magic
Components must feel "touchable" and soft. All components utilize the **`xl` (3rem)** or **`lg` (2rem)** roundedness tokens to ensure a child-friendly feel.

### Buttons (Butonlar)
*   **Primary Button:** Gradient fill (`primary_container` to `primary`), `xl` rounded corners, white text (`on_primary_container`).
*   **Secondary Button:** Ghost style. No background, `outline_variant` at 20% opacity, `title-md` typography.

### Cards (Kartlar)
*   **Story Cards:** Forbid dividers. Use `surface_container_high` for the card background. Separate the story image and the title using a `3` (1rem) spacing token.
*   **Active Reading Card:** Uses a backdrop blur effect to sit "above" the story text, housing audio controls.

### Chips (Etiketler)
*   Used for genres (e.g., *Macera, Uyku, Eğitici*).
*   **Style:** `surface_container_highest` background with `label-md` text. No borders.

### Input Fields (Giriş Alanları)
*   For parent gate or search. Use `surface_container_low` with a soft-focus `primary` glow when active.

### Context-Specific Components
*   **The Star Progress Bar:** A custom linear progress bar using `tertiary` (#FFD700) for the fill, with a glowing "Star" SF Symbol trailing at the current progress point.
*   **Sleep Timer Dial:** A circular glassmorphic element that uses subtle haptic feedback on every "tick."

## 6. Do's and Don'ts

### Do
*   **Use Turkish warm greetings:** Use "İyi Geceler, [İsim]" (Goodnight) instead of a generic "Hoşgeldiniz."
*   **Embrace negative space:** Use the `8` (2.75rem) spacing token between major content sections to prevent the UI from feeling "crowded" and stressful.
*   **Animate Transitions:** Every screen change should feel like a "fade" or a "soft slide," never a harsh snap.

### Don't
*   **Don't use pure black:** It is too high-contrast for a sleep app. Always use `surface` (#041329).
*   **Don't use sharp corners:** Children’s products should feel soft. Avoid any corner radius below `sm` (0.5rem).
*   **Don't use Divider Lines:** If you feel the need for a line, increase the vertical whitespace (Spacing Scale) instead.
*   **Don't use SF Symbols in "Fill" mode exclusively:** Use the "Light" or "Regular" weight symbols to maintain the minimalist, airy vibe.

---
*Document Version 1.0 - Directed for junior design implementation.*```