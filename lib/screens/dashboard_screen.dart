import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/customer_service.dart';
import '../services/local_store.dart';
import 'customers_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Locale locale;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onSignOut;

  const DashboardScreen({
    super.key,
    required this.locale,
    required this.onLanguageChanged,
    required this.onSignOut,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int customerCount = 0;
  int reportCount = 0;
  bool loading = true;

  bool get isMalayalam => widget.locale.languageCode == 'ml';
  String t(String en, String ml) => isMalayalam ? ml : en;

  static const navy = Color(0xFF101B36);
  static const blue = Color(0xFF4169E1);
  static const background = Color(0xFFF4F6FB);

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final customers = await CustomerService.instance.getCustomers(
        AuthService.instance.companyCode,
      );
      final reports = LocalStore.instance.getRecords();
      if (!mounted) return;
      setState(() {
        customerCount = customers.length;
        reportCount = reports.length;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> openCustomers() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomersScreen(locale: widget.locale),
      ),
    );
    if (mounted) await loadDashboard();
  }

  void showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t(
          'This section will be available in the next step.',
          'ഈ വിഭാഗം അടുത്ത ഘട്ടത്തിൽ ലഭ്യമാകും.',
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = AuthService.instance.companyName;
    final code = AuthService.instance.companyCode;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF172B59), blue],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.elevator_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LiftCare Pro',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: navy,
                            )),
                        Text('MAINTENANCE MANAGEMENT',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.2,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'en' || value == 'ml') {
                        widget.onLanguageChanged(value);
                      } else if (value == 'logout') {
                        widget.onSignOut();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'en', child: Text('English')),
                      const PopupMenuItem(value: 'ml', child: Text('മലയാളം')),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'logout',
                        child: Text(t('Sign out', 'ലോഗ് ഔട്ട്')),
                      ),
                    ],
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFFE7EAF1)),
                      ),
                      child: const Icon(Icons.more_horiz_rounded, color: navy),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(23),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF101B36), Color(0xFF294B91), blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withOpacity(0.20),
                      blurRadius: 24,
                      offset: const Offset(0, 11),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('COMPANY WORKSPACE', 'കമ്പനി വർക്ക്‌സ്‌പേസ്'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 13),
                    Text(company,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 7),
                    Text('${t('Company ID', 'കമ്പനി ഐഡി')}: $code',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: Color(0xFF8EF0C1), size: 17),
                        const SizedBox(width: 7),
                        Text(t('Workspace active', 'വർക്ക്‌സ്‌പേസ് സജീവമാണ്'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11)),
                        const Spacer(),
                        const Icon(Icons.wifi_off_rounded,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 5),
                        const Text('Offline ready',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 27),
              _SectionHeading(
                title: t('Overview', 'അവലോകനം'),
                subtitle: t('Your service activity at a glance',
                    'പ്രവർത്തനങ്ങളുടെ ചുരുക്കം'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people_alt_rounded,
                      title: t('Customers', 'കസ്റ്റമേഴ്സ്'),
                      value: '$customerCount',
                      color: blue,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.assignment_rounded,
                      title: t('Reports', 'റിപ്പോർട്ടുകൾ'),
                      value: '$reportCount',
                      color: const Color(0xFF159D83),
                    ),
                  ),
                ],
              ),
              if (loading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 2),
              ],
              const SizedBox(height: 28),
              _SectionHeading(
                title: t('Management', 'മാനേജ്മെന്റ്'),
                subtitle: t('Manage your maintenance operations',
                    'സർവീസ് പ്രവർത്തനങ്ങൾ നിയന്ത്രിക്കുക'),
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 13,
                mainAxisSpacing: 13,
                childAspectRatio: 1.08,
                children: [
                  _MenuCard(
                    icon: Icons.people_alt_rounded,
                    title: t('Customers', 'കസ്റ്റമേഴ്സ്'),
                    subtitle: t('Customer details', 'കസ്റ്റമർ വിവരങ്ങൾ'),
                    color: blue,
                    onTap: openCustomers,
                  ),
                  _MenuCard(
                    icon: Icons.elevator_rounded,
                    title: t('Lifts', 'ലിഫ്റ്റുകൾ'),
                    subtitle: t('Lift management', 'ലിഫ്റ്റ് വിവരങ്ങൾ'),
                    color: const Color(0xFF8B5CF6),
                    onTap: showComingSoon,
                  ),
                  _MenuCard(
                    icon: Icons.assignment_rounded,
                    title: t('Service Reports', 'സർവീസ് റിപ്പോർട്ടുകൾ'),
                    subtitle: t('Monthly maintenance', 'മാസ സർവീസ്'),
                    color: const Color(0xFF159D83),
                    onTap: showComingSoon,
                  ),
                  _MenuCard(
                    icon: Icons.engineering_rounded,
                    title: t('Technicians', 'ടെക്നീഷ്യൻമാർ'),
                    subtitle: t('Staff management', 'സ്റ്റാഫ് വിവരങ്ങൾ'),
                    color: const Color(0xFFE59A36),
                    onTap: showComingSoon,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: const Color(0xFFE9EDF5)),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF0FF),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.shield_outlined,
                          color: blue, size: 25),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('Offline data protection',
                                'ഓഫ്‌ലൈൻ ഡാറ്റ സംരക്ഷണം'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: navy,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            t(
                              'Your records are stored locally on this device.',
                              'നിങ്ങളുടെ വിവരങ്ങൾ ഈ ഉപകരണത്തിൽ തന്നെ സൂക്ഷിക്കുന്നു.',
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 23),
              Center(
                child: Text(
                  'LIFTCARE PRO  •  VERSION 1.0',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.3,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF101B36),
            )),
        const SizedBox(height: 3),
        Text(subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: Color(0xFF101B36),
              )),
          const SizedBox(height: 2),
          Text(title,
              style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: const Color(0xFFE9EDF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 25),
              ),
              const SizedBox(height: 14),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101B36),
                  )),
              const SizedBox(height: 5),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.3,
                    color: Colors.black54,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
