import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/contact_repository.dart';
import '../domain/contact_entry.dart';

final contactProvider = StateNotifierProvider<ContactNotifier, AsyncValue<List<ContactEntry>>>((ref) {
  return ContactNotifier(ref.watch(contactRepositoryProvider));
});

final contactSearchQueryProvider = StateProvider<String>((ref) => '');
final contactGroupFilterProvider = StateProvider<String?>((ref) => null);

class ContactNotifier extends StateNotifier<AsyncValue<List<ContactEntry>>> {
  final ContactRepository _repository;

  ContactNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadContacts();
  }

  Future<void> loadContacts() async {
    state = const AsyncValue.loading();
    try {
      final contacts = await _repository.getAllContacts();
      state = AsyncValue.data(contacts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addContact(ContactEntry contact) async {
    await _repository.insertContact(contact);
    await loadContacts();
  }

  Future<void> updateContact(ContactEntry contact) async {
    await _repository.updateContact(contact);
    await loadContacts();
  }

  Future<void> deleteContact(int id) async {
    await _repository.deleteContact(id);
    await loadContacts();
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    await _repository.toggleFavorite(id, isFavorite);
    await loadContacts();
  }
}

class ContactManagerScreen extends ConsumerStatefulWidget {
  const ContactManagerScreen({super.key});

  @override
  ConsumerState<ContactManagerScreen> createState() => _ContactManagerScreenState();
}

class _ContactManagerScreenState extends ConsumerState<ContactManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFavoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactProvider);
    final searchQuery = ref.watch(contactSearchQueryProvider);
    final groupFilter = ref.watch(contactGroupFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('联系人管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_showFavoritesOnly ? Icons.star : Icons.star_border),
            onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildGroupFilter(),
          Expanded(
            child: contactsAsync.when(
              data: (contacts) => _buildContactList(contacts, searchQuery, groupFilter),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('错误: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactDialog(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索联系人...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(contactSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
        ),
        onChanged: (value) => ref.read(contactSearchQueryProvider.notifier).state = value,
      ),
    );
  }

  Widget _buildGroupFilter() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(null, '全部'),
          ...ContactEntry.defaultGroups.map((g) => _buildFilterChip(g, g)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? group, String label) {
    final isSelected = ref.watch(contactGroupFilterProvider) == group;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          ref.read(contactGroupFilterProvider.notifier).state = selected ? group : null;
        },
      ),
    );
  }

  Widget _buildContactList(List<ContactEntry> contacts, String searchQuery, String? groupFilter) {
    var filteredContacts = contacts;

    if (_showFavoritesOnly) {
      filteredContacts = filteredContacts.where((c) => c.isFavorite).toList();
    }

    if (searchQuery.isNotEmpty) {
      filteredContacts = filteredContacts.where((c) =>
        c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (c.phone?.contains(searchQuery) ?? false) ||
        (c.email?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
        (c.company?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    if (groupFilter != null) {
      filteredContacts = filteredContacts.where((c) => c.group == groupFilter).toList();
    }

    if (filteredContacts.isEmpty) {
      return const Center(child: Text('暂无联系人'));
    }

    return ListView.builder(
      itemCount: filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = filteredContacts[index];
        return _buildContactItem(contact);
      },
    );
  }

  Widget _buildContactItem(ContactEntry contact) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(contact.name[0]),
        ),
        title: Text(contact.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.phone != null) Text(contact.phone!),
            if (contact.company != null) Text(contact.company!),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                contact.isFavorite ? Icons.star : Icons.star_border,
                color: contact.isFavorite ? Colors.amber : null,
              ),
              onPressed: () => ref.read(contactProvider.notifier).toggleFavorite(
                contact.id!,
                !contact.isFavorite,
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('编辑')),
                const PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showContactDialog(context, contact);
                } else if (value == 'delete') {
                  _showDeleteDialog(context, contact);
                }
              },
            ),
          ],
        ),
        onTap: () => _showContactDetail(context, contact),
      ),
    );
  }

  void _showContactDialog(BuildContext context, [ContactEntry? contact]) {
    showDialog(
      context: context,
      builder: (context) => ContactFormDialog(contact: contact),
    );
  }

  void _showDeleteDialog(BuildContext context, ContactEntry contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除联系人'),
        content: Text('确定要删除 "${contact.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(contactProvider.notifier).deleteContact(contact.id!);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showContactDetail(BuildContext context, ContactEntry contact) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 30, child: Text(contact.name[0], style: const TextStyle(fontSize: 24))),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contact.name, style: Theme.of(context).textTheme.headlineSmall),
                    if (contact.company != null) Text(contact.company!),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (contact.phone != null) ListTile(
              leading: const Icon(Icons.phone),
              title: Text(contact.phone!),
            ),
            if (contact.email != null) ListTile(
              leading: const Icon(Icons.email),
              title: Text(contact.email!),
            ),
            if (contact.address != null) ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(contact.address!),
            ),
            if (contact.birthday != null) ListTile(
              leading: const Icon(Icons.cake),
              title: Text(contact.birthday!),
            ),
            if (contact.note != null) ListTile(
              leading: const Icon(Icons.note),
              title: Text(contact.note!),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactFormDialog extends ConsumerStatefulWidget {
  final ContactEntry? contact;

  const ContactFormDialog({super.key, this.contact});

  @override
  ConsumerState<ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends ConsumerState<ContactFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _companyController;
  late TextEditingController _roleController;
  late TextEditingController _addressController;
  late TextEditingController _noteController;
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _emailController = TextEditingController(text: widget.contact?.email ?? '');
    _companyController = TextEditingController(text: widget.contact?.company ?? '');
    _roleController = TextEditingController(text: widget.contact?.role ?? '');
    _addressController = TextEditingController(text: widget.contact?.address ?? '');
    _noteController = TextEditingController(text: widget.contact?.note ?? '');
    _selectedGroup = widget.contact?.group;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.contact != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑联系人' : '添加联系人'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '姓名 *'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: '电话'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: '邮箱'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: '公司'),
            ),
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(labelText: '职位'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: '地址'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedGroup,
              decoration: const InputDecoration(labelText: '分组'),
              items: ContactEntry.defaultGroups.map((g) => DropdownMenuItem(
                value: g,
                child: Text(g),
              )).toList(),
              onChanged: (value) => setState(() => _selectedGroup = value),
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: '备注'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isEmpty) return;

            final contact = ContactEntry(
              id: widget.contact?.id,
              name: _nameController.text,
              phone: _phoneController.text.isEmpty ? null : _phoneController.text,
              email: _emailController.text.isEmpty ? null : _emailController.text,
              company: _companyController.text.isEmpty ? null : _companyController.text,
              role: _roleController.text.isEmpty ? null : _roleController.text,
              address: _addressController.text.isEmpty ? null : _addressController.text,
              note: _noteController.text.isEmpty ? null : _noteController.text,
              group: _selectedGroup,
              isFavorite: widget.contact?.isFavorite ?? false,
              createdAt: widget.contact?.createdAt ?? DateTime.now().toIso8601String(),
            );

            if (isEditing) {
              ref.read(contactProvider.notifier).updateContact(contact);
            } else {
              ref.read(contactProvider.notifier).addContact(contact);
            }
            Navigator.pop(context);
          },
          child: Text(isEditing ? '保存' : '添加'),
        ),
      ],
    );
  }
}