import 'dart:async';
import 'dart:convert';
import 'package:admin_panel/BLoC/ChartBloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gradient_widgets/gradient_widgets.dart';
import './customIcons.dart';
import 'data.dart';
import 'dart:math';
import '../components/DiskChart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import './../components/Panel.dart';
import 'Loader.dart';
import 'Load5.dart';
import 'package:adhara_socket_io/adhara_socket_io.dart';

const URI = "http://127.0.0.1:1024";

class Trending extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

var cardAspectRatio = 12.0 / 16.0;
var widgetAspectRatio = cardAspectRatio * 1.2;

class _MyAppState extends State<Trending> {
  var currentPage = images.length - 1.0;
  Dio dio = new Dio();
  Timer _timer;
  StreamController<LineTouchResponse> chartcontroller;
  List<FlSpot> cpulistFl = new List<FlSpot>();
  List<FlSpot> ramlistFl = new List<FlSpot>();
  List<FlSpot> netrxlistFl = new List<FlSpot>();
  List<FlSpot> nettxlistFl = new List<FlSpot>();
  //Bloc Chart
  ChartBloc chartBloc = new ChartBloc();
  //Socket io

  List<String> toPrint = ["trying to connect"];
  SocketIOManager manager;
  Map<String, SocketIO> sockets = {};
  Map<String, bool> _isProbablyConnected = {};
  //initSocket
  initSocket(String identifier) async {
    setState(() => _isProbablyConnected[identifier] = true);
    SocketIO socket = await manager.createInstance(SocketOptions(
        //Socket IO server URI
        URI,
        nameSpace: (identifier == "namespaced") ? "/adhara" : "/",
        //Query params - can be used for authentication
        query: {
          "auth": "--SOME AUTH STRING---",
          "info": "new connection from adhara-socketio",
          "timestamp": DateTime.now().toString()
        },
        //Enable or disable platform channel logging
        enableLogging: false,
        transports: [
          Transports.WEB_SOCKET /*, Transports.POLLING*/
        ] //Enable required transport
        ));
    socket.onConnect((data) {
      pprint("connected...");
      pprint(data);
      sendMessage(identifier);
    });
    socket.onConnectError(pprint);
    socket.onConnectTimeout(pprint);
    socket.onError(pprint);
    socket.onDisconnect(pprint);
    socket.on("monitor", (data) {
      chartBloc.UpdateChartCPU(data['cpu']);
      chartBloc.UpdateChartRAM(data['ram']);
      chartBloc.UpdateChartDisk(data['disk_write'], data['disk_read']);
    });
    socket.connect();
    sockets[identifier] = socket;
  }

  disconnect(String identifier) async {
    await manager.clearInstance(sockets[identifier]);
    setState(() => _isProbablyConnected[identifier] = false);
  }

  sendMessage(identifier) {
    if (sockets[identifier] != null) {
      pprint("sending message from '$identifier'...");
      sockets[identifier].emit("message", ["Hello Server", 1908]);
      pprint("Message emitted from '$identifier'...");
    }
  }

  pprint(data) {
    setState(() {
      if (data is Map) {
        data = json.encode(data);
      }
      print(data);
      toPrint.add(data);
    });
  }

  @override
  void dispose() {
    super.dispose();
    chartcontroller.close();
    chartBloc.dispose();
  }

