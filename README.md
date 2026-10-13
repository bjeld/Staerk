# STÆRK

Personlig styrke- og vaneapp til Martin — en dansk PWA til at bygge muskler efter 50, holde styr på kreatin, vand og alkoholfri dage, og følge vægt, talje og fotos.

Alt gemmes **kun lokalt** (IndexedDB). Ingen konto, ingen server, ingen tracking.

## Hvad appen gør

- **I dag** — checklists for kreatin, vand (glas med mål), alkoholfri dag, plus skridt/gåtur/golf. Træningspas vælges automatisk efter ugedag og sidste A/B-pas.
- **Træning** — fuldkropsprogram A/B, 3×/uge, ~45 min, 3 sæt × 8–12. Log vægt/reps, se sidste tal og progression. Øvelser kan redigeres.
- **Vaner** — rækker, ugeoversigt og kalender. Ugens sæt pr. muskelgruppe.
- **Fremskridt** — vægt, talje, grafer, komprimerede fotos og før/efter.
- **Indstillinger** — mål, lys/mørk/system, browser-påmindelser, JSON-export/import.

Programmet er lagt til mandag/onsdag/fredag tidligt på jobgymmet. Tirsdag/torsdag og weekend er restitution (gåtur/golf).

## Kør lokalt

Kræver Node.js 20+.

```bash
npm install
npm run dev
```

Åbn [http://127.0.0.1:47321](http://127.0.0.1:47321).

```bash
npm run build
npm run preview
```

## Installér som app (iPhone)

1. Åbn siden i Safari.
2. Del → **Føj til hjemmeskærm**.
3. Åbn STÆRK fra ikonet. Den virker offline, når den først er hentet.

Android: Chrome-menu → **Tilføj til startskærm**.

Notifikationer (kreatin kl. 06:15 som standard) kræver tilladelse. På iPhone: iOS 16.4+ og installeret på hjemmeskærmen. Påmindelsen affyres, når appen er åben eller bliver åbnet efter tidspunktet — en statisk PWA kan ikke vække telefonen i baggrunden pålidelig.

## Deploy (statisk host)

Bygget er rene filer i `dist/`.

```bash
npm run build
```

Upload `dist/` til Cloudflare Pages, Netlify, GitHub Pages eller enhver static host.

- Netlify/Cloudflare: `public/_redirects` sender alle ruter til `index.html`.
- GitHub Pages: kopiér `dist/index.html` til `dist/404.html`, så deep links virker.

Eksempel med Cloudflare Pages (wrangler):

```bash
npx wrangler pages deploy dist --project-name staerk
```

## Backup

**Indstillinger → Eksporter data** henter en JSON-fil med vaner, pas, mål og fotos (base64). Import overskriver alt på enheden.

## Stack

Vite, React, TypeScript, Tailwind CSS, Dexie (IndexedDB), Recharts, vite-plugin-pwa.
