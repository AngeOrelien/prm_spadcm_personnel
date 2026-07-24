# Notes d'intégration — retrait des mocks, persistance auth, bypass OTP, .env

Tu ne m'avais fourni que le dossier `lib/` (pas de `pubspec.yaml`, `android/`,
`ios/`...), donc voici ce qu'il faut faire toi-même à la racine de ton vrai
projet Flutter pour que tout fonctionne.

## 1. Copier les fichiers

- Remplace ton dossier `lib/` par celui fourni ici.
- Place `.env` et `.env.example` à la racine du projet (à côté de
  `pubspec.yaml`, **pas** dans `lib/`).

## 2. `pubspec.yaml` — ajouter la dépendance `flutter_dotenv`

```yaml
dependencies:
  flutter_dotenv: ^5.2.1

flutter:
  assets:
    - .env
```

Puis `flutter pub get`.

> ⚠️ Si `.env` contient un jour un vrai secret (clé API, etc.), ajoute-le à
> `.gitignore` et ne garde que `.env.example` versionné. Ici il ne contient
> que des URLs, donc pas de souci à le committer tel quel si tu veux, mais le
> réflexe est bon à prendre.

## 3. Basculer entre backend local et Vercel

Tout se passe dans `.env`, une seule ligne à changer :

```env
APP_ENV=local     # ou APP_ENV=vercel
```

- `local` → utilise `API_BASE_URL_LOCAL` (`http://localhost:4000/api`),
  pensé pour `adb reverse tcp:4000 tcp:4000` avec ton backend lancé en
  `npm run dev`.
- `vercel` → utilise `API_BASE_URL_VERCEL`
  (`https://prmspadcmbackend.vercel.app/api`).

Une surcharge ponctuelle reste possible sans toucher `.env` :
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000/api
```
(utile pour un appareil physique sur le même Wi-Fi, sans adb reverse).

## 4. Mocks retirés

Supprimés : `core/mock/mock_store.dart`, `core/config/app_config.dart`
(remplacé par `core/config/env_config.dart`, qui ne gère plus que
l'environnement réseau, plus le flag mock).

Nettoyés (tous les `if (AppConfig.useMockData) {...}` retirés, appels réels
au backend conservés tels quels) :
- `features/coordonnateur/data/datasources/coordonnateur_remote_datasource.dart`
- `features/administrateur/data/datasources/administrateur_remote_datasource.dart`
- `features/avs/data/datasources/avs_remote_datasource.dart`
- `features/medecin/data/datasources/medecin_remote_datasource.dart`

⚠️ Le rôle Médecin reste "à l'étude" côté backend (pas d'endpoints dédiés
confirmés) — les appels de `medecin_remote_datasource.dart` échoueront
proprement (`AppException`) tant que ces routes n'existent pas côté serveur.

## 5. Persistance de la session (déjà en place, non modifiée)

`AuthRepositoryImpl.restaurerSession()` lit le token depuis
`SecureStorageService` (flutter_secure_storage), puis appelle `GET /auth/me`
pour valider et récupérer le profil. Si le token est invalide/expiré et non
rafraîchissable, la session est effacée et l'utilisateur retombe sur
l'écran de login. `ApiClient` gère déjà le refresh automatique sur un 401.
Rien à changer ici — c'était déjà correct.

## 6. OTP commenté temporairement (login direct email + mot de passe)

Le flux à 2 facteurs (mot de passe → code OTP par email) est **conservé en
commentaire**, prêt à être réactivé. En attendant, la connexion se fait
directement via la route de test du backend `POST /api/auth/test/login`
(bypass OTP, montée uniquement si `NODE_ENV !== 'production'` côté serveur).

Fichiers touchés (chercher les blocs `⚠️ OTP désactivé temporairement`) :
- `features/auth/data/datasources/auth_remote_datasource.dart`
- `features/auth/domain/repositories/auth_repository.dart`
- `features/auth/data/repositories/auth_repository_impl.dart`
- `features/auth/presentation/providers/auth_providers.dart`
- `features/auth/presentation/pages/login_email_page.dart`
- `features/auth/presentation/pages/otp_verification_page.dart` (écran
  désormais inatteint — `AppRoutes.otp` n'est plus poussé nulle part, mais
  la page reste montée dans le router pour ne rien casser)

### Pour réactiver l'OTP plus tard
1. Dans `auth_remote_datasource.dart` : décommenter `demanderOtp` et
   `verifierOtp`.
2. Dans `auth_repository.dart` + `auth_repository_impl.dart` : décommenter
   `demanderCodeConnexion`/`verifierCodeConnexion`.
3. Dans `auth_providers.dart` : décommenter les 3 méthodes OTP de
   `OtpLoginController` (`demanderCode`, `renvoyerCode`, `verifierCode`).
4. Dans `login_email_page.dart` : dans `_soumettre`, remplacer l'appel à
   `controller.connecter(...)` par `controller.demanderCode(...)`, et
   restaurer `context.push(AppRoutes.otp)` sur succès (+ remettre l'import
   `go_router` et `app_routes.dart`).
5. Dans `otp_verification_page.dart` : restaurer les appels
   `controller.verifierCode(...)` / `controller.renvoyerCode()` à la place
   des deux stubs `context.showError(...)`.

## 7. ⚠️ Point de sécurité à vérifier côté backend

Ton test Insomnia sur `POST https://prmspadcmbackend.vercel.app/api/auth/test/register`
a réussi **en production**. Le code (`routes/authRoutes.js`) ne monte ces
routes de test que si `process.env.NODE_ENV !== 'production'` — donc soit
cette variable n'est pas définie sur ton déploiement Vercel, soit elle a une
valeur différente de `'production'`. Tant qu'elle n'est pas corrigée,
n'importe qui peut créer un compte (y compris administrateur) ou se
connecter sans OTP sur ton backend en ligne. À vérifier dans
Vercel → Project Settings → Environment Variables.
