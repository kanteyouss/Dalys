#!/bin/bash

echo "🏥 E-Santé 4.0 - DALYS Project Setup"
echo "=================================="
echo

# Vérifier si Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter n'est pas installé ou pas dans le PATH"
    echo
    echo "📋 Instructions d'installation de Flutter:"
    echo "1. Télécharger Flutter depuis https://flutter.dev/docs/get-started/install/linux"
    echo "2. Extraire l'archive dans ~/flutter"
    echo "3. Ajouter au PATH dans ~/.bashrc:"
    echo "   export PATH=\"\$PATH:~/flutter/bin\""
    echo "4. Redémarrer le terminal ou exécuter: source ~/.bashrc"
    echo "5. Exécuter: flutter doctor"
    echo
    exit 1
fi

echo "✅ Flutter trouvé: $(flutter --version | head -1)"
echo

# Vérifier la version du SDK Dart
echo "📱 Version du SDK Dart: $(dart --version | cut -d' ' -f4)"
echo

# Installer les dépendances
echo "📦 Installation des dépendances..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ Dépendances installées avec succès"
else
    echo "❌ Erreur lors de l'installation des dépendances"
    exit 1
fi

echo
echo "🚀 Projet prêt!"
echo
echo "📋 Commandes utiles:"
echo "  flutter devices          # Voir les appareils connectés"
echo "  flutter run              # Lancer l'application"
echo "  flutter doctor           # Vérifier la configuration"
echo
echo "🎯 Fonctionnalités actuellement disponibles:"
echo "  ✅ Dashboard de santé avec données simulées"
echo "  ✅ Graphiques d'évolution SpO2"
echo "  ✅ Cartes d'indicateurs vitaux"
echo "  ✅ Système de niveaux de risque (faible/moyen/élevé)"
echo "  ⏳ Alertes intelligentes (à venir)"
echo "  ⏳ Chatbot médical (à venir)"
echo "  ⏳ Suggestions IA (à venir)"
echo