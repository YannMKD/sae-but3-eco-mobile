# TRACKSTAR

**Université Sorbonne Paris Nord - IUT de Villetaneuse**
**BUT Informatique - 3ème année (Groupe Hauméa)**
**SAE S501 : Développement avancé**
**Année universitaire : 2025-2026**

Ce dépôt contient le code source et la documentation technique du projet TRACKSTAR, réalisé dans le cadre de la SAE S501 : Développement avancé 
---

## 1. Présentation du projet
TRACKSTAR est une application mobile de recommandation musicale développée dans le cadre de la SAE S501 pour l'entreprise fictive *IUT Corp*.
L’application propose à l’utilisateur des titres musicaux adaptés à ses préférences à partir d’interactions simples, tout en fonctionnant entièrement hors connexion Internet.

L’objectif principal est de concevoir une application mobile capable :
	•	de recommander des titres musicaux de manière personnalisée,
	•	de fonctionner localement, sans dépendre d’API ou de services distants,
	•	de proposer une interaction rapide et intuitive adaptée à un usage mobile.

### Philosophie
Le positionnement de l'application est résumé par le slogan : **"Chase Stars Not Trends"**. L'utilisateur est invité à construire son propre univers musical (sa "galaxie") au travers d'interactions directes, sans influence extérieure.
L'application répond à une problématique de transparence et de personnalisation : là où les plateformes de streaming traditionnelles utilisent des algorithmes "boîte noire" favorisant les tendances commerciales, TRACKSTAR place l'utilisateur au centre de l'exploration musicale.



## 2. Fonctionnalités Principales

* **Mode Hors-ligne (Offline First) :** L'intégralité du catalogue et le moteur de recommandation sont embarqués sur le terminal.
* **Mécanique de Swipe :** Interface de notation intuitive (droite pour "Liker", gauche pour "Disliker").
* **Système de "Cold Start" :** En l'absence d'historique, l'application propose les titres les plus populaires pour amorcer la collecte de données.
* **Recommandation Adaptative Hybride :**
    * Analyse vectorielle des préférences.
    * Diversification automatique (Règle 80/20 : 80% de titres similaires, 20% de découverte pour éviter la bulle de filtrage).



## 3. Architecture et Choix Techniques

Le projet repose sur une architecture modulaire séparant la couche de présentation, la logique métier et la persistance des données.

### Stack Technique

* **Framework : Flutter (Dart)**
    * *Justification :* Choix motivé par la nécessité d'un rendu natif performant sur Android pour gérer les animations fluides (swipe) et par la portabilité du code.
* **Persistance : SQLite (via `sqflite`)**
    * *Justification :* Contrainte de fonctionnement hors-ligne. SQLite permet de stocker efficacement les métadonnées de ~30 000 titres et d'effectuer des opérations mathématiques (distances) directement via des requêtes SQL optimisées, sans la lourdeur d'un SGBD serveur.
* **IDE & Outils :** VS Code / Android Studio, Figma (Maquettage), Git (Versioning), Photoshop (Branding).

### Données utilisées

L’application s’appuie sur une base de données musicale issue d’un dataset Spotify (Kaggle), contenant environ 30 000 titres.
Chaque titre est décrit par douze caractéristiques audio, qui sont exploitées par le système de recommandation.

Les données sont stockées localement dans une base SQLite, incluse directement dans l’application.
Les interactions de l’utilisateur (likes / dislikes) sont également persistées localement, ce qui permet de conserver son profil entre deux sessions.


### Structure du Projet

```text
lib/
├── main.dart                  # Point d'entrée de l'application
├── models/                    # Modèles de données (Track, ProfileVector)
├── screens/                   # Vues (HomePage, SwipeView, Settings)
├── services/                  # Logique métier et accès données
│   ├── database_service.dart  # Gestionnaire SQLite et requêtes brutes
│   └── prefs_service.dart # Implémentation de la logique de filtrage
assets/
└── images/               
```

## 📥 Installation

