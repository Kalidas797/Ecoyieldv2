import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String _apiUrl =
    'https://old-mode-eb4a.neerajofficial1133.workers.dev/';

// ─── Data Model ───────────────────────────────────────────────────────────────

class EcoEntry {
  final String name;
  final String location;
  final String message;

  EcoEntry({required this.name, required this.location, required this.message});

  factory EcoEntry.fromJson(Map<String, dynamic> json) => EcoEntry(
        name: json['name'] ?? '',
        location: json['location'] ?? '',
        message: json['message'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'location': location,
        'message': message,
      };
}

// ─── Main Page ─────────────────────────────────────────────────────────────────

class GlobalReach extends StatefulWidget {
  const GlobalReach({Key? key}) : super(key: key);

  @override
  State<GlobalReach> createState() => _GlobalReachState();
}

class _GlobalReachState extends State<GlobalReach>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.eco, color: Color(0xFF81C784)),
            const SizedBox(width: 8),
            const Text(
              'EcoYield',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF81C784).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Local × Global',
                style: TextStyle(fontSize: 11, color: Color(0xFFE8F5E9)),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF81C784),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.public), text: 'Community Feed'),
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Share Yield'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FeedTab(),
          _PostTab(),
        ],
      ),
    );
  }
}

// ─── Feed Tab (GET) ────────────────────────────────────────────────────────────

class _FeedTab extends StatefulWidget {
  const _FeedTab();

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  List<EcoEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both list and map responses
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data.containsKey('data')) {
          list = data['data'] as List;
        } else if (data is Map) {
          list = [data];
        }
        setState(() {
          _entries = list.map((e) => EcoEntry.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchEntries,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.grass, size: 64, color: Color(0xFFA5D6A7)),
            const SizedBox(height: 12),
            const Text('No entries yet. Be the first to share!',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchEntries,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _fetchEntries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final e = _entries[index];
          return _EcoCard(entry: e, index: index);
        },
      ),
    );
  }
}

class _EcoCard extends StatelessWidget {
  final EcoEntry entry;
  final int index;
  const _EcoCard({required this.entry, required this.index});

  static const _colors = [
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFF00838F),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Text(
            entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        title: Row(
          children: [
            Text(entry.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.location_on, size: 14, color: Colors.grey),
            Text(entry.location,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(entry.message,
              style: const TextStyle(fontSize: 14, height: 1.4)),
        ),
      ),
    );
  }
}

// ─── Post Tab (POST) ───────────────────────────────────────────────────────────

class _PostTab extends StatefulWidget {
  const _PostTab();

  @override
  State<_PostTab> createState() => _PostTabState();
}

class _PostTabState extends State<_PostTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _submitting = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _successMsg = null;
      _errorMsg = null;
    });
    try {
      final body = jsonEncode({
        'name': _nameCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
      });
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _successMsg = '✅ Yield shared successfully!';
          _submitting = false;
        });
        _nameCtrl.clear();
        _locationCtrl.clear();
        _messageCtrl.clear();
      } else {
        setState(() {
          _errorMsg = 'Error ${response.statusCode}: ${response.body}';
          _submitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Failed to submit: $e';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.eco, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Share Your Yield',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('Connect your local harvest to the global EcoYield network',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name
            _buildLabel('Your Name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              decoration: _inputDecoration('e.g. Neeraj', Icons.person_outline),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            // Location
            _buildLabel('Location'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _locationCtrl,
              decoration:
                  _inputDecoration('e.g. Kerala, India', Icons.location_on_outlined),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Location is required' : null,
            ),
            const SizedBox(height: 16),

            // Message
            _buildLabel('Yield / Message'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 4,
              decoration: _inputDecoration(
                  'Share what you grew, harvested, or discovered...',
                  Icons.message_outlined),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Message is required' : null,
            ),
            const SizedBox(height: 24),

            // Feedback
            if (_successMsg != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: Text(_successMsg!,
                    style: const TextStyle(color: Color(0xFF2E7D32))),
              ),
            if (_errorMsg != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Text(_errorMsg!,
                    style: const TextStyle(color: Color(0xFFC62828))),
              ),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'Sharing...' : 'Share to Network'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF2E7D32)));

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF66BB6A)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      );
}