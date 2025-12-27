import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class AnesthesiologistChecklistViewScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String patientInitials;
  final String dossierNumber;
  final String room;
  final int progress;
  final int total;

  const AnesthesiologistChecklistViewScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientInitials,
    required this.dossierNumber,
    required this.room,
    this.progress = 3,
    this.total = 5,
  });

  @override
  State<AnesthesiologistChecklistViewScreen> createState() =>
      _AnesthesiologistChecklistViewScreenState();
}

class _AnesthesiologistChecklistViewScreenState
    extends State<AnesthesiologistChecklistViewScreen> {
  bool _isLoading = false;

  // Mock data - checklist items filled by nurse (read-only)
  late List<_ChecklistItem> _checklistItems;

  @override
  void initState() {
    super.initState();
    // Initialize with progress from parameters
    _checklistItems = [
      _ChecklistItem(label: 'Identité du patient confirmée', isChecked: widget.progress >= 1),
      _ChecklistItem(label: 'Patient à jeun (> 6h)', isChecked: widget.progress >= 2),
      _ChecklistItem(label: 'Dossier médical complet (Bilans/Radio)', isChecked: widget.progress >= 3),
      _ChecklistItem(label: 'Préparation cutanée / Douche réalisée', isChecked: widget.progress >= 4),
      _ChecklistItem(label: 'Retrait bijoux, prothèses et vernis', isChecked: widget.progress >= 5),
    ];
  }

  int get _checkedCount => _checklistItems.where((item) => item.isChecked).length;
  bool get _isComplete => _checkedCount == _checklistItems.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // App Bar
          _buildAppBar(context),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Hero Card
                  _buildPatientHero(),

                  const SizedBox(height: 24),

                  // Read-only indicator
                  _buildReadOnlyIndicator(),

                  const SizedBox(height: 16),

                  // Section Header
                  _buildSectionHeader(),

                  const SizedBox(height: 16),

                  // Checklist Items
                  ..._checklistItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildChecklistCard(item),
                      )),

                  const SizedBox(height: 24),

                  // Status Summary
                  _buildStatusSummary(),
                ],
              ),
            ),
          ),

          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Text(
                'Vérification Checklist',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.patientInitials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID #${widget.dossierNumber} • ${widget.room}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Checklist remplie par l\'infirmier(e) - Vérification anesthésiste',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Checklist de sécurité',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _isComplete
                ? AppColors.success.withValues(alpha: 0.15)
                : AppColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$_checkedCount / ${_checklistItems.length} VALIDÉS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _isComplete ? AppColors.success : AppColors.warning,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistCard(_ChecklistItem item) {
    return Opacity(
      opacity: 0.85,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isChecked ? AppColors.primarySurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isChecked ? Colors.transparent : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Checkbox (read-only)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isChecked ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: item.isChecked ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: item.isChecked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            // Label
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isComplete
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isComplete
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isComplete ? Icons.check_circle : Icons.pending,
            size: 24,
            color: _isComplete ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isComplete ? 'Patient prêt pour le bloc' : 'Préparation en cours',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _isComplete ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isComplete
                      ? 'Toutes les vérifications ont été effectuées par l\'infirmier(e)'
                      : '${_checklistItems.length - _checkedCount} élément(s) restant(s) à valider par l\'infirmier(e)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isComplete && !_isLoading ? _validateChecklist : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: _isComplete ? 4 : 0,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isComplete ? Icons.verified : Icons.block,
                      color: Colors.white.withValues(alpha: _isComplete ? 1.0 : 0.5),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isComplete ? 'VALIDER LA PRÉPARATION' : 'CHECKLIST INCOMPLÈTE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: _isComplete ? 1.0 : 0.5),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _validateChecklist() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Préparation validée pour ${widget.patientName}'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );

      context.go('/anesthesiologist');
    }
  }
}

class _ChecklistItem {
  final String label;
  final bool isChecked;

  _ChecklistItem({required this.label, required this.isChecked});
}
