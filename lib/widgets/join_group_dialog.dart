import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

Future<void> showJoinGroupDialog(
  BuildContext context, {
  VoidCallback? onGroupJoined,
}) async {
  final t = AppLocalizations.of(context)!;
  final codeCtrl = TextEditingController();
  bool isJoining = false;
  String? errorMessage;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.marigold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.vpn_key_rounded,
                    color: Color(0xFFB87A1F),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  t.joinSol,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              t.enterInviteCodePrompt,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13.5,
                color: AppColors.ash,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 4.0,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                hintText: 'EX: 8A3F29',
                counterText: '',
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.paperDim),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.marigold, width: 2),
                ),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12.5,
                  color: AppColors.coral,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isJoining
                    ? null
                    : () async {
                        final code = codeCtrl.text.trim().toUpperCase();
                        if (code.isEmpty) return;

                        setModalState(() {
                          isJoining = true;
                          errorMessage = null;
                        });

                        try {
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user == null) return;

                          // 1. Tentative via la fonction RPC sécurisée (SECURITY DEFINER)
                          bool joinedViaRpc = false;
                          try {
                            final rpcResult = await Supabase.instance.client.rpc(
                              'join_group_by_code',
                              params: {'p_code': code},
                            );
                            if (rpcResult is Map) {
                              if (rpcResult['success'] == true) {
                                joinedViaRpc = true;
                              } else {
                                final err = rpcResult['error'];
                                if (err == 'invalid_code') {
                                  setModalState(() {
                                    isJoining = false;
                                    errorMessage = t.invalidInviteCode;
                                  });
                                  return;
                                } else if (err == 'already_member') {
                                  setModalState(() {
                                    isJoining = false;
                                    errorMessage = t.alreadyMember;
                                  });
                                  return;
                                } else if (err == 'group_full') {
                                  setModalState(() {
                                    isJoining = false;
                                    errorMessage = t.groupFull;
                                  });
                                  return;
                                }
                              }
                            }
                          } catch (_) {
                            // Fallback direct
                          }

                          if (!joinedViaRpc) {
                            // 2. Chercher le groupe avec ce code
                            final groupResp = await Supabase.instance.client
                                .from('groups')
                                .select('id, name, max_members, organizer_id')
                                .eq('invite_code', code)
                                .maybeSingle();

                            if (groupResp == null) {
                              setModalState(() {
                                isJoining = false;
                                errorMessage = t.invalidInviteCode;
                              });
                              return;
                            }

                            final groupId = groupResp['id'] as String;
                            final maxMembers = (groupResp['max_members'] as int?) ?? 5;

                            // 3. Vérifier si déjà membre
                            final existingMember = await Supabase.instance.client
                                .from('group_members')
                                .select('id')
                                .eq('group_id', groupId)
                                .eq('user_id', user.id)
                                .maybeSingle();

                            if (existingMember != null) {
                              setModalState(() {
                                isJoining = false;
                                errorMessage = t.alreadyMember;
                              });
                              return;
                            }

                            // 4. Compter les membres actuels et trouver le prochain tour
                            final membersCountResp = await Supabase.instance.client
                                .from('group_members')
                                .select('id, turn_order')
                                .eq('group_id', groupId);

                            final membersList = (membersCountResp as List);
                            if (membersList.length >= maxMembers) {
                              setModalState(() {
                                isJoining = false;
                                errorMessage = t.groupFull;
                              });
                              return;
                            }

                            int maxTurn = 0;
                            for (final m in membersList) {
                              final to = m['turn_order'] as int? ?? 0;
                              if (to > maxTurn) maxTurn = to;
                            }
                            final nextTurn = maxTurn > 0 ? maxTurn + 1 : membersList.length + 1;

                            // 5. Insérer le nouveau membre
                            await Supabase.instance.client
                                .from('group_members')
                                .insert({
                                  'group_id': groupId,
                                  'user_id': user.id,
                                  'turn_order': nextTurn,
                                  'status': 'confirmed',
                                });
                          }

                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t.groupJoinedSuccess),
                                backgroundColor: AppColors.palm,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            onGroupJoined?.call();
                          }
                        } catch (e) {
                          setModalState(() {
                            isJoining = false;
                            errorMessage = '$e';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.marigold,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isJoining
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.ink,
                        ),
                      )
                    : Text(
                        t.joinGroupAction,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
