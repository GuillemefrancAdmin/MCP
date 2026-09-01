<!--
  TEMPLATE — Fiche de processus organisationnel
  ================================================
  Usage : dupliquer ce fichier pour chaque processus (ex: MP01-P01-processus.md)
  et remplir les champs entre [ ]. Les blocs "Activité" et "Tâche/Étape" sont
  répétables : copier/coller le bloc autant de fois que nécessaire.
  Convention de codes : MPxx (macro processus) - Pxx (processus) - Axx (activité) - Txx (tâche/étape)
-->

# [Code Processus] — [Titre du processus]

## Métadonnées du formulaire

| Champ | Valeur |
| --- | --- |
| Usager authentifié | [Nom Prénom (courriel)] |
| Date de rédaction | [AAAA-MM-JJ] |
| Version du document | [1,00] |
| Statut | [En cours \| Approuvé \| Abandonné] |
| **Domaine d'affaire** | [ex. Gestion académique — Gestion du curriculum / RH / Finances / Admissions / etc.] |

<!--
  Domaine d'affaire : le module métier auquel appartient ce processus au sein
  du système organisationnel (ex. Gestion académique, Gouvernance, Finances,
  RH, Admissions, Affaires étudiantes...). Sert à classer et regrouper les
  fiches de processus par grand domaine lors de l'indexation.
-->

---

## 1. Secteur

- **Secteur :** [ex. Décanat des études]
- **Responsable :** [Nom] — **Courriel :** [courriel]

## 2. Macro Processus

| Champ | Valeur |
| --- | --- |
| **Code** | [MPxx] |
| **Titre** | [Titre du macro processus] |
| **Description** | [Ensemble des processus et opérations couverts par ce macro processus] |
| **Division** | [Nom de la division responsable] |
| **Responsable division** | [Nom] — [courriel] |
| **Secteur responsable** | [Nom du secteur] |
| **Responsable secteur** | [Nom] — [courriel] |
| **Commentaire** | [Remarques générales sur le macro processus] |

## 3. Processus

| Champ | Valeur |
| --- | --- |
| **Code** | [Pxx] |
| **Titre** | [Titre du processus] |
| **Version** | [1,00] |
| **Description** | [Résumé de ce que couvre le processus] |
| **Révision (section informatique)** | [1,00] |
| **Statut (section informatique)** | [En cours \| Actif \| Abandonné] |
| **Parents** | [Processus parent(s), s'il y a lieu] |

### Intrants

- [Intrant 1 — provenance]
- [Intrant 2 — provenance]

### Extrants

- [Extrant produit par le processus]

### Commentaire général du processus

[Contexte, portée, cas d'application, exceptions, notes sur la gestion (ex. programme conjoint/réseau)]

### Notes complémentaires

<!-- Reprendre autant de notes numérotées que nécessaire, comme dans le document source -->

**Note #1 — [Titre de la note]**
[Contenu]

**Note #2 — [Titre de la note]**
[Contenu]

---

## 4. Instances / parties prenantes impliquées

<!-- Utile pour les processus organisationnels traversant plusieurs comités/instances -->

### Instances internes

1. [Instance 1]
2. [Instance 2]

### Instances externes

1. [Instance 1]
2. [Instance 2]

---

## 5. Activités

<!-- ===================== BLOC RÉPÉTABLE : ACTIVITÉ ===================== -->

### [MPxx-Pxx-Axx] — [Titre de l'activité]

| Champ | Valeur |
| --- | --- |
| **Code** | [MPxx-Pxx-Axx] |
| **Description** | [Description de l'activité] |
| **Intrant de** | [Activité(s) précédente(s), s'il y a lieu] |
| **Commentaire** | [Remarques] |

**Section informatique**

| Champ | Valeur |
| --- | --- |
| À informatiser | [Oui/Non] |
| Commentaire analyse | [Notes d'analyse] |

#### Tâches / Étapes

<!-- ----------- SOUS-BLOC RÉPÉTABLE : TÂCHE / ÉTAPE ----------- -->

##### [MPxx-Pxx-Axx-Txx] — [Titre de la tâche]

| Champ | Valeur |
| --- | --- |
| **Code** | [MPxx-Pxx-Axx-Txx] |
| **Description** | [Description de la tâche] |
| **Application** | [Word \| Outlook \| File Maker \| Système interne \| —] |
| **Acteur(s)** | [Rôle — Secteur] |
| **Intrant de** | [Tâche précédente, s'il y a lieu] |
| **Tâches suivantes** | Code : [ ] — Conditions : [ ] |
| **Commentaire** | [Remarques, exemples, pièces jointes de référence] |

**Section informatique**

| Champ | Valeur |
| --- | --- |
| À informatiser | [Oui/Non] |
| Commentaire analyse | [Notes d'analyse] |
| Fonctions système | [ex. aef_x_x_x.osq, page WEB, etc.] |

<!-- Fin sous-bloc — dupliquer pour chaque tâche/étape suivante -->

<!-- Fin bloc activité — dupliquer la section 5 pour chaque activité suivante (A02, A03, ...) -->

---

## 6. Vue d'ensemble (index rapide)

<!--
  Tableau récapitulatif à remplir une fois toutes les activités/tâches détaillées ci-dessus.
  Sert d'index de navigation rapide pour le processus complet.
-->

| Code | Titre | Type | Acteur(s) principal(aux) | Application |
| --- | --- | --- | --- | --- |
| [Pxx] | [Titre du processus] | Processus | — | — |
| [Axx] | [Titre de l'activité] | Activité | [Rôle] | — |
| [Axx-Txx] | [Titre de la tâche] | Tâche | [Rôle] | [Outil] |

---

## 7. Documents et pièces de référence

| Référence | Description | Emplacement |
| --- | --- | --- |
| [MPx-Px-1] | [ex. Étapes et échéancier (exemple)] | [chemin ou dépôt] |
| [MPx-Px-2] | [ex. Table des matières (gabarit)] | [chemin ou dépôt] |

---

## 8. Historique des révisions

| Version | Date | Auteur | Changements |
| --- | --- | --- | --- |
| 1,00 | [AAAA-MM-JJ] | [Nom] | Création initiale |
