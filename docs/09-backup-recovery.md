# 09 — Sauvegarde et récupération d'Inventory V1 Android

## 1. Objectif et décisions produit

Ce document définit un format unique, l'export, la validation, la restauration et la récupération après interruption pour l'inventaire local Inventory V1.

Décisions produit obligatoires :

- **D09-01 — Sauvegarde système Android :** les données Inventory sont exclues de la sauvegarde automatique Android, y compris les transferts d'appareil gérés par la plateforme.
- **D09-02 — Chiffrement :** aucune couche de chiffrement, aucun mot de passe, aucune clé, biométrie ou chiffrement SQLite propre à Inventory.
- **D09-03 — Complétude :** une sauvegarde inclut toutes les données métier restaurables, y compris les biens retirés ; aucune sauvegarde partielle ou différentielle.
- **D09-04 — Remplacement :** une restauration confirmée remplace l'inventaire actif en entier ; aucune fusion.
- **D09-05 — Préservation :** un fichier invalide ou une restauration interrompue ne doit pas détruire l'inventaire actif.

Inventory demeure Android uniquement, Flutter/Dart, Drift/SQLite, local et hors ligne. Les sauvegardes sont déclenchées volontairement et transférées par le sélecteur de fichiers Android. Le fournisseur choisi par l'utilisateur peut toutefois être externe ou synchroniser le fichier ; ce comportement n'est pas contrôlé par Inventory.

## 2. Périmètre et données couvertes

La sauvegarde couvre les tables métier du [modèle de données](04-data-domain-model.md) :

- l'unique ligne `inventories` et son identité ;
- toutes les lignes `nodes`, actives et retirées, avec leurs parents, propriétés, quantités, valeurs, statuts, motifs et dates de retrait ;
- toutes les lignes `categories` ;
- toutes les associations `node_categories`.

Les identifiants sont conservés sans régénération afin que les références soient restaurées fidèlement. La sauvegarde inclut les valeurs sentimentales et les valeurs financières exactes en cents, comme définies dans le modèle.

La V1 ne gère pas les pièces jointes. Aucun fichier temporaire, journal SQLite, cache, préférence d'interface, URI de fournisseur, donnée d'authentification ou reçu interne de restauration n'est une donnée métier à exporter.

## 3. Comparaison et choix du format

| Option | Avantages | Limites et risques |
| --- | --- | --- |
| Copie cohérente d'une base SQLite | Fidélité native aux types, contraintes et index ; taille souvent réduite. | Une copie du fichier actif peut omettre des transactions en WAL si mal faite ; dépendance à la version et au schéma SQLite/Drift ; difficile à inspecter et valider avant remplacement ; les migrations d'une base arbitraire sont délicates. |
| Export structuré JSON | Format indépendant des fichiers SQLite ; validation des champs et relations avant activation ; version du format distincte du schéma de base ; facile à diagnostiquer et à faire évoluer avec des conversions explicites. | Plus volumineux et coût de sérialisation/parsing ; l'ordre et l'encodage doivent être spécifiés ; non chiffré et lisible. |
| Autre format | Aucun avantage déterminant pour le volume et les données textuelles V1. | Ajouterait un parseur ou une dépendance sans bénéfice suffisant. |

**Choix V1 : JSON UTF-8 dans un conteneur binaire minimal avec longueur et empreinte.** Le format est un seul fichier autonome, sans compression et sans chiffrement. Il permet de contrôler le contenu avant toute écriture dans la base active, sans manipuler une copie brute de la base ni dépendre de ses fichiers WAL.

L'empreinte permet de détecter une corruption accidentelle et une troncature ; elle ne prouve ni l'origine ni l'authenticité du fichier puisqu'elle n'est pas signée.

## 4. Contrat du fichier de sauvegarde

### 4.1 Encadrement et métadonnées

**Extension recommandée :** `.invbackup`.

Le contenu physique est, dans cet ordre :

1. La séquence ASCII exacte `INVENTORY-BACKUP` suivie d'un octet LF (`0A`).
2. Une ligne d'en-tête JSON UTF-8, terminée par un octet LF. Elle ne contient pas de saut de ligne interne.
3. Le nombre exact d'octets `payload_length` du document JSON UTF-8 du contenu métier ; aucun octet supplémentaire après ces données.

L'en-tête contient exactement :

| Champ | Type | Signification |
| --- | --- | --- |
| `format_id` | chaîne | Valeur constante `inventory-backup`. |
| `format_version` | entier | Version de l'encadrement et des règles de sérialisation ; V1 = `1`. |
| `data_schema_version` | entier | Version des données métier sérialisées ; V1 = `1`. |
| `created_at_utc` | chaîne | Date/heure UTC ISO 8601 de création de l'instantané. |
| `payload_length` | entier | Longueur exacte du payload en octets UTF-8. |
| `payload_sha256` | chaîne | SHA-256 hexadécimal du payload exact, avant toute transformation. |

L'extension et le nom du fichier ne sont jamais considérés comme preuve de validité. Le lecteur valide la séquence magique, la ligne d'en-tête, les versions, la longueur, l'empreinte et la structure.

Le payload est un objet JSON avec exactement les clés `inventory`, `nodes`, `categories` et `node_categories`. Chaque ligne contient exactement les champs métier suivants, sans champs calculés ou dépendant de l'appareil :

| Enregistrement | Champs du payload V1 |
| --- | --- |
| `inventory` | `id`, `singleton_key`, `created_at`, `updated_at` ; exactement un objet. |
| `nodes[]` | `id`, `inventory_id`, `parent_id`, `name`, `node_type`, `quantity`, `description`, `condition`, `value_mode`, `financial_value_cents`, `sentimental_value`, `status`, `withdrawal_reason`, `withdrawn_at`, `created_at`, `updated_at`. |
| `categories[]` | `id`, `inventory_id`, `name`, `created_at`, `updated_at`. |
| `node_categories[]` | `inventory_id`, `node_id`, `category_id`. |

Les tableaux sont exportés dans un ordre déterministe par clé primaire. Les UUID et horodatages sont des chaînes ; montants en cents et quantités sont des entiers JSON ; les valeurs absentes sont `null`. Aucun nombre flottant n'est accepté. L'encodage est UTF-8. Les lignes incluent les éléments retirés dans `nodes`; aucun historique autre que celui défini au modèle n'est inventé.

Pour une même version, les noms de propriétés sont ceux du contrat et les clés du payload sont émises dans un ordre déterministe par l'exporteur. Le SHA-256 porte sur les octets exacts sérialisés ; le lecteur n'a pas à reconstituer une sérialisation canonique pour vérifier l'empreinte.

