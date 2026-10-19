# STÆRK til iPhone

Native SwiftUI-app (iOS 17+) med Clean Architecture. Vaner, træning og krop gemmes lokalt med SwiftData. Apple Health er valgfrit.

Hjemmeskærmsnavn: **Styrke**. App-navn i UI: **STÆRK**.

## Krav

- Mac med **Xcode 15 eller nyere** (iOS 17 SDK)
- iPhone på **iOS 17+**
- Et **Apple ID** (gratis udviklerkonto er nok til at køre på egen telefon)

Dette repo kan **ikke** bygges på Linux. Der er ingen Xcode i CI-miljøet, så appen er skrevet til at compile, men ikke kørt på simulator eller iPhone.

## Arkitektur

```
Staerk/
  App/            App-entry, DI-container, rod-navigation
  Domain/         Entiteter, use cases, repository-protokoller
  Data/           SwiftData, HealthKit, notifikationer, backup, skabeloner
  Presentation/   SwiftUI, view models/helpers, tema, tastatur
StaerkTests/      Unit tests for streaks, progression, schedule, vaner, enheder, cirkelpas
```

Views indeholder ikke forretningslogik. Streaks, progression, cirkel-progress og ugeplan ligger i testbare use cases. Data-laget implementerer protokoller via SwiftData.

## Åbn projektet

1. Åbn `ios/Staerk.xcodeproj` i Xcode.
2. Vælg skemaet **Staerk** og en iPhone (eller simulator).

Hvis du har [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
cd ios
xcodegen generate
```

Uden XcodeGen kan projektet regenereres med:

```bash
cd ios
python3 scripts/generate_xcodeproj.py
```

`project.yml` og det committede `.xcodeproj` skal holde trit.

## Signing

1. Projekt **Staerk** → target **Staerk** → **Signing & Capabilities**.
2. **Automatically manage signing**.
3. Vælg **Team**. `DEVELOPMENT_TEAM` er tomt i repoet med vilje.
4. Bundle ID: `com.bjeld.apps.staerk`.
5. Capability **HealthKit** skal være synlig. Fjern den ikke.

## Første start

Nye brugere får et onboarding-flow: navn, enheder (kg/lb, cm/in), vaner fra skabeloner, træningsprogram (cirkel/LOOP, fuldkrop 3×, upper/lower, push/pull/legs, eller Martins LOOP-setup).

Alt er bruger-konfigurerbart:

- Vaner: ja/nej, tæller med mål, eller træning. Ugedage, påmindelse, rækkefølge, slet.
- Program: egne pas som **sæt/reps** eller **cirkel / fast loop** (valgfrit sted, stationer, tids-/rundemål), eller en skabelon. Ugeplan pr. ugedag.
- Cirkelpas logges med ét tryk (Færdig) plus valgfri tid, runder, indsats 1–5 og note. Ingen per-sæt tracking.
- Enheder og mål i Indstillinger.

## Migration

Eksisterende data fra 1.0-store `staerk-martin` (kreatin/vand/alkoholfri, program A/B, pas, målinger, fotos) kopieres ind i den nye `staerk`-store ved første start, hvis den gamle store findes. Onboarding springes over efter migration. Martins A/B-program konverteres til LOOP-cirkel man/ons/fre; gamle pas-logs bevares.

JSON-backup **version 1** kan stadig importeres og konverteres. Ny export er **version 2** (inkl. cirkelfelter). Et eksisterende Martin-program i den nuværende store migreres sikkert til LOOP ved første start.

Hvis migrationen ikke finder den gamle store, start onboarding, eller importer en backup under **Mere → Backup**.

## HealthKit

Første visning af **I dag** kan vise **Tillad adgang**. Appen **læser** skridt, gang/løb, aktiv energi, træningspas og kropsvægt, og **skriver** styrkepas (klassisk styrke) eller cirkelpas (funktionel styrke) samt vægt. Cirkelpas gemmes med den loggede varighed.

Hvis tilladelse afvises, virker resten af appen stadig.

## Tests

I Xcode: skema **Staerk** → **Product → Test** (⌘U).

Mål: `StaerkTests` — streaks, progression, ugeplan, vanescoring, enhedskonvertering, cirkel-progress og LOOP-migration.

## Sprog

Udviklingssprog er **dansk**. Alle UI-strenge ligger i `Staerk/Localizable.xcstrings` med dansk og engelsk. Enheden bestemmer sproget.

## Tastatur

Scroll views bruger `scrollDismissesKeyboard`. Tryk udenfor og en **Færdig**-knap på numerisk tastatur lukker tastaturet. `FocusState` bruges på steppere.

## Ikon og navn

Hjemmeskærmsnavn: **Styrke**. Accent: volt/neon.

## Hvis noget fejler

| Symptom | Tjek |
|---------|------|
| *Signing for "Staerk" requires a development team* | Vælg Team under Signing & Capabilities |
| *Failed to register bundle identifier* | Skift bundle ID |
| Health-ark vises ikke | Capability HealthKit mangler, eller simulator uden Health-data |
| Notifikationer kommer ikke | Tilladelse, Fokustilstand, og at vanens påmindelse er slået til |
| Gammel data mangler | Se **Migration**. Ellers importér JSON-backup |
