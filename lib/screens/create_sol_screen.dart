// Dépendances requises dans pubspec.yaml :
//   supabase_flutter: ^2.5.0
//   share_plus: ^10.0.0
//   intl: ^0.19.0
//   google_fonts: ^6.2.1

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/plan_service.dart';

class CreateSolScreen extends StatefulWidget {
  const CreateSolScreen({super.key});

  @override
  State<CreateSolScreen> createState() => _CreateSolScreenState();
}

class _CreateSolScreenState extends State<CreateSolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _membersCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  String _currency = 'HTG';
  String _frequency = 'monthly';
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;

  /// Plan de l'utilisateur courant. Chargé dans initState.
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _loadUserPlan();
  }

  Future<void> _loadUserPlan() async {
    final pro = await PlanService.isPro();
    if (mounted) setState(() => _isPro = pro);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _membersCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      // --- Vérification côté app AVANT l'insert : évite de faire
      // --- remplir tout le formulaire pour finir sur une erreur.
      // --- La fonction can_create_group() côté base reste le filet
      // --- de sécurité final (voir trigger sur la table groups).
      final canCreate = await supabase.rpc(
        'can_create_group',
        params: {'p_user_id': currentUser.id},
      );

      if (canCreate != true) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        await _showPaywallSheet(reason: 'group');
        return;
      }

      // --- L'utilisateur qui crée le groupe devient automatiquement
      // --- l'organisateur : aucun champ à remplir pour ça.
      final whatsappLink = _whatsappCtrl.text.trim();
      final maxMembers = int.tryParse(_membersCtrl.text.trim()) ?? 5;
      final inviteCode = _generateInviteCode();
      final description = _descCtrl.text.trim();

      final inserted = await supabase
          .from('groups')
          .insert({
            'name': _nameCtrl.text.trim(),
            if (description.isNotEmpty) 'description': description,
            'organizer_id': currentUser.id,
            'contribution_amount': double.parse(_amountCtrl.text.trim()),
            'currency': _currency,
            'frequency': _frequency,
            'order_type': 'random',
            'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
            'status': 'draft',
            'max_members': maxMembers,
            'invite_code': inviteCode,
            if (whatsappLink.isNotEmpty) 'whatsapp_link': whatsappLink,
          })
          .select()
          .single();

      // Ajouter automatiquement l'organisateur comme premier membre
      try {
        await supabase.from('group_members').insert({
          'group_id': inserted['id'],
          'user_id': currentUser.id,
          'turn_order': 1,
          'status': 'confirmed',
        });
      } catch (_) {
        // Ignorer si la politique s'en charge déjà
      }

      if (!mounted) return;
      await _showInviteSheet(
        groupId: inserted['id'] as String,
        inviteCode: inviteCode,
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      // Filet de sécurité : si le trigger côté base a bloqué l'insert
      if (e.message.contains('subscription_required') ||
          e.message.contains('member_limit_reached')) {
        await _showPaywallSheet(
          reason: e.message.contains('member_limit_reached')
              ? 'member'
              : 'group',
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Affichez selon la raison :
  //   'group'  → limite de groupes atteinte (FREE : 1 groupe max)
  //   'member' → limite de membres atteinte (FREE : 5 membres max)
  Future<void> _showPaywallSheet({String reason = 'group'}) async {
    final t = AppLocalizations.of(context)!;
    if (!mounted) return;

    final isMemberLimit = reason == 'member';
    final title = isMemberLimit ? 'Limite de membres atteinte' : t.paywallTitle;
    final body = isMemberLimit
        ? 'Le plan gratuit est limité à ${PlanService.freeMaxMembers} membres par groupe.\nPassez au PRO pour des membres illimités.'
        : t.paywallBody;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13.5,
                color: AppColors.ash,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.paywallPlanName,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '9,99 \$ / mois',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.marigold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.marigold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop(); // Ferme le bottom sheet d'abord

                  // Lance l'achat
                  final success = await PlanService.purchasePro();
                  if (success) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Merci pour votre achat ! Vous êtes maintenant PRO.',
                        ),
                      ),
                    );
                    // Recharge le plan pour débloquer l'interface
                    _loadUserPlan();
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('L\'achat n\'a pas pu être finalisé.'),
                      ),
                    );
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
                child: Text(
                  t.paywallCta,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  t.later,
                  style: GoogleFonts.ibmPlexSans(color: AppColors.ash),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = math.Random();
    return List.generate(6, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  String _buildInviteMessage(AppLocalizations t, {String? inviteCode}) {
    final amount = _amountCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final freqLabel = {
      'weekly': t.freqWeekly,
      'biweekly': t.freqBiweekly,
      'monthly': t.freqMonthly,
    }[_frequency];
    // Formatage de la date compatible avec le Créole Haïtien (ht)
    final dateLabel = _formatLocalizedDate(_startDate, t.localeName);

    return '''
${t.inviteMessageIntro} "${_nameCtrl.text.trim()}" !

${desc.isNotEmpty ? '$desc\n' : ''}${t.inviteMessageAmountLabel} : $amount $_currency
${t.inviteMessageFrequencyLabel} : $freqLabel
${t.inviteMessageStartLabel} : $dateLabel
${inviteCode != null && inviteCode.isNotEmpty ? '\n${t.inviteCode} : $inviteCode' : ''}
''';
  }

  Future<void> _showInviteSheet({required String groupId, String? inviteCode}) async {
    final t = AppLocalizations.of(context)!;
    final message = _buildInviteMessage(t, inviteCode: inviteCode);
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.inviteSheetTitle,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.inviteSheetSubtitle,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13.5,
                color: AppColors.ash,
              ),
            ),
            if (inviteCode != null && inviteCode.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.marigold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.marigold),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.inviteCode.toUpperCase(),
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: const Color(0xFFB87A1F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          inviteCode,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppColors.ink),
                      tooltip: t.copyCode,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: inviteCode));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t.codeCopied),
                              backgroundColor: AppColors.palm,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.paperDim),
              ),
              child: Text(
                message,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12.5,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    SharePlus.instance.share(ShareParams(text: message)),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(t.shareInvite),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.marigold,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: Text(
                  t.later,
                  style: GoogleFonts.ibmPlexSans(color: AppColors.ash),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        title: Text(
          t.createSolTitle,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _label(t.fieldName),
            _field(
              controller: _nameCtrl,
              hint: t.fieldNameHint,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? t.validationNameRequired
                  : null,
            ),
            const SizedBox(height: 16),
            _label(t.fieldDescription),
            _field(
              controller: _descCtrl,
              hint: t.fieldDescriptionHint,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _label(t.fieldAmount),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _field(
                    controller: _amountCtrl,
                    hint: t.fieldAmountHint,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return t.validationAmountRequired;
                      }
                      if (double.tryParse(v.trim()) == null) {
                        return t.validationAmountInvalid;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dropdown(
                    value: _currency,
                    items: const ['HTG', 'USD'],
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label(t.fieldFrequency),
            _dropdown(
              value: _frequency,
              items: const ['weekly', 'biweekly', 'monthly'],
              displayLabel: (k) => {
                'weekly': t.freqWeekly,
                'biweekly': t.freqBiweekly,
                'monthly': t.freqMonthly,
              }[k]!,
              onChanged: (v) => setState(() => _frequency = v!),
              fullWidth: true,
            ),
            const SizedBox(height: 16),
            _label(t.fieldMembers),
            _field(
              controller: _membersCtrl,
              hint: t.fieldMembersHint,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return t.validationMembersRequired;
                }
                final n = int.tryParse(v.trim());
                if (n == null) return t.validationMembersInvalid;
                // Plan FREE : maximum 5 membres (organisateur inclus)
                if (!_isPro && n > PlanService.freeMaxMembers) {
                  return 'Plan gratuit : max ${PlanService.freeMaxMembers} membres. Passez au PRO !';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // --- Lien WhatsApp (optionnel) ---
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.chat_rounded,
                    color: Color(0xFF25D366),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  t.whatsappGroupLink,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paperDim,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t.optional,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ash,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _whatsappCtrl,
              keyboardType: TextInputType.url,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14,
                color: AppColors.ink,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // optionnel
                if (!v.trim().startsWith('http')) {
                  return 'Le lien doit commencer par https://';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'https://chat.whatsapp.com/...',
                hintStyle: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  color: AppColors.ash,
                ),
                prefixIcon: const Icon(
                  Icons.link_rounded,
                  color: Color(0xFF25D366),
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.paperDim),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.paperDim),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF25D366),
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.coral),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _label(t.fieldStartDate),
            InkWell(
              onTap: _pickStartDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.paperDim),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppColors.ash,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatLocalizedDate(
                        _startDate,
                        Localizations.localeOf(context).languageCode,
                      ),
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        t.submitCreate,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.ibmPlexSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.ibmPlexSans(fontSize: 14, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.ibmPlexSans(fontSize: 14, color: AppColors.ash),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.paperDim),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.paperDim),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.marigold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.coral),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    String Function(String)? displayLabel,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.paperDim),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: fullWidth,
          onChanged: onChanged,
          style: GoogleFonts.ibmPlexSans(fontSize: 14, color: AppColors.ink),
          items: items
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(displayLabel != null ? displayLabel(v) : v),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  /// Formate une date selon la langue choisie (Créole Haïtien, Français, Anglais).
  /// Évite l'exception "Invalid locale ht" de la bibliothèque intl.
  static String _formatLocalizedDate(DateTime date, String languageCode) {
    if (languageCode.toLowerCase() == 'ht') {
      const monthsHt = [
        'janvye',
        'fevriye',
        'mas',
        'avril',
        'me',
        'jen',
        'jiyè',
        'out',
        'septanm',
        'oktòb',
        'novanm',
        'desanm',
      ];
      final month = (date.month >= 1 && date.month <= 12)
          ? monthsHt[date.month - 1]
          : '';
      return '${date.day} $month ${date.year}';
    }

    try {
      return DateFormat.yMMMMd(languageCode).format(date);
    } catch (_) {
      try {
        return DateFormat.yMMMMd('fr').format(date);
      } catch (_) {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
  }
}