**Métadonnées techniques :** identité/versions du format, version de données, date UTC, longueur et empreinte.  
**Données métier :** inventaire, nœuds, catégories et associations.  
Ne pas inclure d'identifiant d'appareil, de compte, de suivi, de fournisseur, de chemin privé ou d'identifiant de sauvegarde associé à l'utilisateur.

### 4.2 Limites et fichiers incomplets

Recommandation V1 : refuser un fichier supérieur à **32 Mio** (en-tête inclus) et un en-tête supérieur à **4 Kio**. Le payload est non compressé ; il n'existe donc pas de risque d'expansion d'une archive. Le JSON est plat (tableaux de lignes, sans arbre JSON profond) ; imposer une profondeur de structure maximale de 8 et une limite de 100 000 nœuds. Ces limites doivent être vérifiées sur un appareil Android de capacité modeste et peuvent être abaissées si le budget mémoire de l'analyseur l'exige, mais ne doivent pas être dépassées silencieusement.

Le fichier est invalide si l'en-tête est incomplet, si la longueur annoncée ne correspond pas au nombre d'octets disponibles, si des octets suivent le payload, si SHA-256 diffère, si le JSON est mal formé, si une clé obligatoire est absente ou dupliquée, si une clé non définie pour cette version est présente ou si des valeurs ne respectent pas le contrat. Un fichier tronqué par interruption ne peut donc pas être accepté comme une sauvegarde.

Le checksum SHA-256 sert uniquement à repérer une altération accidentelle. Il ne chiffre pas le fichier et ne protège pas contre une modification volontaire accompagnée d'un recalcul du checksum.

### 4.3 Versions reconnues

- Le lecteur V1 accepte uniquement `format_version = 1` et `data_schema_version = 1`.
- Une version inconnue, supérieure ou non prise en charge est refusée avant toute écriture active.
- Une version antérieure n'est acceptée que si une conversion explicite et testée vers le modèle courant est implémentée.
- Une métadonnée obligatoire absente, dupliquée ou invalide entraîne un refus ; le lecteur ne déduit jamais la version à partir du nom de fichier ou du contenu approximatif.
- Aucun mécanisme universel de migration n'est prévu. Chaque format de données ajouté plus tard nécessite un adaptateur déterministe, puis validation du modèle courant.

Le format de sauvegarde versionné est indépendant de la version interne SQLite/Drift. Les fichiers d'une version future inconnue ne sont jamais interprétés comme V1.

## 5. Architecture de l'export

### Parcours

1. Dans Paramètres, l'utilisateur choisit **Sauvegarder l'inventaire**.
2. Avant le sélecteur, l'application indique que le fichier contiendra biens, emplacements, catégories, valeurs et historique des retraits, qu'il sera lisible sans mot de passe, et qu'un fournisseur externe peut le copier ou le synchroniser.
3. L'utilisateur choisit une destination avec le sélecteur de documents Android (Storage Access Framework), sans permission générale de stockage.
4. Si l'utilisateur annule, l'opération s'arrête sans créer de sauvegarde déclarée réussie.
5. Inventory acquiert un instantané cohérent des tables métier au moyen d'une transaction de lecture SQLite unique. Les écritures concurrentes sont sérialisées de façon à ce que tous les tableaux reflètent le même état logique.
6. Inventory sérialise cet instantané dans un fichier temporaire privé, calcule sa longueur et son SHA-256, puis écrit l'en-tête.
7. Inventory vérifie le fichier temporaire (en-tête, longueur, empreinte et structure minimale) avant transfert.
8. L'application copie le fichier vers la destination sélectionnée et ferme le flux. Si le fournisseur le permet, elle rouvre le document et vérifie longueur, checksum et format.
9. L'application présente l'un des états suivants :
   - **Export vérifié** : le flux est fermé sans erreur et le document relu correspond au fichier temporaire vérifié.
   - **Export écrit, mais non vérifiable** : le fichier temporaire Inventory était valide, tous les octets ont été transmis et le flux s'est fermé sans erreur, mais le fournisseur ne permet pas une relecture. L'application indique explicitement que le contenu distant n'a pas été vérifié ; elle ne qualifie pas le document de sauvegarde vérifiée.
   - **Export échoué** : l'écriture ou la fermeture a signalé une erreur, ou le document relu ne correspond pas au fichier attendu. Un document partiel peut subsister.
   - **Export annulé** : l'utilisateur a annulé avant la sélection ou pendant une opération annulable ; aucune réussite n'est annoncée.

La sauvegarde reflète l'instantané au début de la lecture, même si l'utilisateur reprend ensuite ses modifications. Elle est complète et contient également les biens retirés.

### Cohérence SQLite et interruptions

Ne pas copier directement le fichier SQLite actif. Avec WAL ou un autre mode journal, le fichier principal seul peut ne pas représenter l'état validé ; le mode de journalisation courant reste une responsabilité de SQLite.

Une transaction de lecture couvre toutes les tables exportées et fournit une vue cohérente. L'export est préparé dans un fichier temporaire sous le stockage privé d'Inventory, puis transféré vers l'URI sélectionnée. L'export ne modifie pas l'inventaire actif.

Une interruption avant transfert laisse l'inventaire intact ; le fichier temporaire incomplet est ignoré et nettoyé au prochain démarrage. Une interruption pendant le transfert peut laisser un document partiel chez le fournisseur. Inventory ne promet ni sa suppression ni son remplacement atomique : il ne présente jamais ce document comme réussi et informe l'utilisateur que le fichier peut être incomplet. L'encadrement longueur/empreinte garantit qu'une troncature ne sera pas importée comme fichier valide.

La destination peut devenir indisponible ou manquer d'espace. Une erreur de flux/fermeture ou une différence constatée à la relecture est un échec explicite, sans succès suggéré. Si le fournisseur ne permet pas de relecture, l'état « écrit, mais non vérifiable » est accepté en V1 : exiger une relecture exclurait des fournisseurs sans garantie que le SAF la fournisse pour chaque URI. L'application ne doit toutefois pas appeler ce fichier « vérifié » ni affirmer qu'il a été conservé durablement par le fournisseur. Ne pas promettre un comportement atomique des fournisseurs Android.

Pendant l'export, désactiver la soumission répétée. En cas d'espace privé insuffisant pour la préparation, arrêter avant de déclarer l'export ; supprimer les temporaires appartenant à l'opération et laisser les données métier inchangées.

## 6. Architecture de la restauration

### Parcours de bout en bout

