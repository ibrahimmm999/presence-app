import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('name') ?? '';
      _imagePath = prefs.getString('imagePath');
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('imagePath', _imagePath ?? '');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
      _saveProfile(); // Simpan foto profil yang dipilih
    }
  }

  Future<void> _deleteImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _imagePath = null;
    });
    await prefs.remove('imagePath'); // Hapus path gambar dari SharedPreferences
  }

  void _logout() {
    // Implementasi log out di sini
    print("User logged out");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          _imagePath != null ? FileImage(File(_imagePath!)) : null,
                      child: _imagePath == null
                          ? Icon(
                              Icons.add_a_photo,
                              size: 50,
                            )
                          : null,
                    ),
                  ),
                  if (_imagePath != null)
                    Positioned(
                      bottom: -10,
                      right: -10,
                      child: IconButton(
                        icon: Icon(Icons.delete, color: Colors.blue),
                        onPressed: _deleteImage,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              enabled: false, // Membuat TextField tidak dapat diedit
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _saveProfile(); // Simpan data profil
                print("Name: ${_nameController.text}");
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
