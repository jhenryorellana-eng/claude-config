# Elicitation Reference

The interview script the skill runs **before** generating HTML. The goal: gather just enough context to produce a great deck without making the user fill out a form.

---

## Decision rule: when to interview

**Skip the interview** (go straight to generation) if the user's prompt already contains:
- Specific images attached or pasted URLs
- Concrete data points ("una presentación sobre la Torre Eiffel: 330m, año 1889, 7M visitantes/año")
- A clear tone or audience signal ("corporativo y minimalista", "para mi clase de 5to grado")
- "rápido", "sin preguntar", "usa defaults", "genera ya"

**Run the interview** if the prompt is bare ("crea una presentación sobre la Torre Eiffel", "hazme un deck de Netflix").

When in doubt, *do* interview — but make it short and skippable.

---

## The interview (max 4 questions, single message)

Send all 4 questions in **one** message using the `ask_user_input_v0` tool when available, or as a numbered list if not. Don't drip-feed. Let the user answer in one batch or skip.

Open with one warm sentence: "Antes de armarla, dame 30 segundos de contexto para que quede a tu medida (o decime 'genera ya' y uso defaults inteligentes):"

### Question 1 — Imágenes (most important)

> **¿Tenés imágenes para usar?** Adjuntalas o pegame URLs. Idealmente:
> - 1 imagen "hero" del sujeto principal (la que va a aparecer en todas las slides, preferiblemente vertical/cuadrada de alta resolución)
> - 2-3 imágenes secundarias para los thumbnails y la slide de "media moment"
>
> *Si no tenés, buscaré en Unsplash automáticamente.*

This is the single highest-leverage question. A great hero image transforms the whole deck. The skill should *always* ask for it.

### Question 2 — Datos reales

> **¿Hay 3-4 datos o cifras que querés destacar?** Ejemplo: "altura 330m, año 1889, visitantes 7M/año, peso 10.100 toneladas".
>
> *Si no, los investigo en la web.*

If the user provides data, use it verbatim. If not, the skill must `web_search` real numbers — never fabricate.

### Question 3 — Tono y audiencia

> **¿Qué tono y para quién?** Elegí o describí:
> - 📰 Editorial / revista de viajes
> - 💼 Corporativo / pitch deck
> - ✨ Lujo / premium
> - 🎓 Educativo / didáctico
> - 🎨 Creativo / artístico
> - 🚀 Tech / startup
>
> *Defaultea a editorial si no contestás.*

Tone drives palette + typography + copy register. See `design-system.md` for tone→palette mappings.

### Question 4 — Cierre

> **¿Cómo cierra la última slide?**
> - 🎯 Con un CTA (botón "Reservar visita", "Empezar prueba")
> - 💬 Con una cita o frase final + imagen hero
> - 📍 Con datos de contacto / ubicación
>
> *Default: cita final.*

---

## What NOT to ask

These are the skill's job to decide, not the user's:
- Color palette (derive from topic + tone)
- Typography pairing (derive from tone)
- Slide count (5 unless topic is very thin)
- Animation timing/easing (use defaults from morph-animations.md)
- Specific micro-interactions (apply the catalog)
- Layout details (use the blueprints)

If the user volunteers preferences on these things, honor them. But never *ask*.

---

## Handling user responses

### "Genera ya" / "usa defaults" / silence

Proceed with:
- Hero image: `web_search` for "[topic] official photo high resolution" → use first credible result. Or Unsplash hotlink: `https://source.unsplash.com/1600x1200/?<topic-slug>`
- Data: `web_search` for "[topic] key facts statistics"
- Tone: editorial
- Cierre: quote

### Partial answers (e.g., user provides images but skips data)

Proceed with the user's input for what they gave, fill the rest from defaults/web. Never re-interrogate.

### User pastes a wall of context

Parse it. Extract:
- Image URLs → use as hero/thumbs
- Numbers/dates → use as stats
- Adjectives ("luxe", "minimal", "vibrante") → infer tone
- Names of audiences ("inversores", "alumnos") → infer tone

Don't ask again. Just generate.

### User uploads files

Check `/mnt/user-data/uploads/`. Any images go into the deck. If videos: extract a frame as poster image and embed video tag in the media-showcase slide.

---

## Confirmation step (optional, single line)

After the interview, before generating, **briefly** confirm the plan in one sentence:

> "Listo: 5 slides sobre [topic], paleta [color-name] + tipografía [font-pair], cierre con [variant]. Generando…"

Then start generating. Don't wait for re-confirmation. The user can always ask for changes after seeing the output.

---

## Re-iteration flow

After delivering the first version, *briefly* offer:

> "¿Querés que ajuste algo? Las palancas comunes son: paleta, tipografía, copy de un slide específico, o cambiar el hero por otra imagen."

Then stop. Don't list options aggressively. The user will say what they want.

When they request a change:
- **Palette swap**: read `design-system.md` table, pick alternate
- **Font swap**: read `design-system.md` pairings, pick alternate
- **Copy change on slide N**: edit only that slide's text in the HTML
- **New hero image**: replace the `background-image` URL on `#hero`
- **Reorder slides**: rewrite timeline labels and click-cursor sequence
- **Add a slide**: insert a new blueprint between existing ones, update labels array

For small edits, **edit the existing file** instead of regenerating from scratch. Preserves the user's iterations.
