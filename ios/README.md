# Styrke til iPhone

Native SwiftUI-app. Den kører lokalt på iPhone med SwiftData, Swift Charts, PhotosPicker og Apple Health.

## Krav

- Mac med **Xcode 15 eller nyere** (iOS 17 SDK)
- Martin’s iPhone på **iOS 17+**
- Et **Apple ID** (gratis udviklerkonto er nok til at køre på egen telefon)
- USB-kabel, eller samme Wi-Fi til trådløs debugging

Dette repo kan **ikke** bygges på Linux. Der er ingen Xcode her, så appen er skrevet til at compile, men ikke kørt på simulator eller iPhone.

## Åbn projektet

1. Åbn `ios/Staerk.xcodeproj` i Xcode (dobbeltklik, eller `open ios/Staerk.xcodeproj`).
2. Vælg skemaet **Staerk** og destinationen **Martin’s iPhone** (eller en iPhone-simulator).

Hvis du har [XcodeGen](https://github.com/yonaskolb/XcodeGen) installeret, kan du regenerere projektet fra `project.yml`:

```bash
cd ios
xcodegen generate
```

`project.yml` og det committede `.xcodeproj` skal holde trit. Regenerering er valgfri — projektet er allerede genereret.

## Signing (påkrævet før iPhone)

1. I Xcode: klik på projektet **Staerk** i navigatoren → target **Staerk**.
2. Fanen **Signing & Capabilities**.
3. Sæt flueben i **Automatically manage signing**.
4. Vælg dit **Team** (dit Apple ID). `DEVELOPMENT_TEAM` er tomt i repoet med vilje.
5. Bundle ID er `com.bjeld.apps.staerk`. Hvis Xcode klager over at ID’et er optaget, skift det til fx `com.bjeld.apps.staerk.martin`.
6. Capability **HealthKit** skal være synlig (den kommer fra `Staerk.entitlements`). Fjern den ikke.

Første gang du kører på telefonen:

1. iPhone: **Indstillinger → Generelt → VPN og enhedsadministration** (eller **Privatliv og sikkerhed → Udviklertilstand**) og slå **Udviklertilstand** til. Telefonen genstarter.
2. På iPhone: tillad udviklercertifikatet, hvis iOS spørger.
3. I Xcode: **Product → Run** (⌘R).

## HealthKit

Første åbning af **I dag** viser et kort **Tillad adgang**. iOS viser derefter Health-arket.

Appen **læser**

- skridt
- gang- og løbeafstand
- aktiv energi
- træningspas (inkl. golf, gåtur, styrke)
- kropsvægt

og **skriver**

- styrketræningspas, når et pas gemmes som afsluttet
- kropsvægt, når en vægt logges under **Krop**

Usage-teksterne i `Info.plist` er på dansk. Hvis tilladelse afvises, virker resten af appen stadig; Health-kortet forklarer, hvordan man slår adgang til i Indstillinger.

## Data

Alt gemmes i SwiftData på enheden (`staerk-martin`). Ingen konto, ingen server.

Under **Mere → Backup** kan du eksportere/importere JSON (`version: 1`). Import overskriver alt på enheden.

## Faner

| Fane | Indhold |
|------|---------|
| **I dag** | Fitness-ringe (kreatin, vand, alkoholfri), Health-aktivitet, vaner, golf/gåtur |
| **Træning** | Program A/B, sæt-log med sidste tal og progression, historik |
| **Vaner** | Streaks, ugeoversigt, sæt pr. muskel, månedskalender |
| **Krop** | Vægt, talje, grafer, fotos og før/efter |
| **Mere** | Navn, mål, lys/mørk/system, Health, notifikationer, backup |

Programmet er mandag/onsdag/fredag styrke på jobbet før kl. 7, tirsdag/torsdag hjemme/restitution, weekend golf/gåtur. A/B roterer efter sidste afsluttede pas.

## Notifikationer

**Mere → Tillad notifikationer**, derefter:

- **Kreatin** hver dag kl. det valgte tidspunkt (standard 06:15)
- **Træning** mandag, onsdag og fredag på samme tidspunkt

Lokale påmindelser kan komme, mens appen er lukket.

## Ikon og navn

Hjemmeskærmsnavn: **Styrke**. Ikonet er en lime bolt.

## Hvis noget fejler

| Symptom | Tjek |
|---------|------|
| *Signing for "Staerk" requires a development team* | Vælg Team under Signing & Capabilities |
| *Failed to register bundle identifier* | Skift bundle ID |
| Health-ark vises ikke | Capability HealthKit mangler, eller simulator uden Health-data |
| Notifikationer kommer ikke | Tilladelse, Fokustilstand, og at tidspunktet er i fremtiden |
| Fotos kan ikke vælges | PhotosPicker kræver ikke fotobiblioteks-permission; prøv et andet billede |
