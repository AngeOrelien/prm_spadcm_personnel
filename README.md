# mobile-app-personnel

App Flutter **Personnel** (AVS, Médecin, Coordonnateur, Administrateur) du projet PRM — SPAD Cameroun.

Ce projet démarre volontairement avec le strict nécessaire pour faire fonctionner
l'authentification de bout en bout. Le reste de l'architecture (planning, rapports,
messagerie, alertes...) s'ajoutera au fur et à mesure, feature par feature, en
suivant exactement le même découpage `data / domain / presentation`.

---

## 1. Pourquoi cette architecture (et ce qui a été volontairement laissé de côté)

Le style reprend celui de ton projet `macin` (feature-first : `core`, `features/<nom>/{data,domain,presentation}`,
`shared`, `router`, `screens`), mais **allégé** pour un démarrage :

- Pas de `constants/`, `errors/`, etc. par feature — ils vivent dans `core/` tant qu'ils sont partagés.
- Pas d'`usecases/` remplis pour l'instant : avec un seul flux (login OTP), le repository +
  un controller Riverpod suffisent. Le dossier `domain/usecases/` existe déjà (vide) pour
  quand la logique métier deviendra plus complexe (ex: règles de validation croisées).
- Pas de `injection_container.dart` séparé type get_it : Riverpod fait déjà l'injection de
  dépendances via ses providers (`auth_providers.dart`), donc un second système serait redondant.
- `shared/models` et `shared/repositories` existent mais sont vides : ils serviront quand plusieurs
  features partageront un même modèle (ex: `Notification`, `Piece Jointe`).

## 2. Ce qui est fonctionnel maintenant

Flux d'authentification complet, **sans mot de passe**, aligné sur le backend adapté
(`prm_spadcm_backend_updated.zip`) :

1. Un **administrateur** crée un compte personnel côté backend (`POST /api/auth/admin/personnel`)
   — pas encore d'écran pour ça côté app Personnel, à faire en Phase suivante ou via Insomnia pour l'instant.
2. L'utilisateur saisit son email pro → `POST /api/auth/request-otp` → reçoit un code par email.
3. Il saisit le code → `POST /api/auth/verify-login-otp` → reçoit `accessToken` + `refreshToken`,
   stockés dans `flutter_secure_storage`.
4. Au démarrage suivant, `GET /api/auth/me` restaure automatiquement la session si le token est valide ;
   sinon tentative silencieuse de `POST /api/auth/refresh-token`.
5. Le `GoRouter` redirige automatiquement : session inconnue → splash, non connecté → login,
   connecté → accueil (écran provisoire `HomePlaceholderScreen`).

### Fichiers clés du flux auth

```
lib/
├── core/
│   ├── constants/api_constants.dart      # URL du backend + endpoints
│   ├── errors/app_exception.dart         # Exception unifiée data/domain
│   ├── extensions/context_extensions.dart# context.showError / showInfo
│   └── utils/validators.dart             # validation email / code OTP
├── features/auth/
│   ├── data/
│   │   ├── datasources/auth_remote_datasource.dart  # appels Dio bruts
│   │   ├── models/personnel_model.dart              # JSON <-> entité
│   │   └── repositories/auth_repository_impl.dart   # orchestration
│   ├── domain/
│   │   ├── entities/personnel.dart
│   │   └── repositories/auth_repository.dart        # contrat (interface)
│   └── presentation/
│       ├── providers/auth_providers.dart # DI + AuthController + OtpLoginController
│       ├── pages/login_email_page.dart
│       ├── pages/otp_verification_page.dart
│       └── widgets/otp_code_field.dart
├── router/app_router.dart                # redirection selon l'état de session
├── screens/splash_screen.dart
├── screens/home_placeholder_screen.dart  # à remplacer en Phase 2
└── shared/services/
    ├── api_client.dart            # Dio + intercepteur JWT + refresh auto
    └── secure_storage_service.dart
```

## 3. Lancer le projet

Ce zip contient uniquement `lib/`, `pubspec.yaml` et ce README — pas les fichiers générés par
`flutter create` (android/, ios/, etc.), pour rester léger. Deux façons de démarrer :

```bash
# Option A — nouveau projet Flutter, puis on copie lib/ et pubspec.yaml par-dessus
flutter create mobile_app_personnel
cd mobile_app_personnel
# copie le contenu de ce zip (lib/, pubspec.yaml) en écrasant les fichiers générés
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api
```

```bash
# Option B — si tu as déjà initialisé mobile-app-personnel dans ton repo PRM
cd prm-spad-cameroun/mobile-app-personnel
# copie le contenu de ce zip par-dessus
flutter pub get
flutter run
```

`API_BASE_URL` par défaut pointe vers `http://10.0.2.2:4000/api` (alias localhost pour l'émulateur
Android). Sur simulateur iOS, `http://localhost:4000/api` fonctionne directement. Sur appareil
physique, utilise l'IP locale de ta machine sur le même réseau Wi-Fi.

## 4. Tester le flux complet

1. Lance le backend adapté (`npm run dev`), avec `.env` configuré (voir son propre README).
2. Crée le tout premier administrateur via `/register` + `/verify-otp` (flux classique, bootstrap
   uniquement — voir commentaire dans `routes/authRoutes.js`).
3. Avec le token de cet admin, crée un compte personnel via `POST /api/auth/admin/personnel`
   (Insomnia, en attendant l'écran d'administration côté app).
4. Lance l'app Flutter, saisis l'email de ce compte personnel → tu reçois le code par email →
   tu es connecté et redirigé vers l'écran d'accueil.

## 5. Prochaines étapes suggérées

- Écran de création de compte personnel côté app (réservé au rôle `administrateur`).
- Vrai tableau de bord par rôle (AVS / Médecin / Coordonnateur / Administrateur) à la place de
  `HomePlaceholderScreen`, une fois les endpoints métier disponibles côté backend (Phase 2 du README
  principal du projet).
- Authentification biométrique (FaceID / empreinte) en complément, une fois la session JWT en place —
  simple ajout dans `AuthRepositoryImpl` + `local_auth`, pas de refonte nécessaire.
