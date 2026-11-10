import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

import '../services/auth_service.dart';
import '../services/customer_service.dart';
import '../services/lift_service.dart';

/// Company-isolated, offline-first storage for monthly service reports.
class ServiceReportStore {
  static String _key(String companyCode) =>
      'liftcare_reports_${companyCode.trim().toUpperCase()}';

  static Future<List<Map<String, dynamic>>> getReports(
      String companyCode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(companyCode));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final reports = decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      reports.sort((a, b) => (b['serviceDate'] ?? '')
          .toString()
          .compareTo((a['serviceDate'] ?? '').toString()));
      return reports;
    } catch (_) {
      throw Exception('Service report data could not be read.');
    }
  }

  static Future<void> saveReport(
      String companyCode, Map<String, dynamic> report) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = await getReports(companyCode);
    final now = DateTime.now().toIso8601String();
    final id = (report['id'] ?? '').toString();
    final index = reports.indexWhere((e) => e['id'].toString() == id);
    if (index >= 0) {
      reports[index] = {...reports[index], ...report, 'updatedAt': now};
    } else {
      reports.add({
        ...report,
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'companyCode': companyCode,
        'createdAt': now,
        'updatedAt': now,
      });
    }
    await prefs.setString(_key(companyCode), jsonEncode(reports));
  }

  static Future<void> deleteReport(String companyCode, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = await getReports(companyCode);
    reports.removeWhere((e) => e['id'].toString() == id);
    await prefs.setString(_key(companyCode), jsonEncode(reports));
  }
}

class ServiceReportsScreen extends StatefulWidget {
  final Locale locale;
  const ServiceReportsScreen({super.key, required this.locale});

  @override
  State<ServiceReportsScreen> createState() => _ServiceReportsScreenState();
}

class _ServiceReportsScreenState extends State<ServiceReportsScreen> {
  static const navy = Color(0xFF101B36);
  static const blue = Color(0xFF4169E1);
  bool get ml => widget.locale.languageCode == 'ml';
  String t(String en, String mal) => ml ? mal : en;
  String get companyCode => AuthService.instance.companyCode;

  bool loading = true;
  List<Map<String, dynamic>> reports = [];

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    try {
      final data = await ServiceReportStore.getReports(companyCode);
      if (!mounted) return;
      setState(() {
        reports = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> createReport() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ServiceReportFormScreen(locale: widget.locale),
      ),
    );
    if (saved == true) await loadReports();
  }

