# Google Play – Store-Eintrag und App-Inhalte

Zum Kopieren in die Play Console (App **Candle**, `de.freegroup.candle.app`).
Die Texte beschreiben nur Funktionen, die die App heute hat – bitte bei neuen Funktionen nachziehen.

## Store-Eintrag (Wachstum → Store-Präsenz → Haupteintrag)

Standardsprache: **Deutsch (de-DE)**, Übersetzung: **Englisch (en-US)**

### Deutsch

**App-Name** (30/30)
```
Candle – Navigation für Blinde
```

**Kurzbeschreibung** (71/80)
```
Orientierung für blinde Menschen: Kompass, Orte in der Nähe und Fußwege
```

**Vollständige Beschreibung** (1606/4000)
```
Candle hilft blinden und sehbehinderten Menschen, sich unterwegs zu orientieren. Die App ist von Grund auf für VoiceOver und TalkBack gebaut: große Schaltflächen, klare Ansagen und Vibration statt Blick auf die Karte.

KOMPASS
• Richtung per Vibration: Candle vibriert, wenn du das Handy nach Norden oder in eine der acht Himmelsrichtungen hältst, und sagt sie an.
• Kompass zu einem Ziel: Halte das Handy vor dich – Candle sagt dir Richtung und Entfernung zu deinem Ziel.

ORTE IN DER NÄHE
• Erkunden: Cafés, Restaurants, Apotheken, Geldautomaten, Haltestellen, Taxistände, Krankenhäuser, öffentliche Toiletten, Fußgängerüberwege und Ampeln mit Tonsignal – sortiert nach Entfernung, während du gehst.
• Radar: Zeig mit dem Handy in eine Richtung und höre, welche Orte dort liegen.
• Wikipedia: Artikel über Sehenswürdigkeiten in deiner Umgebung.

EIGENE ORTE UND WEGE
• Lieblingsorte speichern – über die aktuelle Position oder die Adresssuche, auch per Spracheingabe.
• Fußgängernavigation zu gespeicherten Orten.
• Sprachnotizen (Voice-Pins): Sprich an einer Stelle einen Hinweis ein, z. B. „Treppe nach der Tür“.
• Orte teilen und von Familie oder Freunden empfangen.
• Wege aufzeichnen (Beta).

DATENSCHUTZ
Keine Anmeldung, keine Werbung, kein Tracking. Deine Orte, Wege und Sprachnotizen bleiben auf deinem Gerät. Für Karten, Orte und Routen nutzt Candle offene Dienste wie OpenStreetMap.

OPEN SOURCE
Candle ist kostenlos und quelloffen: github.com/freegroup/candle
Fehler gefunden oder eine Idee? Wir freuen uns über Rückmeldungen – besonders von blinden und sehbehinderten Nutzerinnen und Nutzern.
```

### Englisch

**App name** (25/30)
```
Candle – Blind Navigation
```

**Short description** (71/80)
```
Orientation for blind people: compass, nearby places and walking routes
```

**Full description** (1466/4000)
```
Candle helps blind and visually impaired people find their way. The app is built for VoiceOver and TalkBack from the ground up: large buttons, clear announcements and vibration instead of looking at a map.

COMPASS
• Direction by vibration: Candle vibrates when you point your phone north or in one of the eight compass directions, and announces it.
• Compass to a destination: hold the phone in front of you – Candle tells you the direction and distance to your destination.

PLACES NEARBY
• Explore: cafés, restaurants, pharmacies, ATMs, bus stops, taxi stands, hospitals, public toilets, pedestrian crossings and traffic lights with sound signals – sorted by distance while you walk.
• Radar: point your phone in a direction and hear which places are there.
• Wikipedia: articles about sights around you.

YOUR PLACES AND ROUTES
• Save favourite places – from your current position or by address search, also by voice.
• Walking navigation to saved places.
• Voice pins: record a spoken note at a spot, e.g. "stairs after the door".
• Share places and receive them from family and friends.
• Record routes (beta).

PRIVACY
No sign-up, no ads, no tracking. Your places, routes and voice pins stay on your device. For maps, places and routes Candle uses open services such as OpenStreetMap.

OPEN SOURCE
Candle is free and open source: github.com/freegroup/candle
Found a bug or have an idea? We welcome feedback – especially from blind and visually impaired users.
```

