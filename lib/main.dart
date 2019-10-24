import 'package:admin_panel/utils/FromJSON.dart' as prefix0;
import 'package:flutter/material.dart';
import 'package:gradient_widgets/gradient_widgets.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:dio/dio.dart';
import './components/Panel.dart';
import 'package:flutter/cupertino.dart';
import './utils/FromJSON.dart';
import './utils/Trending.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool isLoading = false;
  Dio dio = new Dio();
  @override
  void initState() {
    // TODO: implement initState
    dio.options.baseUrl = "https://cybersvn.team/api";
    dio.options.connectTimeout = 5000; //5s
    dio.options.receiveTimeout = 6000;
    dio.options.validateStatus = (status) {
      return status < 500;
    };
    super.initState();
  }

  void login(String user, String password) async {
    setState(() {
      isLoading = true;
    });
    //String url = 'http://192.168.1.5:5000/api/app-login';
    //var response = await http.post(url,body:{'user':user,'password':password});
    Response response;
    FormData formData = new FormData.from({
      "user": user,
      "password": password,
    });
    try {
      response = await dio.post("/app-login", data: formData).then((res) {
        setState(() {
          isLoading = false;
        });
        FromStatus code = new FromStatus.fromJson(res.data);
        print(code.status + '//' + code.token);
        if (code.status != 'Unauthorized')
          return Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => Trending()));
        else
          return null;
      });
    } catch (err) {
      print(err);
    }
  }

  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    userCtrl.dispose();
    passCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: new Stack(
      children: <Widget>[
        new Image(
          width: size.width,
          height: size.height,
          fit: BoxFit.cover,
          image: AssetImage('assets/background.jpg'),
        ),
        new Center(
            child: isLoading ? new CircularProgressIndicator() : formLogin()),
      ],
    ));
  }

  Widget formLogin() {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
                color: Colors.black12,
                offset: Offset(0.0, 15.0),
                blurRadius: 15.0),
            BoxShadow(
                color: Colors.black12,
                offset: Offset(0.0, -10.0),
                blurRadius: 10.0),
          ]),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("Login",
                style: TextStyle(
                    fontSize: 25,
                    fontFamily: "Poppins-Bold",
                    letterSpacing: .6)),
            SizedBox(
              height: 25,
            ),
            Text("Username",
                style: TextStyle(fontFamily: "Poppins-Medium", fontSize: 18)),
            TextField(
              controller: userCtrl,
              decoration: InputDecoration(
                  hintText: "username",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12.0)),
            ),
            SizedBox(
              height: 25,
            ),
            Text("PassWord",
                style: TextStyle(fontFamily: "Poppins-Medium", fontSize: 18)),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                  hintText: "Password",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12.0)),
            ),
            SizedBox(
              height: 25,
            ),
            GradientButton(
              increaseHeightBy: 10,
              increaseWidthBy: 50,
              child: Text('Login'),
              callback: () {
                login(userCtrl.text, passCtrl.text);
              },
              gradient: Gradients.coldLinear,
              shadowColor: Gradients.backToFuture.colors.last.withOpacity(0.25),
            ),
          ],
        ),
      ),
    );
  }
}