  Future<void> openReport(Map<String, dynamic> report) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ServiceReportDetailScreen(locale: widget.locale, report: report),
      ),
    );
    await loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: Text(t('Service Reports', 'സർവീസ് റിപ്പോർട്ടുകൾ')),
        backgroundColor: Colors.white,
        foregroundColor: navy,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createReport,
        backgroundColor: navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(t('New Report', 'പുതിയ റിപ്പോർട്ട്')),
      ),
      body: RefreshIndicator(
        onRefresh: loadReports,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : reports.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 110),
                      Icon(Icons.assignment_outlined,
                          size: 70, color: Colors.blueGrey.shade200),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          t('No service reports yet',
                              'സർവീസ് റിപ്പോർട്ടുകൾ ലഭ്യമല്ല'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Center(
                        child: Text(
                          t('Create the first monthly maintenance report.',
                              'ആദ്യ മാസ സർവീസ് റിപ്പോർട്ട് തയ്യാറാക്കുക.'),
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: reports.length,
                    itemBuilder: (_, i) {
                      final r = reports[i];
                      final date = DateTime.tryParse(
                              (r['serviceDate'] ?? '').toString()) ??
                          DateTime.now();
                      final done = (r['checklist'] as Map?)
                              ?.values
                              .where((v) => v == true)
                              .length ??
                          0;
                      final total =
                          (r['checklist'] as Map?)?.length ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: Color(0xFFE7EBF3)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF0FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.elevator_rounded,
                                color: blue),
                          ),
                          title: Text(
                            (r['liftLabel'] ?? 'Lift').toString(),
                            style: const TextStyle(
                                color: navy, fontWeight: FontWeight.w800),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${r['customerName'] ?? ''}\n'
                              '${DateFormat('dd MMM yyyy').format(date)} • '
                              '${r['technician'] ?? ''}\n'
                              '$done/$total ${t('checks completed', 'പരിശോധനകൾ പൂർത്തിയായി')}',
                              style: const TextStyle(height: 1.5),
                            ),
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => openReport(r),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class ServiceReportFormScreen extends StatefulWidget {
  final Locale locale;
  const ServiceReportFormScreen({super.key, required this.locale});

  @override
  State<ServiceReportFormScreen> createState() =>
      _ServiceReportFormScreenState();
}

class _ServiceReportFormScreenState extends State<ServiceReportFormScreen> {
  static const navy = Color(0xFF101B36);
  static const blue = Color(0xFF4169E1);
  bool get ml => widget.locale.languageCode == 'ml';
  String t(String en, String mal) => ml ? mal : en;
  String get companyCode => AuthService.instance.companyCode;

  final formKey = GlobalKey<FormState>();
  final technicianController = TextEditingController();
  final notesController = TextEditingController();
  final imagePicker = ImagePicker();

  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> lifts = [];
  String? customerId;
  String? liftId;
  DateTime serviceDate = DateTime.now();
  List<String> photoPaths = [];
  Uint8List? technicianSignature;
  Uint8List? customerSignature;
  bool loading = true;
  bool saving = false;

  static const List<String> checks = [
    'Machine room / controller',
    'Motor and gearbox',
    'Brake operation',
    'Door operation and sensors',
    'Door locks and safety circuit',
    'Car and landing indicators',
    'Emergency alarm / bell',
    'Emergency light',
    'ARD / rescue operation',
    'Car travelling and levelling',
    'Guide rails and lubrication',
    'Pit and top-of-car inspection',
    'General cleaning',
  ];

  final Map<String, bool> checklist = {
    for (final item in checks) item: false,
  };

  @override
  void initState() {
    super.initState();
    loadOptions();
  }

  @override
  void dispose() {
    technicianController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> loadOptions() async {
    try {
      final result = await Future.wait([
        CustomerService.instance.getCustomers(companyCode),
        LiftService.instance.getLifts(companyCode),
      ]);
      if (!mounted) return;
      setState(() {
        customers = result[0];
        lifts = result[1];
        loading = false;
        if (customers.length == 1) customerId = customers.first['id'].toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  List<Map<String, dynamic>> get customerLifts => lifts
      .where((l) => (l['customerId'] ?? '').toString() == customerId)
      .toList();

  Map<String, dynamic>? get selectedCustomer {
    for (final c in customers) {
      if (c['id'].toString() == customerId) return c;
    }
    return null;
  }

  Map<String, dynamic>? get selectedLift {
    for (final l in lifts) {
      if (l['id'].toString() == liftId) return l;
    }
    return null;
  }

  String liftLabel(Map<String, dynamic> l) =>
      '${l['liftId'] ?? ''} • ${l['buildingName'] ?? ''}'.trim();

  Future<void> chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: serviceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => serviceDate = picked);
  }

  Future<void> addPhotos() async {
    try {
      final files = await imagePicker.pickMultiImage(imageQuality: 78);
      if (files.isNotEmpty && mounted) {
        setState(() => photoPaths.addAll(files.map((e) => e.path)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<Uint8List?> captureSignature(String title) async {
    final controller = SignatureController(
      penStrokeWidth: 2.5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    final result = await showDialog<Uint8List?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Signature(controller: controller, backgroundColor: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            onPressed: controller.clear,
            child: Text(t('Clear', 'മായ്ക്കുക')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('Cancel', 'റദ്ദാക്കുക')),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.isEmpty) return;
              final bytes = await controller.toPngBytes();
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, bytes);
              }
            },
            child: Text(t('Use Signature', 'ഒപ്പ് സ്വീകരിക്കുക')),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedCustomer == null || selectedLift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('Select a customer and lift.',
              'കസ്റ്റമറെയും ലിഫ്റ്റിനെയും തിരഞ്ഞെടുക്കുക.')),
        ),
      );
      return;
    }
    if (technicianSignature == null || customerSignature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('Both signatures are required.',
              'രണ്ട് ഒപ്പുകളും ആവശ്യമാണ്.')),
        ),
      );
      return;
    }

    setState(() => saving = true);
    try {
      final customer = selectedCustomer!;
      final lift = selectedLift!;
      final reportNo =
          'SR-${DateFormat('yyyyMM').format(serviceDate)}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      await ServiceReportStore.saveReport(companyCode, {
        'id': '',
        'reportNo': reportNo,
        'serviceDate': serviceDate.toIso8601String(),
        'customerId': customerId,
        'customerName': customer['name'] ?? '',
        'customerPhone': customer['phone'] ?? '',
        'liftId': liftId,
        'liftLabel': liftLabel(lift),
        'technician': technicianController.text.trim(),
        'checklist': checklist,
        'notes': notesController.text.trim(),
        'photoPaths': photoPaths,
        'technicianSignature': base64Encode(technicianSignature!),
        'customerSignature': base64Encode(customerSignature!),
        'companyName': AuthService.instance.companyName,
        'companyCode': companyCode,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget section(String title, IconData icon) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: blue),
            const SizedBox(width: 9),
            Text(title,
                style: const TextStyle(
                    color: navy, fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: Text(t('New Service Report', 'പുതിയ സർവീസ് റിപ്പോർട്ട്')),
        backgroundColor: Colors.white,
        foregroundColor: navy,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                children: [
                  section(t('Service Details', 'സർവീസ് വിവരങ്ങൾ'),
                      Icons.assignment_outlined),
                  DropdownButtonFormField<String>(
                    value: customerId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: t('Customer *', 'കസ്റ്റമർ *'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                    items: customers
                        .map((c) => DropdownMenuItem<String>(
                              value: c['id'].toString(),
                              child: Text(c['name']?.toString() ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      customerId = v;
                      liftId = null;
                    }),
                    validator: (v) => v == null
                        ? t('Select customer', 'കസ്റ്റമറെ തിരഞ്ഞെടുക്കുക')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: liftId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: t('Lift *', 'ലിഫ്റ്റ് *'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                    items: customerLifts
                        .map((l) => DropdownMenuItem<String>(
                              value: l['id'].toString(),
                              child: Text(liftLabel(l)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => liftId = v),
                    validator: (v) => v == null
                        ? t('Select lift', 'ലിഫ്റ്റ് തിരഞ്ഞെടുക്കുക')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: technicianController,
                    decoration: InputDecoration(
                      labelText: t('Technician Name *', 'ടെക്നീഷ്യന്റെ പേര് *'),
                      prefixIcon: const Icon(Icons.engineering_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? t('Enter technician name', 'ടെക്നീഷ്യന്റെ പേര് നൽകുക')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month, color: blue),
                      title: Text(t('Service Date', 'സർവീസ് തീയതി')),
                      subtitle: Text(DateFormat('dd MMMM yyyy').format(serviceDate)),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: chooseDate,
                    ),
                  ),
                  section(t('Monthly Maintenance Checklist', 'മാസ പരിശോധനാ പട്ടിക'),
                      Icons.checklist_rounded),
                  ...checks.map((item) => CheckboxListTile(
                        value: checklist[item] ?? false,
                        onChanged: (v) =>
                            setState(() => checklist[item] = v ?? false),
                        dense: true,
                        activeColor: blue,
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        title: Text(
                          ml ? _checkMalayalam(item) : item,
                          style: const TextStyle(fontSize: 13),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      )),
                  section(t('Service Photos', 'സർവീസ് ഫോട്ടോകൾ'),
                      Icons.photo_library_outlined),
                  OutlinedButton.icon(
                    onPressed: addPhotos,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(t('Add Photos', 'ഫോട്ടോകൾ ചേർക്കുക')),
                  ),
                  if (photoPaths.isNotEmpty)
                    SizedBox(
                      height: 94,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: photoPaths.map((path) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 9),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(File(path),
                                      width: 100, height: 88, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: IconButton(
                                    onPressed: () =>
                                        setState(() => photoPaths.remove(path)),
                                    icon: const Icon(Icons.cancel,
                                        color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  section(t('Signatures', 'ഒപ്പുകൾ'), Icons.draw_outlined),
                  _signatureButton(
                    t('Technician Signature', 'ടെക്നീഷ്യന്റെ ഒപ്പ്'),
                    technicianSignature != null,
                    () async {
                      final bytes = await captureSignature(
                          t('Technician Signature', 'ടെക്നീഷ്യന്റെ ഒപ്പ്'));
                      if (bytes != null) {
                        setState(() => technicianSignature = bytes);
                      }
                    },
                  ),
                  _signatureButton(
                    t('Customer Signature', 'കസ്റ്റമറുടെ ഒപ്പ്'),
                    customerSignature != null,
                    () async {
                      final bytes = await captureSignature(
                          t('Customer Signature', 'കസ്റ്റമറുടെ ഒപ്പ്'));
                      if (bytes != null) {
                        setState(() => customerSignature = bytes);
                      }
                    },
                  ),
                  section(t('Remarks / Notes', 'കുറിപ്പുകൾ'),
                      Icons.notes_outlined),
                  TextFormField(
                    controller: notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: t('Enter observations or pending work',
                          'കണ്ടെത്തിയ കാര്യങ്ങളോ ബാക്കിയുള്ള ജോലികളോ രേഖപ്പെടുത്തുക'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: saving ? null : save,
                      style: FilledButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                      ),
                      icon: saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                      label: Text(t('Save Service Report', 'റിപ്പോർട്ട് സേവ് ചെയ്യുക')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _signatureButton(String label, bool signed, VoidCallback onTap) {
    return Card(
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        leading: Icon(signed ? Icons.verified : Icons.draw,
            color: signed ? Colors.green : blue),
        title: Text(label),
        subtitle: Text(signed
            ? t('Signature captured', 'ഒപ്പ് രേഖപ്പെടുത്തി')
            : t('Tap to sign', 'ഒപ്പിടാൻ അമർത്തുക')),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _checkMalayalam(String value) {
    const translations = {
      'Machine room / controller': 'മെഷീൻ റൂം / കൺട്രോളർ',
      'Motor and gearbox': 'മോട്ടോർ, ഗിയർബോക്സ്',
      'Brake operation': 'ബ്രേക്ക് പ്രവർത്തനം',
      'Door operation and sensors': 'ഡോർ പ്രവർത്തനവും സെൻസറുകളും',
      'Door locks and safety circuit': 'ഡോർ ലോക്കുകളും സേഫ്റ്റി സർക്യൂട്ടും',
      'Car and landing indicators': 'കാർ, ലാൻഡിംഗ് ഇൻഡിക്കേറ്ററുകൾ',
      'Emergency alarm / bell': 'എമർജൻസി അലാറം / ബെൽ',
      'Emergency light': 'എമർജൻസി ലൈറ്റ്',
      'ARD / rescue operation': 'ARD / റെസ്ക്യൂ പ്രവർത്തനം',
      'Car travelling and levelling': 'കാർ യാത്രയും ലെവലിംഗും',
      'Guide rails and lubrication': 'ഗൈഡ് റെയിലുകളും ലൂബ്രിക്കേഷനും',
      'Pit and top-of-car inspection': 'പിറ്റ്, കാർ ടോപ്പ് പരിശോധന',
      'General cleaning': 'പൊതുവായ വൃത്തിയാക്കൽ',
    };
    return translations[value] ?? value;
  }
}

class ServiceReportDetailScreen extends StatelessWidget {
  final Locale locale;
  final Map<String, dynamic> report;
  const ServiceReportDetailScreen(
      {super.key, required this.locale, required this.report});

  bool get ml => locale.languageCode == 'ml';
  String t(String en, String mal) => ml ? mal : en;

  Future<Uint8List> buildPdf() async {
    final doc = pw.Document();
    final date = DateTime.tryParse((report['serviceDate'] ?? '').toString()) ??
        DateTime.now();
    final checks = Map<String, dynamic>.from(report['checklist'] as Map? ?? {});
    final techSig = _decodeSignature(report['technicianSignature']);
    final custSig = _decodeSignature(report['customerSignature']);
    final photoWidgets = <pw.Widget>[];
    final paths = List<String>.from(report['photoPaths'] ?? []);
    for (final path in paths) {
      try {
        final bytes = await File(path).readAsBytes();
        photoWidgets.add(pw.Container(
          width: 220,
          height: 150,
          margin: const pw.EdgeInsets.only(right: 8, bottom: 8),
          child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
        ));
      } catch (_) {}
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => [
        pw.Text((report['companyName'] ?? 'LiftCare Pro').toString(),
            style: pw.TextStyle(
                fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('MONTHLY LIFT MAINTENANCE SERVICE REPORT',
            style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.Divider(),
        pw.Text('Report No: ${report['reportNo'] ?? ''}'),
        pw.Text('Service Date: ${DateFormat('dd MMMM yyyy').format(date)}'),
        pw.SizedBox(height: 12),
        pw.Text('CUSTOMER & LIFT DETAILS',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Customer: ${report['customerName'] ?? ''}'),
        pw.Text('Phone: ${report['customerPhone'] ?? ''}'),
        pw.Text('Lift: ${report['liftLabel'] ?? ''}'),
        pw.Text('Technician: ${report['technician'] ?? ''}'),
        pw.SizedBox(height: 14),
        pw.Text('MAINTENANCE CHECKLIST',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        ...checks.entries.map((e) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(children: [
                pw.Container(
                  width: 13,
                  height: 13,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey700),
                    color: e.value == true ? PdfColors.green : PdfColors.white,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 9))),
                pw.Text(e.value == true ? 'DONE' : 'NOT DONE',
                    style: const pw.TextStyle(fontSize: 8)),
              ]),
            )),
        pw.SizedBox(height: 14),
        pw.Text('REMARKS / PENDING WORK',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text((report['notes'] ?? '').toString().isEmpty
            ? 'No additional remarks'
            : report['notes'].toString()),
        if (photoWidgets.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Text('SERVICE PHOTOS',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 7),
          pw.Wrap(children: photoWidgets),
        ],
        pw.SizedBox(height: 22),
        pw.Text('SIGNATURES',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (techSig != null)
              pw.Expanded(
                child: pw.Column(children: [
                  pw.Image(pw.MemoryImage(techSig), height: 55),
                  pw.Divider(),
                  pw.Text('Technician Signature'),
                ]),
              ),
            pw.SizedBox(width: 25),
            if (custSig != null)
              pw.Expanded(
                child: pw.Column(children: [
                  pw.Image(pw.MemoryImage(custSig), height: 55),
                  pw.Divider(),
                  pw.Text('Customer Signature'),
                ]),
              ),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Text('Generated by LiftCare Pro • Offline Service Record',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    ));
    return doc.save();
  }

  static Uint8List? _decodeSignature(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    try {
      return base64Decode(value.toString());
    } catch (_) {
      return null;
    }
  }

  Future<void> printPdf(BuildContext context) async {
    try {
      final bytes = await buildPdf();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> sharePdf(BuildContext context) async {
    try {
      final bytes = await buildPdf();
      final dir = await getTemporaryDirectory();
      final name =
          '${(report['reportNo'] ?? 'service_report').toString().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.pdf';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'LiftCare Pro Service Report - ${report['customerName'] ?? ''}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse((report['serviceDate'] ?? '').toString()) ??
        DateTime.now();
    final checks = Map<String, dynamic>.from(report['checklist'] as Map? ?? {});
    final done = checks.values.where((v) => v == true).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: Text(t('Report Details', 'റിപ്പോർട്ട് വിവരങ്ങൾ')),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.white,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((report['reportNo'] ?? '').toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 12),
                  _line(t('Customer', 'കസ്റ്റമർ'), report['customerName']),
                  _line(t('Phone', 'ഫോൺ'), report['customerPhone']),
                  _line(t('Lift', 'ലിഫ്റ്റ്'), report['liftLabel']),
                  _line(t('Technician', 'ടെക്നീഷ്യൻ'), report['technician']),
                  _line(t('Date', 'തീയതി'),
                      DateFormat('dd MMM yyyy').format(date)),
                  _line(t('Checklist', 'ചെക്ക്‌ലിസ്റ്റ്'), '$done/${checks.length}'),
                  const Divider(height: 25),
                  Text(t('Maintenance Checklist', 'പരിശോധനാ പട്ടിക'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  ...checks.entries.map((e) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          e.value == true
                              ? Icons.check_circle
                              : Icons.cancel_outlined,
                          color: e.value == true ? Colors.green : Colors.red,
                        ),
                        title: Text(e.key, style: const TextStyle(fontSize: 13)),
                        trailing: Text(e.value == true ? 'Done' : 'Pending',
                            style: const TextStyle(fontSize: 11)),
                      )),
                  const Divider(),
                  Text(t('Remarks', 'കുറിപ്പുകൾ'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text((report['notes'] ?? '').toString().isEmpty
                      ? '-'
                      : report['notes'].toString()),
                  const SizedBox(height: 14),
                  Text(t('Photos', 'ഫോട്ടോകൾ'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List<String>.from(report['photoPaths'] ?? [])
                        .map((p) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(p),
                                  width: 95,
                                  height: 85,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                      width: 95,
                                      height: 85,
                                      child: Icon(Icons.broken_image))),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(t('Signatures', 'ഒപ്പുകൾ'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _signaturePreview(
                          t('Technician', 'ടെക്നീഷ്യൻ'),
                          _decodeSignature(report['technicianSignature']))),
                      const SizedBox(width: 12),
                      Expanded(child: _signaturePreview(
                          t('Customer', 'കസ്റ്റമർ'),
                          _decodeSignature(report['customerSignature']))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => printPdf(context),
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(t('Print / Save PDF', 'PDF പ്രിന്റ് / സേവ് ചെയ്യുക')),
          ),
          OutlinedButton.icon(
            onPressed: () => sharePdf(context),
            icon: const Icon(Icons.share),
            label: Text(t('Share PDF / WhatsApp', 'PDF പങ്കിടുക / WhatsApp')),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, dynamic value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 105,
                child: Text(label,
                    style: const TextStyle(color: Colors.black54))),
            Expanded(
                child: Text((value ?? '-').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );

  Widget _signaturePreview(String label, Uint8List? bytes) => Column(
        children: [
          Container(
            height: 65,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: bytes == null
                ? const Text('-')
                : Image.memory(bytes, fit: BoxFit.contain),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}