1. Dans Paramètres, l'utilisateur choisit **Restaurer une sauvegarde** et sélectionne un fichier avec le sélecteur Android.
2. Inventory ouvre l'URI explicitement choisie, copie le flux vers un temporaire privé sous une limite stricte de taille et ferme le flux.
3. Inventory vérifie le format magique, l'en-tête, les versions reconnues, la longueur, le checksum et l'absence de données après le payload.
4. Le payload est décodé en respectant les limites de mémoire, de structure et de nombre de nœuds.
5. Inventory crée une base SQLite temporaire privée avec le schéma courant et charge les données candidate. Les migrations Drift de la version courante servent uniquement à créer/mettre à niveau ce schéma temporaire ; elles ne rendent pas compatibles automatiquement des formats de sauvegarde arbitraires.
6. Les contrôles SQLite et métier de la section 8 sont exécutés sur cette base isolée.
7. Seulement après validation complète, l'application avertit l'utilisateur que la restauration remplacera **tout** l'inventaire actif et demande une confirmation explicite.
8. Annuler laisse l'inventaire actif inchangé et supprime les temporaires de l'opération.
9. Après confirmation, l'application met en pause les écritures métier, ouvre la transaction de remplacement décrite à la section 7 et remplace l'inventaire entier.
10. Après commit confirmé et vérifications prévues, l'application rafraîchit l'interface et annonce la réussite.

Un fichier invalide, incompatible, corrompu, trop volumineux ou illisible est refusé avant la confirmation de remplacement. L'inventaire actif n'est jamais modifié pour ces cas.

### Migration des données

Les données d'une sauvegarde sont d'abord converties par un adaptateur explicite de `data_schema_version` vers le modèle métier courant. Les anciennes versions ne sont prises en charge que si leur format, leurs champs et leur transformation sont documentés et testés. Ne pas ouvrir une sauvegarde JSON comme si elle était une base SQLite ni exécuter des migrations sur des données non validées.

Les migrations existantes Drift peuvent créer le schéma courant de la base temporaire. Si une ancienne version de sauvegarde est prise en charge, son adaptateur transforme ses données en enregistrements courants avant insertion dans ce schéma ; il n'y a pas de migration SQLite ancienne-vers-courante embarquée dans le fichier JSON.

## 7. Remplacement atomique et récupération

### 7.1 Stratégie retenue

Ne pas remplacer ou renommer le fichier actif SQLite. Ne pas considérer un renommage ou une copie de fichiers comme une garantie d'atomicité multiplateforme.

Après validation en base temporaire, remplacer les lignes métier dans **une seule transaction SQLite sur la base active** :

1. Mettre l'application en mode restauration : bloquer les nouvelles écritures et éviter les lectures d'écran qui supposeraient un état stable ; terminer/attendre toute opération déjà commencée.
2. Inscrire un journal de restauration technique `pending` dans une table interne à la base active, par une transaction courte séparée. Cette table contient au plus un identifiant d'opération aléatoire, un état (`pending`/`committed`) et un horodatage technique ; elle ne contient aucune donnée utilisateur.
3. Démarrer la transaction de remplacement.
4. Supprimer les anciennes associations `node_categories`, supprimer les anciens nœuds dans un ordre enfant-avant-parent, puis les catégories et l'ancienne ligne d'inventaire. Ne pas utiliser de cascade sur les nœuds.
5. Insérer l'inventaire et les catégories, puis les nœuds parent-avant-enfant, puis les associations.
6. Exécuter les vérifications de références, de clés étrangères et les invariants métier dans cette transaction. Toutes les opérations Drift dans la transaction sont attendues ; une erreur est propagée afin que la transaction soit annulée, et aucune opération non attendue ne doit continuer après la fin du callback.
7. Marquer le journal de restauration `committed` dans **la même transaction** que le nouvel inventaire.
8. Committer une seule fois.
9. Une fois la transaction terminée, relire le journal et vérifier l'identité de l'inventaire ainsi que les comptes et invariants attendus. Rafraîchir les requêtes Drift et l'interface seulement après confirmation de l'état durable. Supprimer le temporaire de l'opération et présenter le résultat.

Le journal de restauration est une métadonnée opérationnelle interne, **non exportée** et non visible dans le modèle métier. Son ajout au schéma Drift est nécessaire pour reconnaître après redémarrage si le commit de remplacement a été achevé. Il ne change pas les entités métier de la section 2 ni l'unique inventaire.

La transaction de remplacement doit être protégée par la transaction SQLite native et son mécanisme de journalisation courant (rollback journal ou WAL). Une transaction SQLite donne l'atomicité logique : après récupération, ses changements sont tous validés ou aucun ne l'est, sous les hypothèses du VFS, du système de fichiers et du matériel documentées par SQLite. Drift fournit le regroupement transactionnel, mais ne choisit pas à lui seul un mode de durabilité ; toutes les requêtes doivent être attendues et l'échec doit sortir du callback.

Configurer `PRAGMA synchronous=FULL` sur la connexion SQLite qui effectue le remplacement et vérifier la valeur effective sur cette connexion. Il s'agit d'une demande de synchronisation avant confirmation du commit, pas d'une garantie absolue de durabilité. En mode rollback journal, SQLite synchronise le journal avant d'écrire les pages modifiées, puis synchronise le fichier de base au commit ; en mode WAL, `FULL` synchronise le WAL à chaque commit, tandis que `NORMAL` reporte la synchronisation principalement au checkpoint et peut perdre des transactions récemment commitées lors d'une coupure sans nécessairement corrompre la base. En WAL, les lecteurs peuvent continuer à voir leur ancien instantané pendant que le commit est inscrit au WAL ; la transaction devient visible aux nouvelles lectures après son commit, même si les pages n'ont pas encore été reportées dans le fichier principal. Le WAL et son index font partie de l'état de la base : aucune copie directe du seul fichier principal et aucune suppression manuelle des fichiers `-wal`, `-shm` ou de journal ne sont permises. `FULL` ne peut pas corriger un stockage qui ne respecte pas les synchronisations ou une panne matérielle.

Drift doit être configuré et testé afin que les connexions réutilisées pour cette opération gardent ce réglage ; ne pas supposer qu'un pragma appliqué à une connexion s'applique automatiquement à chaque autre connexion ou qu'une erreur de configuration sera signalée. Ne pas changer arbitrairement le mode journal global.

### 7.2 Cycle de vie du journal et reprise au démarrage

Le journal comporte au plus une ligne et n'utilise que `pending` et `committed`. `pending` est commité avant le remplacement ; `committed` est écrit dans la même transaction SQLite que les nouvelles données. Le journal sert à identifier l'issue de l'opération après récupération ; il ne remplace ni le rollback, ni la récupération du journal/WAL SQLite.

