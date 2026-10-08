# App Store – Eintrag und App-Datenschutz

App **Candle** (`de.freegroup.candle`, App Store Connect App-ID 6478289375). Die Texte beschreiben
nur, was die iOS-App heute kann; keine Hinweise auf andere Plattformen (Apple-Richtlinie 2.3.10).
`node store/app-store-upload.mjs` überträgt Texte, Screenshots und Build in die Version, die gerade
bearbeitet wird; einreichen und den Fragebogen „App-Datenschutz“ macht man in App Store Connect.

Screenshots: `store/screenshots.sh "iPhone 17 Pro Max" iphone-6.9` und
`store/screenshots.sh "iPad Pro 13-inch (M5)" ipad-13` → `store/screenshots/ios/`.

## Deutsch (de-DE)

**Name** (30)
```
Candle – Navigation für Blinde
```

**Untertitel** (30)
```
Kompass, Orte und Fußwege
```

**Werbetext** (170)
```
Neu: Ansagen bei der Navigation wählbar – ausführlich oder kurz („50 Meter, links“). Hinweise wie „Ort gespeichert“ unterbrechen VoiceOver, damit nichts verloren geht.
```

**Stichwörter** (100, durch Komma getrennt)
```
blind,sehbehindert,VoiceOver,Kompass,barrierefrei,Fußgänger,Orte,Radar,Blindennavigation,Ampel
```

**Beschreibung**
```
Candle hilft blinden und sehbehinderten Menschen, sich unterwegs zu orientieren. Die App ist von Grund auf für VoiceOver gebaut: große Schaltflächen, klare Ansagen und Vibration statt Blick auf die Karte.

KOMPASS
• Richtung per Vibration: Candle vibriert, wenn du das iPhone nach Norden oder in eine der acht Himmelsrichtungen hältst, und sagt sie an.
• Kompass zu einem Ziel: Halte das iPhone vor dich – Candle sagt dir Richtung und Entfernung zu deinem Ziel.

ORTE IN DER NÄHE
• Erkunden: Cafés, Restaurants, Apotheken, Geldautomaten, Haltestellen, Taxistände, Krankenhäuser, öffentliche Toiletten, Fußgängerüberwege und Ampeln mit Tonsignal – sortiert nach Entfernung, während du gehst.
• Radar: Zeig mit dem iPhone in eine Richtung und höre, welche Orte dort liegen.
• Wikipedia: Artikel über Sehenswürdigkeiten in deiner Umgebung.

EIGENE ORTE UND WEGE
• Lieblingsorte speichern – über die aktuelle Position oder die Adresssuche, auch per Spracheingabe.
• Fußgängernavigation zu gespeicherten Orten, mit wählbaren Ansagen: ausführlich oder kurz.
• Ortsnotizen: Hinterlege an einer Stelle einen Hinweis, z. B. „Treppe nach der Tür“ – kommst du dort vorbei, während Candle offen ist, vibriert das iPhone und Candle meldet den Hinweis. Eine neue Notiz legst du schnell mit einem langen Druck auf das Candle-Symbol an.
• Orte als Link teilen und von Familie oder Freunden empfangen.

DATENSCHUTZ
Keine Anmeldung, keine Werbung, kein Tracking. Deine Orte und Ortsnotizen bleiben auf deinem Gerät. Für Karten, Orte und Routen nutzt Candle offene Dienste wie OpenStreetMap.

OPEN SOURCE
Candle ist kostenlos und quelloffen: github.com/freegroup/candle
Fehler gefunden oder eine Idee? Wir freuen uns über Rückmeldungen – besonders von blinden und sehbehinderten Nutzerinnen und Nutzern.
```

**Neu in dieser Version**
```
Die erste große Aktualisierung seit Langem:
• Erkunden und Radar: Orte in der Nähe kommen schneller und zuverlässiger.
• Ortsnotizen: Hinweise an einer Stelle hinterlegen; Candle meldet sie, wenn du vorbeikommst.
• Navigation: Ansagen wählbar (ausführlich oder kurz); verlässt du die Route, sagt Candle das an.
• Orte als Link teilen.
• Farbschemata für Menschen mit Sehrest.
• VoiceOver: Neue Screens lesen ihre Überschrift vor, wichtige Hinweise gehen nicht mehr verloren.
```

## English (en-US)

**Name** (30)
```
Candle – Blind Navigation
```

**Subtitle** (30)
```
Compass, places and routes
```

