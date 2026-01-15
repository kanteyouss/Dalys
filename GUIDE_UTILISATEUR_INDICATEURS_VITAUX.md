# 📊 3. Intelligence et Personnalisation
Objectif : Fournir des suggestions intelligentes selon le profil de santé et les conditions actuelles.
🔹 Exemples de suggestions :
    • “Pensez à utiliser votre inhalateur avant de sortir aujourd’hui.”
    • “Évitez les activités physiques entre 16h et 18h.”
    • “Qualité de l’air moyenne : aérez votre logement ce matin.”
🔧 IA utilisée :
    • Modèle de Machine Learning supervisé
        ◦ Entrées : symptômes, environnement, historique de crises
        ◦ Sorties : niveau de risque (faible/moyen/élevé)
    • Framework : TensorFlow / Scikit-Learn
    • API Python (Django REST / Flask) reliée à l’app mobile - Surveillance de Votre Santé Respiratoire

## 🏥 Qu'est-ce que la surveillance des indicateurs vitaux ?

L'application E-Santé 4.0 - DALYS vous permet de surveiller en temps réel plusieurs paramètres essentiels de votre santé respiratoire et de votre environnement. Ces mesures vous aident à comprendre votre état de santé et à prendre les bonnes décisions pour votre bien-être.

## 💾 Comment fonctionne l'affichage des données dans l'application

### 🔄 Mode Simulation vs Mode Réel
L'application dispose désormais d'un interrupteur (switch) en haut à droite de l'écran :

1.  **Mode Simulation (Activé par défaut)** :
    *   L'application génère des données réalistes automatiquement.
    *   Idéal pour découvrir l'application sans capteurs.
    *   Permet de voir comment l'application réagit aux différentes situations.

2.  **Mode Réel (Capteurs Connectés)** :
    *   L'application tente de se connecter aux capteurs physiques via le module ESP32.
    *   Affiche les données réelles de votre corps et de votre environnement.

### 🌐 Les Capteurs Supportés
L'application est conçue pour fonctionner avec le matériel suivant :
- **MAX30100** : Pour la saturation en oxygène (SpO₂) et la fréquence cardiaque.
- **DS18B20** : Pour une mesure précise de la température corporelle.
- **DHT22** : Pour la température et l'humidité ambiante.

### 📱 Ce que vous voyez à l'écran
L'affichage des données comprend :

1.  **Indicateurs Vitaux** :
    *   **SpO₂** (Saturation en oxygène)
    *   **Fréquence Respiratoire** (Estimée ou mesurée)
    *   **Débit de Pointe (PEF)**
    *   **Température Corporelle**

2.  **Indicateurs Environnementaux** :
    *   **Température Ambiante**
    *   **Humidité**

3.  **Code Couleur** :
    *   🟢 **VERT** : Normal
    *   🟡 **ORANGE** : À surveiller
    *   🔴 **ROUGE** : Anormal / Danger

## 🔍 Les indicateurs expliqués

### 1. 💓 Saturation en oxygène (SpO₂)
- **Normal** : 95% à 100%
- Indique si vos poumons oxygènent bien votre sang.

### 2. 🌡️ Température Corporelle
- **Normal** : 36.5°C à 37.5°C
- Une température élevée peut indiquer une infection ou une inflammation.

### 3. 💧 Humidité & Température Ambiante
- **Humidité idéale** : 40% à 60%
- Un air trop sec ou trop humide peut irriter les voies respiratoires.
- Une température ambiante stable est recommandée pour les personnes sensibles.

### 4. 🫁 Fréquence respiratoire
- **Normal** : 12 à 20 respirations/minute
- Un rythme rapide au repos peut signaler une gêne.

### 5. 🌪️ Débit de pointe (PEF)
- **Normal** : 350 à 500 L/min
- Mesure votre souffle (force d'expiration).

## 🎯 Scénarios d'utilisation

### 📈 Tout va bien
*   SpO₂ > 95%
*   Température 37°C
*   Humidité 50%
    → **Continuez ainsi !**

### ⚠️ Attention requise
*   SpO₂ < 95% OU Température > 37.8°C
*   Air trop sec (< 30%) ou trop humide (> 70%)
    → **Surveillez votre état, hydratez-vous, et ajustez votre environnement.**

### � Alerte
*   SpO₂ < 92%
*   Difficultés respiratoires
*   Fièvre élevée (> 38.5°C)
    → **Consultez un médecin immédiatement.**

## 💡 Conseils
- Utilisez le **Mode Simulation** pour vous entraîner à lire les valeurs.
- En **Mode Réel**, assurez-vous que les capteurs sont bien positionnés.
- La température corporelle est plus précise après quelques minutes de repos.

---

## 📞 En cas d'urgence
**Si vous voyez plusieurs indicateurs rouges :**
1. 📱 **Contactez immédiatement** votre médecin ou le 15 (SAMU)
2. 💊 **Prenez vos médicaments** d'urgence si prescrits
3. 👥 **Prévenez un proche**

*Cette application est un outil d'aide mais ne remplace jamais l'avis médical professionnel.*