| Moment / état constaté après récupération | Journal durable | Données métier attendues | Vérification requise | Action de récupération | Comportement utilisateur | Garantie |
| --- | --- | --- | --- | --- | --- | --- |
| Avant création de `pending` | Aucun | Ancien inventaire | Ouverture et contrôles ordinaires | Aucune restauration n'a commencé ; autoriser une nouvelle demande. | Aucun message de récupération. | Conception ; aucun changement métier commencé. |
| Après commit de `pending`, avant le remplacement | `pending` | Ancien inventaire | Intégrité, clés étrangères et invariants de l'ancien inventaire | Présenter la non-application ; garder le marqueur jusqu'à acquittement, puis le supprimer dans une transaction courte. | « La restauration n'a pas été appliquée. Votre inventaire précédent est conservé. » | Atomicité SQLite par conception ; redémarrage réel à tester. |
| Pendant la transaction de remplacement, avant commit | `pending` après rollback/récupération | Ancien inventaire complet | Récupération SQLite, puis intégrité, références et invariants | Ne pas reprendre la transaction interrompue ; présenter l'échec, puis nettoyer `pending` seulement après acquittement. | Même message que ci-dessus. | Atomicité définie par SQLite sous ses hypothèses ; interruption Android à démontrer. |
| Pendant le commit, résultat d'appel incertain | `pending` ou `committed` après récupération | Ancien inventaire si `pending` ; nouvel inventaire si `committed` | Rouvrir après récupération SQLite ; lire le journal, puis vérifier intégrité, références, invariants et identité/comptes attendus | Ne pas déduire l'échec du seul retour d'erreur. Traiter le journal durable ; si la base ne peut pas être vérifiée, bloquer et préserver les fichiers. | Ancien conservé ou nouvelle restauration terminée selon le marqueur ; sinon erreur de récupération sans résultat annoncé. | Décision par conception ; résultat de durabilité à démontrer sur Android. |
| Après commit confirmé, avant affichage du succès | `committed` | Nouvel inventaire complet | Vérifier le journal et les données restaurées avant chargement | Charger le nouvel inventaire, présenter la confirmation ; nettoyer le journal après acquittement. | « La restauration a été effectuée. » | Atomicité SQLite ; redémarrage et durabilité à démontrer. |
| Après commit, avant nettoyage du journal | `committed` | Nouvel inventaire complet | Vérifications comme ci-dessus | Répéter la confirmation au démarrage ; ne pas réexécuter la restauration ; nettoyer après acquittement. | Confirmation de restauration effectuée. | Conception pour l'idempotence de la reprise ; durabilité à démontrer. |
| Pendant le nettoyage du journal | `pending`, `committed` ou aucun, selon l'état acquitté et le commit du nettoyage | Ancien ou nouvel inventaire, conformément à l'état acquitté | Si un marqueur subsiste, vérifier l'état associé et reproposer l'acquittement ; s'il est absent, vérifier l'inventaire actif | Le nettoyage ne touche jamais aux données métier ; autoriser une nouvelle restauration uniquement si l'issue est vérifiée et le journal absent. | Répéter le message déjà présenté si le marqueur subsiste ; sinon ouverture normale. | Transaction du nettoyage ; persistance système à démontrer. |
| Redémarrage avec `pending` | `pending` | Ancien inventaire attendu | Laisser SQLite récupérer, puis vérifier l'ancien inventaire ; tout échec rend l'état non fiable | Signaler la non-application ; nettoyer après acquittement. Interdire une nouvelle restauration jusque-là. | Message de conservation de l'inventaire précédent. | Conception conditionnelle à récupération SQLite vérifiable. |
| Redémarrage avec `committed` | `committed` | Nouvel inventaire attendu | Vérifier intégrité, références, invariants et identité/comptes | Charger sans rejouer ; nettoyer après acquittement. Interdire une nouvelle restauration jusque-là. | Message de restauration achevée. | Conception conditionnelle à récupération SQLite vérifiable. |
| Redémarrage avec base illisible, journal incohérent ou contrôles échoués | Inconnu ou illisible | Indéterminé ; ne pas présumer ancien ni nouveau | Diagnostic en lecture seule autant que possible ; aucune initialisation automatique | Préserver base, fichiers auxiliaires, journal et temporaires ; bloquer les écritures et demander une récupération contrôlée depuis une sauvegarde valide. Ne pas effacer le marqueur. | Dire que l'inventaire n'a pas pu être vérifié ; ne pas afficher un inventaire vide ni un succès. | Limite à démontrer ; aucune garantie de récupération si le support est corrompu. |

Une erreur de `COMMIT` n'implique pas systématiquement un rollback : par exemple, SQLite documente qu'un `SQLITE_BUSY` au commit peut laisser la transaction active. Si l'implémentation confirme ce code et l'état actif, le commit peut être retenté après libération du lecteur bloquant ou la transaction explicitement annulée ; ne pas relancer à l'aveugle un commit dont le résultat est incertain. Une erreur de disque ou d'E/S peut aussi avoir entraîné un rollback automatique ou non. L'opération ne doit alors ni lancer une autre restauration ni permettre des écritures métier. Attendre la fin/annulation contrôlée de la transaction Drift, fermer ou réinitialiser proprement la connexion si nécessaire, rouvrir la base pour laisser SQLite récupérer, puis décider à partir du journal. Si l'état n'est pas lisible et vérifiable, conserver les données et le marqueur sans afficher de résultat.

Si l'écriture initiale de `pending` retourne un résultat incertain, ne pas commencer la transaction de remplacement. Rouvrir la base après récupération : si la ligne est absente, l'ancien inventaire n'a pas été touché et l'opération peut être abandonnée ; si `pending` est présent, appliquer la procédure de reprise et d'acquittement. `committed` ne peut pas être produit à cette étape, puisque le remplacement n'a pas commencé.

Une nouvelle restauration est interdite dès qu'un journal antérieur existe, jusqu'à la vérification de son état, l'information de l'utilisateur et l'acquittement qui autorise la suppression du journal. Un échec du nettoyage laisse le marqueur et bloque une nouvelle restauration ; la reprise répète les vérifications et l'acquittement. L'acquittement précède le nettoyage afin qu'une interruption avant confirmation ne fasse pas perdre l'information à présenter.

Les fichiers temporaires portent un identifiant d'opération interne et vivent uniquement dans un répertoire privé dédié. Au démarrage, nettoyer uniquement les temporaires Inventory connus et non utilisés par une opération active, après résolution du journal. Ne jamais supprimer à l'aveugle la base ou ses fichiers SQLite auxiliaires.

