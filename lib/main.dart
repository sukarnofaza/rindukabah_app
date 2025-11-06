import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io'; // Tambah ini

void main() {
  runApp(const RindukabahApp());
}

class RindukabahApp extends StatelessWidget {
  const RindukabahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rindu Kabah',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeContentPage(),
    const AgendaPage(),
    const GaleriPage(),
    const DutaPage(),
    const LoginPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://rindukabah.co.id/gambar/logoo.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.mosque, color: Colors.green, size: 24);
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'Rindu Kabah',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.green,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Galeri',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Duta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: 'Login',
          ),
        ],
      ),
    );
  }
}

// ========== HOME CONTENT PAGE ==========
class HomeContentPage extends StatefulWidget {
  const HomeContentPage({super.key});

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  List<dynamic> _paketUmroh = [];
  bool _isLoadingPaket = true;
  bool _errorLoadingPaket = false;
  String _errorMessage = '';
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkInternetAndLoadData();
  }

  // Fungsi cek internet tanpa package external
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }

  Future<void> _checkInternetAndLoadData() async {
    final hasInternet = await _checkInternetConnection();
    setState(() {
      _hasInternet = hasInternet;
    });

    if (!hasInternet) {
      setState(() {
        _isLoadingPaket = false;
        _errorLoadingPaket = true;
        _errorMessage = 'Tidak ada koneksi internet. Periksa koneksi Anda.';
      });
      // Auto load dummy data jika tidak ada internet
      _loadDummyData();
      return;
    }

    await _loadPaketUmrohFromAPI();
  }

  Future<void> _loadPaketUmrohFromAPI() async {
    try {
      setState(() {
        _isLoadingPaket = true;
        _errorLoadingPaket = false;
        _errorMessage = '';
      });

      // Coba URL yang berbeda
      final urls = [
        'https://rindukabah.co.id/api_paket_umroh_json.php?limit=3',
        'https://rindukabah.co.id/api_paket_umroh.php?limit=3',
      ];

      http.Response? response;
      String usedUrl = '';

      for (String url in urls) {
        try {
          usedUrl = url;
          response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
          if (response.statusCode == 200) break;
        } catch (e) {
          print('Failed to load from $url: $e');
          continue;
        }
      }

      if (response == null || response.statusCode != 200) {
        throw Exception('Tidak dapat terhubung ke server. Status: ${response?.statusCode}');
      }

      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        setState(() {
          _paketUmroh = data['data'] ?? [];
          _isLoadingPaket = false;
        });
      } else {
        throw Exception('API error: ${data['error']}');
      }
    } catch (e) {
      print('Error loading paket umroh: $e');
      setState(() {
        _isLoadingPaket = false;
        _errorLoadingPaket = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        
        // Auto load dummy data jika API gagal
        if (_paketUmroh.isEmpty) {
          _loadDummyData();
        }
      });
    }
  }

  String _getFlyerUrl(dynamic flyer) {
    if (flyer == null || flyer.toString().isEmpty || flyer.toString() == 'null') {
      return 'https://via.placeholder.com/300x400.png?text=No+Image';
    }
    
    String flyerUrl = flyer.toString();
    
    if (flyerUrl.startsWith('http')) {
      return flyerUrl;
    } else if (flyerUrl.startsWith('/')) {
      return 'https://rindukabah.co.id$flyerUrl';
    } else {
      return 'https://rindukabah.co.id/duta/admin/flyer/$flyerUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeroSection(),
          _buildPaketUmrohSection(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
      ),
      child: Column(
        children: [
          _hasInternet 
              ? Image.network(
                  'https://rindukabah.co.id/gambar/logoo.png',
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.mosque, size: 80, color: Colors.green);
                  },
                )
              : const Icon(Icons.mosque, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          const Text(
            'Selamat Datang di Rindukabah',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Pelayanan Terbaik, Melayani Sepenuh Hati',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaketUmrohSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.airplane_ticket, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text(
                'Paket Umroh Terbaru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih paket umroh sesuai dengan kebutuhan dan budget Anda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          
          if (!_hasInternet && _paketUmroh.isEmpty)
            _buildNoInternetWidget()
          else if (_errorLoadingPaket && _paketUmroh.isEmpty)
            _buildErrorWidget()
          else if (_isLoadingPaket && _paketUmroh.isEmpty)
            _buildLoadingPaket()
          else if (_paketUmroh.isEmpty)
            _buildEmptyPaket()
          else
            _buildPaketUmrohList(),
          
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () {
                _launchURL('https://rindukabah.co.id/paket_umroh.php');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Lihat Semua Paket'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoInternetWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, size: 60, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Tidak Ada Koneksi Internet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Menampilkan data contoh. Periksa koneksi internet Anda.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _checkInternetAndLoadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat data paket umroh',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _loadPaketUmrohFromAPI,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _loadDummyData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Data Contoh'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _loadDummyData() {
    setState(() {
      _paketUmroh = [
        {
          'id': '1',
          'nama_paket': 'Paket Umroh Berkah',
          'durasi': '9',
          'harga_quad': '32000000',
          'tanggal_berangkat': '2024-03-01',
          'tanggal_pulang': '2024-03-09',
          'status': 'OPEN',
          'flyer': '/duta/admin/flyer/umroh_berkah.jpg'
        },
        {
          'id': '2', 
          'nama_paket': 'Land Arrangement Full Ramadhan',
          'durasi': '0',
          'harga_quad': '16900000',
          'tanggal_berangkat': '2024-04-01',
          'tanggal_pulang': '2024-04-10',
          'status': 'OPEN',
          'flyer': '/duta/admin/flyer/ramadhan.jpg'
        }
      ];
      _isLoadingPaket = false;
      _errorLoadingPaket = false;
    });
  }

  Widget _buildLoadingPaket() {
    return Column(
      children: List.generate(2, (index) => 
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              height: 120,
              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 20,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 150,
                          height: 16,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 120,
                          height: 16,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPaket() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.airplane_ticket, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada paket umroh tersedia saat ini',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaketUmrohList() {
    return Column(
      children: _paketUmroh.map((paket) => _buildPaketUmrohCard(paket)).toList(),
    );
  }

  Widget _buildPaketUmrohCard(Map<String, dynamic> paket) {
    final isClosed = paket['status'] == 'CLOSED';
    final flyerUrl = _getFlyerUrl(paket['flyer']);
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _hasInternet 
                    ? Image.network(
                        flyerUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.airplane_ticket, size: 30, color: Colors.grey),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.airplane_ticket, size: 30, color: Colors.grey),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paket['nama_paket']?.toString() ?? 'Nama Paket',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatDate(paket['tanggal_berangkat']) ?? '-'} - ${_formatDate(paket['tanggal_pulang']) ?? '-'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        '${paket['durasi']?.toString() ?? '0'} Hari',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${_formatCurrency(paket['harga_quad'] ?? 0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isClosed ? null : () {
                            _showPackageDetail(paket);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text('Detail'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isClosed ? null : () {
                            _launchURL('https://rindukabah.co.id/pendaftaran.php?id_paket=${paket['id']}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text('Daftar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPackageDetail(Map<String, dynamic> paket) {
    final flyerUrl = _getFlyerUrl(paket['flyer']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(paket['nama_paket']?.toString() ?? 'Detail Paket'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _hasInternet
                      ? Image.network(
                          flyerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.airplane_ticket, size: 50, color: Colors.grey),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.airplane_ticket, size: 50, color: Colors.grey),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailItem('Durasi', '${paket['durasi']} Hari'),
              _buildDetailItem('Tanggal Berangkat', _formatDate(paket['tanggal_berangkat'])),
              _buildDetailItem('Tanggal Pulang', _formatDate(paket['tanggal_pulang'])),
              _buildDetailItem('Harga Quad', 'Rp ${_formatCurrency(paket['harga_quad'])}'),
              _buildDetailItem('Status', paket['status']?.toString() ?? 'AKTIF'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          if (paket['status'] != 'CLOSED')
            ElevatedButton(
              onPressed: () {
                _launchURL('https://rindukabah.co.id/pendaftaran.php?id_paket=${paket['id']}');
                Navigator.pop(context);
              },
              child: const Text('Daftar Sekarang'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty || date.toString() == '0000-00-00') {
      return null;
    }
    
    try {
      final parsedDate = DateTime.parse(date.toString());
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return date.toString();
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    
    final numAmount = amount is int ? amount : 
                     amount is String ? int.tryParse(amount) ?? 0 : 0;
    
    return numAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _launchURL(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }
}

// ========== PAGES LAINNYA ==========
// (AgendaPage, GaleriPage, DutaPage, LoginPage tetap sama seperti sebelumnya)
// Pastikan semua menggunakan pattern yang sama

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Halaman Agenda'),
      ),
    );
  }
}

class GaleriPage extends StatelessWidget {
  const GaleriPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeri'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Halaman Galeri'),
      ),
    );
  }
}

class DutaPage extends StatelessWidget {
  const DutaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duta'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Halaman Duta'),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Halaman Login'),
      ),
    );
  }
}