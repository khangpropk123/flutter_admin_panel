import 'package:fl_chart/fl_chart.dart';
import 'package:rxdart/rxdart.dart';

class ChartBloc {
  FlSpot initData = new FlSpot(0, 0);
  List<FlSpot> cpulistFl = new List<FlSpot>();
  List<FlSpot> ramlistFl = new List<FlSpot>();
  List<List<FlSpot>> diskListFl = new List<List<FlSpot>>(2);
  List<FlSpot> diskReadListFl = new List<FlSpot>();
  List<FlSpot> diskWriteListFl = new List<FlSpot>();
  BehaviorSubject<List<FlSpot>> blocChartCPUObject;
  BehaviorSubject<List<FlSpot>> blocChartRAMObject;
  BehaviorSubject<List<List<FlSpot>>> blocChartDiskObject;
  ChartBloc({this.initData}) {
    blocChartCPUObject = new BehaviorSubject<List<FlSpot>>.seeded([initData]);
    blocChartRAMObject = new BehaviorSubject<List<FlSpot>>.seeded([initData]);
    blocChartDiskObject = new BehaviorSubject<List<List<FlSpot>>>.seeded([
      [initData],
      [initData]
    ]);
  }
  Observable<List<FlSpot>> get blocChartCPU => blocChartCPUObject.stream;
  Observable<List<FlSpot>> get blocChartRAM => blocChartRAMObject.stream;
  Observable<List<List<FlSpot>>> get blocChartDiskWrite =>
      blocChartDiskObject.stream;

  void UpdateChartCPU(double data) {
    if (cpulistFl.length > 100) {
      cpulistFl.clear();
      cpulistFl.add(FlSpot(0, data));
    } else {
      cpulistFl.add(FlSpot((cpulistFl.length).toDouble(), data));
    }
    blocChartCPUObject.sink.add(cpulistFl);
  }

  void UpdateChartRAM(double data) {
    if (ramlistFl.length > 100) {
      ramlistFl.clear();
      ramlistFl.add(FlSpot(0, data));
    } else {
      ramlistFl.add(FlSpot((ramlistFl.length).toDouble(), data));
    }
    blocChartRAMObject.sink.add(ramlistFl);
  }

  void UpdateChartDisk(double wx, double rx) {
    if (diskReadListFl.length > 100) {
      diskReadListFl.clear();
      diskReadListFl.add(FlSpot(0, rx));
    } else {
      diskReadListFl.add(FlSpot((diskReadListFl.length).toDouble(), rx));
    }
    if (diskWriteListFl.length > 100) {
      diskWriteListFl.clear();
      diskWriteListFl.add(FlSpot(0, wx));
    } else {
      diskWriteListFl.add(FlSpot((diskWriteListFl.length).toDouble(), wx));
    }
    diskListFl[0] = diskReadListFl;
    diskListFl[1] = diskWriteListFl;
    blocChartDiskObject.sink.add(diskListFl);
  }

  void dispose() {
    blocChartCPUObject.close();
    blocChartRAMObject.close();
    blocChartDiskObject.close();
  }
}