**Promotional text** (170)
```
New: choose how navigation talks to you – detailed or short ("50 meters, left"). Messages like "Place saved" interrupt VoiceOver, so nothing gets lost.
```

**Keywords** (100)
```
blind,visually impaired,VoiceOver,compass,accessibility,walking,places,radar,low vision,orientation
```

**Description**
```
Candle helps blind and visually impaired people find their way. The app is built for VoiceOver from the ground up: large buttons, clear announcements and vibration instead of looking at a map.

COMPASS
• Direction by vibration: Candle vibrates when you point your iPhone north or in one of the eight compass directions, and announces it.
• Compass to a destination: hold the iPhone in front of you – Candle tells you the direction and distance to your destination.

PLACES NEARBY
• Explore: cafés, restaurants, pharmacies, ATMs, bus stops, taxi stands, hospitals, public toilets, pedestrian crossings and traffic lights with sound signals – sorted by distance while you walk.
• Radar: point your iPhone in a direction and hear which places are there.
• Wikipedia: articles about sights around you.

YOUR PLACES AND ROUTES
• Save favourite places – from your current position or by address search, also by voice.
• Walking navigation to saved places, with announcements you choose: detailed or short.
• Location notes: leave a hint at a spot, e.g. "stairs after the door" – when you pass it with Candle open, your iPhone vibrates and Candle tells you the hint. Add a new one quickly with a long press on the Candle icon.
• Share places as a link and receive them from family and friends.

PRIVACY
No sign-up, no ads, no tracking. Your places and location notes stay on your device. For maps, places and routes Candle uses open services such as OpenStreetMap.

OPEN SOURCE
Candle is free and open source: github.com/freegroup/candle
Found a bug or have an idea? We welcome feedback – especially from blind and visually impaired users.
```

**What's new**
```
The first big update in a long time:
• Explore and radar: places nearby arrive faster and more reliably.
• Location notes: leave a hint at a spot; Candle tells you when you pass it.
• Navigation: choose the announcements (detailed or short); Candle tells you when you leave the route.
• Share places as a link.
• Colour schemes for people with low vision.
• VoiceOver: new screens read out their title, important messages no longer get lost.
```

## Beide Sprachen

| Feld | Wert |
|------|------|
| Support-URL | `https://github.com/freegroup/candle` |
| Marketing-URL | `https://freegroup.github.io/candle/` |
| Datenschutz-URL | `https://freegroup.github.io/candle/` |
| Copyright | `2026 Andreas Herz` |
| Kategorie | Navigation (zweite: Dienstprogramme) |
| Preis | kostenlos |

## Hinweise für die Prüfung (App Review)

```
Candle is a navigation app for blind and visually impaired people; please try it with VoiceOver.
No account or login is needed. Location access is required: the app shows places around the user, the direction and distance to a destination, and walking directions. Location is used only while the app is open (no background location).
To try it: allow location, then open "Erkunden"/"Explore" and pick a category (e.g. cafés), tap a place for the compass to it, or "Navigation starten" for walking directions. "Orte Radar" lists the places in the direction the iPhone points (hold it flat).
Microphone and speech recognition are only used for dictating names of places and notes.
The app is open source: https://github.com/freegroup/candle
```

## App-Datenschutz (App Store Connect → App-Datenschutz)

Nicht über die API möglich; einmal von Hand, bei Änderungen nachziehen.

- Daten zum Tracking verwendet: **Nein**
- Erhobene Daten:

| Datentyp | Zweck | Mit Identität verknüpft | Tracking |
|----------|-------|-------------------------|----------|
| Standort → Genauer Standort | App-Funktionalität | Nein | Nein |
| Suchverlauf (Adresssuche) | App-Funktionalität | Nein | Nein |
| Kennungen → Geräte-ID (anonyme Installations-ID, App Attest) | App-Funktionalität (Schutz des Candle-Servers vor Missbrauch) | Nein | Nein |

Alles andere: nicht erhoben. Orte, Ortsnotizen und Strecken bleiben auf dem Gerät; Spracheingabe
erledigt die Spracherkennung von iOS.

## Altersfreigabe

Alle Inhaltsfragen **Nein/Keine**; keine nutzergenerierten Inhalte für andere, kein Chat, kein
uneingeschränkter Webzugriff (Wikipedia-Artikel werden als Text angezeigt), keine Werbung, keine
Käufe → **4+**.
