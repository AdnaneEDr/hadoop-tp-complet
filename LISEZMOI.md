# Dossier du TP Hadoop 0 à 3

Commencer par **Compte_rendu.pdf** : les 28 exercices sont traités, avec les résultats et les limites d'exécution.

## Ce qui est disponible

- Compte rendu : PDF, Markdown modifiable et HTML.
- `tp3/` : trois programmes Java et projet Maven Hadoop 3.4.3.
- `docker-compose.yml` et `config` : cluster du sujet, avec files default/dev.
- `scripts/` : compilation, démarrage WSL, parcours HDFS/MapReduce et contrôles Python.
- `donnees/` : intégralité du pack fourni, y compris les 18 livres et le bonus 10 000 personnes.
- `resultats/verification_locale/` : résultats complets réellement recalculés en Python, TSV et synthèse JSON.
- `captures/` : captures réelles du navigateur montrant les vérifications locales ; également intégrées au PDF.
- `preuves/` : journal du calcul local et diagnostic de l'environnement.
- `Sujet_original.pdf` : énoncé fourni.
- `MANIFEST_SHA256.txt` : contrôle d'intégrité de tous les autres fichiers.

**Le cluster HDFS/YARN n'a pas été exécuté avec succès.** Les réponses théoriques sont séparées des résultats calculés. Il n'y a pas de JAR compilé, de logs de jobs Hadoop réussis ni de capture NameNode/ResourceManager dans ce dossier. Docker est installé mais son moteur est indisponible ; les téléchargements Hadoop ont échoué. Les sources sont fournies, mais leur compilation contre Hadoop reste à effectuer.

## Recalcul local, sans Hadoop

Depuis le dossier décompressé, avec Python 3 :

```bash
python scripts/verifier_local.py
```

Ce contrôle traite les cinq livres et les réseaux à 5 et 1 000 personnes. Il utilise uniquement la bibliothèque standard Python. Pour k=4, prévoir de la mémoire disponible (le calcul conserve environ 8,9 millions de clés). Ce programme ne simule pas les services Hadoop.

## Installation Docker et compilation

Prérequis : Docker Desktop fonctionnel avec moteur Linux, mémoire adaptée, accès aux registres d'images et à Maven Central. Les logiciels et dépendances Hadoop ne sont pas embarqués dans le ZIP.

Dans PowerShell, depuis ce dossier :

```powershell
New-Item -ItemType Directory -Force jobs | Out-Null
docker compose up -d --scale datanode=2 --scale nodemanager=2
docker compose ps
docker run --rm -v "${PWD}/tp3:/app" -w /app maven:3.9-eclipse-temurin-17 mvn -q package
Copy-Item tp3/target/tp3.jar jobs/tp3.jar
docker compose exec namenode bash /opt/scripts/tp_cluster.sh
```

Le script génère les résultats et un journal dans `resultats/cluster`. Il exige un espace `/user/etudiant/tp1` à `tp3` neuf : ne pas le relancer tel quel si des sorties existent déjà. Utiliser un cluster de TP dédié. Les données créées sont de petits jeux de test. Les exercices de quota et safe mode provoquent volontairement des refus d'écriture, vérifiés par le script.

Le script fait l'ajout `THE END` à la fin, après les WordCount. Il ne tue pas automatiquement une application à 30 % et ne détruit pas les conteneurs : suivre la procédure interactive du compte rendu pour ces points. Aucun `docker compose down` automatique n'est inclus. Pour arrêter en conservant HDFS : `docker compose stop`.

Interfaces : HDFS `http://localhost:9870` ; YARN `http://localhost:8088`.

## Variante WSL

Installer Java 11 et extraire la distribution officielle Hadoop 3.4.3 dans `~/tp-hadoop-runtime/hadoop-3.4.3`. Puis, sous Ubuntu WSL, depuis le dossier du TP :

```bash
bash scripts/demarrer_wsl.sh
bash scripts/compiler.sh
bash scripts/tp_cluster.sh
```

Cette variante pédagogique a été préparée mais **n'a pas pu être validée**. Elle crée ses propres configurations et répertoires sous `~/tp-hadoop-runtime` et utilise les ports 19870 (HDFS) et 18088 (YARN). Elle ne formate le NameNode que si son dossier `current` est absent. Les deux DataNodes et deux NodeManagers partagent l'hôte physique.

## Captures à compléter sur un cluster fonctionnel

1. Conteneurs en fonctionnement et versions Java/Hadoop.
2. NameNode : deux DataNodes et cinq livres ; `fsck` Bible, cinq blocs.
3. Quota refusé, sous-réplication à r=3 et mode sécurisé.
4. ResourceManager : deux nœuds, ressources, application RUNNING puis SUCCEEDED.
5. Application tuée et logs avec les identifiants réels.
6. File dev et résultats/counters des trois programmes Java.
7. Comparaison des `Reduce shuffle bytes` avec et sans Combiner.

Les captures incluses sont celles des calculs locaux disponibles. Cette liste signale explicitement les preuves distribuées manquantes.
