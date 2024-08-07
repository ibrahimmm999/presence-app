import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:presensi/models/home-response.dart';
import 'package:presensi/notifi_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as myHttp;
import 'package:presensi/collection.dart';
import 'package:presensi/presensi-util.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:location/location.dart';
import 'package:dio/dio.dart';
import 'package:android_package_installer/android_package_installer.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'shared_preferences_helper.dart';
import 'profile_page.dart'; // Import file profile_page.dart
import 'permission_request_page.dart';
import 'verifikasi_absen.dart';
import 'package:presensi/notifications.dart';
import 'package:presensi/usernotifications.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _name, _token;
  HomeResponseModel? homeResponseModel;
  Datum? hariIni;
  List<Datum> riwayat = [];
  List<dynamic> _notifications = [];
  List<dynamic> _usernotifications = [];
  bool isPresensiMasuk = false;
  bool isPresensiKeluar = false;
  String? previousLatitude;
  String? previousLongitude;
  String _latestVersion = '';
  String _updateUrl = '';
  
  bool isMockLocation = false;
  Location location = Location();
  double? _latitude;
  double? _longitude;
  ProgressDialog? _progressDialog;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });
    _name = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("name") ?? "";
    });
    _checkPresensiStatus();
  }

  Future<void> _checkForUpdate() async {
    try {
      final response = await myHttp.get(
          Uri.parse('https://datatech.co.id/indexLaravel.php/check-update'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _latestVersion = data['version'];
        _updateUrl = data['url'];

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_latestVersion != currentVersion) {
          _showUpdateDialog();
        }
      }
    } catch (e) {
      print('Failed to check for update: $e');
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Available'),
        content: Text(
            'A new version of the app is available. Please update to version $_latestVersion.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Later'),
          ),
          TextButton(
            onPressed: _downloadAndInstallApk,
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstallApk() async {
    _progressDialog = ProgressDialog(
      context,
      type: ProgressDialogType.download,
      textDirection: TextDirection.rtl,
      isDismissible: true,
    );
    _progressDialog!.style(
      message: 'Downloading Update...',
      borderRadius: 10.0,
      backgroundColor: Colors.white,
      elevation: 10.0,
      messageTextStyle: const TextStyle(
          color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600),
    );
    _progressDialog!.show();
    final directory = await getExternalStorageDirectory();
    final savePath = '${directory!.path}/presensi.apk';

    try {
      await Dio().download(
        _updateUrl,
        savePath,
        onReceiveProgress: (received, total) {
          print('Received: $received, Total: $total');
        },
      );
      _progressDialog!.hide();
      print('Downloaded APK to: $savePath');

      await AndroidPackageInstaller.installApk(apkFilePath: savePath);
    } catch (e) {
      _progressDialog!.hide();
      print('Failed to download APK: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download update.'),
        ),
      );
    }
  }

  Future<LocationData?> _currentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    LocationData locationData = await location.getLocation();
    bool isMockLocation = await _isMockLocation(locationData);
    if (isMockLocation) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lokasi Palsu Terdeteksi!')));
      return null;
    }

    return locationData;
  }

  Future<bool> _isMockLocation(LocationData locationData) async {
    if (locationData.isMock != null) {
      return locationData.isMock!;
    }
    return false;
  }

  Future _checkPresensiStatus() async {
    await getData();

    if (homeResponseModel != null && homeResponseModel!.data.isNotEmpty) {
      final hariIniData =
          homeResponseModel!.data.firstOrNull((presensi) => presensi.isHariIni);
      if (hariIniData != null) {
        if (hariIniData.masuk != null) {
          setState(() {
            isPresensiMasuk = true;
            isPresensiKeluar = true;
          });
        }
      }
    }
  }

  Future getData() async {
    final Map<String, String> headres = {
      'Authorization': 'Bearer ' + await _token
    };
    var response = await myHttp.get(
        Uri.parse('https://datatech.co.id/indexLaravel.php/api/get-presensi'),
        headers: headres);

    homeResponseModel = HomeResponseModel.fromJson(json.decode(response.body));
    riwayat.clear();
    homeResponseModel!.data.forEach((element) {
      if (element.isHariIni) {
        hariIni = element;
      } else {
        riwayat.add(element);
      }
    });
  }

  Future<void> _presensiMasuk() async {
    final LocationData? locationData = await _currentLocation();
    if (locationData != null) {
      _latitude = locationData.latitude;
      _longitude = locationData.longitude;

      if (_latitude != null && _longitude != null && !isMockLocation) {
        final String token = await _token;
        final result =
            await PresensiUtil.savePresensi(_latitude!, _longitude!, token);
        if (result['success']) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(result['message'])));
          setState(() {
            isPresensiMasuk = true;
          });
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(result['message'])));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Tidak dapat mendapatkan lokasi saat ini.')));
      }
    }
  }

  Future<void> _presensiKeluar() async {
    final LocationData? locationData = await _currentLocation();
    if (locationData != null) {
      _latitude = locationData.latitude;
      _longitude = locationData.longitude;

      if (_latitude != null && _longitude != null && !isMockLocation) {
        final String token = await _token;
        final result =
            await PresensiUtil.savePresensi(_latitude!, _longitude!, token);
        if (result['success']) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(result['message'])));
          setState(() {
            isPresensiKeluar = true;
          });
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(result['message'])));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Tidak dapat mendapatkan lokasi saat ini.')));
      }
    }
  }
  
  void _notificationAbsenRequest() {
    // Navigasi ke halaman permohonan perbaikan absensi
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationsPage ()),
    );
  }

  void _usernotificationAbsenRequest() {
    // Navigasi ke halaman permohonan perbaikan absensi
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserNotificationsPage ()),
    );
  }

  void _openAbsenceCorrectionRequest() {
    // Navigasi ke halaman permohonan perbaikan absensi
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RequestForm()),
    );
  }

  void _editPresensi(Datum presensi, bool isSubmitted) async {
  // Cek apakah permohonan perbaikan absen disetujui
  if (isSubmitted = true) {
    // Navigasi ke halaman untuk mengedit jam presensi
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPresensiPage(presensi: presensi),
      ),
    );
  } else {
    // Tampilkan pesan atau lakukan tindakan lain jika tidak disetujui
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Permohonan perbaikan absen belum disetujui.'),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final bool? result = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Konfirmasi'),
              content: Text('Apakah Anda yakin ingin keluar?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Tidak'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Ya'),
                ),
              ],
            );
          },
        );
        return result ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home Page'),
          actions: <Widget>[
            FutureBuilder<String>(
              future: _name,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Icon(Icons.error);
                } else if (snapshot.hasData) {
                  final String? userName = snapshot.data;
                  return PopupMenuButton<String>(
                    onSelected: (String value) {
                      if (value == 'profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfilePage()),
                        );
                      } else if (value == 'absence_correction') {
                        _openAbsenceCorrectionRequest();
                      } else if (value == 'notification_absen') {
                        _notificationAbsenRequest();
                      } else if (value == 'user_notification') {
                        _usernotificationAbsenRequest();
                      } else if (value == 'absence_verification') {
                        Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => VerifikasiAbsen()),
                        );
                      }
                      
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'profile',
                          child: Text('Profile'),
                        ),
                        PopupMenuItem<String>(
                          value: 'absence_correction',
                          child: Text('Permohonan Perbaikan Absensi'),
                        ),
                         PopupMenuItem<String>(
                          value: 'user_notification',
                          child: Text('Notifikasi'),
                        ),
                        if (userName == 'Fina Valentina')
                        PopupMenuItem<String>(
                          value: 'notification_absen',
                          child: Text('Notifikasi Untuk Karyawan'),
                        ),
                        if (userName == 'Fina Valentina')
                          PopupMenuItem<String>(
                            value: 'absence_verification',
                            child: Text('Verifikasi Absensi'),
                          ),

                          
                      ];
                    },
                  );
                } else {
                  return Icon(Icons.error);
                }
              },
            ),
          ],
        ),
        body: FutureBuilder(
          future: getData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder(
                        future: _name,
                        builder: (BuildContext context,
                            AsyncSnapshot<String> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else {
                            if (snapshot.hasData) {
                              return Text(snapshot.data!,
                                  style: TextStyle(fontSize: 18));
                            } else {
                              return Text("-",
                                  style: TextStyle(fontSize: 18));
                            }
                          }
                        },
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        width: 400,
                        decoration: BoxDecoration(color: Colors.blue[800]),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(hariIni?.tanggal ?? '-',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                              SizedBox(
                                height: 30,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(hariIni?.masuk ?? '-',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24)),
                                      Text("Masuk",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16))
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(hariIni?.pulang ?? '-',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24)),
                                      Text("Pulang",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16))
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text("Riwayat Presensi"),
                      Expanded(
                        child: ListView.builder(
                          itemCount: riwayat.length,
                          itemBuilder: (context, index) => Card(
                            child: ListTile(
                              leading: Text(riwayat[index].tanggal),
                              title: Row(
                                children: [
                                  Column(
                                    children: [
                                      Text(riwayat[index].masuk,
                                          style: TextStyle(fontSize: 18)),
                                      Text("Masuk",
                                          style: TextStyle(fontSize: 14))
                                    ],
                                  ),
                                  SizedBox(width: 20),
                                  Column(
                                    children: [
                                      Text(riwayat[index].pulang,
                                          style: TextStyle(fontSize: 18)),
                                      Text("Pulang",
                                          style: TextStyle(fontSize: 14))
                                    ],
                                  ),
                                ],
                              ),
                              
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!isPresensiMasuk)
              FloatingActionButton.extended(
                onPressed: _presensiMasuk,
                label: Text('Presensi Masuk'),
                icon: Icon(Icons.login),
              ),
            SizedBox(height: 16),
            if (isPresensiKeluar)
              FloatingActionButton.extended(
                onPressed: _presensiKeluar,
                label: Text('Presensi Pulang'),
                icon: Icon(Icons.logout),
              ),
          ],
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

class AbsenceCorrectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Permohonan Perbaikan Absensi'),
      ),
      body: Center(
        child: Text('Halaman permohonan perbaikan absensi'),
      ),
    );
  }
}

