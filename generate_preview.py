import base64
import os

images_dir = 'assets/images'
star_path = os.path.join(images_dir, 'hero_star.jpg')
together_path = os.path.join(images_dir, 'together_love.jpg')
todo_icon_path = os.path.join(images_dir, 'todo_icon.png')

def get_b64(path):
    if os.path.exists(path):
        with open(path, 'rb') as f:
            return 'data:image/jpeg;base64,' + base64.b64encode(f.read()).decode('utf-8')
    return ''

star_b64 = get_b64(star_path)
together_b64 = get_b64(together_path)
todo_icon_b64 = get_b64(todo_icon_path)

html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Do It Now - Live Browser Simulator</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Caveat:wght@600;700&family=Noto+Sans+Telugu:wght@400;600;700;800&family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    body {{
      font-family: 'Poppins', sans-serif;
      background: radial-gradient(circle at 50% 20%, #2A1D36 0%, #150F1D 100%);
      color: #3B2A4D;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 16px;
      overflow-x: hidden;
    }}
    .telugu-font {{
      font-family: 'Noto Sans Telugu', sans-serif;
    }}
    .handwriting {{
      font-family: 'Caveat', cursive;
    }}
    .glass-card {{
      background: rgba(255, 255, 255, 0.72);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border: 1px solid rgba(255, 255, 255, 0.8);
    }}
    .night-card {{
      background: rgba(30, 20, 48, 0.78);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border: 1px solid rgba(205, 180, 246, 0.2);
      color: #FFF6EC;
    }}
    @keyframes gentleBounce {{
      0%, 100% {{ transform: translateY(0); }}
      50% {{ transform: translateY(-4px); }}
    }}
    .bounce-pill {{
      animation: gentleBounce 2.5s ease-in-out infinite;
    }}
    @keyframes pulseRing {{
      0% {{ transform: scale(0.96); opacity: 0.8; }}
      50% {{ transform: scale(1.04); opacity: 0.4; }}
      100% {{ transform: scale(0.96); opacity: 0.8; }}
    }}
    .pulse-ring {{
      animation: pulseRing 3s ease-in-out infinite;
    }}
    .floating-heart {{
      position: absolute;
      pointer-events: none;
      animation: floatUp 2.2s ease-out forwards;
    }}
    @keyframes floatUp {{
      0% {{ transform: translate(0, 0) scale(0.8); opacity: 1; }}
      100% {{ transform: translate(var(--x-offset), -140px) scale(1.3); opacity: 0; }}
    }}
  </style>
</head>
<body>

  <!-- Top Simulator Control Header -->
  <div class="w-full max-w-md flex items-center justify-between py-2 px-4 mb-2 text-white">
    <div class="flex items-center gap-2.5">
      <img src="{todo_icon_b64}" class="w-8 h-8 rounded-xl shadow-md border border-amber-200/50">
      <div>
        <h1 class="text-sm font-bold tracking-wide">Do It Now</h1>
        <p class="text-[11px] text-pink-300">Love from Babu ❤️</p>
      </div>
    </div>
    <div class="flex items-center gap-2">
      <button onclick="toggleTheme()" id="themeBtn" class="text-xs bg-slate-800 border border-slate-700 hover:border-pink-400 px-3 py-1.5 rounded-full flex items-center gap-1.5 transition">
        <span id="themeIcon">🌙</span> <span id="themeText">Night Sky</span>
      </button>
      <button onclick="triggerTestAlarm()" class="text-xs bg-gradient-to-r from-pink-500 to-rose-500 hover:from-pink-600 hover:to-rose-600 text-white font-semibold px-3 py-1.5 rounded-full shadow-lg flex items-center gap-1 transition">
        🔔 Test Alarm
      </button>
    </div>
  </div>

  <!-- Mobile Device Frame Container -->
  <div id="phoneFrame" class="relative w-[380px] h-[780px] bg-[#FFF6EC] rounded-[44px] shadow-[0_25px_60px_rgba(0,0,0,0.6)] border-[9px] border-slate-800 overflow-hidden flex flex-col transition-colors duration-500">

    <!-- Phone Notch -->
    <div class="absolute top-2.5 left-1/2 -translate-x-1/2 w-28 h-5 bg-slate-800 rounded-full z-50 flex items-center justify-end px-3">
      <div class="w-2.5 h-2.5 rounded-full bg-slate-950/80 border border-slate-700"></div>
    </div>

    <!-- Phone Status Bar -->
    <div class="h-10 pt-2 px-7 flex items-center justify-between text-xs font-semibold z-40 transition-colors" id="statusBar">
      <span id="liveClock">09:20</span>
      <div class="flex items-center gap-1.5">
        <span>5G</span>
        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 3c-4.97 0-9 4.03-9 9 0 2.12.74 4.07 1.97 5.61L12 22l7.03-4.39C20.26 16.07 21 14.12 21 12c0-4.97-4.03-9-9-9z"/></svg>
        <span class="text-[10px]">100%</span>
      </div>
    </div>

    <!-- Main Screens Viewport -->
    <div class="flex-1 relative overflow-hidden flex flex-col" id="screenViewport">

      <!-- SCREEN 1: HOME SCREEN -->
      <div id="homeScreen" class="flex-1 overflow-y-auto px-4 pb-24 pt-2 flex flex-col gap-4">
        
        <!-- Header with Love from Babu at TOP + Star Hero Avatar -->
        <div class="flex items-center justify-between pt-1">
          <div class="flex items-center gap-3.5">
            <div onclick="switchScreen('message')" class="relative cursor-pointer group">
              <div id="homeAvatarContainer" class="w-16 h-16 rounded-full border-2 border-pink-300 p-0.5 shadow-md group-hover:scale-105 transition-transform overflow-hidden bg-pink-100">
                <img id="homeAvatarImg" src="{star_b64}" class="w-full h-full object-cover rounded-full">
                <div id="homeAvatarNature" class="hidden w-full h-full rounded-full bg-gradient-to-tr from-emerald-200 to-indigo-300 flex items-center justify-center text-2xl">
                  🌿
                </div>
              </div>
              <div class="absolute bottom-0 right-0 bg-gradient-to-r from-pink-500 to-rose-500 text-white rounded-full p-1 shadow">
                <svg class="w-2.5 h-2.5 fill-current" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>
              </div>
            </div>
            <div>
              <p class="text-xs font-bold text-rose-500 uppercase tracking-widest flex items-center gap-1">
                <span>❤️</span> Love from Babu
              </p>
              <h2 class="text-lg font-bold text-slate-800 leading-tight">Hi Bujji 👋</h2>
            </div>
          </div>
          <button onclick="triggerTestAlarm()" class="w-10 h-10 rounded-full glass-card flex items-center justify-center text-lg hover:scale-110 active:scale-95 transition shadow-sm">
            🔔
          </button>
        </div>

        <!-- Curated Telugu Quote Card (Pure English UI Container with Telugu quote text) -->
        <div class="glass-card rounded-[26px] p-4 shadow-sm border border-pink-200/60 relative overflow-hidden">
          <div class="flex items-center justify-between mb-2">
            <span class="text-[11px] font-bold tracking-wide uppercase text-purple-700 bg-purple-100/80 px-2.5 py-0.5 rounded-full">
              Daily Telugu Quote
            </span>
            <button onclick="refreshQuote()" class="text-xs text-purple-600 hover:text-purple-800 flex items-center gap-1 font-semibold">
              🔄 <span>New</span>
            </button>
          </div>
          <p id="quoteTelugu" class="text-sm font-bold text-slate-800 leading-relaxed">
            Nee arogyame mana baby arogyam. Mandulu vesuko bangaram ❤️
          </p>
          <p id="quoteEnglish" class="text-xs text-purple-700/80 mt-1 italic font-medium">
            Your health is our baby's health. Take your medicines, bangaram ❤️
          </p>
        </div>

        <!-- Moon-and-Sun Dial Countdown Widget -->
        <div onclick="openAlarmScreen()" class="glass-card rounded-[30px] p-5 shadow-sm flex flex-col items-center justify-center relative cursor-pointer group hover:border-pink-300 transition">
          <div class="text-[11px] font-bold text-purple-800 uppercase tracking-wider mb-2">Next Medicine Time</div>
          <div class="relative w-36 h-36 flex items-center justify-center">
            <div class="absolute inset-0 rounded-full border-4 border-pink-200/50 pulse-ring"></div>
            <div class="w-32 h-32 rounded-full bg-gradient-to-tr from-pink-200 via-purple-100 to-amber-100 flex flex-col items-center justify-center shadow-inner">
              <span class="text-2xl mb-0.5">☀️</span>
              <span class="text-xl font-bold text-slate-800 tracking-tight">09:20 AM</span>
              <span class="text-[10px] font-bold text-rose-500 uppercase tracking-widest mt-0.5">Morning Dose</span>
            </div>
          </div>
          <p class="text-[10px] text-purple-700/80 font-medium mt-1">Tap dial to preview Full Alarm Screen 🔔</p>
        </div>

        <!-- Blooming Plant / Flower Streak Widget -->
        <div class="glass-card rounded-[22px] p-3 flex items-center gap-3.5 shadow-sm" id="streakCard">
          <div class="w-16 h-16 bg-pink-100/50 rounded-2xl flex items-center justify-center shrink-0 border border-pink-200/50">
            <div id="flowerGraphic" class="text-3xl animate-bounce">🌺</div>
          </div>
          <div class="flex-1">
            <div class="flex items-center gap-1.5">
              <span class="text-xs bg-rose-100 text-rose-600 font-bold px-2 py-0.5 rounded-full flex items-center gap-1">
                🔥 <span>7 Days Loving Streak</span>
              </span>
            </div>
            <h4 class="text-xs font-bold text-slate-800 mt-1">Radiant Bloom of Love! 🌺✨</h4>
            <p class="text-[10px] text-slate-500">Every morning tablet taken on schedule!</p>
          </div>
        </div>

        <!-- Today's Medicines Header with Add Button -->
        <div class="flex items-center justify-between pt-1">
          <div class="flex items-center gap-2">
            <h3 class="text-sm font-bold text-slate-800">Today's Medicine</h3>
            <span class="text-[11px] font-semibold text-purple-700 bg-purple-100 px-2 py-0.5 rounded-full">
              <span id="completedCount">0</span>/<span id="totalMedsCount">1</span> Taken
            </span>
          </div>
          <button onclick="openAddModal()" class="text-xs font-bold text-pink-600 bg-pink-100 hover:bg-pink-200 px-2.5 py-1 rounded-full flex items-center gap-1 transition">
            <span>+</span> Add Reminder
          </button>
        </div>

        <!-- Medicines List Container -->
        <div id="medicinesContainer" class="flex flex-col gap-3">
          <!-- Default Reminder: tablet vesuko mundu at 09:20 AM -->
          <div class="glass-card rounded-[24px] p-4 shadow-sm transition-all" id="medCard1">
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2.5">
                <div class="w-10 h-10 rounded-full bg-pink-100 border border-pink-200 flex items-center justify-center bounce-pill text-lg">
                  💊
                </div>
                <div>
                  <span class="text-sm font-bold text-slate-800">09:20 AM</span>
                  <span id="cardBadge" class="ml-2 text-[10px] font-semibold text-purple-700 bg-purple-100 px-2 py-0.5 rounded-full">Due Today 💕</span>
                  <p class="text-[11px] text-slate-500">1 Tablet • Everyday</p>
                </div>
              </div>
            </div>
            <h4 class="text-sm font-bold text-slate-800 mt-2.5 text-base">tablet vesuko mundu</h4>
            <p class="text-xs text-purple-700/90 italic mt-0.5">Take on time every morning without fail ❤️</p>
            
            <div class="flex items-center justify-between mt-3 pt-2 border-t border-pink-100">
              <!-- Notify Babu button -->
              <button onclick="notifyBabuWhatsApp()" class="text-xs text-emerald-700 bg-emerald-50 hover:bg-emerald-100 px-3 py-1.5 rounded-full font-semibold flex items-center gap-1 transition">
                <span>💬</span> Message Babu
              </button>
              <!-- Taken button -->
              <button onclick="markTaken(event)" id="btnTake" class="px-5 py-2 rounded-full font-bold text-xs bg-gradient-to-r from-pink-500 to-rose-500 hover:from-pink-600 hover:to-rose-600 text-white shadow-md active:scale-95 transition flex items-center gap-1.5">
                <span>Taken ❤️</span>
              </button>
            </div>
          </div>
        </div>

      </div>

      <!-- SCREEN 2: ALARM SCREEN -->
      <div id="alarmScreen" class="hidden absolute inset-0 z-30 flex flex-col justify-between p-5 text-white bg-slate-900 overflow-hidden">
        <!-- Background (Couple Photo OR Serene Nature) -->
        <div class="absolute inset-0 z-0">
          <img id="alarmBgImg" src="{star_b64}" class="w-full h-full object-cover">
          <div id="alarmBgNature" class="hidden w-full h-full bg-gradient-to-b from-[#1E293B] via-[#334155] to-[#0F172A] flex items-center justify-center">
            <span class="text-[130px] opacity-15">🌿</span>
          </div>
          <div class="absolute inset-0 bg-gradient-to-b from-[#3B2A4D]/85 via-[#1B1528]/90 to-[#1B1528]/98"></div>
        </div>

        <div class="relative z-10 flex items-center justify-between pt-4">
          <div class="flex items-center gap-2 bg-white/20 backdrop-blur-md px-3 py-1 rounded-full border border-white/20 text-xs font-bold">
            <span class="animate-spin">🔔</span> 09:20 AM ALARM
          </div>
          <button onclick="switchScreen('home')" class="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center text-sm">✕</button>
        </div>

        <div class="relative z-10 flex flex-col items-center text-center my-auto">
          <!-- Avatar (Couple OR Serene Nature) -->
          <div class="w-24 h-24 rounded-full border-4 border-pink-300 shadow-2xl overflow-hidden mb-3 p-0.5 bg-pink-100 flex items-center justify-center">
            <img id="alarmAvatarImg" src="{star_b64}" class="w-full h-full object-cover rounded-full">
            <div id="alarmAvatarNature" class="hidden w-full h-full rounded-full bg-gradient-to-tr from-emerald-300 to-indigo-300 flex items-center justify-center text-3xl">
              🌿
            </div>
          </div>
          
          <div id="alarmPrivacyBadge" class="hidden mb-2 px-2.5 py-0.5 rounded-full bg-white/10 text-[10px] text-emerald-300 flex items-center gap-1">
            <span>🌿</span> Serene Nature Mode (Private)
          </div>

          <h3 class="text-xs uppercase tracking-widest text-pink-300 font-semibold mb-1">Medicine Reminder</h3>
          <h2 class="text-xl font-bold tracking-tight mb-2">tablet vesuko mundu</h2>

          <!-- Curated Telugu Quote -->
          <div class="bg-white/10 backdrop-blur-md p-4 rounded-2xl border border-white/15 my-2 max-w-xs">
            <p id="alarmTeluguQuote" class="text-base font-bold text-pink-100 leading-relaxed">
              Nuvvu baagunte nenu baaguntanu. Tablet vesukunnava? ❤️
            </p>
            <p class="text-[11px] text-pink-200/80 mt-1.5 italic">
              "I am fine only if you are fine. Did you take your tablet?"
            </p>
          </div>
        </div>

        <!-- Action Sliders & Buttons -->
        <div class="relative z-10 flex flex-col gap-2.5 pb-2">
          <!-- Slide to take slider -->
          <div id="slideTrack" class="relative w-full h-14 bg-white/20 rounded-full backdrop-blur-md border border-white/30 flex items-center px-2 overflow-hidden cursor-pointer select-none">
            <div class="absolute inset-0 flex items-center justify-center text-xs font-bold text-white/90 tracking-wide pointer-events-none">
              Slide to take ❤️ ➔
            </div>
            <div id="sliderThumb" class="w-10 h-10 rounded-full bg-gradient-to-r from-pink-500 to-rose-500 text-white flex items-center justify-center shadow-lg transform transition-transform">
              ❤️
            </div>
          </div>

          <div class="flex items-center gap-2">
            <button onclick="snoozeAlarm()" class="flex-1 py-2.5 rounded-full bg-white/15 hover:bg-white/25 text-xs font-semibold backdrop-blur-md border border-white/20 transition">
              ⏳ Snooze 10m
            </button>
            <button onclick="notifyBabuWhatsApp()" class="flex-1 py-2.5 rounded-full bg-emerald-500/80 hover:bg-emerald-500 text-xs font-semibold backdrop-blur-md border border-emerald-400/40 transition">
              💬 Message Babu
            </button>
          </div>
        </div>
      </div>

      <!-- SCREEN 3: LOVE NOTE SCREEN -->
      <div id="messageScreen" class="hidden flex-1 overflow-y-auto px-4 pb-24 pt-2 flex flex-col gap-4">
        <h2 class="text-base font-bold text-slate-800 pt-2">Love Letter from Babu ❤️</h2>

        <div class="relative rounded-3xl overflow-hidden shadow-lg border border-pink-200">
          <img id="loveNoteBackdrop" src="{together_b64}" class="w-full h-64 object-cover">
          <div class="absolute inset-0 bg-gradient-to-t from-slate-900/90 via-slate-900/40 to-transparent"></div>
          <div class="absolute bottom-4 left-4 right-4 text-white">
            <h3 class="text-lg font-bold">Forever With You</h3>
            <p class="text-xs text-pink-200">Every pill on time keeps our dream shining bright.</p>
          </div>
        </div>

        <div class="bg-[#FFFDF9] rounded-3xl p-5 shadow-sm border border-amber-200 text-slate-800 relative">
          <span class="text-4xl absolute top-3 right-4 opacity-20">💌</span>
          <p class="handwriting text-lg leading-relaxed text-slate-700">
            My Dearest Bujji ❤️,<br><br>
            You are my whole world, and our baby is our sweetest blessing. Taking your tablet every morning at 09:20 AM gives me peace of mind.<br><br>
            Please never skip your medicine. Your health and smile mean everything to me.<br><br>
            Forever yours,<br>
            <b>Love from Babu ❤️</b>
          </p>
        </div>
      </div>

      <!-- SCREEN 4: HISTORY SCREEN -->
      <div id="historyScreen" class="hidden flex-1 overflow-y-auto px-4 pb-24 pt-2 flex flex-col gap-3.5">
        <h2 class="text-base font-bold text-slate-800 pt-2">Adherence History</h2>

        <div class="glass-card rounded-2xl p-4 shadow-sm flex items-center justify-around text-center">
          <div>
            <p class="text-2xl font-bold text-emerald-600" id="histStreak">7</p>
            <p class="text-[11px] text-slate-500 font-semibold">Day Streak</p>
          </div>
          <div class="w-px h-10 bg-slate-200"></div>
          <div>
            <p class="text-2xl font-bold text-purple-600">100%</p>
            <p class="text-[11px] text-slate-500 font-semibold">Weekly Rate</p>
          </div>
          <div class="w-px h-10 bg-slate-200"></div>
          <div>
            <p class="text-2xl font-bold text-rose-500">0</p>
            <p class="text-[11px] text-slate-500 font-semibold">Missed</p>
          </div>
        </div>

        <!-- 7-Day Adherence Calendar -->
        <div class="glass-card rounded-2xl p-3.5 shadow-sm">
          <h3 class="text-xs font-bold text-slate-700 mb-2">Past 7 Days</h3>
          <div class="grid grid-cols-7 gap-1 text-center">
            <div class="flex flex-col items-center gap-1 bg-emerald-100/60 p-1.5 rounded-xl border border-emerald-300"><span class="text-[10px] font-bold text-emerald-800">Sun</span><span class="text-xs font-bold text-emerald-900">22</span><span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span></div>
            <div class="flex flex-col items-center gap-1 bg-emerald-100/60 p-1.5 rounded-xl border border-emerald-300"><span class="text-[10px] font-bold text-emerald-800">Mon</span><span class="text-xs font-bold text-emerald-900">23</span><span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span></div>
            <div class="flex flex-col items-center gap-1 bg-emerald-100/60 p-1.5 rounded-xl border border-emerald-300"><span class="text-[10px] font-bold text-emerald-800">Tue</span><span class="text-xs font-bold text-emerald-900">24</span><span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span></div>
            <div class="flex flex-col items-center gap-1 bg-emerald-100/60 p-1.5 rounded-xl border border-emerald-300"><span class="text-[10px] font-bold text-emerald-800">Wed</span><span class="text-xs font-bold text-emerald-900">25</span><span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span></div>
            <div class="flex flex-col items-center gap-1 bg-emerald-100/60 p-1.5 rounded-xl border border-emerald-300"><span class="text-[10px] font-bold text-emerald-800">Thu</span><span class="text-xs font-bold text-emerald-900">26</span><span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span></div>
            <div class="flex flex-col items-center gap-1 bg-emerald-100/60 p-1.5 rounded-xl border border-emerald-300"><span class="text-[10px] font-bold text-emerald-800">Fri</span><span class="text-xs font-bold text-emerald-900">27</span><span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span></div>
            <div class="flex flex-col items-center gap-1 bg-pink-200 p-1.5 rounded-xl border border-pink-400"><span class="text-[10px] font-bold text-rose-800">Today</span><span class="text-xs font-bold text-rose-900">28</span><span class="w-1.5 h-1.5 rounded-full bg-rose-500"></span></div>
          </div>
        </div>

        <h3 class="text-xs font-bold text-slate-700 mt-1">Recent Activity</h3>
        <div class="flex flex-col gap-2">
          <div class="glass-card rounded-2xl p-3 flex items-center justify-between text-xs">
            <div class="flex items-center gap-2.5">
              <span class="text-emerald-500 text-lg">✓</span>
              <div>
                <p class="font-bold text-slate-800">tablet vesuko mundu</p>
                <p class="text-[10px] text-slate-500">Today at 09:20 AM • Taken</p>
              </div>
            </div>
            <span class="text-[10px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full">Taken ✓</span>
          </div>
        </div>
      </div>

      <!-- SCREEN 5: SETTINGS -->
      <div id="settingsScreen" class="hidden flex-1 overflow-y-auto px-4 pb-24 pt-2 flex flex-col gap-3.5">
        <h2 class="text-base font-bold text-slate-800 pt-2">Settings</h2>

        <!-- Names & Contact (Hidden Phone + No Phone Brands) -->
        <div class="glass-card rounded-2xl p-3.5 shadow-sm">
          <h3 class="text-xs font-bold text-purple-800 mb-2.5">Names & WhatsApp</h3>
          <div class="flex flex-col gap-2.5">
            <div>
              <label class="text-[10px] text-slate-500 font-semibold">Her Name</label>
              <input id="inputHerName" type="text" value="Bujji" class="w-full text-xs p-2 rounded-xl border border-pink-200 bg-white/90">
            </div>
            <div>
              <div class="flex items-center justify-between mb-0.5">
                <label class="text-[10px] text-slate-500 font-semibold">Babu's WhatsApp Number</label>
                <button onclick="togglePhoneVisibility()" id="btnPhoneEye" class="text-[10px] text-purple-600 font-semibold flex items-center gap-1">
                  👁️ <span>Show</span>
                </button>
              </div>
              <input id="inputBabuPhone" type="password" value="919876543210" class="w-full text-xs p-2 rounded-xl border border-pink-200 bg-white/90 font-mono">
            </div>
          </div>
        </div>

        <!-- Medicine Reminders Section (Manage & Add) -->
        <div class="glass-card rounded-2xl p-3.5 shadow-sm">
          <div class="flex items-center justify-between mb-2">
            <h3 class="text-xs font-bold text-purple-800 flex items-center gap-1.5">
              <span>💊</span> Medicine Reminders
            </h3>
            <button onclick="openAddModal()" class="text-[11px] font-bold text-pink-600 bg-pink-100 hover:bg-pink-200 px-2.5 py-0.5 rounded-full transition">
              + Add More
            </button>
          </div>
          <div id="settingsMedsList" class="flex flex-col gap-1.5">
            <div class="flex items-center justify-between p-2 rounded-xl bg-white/70 border border-pink-100 text-xs">
              <div>
                <p class="font-bold text-slate-800">tablet vesuko mundu</p>
                <p class="text-[10px] text-slate-500">09:20 AM • 1 Tablet • Everyday</p>
              </div>
              <span class="text-[10px] text-emerald-600 font-bold bg-emerald-50 px-2 py-0.5 rounded-full">Active</span>
            </div>
          </div>
        </div>

        <!-- Photo Privacy & Theme Section -->
        <div class="glass-card rounded-2xl p-3.5 shadow-sm">
          <h3 class="text-xs font-bold text-purple-800 mb-1 flex items-center gap-1.5">
            <span>🛡️</span> Photo Privacy & Theme
          </h3>
          <p class="text-[10px] text-slate-500 mb-2.5">Choose background style for lock screen & busy days:</p>

          <!-- Nature option -->
          <div onclick="selectPhotoStyle('nature')" id="optNature" class="cursor-pointer p-2.5 rounded-xl border-2 border-emerald-400 bg-emerald-50/70 mb-2 flex items-center justify-between transition">
            <div class="flex items-center gap-2">
              <span class="text-xl">🌿</span>
              <div>
                <p class="text-xs font-bold text-slate-800">Serene Nature & Flowers (Private)</p>
                <p class="text-[10px] text-slate-500">Calm botanical art. No personal photos. Perfect for office/busy days.</p>
              </div>
            </div>
            <span id="badgeNature" class="text-emerald-600 font-bold text-sm">✓</span>
          </div>

          <!-- Couple option -->
          <div onclick="selectPhotoStyle('couple')" id="optCouple" class="cursor-pointer p-2.5 rounded-xl border border-slate-200 bg-white/70 flex items-center justify-between transition">
            <div class="flex items-center gap-2">
              <span class="text-xl">❤️</span>
              <div>
                <p class="text-xs font-bold text-slate-800">Our Sweet Couple Photos</p>
                <p class="text-[10px] text-slate-500">Shows personal romantic couple photos.</p>
              </div>
            </div>
            <span id="badgeCouple" class="hidden text-pink-600 font-bold text-sm">✓</span>
          </div>

          <!-- Lock Screen Privacy Toggle -->
          <div class="flex items-center justify-between mt-2.5 pt-2 border-t border-pink-100">
            <div>
              <p class="text-[11px] font-bold text-slate-800">Always use Nature on Lock Screen</p>
              <p class="text-[9px] text-slate-500">Never shows personal photo when phone is locked</p>
            </div>
            <input type="checkbox" id="chkLockPrivacy" checked class="w-4 h-4 accent-emerald-500">
          </div>
        </div>

        <!-- 4 Selectable Alarm Sounds -->
        <div class="glass-card rounded-2xl p-3.5 shadow-sm">
          <h3 class="text-xs font-bold text-purple-800 mb-2">Alarm Sounds (4 Tones)</h3>
          <div class="flex flex-col gap-1.5">
            <button onclick="playTone(0)" class="w-full py-2 px-3 rounded-xl bg-pink-50 hover:bg-pink-100 text-xs font-semibold text-slate-700 flex items-center justify-between transition">
              <span>🔔 1. Gentle Morning Chime</span>
              <span class="text-pink-600 text-xs">▶ Play</span>
            </button>
            <button onclick="playTone(1)" class="w-full py-2 px-3 rounded-xl bg-purple-50 hover:bg-purple-100 text-xs font-semibold text-slate-700 flex items-center justify-between transition">
              <span>🎵 2. Sweet Loving Bell</span>
              <span class="text-purple-600 text-xs">▶ Play</span>
            </button>
            <button onclick="playTone(2)" class="w-full py-2 px-3 rounded-xl bg-rose-50 hover:bg-rose-100 text-xs font-semibold text-slate-700 flex items-center justify-between transition">
              <span>🚨 3. Urgent Care Alarm</span>
              <span class="text-rose-600 text-xs">▶ Play</span>
            </button>
            <button onclick="playTone(3)" class="w-full py-2 px-3 rounded-xl bg-amber-50 hover:bg-amber-100 text-xs font-semibold text-slate-700 flex items-center justify-between transition">
              <span>🎼 4. Celestial Harp</span>
              <span class="text-amber-600 text-xs">▶ Play</span>
            </button>
          </div>
        </div>

        <!-- Battery Optimization & Permissions -->
        <div class="glass-card rounded-2xl p-3.5 shadow-sm border border-emerald-200">
          <div class="flex items-center gap-1.5 text-xs font-bold text-emerald-800">
            <span>⚡</span> Battery Optimization & Permissions
          </div>
          <p class="text-[11px] text-slate-600 mt-1.5 leading-relaxed">
            <b>Crucial for background alarms:</b><br>
            1. Settings > Battery > <b>High background power consumption</b> > Turn ON.<br>
            2. Settings > Apps > <b>Autostart</b> > Allow.<br>
            3. In Recent Apps, swipe down on Do It Now and tap <b>Lock 🔒</b>.
          </p>
        </div>
      </div>

    </div>

    <!-- Celebration Popup Overlay -->
    <div id="celebrationOverlay" class="hidden absolute inset-0 z-50 bg-black/40 backdrop-blur-sm flex items-center justify-center p-6">
      <div class="bg-[#FFF6EC] rounded-[32px] p-6 max-w-xs w-full text-center shadow-2xl border-2 border-pink-300 animate-in fade-in zoom-in duration-300">
        <div class="w-20 h-20 bg-pink-100 rounded-full flex items-center justify-center text-4xl mx-auto mb-3 shadow-inner">
          🧸🍼
        </div>
        <h3 class="text-lg font-bold text-slate-800">Thank you Bujji! ❤️</h3>
        <p class="text-xs text-purple-700 mt-1 leading-relaxed">
          Tablet taken on time!<br>Our baby is safe and loved 💕<br><b>Love from Babu</b>
        </p>
        <button onclick="closeCelebration()" class="mt-4 px-6 py-2 bg-gradient-to-r from-pink-500 to-rose-500 text-white rounded-full text-xs font-bold shadow-md hover:scale-105 active:scale-95 transition">
          Done 💕
        </button>
      </div>
    </div>

    <!-- Modal to Add New Medicine Reminder -->
    <div id="addMedModal" class="hidden absolute inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-5">
      <div class="bg-[#FFF6EC] rounded-3xl p-5 max-w-xs w-full shadow-2xl border border-pink-300 text-slate-800">
        <h3 class="text-sm font-bold text-slate-800 mb-3 flex items-center gap-2">
          <span>💊</span> Add Medicine Reminder
        </h3>
        <div class="flex flex-col gap-2 text-xs">
          <div>
            <label class="text-[10px] text-slate-500 font-semibold">Medicine Name / Label</label>
            <input id="newMedName" type="text" placeholder="e.g. Calcium Tablet" class="w-full p-2 rounded-xl border border-pink-200 bg-white">
          </div>
          <div class="grid grid-cols-2 gap-2">
            <div>
              <label class="text-[10px] text-slate-500 font-semibold">Dose</label>
              <input id="newMedDose" type="text" value="1" class="w-full p-2 rounded-xl border border-pink-200 bg-white">
            </div>
            <div>
              <label class="text-[10px] text-slate-500 font-semibold">Time</label>
              <input id="newMedTime" type="time" value="20:00" class="w-full p-2 rounded-xl border border-pink-200 bg-white">
            </div>
          </div>
          <div>
            <label class="text-[10px] text-slate-500 font-semibold">Optional Note</label>
            <input id="newMedNote" type="text" placeholder="After dinner with warm milk ❤️" class="w-full p-2 rounded-xl border border-pink-200 bg-white">
          </div>
        </div>
        <div class="flex items-center gap-2 mt-4">
          <button onclick="closeAddModal()" class="flex-1 py-2 rounded-xl bg-slate-200 text-slate-700 text-xs font-semibold">
            Cancel
          </button>
          <button onclick="saveNewMed()" class="flex-1 py-2 rounded-xl bg-gradient-to-r from-pink-500 to-rose-500 text-white text-xs font-bold shadow">
            Save
          </button>
        </div>
      </div>
    </div>

    <!-- Bottom Navigation Bar (Pure English UI) -->
    <div class="h-16 glass-card border-t border-pink-200/50 flex items-center justify-around px-2 z-40" id="bottomNav">
      <button onclick="switchScreen('home')" id="navHome" class="flex flex-col items-center gap-0.5 text-rose-500 font-bold transition">
        <span class="text-lg">🏠</span>
        <span class="text-[10px]">Home</span>
      </button>
      <button onclick="switchScreen('history')" id="navHistory" class="flex flex-col items-center gap-0.5 text-slate-400 hover:text-rose-500 transition">
        <span class="text-lg">📅</span>
        <span class="text-[10px]">History</span>
      </button>
      <button onclick="switchScreen('message')" id="navMsg" class="flex flex-col items-center gap-0.5 text-slate-400 hover:text-rose-500 transition">
        <span class="text-lg">💌</span>
        <span class="text-[10px]">Love Note</span>
      </button>
      <button onclick="switchScreen('settings')" id="navSettings" class="flex flex-col items-center gap-0.5 text-slate-400 hover:text-rose-500 transition">
        <span class="text-lg">⚙️</span>
        <span class="text-[10px]">Settings</span>
      </button>
    </div>

  </div>

  <p class="text-xs text-slate-400 mt-3 text-center">
    Click 'Taken', 'Test Alarm', or sound previews to listen live!
  </p>

  <script>
    const quotes = [
      {{ telugu: 'Nee arogyame mana baby arogyam. Mandulu vesuko bangaram ❤️', english: "Your health is our baby's health. Take your medicines, bangaram ❤️" }},
      {{ telugu: 'Mandulu marchipothe mana baby ki ibbandi avthundi. Ippude vesuko 🙏', english: 'If you forget medicines it troubles our baby. Please take it now 🙏' }},
      {{ telugu: 'Nuvvu baagunte nenu baaguntanu. Tablet vesukunnava? ❤️', english: 'I am fine only if you are fine. Did you take your tablet?' }},
      {{ telugu: 'Naa pranam nuvve, mana baby kooda. Mandu time ayindi! 🍼', english: "You are my life, and our baby too. It's medicine time!" }},
      {{ telugu: 'Okka tablet... mana baby ki oka pedda gift 🍼', english: 'Just one tablet... is a big gift for our baby 🍼' }},
      {{ telugu: 'Naa kosam kaadu, mana baby kosam vesuko chinna 💕', english: 'Not for me, take it for our baby chinna 💕' }},
      {{ telugu: 'Ippude vesuko, tharvatha naaku message cheyyi ❤️', english: 'Take it right now, and message me after ❤️' }}
    ];
    let quoteIndex = 0;
    let isPhoneVisible = false;
    let currentPhotoStyle = 'couple'; // 'nature' or 'couple'

    let extraMedicines = [];

    // Web Audio Synthesizer: 4 Sounds!
    let audioCtx = null;
    function getAudioCtx() {{
      if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      return audioCtx;
    }}

    function playTone(type) {{
      const ctx = getAudioCtx();
      if (type === 0) {{
        // 1. Gentle Chime
        [523.25, 659.25, 783.99, 987.77].forEach((f, i) => {{
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.frequency.value = f;
          gain.gain.setValueAtTime(0.12, ctx.currentTime + i * 0.12);
          gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + i * 0.12 + 1.2);
          osc.connect(gain); gain.connect(ctx.destination);
          osc.start(ctx.currentTime + i * 0.12);
          osc.stop(ctx.currentTime + i * 0.12 + 1.2);
        }});
      }} else if (type === 1) {{
        // 2. Sweet Bell
        [880.0, 1108.73, 1318.51].forEach((f, i) => {{
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.frequency.value = f;
          gain.gain.setValueAtTime(0.15, ctx.currentTime + i * 0.18);
          gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + i * 0.18 + 1.5);
          osc.connect(gain); gain.connect(ctx.destination);
          osc.start(ctx.currentTime + i * 0.18);
          osc.stop(ctx.currentTime + i * 0.18 + 1.5);
        }});
      }} else if (type === 2) {{
        // 3. Urgent Care Alarm
        [659.25, 880.0, 659.25, 880.0].forEach((f, i) => {{
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'triangle';
          osc.frequency.value = f;
          gain.gain.setValueAtTime(0.2, ctx.currentTime + i * 0.15);
          gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + i * 0.15 + 0.14);
          osc.connect(gain); gain.connect(ctx.destination);
          osc.start(ctx.currentTime + i * 0.15);
          osc.stop(ctx.currentTime + i * 0.15 + 0.15);
        }});
      }} else if (type === 3) {{
        // 4. Celestial Harp
        [523.25, 587.33, 659.25, 783.99, 880.0, 1046.50].forEach((f, i) => {{
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.value = f;
          gain.gain.setValueAtTime(0.1, ctx.currentTime + i * 0.14);
          gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + i * 0.14 + 1.8);
          osc.connect(gain); gain.connect(ctx.destination);
          osc.start(ctx.currentTime + i * 0.14);
          osc.stop(ctx.currentTime + i * 0.14 + 1.8);
        }});
      }}
    }}

    function togglePhoneVisibility() {{
      isPhoneVisible = !isPhoneVisible;
      const input = document.getElementById('inputBabuPhone');
      const btn = document.getElementById('btnPhoneEye');
      if (isPhoneVisible) {{
        input.type = 'text';
        btn.innerHTML = '🔒 <span>Hide</span>';
      }} else {{
        input.type = 'password';
        btn.innerHTML = '👁️ <span>Show</span>';
      }}
    }}

    function selectPhotoStyle(style) {{
      currentPhotoStyle = style;
      const optNature = document.getElementById('optNature');
      const optCouple = document.getElementById('optCouple');
      const badgeNature = document.getElementById('badgeNature');
      const badgeCouple = document.getElementById('badgeCouple');

      const alarmBgImg = document.getElementById('alarmBgImg');
      const alarmBgNature = document.getElementById('alarmBgNature');
      const alarmAvatarImg = document.getElementById('alarmAvatarImg');
      const alarmAvatarNature = document.getElementById('alarmAvatarNature');
      const alarmPrivacyBadge = document.getElementById('alarmPrivacyBadge');

      const homeAvatarImg = document.getElementById('homeAvatarImg');
      const homeAvatarNature = document.getElementById('homeAvatarNature');

      if (style === 'nature') {{
        optNature.className = 'cursor-pointer p-2.5 rounded-xl border-2 border-emerald-400 bg-emerald-50/70 mb-2 flex items-center justify-between transition';
        optCouple.className = 'cursor-pointer p-2.5 rounded-xl border border-slate-200 bg-white/70 flex items-center justify-between transition';
        badgeNature.classList.remove('hidden');
        badgeCouple.classList.add('hidden');

        alarmBgImg.classList.add('hidden');
        alarmBgNature.classList.remove('hidden');
        alarmAvatarImg.classList.add('hidden');
        alarmAvatarNature.classList.remove('hidden');
        alarmPrivacyBadge.classList.remove('hidden');

        homeAvatarImg.classList.add('hidden');
        homeAvatarNature.classList.remove('hidden');
      }} else {{
        optCouple.className = 'cursor-pointer p-2.5 rounded-xl border-2 border-pink-400 bg-pink-50/70 flex items-center justify-between transition';
        optNature.className = 'cursor-pointer p-2.5 rounded-xl border border-slate-200 bg-white/70 mb-2 flex items-center justify-between transition';
        badgeCouple.classList.remove('hidden');
        badgeNature.classList.add('hidden');

        alarmBgImg.classList.remove('hidden');
        alarmBgNature.classList.add('hidden');
        alarmAvatarImg.classList.remove('hidden');
        alarmAvatarNature.classList.add('hidden');
        alarmPrivacyBadge.classList.add('hidden');

        homeAvatarImg.classList.remove('hidden');
        homeAvatarNature.classList.add('hidden');
      }}
    }}

    function openAddModal() {{
      document.getElementById('addMedModal').classList.remove('hidden');
    }}

    function closeAddModal() {{
      document.getElementById('addMedModal').classList.add('hidden');
    }}

    function saveNewMed() {{
      const name = document.getElementById('newMedName').value.trim();
      const dose = document.getElementById('newMedDose').value.trim() || '1';
      const time = document.getElementById('newMedTime').value.trim() || '20:00';
      const note = document.getElementById('newMedNote').value.trim() || 'Take on time ❤️';

      if (!name) {{
        alert('Please enter medicine name');
        return;
      }}

      // Add to array
      extraMedicines.push({{ name, dose, time, note, taken: false }});
      closeAddModal();
      renderExtraMedicines();
      document.getElementById('newMedName').value = '';
    }}

    function renderExtraMedicines() {{
      const container = document.getElementById('medicinesContainer');
      const settingsList = document.getElementById('settingsMedsList');
      const totalCount = document.getElementById('totalMedsCount');
      totalCount.innerText = 1 + extraMedicines.length;

      // Remove existing extras
      document.querySelectorAll('.extra-card').forEach(e => e.remove());
      document.querySelectorAll('.extra-setting-item').forEach(e => e.remove());

      extraMedicines.forEach((m, idx) => {{
        // Home card
        const card = document.createElement('div');
        card.className = 'extra-card glass-card rounded-[24px] p-4 shadow-sm transition-all';
        card.innerHTML = `
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2.5">
              <div class="w-10 h-10 rounded-full bg-purple-100 border border-purple-200 flex items-center justify-center text-lg">
                💊
              </div>
              <div>
                <span class="text-sm font-bold text-slate-800">${{m.time}}</span>
                <span class="ml-2 text-[10px] font-semibold text-purple-700 bg-purple-100 px-2 py-0.5 rounded-full">Due Today</span>
                <p class="text-[11px] text-slate-500">${{m.dose}} Tablet • Scheduled</p>
              </div>
            </div>
          </div>
          <h4 class="text-sm font-bold text-slate-800 mt-2.5 text-base">${{m.name}}</h4>
          <p class="text-xs text-purple-700/90 italic mt-0.5">${{m.note}}</p>
          <div class="flex items-center justify-between mt-3 pt-2 border-t border-pink-100">
            <button onclick="notifyBabuWhatsApp()" class="text-xs text-emerald-700 bg-emerald-50 hover:bg-emerald-100 px-3 py-1.5 rounded-full font-semibold flex items-center gap-1">
              💬 Message Babu
            </button>
            <button onclick="markExtraTaken(this, ${{idx}})" class="px-5 py-2 rounded-full font-bold text-xs bg-gradient-to-r from-pink-500 to-rose-500 text-white shadow-md">
              Taken ❤️
            </button>
          </div>
        `;
        container.appendChild(card);

        // Settings item
        const sItem = document.createElement('div');
        sItem.className = 'extra-setting-item flex items-center justify-between p-2 rounded-xl bg-white/70 border border-pink-100 text-xs';
        sItem.innerHTML = `
          <div>
            <p class="font-bold text-slate-800">${{m.name}}</p>
            <p class="text-[10px] text-slate-500">${{m.time}} • ${{m.dose}} Dose</p>
          </div>
          <span class="text-[10px] text-emerald-600 font-bold bg-emerald-50 px-2 py-0.5 rounded-full">Active</span>
        `;
        settingsList.appendChild(sItem);
      }});
    }}

    function markExtraTaken(btn, idx) {{
      extraMedicines[idx].taken = true;
      btn.innerText = 'Taken ✓';
      btn.className = 'px-5 py-2 rounded-full font-bold text-xs bg-emerald-500 text-white shadow-md pointer-events-none';
      playTone(1);
      showCelebration();
    }}

    function refreshQuote() {{
      quoteIndex = (quoteIndex + 1) % quotes.length;
      document.getElementById('quoteTelugu').innerText = quotes[quoteIndex].telugu;
      document.getElementById('quoteEnglish').innerText = quotes[quoteIndex].english;
      document.getElementById('alarmTeluguQuote').innerText = quotes[quoteIndex].telugu;
    }}

    function openAlarmScreen() {{
      refreshQuote();
      playTone(0);
      switchScreen('alarm');
    }}

    function triggerTestAlarm() {{
      openAlarmScreen();
    }}

    function snoozeAlarm() {{
      alert('musukoni mundu vesuko! 😠❤️\n\nSnooze cheyoddu bangaram! Ippude vesuko please... Sare 10m tharvatha malli alert avthundi!');
      switchScreen('home');
    }}

    function notifyBabuWhatsApp() {{
      const num = document.getElementById('inputBabuPhone').value || '919876543210';
      const text = encodeURIComponent('Hi Babu ❤️ I took my medicine on time! Love you!');
      window.open(`https://wa.me/${{num}}?text=${{text}}`, '_blank');
    }}

    function markTaken(e) {{
      playTone(1);
      spawnHearts(e);

      const btn = document.getElementById('btnTake');
      btn.innerText = 'Taken ✓';
      btn.className = 'px-5 py-2 rounded-full font-bold text-xs bg-emerald-500 text-white shadow-md pointer-events-none';

      const badge = document.getElementById('cardBadge');
      badge.innerText = 'Taken ✅';
      badge.className = 'ml-2 text-[10px] font-bold text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-full';

      document.getElementById('completedCount').innerText = '1';
      document.getElementById('flowerGraphic').innerText = '🌸';

      setTimeout(showCelebration, 600);
    }}

    function showCelebration() {{
      document.getElementById('celebrationOverlay').classList.remove('hidden');
    }}

    function closeCelebration() {{
      document.getElementById('celebrationOverlay').classList.add('hidden');
    }}

    function spawnHearts(e) {{
      const rect = e.target.getBoundingClientRect();
      const frame = document.getElementById('phoneFrame');
      const frameRect = frame.getBoundingClientRect();

      for (let i = 0; i < 15; i++) {{
        const heart = document.createElement('div');
        heart.className = 'floating-heart text-2xl z-50';
        heart.innerHTML = ['❤️', '💕', '💖', '🌸'][Math.floor(Math.random() * 4)];
        heart.style.left = (rect.left - frameRect.left + rect.width / 2 + (Math.random() * 40 - 20)) + 'px';
        heart.style.top = (rect.top - frameRect.top + (Math.random() * 20 - 10)) + 'px';
        heart.style.setProperty('--x-offset', (Math.random() * 120 - 60) + 'px');
        frame.appendChild(heart);
        setTimeout(() => heart.remove(), 2200);
      }}
    }}

    function switchScreen(name) {{
      ['home', 'history', 'message', 'settings', 'alarm'].forEach(s => {{
        const el = document.getElementById(s + 'Screen');
        if (el) el.classList.add('hidden');
        const nav = document.getElementById('nav' + s.charAt(0).toUpperCase() + s.slice(1));
        if (nav) {{
          nav.classList.remove('text-rose-500', 'font-bold');
          nav.classList.add('text-slate-400');
        }}
      }});

      const target = document.getElementById(name + 'Screen');
      if (target) target.classList.remove('hidden');

      const activeNav = document.getElementById('nav' + name.charAt(0).toUpperCase() + name.slice(1));
      if (activeNav) {{
        activeNav.classList.remove('text-slate-400');
        activeNav.classList.add('text-rose-500', 'font-bold');
      }}
    }}

    let isNight = false;
    function toggleTheme() {{
      isNight = !isNight;
      const frame = document.getElementById('phoneFrame');
      const themeText = document.getElementById('themeText');
      const themeIcon = document.getElementById('themeIcon');
      const cards = document.querySelectorAll('.glass-card');

      if (isNight) {{
        frame.style.background = '#150F1D';
        themeText.innerText = 'Pastel Day';
        themeIcon.innerText = '☀️';
        cards.forEach(c => {{
          c.classList.remove('glass-card');
          c.classList.add('night-card');
        }});
      }} else {{
        frame.style.background = '#FFF6EC';
        themeText.innerText = 'Night Sky';
        themeIcon.innerText = '🌙';
        cards.forEach(c => {{
          c.classList.remove('night-card');
          c.classList.add('glass-card');
        }});
      }}
    }}

    // Draggable Slider for Alarm
    const track = document.getElementById('slideTrack');
    const thumb = document.getElementById('sliderThumb');
    let isDragging = false;
    let startX = 0;

    track.addEventListener('mousedown', (e) => {{
      isDragging = true;
      startX = e.clientX;
    }});

    window.addEventListener('mousemove', (e) => {{
      if (!isDragging) return;
      const maxDrag = track.clientWidth - thumb.clientWidth - 16;
      let diff = e.clientX - startX;
      if (diff < 0) diff = 0;
      if (diff > maxDrag) diff = maxDrag;
      thumb.style.transform = `translateX(${{diff}}px)`;

      if (diff >= maxDrag * 0.9) {{
        isDragging = false;
        thumb.style.transform = 'translateX(0px)';
        switchScreen('home');
        markTaken({{ target: document.getElementById('btnTake') }});
      }}
    }});

    window.addEventListener('mouseup', () => {{
      if (isDragging) {{
        isDragging = false;
        thumb.style.transform = 'translateX(0px)';
      }}
    }});

    // Initialize in Serene Nature mode by default for privacy
    selectPhotoStyle('nature');
  </script>
</body>
</html>
"""

with open('preview.html', 'w', encoding='utf-8') as f:
    f.write(html_content)

art_dir = r'C:\Users\yuvar\.gemini\antigravity\brain\25f814ba-003c-4103-a85c-cc703dd2c331'
with open(os.path.join(art_dir, 'preview.html'), 'w', encoding='utf-8') as f:
    f.write(html_content)

print('SUCCESS_REGENERATED_CLEAN')
