import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pickrr_app/src/helpers/constants.dart';
import 'package:pickrr_app/src/helpers/utility.dart';
import 'package:pickrr_app/src/screens/ride/receiver_details.dart';
import 'package:pickrr_app/src/services/repositories/core.dart';
import 'package:pickrr_app/src/services/repositories/ride.dart';
import 'package:pickrr_app/src/utils/alert_bar.dart';
import 'package:pickrr_app/src/widgets/arguments.dart';
import 'package:pickrr_app/src/widgets/nav_drawer.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickrr_app/src/blocs/authentication/bloc.dart';
import 'package:pickrr_app/src/models/user.dart';

class Home extends StatefulWidget {
  final AlertBarArguments arguments;

  Home({this.arguments});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  RideRepository _rideRepository;
  CoreRepository _coreRepository;
  GoogleMapController mapController;
  TextEditingController destinationController;
  TextEditingController pickupController;
  List<Marker> markersList = [];
  LatLng _center = LatLng(4.816280, 7.000530);
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: AppData.mapAPIKey);
  GoogleMapPolyline googleMapPolyline;
  final List<Polyline> polyline = [];
  List<LatLng> routeCoords = [];
  Completer<GoogleMapController> __controller = Completer();
  Map<String, dynamic> pickupCoordinate = {};
  Map<String, dynamic> destinationCoordinate = {};

  PlaceDetails destination;
  PlaceDetails pickupPoint;

  String _placeDistance;
  double _distanceCovered;
  double _ridePrice;
  String _placeTime;

  @override
  void initState() {
    _rideRepository = RideRepository();
    _coreRepository = CoreRepository();
    destinationController = new TextEditingController();
    pickupController = new TextEditingController();
    googleMapPolyline = new GoogleMapPolyline(apiKey: AppData.mapAPIKey);
    _accountBlockedAlert();
    _applicationSubmittedAlert();
    super.initState();
  }

  final currencyFormatter =
      NumberFormat.currency(locale: 'en_US', symbol: '\u20a6');

  void onMapCreated(controller) {
    setState(() {
      mapController = controller;
      __controller.complete(controller);
    });
  }

  Future<Null> displayPredictionDestination(Prediction p) async {
    if (p != null) {
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);
      final lat = detail.result.geometry.location.lat;
      final lng = detail.result.geometry.location.lng;

      destination = detail.result;
      destinationController.text =
          detail.result.name + ', ' + detail.result.formattedAddress;
      Marker marker = Marker(
          markerId: MarkerId('distanceMarker'),
          draggable: false,
          infoWindow: InfoWindow(
            title: "Delivery destination",
          ),
          onTap: () {},
          position: LatLng(lat, lng));
      markersList.add(marker);
      destinationCoordinate['lat'] = lat;
      destinationCoordinate['lng'] = lng;
      destinationCoordinate['address'] = destinationController.text;

      mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 16.0)));

      if (destination != null && pickupPoint != null) {
        computePath();
      } else {
        setState(() {});
      }
    }
  }

  Future<Null> displayPredictionPickup(Prediction p) async {
    if (p != null) {
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId);
      final lat = detail.result.geometry.location.lat;
      final lng = detail.result.geometry.location.lng;

      pickupPoint = detail.result;
      pickupController.text =
          detail.result.name + ', ' + detail.result.formattedAddress;
      Marker marker = Marker(
          markerId: MarkerId('pickupMarker'),
          draggable: false,
          infoWindow: InfoWindow(
            title: "This is where you start",
          ),
          onTap: () {},
          position: LatLng(lat, lng));
      markersList.add(marker);
      pickupCoordinate['lat'] = lat;
      pickupCoordinate['lng'] = lng;
      pickupCoordinate['address'] = pickupController.text;

      mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 16.0)));
      if (destination != null && pickupPoint != null) {
        computePath();
      } else {
        setState(() {});
      }
    }
  }

  computePath() async {
    LatLng origin = new LatLng(
        destination.geometry.location.lat, destination.geometry.location.lng);
    LatLng end = new LatLng(
        pickupPoint.geometry.location.lat, pickupPoint.geometry.location.lng);
    routeCoords.addAll(await googleMapPolyline.getCoordinatesWithLocation(
        origin: origin, destination: end, mode: RouteMode.driving));

    double totalDistance = 0.0;

    for (int i = 0; i < routeCoords.length - 1; i++) {
      totalDistance += coordinateDistance(
        routeCoords[i].latitude,
        routeCoords[i].longitude,
        routeCoords[i + 1].latitude,
        routeCoords[i + 1].longitude,
      );
    }

    double kmsPerMin = 0.5;

    double minsTaken = totalDistance / kmsPerMin;

    int totalMinutes = minsTaken.toInt();

    String totalTime;

    if (totalMinutes < 60) {
      totalTime = "$totalMinutes mins";
    } else {
      String minutes = (totalMinutes % 60).toString();
      minutes = minutes.length == 1 ? "0$minutes" : minutes;
      totalTime = "${totalMinutes ~/ 60} hours, $minutes mins";
    }

    Map<String, dynamic> formDetails = {'price': totalDistance};
    _ridePrice =
        await _coreRepository.getRidePrice(new FormData.fromMap(formDetails));

    setState(() {
      _distanceCovered = totalDistance;
      _placeDistance = totalDistance.toStringAsFixed(1);
      _placeTime = totalTime;

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

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
          pickupPoint.geometry.location.lat, pickupPoint.geometry.location.lng),
      northeast: LatLng(
          destination.geometry.location.lat, destination.geometry.location.lng),
    );

    LatLng centerBounds = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2);

    mapController.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: centerBounds,
      zoom: 17,
    )));
    zoomToFit(mapController, bounds, centerBounds);
  }

  void _processLocations() async {
    AlertBar.dialog(context, 'Processing request...', AppColor.primaryText,
        showProgressIndicator: true, duration: null);

    try {
      Map<String, dynamic> formDetails = {
        'pickup_lat': pickupCoordinate['lat'].toStringAsFixed(6),
        'pickup_lng': pickupCoordinate['lng'].toStringAsFixed(6),
        'pickup_address': pickupCoordinate['address'],
        'destination_lat': destinationCoordinate['lat'].toStringAsFixed(6),
        'destination_address': destinationCoordinate['address'],
        'destination_lng': destinationCoordinate['lng'].toStringAsFixed(6),
      };

      if (!await isInternetConnected()) {
        Navigator.pop(context);
        AlertBar.dialog(context,
            'Please check your internet connection and try again.', Colors.red,
            icon: Icon(Icons.error), duration: 5);
        return;
      }
      var response = await _rideRepository
          .submitRideLocation(new FormData.fromMap(formDetails));
      pickupCoordinate['id'] = response['pickup_id'];
      destinationCoordinate['id'] = response['destination_id'];
      final duration = _placeTime;
      final locationDistance = _placeDistance;
      final price = _ridePrice;
      final pickupDetails = pickupCoordinate;
      final destinationDetails = destinationCoordinate;
      final totalDistanceCovered = _distanceCovered;
      _resetState();
      Navigator.pop(context);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PackageReceiverDetails(
                  duration: duration,
                  distanceCovered: totalDistanceCovered,
                  distance: locationDistance,
                  price: price,
                  pickupCoordinate: pickupDetails,
                  destinationCoordinate: destinationDetails)));
    } catch (err) {
      debugLog(err);
      Navigator.pop(context);
      AlertBar.dialog(context, err.message, Colors.red,
          icon: Icon(Icons.error), duration: 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
            preferredSize: const Size.fromHeight(50), child: PickrrAppBar()),
        drawer: Drawer(
          child: NavDrawer(),
        ),
        body: SafeArea(
          top: false,
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
                      GoogleMap(
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
                        compassEnabled: false,
                        zoomControlsEnabled: false,
                        trafficEnabled: false,
                        buildingsEnabled: false,
                      ),
                      // CustomerAppBar(),
                    ],
                  ),
                ),
                Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        Shadows.primaryShadow,
                      ],
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(0.0),
                          topLeft: Radius.circular(0.0)),
                    ),
                    width: MediaQuery.of(context).size.width,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          Container(
                            height: 8,
                            width: 60,
                            margin: EdgeInsets.only(top: 15),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          _placeDistance != null
                              ? _deliveryDetails()
                              : _bottomTitle(),
                          // Container(
                          //     height: 50.0,
                          //     width: double.infinity,
                          //     margin: EdgeInsets.only(
                          //         left: 20, right: 20, bottom: 6, top: 13),
                          //     decoration: BoxDecoration(
                          //       color: Colors.white,
                          //       border: Border.fromBorderSide(
                          //           Borders.globalSearchBorder),
                          //       boxShadow: [
                          //         Shadows.globalShadowSearch,
                          //       ],
                          //       borderRadius:
                          //           BorderRadius.all(Radius.circular(5)),
                          //     ),
                          //     child: Column(
                          //       children: <Widget>[
                          //         TextField(
                          //           readOnly: true,
                          //           decoration: InputDecoration(
                          //             hintText: "Pickup location",
                          //             hintStyle: TextStyle(
                          //               color: Colors.black45,
                          //               fontFamily: "Ubuntu",
                          //               fontWeight: FontWeight.w400,
                          //               fontSize: 17,
                          //             ),
                          //             labelStyle: TextStyle(
                          //               color: Colors.black,
                          //               fontFamily: "Ubuntu",
                          //               fontWeight: FontWeight.w500,
                          //               fontSize: 17,
                          //             ),
                          //             border: InputBorder.none,
                          //             prefixIcon: Column(
                          //               mainAxisAlignment:
                          //                   MainAxisAlignment.center,
                          //               children: [
                          //                 Padding(
                          //                   padding: const EdgeInsets.only(
                          //                       left: 8.0, right: 5),
                          //                   child: SvgPicture.asset(
                          //                       'assets/svg/pin.svg',
                          //                       height: 19,
                          //                       color: AppColor.primaryText,
                          //                       semanticsLabel: 'search icon'),
                          //                 ),
                          //               ],
                          //             ),
                          //             contentPadding: EdgeInsets.only(
                          //                 left: 15.0, top: 15.0),
                          //           ),
                          //           controller: pickupController,
                          //           onTap: () async {
                          //             setState(() {
                          //               _clearPickupRecord();
                          //             });
                          //             Prediction p =
                          //                 await PlacesAutocomplete.show(
                          //                     context: context,
                          //                     apiKey: AppData.mapAPIKey,
                          //                     mode: Mode.fullscreen,
                          //                     logo: Icon(Icons.search,
                          //                         color: Colors.transparent),
                          //                     language: "en",
                          //                     hint: 'Search pickup location',
                          //                     components: [
                          //                   new Component(
                          //                       Component.country, "ng"),
                          //                 ]);
                          //             displayPredictionPickup(p);
                          //           },
                          //         ),
                          //       ],
                          //     )),
                          // Container(
                          //     height: 50.0,
                          //     width: double.infinity,
                          //     margin: EdgeInsets.only(
                          //         left: 20, right: 20, bottom: 18, top: 6),
                          //     decoration: BoxDecoration(
                          //       color: Colors.white,
                          //       border: Border.fromBorderSide(
                          //           Borders.globalSearchBorder),
                          //       boxShadow: [
                          //         Shadows.globalShadowSearch,
                          //       ],
                          //       borderRadius:
                          //           BorderRadius.all(Radius.circular(5)),
                          //     ),
                          //     child: Column(
                          //       children: <Widget>[
                          //         TextField(
                          //           readOnly: true,
                          //           decoration: InputDecoration(
                          //             hintText: "Dropoff location",
                          //             hintStyle: TextStyle(
                          //               color: Colors.black45,
                          //               fontFamily: "Ubuntu",
                          //               fontWeight: FontWeight.w400,
                          //               fontSize: 17,
                          //             ),
                          //             labelStyle: TextStyle(
                          //               color: Colors.black,
                          //               fontFamily: "Ubuntu",
                          //               fontWeight: FontWeight.w500,
                          //               fontSize: 17,
                          //             ),
                          //             border: InputBorder.none,
                          //             prefixIcon: Column(
                          //               mainAxisAlignment:
                          //                   MainAxisAlignment.center,
                          //               children: [
                          //                 Padding(
                          //                   padding: const EdgeInsets.only(
                          //                       left: 8.0, right: 5),
                          //                   child: SvgPicture.asset(
                          //                       'assets/svg/nav.svg',
                          //                       height: 19,
                          //                       color: AppColor.primaryText,
                          //                       semanticsLabel: 'search icon'),
                          //                 ),
                          //               ],
                          //             ),
                          //             contentPadding: EdgeInsets.only(
                          //                 left: 15.0, top: 15.0),
                          //           ),
                          //           controller: destinationController,
                          //           onTap: () async {
                          //             setState(() {
                          //               _clearDestinationRecord();
                          //             });
                          //             Prediction p =
                          //                 await PlacesAutocomplete.show(
                          //                     context: context,
                          //                     apiKey: AppData.mapAPIKey,
                          //                     mode: Mode.fullscreen,
                          //                     language: "en",
                          //                     logo: Icon(Icons.search,
                          //                         color: Colors.transparent),
                          //                     hint: 'Search destination',
                          //                     components: [
                          //                   new Component(
                          //                       Component.country, "ng")
                          //                 ]);
                          //             displayPredictionDestination(p);
                          //           },
                          //         ),
                          //       ],
                          //     )),
                          ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.circle,
                              color: Colors.red,
                              size: 11,
                            ),
                            subtitle: Container(
                                height: 50.0,
                                width: double.infinity,
                                // margin: EdgeInsets.only(
                                //     left: 20, right: 20, bottom: 6, top: 13),
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
                                        hintText: "Pickup location",
                                        hintStyle: TextStyle(
                                          color: Colors.black45,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16,
                                        ),
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                          fontFamily: "Ubuntu",
                                          fontWeight: FontWeight.w500,
                                          fontSize: 17,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.only(
                                            left: 15),
                                      ),
                                      controller: pickupController,
                                      onTap: () async {
                                        setState(() {
                                          _clearPickupRecord();
                                        });
                                        Prediction p =
                                        await PlacesAutocomplete.show(
                                            context: context,
                                            apiKey: AppData.mapAPIKey,
                                            mode: Mode.fullscreen,
                                            logo: Icon(Icons.search,
                                                color: Colors.transparent),
                                            language: "en",
                                            hint: 'Search pickup location',
                                            components: [
                                              new Component(
                                                  Component.country, "ng"),
                                            ]);
                                        displayPredictionPickup(p);
                                      },
                                    ),
                                  ],
                                )),
                          ),
                          SizedBox(height: 6),
                          ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.circle,
                              color: Colors.green,
                              size: 11,
                            ),
                            subtitle: Container(
                                height: 50.0,
                                width: double.infinity,
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
                                        hintText: "Dropoff location",
                                        hintStyle: TextStyle(
                                          color: Colors.black45,

                                          fontWeight: FontWeight.w400,
                                          fontSize: 16,
                                        ),
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                          fontFamily: "Ubuntu",
                                          fontWeight: FontWeight.w500,
                                          fontSize: 17,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.only(
                                            left: 15),
                                      ),
                                      controller: destinationController,
                                      onTap: () async {
                                        setState(() {
                                          _clearDestinationRecord();
                                        });
                                        Prediction p =
                                            await PlacesAutocomplete.show(
                                                context: context,
                                                apiKey: AppData.mapAPIKey,
                                                mode: Mode.fullscreen,
                                                language: "en",
                                                logo: Icon(Icons.search,
                                                    color: Colors.transparent),
                                                hint: 'Search destination',
                                                components: [
                                              new Component(
                                                  Component.country, "ng")
                                            ]);
                                        displayPredictionDestination(p);
                                      },
                                    ),
                                  ],
                                )),
                          ),
                          SizedBox(height: 15),
                          InkWell(
                            child: Container(
                                height: 47,
                                alignment: Alignment.center,
                                margin: EdgeInsets.only(
                                    left: 20, right: 20, bottom: 8),
                                decoration: BoxDecoration(
                                  color: _placeDistance != null
                                      ? AppColor.primaryPepper
                                      : Colors.grey.withOpacity(0.5),
                                  borderRadius: Radii.k25pxAll,
                                ),
                                child: Text(
                                    _placeDistance != null
                                        ? 'Order ride'
                                        : 'Calculate price',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Ubuntu',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400))),
                            onTap: () => _placeDistance != null
                                ? _processLocations()
                                : null,
                            splashColor: Colors.grey[300],
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ));
  }

  void _resetState() {
    setState(() {
      _clearDestinationRecord();
      _clearPickupRecord();
      _clearMapRecords();
    });
  }

  _clearDestinationRecord() {
    destinationController.clear();
    destinationCoordinate = {};
    destination = null;
    _clearRideDetails();
    final int markerId = markersList
        .indexWhere((element) => element.markerId == MarkerId('pickupMarker'));
    if (markerId > -1) {
      markersList.removeAt(markerId);
    }
  }

  _clearPickupRecord() {
    pickupController.clear();
    pickupCoordinate = {};
    pickupPoint = null;
    _clearRideDetails();
    final int markerId = markersList
        .indexWhere((element) => element.markerId == MarkerId('pickupMarker'));
    if (markerId > -1) {
      markersList.removeAt(markerId);
    }
  }

  _clearRideDetails() {
    routeCoords.clear();
    polyline.clear();
    _placeDistance = null;
    _distanceCovered = null;
    _placeTime = null;
    _ridePrice = null;
  }

  _clearMapRecords() {
    markersList.clear();
    routeCoords.clear();
    polyline.clear();
  }

  @override
  void dispose() {
    mapController.dispose();
    destinationController.dispose();
    pickupController.dispose();
    if (mounted) {
      _resetState();
    }
    super.dispose();
  }

  _deliveryDetails() => Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.only(left: 15, right: 20, bottom: 5, top: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset('assets/svg/scooter.svg',
                height: 50, semanticsLabel: 'search icon'),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated time:',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: "Ubuntu",
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text('$_placeTime' ' / ' '$_placeDistance' 'km',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: "Ubuntu",
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      )),
                ],
              ),
            ),
            Expanded(
                flex: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Fare estimate:',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: "Ubuntu",
                        color: Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(currencyFormatter.format(_ridePrice),
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: "Roboto",
                          color: AppColor.primaryPepper,
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
              "You\'re welcome,",
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
            margin: EdgeInsets.only(left: 20, top: 3, bottom: 8),
            child: new Text(
              "Do you have any errands?",
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

  Future<void> zoomToFit(GoogleMapController controller, LatLngBounds bounds,
      LatLng centerBounds) async {
    bool keepZoomingOut = true;

    while (keepZoomingOut) {
      final LatLngBounds screenBounds = await controller.getVisibleRegion();
      if (fits(bounds, screenBounds)) {
        keepZoomingOut = false;
        final double zoomLevel = await controller.getZoomLevel() - 0.5;
        controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: centerBounds,
          zoom: zoomLevel,
        )));
        break;
      } else {
        final double zoomLevel = await controller.getZoomLevel() - 0.1;
        controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: centerBounds,
          zoom: zoomLevel,
        )));
      }
    }
  }

  bool fits(LatLngBounds fitBounds, LatLngBounds screenBounds) {
    final bool northEastLatitudeCheck =
        screenBounds.northeast.latitude >= fitBounds.northeast.latitude;
    final bool northEastLongitudeCheck =
        screenBounds.northeast.longitude >= fitBounds.northeast.longitude;

    final bool southWestLatitudeCheck =
        screenBounds.southwest.latitude <= fitBounds.southwest.latitude;
    final bool southWestLongitudeCheck =
        screenBounds.southwest.longitude <= fitBounds.southwest.longitude;

    return northEastLatitudeCheck &&
        northEastLongitudeCheck &&
        southWestLatitudeCheck &&
        southWestLongitudeCheck;
  }

  _applicationSubmittedAlert() {
    if (widget.arguments != null && widget.arguments.showSnackBar) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        AlertBar.dialog(context,
            'Request has been sent. You will be contacted soon.', Colors.green,
            icon: Icon(
              Icons.check_circle_outline,
              color: Colors.green,
            ),
            duration: 10);
      });
    }
  }

  _accountBlockedAlert() {
    if (widget.arguments != null &&
        widget.arguments.showAccountBlockedSnackBar) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content:
              Text('Your account has been blocked. Contact admin for help'),
        ));
      });
    }
  }
}

