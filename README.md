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

## GitHub Pages

Live-host er **GitHub Pages** på kontoen **[bjeld](https://github.com/bjeld)** (ikke Cloudflare). Workflowen `.github/workflows/pages.yml` bygger med base path `/health-app/` og publicerer `dist/`.

Offentlig URL, når `bjeld/health-app` er oprettet og Action’en har kørt:

**https://bjeld.github.io/health-app/**

1. Opret det **offentlige** repo [github.com/bjeld/health-app](https://github.com/bjeld/health-app).
2. Push `main` til det repo.
3. Repo → Settings → Pages → **Source: GitHub Actions** (første workflow-kørsel slår det ofte til selv).
4. Vent på workflowen **Deploy GitHub Pages**.

Lokalt tjek af samme subpath:

```bash
VITE_BASE=/health-app/ npm run build
npm run preview
```

Åbn derefter [http://127.0.0.1:47321/health-app/](http://127.0.0.1:47321/health-app/).

`dist/404.html` er en kopi af `index.html`, så deep links virker. `public/.nojekyll` forhindrer Jekyll i at skjule filer.

## Backup

**Indstillinger → Eksporter data** henter en JSON-fil med vaner, pas, mål og fotos (base64). Import overskriver alt på enheden.

## Stack

Vite, React, TypeScript, Tailwind CSS, Dexie (IndexedDB), Recharts, vite-plugin-pwa.
