# Just Tell Me

Say what you want done. The app understands it, plans it, and completes as much as connected services and device permissions safely allow.

This monorepo follows `just-tell-me-cursor-spec/`. Current implementation covers **Milestones 0–5** plus on-device speech on Android/iOS. Gmail OAuth is **not** connected.

## Layout

- `mobile/` — Flutter Android/iOS app
- `backend/` — FastAPI planner API
- `shared/` — ActionPlan JSON schema and golden utterances
- `just-tell-me-cursor-spec/` — product and engineering specification

App ID / package name: `com.justtellme.app`

## Backend (required for planning)

```powershell
cd backend
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
```

Health check: `GET http://127.0.0.1:8080/health`

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
pytest
```

## Mobile

Flutter is installed at `C:\Users\HP\flutter`. Add it to PATH, then:

```powershell
$env:Path = "C:\Users\HP\flutter\bin;" + $env:Path
cd "C:\Users\HP\Desktop\Just Tell Me\mobile"
flutter pub get
flutter test
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

## Try it on a Samsung S23

The phone must reach the planner on your PC. USB debugging installs the app; Wi‑Fi lets it call the API.

1. On the S23: **Settings → About phone → tap Build number 7 times** to unlock Developer options.
2. **Settings → Developer options** → turn on **USB debugging**.
3. Plug the phone into the PC with a data cable (not charge-only). Accept **Allow USB debugging**.
4. Phone and PC on the **same Wi‑Fi**.
5. On the PC, find your LAN IP:

```powershell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.PrefixOrigin -ne 'WellKnown' } | Select-Object IPAddress, InterfaceAlias
```

Use the Wi‑Fi address, often like `192.168.1.23`.

6. Start the backend so the phone can see it (not `127.0.0.1` only):

```powershell
cd "C:\Users\HP\Desktop\Just Tell Me\backend"
.\.venv\Scripts\Activate.ps1
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
```

If Windows Firewall asks, **allow** Python/port 8080 on private networks.

7. Install and run on the S23:

```powershell
$env:Path = "C:\Users\HP\flutter\bin;" + $env:Path
cd "C:\Users\HP\Desktop\Just Tell Me\mobile"
flutter devices
flutter run -d android --dart-define=API_BASE_URL=http://YOUR_PC_IP:8080
```

Replace `YOUR_PC_IP` with the address from step 5, for example `http://192.168.1.23:8080`.

8. Allow **Microphone**, **Contacts**, **Notifications**, and **Calendar** when Android asks.
9. Tap the mic, speak, tap again when finished. Voice uses Samsung/Google speech on the phone — it does not work on the Windows window.

If `flutter devices` does not list the S23: try another cable, install [Google USB Driver](https://developer.android.com/studio/run/win-usb), or use **Wireless debugging** in Developer options and `adb connect PHONE_IP:PORT`.

The app calls `http://127.0.0.1:8080` on Windows. On an emulator use `http://10.0.2.2:8080`. On a physical phone, always use the PC’s LAN IP.

## Product rules that are already enforced

- Planner output is validated against `shared/schemas/action_plan.schema.json`
- The LLM/planner never executes actions
- Confirmation policy can only stay the same or get stricter
- WhatsApp/Telegram personal messaging is `handed_off`, never `sent`
- Typed input always works; the mic uses the phone’s built-in speech recognizer

## Next milestones (see PLAN.md)

6. Gmail OAuth + confirmation tokens  
7–9. Hardened handoff, photo picker  
10. Audit log, encryption, account deletion
