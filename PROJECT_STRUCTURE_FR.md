# Architecture & Philosophie du Framework CMake

Ce projet repose sur un framework CMake sur-mesure de qualité industrielle, conçu pour le développement embarqué sur microcontrôleurs AVR (Arduino).
L'objectif de cette architecture est de s'affranchir de l'IDE Arduino classique tout en conservant sa compatibilité, en offrant une compilation modulaire, rapide, stricte et prévisible.

## 📁 Arborescence du Projet

L'arborescence est divisée en deux parties : la racine (qui contient la configuration globale et la toolchain) et le dossier `cmake/` (qui contient le moteur de génération).

    C:.
    │   .gitignore                 # Fichiers ignorés par Git (ex: build/, .vs/)
    │   board.json                 # Fichier de configuration définissant la cible matérielle (MCU, fréquence, etc.)
    │   BOARD_CONFIG_EN.md         # Documentation de la configuration de la carte (Anglais)
    │   BOARD_CONFIG_FR.md         # Documentation de la configuration de la carte (Français)
    │   CMakeLists.txt             # Point d'entrée principal de CMake. Orchestre le projet.
    │   CMakePresets.json          # Préréglages CMake (presets) pour l'intégration continue et les IDE (VS2022, VSCode).
    │   LICENSE                    # Licence du projet
    │   README fr.md               # Documentation générale (Français)
    │   README.md                  # Documentation générale (Anglais)
    │   Toolchain-AVR.cmake        # Fichier de Toolchain croisée : configure CMake pour utiliser avr-gcc au lieu du compilateur PC natif.
    │
    └───cmake/                     # Cœur du framework de compilation
            Arduino.cmake          # Orchestrateur principal des modules Arduino.
            ArduinoApp.cmake       # Module de gestion de l'application utilisateur.
            ArduinoCore.cmake      # Module de gestion du framework natif (Arduino Core).
            ArduinoDeps.cmake      # Module de gestion des bibliothèques tierces.
            ArduinoHelper.cmake    # Boîte à outils interne (fonctions utilitaires privées).

## 🧠 Philosophie de Conception

Le framework a été architecturé autour de trois grands principes d'ingénierie logicielle : le **Principe de Responsabilité Unique (SRP)**, la **Symétrie Architecturale**, et l'**Encapsulation**.

### 1. La Symétrie Architecturale (Le Cœur du Design)

Le traitement des sources est divisé en trois entités distinctes mais traitées avec une symétrie absolue. Que l'on compile le cœur Arduino, une bibliothèque externe ou l'application finale, le flux d'exécution reste strictement le même. 

Cette symétrie est incarnée par les trois modules frères :
* **`ArduinoCore.cmake`** : Compile les sources de base du microcontrôleur (`wiring.c`, `HardwareSerial.cpp`, etc.) sous forme de bibliothèque statique.
* **`ArduinoDeps.cmake`** : Compile les bibliothèques tierces (ex: Wire, SPI) sous forme de bibliothèques statiques.
* **`ArduinoApp.cmake`**  : Compile le code source de l'utilisateur final et réalise l'édition de liens (Link) avec le Core et les Dépendances pour générer l'exécutable (`.elf` / `.hex`).

**Le Modèle de Conception (Pattern) unifié :**
Chacun de ces trois modules suit rigoureusement la même séquence logique en trois étapes :
1.  **Gather (Collecte)** : Recherche récursive des fichiers sources (`.c`, `.cpp`, `.S`).
2.  **Adjust (Filtrage)** : Purge chirurgicale des fichiers indésirables (exclusion des dossiers `examples/`, `extras/`, ou des sketchs `.ino` parasites).
3.  **Build (Construction)** : Création de la cible CMake (`add_library` ou `add_executable`) et application des propriétés.

Ce modèle s'appuie également sur une gestion stricte de la visibilité (Scope). Les fonctions sont logiquement classées en : 
1.  **Public** API exposée à l'utilisateur dans `Arduino.cmake`.
2.  **Protected** fonctions de construction partagées entre les modules internes.
3.  **Private** méthodes utilitaires inaccessibles de l'extérieur.

### 2. Principe de Responsabilité Unique (SRP)

Chaque fichier `.cmake` a un rôle unique et défini, évitant ainsi un `CMakeLists.txt` monolithique et illisible :
* Le `CMakeLists.txt` racine ne fait que déclarer le projet et appeler le framework.
* Le fichier `Toolchain-AVR.cmake` ne fait *que* configurer le compilateur croisé.
* Le fichier `Arduino.cmake` agit comme un chef d'orchestre : il inclut les sous-modules et expose l'API publique.
* Le fichier `ArduinoHelper.cmake` factorise les parties de code communes et isole toute la machinerie complexe (expressions régulières, parcours de dossiers), garantissant que les autres modules ne fassent *que* de la déclaration de cibles.

### 3. Encapsulation et Résilience (`ArduinoHelper.cmake`)

Pour maintenir les modules `App`, `Core` et `Deps` aussi propres et lisibles que possible, toute la complexité algorithmique (expressions régulières, parcours de dossiers, abstraction des commandes CMake) est reléguée dans **`ArduinoHelper.cmake`**.

Ce fichier agit comme une API privée (les fonctions sont préfixées par `_arduino_` pour indiquer qu'elles ne doivent pas être appelées directement depuis le `CMakeLists.txt` utilisateur). Il garantit la robustesse du framework, notamment grâce à son filtrage avancé qui rend la compilation totalement résiliente face aux bibliothèques Arduino mal structurées.

---
*Ce framework offre ainsi une base de développement "bare-metal" professionnelle, prête à accueillir des projets C/C++ ambitieux avec des temps de compilation optimisés et un outillage prédictible.*