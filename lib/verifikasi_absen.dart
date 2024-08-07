import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerifikasiAbsen extends StatefulWidget {
  @override
  _VerifikasiAbsenState createState() => _VerifikasiAbsenState();
}

class _VerifikasiAbsenState extends State<VerifikasiAbsen> {
  List<Map<String, String>> _requestList = [];
  String _name = '';
  String _id = 'IDTI025';
  String _day = '';
  String _startTime = '';
  String _endTime = '';

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _dateController = TextEditingController();
  final _entryTimeController = TextEditingController();
  final _exitTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name_$_id') ?? '';
      _day = prefs.getString('day_$_id') ?? '';
      _startTime = prefs.getString('startTime_$_id') ?? '';
      _endTime = prefs.getString('endTime_$_id') ?? '';
    });
    _loadRequestList();
  }

  Future<void> _loadRequestList() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _requestList = prefs.getStringList('requestList')?.map((item) {
        final data = item.split(',');
        return {
          'name': data[0],
          'day': data[1],
          'startTime': data[2],
          'endTime': data[3],
          'id': data[4],
        };
      }).toList() ?? [];
    });
  }

  Future<void> _saveRequestList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('requestList', _requestList.map((item) {
      return '${item['name']},${item['day']},${item['startTime']},${item['endTime']},${item['id']}';
    }).toList());
  }

  Future<void> _saveSalahAbsen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('requestList', _requestList.map((item) {
      return '${item['name']},${item['day']},${item['startTime']},${item['endTime']},${item['id']}';
    }).toList());
  }

  Future<void> _clearFormData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('name_$_id');
    await prefs.remove('day_$_id');
    await prefs.remove('startTime_$_id');
    await prefs.remove('endTime_$_id');
    await prefs.remove('isSubmitted_$_id');
    await prefs.remove('status_$_id');
  }

  Future<void> _updateStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('status_$_id', status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request $status')),
    );
    await _clearFormData();
    setState(() {
      _name = '';
      _day = '';
      _startTime = '';
      _endTime = '';
    });
  }

  Future<void> _approveRequest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSubmitted_$_id', true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request approved')),
    );

    await _updateStatus('approved');
    await _removeCurrentRequest();
  }

  Future<void> _rejectRequest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSubmitted_$_id', true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request rejected')),
    );

    await _updateStatus('rejected');
    await _removeCurrentRequest();
  }

  Future<void> _removeCurrentRequest() async {
    _requestList.removeWhere((item) => item['id'] == _id);
    await _saveRequestList();
    _loadFormData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Attendance'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $_name'),
            Text('Day: $_day'),
            Text('Start Time: $_startTime'),
            Text('End Time: $_endTime'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _approveRequest,
                  child: Text('Approve'),
                ),
                ElevatedButton(
                  onPressed: _rejectRequest,
                  child: Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: VerifikasiAbsen()));
