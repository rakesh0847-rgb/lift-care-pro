
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/customer_service.dart';

class CustomersScreen extends StatefulWidget {
  final Locale locale;

  const CustomersScreen({
    super.key,
    required this.locale,
  });

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  static const navy = Color(0xFF101B36);
  static const blue = Color(0xFF4169E1);
  static const background = Color(0xFFF4F6FB);

  final searchController = TextEditingController();

  List<Map<String, dynamic>> customers = [];
  bool loading = true;

  bool get ml => widget.locale.languageCode == 'ml';

  String t(String en, String mal) => ml ? mal : en;

  String get companyCode => AuthService.instance.companyCode;

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadCustomers() async {
    try {
      final result =
          await CustomerService.instance.getCustomers(companyCode);

      if (!mounted) return;

      setState(() {
        customers = result;
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

  List<Map<String, dynamic>> get filteredCustomers {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) return customers;

    return customers.where((c) {
      return [
        c['name'],
        c['phone'],
        c['email'],
        c['address'],
      ].any((value) =>
          (value ?? '').toString().toLowerCase().contains(query));
    }).toList();
  }

  Future<void> showCustomerForm([
    Map<String, dynamic>? customer,
  ]) async {
    final formKey = GlobalKey<FormState>();

    final name = TextEditingController(
        text: customer?['name'] ?? '');
    final phone = TextEditingController(
        text: customer?['phone'] ?? '');
    final email = TextEditingController(
        text: customer?['email'] ?? '');
    final address = TextEditingController(
        text: customer?['address'] ?? '');
    final gst = TextEditingController(
        text: customer?['gst'] ?? '');
    final liftCount = TextEditingController(
        text: (customer?['liftCount'] ?? '').toString());
    final notes = TextEditingController(
        text: customer?['notes'] ?? '');

    final isEdit = customer != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
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
                              isEdit ? 'Edit Customer' : 'New Customer',
                              isEdit
                                  ? 'കസ്റ്റമർ വിവരങ്ങൾ തിരുത്തുക'
                                  : 'പുതിയ കസ്റ്റമർ',
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
                            horizontal: 20),
                        children: [
                          _sectionTitle(
                            t('Customer Information',
                                'കസ്റ്റമർ വിവരങ്ങൾ'),
                          ),
                          const SizedBox(height: 14),

                          _field(
                            name,
                            t('Customer Name *', 'പേര് *'),
                            Icons.person_outline,
                            required: true,
                          ),
                          _field(
                            phone,
                            t('Phone Number *', 'ഫോൺ നമ്പർ *'),
                            Icons.phone_outlined,
                            keyboard: TextInputType.phone,
                            required: true,
                          ),
                          _field(
                            email,
                            t('Email Address', 'ഇമെയിൽ'),
                            Icons.email_outlined,
                            keyboard: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 12),
                          _sectionTitle(
                            t('Business Details',
                                'ബിസിനസ് വിവരങ്ങൾ'),
                          ),
                          const SizedBox(height: 14),

                          _field(
                            address,
                            t('Address / Location', 'വിലാസം'),
                            Icons.location_on_outlined,
                            maxLines: 3,
                          ),
                          _field(
                            gst,
                            t('GST Number', 'GST നമ്പർ'),
                            Icons.receipt_long_outlined,
                          ),
                          _field(
                            liftCount,
                            t('Number of Lifts', 'ലിഫ്റ്റുകളുടെ എണ്ണം'),
                            Icons.elevator_outlined,
                            keyboard: TextInputType.number,
                          ),

                          const SizedBox(height: 12),
                          _sectionTitle(
                            t('Additional Notes', 'കൂടുതൽ വിവരങ്ങൾ'),
                          ),
                          const SizedBox(height: 14),

                          _field(
                            notes,
                            t('Notes', 'കുറിപ്പുകൾ'),
                            Icons.notes_outlined,
                            maxLines: 3,
                          ),

                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      14 + MediaQuery.of(sheetContext)
                          .viewInsets.bottom,
                    ),
                    color: Colors.white,
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

                                setModalState(() => saving = true);

                                try {
                                  await CustomerService.instance
                                      .saveCustomer(
                                    companyCode: companyCode,
                                    customer: {
                                      'id': customer?['id'] ?? '',
                                      'name': name.text.trim(),
                                      'phone': phone.text.trim(),
                                      'email': email.text.trim(),
                                      'address': address.text.trim(),
                                      'gst': gst.text.trim(),
                                      'liftCount': int.tryParse(
                                              liftCount.text.trim()) ??
                                          0,
                                      'notes': notes.text.trim(),
                                    },
                                  );

                                  if (!mounted) return;

                                  Navigator.pop(sheetContext);
                                  await loadCustomers();

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        t('Customer saved successfully',
                                            'കസ്റ്റമർ സേവ് ചെയ്തു'),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  setModalState(() => saving = false);

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                    ),
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
                          t('Save Customer', 'കസ്റ്റമർ സേവ് ചെയ്യുക'),
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

    name.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    gst.dispose();
    liftCount.dispose();
    notes.dispose();
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: navy,
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? t('This field is required', 'ഈ വിവരം നൽകണം')
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

  Future<void> deleteCustomer(
      Map<String, dynamic> customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Delete Customer?', 'കസ്റ്റമറെ നീക്കണോ?')),
        content: Text(
          t(
            'This customer record will be deleted from this device.',
            'ഈ കസ്റ്റമർ വിവരങ്ങൾ ഉപകരണത്തിൽ നിന്ന് നീക്കം ചെയ്യും.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('Cancel', 'റദ്ദാക്കുക')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(t('Delete', 'നീക്കുക')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await CustomerService.instance.deleteCustomer(
      companyCode: companyCode,
      customerId: customer['id'].toString(),
    );

    await loadCustomers();
  }

  Widget _customerCard(Map<String, dynamic> customer) {
    final name = (customer['name'] ?? '').toString();
    final phone = (customer['phone'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE9EDF5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 49,
                  width: 49,
                  decoration: BoxDecoration(
                    color: blue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      showCustomerForm(customer);
                    } else if (value == 'delete') {
                      deleteCustomer(customer);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined),
                          const SizedBox(width: 10),
                          Text(t('Edit', 'തിരുത്തുക')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline,
                              color: Colors.red),
                          const SizedBox(width: 10),
                          Text(t('Delete', 'നീക്കുക')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 25),

            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 17, color: Colors.grey),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    (customer['address'] ?? '').toString().isEmpty
                        ? t('No address added', 'വിലാസം നൽകിയിട്ടില്ല')
                        : customer['address'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            Row(
              children: [
                const Icon(Icons.elevator_outlined,
                    size: 17, color: blue),
                const SizedBox(width: 6),
                Text(
                  '${customer['liftCount'] ?? 0} ${t('Lifts', 'ലിഫ്റ്റുകൾ')}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: navy,
                  ),
                ),
                const Spacer(),
                Text(
                  t('Customer ID', 'കസ്റ്റമർ ID'),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '#${customer['id']}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = filteredCustomers;

    return Scaffold(
      backgroundColor: background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        onPressed: () => showCustomerForm(),
        icon: const Icon(Icons.add),
        label: Text(t('Add Customer', 'പുതിയ കസ്റ്റമർ')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadCustomers,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new),
                  ),
                  Expanded(
                    child: Text(
                      t('Customers', 'കസ്റ്റമേഴ്സ്'),
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                  ),
                  const Icon(Icons.people_alt_rounded,
                      color: blue, size: 28),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF172B59),
                      Color(0xFF4169E1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded,
                        size: 43, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('Total Customers', 'ആകെ കസ്റ്റമേഴ്സ്'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${customers.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.verified_user_outlined,
                        color: Colors.white70, size: 30),
                  ],
                ),
              ),

              const SizedBox(height: 23),

              TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: t('Search customers...', 'കസ്റ്റമറെ തിരയുക...'),
                  prefixIcon: const Icon(Icons.search, color: blue),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      t('Customer Directory', 'കസ്റ്റമർ ലിസ്റ്റ്'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                  ),
                  Text(
                    '${visible.length} ${t('Records', 'രേഖകൾ')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              if (loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (visible.isEmpty)
                Container(
                  padding: const EdgeInsets.all(35),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 55, color: Colors.black26),
                      const SizedBox(height: 13),
                      Text(
                        t('No customers found',
                            'കസ്റ്റമർമാരെ കണ്ടെത്തിയില്ല'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        t('Add your first customer.',
                            'ആദ്യത്തെ കസ്റ്റമറെ ചേർക്കുക.'),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...visible.map(_customerCard),

              const SizedBox(height: 85),
            ],
          ),
        ),
      ),
    );
  }
}
