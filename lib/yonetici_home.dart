import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class YoneticiHome extends StatefulWidget {
  @override
  State<YoneticiHome> createState() => _YoneticiHomeState();
}

class _YoneticiHomeState extends State<YoneticiHome> {
  final _aciklamaController = TextEditingController();
  final _odulController = TextEditingController();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? _kullaniciAdi;

  @override
  void initState() {
    super.initState();
    _kullaniciAdi = _auth.currentUser?.email?.split('@')[0];
  }

  Future<void> _gorevOlustur() async {
    final aciklama = _aciklamaController.text.trim();
    final odul = _odulController.text.trim();
    if (aciklama.isEmpty || odul.isEmpty) return;

    final uid = _auth.currentUser!.uid;

    await _firestore.collection('gorevler').add({
      'aciklama': aciklama,
      'odul': odul,
      'tanimlayanId': uid,
      'kabulEdenler': [],
      'kazananId': null,
      'olusturmaTarihi': FieldValue.serverTimestamp(),
    });

    _aciklamaController.clear();
    _odulController.clear();
  }

  Future<String> getEmailFromUid(String uid) async {
    try {
      final userDoc =
          await _firestore.collection('kullanicilar').doc(uid).get();
      return userDoc.data()?['email'] ?? uid;
    } catch (e) {
      return 'Erişim hatası';
    }
  }

  Future<void> _gorevSil(String gorevId) async {
    await _firestore.collection('gorevler').doc(gorevId).delete();
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final date = timestamp.toDate();
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEAF6FF), // açık mavi zemin
      appBar: AppBar(
        title: Text('Yönetici Paneli'),
        backgroundColor: Color(0xFF91C8E4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_kullaniciAdi != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'Hoş geldin, $_kullaniciAdi!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF548CFF),
                  ),
                ),
              ),
            TextField(
              controller: _aciklamaController,
              decoration: InputDecoration(
                labelText: 'Görev Açıklaması',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _odulController,
              decoration: InputDecoration(
                labelText: 'Ödül (örnek: 1000 TL çeki)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _gorevOlustur,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF548CFF),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Görev Oluştur',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('gorevler')
                    .orderBy('olusturmaTarihi', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();

                  final gorevler = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: gorevler.length,
                    itemBuilder: (context, index) {
                      final gorev = gorevler[index];
                      final aciklama = gorev['aciklama'] ?? '';
                      final odul = gorev['odul'] ?? '';
                      final tarih = gorev['olusturmaTarihi'];
                      final String? kazananId = gorev['kazananId'];
                      final bool tamamlandi = kazananId != null;

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        color: tamamlandi
                            ? Colors.green.shade100
                            : Color(0xFFF7F9FC),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Görev: $aciklama',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _gorevSil(gorev.id),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text('Ödül: $odul'),
                              Text('Oluşturma: ${formatTimestamp(tarih)}'),
                              SizedBox(height: 8),
                              Text(
                                tamamlandi ? 'Kazanan:' : 'Durum:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              tamamlandi
                                  ? FutureBuilder<String>(
                                      future: getEmailFromUid(kazananId!),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Text('Yükleniyor...');
                                        }
                                        if (snapshot.hasError) {
                                          return Text(
                                              'Hata: ${snapshot.error}');
                                        }
                                        return Text(snapshot.data ??
                                            kazananId);
                                      },
                                    )
                                  : Text('Henüz tamamlanmadı'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