### 7.3 Trois garanties distinctes et limites

1. **Atomicité transactionnelle SQLite :** les lecteurs extérieurs à la transaction voient l'ancien état jusqu'au commit et le nouvel état après le commit ; ils ne voient pas un remplacement partiel. Une interruption avant commit est récupérée comme rollback, sous les hypothèses SQLite. Les erreurs doivent être propagées et l'issue d'un commit incertain doit être résolue après récupération, au moyen du journal. En WAL, une connexion déjà engagée dans un instantané de lecture peut conserver cet ancien instantané jusqu'à la fin de sa transaction ; l'application bloque les lectures métier concurrentes et rafraîchit Drift après commit.
2. **Atomicité des fichiers exportés :** elle n'est pas garantie par l'interface générique d'un fournisseur de documents Android. Un transfert interrompu peut laisser un fichier partiel ; longueur et checksum le font refuser, mais Inventory ne promet ni remplacement ni suppression atomique chez ce fournisseur.
3. **Durabilité après arrêt brutal/redémarrage :** `synchronous=FULL` demande à SQLite les synchronisations associées à la durabilité du commit dans le mode journal actif ; il ne protège pas contre un VFS, système de fichiers ou matériel qui ne respecte pas ces demandes. La récupération après arrêt du processus, redémarrage et coupure électrique doit être testée séparément sur les versions/appareils retenus. Aucune garantie absolue n'est revendiquée contre une panne matérielle, un stockage défectueux ou une corruption.

Cette stratégie évite une bascule de fichiers de base active et des fenêtres où celle-ci serait absente. Elle n'est pas une promesse absolue contre une défaillance matérielle ou une corruption qui viole les hypothèses SQLite/Android ; ce risque doit rester explicite.

## 8. Validation et compatibilité

La validation se fait d'abord sur le fichier puis sur une base temporaire, jamais directement sur la base active.

### Contrôles de fichier

- Séquence magique exacte et en-tête complet.
- `format_id`, versions, horodatage, longueur et checksum conformes.
- Taille et profondeur sous les limites ; UTF-8 strict ; un unique objet JSON payload ; aucune donnée finale supplémentaire.
- Tous les champs obligatoires présents avec le type attendu ; aucune clé JSON dupliquée.
- Version reconnue et compatible ; aucune interprétation permissive d'une version inconnue.

### Contrôles des données métier

Appliquer les invariants du document 04, en particulier :

- une seule ligne d'inventaire et identifiants UUID uniques ;
- références présentes, identifiants sans collision et aucune relation inter-inventaire ;
- parent existant, racines autorisées, parent capable de contenir, absence d'auto-parent et de cycle ;
- chemin actif atteignant un emplacement racine ;
- aucun enfant sous un bien simple ou un nœud retiré ; aucun nœud retiré ne sert de parent ;
- associations uniques vers une catégorie et un bien du même inventaire ;
- quantité entière positive pour les biens et absence de quantité pour les autres types ;
- valeurs exactes et mode exclusif : valeur financière en cents seule ou note sentimentale 1–5 seule ; valeurs absentes sur les nœuds non valorisables ;
- statut actif sans motif/date de retrait ; statut retiré avec type de bien, motif autorisé et date ;
- absence de champs ou de données partielles qui rendraient impossible une restauration fidèle.

### Vérifications SQLite temporaire

- Charger toutes les lignes dans une base créée avec le schéma courant et les contraintes activées.
- Exécuter `PRAGMA integrity_check` et exiger le résultat `ok`.
- Exécuter `PRAGMA foreign_key_check` et exiger zéro ligne de violation.
- Exécuter les validations métier inter-lignes et vérifier les comptes attendus pour toutes les tables importées.
- Refuser l'activation si une vérification échoue ; conserver la base active intacte.

Des migrations Drift existantes peuvent être utilisées pour créer le schéma temporaire courant. Elles ne constituent pas une preuve de compatibilité de sauvegarde : chaque version de payload antérieure acceptée exige un adaptateur explicite, puis l'ensemble des contrôles ci-dessus.

## 9. Sécurité et confidentialité

- Une sauvegarde est déclenchée volontairement, complète et écrite uniquement à l'URI choisie par l'utilisateur.
- Le fichier n'est pas chiffré et est lisible par toute personne ayant accès au fichier. Le pré-export doit en avertir clairement l'utilisateur.
- Aucun mot de passe, chiffrement, authentification, biométrie ou service de clés n'est ajouté.
- Le fournisseur choisi dans le sélecteur peut synchroniser ou transférer le fichier ; Inventory ne transmet rien de son côté et ne contrôle pas les pratiques du fournisseur.
- Le Storage Access Framework est utilisé pour choisir une destination et une source, sans permission générale de stockage.
- Le temporaire d'import ou d'export est conservé uniquement dans le stockage privé de l'application et supprimé après succès, annulation ou échec contrôlé.
- L'import est non fiable : validation stricte, limite de taille, absence de compression et aucune extraction de chemin d'archive.
- Aucun nom de possession, chemin, valeur, payload, URI sensible ou exception SQL détaillée n'est inscrit dans les journaux.
- L'échec d'une restauration ne déclenche jamais une initialisation d'inventaire vide ni un effacement de la base.

### Exclusion de la sauvegarde Android système (D09-01)

La configuration dépend à la fois de l'API de l'appareil et du `targetSdkVersion`. Les versions minimale et cible d'Inventory n'étant pas fixées ici, cette matrice est conditionnelle ; elles devront être arrêtées avant de choisir la configuration de production.

