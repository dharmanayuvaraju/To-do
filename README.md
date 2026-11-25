# 🌸 Do It Now
> *A personalized, loving daily medicine reminder app built with Flutter for Android.*

Crafted with love, warmth, and care as a heartfelt surprise for her. Designed around the aesthetic concept of **"Soft Pastel Nursery + Night Sky"**, featuring full Telugu & English bilingual support, celestial countdown dials, blooming streak animations, reliable offline alarms, and personal photos.

---

## 🔔 Partner Push Alerts (Free Spark Plan FCM Direct)

When **SHE** taps **Taken** (either on the notification action button or inside the app), **HE** instantly receives a high-priority push notification on his phone within about 3 seconds, even if his app is completely closed.

- **100% Free Spark Plan:** No credit card, no Blaze billing, and no Cloud Functions required.
- **Direct FCM v1 API:** Her phone sends push notifications directly to the Google FCM HTTP v1 API using a restricted service account sender key.
- **His Phone:** Registers its device FCM token in Firebase Realtime Database under an unguessable 34-character pair code (starts with `dn...`).
- **Offline Delivery:** If Her phone is offline when tapping Taken, the event is saved to an offline queue on her phone and automatically delivered as soon as the phone is online and the app or a reminder runs, with the original time recorded.

### Simple Pairing Steps
1. **On His Phone:**
   - Open **Do It Now > Settings > Partner Alerts**, choose **"I get alerts (His)"**.
   - Tap **Copy** or **Share** to send his pair code to Her via WhatsApp.
   - Configure Battery: **Settings > Apps > Do It Now > Battery > Unrestricted** and enable **Autostart**.
2. **On Her Phone:**
   - Open **Do It Now > Settings > Partner Alerts**, choose **"I take medicine (Her)"**.
   - Paste His pair code into **His Pair Code**.
   - Paste the service account JSON key into **Sender Key**.
   - Tap **Save Settings**, then tap **Send test alert to his phone**.
   - His phone will show **"Test alert: Do It Now is connected ❤️"** within 3 seconds!

> [!NOTE]
> The sender key has only one permission (`cloudmessaging.messages.create`) and is stored securely in private local storage on Her phone only. It is never committed to Git or baked into APK assets. If it ever leaks, simply delete it in Google Cloud Console > IAM & Admin > Service Accounts > fcm-sender > Keys and generate a new one.

---

## 📸 Personal Photos & Assets

The app uses your couple photos placed in `assets/images/`:
- `assets/images/me.jpg` — **Star Hero Image** (sweet embrace): Used on the Home screen header hero avatar with glowing aura, Splash screen central hero, Alarm screen backdrop, and Love Letter backdrop.
- `assets/images/together_love.jpg` — Romantic couple gazing photo.
- `assets/images/together.jpg` — Couple portrait backdrop.
- `assets/quotes.json` — 32 curated loving Telugu quotes loaded into the app.

---

## 🎨 Theme & Palette ("Soft Pastel Nursery + Night Sky")

- **Blush Pink (`#F8C8DC`)**: Gentle loving accents & buttons.
- **Lavender (`#CDB4F6`)**: Card highlights & night sky transitions.
- **Cream (`#FFF6EC`)**: Warm, non-clinical background.
- **Deep Plum (`#3B2A4D`)**: Primary typography and contrasting elements.
- **Mint Success (`#A8E6CF`)**: Doses taken & success indicators.

---

## 🚀 Key Features

1. **Exact Alarm & Cascading Notifications:**
   - Rings like an alarm with sound (`alarm_chime.wav`), vibration, and full-screen intent even when phone is locked.
   - Shows action buttons: `Taken / తీసుకున్నాను ✅` and `Snooze 10m / 10 నిమిషాలు ఆపు ⏳`.
   - Automatically repeats every 10 minutes up to 6 times if unanswered.
   - If not marked taken after 60 minutes, records as `Missed` in history.
   - Re-syncs on app launch to cancel any pending repeat nag alarms for doses already taken today.
2. **Instant Partner Push Notifications:**
   - She marks dose as Taken -> He instantly receives a push alert.
3. **Glowing Sun-and-Moon Countdown Dial:**
   - Circular progress ring showing time remaining until the next medicine dose.
   - Celestial icon automatically toggles between radiant sun ☀️ and crescent moon 🌙.
4. **Growing Plant / Blooming Flower Streak:**
   - Plant visually grows from a seedling in soil (Day 0) → sprout (Days 1-2) → flower bud (Days 3-4) → blooming petals (Days 5-6) → radiant full blooming lotus/rose (Day 7+).
5. **Floating Hearts & Teddy Celebration:**
   - Tapping "Taken" triggers haptic feedback, 25 floating pastel particles, and a sweet celebration popup.
6. **Telugu Quotes & Typography:**
   - Bundled offline `Noto Sans Telugu` and `Ramabhadra` TTF fonts.
   - Quotes refresh on home screen and display prominently during alarms.
7. **"Message from Babu" Screen:**
   - Full-screen photo + handwritten-style love letter card. Customizable directly inside the app.

---

## 📱 How to Build the APK & Install

### 1. Build Split-per-ABI Release APK (Compact Size ~25MB)
Open terminal inside this project folder:
```bash
# Get dependencies
flutter pub get

# Code analysis (must show 0 errors)
flutter analyze

# Build split APKs
flutter build apk --release --split-per-abi
```
The recommended ARM64 APK will be created at:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (approx. 25MB).

---

## ⚡ Critical Battery Optimization Whitelisting (By Manufacturer)

To guarantee that Android doesn't kill the alarms or notifications when the phone is locked or deep-sleeping, perform these steps on both phones:

### 1. In-App Exemption Prompt
Open **Do It Now > Settings > Battery Guide & Whitelist ⚡** and tap **Request Whitelist**. Tap **Allow** on the Android system popup.

### 2. Brand-Specific Steps:

#### 🔹 Samsung (One UI)
1. Go to **Settings > Apps > Do It Now**.
2. Tap **Battery** > Select **Unrestricted**.
3. Go to **Device Care > Battery > Background usage limits**. Ensure *Do It Now* is **NOT** in Sleeping or Deep Sleeping apps.
4. Enable **Appear on top** permission.

#### 🔹 Xiaomi / Redmi / POCO (MIUI / HyperOS)
1. Open **Settings > Apps > Manage Apps > Do It Now**.
2. Turn **ON** **Autostart** *(Crucial)*.
3. Under **Battery Saver**, select **No restrictions**.
4. Go to **Permissions > Other permissions** > Turn ON **Show on Lock screen** and **Display pop-up windows**.

#### 🔹 Vivo / iQOO (Funtouch OS / OriginOS)
1. Go to **Settings > Battery > High background power consumption**.
2. Toggle **ON** for *Do It Now*.
3. Go to **Settings > Apps > Do It Now > Permissions**, enable **Autostart** and **Floating Windows**.

#### 🔹 Oppo / Realme (ColorOS / Realme UI)
1. Open **Settings > Battery > Battery usage > Do It Now**.
2. Turn **ON** **Allow foreground activity** and **Allow background activity**.
3. Turn **ON** **Allow auto-launch**.
4. In **App Info > Manage Notifications**, enable **Set as important**.

#### 🔹 OnePlus (OxygenOS)
1. Go to **Settings > Battery > Battery optimization > Do It Now > Select "Don't optimize"**.
2. In recent apps tray, tap the 3 dots on *Do It Now* and tap **Lock** so it remains protected in memory.