1.  **Cloner le dépôt :**
    ```bash
    git clone [https://github.com/votre-repo/trackstar.git](https://github.com/votre-repo/trackstar.git)
    ```
2.  **Installer les dépendances :**
    ```bash
    flutter pub get
    ```
3.  **Base de données :**
    Assurez-vous que le fichier `app.db` (ou `tracks.db`) est bien présent dans `assets/database/`.
4.  **Lancer l'application :**
    ```bash
    flutter run
    ```


## Performance et Optimisation

L’application a été conçue pour garantir des performances compatibles avec un usage mobile *offline*, en maîtrisant le CPU, la mémoire et la batterie.

### Analyse de Complexité
- **Complexité globale :** **O(N log N)**  
  La complexité est dominée par le tri des distances euclidiennes sur l’ensemble du catalogue (≈ 30 000 titres) lors de la phase de recommandation.

### Optimisations mises en œuvre
- **Réduction dimensionnelle (ACP)** : passage de 12 à 8 dimensions afin d’alléger les calculs vectoriels.
- **Traitement asynchrone** : exécution du moteur de recommandation hors du thread UI pour préserver la fluidité.
- **Mise en cache du profil utilisateur** : limitation des recalculs lors des swipes successifs.
- **Gestion optimisée du cycle de vie** : arrêt des traitements coûteux en arrière-plan pour réduire l’impact énergétique.

Ces choix permettent d’atteindre des temps de réponse inférieurs à la seconde, une consommation d’environ 10 % de batterie par heure et une utilisation mémoire stable, sans fuites.

---

## Branding & Interface

L’identité de TRACKSTAR a été conçue comme un prolongement direct du fonctionnement de l’application : encourager une découverte musicale active à travers une métaphore spatiale cohérente.

- Concept narratif  
  L’utilisateur est envisagé comme un explorateur évoluant au sein de galaxies musicales, chacune correspondant à un regroupement de titres aux caractéristiques audio similaires. Cette approche permet de rendre lisible et engageant un système de recommandation fondé sur des clusters algorithmiques.

- Logo  
  Le logo représente une silhouette humaine inversée, flottant en apesanteur. Il ne décrit pas littéralement l’écoute musicale, mais symbolise le lâcher-prise, l’immersion et l’exploration, en cohérence avec l’univers de marque de l’application.

- Typographie  
  Le nom TRACKSTAR utilise la police Helvetica, en référence à son usage historique dans l’identité visuelle de la NASA, afin d’ancrer la marque dans une imagerie d’exploration rigoureuse et technologique.  
  L’interface de l’application repose volontairement sur la police système par défaut de Flutter, dans une logique de lisibilité, de performance et d’optimisation des ressources.

- Interface et choix visuels  
  L’application adopte un mode sombre dominant, inspiré du ciel étoilé, accompagné d’effets visuels discrets (nébuleuses, animations de feedback) servant de repères narratifs.  
  Le design est volontairement minimaliste et textuel, sans médias lourds, afin de garantir fluidité, réactivité et compatibilité avec un fonctionnement entièrement hors-ligne.


## Équipe de Développement (Groupe Hauméa)

Le projet a été réalisé grâce à une organisation agile en pôles de compétences.

### Pilotage & Branding
* **Kelvin UTHAYAKUMAR** (Chef de projet & Frontend)
* **Yann DIARRASSOUBA** (Branding & Algorithmie)

### Développement Logiciel
* **Rayan EL OUAZZANI** (Lead Fullstack & Architecture Reco)
* **Edmilson DA COSTA SA** (Backend & Support technique)
* **Ilyes MEDJDOUB** (Optimisation & Qualité)

### Interface & Expérience Utilisateur
* **Leelian SERRANT** (Lead Frontend & UI/UX)
* **Mouhamadou Mourtada DIOP** (Intégration Front-end)



## 📄 Licence

Ce projet est distribué sous licence MIT.
*Copyright © 2026 Groupe Hauméa - IUT de Villetaneuse.*
