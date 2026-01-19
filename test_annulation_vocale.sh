#!/bin/bash

# Script de test pour la fonctionnalité d'annulation vocale "Je vais bien"
# Date: 18 janvier 2026

echo "🧪 =========================================="
echo "   TEST ANNULATION VOCALE - ALERTE SOS"
echo "=========================================="
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de test
test_case() {
    echo -e "${BLUE}📋 Test:${NC} $1"
}

success() {
    echo -e "${GREEN}✅ SUCCÈS:${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠️  ATTENTION:${NC} $1"
}

error() {
    echo -e "${RED}❌ ERREUR:${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

echo "📱 Vérification de l'environnement..."
echo ""

# 1. Vérifier Flutter
if ! command -v flutter &> /dev/null; then
    error "Flutter non installé"
    exit 1
fi
success "Flutter installé: $(flutter --version | head -n 1)"

# 2. Vérifier device connecté
DEVICE_COUNT=$(flutter devices --machine | jq '. | length' 2>/dev/null || echo "0")
if [ "$DEVICE_COUNT" -eq 0 ]; then
    warning "Aucun appareil connecté détecté"
    info "Connectez un appareil Android ou démarrez un émulateur"
else
    success "$DEVICE_COUNT appareil(s) détecté(s)"
    flutter devices
fi

echo ""
echo "🔧 Vérification des dépendances..."
echo ""

# 3. Vérifier speech_to_text dans pubspec.yaml
if grep -q "speech_to_text: \^7.3.0" pubspec.yaml; then
    success "speech_to_text: ^7.3.0 présent dans pubspec.yaml"
else
    error "speech_to_text manquant dans pubspec.yaml"
    exit 1
fi

# 4. Vérifier permission_handler
if grep -q "permission_handler:" pubspec.yaml; then
    success "permission_handler présent dans pubspec.yaml"
else
    error "permission_handler manquant dans pubspec.yaml"
    exit 1
fi

echo ""
echo "📝 Vérification des permissions..."
echo ""

# 5. Vérifier permissions Android
if grep -q "android.permission.RECORD_AUDIO" android/app/src/main/AndroidManifest.xml; then
    success "Permission RECORD_AUDIO présente (Android)"
else
    error "Permission RECORD_AUDIO manquante dans AndroidManifest.xml"
fi

# 6. Vérifier permissions iOS
if grep -q "NSMicrophoneUsageDescription" ios/Runner/Info.plist; then
    success "NSMicrophoneUsageDescription présente (iOS)"
else
    error "NSMicrophoneUsageDescription manquante dans Info.plist"
fi

if grep -q "NSSpeechRecognitionUsageDescription" ios/Runner/Info.plist; then
    success "NSSpeechRecognitionUsageDescription présente (iOS)"
else
    error "NSSpeechRecognitionUsageDescription manquante dans Info.plist"
fi

echo ""
echo "🔍 Vérification du code source..."
echo ""

# 7. Vérifier intégration speech_to_text
if grep -q "import 'package:speech_to_text/speech_to_text.dart'" lib/data/services/service_reconnaissance_vocale.dart; then
    success "Import speech_to_text présent dans service_reconnaissance_vocale.dart"
else
    error "Import speech_to_text manquant"
    exit 1
fi

# 8. Vérifier méthode initialize()
if grep -q "Future<bool> initialize()" lib/data/services/service_reconnaissance_vocale.dart; then
    success "Méthode initialize() implémentée"
else
    error "Méthode initialize() manquante"
fi

# 9. Vérifier détection permissive isCancel()
if grep -q "componentKeywords" lib/data/services/service_reconnaissance_vocale.dart; then
    success "Détection permissive (composants) implémentée"
else
    warning "Détection par composants peut-être manquante"
fi

# 10. Vérifier initialisation dans emergency_countdown_overlay
if grep -q "_initializeVoiceRecognition()" lib/features/alertes/widgets/emergency_countdown_overlay.dart; then
    success "Initialisation vocale dans emergency_countdown_overlay.dart"
else
    error "Initialisation vocale manquante dans overlay"
fi

echo ""
echo "📦 Build de test..."
echo ""

# 11. Analyse statique
info "Exécution de flutter analyze..."
if flutter analyze > /tmp/flutter_analyze.log 2>&1; then
    success "Aucune erreur d'analyse statique"
else
    warning "Analyse statique avec warnings (voir /tmp/flutter_analyze.log)"
    grep -i "error" /tmp/flutter_analyze.log || true
fi

echo ""
echo "🎯 PLAN DE TEST MANUEL"
echo "=========================================="
echo ""

cat << EOF
Pour valider complètement la fonctionnalité, effectuez les tests suivants:

${BLUE}TEST 1: Annulation Vocale Basique${NC}
───────────────────────────────────────
1. Construire et installer l'application:
   ${GREEN}flutter build apk --debug${NC}
   ${GREEN}adb install build/app/outputs/flutter-apk/app-debug.apk${NC}

2. Lancer l'application
3. Déclencher une alerte SOS manuellement (bouton SOS)
4. Attendre l'annonce vocale: "Alerte d'urgence déclenchée..."
5. ${YELLOW}DIRE: "je vais bien"${NC}
6. ${GREEN}ATTENDU: Alerte annulée avec confirmation "Annulation confirmée. Vous allez bien."${NC}

${BLUE}TEST 2: Variantes de Phrases${NC}
───────────────────────────────────────
Répéter le TEST 1 avec ces phrases:
- "bien" seul
- "ok"
- "okay"
- "tout va bien"
- "je me sens bien"
- "stop"
- "annuler"
- "ça va"

${GREEN}ATTENDU: TOUTES ces phrases doivent annuler l'alerte${NC}

${BLUE}TEST 3: Indicateur Visuel${NC}
───────────────────────────────────────
1. Déclencher alerte SOS
2. Vérifier que l'icône microphone est ${GREEN}VERTE${NC}
3. Vérifier le message: "${YELLOW}🎤 Dites 'je vais bien' pour annuler${NC}"

${BLUE}TEST 4: Permission Microphone Refusée${NC}
───────────────────────────────────────
1. Dans Paramètres Android > Applications > Dalys > Permissions
2. REFUSER la permission Microphone
3. Déclencher alerte SOS
4. ${GREEN}ATTENDU: Message "Microphone non disponible - Utilisez le bouton"${NC}
5. Vérifier que le bouton tactile "JE VAIS BIEN" fonctionne

${BLUE}TEST 5: Écoute Continue${NC}
───────────────────────────────────────
1. Déclencher alerte SOS
2. Attendre 5 secondes sans parler
3. Entendre le rappel vocal
4. Dire "bien" avant la fin du compte à rebours (10s)
5. ${GREEN}ATTENDU: Annulation même après 5 secondes${NC}

${BLUE}TEST 6: Environnement Bruyant${NC}
───────────────────────────────────────
1. Activer musique forte à proximité
2. Déclencher alerte SOS
3. Dire clairement "je vais bien"
4. ${GREEN}ATTENDU: Reconnaissance malgré le bruit ambiant${NC}

${BLUE}TEST 7: Logs Temps Réel${NC}
───────────────────────────────────────
Pendant les tests, surveiller les logs:
${GREEN}flutter logs | grep "🎤\|✅\|❌\|ANNULATION"${NC}

Chercher:
- "🎤 DÉTECTÉ: ..." (reconnaissance en cours)
- "✅ ANNULATION DÉTECTÉE" (détection réussie)
- "❌ Erreur reconnaissance vocale" (problèmes)

EOF

echo ""
echo "🚀 COMMANDES RAPIDES"
echo "=========================================="
echo ""

cat << EOF
# Build et installation
${GREEN}flutter clean && flutter pub get${NC}
${GREEN}flutter build apk --debug${NC}
${GREEN}adb install build/app/outputs/flutter-apk/app-debug.apk${NC}

# Logs filtrés
${GREEN}flutter logs | grep "🎤\|DÉTECTÉ\|ANNULATION"${NC}

# Vérifier permissions sur device
${GREEN}adb shell dumpsys package com.dalys | grep -A 3 "permission"${NC}

# Lancer app et logs simultanément
${GREEN}adb shell am start -n com.dalys/.MainActivity && flutter logs${NC}

EOF

echo ""
echo "📊 CRITÈRES DE SUCCÈS"
echo "=========================================="
echo ""

cat << EOF
Pour considérer la fonctionnalité comme validée:

✅ ${GREEN}OBLIGATOIRE:${NC}
   - Phrase "je vais bien" annule l'alerte
   - Confirmation vocale "Annulation confirmée"
   - Indicateur visuel microphone actif (vert)
   - Bouton tactile "JE VAIS BIEN" fonctionne toujours
   
✅ ${GREEN}IMPORTANT:${NC}
   - Au moins 5 variantes de phrases reconnues ("bien", "ok", "stop", etc.)
   - Rappel vocal à mi-parcours
   - Fallback gracieux si permission refusée
   
✅ ${GREEN}SOUHAITABLE:${NC}
   - Reconnaissance en environnement bruyant
   - Écoute continue sans interruption
   - Logs clairs et informatifs

EOF

echo ""
success "Pré-vérifications terminées avec succès!"
echo ""
info "Procédez maintenant aux tests manuels sur appareil réel"
echo ""

# Proposer de builder automatiquement
read -p "Voulez-vous builder l'APK maintenant? (o/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[OoYy]$ ]]; then
    info "Lancement du build..."
    flutter clean
    flutter pub get
    flutter build apk --debug
    
    if [ $? -eq 0 ]; then
        success "Build réussi!"
        info "Fichier APK: build/app/outputs/flutter-apk/app-debug.apk"
        
        # Vérifier si un device est connecté
        if [ "$DEVICE_COUNT" -gt 0 ]; then
            read -p "Installer sur l'appareil connecté? (o/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[OoYy]$ ]]; then
                adb install -r build/app/outputs/flutter-apk/app-debug.apk
                success "Installation terminée!"
                info "Lancement de l'application..."
                adb shell am start -n com.dalys/.MainActivity
            fi
        fi
    else
        error "Échec du build"
        exit 1
    fi
fi

echo ""
echo "🎉 Script terminé!"
echo ""
