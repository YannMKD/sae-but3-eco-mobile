# ✨ Trackstar ✨

## ✨ Aperçu du Projet

Notre application mobile développée avec **Flutter** qui implémente un système de recommandation musicale basé sur une approche **hybride**. L'objectif est d'aider l'utilisateur à découvrir de nouveaux morceaux via une interface simple de "swiping" (similaire à Tinder), tout en construisant un profil de goûts précis basé sur 8 **Composantes Principales (CP)** de la musique.

L'application utilise une base de données **SQLite** pré-calculée qui contient les caractéristiques vectorielles de milliers de morceaux.

---

## 🛠️ Stack Technique

| Domaine | Technologie / Langage | Dépendances Clés |
| :--- | :--- | :--- |
| **Mobile** | Flutter (Dart) | `sqflite`, `path_provider` |
| **Base de Données** | SQLite | Fichier `assets/app_data.db` |
| **Data Preprocessing**| Python, Pandas | `spotify_data_preprocessed_final.csv` (Source) |

---

## 🚀 Fonctionnalités Clés et Algorithme

### 1. Système de Swiping et Interactions
L'utilisateur interagit avec les morceaux via :
* **Swipe Droit (Like) :** `liked = 1`
* **Swipe Gauche (Dislike) :** `liked = -1`
* **Non vu :** `liked = 0`

### 2. Stratégie de Recommandation Hybride

Le système bascule dynamiquement entre deux modes :

| Mode | Condition | Fonctionnement |
| :--- | :--- | :--- |
| **Cold Start** | Moins de 5 interactions enregistrées. | Affiche les 10 morceaux les plus populaires (`track_popularity` DESC). |
| **Recommandation Vectorielle**| 5 interactions ou plus. | Calcule la distance euclidienne entre le **vecteur profil utilisateur** et les morceaux non vus (`liked=0`). Propose les morceaux ayant la distance la plus faible. |

### 3. Calcul du Profil Utilisateur

Le vecteur profil (8 dimensions) est calculé comme la moyenne pondérée des vecteurs CP des morceaux aimés et dislikés :

$$\text{Score Net Moyen} (\text{CP}_n) = \frac{\sum_{\text{Like}} \text{CP}_n - \sum_{\text{Dislike}} \text{CP}_n}{N_{\text{Total Swipes}}}$$

Ce calcul est effectué via la requête SQL `DatabaseQueries.calculateProfileVector`.