class PickrrAppBar extends StatefulWidget {
  @override
  _PickrrAppBarState createState() => _PickrrAppBarState();
}

class _PickrrAppBarState extends State<PickrrAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      brightness: Brightness.light,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.only(left: 10),
                child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.menu_sharp,
                        size: 22,
                        color: Colors.black,
                      ),
                    )),
              ),
            ],
          ),
          onTap: () {
            Scaffold.of(context).openDrawer();
          }),


      actions: [
        Row(
          children: [
            BlocBuilder<AuthenticationBloc, AuthenticationState>(
                builder: (_, state) {
              if (state is NonLoggedIn) {
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => Navigator.pushReplacementNamed(context, '/'));
              }
              if (state.props.isEmpty) {
                return Container();
              }
              User user = state.props[0];
              return RaisedButton.icon(
                onPressed: () {
                  if (user.isDriver) {
                    Navigator.pushNamed(
                      context,
                      '/DriversHomePage',
                    );
                    return;
                  }
                  if (user.isBusiness) {
                    Navigator.pushNamed(
                      context,
                      '/BusinessHomePage',
                    );
                    return;
                  }
                  Navigator.pushNamed(
                    context,
                    '/DriverOnboard',
                  );
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0))),
                label: Container(
                  margin: EdgeInsets.only(right: 5, top: 10, bottom: 10),
                  child: user.isDriver
                      ? Text('Open as rider',
                          style: TextStyle(
                              fontSize: 13.6,
                              fontFamily: 'Ubuntu',
                              color: Colors.white,
                              fontWeight: FontWeight.w400))
                      : user.isBusiness
                          ? Text('Open as business',
                              style: TextStyle(
                                  fontSize: 13.6,
                                  fontFamily: 'Ubuntu',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400))
                          : Text('Become a rider',
                              style: TextStyle(
                                  fontSize: 13.6,
                                  fontFamily: 'Ubuntu',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400)),
                ),
                icon: Container(
                  margin: EdgeInsets.only(left: 5, top: 10, bottom: 10),
                  child: SvgPicture.asset('assets/svg/kargo_bike.svg',
                      height: 20, semanticsLabel: 'Bike Icon'),
                ),
                textColor: Colors.white,
                splashColor: Colors.yellowAccent,
                color: AppColor.primaryText,
                elevation: 5,
              );
            }),
            SizedBox(width: 15)
          ],
        ),
      ],
    );
  }
}
