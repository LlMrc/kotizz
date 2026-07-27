# Sòl App — MVP Flutter

## Mise en route

1. `flutter pub get`
2. Renseigne tes identifiants Supabase dans `lib/main.dart` (voir le
   commentaire au-dessus de `main()`) — appelle `Supabase.initialize(...)`
   avant `runApp()`.
3. `flutter run`

## Structure

```
lib/
  main.dart                    → point d'entrée, gestion de la langue
  l10n/app_localizations.dart  → traductions EN / FR / HT
  theme/app_colors.dart        → palette partagée
  widgets/responsive_shell.dart→ BottomNavigationBar (mobile) / NavigationRail (≥720px)
  screens/
    home_screen.dart           → écran d'accueil + roue de rotation
    groups_screen.dart         → liste des sòl (placeholder à brancher)
    alerts_screen.dart         → notifications (placeholder à brancher)
    profile_screen.dart        → stats + sélecteur de langue
    create_sol_screen.dart     → formulaire de création + invitation
```

## Langues

Le sélecteur de langue est dans l'écran Profil (`ChoiceChip` EN / FR / HT).
Le changement est géré dans `main.dart` via `AppLanguage` et rebuild
immédiatement toute l'app — pas besoin de redémarrage.

Pour ajouter une chaîne traduite : ajoute une clé dans le dictionnaire
`_values` de `app_localizations.dart` (avec `en`, `fr`, `ht`), puis
expose-la via un getter/méthode dans `AppLocalizations`.

## Responsive

`ResponsiveShell` bascule automatiquement à 720px de largeur
(`kRailBreakpoint` dans `responsive_shell.dart`) :
- **< 720px** → `BottomNavigationBar` en bas (mobile)
- **≥ 720px** → `NavigationRail` à gauche (tablette / desktop / web)

## Prochaines étapes suggérées

- Brancher `groups_screen.dart` et `alerts_screen.dart` sur Supabase
  (tables `groups`/`participants` et `notifications` du schéma déjà conçu)
- Remplacer le nom "Louis" codé en dur dans `home_screen.dart` par
  `supabase.auth.currentUser`
- Ajouter l'authentification (écran de connexion / inscription)
