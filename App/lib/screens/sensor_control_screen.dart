import 'package:app/res/custom_colors.dart';
import 'package:app/widgets/app_bar_title.dart';
import 'package:app/widgets/bottom_navigation_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart';

class SensorControlScreen extends StatefulWidget {
  const SensorControlScreen({Key key, this.board, this.device, this.title}) : super(key: key);

  final Map<String, dynamic> board;
  final dynamic device;
  final String title;

  @override
  _SensorControlScreenState createState() => _SensorControlScreenState();
}

class _SensorControlScreenState extends State<SensorControlScreen> {

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance.collection("board-configs").doc(widget.board["id"]).update({
      "devices": widget.board["devices"]
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        backgroundColor: CustomColors.navy,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: CustomColors.navy,
          title: AppBarTitle(title: widget.title),
        ),
        bottomNavigationBar: const BottomNavbar(),
        body: build_body()
    );
  }

  Widget build_chart_wrapper() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('sensors').doc(widget.board["id"]).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Center(child: CircularProgressIndicator());
          default:
            var data = snapshot.data.data() as Map<String, dynamic>;
            var devices = data["devices"] as List<dynamic>;
            var sensor = null;

            for (var d in devices) {
              if(d["name"] == widget.device["name"]) {
                sensor = d;
                break;
              }
            }

            if (sensor == null) {
              return Column(children: const [
                Text("There is no sensor data yet"),
              ]);
            }
            else {
              return Column(children: [
                Text("Sensor value: " + (sensor["data"] as List).last["value"].toString()),
                build_chart(sensor),
              ]);
            }
        }
      },
    );
  }

  Widget build_switch_wrapper() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('boards').doc(widget.board["id"]).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Center(child: CircularProgressIndicator());
          default:
            var data = snapshot.data.data() as Map<String, dynamic>;
            var devices = data["devices"] as List<dynamic>;

            var sensor = null;

            for (var d in devices) {
              if (d["name"] == widget.device["name"]) {
                sensor = d;
                break;
              }
            }

            var children = [build_active_switch(sensor["active"])];

            return Column(
                children: children
            );
        }
      },
    );
  }


  Widget build_body() {

    var children = [
      build_chart_wrapper(),
      build_switch_wrapper()
    ];

    return Column(children: children);
  }

  Widget build_active_switch(active) {
    return FlutterSwitch(
      activeColor: Colors.green,
      inactiveColor: const Color(0x4D6CC770),
      width: 100.0,
      height: 50.0,
      valueFontSize: 25.0,
      toggleSize: 25.0,
      value: active == 1 ? true : false,
      borderRadius: 30.0,
      padding: 8.0,
      showOnOff: true,
      onToggle: (val) {

          List devices = widget.board["devices"];

          for(var i=0; i<devices.length; ++i) {
            if (devices[i]["name"] == widget.device["name"]) {
              devices[i]["active"] = (val == true ? 1 : 0);
              break;
            }
          }

          FirebaseFirestore.instance.collection("board-configs").doc(widget.board["id"]).update({
            "devices": devices
          });

      }
    );
  }

  Widget build_chart(Map<String, dynamic> sensor) {

    List<SensorData> sensor_data = [];

    if((sensor["data"] as List).isNotEmpty) {
      sensor_data = (sensor["data"] as List).map((e) => SensorData(DateTime.parse(e["time"]), e["value"])).toList();
    }

    return Center(
      child: Container(
        child: SfCartesianChart(
          title: ChartTitle(text: 'Real-time sensor data'),
          primaryXAxis: DateTimeAxis(
            name: "Time",
            title: AxisTitle(
              text: "Time"
            )
          ),
          series: <LineSeries<SensorData, DateTime>>[LineSeries<SensorData, DateTime>(
              enableTooltip: true,
              dataSource:  sensor_data,
              xValueMapper: (SensorData data, _) => data.time,
              yValueMapper: (SensorData data, _) => data.value,
              markerSettings: const MarkerSettings(
                isVisible: true,
                width: 3,
                height: 3,
                shape: DataMarkerType.circle,
                color: Colors.lightBlueAccent,
                borderColor: Colors.lightBlueAccent
              )
            )]
        )
      )
    );
  }
}

class SensorData {
  SensorData(this.time, this.value);
  final DateTime time;
  final num value;
}