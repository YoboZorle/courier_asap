import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:intl/intl.dart';
import 'package:pickrr_app/src/helpers/constants.dart';
import 'package:pickrr_app/src/helpers/utility.dart';
import 'package:pickrr_app/src/user/custom_appbar.dart';
import 'package:pickrr_app/src/widgets/nav_drawer.dart';
import 'package:latlong/latlong.dart' as myLat;

import 'package:pickrr_app/src/user/user_order.dart';
import 'dart:math' show cos, sqrt, asin;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  GoogleMapController mapController;
  TextEditingController destinationController = new TextEditingController();
  TextEditingController pickupController = new TextEditingController();
  List<Marker> markersList = [];
  LatLng _center = LatLng(
      4.778559, 7.016669); //port harcourt coordinates -- default location
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: AppData.mapAPIKey);
  GoogleMapPolyline googleMapPolyline =
      new GoogleMapPolyline(apiKey: AppData.mapAPIKey);
  final List<Polyline> polyline = [];
  List<LatLng> routeCoords = [];
  Completer<GoogleMapController> __controller = Completer();

  PlaceDetails departure;
  PlaceDetails arrival;

  String _placeDistance;
  String _placeTime;

  final currencyFormatter =
      NumberFormat.currency(locale: 'en_US', symbol: '\u20a6');
  double amount = 500;

  void onMapCreated(controller) {
    setState(() {
      mapController = controller;
      __controller.complete(controller);
    });
  }

  Future<Null> displayPredictionDestination(Prediction p) async {
    if (p != null) {
      // get detail (lat/lng)
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);
      final lat = detail.result.geometry.location.lat;
      final lng = detail.result.geometry.location.lng;

      setState(() {
        departure = detail.result;
        destinationController.text = detail.result.name;
        Marker marker = Marker(
            markerId: MarkerId('arrivalMarker'),
            draggable: false,
            infoWindow: InfoWindow(
              title: "This is where you will arrive",
            ),
            onTap: () {
              //print('this is where you will arrive');
            },
            position: LatLng(lat, lng));
        markersList.add(marker);
      });

      mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 16.0)));
      computePath();
    }
  }

  Future<Null> displayPredictionPickup(Prediction p) async {
    if (p != null) {
      // get detail (lat/lng)
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);
      final lat = detail.result.geometry.location.lat;
      final lng = detail.result.geometry.location.lng;

      setState(() {
        arrival = detail.result;
        pickupController.text = detail.result.name;
        Marker marker = Marker(
            markerId: MarkerId('pickupMarker'),
            draggable: false,
            infoWindow: InfoWindow(
              title: "This is where you start",
            ),
            onTap: () {
              //print('this is where you will arrive');
            },
            position: LatLng(lat, lng));
        markersList.add(marker);
      });
      mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 16.0)));
    }
  }

  computePath() async {
    LatLng origin = new LatLng(
        departure.geometry.location.lat, departure.geometry.location.lng);
    LatLng end = new LatLng(
        arrival.geometry.location.lat, arrival.geometry.location.lng);
    routeCoords.addAll(await googleMapPolyline.getCoordinatesWithLocation(
        origin: origin, destination: end, mode: RouteMode.driving));

    //math area
    // _myDistanceCalc(
    //     lat1: departure.geometry.location.lat,
    //     lon1: departure.geometry.location.lng,
    //     lat2: arrival.geometry.location.lat,
    //     lon2: arrival.geometry.location.lng);

    double totalDistance = 0.0;

    // Calculating the total distance by adding the distance
    // between small segments
    for (int i = 0; i < routeCoords.length - 1; i++) {
      totalDistance += _coordinateDistance(
        routeCoords[i].latitude,
        routeCoords[i].longitude,
        routeCoords[i + 1].latitude,
        routeCoords[i + 1].longitude,
      );
    }

    int speed = 30;
    double time = speed * totalDistance;

    double kms_per_min = 0.5;

    double mins_taken = totalDistance / kms_per_min;

    int totalMinutes = mins_taken.toInt();

    print("ResponseT: kms : $totalDistance, mins: $mins_taken");
    String totalTime;

    if (totalMinutes<60)
    {
      totalTime =  "$totalMinutes mins";
    }else {
      String minutes = (totalMinutes % 60).toString();
      minutes = minutes.length == 1 ? "0$minutes" : minutes;
      totalTime =  "${totalMinutes ~/ 60} hours, $minutes mins";
    }

    setState(() {
      _placeDistance = totalDistance.toStringAsFixed(1);
      print('DISTANCE: $_placeDistance km');

      _placeTime = totalTime;
      print('Time is just $_placeTime');

    });

    setState(() {
      polyline.add(Polyline(
          polylineId: PolylineId('iter'),
          visible: true,
          points: routeCoords,
          width: 6,
          geodesic: true,
          color: Colors.red,
          startCap: Cap.roundCap,
          endCap: Cap.buttCap));
    });

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          northeast: LatLng(
            departure.geometry.location.lat,
            departure.geometry.location.lng,
          ),
          southwest: LatLng(
            arrival.geometry.location.lat,
            arrival.geometry.location.lng,
          ),
        ),
        150.0, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: NavDrawer(),
        ),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
          ),
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(new FocusNode());
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: [
                      Hero(
                        tag: 'map',
                        flightShuttleBuilder: _flightShuttleBuilder,
                        child: GoogleMap(
                          onMapCreated: onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: _center,
                            zoom: 16.0,
                          ),
                          markers: Set.from(markersList),
                          polylines: Set.from(polyline),
                          indoorViewEnabled: true,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomGesturesEnabled: true,
                          zoomControlsEnabled: false,
                          trafficEnabled: false,
                          buildingsEnabled: false,
                        ),
                      ),
                      CustomerAppBar(),
                      // Positioned(
                      //     bottom: 0, right: 0, child: orderLocationDetailsPanel())
                    ],
                  ),
                ),
                Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        Shadows.primaryShadow,
                      ],
                    ),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: [
                        Container(
                          height: 8,
                          width: 60,
                          margin: EdgeInsets.only(top: 14, bottom: 13),
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(16)),
                        ),
                    _placeDistance != null ? _billingLayout()
                        : _bottomTitle(),
                        Container(
                            height: 50.0,
                            width: double.infinity,
                            margin: EdgeInsets.only(
                                left: 20, right: 20, bottom: 8, top: 13),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.fromBorderSide(
                                  Borders.globalSearchBorder),
                              boxShadow: [
                                Shadows.globalShadowSearch,
                              ],
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                            ),
                            child: Column(
                              children: <Widget>[
                                TextField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: "Enter Pickup Location",
                                    hintStyle: TextStyle(
                                      color: Colors.black45,
                                      fontFamily: "Ubuntu",
                                      fontWeight: FontWeight.w400,
                                      fontSize: 17,
                                    ),
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: "Ubuntu",
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17,
                                    ),
                                    border: InputBorder.none,
                                    prefixIcon: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8.0, right: 5),
                                          child: SvgPicture.asset(
                                              'assets/svg/pin.svg',
                                              height: 19,
                                              color: AppColor.primaryText,
                                              semanticsLabel: 'search icon'),
                                        ),
                                      ],
                                    ),
                                    contentPadding:
                                        EdgeInsets.only(left: 15.0, top: 15.0),
                                  ),
                                  controller: pickupController,
                                  onTap: () async {
                                    Prediction p =
                                        await PlacesAutocomplete.show(
                                            context: context,
                                            apiKey: AppData.mapAPIKey,
                                            mode: Mode.fullscreen,
                                            language: "en",
                                            hint: 'Search pickup location',
                                            components: [
                                          new Component(Component.country, "ng")
                                        ]);
                                    displayPredictionPickup(p);

                                    setState(() {
                                      if (markersList.isNotEmpty)
                                        markersList.clear();
                                      if (polyline.isNotEmpty) polyline.clear();
                                      if (routeCoords.isNotEmpty)
                                        routeCoords.clear();
                                      _placeDistance = null;
                                      _placeTime = null;
                                      pickupController.clear();
                                    });
                                  },
                                ),
                              ],
                            )),
                        Container(
                            height: 50.0,
                            width: double.infinity,
                            margin: EdgeInsets.only(
                                left: 20, right: 20, bottom: 18, top: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.fromBorderSide(
                                  Borders.globalSearchBorder),
                              boxShadow: [
                                Shadows.globalShadowSearch,
                              ],
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                            ),
                            child: Column(
                              children: <Widget>[
                                TextField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: "Enter Destination Location",
                                    hintStyle: TextStyle(
                                      color: Colors.black45,
                                      fontFamily: "Ubuntu",
                                      fontWeight: FontWeight.w400,
                                      fontSize: 17,
                                    ),
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: "Ubuntu",
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17,
                                    ),
                                    border: InputBorder.none,
                                    prefixIcon: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8.0, right: 5),
                                          child: SvgPicture.asset(
                                              'assets/svg/nav.svg',
                                              height: 19,
                                              color: AppColor.primaryText,
                                              semanticsLabel: 'search icon'),
                                        ),
                                      ],
                                    ),
                                    contentPadding:
                                        EdgeInsets.only(left: 15.0, top: 15.0),
                                  ),
                                  controller: destinationController,
                                  onTap: () async {
                                    Prediction p =
                                        await PlacesAutocomplete.show(
                                            context: context,
                                            apiKey: AppData.mapAPIKey,
                                            mode: Mode.fullscreen,
                                            language: "en",
                                            hint: 'Search destination',
                                            components: [
                                          new Component(Component.country, "ng")
                                        ]);
                                    displayPredictionDestination(p);
                                    setState(() {
                                      if (markersList.isNotEmpty)
                                        markersList.clear();
                                      if (polyline.isNotEmpty) polyline.clear();
                                      if (routeCoords.isNotEmpty)
                                        routeCoords.clear();
                                      _placeDistance = null;
                                      _placeTime = null;
                                      destinationController.clear();
                                    });
                                  },
                                ),
                              ],
                            )),
                        InkWell(
                          child: Container(
                              height: 47,
                              alignment: Alignment.center,
                              margin: EdgeInsets.only(
                                  left: 20, right: 20, bottom: 25),
                              decoration: BoxDecoration(
                                color: _placeDistance != null ? AppColor.primaryText : Colors.grey.withOpacity(0.5),
                                borderRadius: Radii.k25pxAll,
                              ),
                              child: Text(_placeDistance != null ? 'Request rider' : 'Get estimate',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Ubuntu',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400))),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UserOrder()),
                            );
                          },
                          splashColor: Colors.grey[300],
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ));
  }

  Widget _flightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    return DefaultTextStyle(
      style: DefaultTextStyle.of(toHeroContext).style,
      child: toHeroContext.widget,
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  // Formula for calculating distance between two coordinates
  // https://stackoverflow.com/a/54138876/11910277
  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;  // var p = 0.028453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _myDistanceCalc({lat1, lon1, lat2, lon2}) {
    debugLog('Calculating distance');
    final myLat.Distance distance = new myLat.Distance();

    // km = 423
    debugLog('Computing distance ...');
    final int km = distance.as(
        myLat.LengthUnit.Kilometer,
        new myLat.LatLng(52.518611, 13.408056),
        new myLat.LatLng(51.519475, 7.46694444));
    debugLog('Distance in km: ${km.toString()}');

    // meter = 422591.551
    final int meter = distance(new myLat.LatLng(52.518611, 13.408056),
        new myLat.LatLng(51.519475, 7.46694444));
    debugLog('Distance in meters: ${meter.toString()}');
  }

  _billingLayout() => Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.only(left: 20, right: 20, bottom: 15, top: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated time:',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: "Ubuntu",
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text('$_placeTime',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "Ubuntu",
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      )),
                ],
              ),
            ),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total distance:',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: "Ubuntu",
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text('$_placeDistance' 'km',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Ubuntu",
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    )),
              ],
            )),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fare estimate:',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: "Ubuntu",
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(currencyFormatter.format(amount),
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: "Ubuntu",
                      color: AppColor.primaryText,
                      fontWeight: FontWeight.w800,
                    )),
              ],
            )),
          ],
        ),
      );

  _bottomTitle() => Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(left: 20),
            child: Text(
              "Hello dear,",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 15,
                fontFamily: "Ubuntu",
                color: Colors.black54,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(left: 20, top: 3),
            child: new Text(
              "A rider is ready for you.",
              maxLines: 1,
              textAlign: TextAlign.left,
              style: TextStyle(
                  fontSize: 20.0,
                  fontFamily: "Ubuntu",
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  height: 1.35),
            ),
          ),
        ],
      );
}
