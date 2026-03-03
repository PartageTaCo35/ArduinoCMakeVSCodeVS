# 🚀 Modern Arduino CMake
Marre de l'IDE Arduino classique ? Utilisez la puissance de **Visual Studio 2026** ou **VS Code** et **CMake** pour développer sur AVR (Uno, Nano, etc.) avec un environnement de qualité professionnel mais accessible aux hobbyists, tout en gardant vos habitudes Arduino.

## 1. Démarrage Rapide
  - Copier ou cloner le dépôt.
  - **Ajouter vos sources** et sous-répertoires de sources à la racine.
  - Personnaliser au besoin le fichier CMakeLists.txt fourni à la racine.
  - Configurer votre carte dans le fichier board.json.
  - Lancer votre IDE (VS ou VS Code) en mode CMake et choisissez le dossier où le CMakeLists.txt se trouve.
  - Votre IDE configurera le projet CMake (il peut vous demander certaines précisions lors de cette étape).
    - Si vous êtes sous Visual Studio, **basculez l'affichage** de l'Explorateur de solutions en mode CMake par un simple clic droit.
  - Compiler & Flasher : Sélectionnez la cible flash dans votre IDE pour envoyer le code sur la carte.

**Prérequis :** 
  - CMake (3.19+)
  - Arduino IDE (pour fournir l'écosystème)
  - Éventuellement Doxygen pour la documentation.

## 2. Configurer votre carte (board.json)
Pas de menus cachés. Tout se passe dans un fichier JSON simple à la racine.
Si vous ne le créez pas, le projet utilise par défaut les réglages d'un Arduino Uno.

```JSON
{
  "board": "uno",
  "mcu": "atmega328p",
  "f_cpu": "16000000UL",
  "upload_port": "COM3",
  "upload_baud": "115200",
  "programmer": "arduino",
  "defines": [
    "ARDUINO=10819",
    "ARDUINO_AVR_UNO",
    "ARDUINO_ARCH_AVR"
  ]
}
```

## 3. Flexibilité et Modes de fonctionnement
Le framework s'adapte à votre manière de travailler selon quatre modes détectés automatiquement :
  - **Mode Arduino** : Utilisez uniquement des fichiers ```.ino```. Le framework injecte automatiquement ```Arduino.h``` pour vous.
  - **Mode C++ pur** : Développez classiquement avec des fichiers ```.cpp``` et ```.h```.
  - **Mode Hybride** : Mélangez un fichier ```.ino``` pour la structure globale et des fichiers ```.cpp``` pour vos classes et drivers.
  - **Mode Expert (Root)** : Vous pouvez définir votre propre fichier ```main.cpp```. Dans ce cas, le framework ignore celui fourni par Arduino pour vous donner le contrôle total.

**Astuce :** Pour comprendre comment Arduino initialise le matériel, inspirez-vous du fichier original situé dans votre installation : ```cores/arduino/main.cpp```.

### Ajouter des bibliothèques ou des cartes
Le framework s'appuie sur l'écosystème officiel. Pour ajouter une nouvelle bibliothèque ou une carte :
  - Ouvrez l'**Arduino IDE**.
  - Effectuez la procédure classique (Gestionnaire de bibliothèques ou de cartes).
  - Relancez simplement la configuration CMake dans votre IDE professionnel. Le projet détectera automatiquement les nouveaux composants.

### Points forts
  - **Bibliothèques facilitées :** Pour ajouter ```Wire``` ou ```SPI```, il suffit d'une ligne dans votre CMake : ```arduino_link_libraries(votre_app Wire SPI)```.
  - **Code ultra-léger :**         Le système supprime automatiquement le code inutile et optimise la taille finale (LTO) pour que vos programmes rentrent dans les plus petits microcontrôleurs.
  - **Organisation propre :**      Vos dossiers et fichiers d'en-tête (```.h```) s'affichent correctement dans l'arborescence de votre IDE, facilitant la navigation.
  - **Astuce Coloration :**        Configurez votre IDE pour qu'il applique la coloration syntaxique du C++ aux fichiers ```.ino``` afin de bénéficier de l'auto-complétion complète. 😉

## 4. Documentation (Optionnel)
Si Doxygen est installé sur votre système, vous pouvez générer une documentation technique complète de votre code en lançant la cible doc_votre_app.
C'est l'outil idéal pour maintenir des projets complexes et propres sur le long terme.

## 5. Licence
Ce projet est distribué sous licence MIT. Vous êtes libre de l'utiliser, de le modifier et de le partager.