class EditPresensiPage extends StatelessWidget {
  final Datum presensi;
  final _formKey = GlobalKey<FormState>();
  final _tanggalController = TextEditingController();
  final _jamMasukController = TextEditingController();
  final _jamKeluarController = TextEditingController();

  EditPresensiPage({required this.presensi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Presensi'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _tanggalController,
                  decoration: InputDecoration(
                    labelText: 'Tanggal',
                    hintText: 'YYYY-MM-DD',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a date';
                    }
                    // Add more validation for date format if needed
                    return null;
                  },
                ),
              SizedBox(height: 20),
                TextFormField(
                  controller: _jamMasukController,
                  decoration: InputDecoration(
                    labelText: 'Jam Masuk',
                    hintText: 'HH:MM',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a time';
                    }
                    // Add more validation for time format if needed
                    return null;
                  },
                ),

              SizedBox(height: 20),
                TextFormField(
                  controller: _jamKeluarController,
                  decoration: InputDecoration(
                    labelText: 'Jam Pulang',
                    hintText: 'HH:MM',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a time';
                    }
                    
                    return null;
                  },
                ),

                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      // Process data
                      print('Tanggal: ${_tanggalController.text}');
                      print('Jam Masuk: ${_jamMasukController.text}');
                      print('Jam Pulang: ${_jamKeluarController.text}');
                    }
                  },
                  child: Text('Save'),
                ), 
              ],
            ),
          ),
        ),
      ),
    );
  }
}
