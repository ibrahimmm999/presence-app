import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:presensi/home-page.dart';
import 'package:http/http.dart' as myHttp;
import 'package:presensi/models/login-response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  late Future<String> _name, _token;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });

    _name = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("name") ?? "";
    });
    checkToken(_token, _name);
  }

  checkToken(token, name) async {
    String tokenStr = await token;
    String nameStr = await name;
    if (tokenStr != "" && nameStr != "") {
      Future.delayed(Duration(seconds: 1), () async {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => HomePage()))
            .then((value) {
          setState(() {});
        });
      });
    }
  }

//untuk fetch data login sesuai yang ada di api
  Future login(String email, String password) async {
    LoginResponseModel? loginResponseModel;
    Map<String, String> body = {"email": email, "password": password};

    try {
      var response = await myHttp.post(
        Uri.parse('https://datatech.co.id/indexLaravel.php/api/login'),
        body: body,
      );

      if (response.statusCode == 200) {
        loginResponseModel =
            LoginResponseModel.fromJson(json.decode(response.body));
        saveUser(loginResponseModel.data.token, loginResponseModel.data.name);
      } else if (response.statusCode == 401) {
        showErrorSnackBar("Email atau password salah");
      } else if (response.statusCode == 403) {
        var responseData = jsonDecode(response.body);
        var message = responseData['message'];
        showErrorSnackBar(message);
      } else {
        showErrorSnackBar(
            "Terjadi kesalahan. Kode status: ${response.statusCode}");
      }
    } catch (error) {
      showErrorSnackBar("Terjadi kesalahan: $error");
    }
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

//jika berhasil login data user disimpan supaya user ketika keluar dari aplikasi tidak perlu login ulang
  Future saveUser(token, name) async {
    try {
      print("WELCOME " + token + " | " + name);
      final SharedPreferences pref = await _prefs;
      pref.setString("name", name);
      pref.setString("token", token);
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => HomePage()))
          .then((value) {
        setState(() {});
      });
    } catch (err) {
      print('ERROR :' + err.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err.toString())));
    }
  }

  void checkingPermissionNotification(BuildContext context) {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Allow Notifications'),
                  content: const Text(
                      'Our app would like to send you notifications'),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Don\'t Allow',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        )),
                    TextButton(
                        onPressed: () {
                          AwesomeNotifications()
                              .requestPermissionToSendNotifications()
                              .then((value) {
                            Navigator.pop(context);
                          });
                        },
                        child: const Text(
                          'Allow',
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        )),
                  ],
                ));
      }
    });
  }

//membuat halaman login
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(child: Text("ABSENSI PT. INFRA DATATECH")),
              Center(child: Text("LOGIN")),
              SizedBox(height: 20),
              Text("Employee ID"),
              TextField(
                controller: emailController,
              ),
              SizedBox(height: 20),
              Text("Password"),
              TextField(
                controller: passwordController,
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    login(emailController.text, passwordController.text);
                  },
                  child: Text("Masuk"))
            ],
          ),
        ),
      )),
    );
  }
}
