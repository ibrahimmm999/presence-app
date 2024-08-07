import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, String>> contacts = [
    {"name": "Fathan", "id" : "IDTI029", "phone": "087885624017"},
    {"name": "Bintang", "id" : "IDTI034", "phone": "0895611496269"},
    {"name": "Fina Valentina", "id" : "IDTI025", "phone": "085838999169"},
    {"name": "Sajidah", "id" : "IDTI026", "phone": "087887887862"},
    {"name": "Fauzie", "id" : "IDTI027", "phone": "0859110114311"},
  ];

  void _openWhatsApp(String phone) async {
    final message = 'Halo, ini merupakan pesan otomatis dari Tim IT Infra Datatech. Pesan ini untuk mengingatkan untuk JANGAN LUPA UNTUK MELAKUKAN ABSEN HARI INI';
    final encodedMessage = Uri.encodeComponent(message);
    final formattedPhone = phone.replaceFirst('0', '+62'); // Add country code for Indonesia
    final url = 'https://wa.me/$formattedPhone?text=$encodedMessage';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Peringatan Absen Karyawan'),
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(contacts[index]['name']!),
              subtitle: Text(contacts[index]['id']!),
              trailing: IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  final phone = contacts[index]['phone']!;
                  _openWhatsApp(phone);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: NotificationsPage()));