| Appareil / condition de cible | Configuration exigée | Mécanisme concerné | Résultat attendu | Vérification sur appareil | Limite non contrôlable |
| --- | --- | --- | --- | --- | --- |
| Android API 23–30 (Android 6 à 11), tous niveaux de cible | Règles historiques `fullBackupContent` excluant les domaines contenant les données Inventory ; appliquer aussi `android:allowBackup="false"` comme défense supplémentaire. | Auto Backup/cloud et transfert direct si disponible par la plateforme | Aucune donnée Inventory restaurée depuis une sauvegarde système ou transférée. | Inspecter manifeste fusionné/règles et exécuter les flux de sauvegarde/restauration applicables sur API 30 et la version minimale retenue. | Les mécanismes propriétaires non fondés sur Auto Backup peuvent ignorer les règles Android. |
| Android API 31+ lorsque `targetSdkVersion` est inférieur à 31 | Les règles `fullBackupContent` sont utilisées ; garder les domaines Inventory exclus et `allowBackup=false`. | Cloud et transfert direct selon le comportement de la version cible et de l'appareil | Aucune donnée Inventory transférée par les règles de sauvegarde Android. | Tester cloud et transfert direct sur un appareil API 31+ utilisant une construction dont le target est celui retenu. | `allowBackup=false` n'est pas à lui seul une preuve d'exclusion D2D sur certains fabricants. |
| Android API 31+ avec `targetSdkVersion` 31 ou plus | Fournir **les deux** règles : `fullBackupContent` pour les appareils API 30 et antérieurs, et `dataExtractionRules` pour Android 12+ ; dans cette dernière, exclure les données Inventory de `cloud-backup` et `device-transfer`. | Auto Backup cloud et transfert direct d'appareil | Exclusion dans les deux canaux et sur les deux plages d'API applicables. | Inspecter les deux ressources et tester séparément API ≤30 et API ≥31 avec la construction cible. | Les comportements OEM hors contrat Android restent hors contrôle. |
| Android 16 QPR2 ou ultérieur, seulement si le transfert interplateforme s'applique à la construction et à la plateforme retenues | Ajouter l'exclusion dédiée au transfert interplateforme selon le schéma `dataExtractionRules` alors en vigueur ; ne pas supposer que les règles cloud/D2D couvrent ce canal. | Transfert interplateforme Android | Aucune donnée Inventory exportée par ce canal système. | Tester le flux si disponible pour les appareils et versions réellement pris en charge ; vérifier les règles de construction. | Disponibilité du mécanisme et outils de migration peuvent dépendre de la plateforme/fabricant. |
| Toute version avec outil de migration propre au fabricant | Aucune garantie générale ne peut être déduite des seules règles Auto Backup ; tester les outils OEM retenus et documenter leur résultat. | Assistant de migration fabricant ou transfert hors contrat Android | Exclusion recherchée ; déclarer explicitement tout canal qui ne peut être contrôlé ou vérifié. | Essai sur chaque famille d'appareils incluse dans la validation produit. | Inventory ne peut pas garantir le comportement d'un outil tiers/fabricant qui ignore les règles système. |

