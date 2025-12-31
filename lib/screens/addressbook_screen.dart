import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/i2pd_service.dart';

/// Screen showing address book entries
class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Sample address book data - in real app this comes from i2pd
  final List<Map<String, String>> _addresses = [
    {'name': 'inr.i2p', 'address': 'a2pl...b32.i2p', 'type': 'host'},
    {'name': 'i2p-projekt.i2p', 'address': 'b3nj...b32.i2p', 'type': 'host'},
    {'name': 'stats.i2p', 'address': 'c4ok...b32.i2p', 'type': 'host'},
    {'name': 'echelon.i2p', 'address': 'd5pl...b32.i2p', 'type': 'host'},
    {'name': 'wiki.i2p', 'address': 'e6qm...b32.i2p', 'type': 'host'},
    {'name': 'forum.i2p', 'address': 'f7rn...b32.i2p', 'type': 'host'},
    {'name': 'tracker2.postman.i2p', 'address': 'g8so...b32.i2p', 'type': 'host'},
    {'name': 'git.idk.i2p', 'address': 'h9tp...b32.i2p', 'type': 'host'},
  ];

  List<Map<String, String>> get _filteredAddresses {
    if (_searchQuery.isEmpty) return _addresses;
    return _addresses
        .where((addr) =>
            addr['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            addr['address']!.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Address Book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh address book from subscriptions
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Updating address book...')),
              );
            },
            tooltip: 'Update from subscriptions',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
            tooltip: 'Add address',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search addresses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _filteredAddresses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No addresses in address book'
                              : 'No addresses match "$_searchQuery"',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredAddresses.length,
                    itemBuilder: (context, index) {
                      final addr = _filteredAddresses[index];
                      return _AddressBookEntry(
                        name: addr['name']!,
                        address: addr['address']!,
                        onTap: () => _showAddressDetails(addr),
                        onDelete: () => _deleteAddress(addr),
                      );
                    },
                  ),
          ),
          _buildSubscriptionInfo(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_addresses.length} addresses • Last updated: Never',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'example.i2p',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Base64 or b32.i2p address',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add to address book
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddressDetails(Map<String, String> addr) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              addr['name']!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'B32 Address:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                addr['address']!,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Copy to clipboard
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Open in browser
                    },
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAddress(Map<String, String> addr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Remove ${addr['name']} from address book?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _addresses.remove(addr);
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddressBookEntry extends StatelessWidget {
  final String name;
  final String address;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AddressBookEntry({
    required this.name,
    required this.address,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.purple.withOpacity(0.2),
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(color: Colors.purple),
        ),
      ),
      title: Text(name),
      subtitle: Text(
        address,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}
