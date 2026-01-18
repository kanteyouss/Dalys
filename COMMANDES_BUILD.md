# 🚀 Commandes de Build DALYS

Ce fichier regroupe toutes les commandes nécessaires pour générer les versions installables de l'application.

## 🧹 Nettoyage et Préparation
À exécuter avant chaque build important :
```bash
flutter clean
flutter pub get
```

## 🤖 Android
### Générer un APK (Installation directe)
```bash
# Version de test (Debug)
flutter build apk --debug

# Version finale optimisée (Release)
flutter build apk --release

# Version optimisée par architecture (plus léger)
flutter build apk --split-per-abi
```

### Générer un App Bundle (Pour Google Play Store)
```bash
flutter build appbundle
```

---

## 🍎 iOS (Mac + Xcode requis)
### Préparation des dépendances
```bash
cd ios
pod install
cd ..
```

### Générer le build iOS
```bash
flutter build ios --release
```

---

## 🛠️ Utilitaires
### Vérifier l'état du système
```bash
flutter doctor
```

### Mettre à jour les icônes (Logo de l'app)
```bash
# 1. Mettre votre image dans assets/images/logo_app.png
# 2. Lancer la génération
flutter pub run flutter_launcher_icons:main
```

### Mettre à jour l'écran de démarrage (Splash Screen)
```bash
flutter pub run flutter_native_splash:create
```

---
*Note : Pour Android, l'APK se trouve dans `build/app/outputs/flutter-apk/`.*

---

## ☁️ Build iOS dans le Cloud (GitHub Actions)
Si vous n'avez pas de Mac, utilisez cette méthode.

1.  **Pousser le code sur GitHub** :
    ```bash
    git add .
    git commit -m "Déclenchement build iOS"
    git push origin V8-IOS
    ```

2.  **Récupérer l'application** :
    *   Allez sur votre dépôt GitHub > Onglet **Actions**.
    *   Cliquez sur le dernier workflow "Build iOS".
    *   Une fois terminé (✅), téléchargez l'artefact **ios-build** en bas de page.

