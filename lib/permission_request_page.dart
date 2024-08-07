import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestForm extends StatefulWidget {
  @override
  _RequestFormState createState() => _RequestFormState();
}

class _RequestFormState extends State<RequestForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  bool _approveRequest = false;
  bool _rejectRequest = false;
  bool _isSubmitted = false;
  String _status = 'Menunggu verifikasi...';

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = _idController.text;
    _nameController.text = prefs.getString('name_$id') ?? '';
    _dayController.text = prefs.getString('day_$id') ?? '';
    _startTimeController.text = prefs.getString('startTime_$id') ?? '';
    _endTimeController.text = prefs.getString('endTime_$id') ?? '';
    setState(() {
      _isSubmitted = prefs.getBool('isSubmitted_$id') ?? false;
      _status = prefs.getString('status_$id') ?? 'Menunggu verifikasi...';
      _approveRequest = prefs.getBool('approveRequest_$id') ?? false;
      _rejectRequest = prefs.getBool('rejectRequest_$id') ?? false;
    });
  }

  Future<void> _saveFormData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = _idController.text;
    await prefs.setString('name_$id', _nameController.text);
    await prefs.setString('day_$id', _dayController.text);
    await prefs.setString('startTime_$id', _startTimeController.text);
    await prefs.setString('endTime_$id', _endTimeController.text);
    await prefs.setBool('approveRequest_$id', _approveRequest);
    await prefs.setBool('rejectRequest_$id', _rejectRequest);
    await prefs.setString('status_$id', _status);
    await prefs.setBool('isSubmitted_$id', _isSubmitted);

    // Save form data for the verifier (IDTI025)
    await prefs.setString('name_IDTI025', _nameController.text);
    await prefs.setString('day_IDTI025', _dayController.text);
    await prefs.setString('startTime_IDTI025', _startTimeController.text);
    await prefs.setString('endTime_IDTI025', _endTimeController.text);
    await prefs.setBool('isSubmitted_IDTI025', true);
    await prefs.setString('status_IDTI025', 'Menunggu verifikasi...');
  }

  Future<void> _submitRequest() async {
    final name = _nameController.text;
    final id = _idController.text;
    final day = _dayController.text;
    final startTime = _startTimeController.text;
    final endTime = _endTimeController.text;

    if (name.isEmpty || id.isEmpty || day.isEmpty || startTime.isEmpty || endTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all the fields')),
      );
      return;
    }

    final message = 'Halo kak, saya $name dengan id $id terdapat kesalahan absen untuk hari $day. '
                    'Saya masuk jam $startTime dan pulang jam $endTime.' 
                    'Ingin melakukan konfirmasi';

    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/6285838999169?text=$encodedMessage';

    if (await canLaunch(url)) {
      await launch(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening WhatsApp with your message')),
      );
      setState(() {
        _isSubmitted = true;
        _status = 'Menunggu verifikasi...';
      });
      await _saveFormData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Permission Request Form'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              enabled: !_isSubmitted,
            ),
            TextField(
              controller: _idController,
              decoration: InputDecoration(labelText: 'ID'),
              onChanged: (value) => _loadFormData(),
              enabled: !_isSubmitted,
            ),
            TextField(
              controller: _dayController,
              decoration: InputDecoration(labelText: 'Day'),
              enabled: !_isSubmitted,
            ),
            TextField(
              controller: _startTimeController,
              decoration: InputDecoration(labelText: 'Start Time'),
              enabled: !_isSubmitted,
            ),
            TextField(
              controller: _endTimeController,
              decoration: InputDecoration(labelText: 'End Time'),
              enabled: !_isSubmitted,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitted ? null : _submitRequest,
              child: Text('Submit'),
            ),
            if (_approveRequest || _rejectRequest)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _approveRequest ? 'Accepted' : 'Rejected',
                  
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: RequestForm()));
