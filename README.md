# NF Workflows

React Native uygulamalar için yeniden kullanılabilir (reusable) GitHub Actions workflow template'leri.

## 📁 Proje Yapısı

```
nf_workflows/
├── .github/workflows/
│   ├── setup-node.yml              # Node.js ortam kurulumu
│   ├── ios-build.yml               # iOS build (archive + IPA)
│   ├── ios-deploy-testflight.yml   # TestFlight deploy
│   ├── ios-deploy-firebase.yml     # iOS Firebase App Distribution
│   ├── android-build.yml           # Android APK/AAB build
│   ├── android-deploy-play.yml     # Google Play Store deploy
│   ├── android-deploy-firebase.yml # Android Firebase App Distribution
│   └── create-github-release.yml   # GitHub Release oluşturma
├── fastlane/
│   ├── Fastfile                    # iOS Fastlane lanes
│   └── utils/
│       ├── config_helper.rb        # ENV konfigürasyon yönetimi
│       ├── file_helper.rb          # Dosya işlemleri (base64, zip)
│       └── github_helper.rb        # GitHub API entegrasyonu
└── README.md
```

## 🚀 Kullanım

### Workflow'ları Çağırma

Bu repo'daki reusable workflow'ları kendi projenizden `workflow_call` ile çağırabilirsiniz:

```yaml
# .github/workflows/deploy-ios.yml
name: Deploy iOS

on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: appibara/nf_workflows/.github/workflows/ios-deploy-testflight.yml@main
    with:
      scheme: "MyApp"
      workspace-name: "MyApp"
    secrets:
      APP_IDENTIFIER: ${{ secrets.APP_IDENTIFIER }}
      APPLE_DEVELOPER_PORTAL_TEAM_ID: ${{ secrets.APPLE_DEVELOPER_PORTAL_TEAM_ID }}
      APPLE_STORE_CONNECT_TEAM_ID: ${{ secrets.APPLE_STORE_CONNECT_TEAM_ID }}
      APPLE_KEY: ${{ secrets.APPLE_KEY }}
      APPLE_KEY_ID: ${{ secrets.APPLE_KEY_ID }}
      APPLE_ISSUER_ID: ${{ secrets.APPLE_ISSUER_ID }}
      MATCH_REPO_URL: ${{ secrets.MATCH_REPO_URL }}
      MATCH_REPO_USERNAME: ${{ secrets.MATCH_REPO_USERNAME }}
      MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
      MATCH_REPO_BRANCH: ${{ secrets.MATCH_REPO_BRANCH }}
      MATCH_REPO_PRIVATE_KEY: ${{ secrets.MATCH_REPO_PRIVATE_KEY }}
```

### Android Build Örneği

```yaml
# .github/workflows/build-android.yml
name: Build Android

on:
  pull_request:
    branches: [main]

jobs:
  build:
    uses: appibara/nf_workflows/.github/workflows/android-build.yml@main
    with:
      build-type: "apk"
      build-variant: "release"
    secrets:
      ANDROID_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
      ANDROID_KEYSTORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
      ANDROID_KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
      ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
```

## 🔧 Workflow Listesi

### `setup-node.yml`
Node.js ortamı kurulumu. Caching desteği ve opsiyonel CocoaPods kurulumu.

| Input | Varsayılan | Açıklama |
|-------|-----------|----------|
| `node-version` | `24` | Node.js versiyonu |
| `package-manager` | `npm` | Paket yöneticisi (npm/yarn) |
| `cache-pods` | `false` | CocoaPods cache |
| `install-pods` | `false` | CocoaPods kurulumu |

---

### `ios-build.yml`
iOS archive ve IPA oluşturma. Code signing (match) destekli.

| Input | Varsayılan | Açıklama |
|-------|-----------|----------|
| `scheme` | *(zorunlu)* | Xcode scheme adı |
| `workspace-name` | *(zorunlu)* | Xcode workspace adı |
| `export-method` | `app-store` | Export metodu |
| `fastlane-lane` | `create_archive` | Çalıştırılacak lane |
| `xcode-version` | `latest-stable` | Xcode versiyonu |

---

### `ios-deploy-testflight.yml`
TestFlight'a deploy. `internal` Fastlane lane'ini çalıştırır.

---

### `ios-deploy-firebase.yml`
iOS Firebase App Distribution'a deploy. `adhoc` Fastlane lane'ini çalıştırır. Ek secret: `FIREBASE_CREDENTIALS`.

---

### `android-build.yml`
Android APK veya AAB oluşturma. Gradle ile build ve keystore signing.

| Input | Varsayılan | Açıklama |
|-------|-----------|----------|
| `build-type` | `bundle` | Build tipi (apk/bundle) |
| `build-variant` | `release` | Build variant |
| `java-version` | `17` | Java versiyonu |

---

### `android-deploy-play.yml`
Google Play Store'a AAB deploy. Fastlane `supply` kullanır.

| Input | Varsayılan | Açıklama |
|-------|-----------|----------|
| `track` | `internal` | Play Store track'i |
| `package-name` | *(zorunlu)* | Android paket adı |

---

### `android-deploy-firebase.yml`
Android Firebase App Distribution'a APK deploy.

| Input | Varsayılan | Açıklama |
|-------|-----------|----------|
| `firebase-app-id` | *(zorunlu)* | Firebase App ID |
| `firebase-groups` | `internal` | Tester grupları |

---

### `create-github-release.yml`
GitHub Release oluşturma ve artifact ekleme.

| Input | Varsayılan | Açıklama |
|-------|-----------|----------|
| `tag-name` | *(zorunlu)* | Release tag adı |
| `release-name` | *(zorunlu)* | Release başlığı |
| `generate-release-notes` | `true` | Otomatik release notes |

## 🔐 Gerekli Secrets

### iOS
| Secret | Açıklama |
|--------|----------|
| `APP_IDENTIFIER` | Bundle identifier |
| `APPLE_DEVELOPER_PORTAL_TEAM_ID` | Apple Developer Team ID |
| `APPLE_STORE_CONNECT_TEAM_ID` | App Store Connect Team ID |
| `APPLE_KEY` | App Store Connect API Key (base64) |
| `APPLE_KEY_ID` | API Key ID |
| `APPLE_ISSUER_ID` | API Issuer ID |
| `MATCH_REPO_URL` | Match certificates repo URL |
| `MATCH_REPO_USERNAME` | Match repo username |
| `MATCH_PASSWORD` | Match passphrase |
| `MATCH_REPO_BRANCH` | Match repo branch |
| `MATCH_REPO_PRIVATE_KEY` | Match repo SSH key (base64) |
| `FIREBASE_CREDENTIALS` | Firebase SA key (base64) — sadece Firebase deploy |

### Android
| Secret | Açıklama |
|--------|----------|
| `ANDROID_KEYSTORE_BASE64` | Keystore dosyası (base64) |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore şifresi |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key şifresi |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Play Console SA key (base64) — sadece Play deploy |
| `FIREBASE_CREDENTIALS` | Firebase SA key (base64) — sadece Firebase deploy |
