# Norn — Logo

The mark is a **right-facing cyborg profile** whose cranium is a **clock** —
a machine whose mind is time. This is the canonical Norn identity.

- **Palette:** gunmetal `#3A3D44` → white gradient (charcoal `#2A2C31`, `#55585F`, `#8B8E95`, `#ECEDEE`)
- **Background:** transparent.
- **Format:** SVG (crisp at any size). A 1024 PNG can be rasterised on demand.

## Files

| File | Use | Status |
|---|---|---|
| `norn-mark.svg` | Icon-only mark. Square, transparent. Use for app icon, favicon, avatar. | **Current** |
| `norn-lockup.svg` | Mark + `NORN` wordmark. Use for headers, splash, about screens. | **Current** |

> Legacy duplicates have been removed. Do not use deprecated branding in new code.

## Rasterise to PNG

```bash
magick -background none norn-mark.svg -resize 1024x1024 norn-mark-1024.png
```

## Brand concept prompt — Norn

Use this for brandkit / Midjourney / DALL·E / Recraft / Ideogram to generate
the brand boards.

```
Premium brand-kit overview image for "Norn", a multi-model AI chat client.

Brand strategy:
- category: AI chat application (developer/power-user leaning)
- audience: technical users who want many models, BYOK, offline options
- personality: precise, calm, intelligent, trustworthy, slightly mechanical
- core metaphor: time and fate — the Norns (Urðr, Verðandi, Skuld) weave destiny
  and govern past/present/future; the AI holds all three in one mind
- logo idea: a right-facing cyborg head whose cranium IS a clock — the machine's
  mind is time. Half-organic profile, half-mechanical skull, a clock fused into
  the brain-case, a subtle panel seam, minimalist hands at 10 and 2.

Layout: 3x3 presentation grid on a dark charcoal canvas, strong gutters, sparse
typography, large negative space, cinematic restraint.

Panels: logo cover (large mark + wordmark); logo construction (circle + jaw
geometry, clock breakdown, gradient axis); digital application (chat UI header,
app icon, prompt input bar); tagline ("Every model. One mind."); color system
(gunmetal-to-white gradient strip, ticks of #3A3D44 #55585F #8B8E95 #ECEDEE);
typography (geometric sans specimen, wide tracking); physical application
(embossed card, app icon tile); image direction (moody macro of brushed
gunmetal, halftone dusk, single shaft of light); system detail (clock-hand
states, icon set, input chip).

Visual mode: dark developer / builder — near-black panels, monospace accents,
subtle grid, restrained, premium.

Palette: charcoal canvas #15171A, mark in gunmetal→white gradient, single cool
steel accent, off-white type #ECEDEE. No rainbow, no neon, no generic purple AI
glow.

Style: premium, sparse, cinematic, intentional, brand-guidelines deck. No
clutter, no copied real-world logos, no cliché robot imagery, no cheap mockups.
Logo must be consistent and ownable across every panel.
```