### Grafiken

| Feld | Datei | Status |
|------|-------|--------|
| App-Symbol 512×512 | `docs/icon.png` | ✅ |
| Vorschaugrafik 1024×500 | `app/assets/images/google_store_preview.png` | ✅ |
| Smartphone-Screenshots (2–8, max. Seitenverhältnis 2:1) | `store/screenshots/android/` | ⏳ werden per Emulator erstellt |

### Kategorie und Kontakt (Store-Einstellungen)

- App-Kategorie: **Karten & Navigation**
- Tags: Navigation, Barrierefreiheit
- E-Mail: *Adresse des Entwicklerkontos*
- Website: `https://freegroup.github.io/candle/`

## App-Inhalte (Richtlinie → App-Inhalte)

| Punkt | Antwort |
|-------|---------|
| Datenschutzerklärung | `https://freegroup.github.io/candle/` |
| Werbung | Nein, die App enthält keine Werbung |
| App-Zugriff | Alle Funktionen sind ohne besonderen Zugriff verfügbar |
| Einstufung (Fragebogen) | Kategorie „Dienstprogramm, Produktivität, Kommunikation oder Sonstiges“; alle Inhaltsfragen **Nein**; „Teilt die App den aktuellen Standort mit anderen Nutzern?“ **Ja** (Funktion „Position teilen“) |
| Zielgruppe | 13–15, 16–17, 18+ (nicht unter 13) |
| Nachrichten-App | Nein |
| Gesundheits-Apps | Keine Gesundheitsfunktionen |
| Finanzfunktionen | Keine |
| Regierungs-App | Nein |

### Datensicherheit

Allgemein:
- Erhebt oder teilt die App Nutzerdaten? **Ja**
- Werden alle Daten bei der Übertragung verschlüsselt? **Ja** (nur HTTPS)
- Kontoerstellung: **Die App erlaubt keine Kontoerstellung**
- Möglichkeit, Löschung zu beantragen: **Nein** (es werden keine personenbezogenen Daten gespeichert)

Datentypen:

| Datentyp | Erhoben | Geteilt | Nur flüchtig verarbeitet | Erforderlich | Zweck |
|----------|---------|---------|--------------------------|--------------|-------|
| Standort → Genauer Standort | Ja | Ja (Overpass, openrouteservice, Nominatim, Wikipedia) | Ja | Erforderlich | App-Funktionen |
| App-Aktivitäten → Suchverlauf in der App | Ja | Ja (Nominatim, Adresssuche) | Ja | Optional | App-Funktionen |
| Geräte- oder andere IDs | Ja (anonyme Installations-ID) | Nein | Nein | Erforderlich | App-Funktionen; Betrugsprävention, Sicherheit und Compliance |

Alle anderen Datentypen: nicht erhoben. (Sprachnotizen bleiben auf dem Gerät; die Spracheingabe erledigt der Spracherkenner des Betriebssystems.)

### Berechtigungen

- **Standort im Hintergrund:** nicht mehr angefordert (seit 1.4.5, entfernt aus `AndroidManifest.xml`).
- **Vordergrunddienst „Standort“** (`FOREGROUND_SERVICE_LOCATION`): falls die Console die Erklärung verlangt – Aufgabe *Navigation/Routenaufnahme*, vom Nutzer gestartet, Benachrichtigung sichtbar, endet beim Stoppen der Aufnahme. Google verlangt dazu ein kurzes Video (z. B. nicht gelistetes YouTube-Video), das die Aufnahme zeigt.
