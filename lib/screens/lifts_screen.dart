import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/customer_service.dart';
import '../services/lift_service.dart';

class LiftsScreen extends StatefulWidget {
  final Locale locale;
  const LiftsScreen({super.key, required this.locale});
  @override
  State<LiftsScreen> createState() => _LiftsScreenState();
}

class _LiftsScreenState extends State<LiftsScreen> {
  static const navy = Color(0xFF101B36), blue = Color(0xFF4169E1);
  static const bg = Color(0xFFF4F6FB);
  final search = TextEditingController();
  List<Map<String, dynamic>> lifts = [], customers = [];
  bool loading = true;
  bool get ml => widget.locale.languageCode == 'ml';
  String t(String en, String mal) => ml ? mal : en;
  String get companyCode => AuthService.instance.companyCode;

  @override
  void initState() { super.initState(); loadData(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> loadData() async {
    try {
      final r = await Future.wait([
        LiftService.instance.getLifts(companyCode),
        CustomerService.instance.getCustomers(companyCode),
      ]);
      if (!mounted) return;
      setState(() { lifts = r[0]; customers = r[1]; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  List<Map<String, dynamic>> get filtered {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return lifts;
    return lifts.where((l) => [
      l['liftId'], l['buildingName'], l['customerName'], l['liftType'], l['capacity']
    ].any((v) => (v ?? '').toString().toLowerCase().contains(q))).toList();
  }

  Map<String, dynamic> newRow([Map<String, dynamic>? d]) => {
    'liftId': TextEditingController(text: (d?['liftId'] ?? '').toString()),
    'building': TextEditingController(text: (d?['buildingName'] ?? '').toString()),
    'capacity': TextEditingController(text: (d?['capacity'] ?? '').toString()),
    'floors': TextEditingController(text: (d?['floors'] ?? '').toString()),
    'machine': TextEditingController(text: (d?['machine'] ?? '').toString()),
    'motor': TextEditingController(text: (d?['motor'] ?? '').toString()),
    'controller': TextEditingController(text: (d?['controller'] ?? '').toString()),
    'notes': TextEditingController(text: (d?['notes'] ?? '').toString()),
    'type': d?['liftType']?.toString() ?? 'Passenger',
  };

  Future<void> showLiftForm([Map<String, dynamic>? lift]) async {
    final formKey = GlobalKey<FormState>();
    final editing = lift != null;
    final count = TextEditingController(text: '1');
    String? customerId = lift?['customerId']?.toString();
    DateTime? install = DateTime.tryParse((lift?['installationDate'] ?? '').toString());
    DateTime? amcStart = DateTime.tryParse((lift?['amcStartDate'] ?? '').toString());
    DateTime? amcEnd = DateTime.tryParse((lift?['amcEndDate'] ?? '').toString());
    final rows = <Map<String, dynamic>>[newRow(lift)];

    String dateText(DateTime? d) => d == null
      ? t('Select date', 'തീയതി തിരഞ്ഞെടുക്കുക')
      : '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    Future<DateTime?> pick(DateTime? d) => showDatePicker(
      context: context, initialDate: d ?? DateTime.now(),
      firstDate: DateTime(1990), lastDate: DateTime(2100));

    Widget field(TextEditingController c, String label, IconData icon,
        {bool required = false, TextInputType? keyboard}) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c, keyboardType: keyboard,
        validator: required ? (v) => v == null || v.trim().isEmpty
          ? t('Required field', 'ഈ വിവരം നൽകണം') : null : null,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: blue),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none)),
      ));

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (sheet) {
        bool saving = false;
        return StatefulBuilder(builder: (ctx, modalSet) {
          Widget section(String s) => Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 10),
            child: Text(s, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: navy)));
          Widget dateField(String label, DateTime? value, ValueChanged<DateTime> set) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(onTap: () async {
              final d = await pick(value); if (d != null) modalSet(() => set(d));
            }, child: InputDecorator(
              decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.calendar_month, color: blue),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none)),
              child: Text(dateText(value)))));

          return Container(
            height: MediaQuery.of(ctx).size.height * .93,
            decoration: const BoxDecoration(color: bg, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            child: Column(children: [
              Padding(padding: const EdgeInsets.all(18), child: Row(children: [
                Expanded(child: Text(t(editing ? 'Edit Lift' : 'Add Lifts', editing ? 'ലിഫ്റ്റ് തിരുത്തുക' : 'ലിഫ്റ്റുകൾ ചേർക്കുക'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navy))),
                IconButton(onPressed: () => Navigator.pop(sheet), icon: const Icon(Icons.close)),
              ])),
              Expanded(child: Form(key: formKey, child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  section(t('Customer Information', 'കസ്റ്റമർ വിവരങ്ങൾ')),
                  DropdownButtonFormField<String>(
                    value: customerId, isExpanded: true,
                    decoration: InputDecoration(labelText: t('Select Customer', 'കസ്റ്റമറെ തിരഞ്ഞെടുക്കുക'),
                      prefixIcon: const Icon(Icons.person_outline, color: blue), filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none)),
                    items: customers.map((c) => DropdownMenuItem<String>(
                      value: c['id'].toString(), child: Text(c['name']?.toString() ?? '', overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => modalSet(() => customerId = v),
                    validator: (v) => v == null || v.isEmpty ? t('Select a customer', 'കസ്റ്റമറെ തിരഞ്ഞെടുക്കുക') : null),
                  if (!editing) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: count, keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: t('Number of Lifts', 'ലിഫ്റ്റുകളുടെ എണ്ണം'),
                        helperText: t('Enter 1–20. Each lift has separate specifications.', '1–20 വരെ നൽകുക. ഓരോ ലിഫ്റ്റിനും പ്രത്യേകം വിവരങ്ങൾ നൽകാം.'),
                        prefixIcon: const Icon(Icons.format_list_numbered, color: blue), filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none)),
                      validator: (v) { final n = int.tryParse((v ?? '').trim()); return n == null || n < 1 || n > 20
                        ? t('Enter a number from 1 to 20', '1 മുതൽ 20 വരെ എണ്ണം നൽകുക') : null; },
                      onChanged: (v) {
                        final n = int.tryParse(v.trim()); if (n == null || n < 1 || n > 20) return;
                        modalSet(() {
                          while (rows.length < n) rows.add(newRow());
                          while (rows.length > n) {
                            final x = rows.removeLast();
                            for (final v in x.values) { if (v is TextEditingController) v.dispose(); }
                          }
                        });
                      }),
                  ],
                  ...List.generate(rows.length, (i) {
                    final r = rows[i];
                    return Container(
                      margin: const EdgeInsets.only(top: 14), padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(color: const Color(0xFFEAF0FF), borderRadius: BorderRadius.circular(15)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${t('Lift', 'ലിഫ്റ്റ്')} ${i + 1} – ${t('Specifications', 'വിവരങ്ങൾ')}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: navy)),
                        const SizedBox(height: 10),
                        field(r['liftId'], t('Lift ID / Number *', 'ലിഫ്റ്റ് നമ്പർ *'), Icons.tag, required: true),
                        field(r['building'], t('Building Name *', 'കെട്ടിടത്തിന്റെ പേര് *'), Icons.apartment, required: true),
                        DropdownButtonFormField<String>(
                          value: r['type'] as String,
                          decoration: InputDecoration(labelText: t('Lift Type', 'ലിഫ്റ്റിന്റെ തരം'), filled: true, fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none)),
                          items: [
                            DropdownMenuItem(value: 'Passenger', child: Text(t('Passenger Lift', 'പാസഞ്ചർ ലിഫ്റ്റ്'))),
                            DropdownMenuItem(value: 'Goods', child: Text(t('Goods Lift', 'ഗുഡ്സ് ലിഫ്റ്റ്'))),
                            DropdownMenuItem(value: 'Hospital', child: Text(t('Hospital Lift', 'ഹോസ്പിറ്റൽ ലിഫ്റ്റ്'))),
                            DropdownMenuItem(value: 'Home', child: Text(t('Home Lift', 'ഹോം ലിഫ്റ്റ്'))),
                          ],
                          onChanged: (v) { if (v != null) modalSet(() => r['type'] = v); }),
                        const SizedBox(height: 10),
                        field(r['capacity'], t('Capacity (KG) *', 'ശേഷി (KG) *'), Icons.scale, required: true, keyboard: TextInputType.number),
                        field(r['floors'], t('Number of Floors', 'നിലകളുടെ എണ്ണം'), Icons.layers, keyboard: TextInputType.number),
                        field(r['machine'], t('Machine / Gearbox', 'മെഷീൻ / ഗിയർബോക്സ്'), Icons.settings),
                        field(r['motor'], t('Motor Details', 'മോട്ടോർ വിവരങ്ങൾ'), Icons.electric_bolt),
                        field(r['controller'], t('Controller Details', 'കൺട്രോളർ വിവരങ്ങൾ'), Icons.memory),
                        field(r['notes'], t('Notes', 'കുറിപ്പുകൾ'), Icons.notes),
                      ]),
                    );
                  }),
                  section(t('Installation & AMC Dates (applies to all lifts in this batch)', 'ഇൻസ്റ്റലേഷൻ & AMC തീയതികൾ (ഈ ബാച്ചിലെ എല്ലാ ലിഫ്റ്റുകൾക്കും)')),
                  dateField(t('Installation Date', 'ഇൻസ്റ്റലേഷൻ തീയതി'), install, (d) => install = d),
                  dateField(t('AMC Start Date', 'AMC ആരംഭ തീയതി'), amcStart, (d) => amcStart = d),
                  dateField(t('AMC End Date', 'AMC അവസാന തീയതി'), amcEnd, (d) => amcEnd = d),
                  const SizedBox(height: 20),
                ],
              ))),
              Container(color: Colors.white, padding: EdgeInsets.fromLTRB(18, 12, 18, 12 + MediaQuery.of(sheet).viewInsets.bottom),
                child: SizedBox(width: double.infinity, height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: navy),
                    onPressed: saving ? null : () async {
                      if (!formKey.currentState!.validate()) return;
                      if (amcStart != null && amcEnd != null && amcEnd!.isBefore(amcStart!)) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(t('AMC end date must be after start date.', 'AMC അവസാന തീയതി ആരംഭ തീയതിക്ക് ശേഷമായിരിക്കണം.'))));
                        return;
                      }
                      final ids = rows.map((r) => (r['liftId'] as TextEditingController).text.trim().toLowerCase()).toList();
                      if (ids.toSet().length != ids.length) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(t('Each lift must have a different Lift ID.', 'ഓരോ ലിഫ്റ്റിനും വ്യത്യസ്ത ഐഡി നൽകണം.'))));
                        return;
                      }
                      modalSet(() => saving = true);
                      try {
                        final customer = customers.firstWhere((c) => c['id'].toString() == customerId);
                        for (final r in rows) {
                          await LiftService.instance.saveLift(companyCode: companyCode, lift: {
                            'id': editing ? (lift?['id'] ?? '') : '',
                            'liftId': r['liftId'].text.trim(),
                            'buildingName': r['building'].text.trim(),
                            'customerId': customerId ?? '',
                            'customerName': customer['name']?.toString() ?? '',
                            'liftType': r['type'],
                            'capacity': r['capacity'].text.trim(),
                            'floors': int.tryParse(r['floors'].text.trim()) ?? 0,
                            'machine': r['machine'].text.trim(),
                            'motor': r['motor'].text.trim(),
                            'controller': r['controller'].text.trim(),
                            'installationDate': install?.toIso8601String() ?? '',
                            'amcStartDate': amcStart?.toIso8601String() ?? '',
                            'amcEndDate': amcEnd?.toIso8601String() ?? '',
                            'notes': r['notes'].text.trim(),
                          });
                        }
                        if (!mounted) return;
                        Navigator.pop(sheet);
                        await loadData();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('${rows.length} lift record(s) saved.', '${rows.length} ലിഫ്റ്റ് റെക്കോർഡുകൾ സേവ് ചെയ്തു.'))));
                      } catch (e) {
                        modalSet(() => saving = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
                    icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                    label: Text(t('Save Lift Records', 'ലിഫ്റ്റ് വിവരങ്ങൾ സേവ് ചെയ്യുക')),
                  ))),
            ]),
          );
        });
      },
    );
    for (final r in rows) {
      for (final v in r.values) { if (v is TextEditingController) v.dispose(); }
    }
    count.dispose();
  }

  Future<void> deleteLift(Map<String, dynamic> lift) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(t('Delete Lift?', 'ലിഫ്റ്റ് നീക്കം ചെയ്യണോ?')),
      content: Text(t('This lift record will be deleted from this device.', 'ഈ ലിഫ്റ്റ് വിവരങ്ങൾ ഈ ഉപകരണത്തിൽ നിന്ന് നീക്കം ചെയ്യും.')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('Cancel', 'റദ്ദാക്കുക'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('Delete', 'നീക്കം ചെയ്യുക'))),
      ],
    ));
    if (ok != true) return;
    try {
      await LiftService.instance.deleteLift(companyCode: companyCode, liftId: lift['id'].toString());
      await loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget info(IconData icon, String value) => Flexible(child: Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 15, color: blue), const SizedBox(width: 5),
    Flexible(child: Text(value, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 11, color: navy, fontWeight: FontWeight.w600))),
  ]));

  String formatDate(dynamic value) {
    final d = DateTime.tryParse(value.toString());
    if (d == null) return '';
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }

  Widget liftCard(Map<String, dynamic> l) => Container(
    margin: const EdgeInsets.only(bottom: 13), padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE9EDF5))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(height: 46, width: 46, decoration: BoxDecoration(color: const Color(0xFFEAF0FF), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.elevator, color: blue, size: 27)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((l['buildingName'] ?? '').toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navy)),
          Text('${t('Lift ID', 'ലിഫ്റ്റ് ഐഡി')}: ${l['liftId'] ?? ''}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ])),
        PopupMenuButton<String>(
          onSelected: (v) { if (v == 'edit') showLiftForm(l); if (v == 'delete') deleteLift(l); },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(t('Edit', 'തിരുത്തുക'))),
            PopupMenuItem(value: 'delete', child: Text(t('Delete', 'നീക്കം ചെയ്യുക'))),
          ]),
      ]),
      const Divider(height: 25),
      Row(children: [
        info(Icons.category, (l['liftType'] ?? 'Passenger').toString()),
        const SizedBox(width: 15), info(Icons.scale, '${l['capacity'] ?? ''} KG'),
        const SizedBox(width: 15), info(Icons.layers, '${l['floors'] ?? 0} ${t('Floors', 'നിലകൾ')}'),
      ]),
      if ((l['customerName'] ?? '').toString().isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('${t('Customer', 'കസ്റ്റമർ')}: ${l['customerName']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
      if ((l['amcEndDate'] ?? '').toString().isNotEmpty) ...[
        const SizedBox(height: 10),
        Text('${t('AMC End', 'AMC അവസാനിക്കുന്നത്')}: ${formatDate(l['amcEndDate'])}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final items = filtered;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, elevation: 0, foregroundColor: navy,
        title: Text(t('Lift Management', 'ലിഫ്റ്റ് മാനേജ്മെന്റ്'), style: const TextStyle(fontWeight: FontWeight.bold))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: navy, foregroundColor: Colors.white,
        onPressed: () => showLiftForm(), icon: const Icon(Icons.add),
        label: Text(t('Add Lift', 'ലിഫ്റ്റ് ചേർക്കുക'))),
      body: RefreshIndicator(onRefresh: loadData, child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
        children: [
          Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [navy, Color(0xFF294B91), blue]), borderRadius: BorderRadius.circular(22)),
            child: Row(children: [
              const Icon(Icons.elevator, color: Colors.white, size: 38), const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('TOTAL LIFTS', 'ആകെ ലിഫ്റ്റുകൾ'), style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.3)),
                Text('${lifts.length}', style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.bold)),
              ])),
              const Icon(Icons.cloud_off, color: Colors.white70),
            ])),
          const SizedBox(height: 18),
          TextField(controller: search, onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: t('Search lifts, building or customer...', 'ലിഫ്റ്റ്, കെട്ടിടം, കസ്റ്റമർ എന്നിവ തിരയുക...'),
              prefixIcon: const Icon(Icons.search, color: blue), filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
          const SizedBox(height: 18),
          if (loading) const Center(child: Padding(padding: EdgeInsets.all(35), child: CircularProgressIndicator()))
          else if (items.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(35), child: Text(t('No lifts found. Add your first lift.', 'ലിഫ്റ്റുകൾ കണ്ടെത്തിയില്ല. ആദ്യത്തെ ലിഫ്റ്റ് ചേർക്കുക.'))))
          else ...[
            Text('${t('Lift Records', 'ലിഫ്റ്റ് വിവരങ്ങൾ')} (${items.length})',
              style: const TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12), ...items.map(liftCard),
          ],
        ],
      )),
    );
  }
}
