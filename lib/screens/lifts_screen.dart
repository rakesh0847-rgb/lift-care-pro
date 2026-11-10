
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/customer_service.dart';
import '../services/lift_service.dart';

class LiftsScreen extends StatefulWidget {
  final Locale locale;

  const LiftsScreen({
    super.key,
    required this.locale,
  });

  @override
  State<LiftsScreen> createState() => _LiftsScreenState();
}

class _LiftsScreenState extends State<LiftsScreen> {
  static const navy = Color(0xFF101B36);
  static const blue = Color(0xFF4169E1);
  static const background = Color(0xFFF4F6FB);

  final searchController = TextEditingController();

  List<Map<String, dynamic>> lifts = [];
  List<Map<String, dynamic>> customers = [];

  bool loading = true;

  bool get ml => widget.locale.languageCode == 'ml';

  String t(String en, String mal) => ml ? mal : en;

  String get companyCode => AuthService.instance.companyCode;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final results = await Future.wait([
        LiftService.instance.getLifts(companyCode),
        CustomerService.instance.getCustomers(companyCode),
      ]);

      if (!mounted) return;

      setState(() {
        lifts = results[0];
        customers = results[1];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  List<Map<String, dynamic>> get filteredLifts {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) return lifts;

    return lifts.where((lift) {
      return [
        lift['liftId'],
        lift['buildingName'],
        lift['customerName'],
        lift['liftType'],
        lift['capacity'],
      ].any((value) =>
          (value ?? '').toString().toLowerCase().contains(query));
    }).toList();
  }

  String customerName(String? id) {
    if (id == null || id.isEmpty) return '';

    final customer = customers.where(
      (c) => c['id'].toString() == id,
    );

    if (customer.isEmpty) return '';

    return customer.first['name']?.toString() ?? '';
  }

  Future<void> showLiftForm([
    Map<String, dynamic>? lift,
  ]) async {
    final formKey = GlobalKey<FormState>();

    final liftId = TextEditingController(
      text: lift?['liftId'] ?? '',
    );

    final building = TextEditingController(
      text: lift?['buildingName'] ?? '',
    );

    final capacity = TextEditingController(
      text: lift?['capacity']?.toString() ?? '',
    );

    final floors = TextEditingController(
      text: lift?['floors']?.toString() ?? '',
    );

    final machine = TextEditingController(
      text: lift?['machine'] ?? '',
    );

    final motor = TextEditingController(
      text: lift?['motor'] ?? '',
    );

    final controller = TextEditingController(
      text: lift?['controller'] ?? '',
    );

    final notes = TextEditingController(
      text: lift?['notes'] ?? '',
    );

    final isEdit = lift != null;

    String liftType = lift?['liftType'] ?? 'Passenger';
    String? customerId = lift?['customerId']?.toString();

    DateTime? installationDate =
        DateTime.tryParse(lift?['installationDate'] ?? '');

    DateTime? amcStartDate =
        DateTime.tryParse(lift?['amcStartDate'] ?? '');

    DateTime? amcEndDate =
        DateTime.tryParse(lift?['amcEndDate'] ?? '');

    String dateText(DateTime? date) {
      if (date == null) return t('Select date', 'തീയതി തിരഞ്ഞെടുക്കുക');

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    Future<DateTime?> chooseDate(
      BuildContext context,
      DateTime? initial,
    ) {
      return showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(1990),
        lastDate: DateTime(2100),
      );
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget field(
              TextEditingController textController,
              String label,
              IconData icon, {
              bool required = false,
              TextInputType? keyboard,
              int maxLines = 1,
            }) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: TextFormField(
                  controller: textController,
                  keyboardType: keyboard,
                  maxLines: maxLines,
                  validator: required
                      ? (value) =>
                          value == null || value.trim().isEmpty
                              ? t('Required field', 'ഈ വിവരം നൽകണം')
                              : null
                      : null,
                  decoration: InputDecoration(
                    labelText: label,
                    prefixIcon: Icon(icon, color: blue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5EAF2),
                      ),
                    ),
                  ),
                ),
              );
            }

            Widget section(String title) {
              return Padding(
                padding: const EdgeInsets.only(
                  top: 13,
                  bottom: 14,
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
              );
            }

            Widget dateField(
              String label,
              DateTime? value,
              ValueChanged<DateTime> onSelected,
            ) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: InkWell(
                  onTap: () async {
                    final selected = await chooseDate(
                      context,
                      value,
                    );

                    if (selected != null) {
                      setModalState(() => onSelected(selected));
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: label,
                      prefixIcon: const Icon(
                        Icons.calendar_month_outlined,
                        color: blue,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    child: Text(dateText(value)),
                  ),
                ),
              );
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: const BoxDecoration(
                color: background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t(
                              isEdit ? 'Edit Lift' : 'Add New Lift',
                              isEdit
                                  ? 'ലിഫ്റ്റ് വിവരങ്ങൾ തിരുത്തുക'
                                  : 'പുതിയ ലിഫ്റ്റ് ചേർക്കുക',
                            ),
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: navy,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Form(
                      key: formKey,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        children: [
                          section(t(
                            'Customer Information',
                            'കസ്റ്റമർ വിവരങ്ങൾ',
                          )),

                          DropdownButtonFormField<String>(
                            value: customerId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: t(
                                'Select Customer',
                                'കസ്റ്റമറെ തിരഞ്ഞെടുക്കുക',
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: blue,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  t('No customer selected',
                                      'കസ്റ്റമറെ തിരഞ്ഞെടുത്തിട്ടില്ല'),
                                ),
                              ),
                              ...customers.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c['id'].toString(),
                                  child: Text(
                                    c['name']?.toString() ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setModalState(() => customerId = value);
                            },
                          ),

                          const SizedBox(height: 14),

                          field(
                            liftId,
                            t('Lift ID / Number *', 'ലിഫ്റ്റ് നമ്പർ *'),
                            Icons.tag,
                            required: true,
                          ),

                          field(
                            building,
                            t('Building Name *', 'കെട്ടിടത്തിന്റെ പേര് *'),
                            Icons.apartment,
                            required: true,
                          ),

                          section(t('Lift Specifications', 'ലിഫ്റ്റ് വിവരങ്ങൾ')),

                          DropdownButtonFormField<String>(
                            value: liftType,
                            decoration: InputDecoration(
                              labelText: t('Lift Type', 'ലിഫ്റ്റിന്റെ തരം'),
                              prefixIcon: const Icon(
                                Icons.elevator_outlined,
                                color: blue,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'Passenger',
                                child: Text(t('Passenger Lift', 'പാസഞ്ചർ ലിഫ്റ്റ്')),
                              ),
                              DropdownMenuItem(
                                value: 'Goods',
                                child: Text(t('Goods Lift', 'ഗുഡ്സ് ലിഫ്റ്റ്')),
                              ),
                              DropdownMenuItem(
                                value: 'Hospital',
                                child: Text(t('Hospital Lift', 'ഹോസ്പിറ്റൽ ലിഫ്റ്റ്')),
                              ),
                              DropdownMenuItem(
                                value: 'Home',
                                child: Text(t('Home Lift', 'ഹോം ലിഫ്റ്റ്')),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() => liftType = value);
                              }
                            },
                          ),

                          const SizedBox(height: 13),

                          field(
                            capacity,
                            t('Capacity (KG) *', 'ശേഷി (KG) *'),
                            Icons.scale_outlined,
                            required: true,
                            keyboard: TextInputType.number,
                          ),

                          field(
                            floors,
                            t('Number of Floors', 'നിലകളുടെ എണ്ണം'),
                            Icons.layers_outlined,
                            keyboard: TextInputType.number,
                          ),

                          section(t('Technical Details', 'സാങ്കേതിക വിവരങ്ങൾ')),

                          field(
                            machine,
                            t('Machine / Gearbox', 'മെഷീൻ / ഗിയർബോക്സ്'),
                            Icons.settings_outlined,
                          ),

                          field(
                            motor,
                            t('Motor Details', 'മോട്ടോർ വിവരങ്ങൾ'),
                            Icons.electric_bolt_outlined,
                          ),

                          field(
                            controller,
                            t('Controller Details', 'കൺട്രോളർ വിവരങ്ങൾ'),
                            Icons.memory_outlined,
                          ),

                          section(t('Installation & AMC', 'ഇൻസ്റ്റലേഷൻ & AMC')),

                          dateField(
                            t('Installation Date', 'ഇൻസ്റ്റലേഷൻ തീയതി'),
                            installationDate,
                            (d) => installationDate = d,
                          ),

                          dateField(
                            t('AMC Start Date', 'AMC ആരംഭ തീയതി'),
                            amcStartDate,
                            (d) => amcStartDate = d,
                          ),

                          dateField(
                            t('AMC End Date', 'AMC അവസാന തീയതി'),
                            amcEndDate,
                            (d) => amcEndDate = d,
                          ),

                          section(t('Additional Information', 'കൂടുതൽ വിവരങ്ങൾ')),

                          field(
                            notes,
                            t('Notes', 'കുറിപ്പുകൾ'),
                            Icons.notes_outlined,
                            maxLines: 3,
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      14 + MediaQuery.of(sheetContext)
                          .viewInsets.bottom,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: navy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: saving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                if (amcStartDate != null &&
                                    amcEndDate != null &&
                                    amcEndDate!.isBefore(amcStartDate!)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(t(
                                        'AMC end date must be after start date.',
                                        'AMC അവസാന തീയതി ആരംഭ തീയതിക്ക് ശേഷമായിരിക്കണം.',
                                      )),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => saving = true);

                                try {
                                  final selectedCustomer =
                                      customers.where(
                                    (c) =>
                                        c['id'].toString() == customerId,
                                  );

                                  await LiftService.instance.saveLift(
                                    companyCode: companyCode,
                                    lift: {
                                      'id': lift?['id'] ?? '',
                                      'liftId': liftId.text.trim(),
                                      'buildingName': building.text.trim(),
                                      'customerId': customerId ?? '',
                                      'customerName': selectedCustomer.isEmpty
                                          ? ''
                                          : selectedCustomer.first['name'],
                                      'liftType': liftType,
                                      'capacity': capacity.text.trim(),
                                      'floors': int.tryParse(
                                              floors.text.trim()) ??
                                          0,
                                      'machine': machine.text.trim(),
                                      'motor': motor.text.trim(),
                                      'controller': controller.text.trim(),
                                      'installationDate':
                                          installationDate?.toIso8601String() ?? '',
                                      'amcStartDate':
                                          amcStartDate?.toIso8601String() ?? '',
                                      'amcEndDate':
                                          amcEndDate?.toIso8601String() ?? '',
                                      'notes': notes.text.trim(),
                                    },
                                  );

                                  if (!mounted) return;

                                  Navigator.pop(sheetContext);
                                  await loadData();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(t(
                                        'Lift saved successfully',
                                        'ലിഫ്റ്റ് വിവരങ്ങൾ സേവ് ചെയ്തു',
                                      )),
                                    ),
                                  );
                                } catch (e) {
                                  setModalState(() => saving = false);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              },
                        icon: saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          t('Save Lift', 'ലിഫ്റ്റ് സേവ് ചെയ്യുക'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    liftId.dispose();
    building.dispose();
    capacity.dispose();
    floors.dispose();
    machine.dispose();
    motor.dispose();
    controller.dispose();
    notes.dispose();
  }

  Future<void> deleteLift(Map<String, dynamic> lift) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Delete Lift?', 'ലിഫ്റ്റ് നീക്കം ചെയ്യണോ?')),
        content: Text(t(
          'This lift record will be deleted from this device.',
          'ഈ ലിഫ്റ്റ് വിവരങ്ങൾ ഈ ഉപകരണത്തിൽ നിന്ന് നീക്കം ചെയ്യും.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('Cancel', 'റദ്ദാക്കുക')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('Delete', 'നീക്കം ചെയ്യുക')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await LiftService.instance.deleteLift(
        companyCode: companyCode,
        liftId: lift['id'].toString(),
      );

      await loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget liftCard(Map<String, dynamic> lift) {
    final type = lift['liftType'] ?? 'Passenger';
    final id = lift['liftId'] ?? '';
    final name = lift['buildingName'] ?? '';
    final customer = lift['customerName'] ?? '';
    final capacity = lift['capacity'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9EDF5)),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 47,
                width: 47,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.elevator_rounded,
                  color: blue,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t('Lift ID', 'ലിഫ്റ്റ് ഐഡി')}: $id',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    showLiftForm(lift);
                  } else if (value == 'delete') {
                    deleteLift(lift);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(t('Edit', 'തിരുത്തുക')),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(t('Delete', 'നീക്കം ചെയ്യുക')),
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 25),

          Row(
            children: [
              _info(Icons.category_outlined, type),
              const SizedBox(width: 20),
              _info(Icons.scale_outlined, '$capacity KG'),
              const SizedBox(width: 20),
              _info(
                Icons.layers_outlined,
                '${lift['floors'] ?? 0} ${t('Floors', 'നിലകൾ')}',
              ),
            ],
          ),

          if (customer.toString().isNotEmpty) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 17, color: Colors.black54),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    customer,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if ((lift['amcEndDate'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event_outlined,
                    size: 17, color: blue),
                const SizedBox(width: 7),
                Text(
                  '${t('AMC End', 'AMC അവസാനിക്കുന്നത്')}: '
                  '${_formatDate(lift['amcEndDate'])}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _info(IconData icon, String value) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: blue),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value.toString());
    if (date == null) return '';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredLifts;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: navy,
        title: Text(
          t('Lift Management', 'ലിഫ്റ്റ് മാനേജ്മെന്റ്'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        onPressed: () => showLiftForm(),
        icon: const Icon(Icons.add),
        label: Text(t('Add Lift', 'ലിഫ്റ്റ് ചേർക്കുക')),
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [navy, Color(0xFF294B91), blue],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.elevator_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('TOTAL LIFTS', 'ആകെ ലിഫ്റ്റുകൾ'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${lifts.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: Colors.white70,
                    size: 23,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: t(
                  'Search lifts, building or customer...',
                  'ലിഫ്റ്റ്, കെട്ടിടം, കസ്റ്റമർ എന്നിവ തിരയുക...',
                ),
                prefixIcon: const Icon(Icons.search, color: blue),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(35),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(35),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.elevator_outlined,
                      size: 55,
                      color: Colors.black26,
                    ),
                    const SizedBox(height: 13),
                    Text(
                      t('No lifts found', 'ലിഫ്റ്റുകൾ കണ്ടെത്തിയില്ല'),
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      t(
                        'Add your first lift to get started.',
                        'ആദ്യത്തെ ലിഫ്റ്റ് ചേർത്ത് തുടങ്ങാം.',
                      ),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                '${t('Lift Records', 'ലിഫ്റ്റ് വിവരങ്ങൾ')} (${filtered.length})',
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 13),
              ...filtered.map(liftCard),
            ],
          ],
        ),
      ),
    );
  }
}
