#!/bin/bash

# Script pour générer un son de notification doux avec FFmpeg
# Nécessite: ffmpeg installé (apt install ffmpeg)

echo "🔊 Génération du son de notification médicament..."

# Créer un son doux avec FFmpeg (tonalité à 440Hz + 880Hz, durée 2s, fade in/out)
ffmpeg -f lavfi -i "sine=frequency=440:duration=0.3" -af "volume=0.3,afade=t=in:d=0.1:curve=log,afade=t=out:st=0.2:d=0.1:curve=log" /tmp/tone1.wav 2>/dev/null

ffmpeg -f lavfi -i "sine=frequency=880:duration=0.3" -af "volume=0.2,afade=t=in:d=0.1:curve=log,afade=t=out:st=0.2:d=0.1:curve=log" /tmp/tone2.wav 2>/dev/null

# Mélanger les deux tonalités
ffmpeg -i /tmp/tone1.wav -i /tmp/tone2.wav -filter_complex amix=inputs=2:duration=longest /tmp/mixed.wav 2>/dev/null

# Ajouter du silence au début
ffmpeg -i /tmp/mixed.wav -af "adelay=100|100" /tmp/delayed.wav 2>/dev/null

# Répéter 2 fois avec pause
ffmpeg -i /tmp/delayed.wav -i /tmp/delayed.wav -filter_complex "[0:a][1:a]concat=n=2:v=0:a=1[out]" -map "[out]" /tmp/repeated.wav 2>/dev/null

# Convertir en MP3 pour Android
ANDROID_DIR="android/app/src/main/res/raw"
if [ -d "$ANDROID_DIR" ]; then
    ffmpeg -i /tmp/repeated.wav -codec:a libmp3lame -b:a 128k "$ANDROID_DIR/medication_reminder.mp3" 2>/dev/null
    echo "✅ Fichier Android créé: $ANDROID_DIR/medication_reminder.mp3"
else
    echo "⚠️  Dossier Android non trouvé: $ANDROID_DIR"
fi

# Convertir en AIFF pour iOS
IOS_DIR="ios/Runner"
if [ -d "$IOS_DIR" ]; then
    ffmpeg -i /tmp/repeated.wav -acodec pcm_s16le "$IOS_DIR/medication_reminder.aiff" 2>/dev/null
    echo "✅ Fichier iOS créé: $IOS_DIR/medication_reminder.aiff"
else
    echo "⚠️  Dossier iOS non trouvé: $IOS_DIR"
fi

# Nettoyer
rm /tmp/tone1.wav /tmp/tone2.wav /tmp/mixed.wav /tmp/delayed.wav /tmp/repeated.wav 2>/dev/null

echo ""
echo "🎉 Sons de notification créés avec succès!"
echo ""
echo "📝 Prochaines étapes:"
echo "1. Écouter les fichiers pour vérifier qu'ils sont agréables"
echo "2. Pour iOS: Ouvrir Xcode et vérifier que le fichier est dans Build Phases > Copy Bundle Resources"
echo "3. Rebuild l'application: flutter clean && flutter build apk"
echo ""
echo "💡 Si vous préférez un autre son:"
echo "   - Téléchargez un MP3/WAV depuis freesound.org"
echo "   - Remplacez les fichiers générés"
echo "   - Assurez-vous que le nom reste 'medication_reminder'"
