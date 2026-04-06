# 🌐 Pankh Client (Flutter Web)

Frontend for **pankh.email**, built using Flutter and deployed via CI/CD.

---

## 🚀 Live URLs

* 🌍 Main Site: https://pankh.email
* 🔗 API: https://api.pankh.email/api

---

## 🧱 Project Structure

```bash
.
├── lib/                 # Flutter app code
├── web/                 # Web entry point
├── pubspec.yaml
├── .github/
│   └── workflows/
│       └── deploy.yml
```

---

## ⚙️ How It Works

1. Code is pushed to GitHub
2. GitHub Actions runs automatically
3. Flutter web build is generated in CI
4. Built files are deployed to server via SSH
5. Nginx serves the app from:

```
/var/www/pankh
```

---

## 🚀 Deployment Flow

```bash
git add .
git commit -m "update frontend"
git push origin main
```

👉 This triggers:

* Flutter build (in CI)
* Automatic deployment to server

---

## ⚙️ CI/CD Details

Workflow file:

```
.github/workflows/deploy.yml
```

### CI Steps:

* Setup Flutter
* Install dependencies (`flutter pub get`)
* Build web app
* Deploy via `rsync` over SSH

---

## 🔐 Required GitHub Secrets

| Name     | Description      |
| -------- | ---------------- |
| SSH_HOST | Server public IP |
| SSH_USER | ubuntu           |
| SSH_KEY  | Private SSH key  |

---

## 🌐 Environment Configuration

Build uses:

```bash
--dart-define=PANKH_API_BASE_URL=https://api.pankh.email/api
```

> ⚠️ If this is incorrect, API calls will fail silently.

---

## 🧪 Verification

After deployment:

1. Open:

   ```
   https://pankh.email
   ```

2. Check browser DevTools → Network:

   * API calls should go to:

     ```
     https://api.pankh.email/api
     ```

---

## 🧯 Troubleshooting

### ❌ Blank page

* Check CI logs
* Ensure build completed successfully

---

### ❌ API not working

* Verify `dart-define` value
* Check backend availability

---

### ❌ CI/CD failed

* Go to GitHub → Actions
* Inspect logs

---

### ❌ Old UI still visible

* Hard refresh (`Cmd + Shift + R`)
* Check if deployment ran successfully

---

## 🔄 Development Workflow

* No need to build locally for deployment
* CI handles build automatically
* Local build only for testing:

```bash
flutter run -d chrome
```

---

## ⚡ Best Practices

* Keep Flutter version consistent with CI
* Avoid committing `build/` folder
* Test locally before pushing

---

## 🔮 Future Improvements

* CI caching (faster builds)
* Preview deployments (PR-based)
* CDN integration (Cloudflare)
* Versioned releases

---

## 🧠 Summary

* Source code in repo
* CI builds Flutter web
* Auto deploy via SSH
* Nginx serves static files

---

Built with ❤️ for pankh.email.
