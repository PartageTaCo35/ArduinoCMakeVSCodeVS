# ⚙️ Configuration de la carte (`board.json`)

Le fichier `board.json` est le cœur de la configuration matérielle de votre projet. Il permet d'indiquer au framework CMake quel microcontrôleur vous ciblez et comment envoyer le code dessus, sans avoir à toucher aux scripts complexes.

Si ce fichier est absent de la racine de votre projet, le framework utilisera automatiquement la configuration d'un **Arduino Uno** par défaut.

## Structure du fichier

Voici la liste des paramètres attendus dans le fichier :

* **`board`** : Le nom "humain" de la carte (ex: `uno`, `nano`). Principalement utilisé pour la lisibilité.
* **`mcu`** : La référence exacte de la puce (ex: `atmega328p`, `atmega2560`). Utilisé par le compilateur GCC pour adapter les instructions.
* **`f_cpu`** : La fréquence d'horloge du processeur en Hertz, suivie de `UL` (Unsigned Long).
* **`upload_port`** : Le port série sur lequel votre carte est branchée (ex: `COM3` sous Windows, `/dev/ttyUSB0` sous Linux).
* **`upload_baud`** : La vitesse de communication pour le téléversement. Dépend du bootloader de la carte.
* **`programmer`** : Le protocole utilisé par AVRDUDE pour communiquer avec la carte (généralement `arduino` ou `wiring`).
* **`defines`** : Une liste (tableau) de macros de préprocesseur qui seront injectées dans votre code et dans la bibliothèque Arduino.

---

## 📋 Exemples Prêts à l'emploi

Voici des configurations standards pour les cartes les plus communes.
Copiez-collez simplement le bloc correspondant dans votre fichier `board.json` et adaptez le `upload_port`.

### 1. Arduino Uno (Par défaut)
```json
{
  "board": "uno",
  "mcu": "atmega328p",
  "variant": "standard",
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

### 2. Arduino Nano (Ancien Bootloader)
```json
Note : Très courant sur les clones chinois.
{
  "board": "nano",
  "mcu": "atmega328p",
  "variant": "eightanaloginputs",
  "f_cpu": "16000000UL",
  "upload_port": "COM4",
  "upload_baud": "115200",
  "programmer": "arduino",
  "defines": [
    "ARDUINO=10819",
    "ARDUINO_AVR_NANO",
    "ARDUINO_ARCH_AVR"
  ]
}
```

### 3. Arduino Mega 2560
```json
{
  "board": "mega",
  "mcu": "atmega2560",
  "variant": "mega",
  "f_cpu": "16000000UL",
  "upload_port": "COM5",
  "upload_baud": "115200",
  "programmer": "wiring",
  "defines": [
    "ARDUINO=10819",
    "ARDUINO_AVR_MEGA2560",
    "ARDUINO_ARCH_AVR"
  ]
}
```

## 🔍 Comment trouver les paramètres pour une carte exotique ?
Si votre carte ne figure pas dans la liste ci-dessus, voici l'astuce imparable pour trouver les bonnes valeurs :
  1. Ouvrez l'IDE Arduino officiel.
  2. Allez dans Fichier > Préférences, et cochez la case **"Afficher les résultats détaillés pendant la compilation et le téléversement"**.
  3. Sélectionnez votre carte et son port, puis compilez et téléversez un programme vide (**Blink**).
  4. Dans la console noire en bas, cherchez la longue ligne de commande **avr-gcc** :
     - Cherchez le paramètre `-mmcu=` (cela vous donnera le mcu).
     - Cherchez le paramètre `-DF_CPU=` (cela vous donnera le `f_cpu`).
     - Cherchez les `-DARDUINO_AVR_...` (cela vous donnera les `defines`).
  5. Cherchez la ligne commençant par avrdude lors du téléversement :
     - Le paramètre `-c` vous donne le programmer.
     - Le paramètre `-b` vous donne le upload_baud.
	 
## Attention
Les **ESP32**, **RISCV**, carte basé sur **ARM** ne sont pas des carte utilisant AVR et donc AVR-GCC.

## ⚠️ Note importante sur la configuration
Toute modification apportée au fichier `board.json` (changement de port, de MCU ou de flags) n'est pas prise en compte instantanément par le système de build. 

Pour que vos changements soient correctement propagés dans le projet, vous devez **régénérer le cache CMake** de votre IDE (généralement via la commande "Delete Cache and Reconfigure" ou "Reload CMake Project").
Cette étape est nécessaire pour garantir que les nouvelles définitions matérielles soient bien transmises au compilateur.