`android:allowBackup="false"` est une défense supplémentaire, pas le mécanisme de preuve : la documentation Android signale qu'à partir d'Android 12 certains fabricants peuvent le respecter pour le cloud sans bloquer le transfert direct. Les règles XML doivent exclure explicitement les domaines utilisés (base, fichiers, préférences et stockage protégé par appareil seulement s'il est utilisé) et rester cohérentes. Si `minSdkVersion` est inférieur à 23, Auto Backup ne s'applique pas aux API inférieures à 23, mais tout canal OEM ou outil tiers reste à considérer séparément.

Ne pas déclarer D09-01 vérifiée sur la seule inspection de `allowBackup` : la version minimale, le `targetSdkVersion`, le manifeste fusionné, les ressources effectivement empaquetées et les flux de transfert disponibles sont des données de l'implémentation à confirmer.

L'exclusion de la sauvegarde automatique Android n'interdit pas l'export volontaire d'un fichier vers un fournisseur que l'utilisateur choisit ; cet export reste distinct et explicitement initié.

## 10. Parcours et états UX

Les messages restent compréhensibles sans jargon, n'exposent ni chemins internes ni SQL et ne présentent jamais un échec comme une réussite.

### Export

| État | Information/action |
| --- | --- |
| Information avant export | Contenu complet, présence de l'historique retiré, absence de chiffrement et sensibilité ; le fournisseur choisi peut copier ou synchroniser le fichier. |
| Sélection de destination | Sélecteur Android ; l'annulation ne modifie rien. |
| Export en cours | Indiquer la progression si possible et désactiver les déclenchements répétés. |
| Export vérifié | Confirmer après fermeture et relecture conforme ; fournir le nom de fichier et l'emplacement connu du fournisseur si disponible. |
| Export écrit, mais non vérifiable | Dire que l'écriture et la fermeture n'ont pas signalé d'erreur, mais que le fournisseur n'a pas permis de vérifier le contenu distant. Ne pas présenter le fichier comme vérifié ni garanti conservé. |
| Export échoué | Dire que l'écriture ou la vérification a échoué ; signaler qu'un fichier partiel peut subsister et qu'Inventory ne peut pas toujours le supprimer. |
| Export annulé | Aucun message de réussite ; revenir au parcours précédent. |

### Restauration

| État | Information/action |
| --- | --- |
| Sélection | Sélecteur de document ; aucun accès général au stockage. |
| Validation en cours | Indiquer que l'inventaire courant n'est pas encore modifié. |
| Fichier invalide/incompatible | Refuser et expliquer que l'inventaire actuel est conservé. |
| Confirmation | Après validation, avertir que tout l'inventaire actif sera remplacé ; proposer confirmer ou annuler. |
| Restauration en cours | Bloquer les actions concurrentes et montrer la progression, sans détail SQL. |
| Restauration réussie | Présenter le nouvel inventaire après commit vérifié. |
| Récupération après interruption | Au démarrage, annoncer soit que l'ancienne restauration n'a pas été appliquée et que les données existantes sont conservées, soit que la restauration complète a été achevée. |
| Base non fiable | Ne pas afficher un inventaire vide ; expliquer que l'ouverture a échoué et que les données n'ont pas été réinitialisées. |

## 11. Gestion des erreurs

| Échec | Comportement obligatoire |
| --- | --- |
| Sélecteur annulé | Arrêt sans modification et sans message de succès. |
| URI illisible ou fournisseur indisponible | Erreur explicite ; réessai possible ; aucune donnée active touchée. |
| Format/version/checksum/longueur invalide | Refus avant confirmation de remplacement ; base active inchangée. |
| Fichier dépassant les limites ou manque d'espace temporaire | Arrêt contrôlé et message indiquant que la restauration n'a pas été faite. |
| Validation métier/SQLite échouée | Détruire seulement la base temporaire fautive après diagnostic local utile ; préserver la base active. |
| Échec dans la transaction active avant commit | Laisser Drift terminer le rollback de la transaction ; garder `pending` jusqu'à vérification et acquittement ; l'ancien inventaire est attendu, mais doit être vérifié après une erreur de stockage. |
| Résultat du commit incertain | Ne pas annoncer un résultat et ne pas démarrer une autre restauration ; terminer/récupérer la transaction, rouvrir la base et décider à partir du journal. Un résultat impossible à vérifier bloque les écritures et préserve les fichiers. |
| Export interrompu ou destination pleine | Aucun succès ; l'inventaire actif reste inchangé ; un fichier distant partiel peut exister. |
| SQLite impossible à ouvrir ou contrôle d'intégrité invalide au démarrage | Ne pas créer une base vide et ne pas supprimer la base ; bloquer l'accès aux écritures et expliquer la nécessité d'une récupération. |

Les erreurs techniques détaillées sont conservées uniquement dans le contexte local nécessaire au diagnostic, sans contenu métier. Ne pas supprimer automatiquement les sauvegardes externes ni promettre le nettoyage d'un URI contrôlé par un autre fournisseur.

## 12. Scénarios de validation Android

Les résultats doivent être constatés sur un véritable appareil Android. Les tests automatisés d'intégrité, de format et de transactions complètent l'observation utilisateur sans s'y substituer.

1. **Sauvegarde complète d'un inventaire non vide :** créer emplacements, contenants imbriqués, biens actifs et catégories ; exporter et vérifier que le fichier est réouvrable.
2. **Hiérarchie :** restaurer et vérifier chaque parent, chemin complet et descendant d'un contenant imbriqué.
3. **Catégories et quantités :** restaurer plusieurs associations, quantités supérieures à 1 et l'absence de doublons.
4. **Valorisations :** restaurer des biens financiers (dont 0 et un lot) et sentimentaux ; vérifier exclusivité, valeur exacte et total calculé.
5. **Historique :** restaurer des biens retirés avec motif/date et vérifier leur présence dans Historique, absents de l'inventaire actif.
6. **Fichier invalide :** sélectionner un fichier texte arbitraire, un JSON malformé et une sauvegarde dont un octet du payload a été modifié ; chacun est refusé, l'inventaire actif de référence reste présent.
7. **Fichier incompatible :** modifier en environnement de test la version du format ou du schéma ; l'application refuse sans remplacement.
8. **Annulation :** sélectionner une sauvegarde valide, attendre la validation, annuler à la confirmation ; vérifier que l'inventaire existant demeure identique.
9. **Destination indisponible :** choisir un fournisseur de documents de test, le déconnecter ou révoquer son accès durant l'export ; aucune réussite n'est annoncée.
10. **Espace insuffisant :** utiliser un fournisseur ou environnement contrôlé qui refuse l'écriture faute de place ; vérifier l'erreur et l'absence de succès, sans exiger la suppression du fichier partiel.
11. **Interruption pendant l'export :** en environnement de validation, arrêter le processus pendant la copie vers une destination ; l'inventaire reste intact et le fichier partiel est refusé à l'import.
12. **Interruption pendant la validation :** arrêter le processus durant le décodage ou la validation d'un fichier volumineux ; au redémarrage, l'inventaire original s'ouvre et le temporaire orphelin est nettoyé.
13. **Interruption avant commit :** déclencher dans une version de test contrôlée un arrêt du processus après écriture de `pending`, puis à plusieurs points de la transaction avant commit ; au redémarrage, SQLite récupère l'ancien inventaire et l'application signale que la restauration n'a pas été appliquée.
14. **Issue de commit incertaine :** interrompre le processus à la frontière commit/retour applicatif (par exemple après le commit SQLite mais avant l'accusé applicatif) et répéter des essais autour de cette frontière ; au redémarrage, accepter `pending` ou `committed` seulement après récupération SQLite, vérifier les données correspondantes et ne jamais inférer un rollback du seul résultat d'appel. Cette méthode teste l'issue incertaine pour l'application ; elle ne simule pas une panne physique.
15. **Commit achevé avant confirmation UI :** interrompre le processus après le commit mais avant le message de succès ; au redémarrage, l'inventaire restauré est complet et le reçu `committed` déclenche une confirmation, sans duplication de données.
16. **Redémarrage forcé :** répéter l'interruption avec fermeture forcée du processus ; pour un essai de coupure d'alimentation, utiliser uniquement un appareil de validation et documenter modèle/version Android, mode journal et résultat. Une coupure physique n'est pas simulée par un simple test de processus.
17. **Hors ligne :** activer le mode avion, exporter vers un fournisseur local disponible et restaurer ; toutes les fonctions Inventory marchent sans réseau. Si un fournisseur choisi dépend du réseau, l'application l'indique comme indisponible sans prétendre que l'opération locale a réussi.
18. **Exclusion Android automatique :** vérifier le manifeste fusionné et les règles avec les valeurs `minSdkVersion`/`targetSdkVersion` de production. Tester API 30 et antérieures ainsi qu'API 31+ si elles sont prises en charge, les flux cloud et D2D séparément, et tout transfert interplateforme applicable.

Les interruptions sont provoquées avec une version de validation et un point d'arrêt de test contrôlé, ou par fermeture forcée via les outils Android. Ne jamais utiliser un inventaire personnel irremplaçable pour tester une interruption ou une corruption.

## 13. Critères d'acceptation

Le système est acceptable si :

- un seul format versionné est produit et reconnu ;
- un export inclut toutes les données métier et un instantané SQLite cohérent ;
- un fichier tronqué, altéré, trop volumineux ou de version inconnue est refusé ;
- un document relu n'est appelé « export vérifié » qu'après concordance ; un fournisseur ne permettant pas la relecture peut produire l'état distinct « écrit, mais non vérifiable », sans garantie de contenu ou de conservation distante ;
- aucune permission générale de stockage n'est nécessaire ;
- les données métier ne sont pas incluses dans Auto Backup, transfert direct ou tout canal de sauvegarde Android ciblé par la configuration ;
- la restauration est intégralement validée dans un environnement temporaire avant la confirmation et avant toute modification active ;
- l'inventaire existant est remplacé seulement après confirmation explicite ;
- un remplacement est réalisé dans une transaction SQLite unique, pas par échange non garanti des fichiers de base ;
- le marqueur opérationnel, lu après récupération SQLite, permet de déterminer l'issue de la transaction ; une base illisible ou incohérente n'est jamais réinitialisée ;
- un échec n'entraîne ni base vide, ni données partiellement restaurées, ni message de succès trompeur ;
- aucun chiffrement, authentification, transfert distant ou mécanisme incrémental n'est ajouté.

Les garanties liées à SQLite après arrêt brutal doivent être vérifiées avec le mode journal, `synchronous=FULL` et les versions Android réellement retenues. Une garantie absolue contre une panne matérielle ou un système de fichiers défaillant n'est pas revendiquée.

## 14. Décisions confirmées, recommandations et risques résiduels

### Décisions confirmées

- D09-01 : exclusion des données Inventory de la sauvegarde automatique Android, y compris le transfert d'appareil.
- D09-02 : aucun chiffrement supplémentaire, mot de passe ou clé Inventory.
- D09-03 : une sauvegarde complète, incluant l'historique des biens retirés.
- D09-04 : restauration par remplacement complet, sans fusion.
- D09-05 : protection bloquante de l'inventaire existant contre fichier invalide ou restauration interrompue.
- Application locale, Android, Drift/SQLite, export volontaire et accès aux fichiers via sélection explicite.

### Décisions techniques recommandées par ce document

- Format `.invbackup` : encadrement simple avec en-tête versionné et SHA-256 d'un payload JSON UTF-8 non compressé.
- Limites initiales : 32 Mio, en-tête 4 Kio, 100 000 nœuds ; à vérifier sur l'appareil Android cible.
- Export depuis une transaction de lecture cohérente vers un temporaire privé, puis transfert vers le document choisi et vérification.
- Restauration à partir d'une base temporaire avec schéma courant, puis remplacement des lignes dans une unique transaction de la base active.
- Petit journal opérationnel interne `pending`/`committed`, non exporté, pour distinguer au démarrage rollback de transaction et commit terminé avant interruption de l'interface.
- Configuration Android selon API et `targetSdkVersion` : règles `fullBackupContent` pour Android 11 et antérieurs, et, pour une cible 31+, règles `dataExtractionRules` séparant `cloud-backup` et `device-transfer`, plus toute règle dédiée à un canal ultérieur effectivement pris en charge. `allowBackup=false` seul ne prouve pas l'exclusion.
- Un fournisseur SAF qui n'autorise pas la relecture peut aboutir à l'état distinct « écrit, mais non vérifiable » ; l'utilisateur n'est pas contraint à un autre fournisseur et aucune validité distante n'est affirmée.

### Cohérence documentaire et arbitrages

- Le [document 03](03-technical-architecture.md), section 5, exige déjà une validation séparée et un remplacement complet ; le présent document précise ces opérations.
- Le [document 04](04-data-domain-model.md), section 9, prévoit la sauvegarde des tables métier et une validation avant remplacement ; le format et les contrôles sont maintenant détaillés.
- Le [document 06](06-ux-ui.md), section 11, décrit l'avertissement de remplacement et les erreurs ; le présent document précise les états et le résultat après interruption.
- Le [document 07](07-security-privacy.md), sections 4, 8 et 14, conservait des recommandations/points ouverts sur la sauvegarde système et le chiffrement ; la présente consolidation les aligne sur D09-01, D09-02 et la décision d'absence de verrouillage/chiffrement SQLite en V1.
- Aucun autre conflit bloquant n'a été relevé.

### Risques résiduels

- Le fichier exporté est lisible sans chiffrement et peut être copié ou synchronisé par le fournisseur choisi.
- Le contrôle SHA-256 détecte une corruption accidentelle, pas une falsification volontaire.
- L'atomicité fichier d'un fournisseur Android n'est pas garantie. Un document non relisible n'est que « écrit, mais non vérifiable » ; la fermeture sans erreur ne prouve ni le contenu après écriture ni sa conservation durable par le fournisseur.
- La durabilité d'un commit après une coupure d'alimentation dépend du respect des garanties SQLite par le système de fichiers et le matériel ; cette hypothèse doit être testée.
- Une corruption matérielle ou un appareil compromis peut dépasser les protections de V1.

## 15. Classification des garanties

Cette classification distingue les propriétés prévues par le contrat des résultats qui nécessitent une preuve d'exécution. Une exigence écrite n'est pas, à elle seule, une garantie démontrée sur un appareil.

### A. Garanties définies par conception

- Une sauvegarde incompatible, malformée ou invalide est refusée avant modification active.
- La restauration est validée dans un environnement temporaire avant confirmation et activation.
- Le remplacement métier s'effectue dans une seule transaction SQLite ; aucune restauration partielle n'est volontairement rendue visible.
- Le marqueur `committed` et le nouvel inventaire sont écrits dans la même transaction ; après récupération SQLite, le marqueur distingue l'ancien état `pending` du nouvel état `committed`, sous les hypothèses SQLite.
- Le journal ne remplace pas le mécanisme de rollback/récupération SQLite ; il est conservé jusqu'à vérification et acquittement.
- L'import/export utilise des temporaires privés et aucune erreur n'est présentée comme une réussite.

### B. Garanties à démontrer lors de l'implémentation

- Le réglage effectif `synchronous=FULL` sur la connexion réelle de remplacement, le mode journal actif, le comportement Drift/SQLite au commit et le traitement des erreurs/transactions encore actives.
- La récupération correcte après arrêt forcé du processus et redémarrage, ainsi que l'issue à la frontière d'un commit incertain ; un essai de processus ne vaut pas preuve de coupure électrique.
- La durabilité en cas d'arrêt brutal sur les versions/appareils retenus et la conformité aux hypothèses de synchronisation du système de fichiers/matériel.
- Les règles réellement empaquetées pour la combinaison de `minSdkVersion`, `targetSdkVersion` et API ; les flux cloud, D2D et tout canal système ultérieur pris en charge.
- Les capacités réelles des fournisseurs SAF ciblés, notamment fermeture, relecture et erreurs d'écriture. Une relecture impossible doit aboutir à l'état qualifié défini à la section 5, pas à une affirmation de vérification.

### C. Risques résiduels acceptés

- Panne matérielle, corruption physique ou système de fichiers/VFS qui ne respecte pas les demandes de synchronisation SQLite.
- Copie volontaire d'un fichier `.invbackup` non chiffré, ainsi que copie, synchronisation ou perte de conservation sous le contrôle d'un fournisseur externe.
- Outil de migration propriétaire qui contourne ou ignore les règles Android ; les politiques des fabricants ne sont pas garanties universellement par Inventory.
- Falsification volontaire d'un payload accompagnée du recalcul de son SHA-256 ; l'empreinte n'est pas une signature ni une preuve d'origine.

## Références officielles

- [Auto Backup for Apps — règles par version, Android 11 et antérieurs, Android 12+ et transferts](https://developer.android.com/identity/data/autobackup)
- [Android — sauvegarde des données](https://developer.android.com/identity/data/backup)
- [Android — transferts interplateformes dans Auto Backup](https://developer.android.com/identity/data/autobackup#configure-cross-platform)
- [Storage Access Framework — création et ouverture de documents](https://developer.android.com/training/data-storage/shared/documents-files)
- [SQLite — transactions](https://www.sqlite.org/lang_transaction.html)
- [SQLite — atomic commit](https://www.sqlite.org/atomiccommit.html)
- [SQLite — write-ahead logging](https://www.sqlite.org/wal.html)
- [SQLite — PRAGMA synchronous](https://www.sqlite.org/pragma.html#pragma_synchronous)
- [Drift — transactions](https://drift.simonbinder.eu/dart_api/transactions/)
