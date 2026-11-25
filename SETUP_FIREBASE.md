# SETUP_FIREBASE.md: Free Spark Plan Setup for Partner Alerts

> **Note:** Spark plan, 100% free. No credit card or Blaze upgrade required. Database rules are pasted manually in the Firebase console. Sender key steps are detailed below.

---

### Step A: Re-Download `google-services.json`
1. Open [console.firebase.google.com](https://console.firebase.google.com/) and select your project (`do-it-now`).
2. Go to **Project settings** (gear icon) > **Your apps** > **Android app** (`com.a3y.doitnow`).
3. Download **`google-services.json`** again.
   *(If you previously downloaded it before creating the Realtime Database, the old file was missing the database URL).*
4. Replace `android/app/google-services.json` with this newly downloaded file.

---

### Step B: Database Rules
1. In Firebase Console, navigate to **Build > Realtime Database > Rules tab**.
2. Replace all existing contents with this single JSON snippet:
   ```json
   {"rules":{".read":false,".write":false,"pairs":{"$code":{"receiverToken":{".read":"auth != null",".write":"auth != null && newData.isString() && newData.val().length < 400"}}}}}
   ```
3. Click **Publish**.

---

### Step C: Create FCM Sender Key (Cloud Messaging Only)
1. Open [console.cloud.google.com](https://console.cloud.google.com/) and select your Firebase project in the top project picker.
2. In the navigation menu, go to **IAM & Admin > Roles > Create role**:
   - **Title**: `FCM sender only`
   - **ID**: `fcm_sender_only`
   - Click **Add permissions**, type `cloudmessaging.messages.create` in the filter, select it, click **Add**, then **Create**.
3. In the navigation menu, go to **IAM & Admin > Service Accounts > Create service account**:
   - **Name**: `fcm-sender`
   - Click **Create and Continue**.
   - Under "Select a role", choose **Custom > FCM sender only**.
   - Click **Done**.
4. Click on the created service account (`fcm-sender`), go to the **Keys** tab:
   - Click **Add key > Create new key > JSON > Create**.
   - A `.json` file will download to your computer.
5. In the navigation menu, go to **APIs & Services > Library**:
   - Search for **"Firebase Cloud Messaging API"**.
   - Ensure it says **Enabled** (if not, click **Enable**).
6. **Save into Her Phone**:
   - Copy the entire text inside the downloaded `.json` key file.
   - On **HER phone only**, open **Do It Now > Settings > Partner Alerts > Sender Key (paste the JSON)**, paste the text, and tap **Save Settings**.
   - *Never commit this key to Git, never put it in project folders, and never share it publicly.*

---

### Step D: Pair the Phones
1. **On His Phone (Receiver)**:
   - Open Do It Now > Settings > Partner Alerts.
   - Select **"I get alerts (His)"**.
   - Copy his generated pair code (starts with `dn...`) and send it to Her phone via WhatsApp.
   - Settings: Settings > Apps > Do It Now > Battery > Unrestricted.
2. **On Her Phone (Taker)**:
   - Open Do It Now > Settings > Partner Alerts.
   - Select **"I take medicine (Her)"**.
   - Paste His pair code in the **His Pair Code** field.
   - Paste the service account JSON in the **Sender Key** field.
   - Tap **Save Settings**.
   - Tap **Send test alert to his phone**. His phone will buzz and display the test alert within a few seconds!
