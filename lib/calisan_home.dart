import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalisanHome extends StatefulWidget {
  @override
  _CalisanHomeState createState() => _CalisanHomeState();
}

class _CalisanHomeState extends State<CalisanHome> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _gorevKabulEt(String gorevId) async {
    final uid = _auth.currentUser!.uid;
    final docRef = _firestore.collection('gorevler').doc(gorevId);
    final doc = await docRef.get();
    final kabulEdenler = List<String>.from(doc['kabulEdenler'] ?? []);

    if (!kabulEdenler.contains(uid)) {
      await docRef.update({
        'kabulEdenler': FieldValue.arrayUnion([uid])
      });
      setState(() {});
    }
  }

  Future<void> _gorevTamamla(String gorevId) async {
    final uid = _auth.currentUser!.uid;
    final docRef = _firestore.collection('gorevler').doc(gorevId);
    final doc = await docRef.get();
    final kazananId = doc.data()?['kazananId'];

    if (kazananId == null) {
      await docRef.update({'kazananId': uid});
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bu görev zaten tamamlandı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kullanici = _auth.currentUser;
    final isim = kullanici != null ? kullanici.email!.split('@')[0] : 'Kullanıcı';
    final benimUid = kullanici!.uid;

    return Scaffold(
      backgroundColor: Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text('Çalışan Paneli'),
        backgroundColor: Color(0xFF91C8E4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Hoş geldin, $isim!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('gorevler')
                  .orderBy('olusturmaTarihi', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final gorevler = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: gorevler.length,
                  itemBuilder: (context, index) {
                    final gorev = gorevler[index];
                    final data = gorev.data() as Map<String, dynamic>;
                    final aciklama = data['aciklama'] ?? '';
                    final odul = data['odul'] ?? '';
                    final gorevId = gorev.id;

                    final kabulEdenler = List<String>.from(data['kabulEdenler'] ?? []);
                    final kazananId = data['kazananId'] as String?;
                    final bool gorevTamamlandi = kazananId != null;
                    final bool kazananBenMiyim = kazananId == benimUid;
                    final bool benKabulEttim = kabulEdenler.contains(benimUid);

                    return Card(
                      color: gorevTamamlandi
                          ? (kazananBenMiyim ? Color(0xFFC5FAD5) : Color(0xFFE0E0E0))
                          : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Görev: $aciklama',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Ödül: $odul',
                                style: TextStyle(color: Colors.black54, fontSize: 14)),
                            SizedBox(height: 12),

                            if (benKabulEttim)
                              Text('Durum: Kabul edildi',
                                  style: TextStyle(color: Color(0xFF5DADE2), fontWeight: FontWeight.w600)),

                            if (!benKabulEttim && !gorevTamamlandi)
                              Text('Durum: Henüz kabul edilmedi',
                                  style: TextStyle(color: Colors.grey)),

                            SizedBox(height: 12),

                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: (!gorevTamamlandi && !benKabulEttim)
                                      ? () => _gorevKabulEt(gorevId)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF82CD47),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Kabul Et'),
                                ),
                                SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: (!gorevTamamlandi && benKabulEttim)
                                      ? () => _gorevTamamla(gorevId)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF548CFF),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Tamamla'),
                                ),
                              ],
                            ),

                            SizedBox(height: 12),

                            if (kazananId != null)
                              FutureBuilder<DocumentSnapshot>(
                                future: _firestore.collection('kullanicilar').doc(kazananId).get(),
                                builder: (context, snap) {
                                  if (!snap.hasData) return Text('Kazanan: yükleniyor...');
                                  final email = snap.data!.get('email') ?? kazananId;
                                  return Text(
                                    'Kazanan: $email',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade700),
                                  );
                                },
                              ),
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
    );
  }
}
