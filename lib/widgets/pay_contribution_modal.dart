import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class PayContributionModal extends StatefulWidget {
  final Map<String, dynamic> group;
  final Map<String, dynamic>? beneficiary;
  final bool hasPaid;
  final VoidCallback? onPaymentUpdated;

  const PayContributionModal({
    super.key,
    required this.group,
    required this.beneficiary,
    required this.hasPaid,
    this.onPaymentUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> group,
    required Map<String, dynamic>? beneficiary,
    required bool hasPaid,
    VoidCallback? onPaymentUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PayContributionModal(
        group: group,
        beneficiary: beneficiary,
        hasPaid: hasPaid,
        onPaymentUpdated: onPaymentUpdated,
      ),
    );
  }

  @override
  State<PayContributionModal> createState() => _PayContributionModalState();
}

class _PayContributionModalState extends State<PayContributionModal> {
  bool _isSubmitting = false;
  late bool _hasPaid;

  @override
  void initState() {
    super.initState();
    _hasPaid = widget.hasPaid;
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'B';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Future<void> _callPhone(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copié dans le presse-papiers'),
        backgroundColor: AppColors.palm,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _declarePayment() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final groupId = widget.group['id'] as String;
      final currentTurn = (widget.group['current_turn'] as int?) ?? 1;
      final rawAmount = widget.group['contribution_amount'];
      final amount = double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;
      final currency = (widget.group['currency'] as String?) ?? 'HTG';
      final groupName = (widget.group['name'] as String?) ?? 'Tontine';
      final isOrganizer = (widget.group['organizer_id'] == user.id);

      // Si l'utilisateur est l'organisateur lui-même, son paiement est directement confirmé
      final initialStatus = isOrganizer ? 'confirmed' : 'pending';

      // Vérifier si une contribution existe déjà
      final existing = await Supabase.instance.client
          .from('contributions')
          .select('id, payment_status')
          .eq('group_id', groupId)
          .eq('user_id', user.id)
          .eq('turn_number', currentTurn)
          .maybeSingle();

      if (existing != null) {
        await Supabase.instance.client
            .from('contributions')
            .update({
              'payment_status': initialStatus,
              'paid_at': DateTime.now().toIso8601String(),
              'amount': amount,
              'currency': currency,
            })
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client.from('contributions').insert({
          'group_id': groupId,
          'user_id': user.id,
          'turn_number': currentTurn,
          'amount': amount,
          'currency': currency,
          'payment_status': initialStatus,
          'paid_at': DateTime.now().toIso8601String(),
        });
      }

      // Notifier l'organisateur et le bénéficiaire
      final organizerId = widget.group['organizer_id'] as String?;
      final beneficiaryUserId = widget.beneficiary?['user_id'] as String?;
      final recipients = <String>{};
      if (organizerId != null && organizerId != user.id) recipients.add(organizerId);
      if (beneficiaryUserId != null && beneficiaryUserId != user.id) recipients.add(beneficiaryUserId);

      if (recipients.isNotEmpty) {
        final alerts = recipients.map((rId) => {
          'user_id': rId,
          'group_id': groupId,
          'type': 'payment',
          'title': 'Paiement de cotisation déclaré 💳',
          'body': 'Un membre a déclaré avoir payé sa cotisation pour le Tour $currentTurn de "$groupName". En attente de votre confirmation.',
          'is_read': false,
        }).toList();

        try {
          await Supabase.instance.client.from('alerts').insert(alerts);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOrganizer
                ? 'Cotisation confirmée (Payé) 🟢'
                : 'Paiement signalé ! Seul l\'organisateur peut valider et faire passer le statut à "Payé".'),
            backgroundColor: AppColors.palm,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        widget.onPaymentUpdated?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final beneficiary = widget.beneficiary;
    final groupName = (widget.group['name'] as String?) ?? 'Tontine';
    final currentTurn = (widget.group['current_turn'] as int?) ?? 1;
    final totalTurns = (widget.group['max_members'] as int?) ?? 5;
    final amount = widget.group['contribution_amount']?.toString() ?? '0';
    final currency = (widget.group['currency'] as String?) ?? 'HTG';

    final beneficiaryName = (beneficiary?['full_name'] as String?)?.trim().isNotEmpty == true
        ? (beneficiary!['full_name'] as String).trim()
        : 'Bénéficiaire en cours d\'attribution';
    final beneficiaryPhone = (beneficiary?['phone'] as String?)?.trim() ?? '';
    final payoutMethod = (beneficiary?['payout_method'] as String?)?.trim() ?? '';
    final payoutDetails = (beneficiary?['payout_details'] as String?)?.trim() ?? '';
    final isBeneficiaryUser = beneficiary != null && beneficiary['user_id'] == currentUser?.id;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.ash.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payer votre cotisation',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$groupName • Tour $currentTurn/$totalTurns',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          color: AppColors.ash,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const Divider(height: 20, color: AppColors.paperDim),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Montant à payer card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.marigold.withValues(alpha: 0.2),
                          AppColors.marigold.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.marigold.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MONTANT DE LA COTISATION',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: const Color(0xFF8A5A0A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$amount $currency',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.payments_rounded,
                            color: Color(0xFFB87A1F),
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section Bénéficiaire
                  Text(
                    'BÉNÉFICIAIRE DU TOUR',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.ash,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Bénéficiaire Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.paperDim),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.marigold,
                                border: Border.all(color: AppColors.ink, width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _getInitials(beneficiaryName),
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          beneficiaryName,
                                          style: GoogleFonts.bricolageGrotesque(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.marigold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isBeneficiaryUser
                                          ? 'C\'est votre tour !'
                                          : 'Bénéficiaire du Tour $currentTurn',
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF8A5A0A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.paperDim),
                        const SizedBox(height: 14),

                        // Téléphone
                        _InfoRow(
                          icon: Icons.phone_rounded,
                          label: 'Numéro de téléphone',
                          value: beneficiaryPhone.isNotEmpty ? beneficiaryPhone : 'Non renseigné',
                          actionWidget: beneficiaryPhone.isNotEmpty
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Copier',
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.ash),
                                      onPressed: () => _copyToClipboard(context, beneficiaryPhone, 'Numéro'),
                                    ),
                                    IconButton(
                                      tooltip: 'Appeler',
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.call_rounded, size: 18, color: AppColors.palm),
                                      onPressed: () => _callPhone(beneficiaryPhone),
                                    ),
                                    IconButton(
                                      tooltip: 'WhatsApp',
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF25D366)),
                                      onPressed: () => _openWhatsApp(beneficiaryPhone),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Moyen de paiement / Banque
                        _InfoRow(
                          icon: Icons.account_balance_rounded,
                          label: 'Moyen de réception / Banque',
                          value: payoutMethod.isNotEmpty ? payoutMethod : 'MonCash / Natcash / Virement',
                        ),
                        const SizedBox(height: 12),

                        // Coordonnées / Compte bancaire
                        _InfoRow(
                          icon: Icons.credit_card_rounded,
                          label: 'Compte en banque / Coordonnées',
                          value: payoutDetails.isNotEmpty
                              ? payoutDetails
                              : (beneficiaryPhone.isNotEmpty
                                  ? 'Utiliser le No téléphone ($beneficiaryPhone)'
                                  : 'Contacter directement le bénéficiaire'),
                          actionWidget: (payoutDetails.isNotEmpty || beneficiaryPhone.isNotEmpty)
                              ? IconButton(
                                  tooltip: 'Copier',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.ash),
                                  onPressed: () => _copyToClipboard(
                                    context,
                                    payoutDetails.isNotEmpty ? payoutDetails : beneficiaryPhone,
                                    'Coordonnées',
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Consignes / Note
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.paperDim),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.ash),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Envoyez votre part de cotisation au bénéficiaire indiqué ci-dessus. Une fois le transfert réalisé, signalez votre paiement ci-dessous. Seul l\'organisateur de la tontine peut valider et faire passer votre statut à "Payé".',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12.5,
                              color: AppColors.ash,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  if (isBeneficiaryUser)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.palm.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.palm.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.palm, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'C\'est votre tour ! Vous êtes le bénéficiaire de ce pot. Les membres vous versent leur cotisation.',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.palm,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_hasPaid)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.palm.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.palm.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.palm, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cotisation validée par l\'organisateur ✓',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.palm,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Votre paiement pour ce tour est officiellement confirmé (Payé).',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 12,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.palm,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _declarePayment,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, size: 20),
                        label: Text(
                          _isSubmitting
                              ? 'Traitement en cours...'
                              : (widget.group['organizer_id'] == currentUser?.id
                                  ? 'Confirmer mon paiement (Payé)'
                                  : 'Signaler mon paiement à l\'organisateur'),
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Fermer',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ash,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? actionWidget;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.actionWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  color: AppColors.ash,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        if (actionWidget != null) actionWidget!,
      ],
    );
  }
}
