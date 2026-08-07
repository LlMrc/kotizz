import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';

/// Gestionnaire des notifications reçues lorsque l'application est fermée ou en arrière-plan.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Traitement silencieux en arrière-plan
}

/// Service centralisé de gestion des Push Notifications (Firebase / FCM).
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialise Firebase et configure les écouteurs de notifications.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Demande de permission à l'utilisateur (obligatoire sur iOS et Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Enregistre le token dès que l'utilisateur s'authentifie
        await syncFcmToken();

        // Écoute si le token change en cours d'utilisation
        _messaging.onTokenRefresh.listen((newToken) async {
          await _saveTokenToSupabase(newToken);
        });
      }
    } catch (e) {
      // Ignorer l'erreur si Firebase n'est pas encore prêt sur la plateforme courante (ex: Web)
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Récupère le token FCM de l'appareil et le sauvegarde dans la table `profiles` de Supabase.
  static Future<void> syncFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Sauvegarde le token dans Supabase si l'utilisateur est connecté.
  static Future<void> _saveTokenToSupabase(String token) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', uid);
    } catch (e) {
      debugPrint('Failed to save FCM token to Supabase: $e');
    }
  }

  /// Active l'écoute des messages reçus lorsque l'application est OUVERTE (Foreground).
  static void setupForegroundListener(BuildContext context) {
    // Capture du messenger avant tout gap asynchrone pour respecter
    // la règle use_build_context_synchronously.
    final messenger = ScaffoldMessenger.of(context);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      // Affiche une bannière d'alerte élégante en haut de l'écran
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: AppColors.marigold, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (notification.title != null)
                      Text(
                        notification.title!,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white),
                      ),
                    if (notification.body != null)
                      Text(
                        notification.body!,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.white),
                      ),
                  ],
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }
}
