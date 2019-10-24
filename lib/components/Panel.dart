import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:gradient_widgets/gradient_widgets.dart';
import './../utils/Loader.dart';
import 'package:flutter/cupertino.dart';
import './../utils/FromJSON.dart';

class MemberPanel extends StatefulWidget {
  @override
  _Panel createState() => _Panel();
}

class _Panel extends State<MemberPanel> {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey();
  Dio dio = new Dio();
  StreamController<List<FromMember>> streamMember =
      StreamController<List<FromMember>>.broadcast();
  List<FromMember> list = new List<FromMember>();
  @override
  void initState() {
    dio.options.baseUrl = "https://cybersvn.team/api";
    dio.options.connectTimeout = 5000; //5s
    dio.options.receiveTimeout = 6000;
    dio.options.validateStatus = (status) {
      return status < 500;
    };
    list = getData();
    // TODO: implement initState
    super.initState();
  }

  List<FromMember> getData() {
    FormData formData = new FormData.from({
      "user": 'admin',
      "password": 'password',
    });
    List<FromMember> member = new List<FromMember>();
    dio.post('/app-get-all-user', data: formData).then((res) {
      res.data.forEach((fruit) => member.add(FromMember.fromJson(fruit)));
      streamMember.sink.add(member);
      return member;
    });
    // print(member.length);
    return member;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    streamMember.close();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return Scaffold(
      key: _scaffoldKey,
      drawer: Theme(
        data: Theme.of(context).copyWith(
          // Set the transparency here
          canvasColor: Colors.white.withOpacity(
              0.2), //or any other color you want. e.g Colors.blue.withOpacity(0.5)
        ),
        child: new Drawer(
          child: new ListView(
            children: <Widget>[
              DrawerHeader(
                child: Center(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CircleAvatar(
                          maxRadius: 30,
                          backgroundImage: AssetImage('assets/background.jpg'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: DotLoader(
                          dotOneColor: CupertinoColors.activeBlue,
                          dotTwoColor: CupertinoColors.activeGreen,
                          dotThreeColor: CupertinoColors.activeOrange,
                          duration: Duration(milliseconds: 1000),
                        ),
                      ),
                      Text(
                        'Administrator',
                        style: TextStyle(
                            fontFamily: "Poppins-Medium", fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              GradientButton(
                gradient: Gradients.coldLinear,
                shadowColor: Gradients.hotLinear.colors.last.withOpacity(0.4),
                child: Text("Dashboard"),
                callback: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  //maxRadius: 30,
                  backgroundImage: AssetImage('assets/background.jpg'),
                ),
                title: Text("Phạm Tuấn Khang"),
                subtitle: Text('Member'),
                trailing: Text(
                  "1000",
                  style: TextStyle(
                      color: CupertinoColors.activeOrange, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      body: streamMember.stream == null
          ? CircularProgressIndicator()
          : StreamBuilder(
              initialData: List<FromMember>(),
              stream: streamMember.stream,
              builder: (BuildContext context,
                  AsyncSnapshot<List<FromMember>> snapshot) {
                return ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, position) {
                    return ListTile(
                      leading: CircleAvatar(
                        //maxRadius: 30,
                        backgroundImage:
                            NetworkImage(snapshot.data[position].provider_pic),
                      ),
                      title: Text(snapshot.data[position].name),
                      subtitle: Text('Member Point: ' +
                          snapshot.data[position].point.toString() +
                          "  Permision: " +
                          snapshot.data[position].post_permission.toString()),
                      trailing: FloatingActionButton(
                        child: Icon(snapshot.data[position].post_permission
                            ? Icons.check_circle
                            : Icons.do_not_disturb_on),
                      ),
                    );
                  },
                );
              }),
      floatingActionButton: FloatingActionButton(
        child: new Icon(Icons.menu),
        onPressed: () {
          _scaffoldKey.currentState.openDrawer();
          print(list);
          //getData();
        },
      ),
    );
  }

  void _displayDrawer(BuildContext context) {
    _scaffoldKey.currentState.openDrawer();
  }
}