  @override
  void initState() {
    dio.options.baseUrl = "https://cybersvn.team/api";
    dio.options.connectTimeout = 5000; //5s
    dio.options.receiveTimeout = 6000;
    dio.options.validateStatus = (status) {
      return status < 500;
    };
    chartcontroller = StreamController();
    chartcontroller.stream.distinct().listen((LineTouchResponse response) {});
    cpulistFl.add(FlSpot(0, 0));
    ramlistFl.add(FlSpot(0, 0));
    netrxlistFl.add(FlSpot(0, 0));
    nettxlistFl.add(FlSpot(0, 0));

    manager = SocketIOManager();
    initSocket("default");

    // TODO: implement initState
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    PageController controller = PageController(initialPage: images.length - 1);
    controller.addListener(() {
      setState(() {
        currentPage = controller.page;
      });
    });
    List<Color> cpuGradientColors = [
      Color(0xfff3b6e6),
      Color(0xf002d39a),
      Color(0xf002d39a),
    ];
    List<Color> ramGradientColors = [
      Color(0xf002d39a),
      Color(0xfff3b6e6),
      Color(0xfff3b6e6),
    ];
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [
            Color(0xFF1b1e44),
            Color(0xFF2d3447),
          ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              tileMode: TileMode.clamp)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Trending",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 46.0,
                          fontFamily: "Calibre-Semibold",
                          letterSpacing: 1.0,
                        )),
                    ColorLoader5()
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Row(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFff6e6e),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 22.0, vertical: 6.0),
                          child: Text("Cybers",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 15.0,
                    ),
                  ],
                ),
              ),
              Stack(
                children: <Widget>[
                  CardScrollWidget(currentPage),
                  Positioned.fill(
                    child: PageView.builder(
                      itemCount: images.length,
                      controller: controller,
                      reverse: true,
                      itemBuilder: (context, index) {
                        return Container();
                      },
                    ),
                  )
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    DotLoader(
                      dotOneColor: CupertinoColors.activeBlue,
                      dotTwoColor: CupertinoColors.activeGreen,
                      dotThreeColor: CupertinoColors.activeOrange,
                      duration: Duration(milliseconds: 1000),
                    ),
                    Text("Overview",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 46.0,
                          fontFamily: "Calibre-Semibold",
                          letterSpacing: 1.0,
                        )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Row(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 22.0, vertical: 6.0),
                          child: Text("Latest",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 15.0,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(left: 18.0),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(30.0),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                            width: 250.0,
                            height: 222.0,
                            child: new GradientCard(
                              gradient: Gradients.deepSpace,
                              shadowColor:
                                  Gradients.haze.colors.last.withOpacity(0.25),
                              elevation: 10,
                              child: Center(
                                child: GradientText(
                                  '   200 Posts',
                                  shaderRect:
                                      Rect.fromLTWH(0.0, 0.0, 50.0, 50.0),
                                  gradient: Gradients.haze,
                                  style: TextStyle(
                                    fontSize: 40.0,
                                  ),
                                ),
                              ),
                            ),
                          )),
                    ),
                  ),
                  Expanded(
                      flex: 1,
                      child: Center(
                        child: new Column(
                          children: <Widget>[
                            Text("Posts",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Poppins-Medium')),
                            Text(
                              'Total',
                              style: TextStyle(
                                  fontSize: 30, fontFamily: 'Poppins-Medium'),
                            ),
                          ],
                        ),
                      ))
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(
                      flex: 1,
                      child: Center(
                        child: new Column(
                          children: <Widget>[
                            Text("Members",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Poppins-Medium')),
                            Text(
                              'Total',
                              style: TextStyle(
                                  fontSize: 30, fontFamily: 'Poppins-Medium'),
                            )
                          ],
                        ),
                      )),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MemberPanel()));
                      },
                      child: Padding(
                        padding: EdgeInsets.only(right: 18.0),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(25.0),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                              width: 250.0,
                              height: 222.0,
                              child: new GradientCard(
                                gradient: Gradients.haze,
                                shadowColor: Gradients.coldLinear.colors.last
                                    .withOpacity(0.25),
                                elevation: 10,
                                child: Center(
                                  child: GradientText(
                                    '   450 Mems',
                                    shaderRect:
                                        Rect.fromLTWH(0.0, 0.0, 50.0, 50.0),
                                    gradient: Gradients.deepSpace,
                                    style: TextStyle(
                                      fontSize: 40.0,
                                    ),
                                  ),
                                ),
                              ),
                            )),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Container(
                    height: 300,
                    width: size.width,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(18)),
                        gradient: LinearGradient(
                          colors: [
                            Color(0xff2c274c),
                            Color(0xff46426c),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        )),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(
                          height: 37,
                        ),
                        Text(
                          "Connection",
                          style: TextStyle(
                            color: Color(0xff827daa),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: 4,
                        ),
                        Text(
                          "Disk Monitor",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: 37,
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(right: 16.0, left: 6.0),
                            child: StreamBuilder<List<List<FlSpot>>>(
                                initialData: [],
                                stream: chartBloc.blocChartDiskObject,
                                builder: (context, snapshot) {
                                  return FlChart(
                                    chart: LineChart(
                                      LineChartData(
                                        lineTouchData: LineTouchData(
                                            touchResponseSink:
                                                chartcontroller.sink,
                                            touchTooltipData: TouchTooltipData(
                                              tooltipBgColor: Colors.blueGrey
                                                  .withOpacity(0.8),
                                            )),
                                        gridData: FlGridData(
                                          show: false,
                                        ),
                                        titlesData: FlTitlesData(
                                          bottomTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 22,
                                            textStyle: TextStyle(
                                              color: const Color(0xff72719b),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            margin: 10,
                                            getTitles: (value) {
                                              switch (value.toInt()) {
                                                case 95:
                                                  return 'Time';
                                              }
                                              return '';
                                            },
                                          ),
                                          leftTitles: SideTitles(
                                            showTitles: true,
                                            textStyle: TextStyle(
                                              color: Color(0xff75729e),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            getTitles: (value) {
                                              switch (value.toInt()) {
                                                case 0:
                                                  return '0';
                                                case 200:
                                                  return '200';
                                                case 500:
                                                  return '500';
                                                case 800:
                                                  return '800';
                                                case 1000:
                                                  return '1000';
                                                case 1200:
                                                  return 'MB';
                                              }
                                              return '';
                                            },
                                            margin: 8,
                                            reservedSize: 30,
                                          ),
                                        ),
                                        borderData: FlBorderData(
                                            show: true,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Color(0xff4e4965),
                                                width: 4,
                                              ),
                                              left: BorderSide(
                                                color: Colors.transparent,
                                              ),
                                              right: BorderSide(
                                                color: Colors.transparent,
                                              ),
                                              top: BorderSide(
                                                color: Colors.transparent,
                                              ),
                                            )),
                                        minX: 0,
                                        maxX: 100,
                                        maxY: 1200,
                                        minY: 0,
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: snapshot.data[0],
                                            isCurved: true,
                                            colors: [
                                              Color(0xffaa4cfc),
                                            ],
                                            barWidth: 8,
                                            isStrokeCapRound: true,
                                            dotData: FlDotData(
                                              show: false,
                                            ),
                                            belowBarData: BelowBarData(
                                              show: false,
                                            ),
                                          ),
                                          LineChartBarData(
                                            spots: snapshot.data[1],
                                            isCurved: true,
                                            colors: [
                                              Color(0xff27b6fc),
                                            ],
                                            barWidth: 8,
                                            isStrokeCapRound: true,
                                            dotData: FlDotData(
                                              show: false,
                                            ),
                                            belowBarData: BelowBarData(
                                              show: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 18.0),
                        child: Container(
                          height: 200,
                          width: 300,
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(18)),
                              color: Color(0xff232d37)),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 18.0, left: 12.0, top: 24, bottom: 12),
                            child: StreamBuilder<Object>(
                                initialData: cpulistFl,
                                stream: chartBloc.blocChartCPU,
                                builder: (context, snapshot) {
                                  return FlChart(
                                    chart: LineChart(
                                      LineChartData(
                                        gridData: FlGridData(
                                          show: true,
                                          drawHorizontalGrid: true,
                                          getDrawingVerticalGridLine: (value) {
                                            return const FlLine(
                                              color: Color(0xff37434d),
                                              strokeWidth: 1,
                                            );
                                          },
                                          getDrawingHorizontalGridLine:
                                              (value) {
                                            return const FlLine(
                                              color: Color(0xff37434d),
                                              strokeWidth: 1,
                                            );
                                          },
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          bottomTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 22,
                                            textStyle: TextStyle(
                                                color: const Color(0xff68737d),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                            getTitles: (value) {
                                              switch (value.toInt()) {
                                                case 0:
                                                  return '0s';
                                                case 20:
                                                  return '5s';
                                                case 40:
                                                  return '10s';
                                                case 60:
                                                  return '15s';
                                                case 80:
                                                  return '20s';
                                                case 100:
                                                  return '25s';
                                              }

                                              return '';
                                            },
                                            margin: 8,
                                          ),
                                          leftTitles: SideTitles(
                                            showTitles: true,
                                            textStyle: TextStyle(
                                              color: const Color(0xff67727d),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            getTitles: (value) {
                                              switch (value.toInt()) {
                                                case 20:
                                                  return '20%';
                                                case 40:
                                                  return '40%';
                                                case 60:
                                                  return '60%';
                                                case 80:
                                                  return '80%';
                                                case 100:
                                                  return '100%';
                                              }
                                              return '';
                                            },
                                            reservedSize: 28,
                                            margin: 12,
                                          ),
                                        ),
                                        borderData: FlBorderData(
                                            show: true,
                                            border: Border.all(
                                                color: Color(0xff37434d),
                                                width: 1)),
                                        minX: 0,
                                        maxX: 100,
                                        minY: 0,
                                        maxY: 100,
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: snapshot.data,
                                            isCurved: true,
                                            colors: cpuGradientColors,
                                            barWidth: 5,
                                            isStrokeCapRound: true,
                                            dotData: FlDotData(
                                              show: false,
                                            ),
                                            belowBarData: BelowBarData(
                                              show: true,
                                              colors: cpuGradientColors
                                                  .map((color) =>
                                                      color.withOpacity(0.3))
                                                  .toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: new Column(
                          children: <Widget>[
                            Text("CPU",
                                style: TextStyle(
                                    fontSize: 30,
                                    fontFamily: 'Poppins-Medium')),
                            Text(
                              'Monitor',
                              style: TextStyle(
                                  fontSize: 18, fontFamily: 'Poppins-Medium'),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Center(
                          child: new Column(
                            children: <Widget>[
                              Text("RAM",
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontFamily: 'Poppins-Medium')),
                              Text(
                                'Monitor',
                                style: TextStyle(
                                    fontSize: 18, fontFamily: 'Poppins-Medium'),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 18.0),
                        child: Container(
                          height: 200,
                          width: 300,
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(18)),
                              color: Color(0xff232d37)),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 18.0, left: 12.0, top: 24, bottom: 12),
                            child: StreamBuilder<Object>(
                                initialData: [chartBloc.initData],
                                stream: chartBloc.blocChartRAM,
                                builder: (context, snapshot) {
                                  return FlChart(
                                    chart: LineChart(
                                      LineChartData(
                                        gridData: FlGridData(
                                          show: true,
                                          drawHorizontalGrid: true,
                                          getDrawingVerticalGridLine: (value) {
                                            return const FlLine(
                                              color: Color(0xff37434d),
                                              strokeWidth: 1,
                                            );
                                          },
                                          getDrawingHorizontalGridLine:
                                              (value) {
                                            return const FlLine(
                                              color: Color(0xff37434d),
                                              strokeWidth: 1,
                                            );
                                          },
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          bottomTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 22,
                                            textStyle: TextStyle(
                                                color: const Color(0xff68737d),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                            getTitles: (value) {
                                              switch (value.toInt()) {
                                                case 0:
                                                  return '0s';
                                                case 20:
                                                  return '5s';
                                                case 40:
                                                  return '10s';
                                                case 60:
                                                  return '15s';
                                                case 80:
                                                  return '20s';
                                                case 100:
                                                  return '25s';
                                              }

                                              return '';
                                            },
                                            margin: 8,
                                          ),
                                          leftTitles: SideTitles(
                                            showTitles: true,
                                            textStyle: TextStyle(
                                              color: const Color(0xff67727d),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            getTitles: (value) {
                                              switch (value.toInt()) {
                                                case 20:
                                                  return '20%';
                                                case 40:
                                                  return '40%';
                                                case 60:
                                                  return '60%';
                                                case 80:
                                                  return '80%';
                                                case 100:
                                                  return '100%';
                                              }
                                              return '';
                                            },
                                            reservedSize: 28,
                                            margin: 12,
                                          ),
                                        ),
                                        borderData: FlBorderData(
                                            show: true,
                                            border: Border.all(
                                                color: Color(0xff37434d),
                                                width: 1)),
                                        minX: 0,
                                        maxX: 100,
                                        minY: 0,
                                        maxY: 100,
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: snapshot.data,
                                            isCurved: true,
                                            colors: ramGradientColors,
                                            barWidth: 5,
                                            isStrokeCapRound: true,
                                            dotData: FlDotData(
                                              show: false,
                                            ),
                                            belowBarData: BelowBarData(
                                              show: true,
                                              colors: ramGradientColors
                                                  .map((color) =>
                                                      color.withOpacity(0.3))
                                                  .toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardScrollWidget extends StatelessWidget {
  var currentPage;
  var padding = 20.0;
  var verticalInset = 20.0;

  CardScrollWidget(this.currentPage);

  @override
  Widget build(BuildContext context) {
    return new AspectRatio(
      aspectRatio: widgetAspectRatio,
      child: LayoutBuilder(builder: (context, contraints) {
        var width = contraints.maxWidth;
        var height = contraints.maxHeight;

        var safeWidth = width - 2 * padding;
        var safeHeight = height - 2 * padding;

        var heightOfPrimaryCard = safeHeight;
        var widthOfPrimaryCard = heightOfPrimaryCard * cardAspectRatio;

        var primaryCardLeft = safeWidth - widthOfPrimaryCard;
        var horizontalInset = primaryCardLeft / 2;

        List<Widget> cardList = new List();

        for (var i = 0; i < images.length; i++) {
          var delta = i - currentPage;
          bool isOnRight = delta > 0;

          var start = padding +
              max(
                  primaryCardLeft -
                      horizontalInset * -delta * (isOnRight ? 15 : 1),
                  0.0);

          var cardItem = Positioned.directional(
            top: padding + verticalInset * max(-delta, 0.0),
            bottom: padding + verticalInset * max(-delta, 0.0),
            start: start,
            textDirection: TextDirection.rtl,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      offset: Offset(3.0, 6.0),
                      blurRadius: 10.0)
                ]),
                child: AspectRatio(
                  aspectRatio: cardAspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.asset(images[i], fit: BoxFit.cover),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Text(title[i],
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25.0,
                                      fontFamily: "SF-Pro-Text-Regular")),
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 12.0, bottom: 12.0),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 22.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    borderRadius: BorderRadius.circular(20.0)),
                                child: Text("Read Story",
                                    style: TextStyle(color: Colors.white)),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
          cardList.add(cardItem);
        }
        return Stack(
          children: cardList,
        );
      }),
    );
  }
}
