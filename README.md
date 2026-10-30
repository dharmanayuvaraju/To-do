# 🌸 Do It Now
> *A personalized, loving daily medicine reminder app built with Flutter for Android.*

Crafted with love, warmth, and care as a heartfelt surprise for her. Designed around the aesthetic concept of **"Soft Pastel Nursery + Night Sky"**, featuring full Telugu & English bilingual support, celestial countdown dials, blooming streak animations, reliable offline alarms, and personal photos.

---

## 📸 Personal Photos & Assets

The app uses your couple photos placed in `assets/images/`:
- `assets/images/hero_star.jpg` & `assets/images/me.jpg` — **Star Hero Image** (sweet embrace): Used on the Home screen header hero avatar with glowing aura, Splash screen central hero, Alarm screen backdrop, and Love Letter backdrop.
- `assets/images/together_love.jpg` — Romantic couple gazing photo.
- `assets/images/together.jpg` — Couple portrait backdrop.
- `assets/quotes.json` — 7 curated Telugu quotes loaded into the app.

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
2. **Glowing Sun-and-Moon Countdown Dial:**
   - Circular progress ring showing time remaining until the next medicine dose.
   - Celestial icon automatically toggles between radiant sun ☀️ and crescent moon 🌙.
3. **Growing Plant / Blooming Flower Streak:**
   - Plant visually grows from a seedling in soil (Day 0) → sprout (Days 1-2) → flower bud (Days 3-4) → blooming petals (Days 5-6) → radiant full blooming lotus/rose (Day 7+).
4. **Floating Hearts & Teddy Celebration:**
   - Tapping "Taken" triggers haptic feedback, 25 floating pastel particles, and a sweet teddy/baby celebration popup.
5. **Telugu Quotes & Typography:**
   - Google Fonts with Telugu rendering (`Noto Sans Telugu` and `Ramabhadra`).
   - Quotes refresh on home screen and display prominently during alarms.
6. **"Message from [MY NAME]" Screen:**
   - Full-screen photo + handwritten-style love letter card. Customizable directly inside the app.
7. **Full Offline Architecture:**
   - Zero login, zero backend, 100% private. Data stored safely using `SharedPreferences`.

---

## 📱 How to Build the APK & Install on Her Phone

### 1. Build the APK
Open terminal inside this project folder:
```bash
# Get dependencies
flutter pub get

# Build Release APK
flutter build apk --release
```
Your compiled APK will be created at:
`build/app/outputs/flutter-apk/app-release.apk`

*(Optional)* To create a smaller, device-optimized APK:
```bash
flutter build apk --split-per-abi
```

### 2. Install on Her Phone
- **Method A (USB / ADB):** Connect her phone with USB Debugging enabled:
  ```bash
  adb install build/app/outputs/flutter-apk/app-release.apk
  ```
- **Method B (WhatsApp / Telegram / Drive):**
  Send `app-release.apk` to her phone via WhatsApp or Google Drive. On her phone, tap the file and select **Install** (allow "Install from unknown sources" if prompted).

---

## ⚡ Critical Battery Optimization Whitelisting (By Manufacturer)

To guarantee that Android doesn't kill the alarms when the phone is locked or deep-sleeping, perform these steps once on her phone:

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

---

## 🧪 Testing Alarms & Boot Reschedule

1. **Test Alarm (Immediate):**
   - Tap the notification bell icon on the Home screen header or go to **Settings > Test Alarm (4s)**.
   - Lock your screen immediately.
   - Within 4 seconds, the full-screen alarm overlay will turn on the screen with sound, vibration, and your photo.
2. **App Closed Test:**
   - Schedule a medicine 2 minutes from the current time in **Add Medicine**.
   - Swipe away (kill) *Do It Now* from Recent Apps.
   - Turn off screen and wait for the alarm to ring.
3. **Phone Reboot Test:**
   - Restart the phone. The `ScheduledNotificationBootReceiver` declared in `AndroidManifest.xml` triggers automatically upon `BOOT_COMPLETED` and recalculates upcoming dose schedules without needing to open the app!
