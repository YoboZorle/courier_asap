import 'package:flutter/material.dart';
import 'package:list_tile_switch/list_tile_switch.dart';
import 'package:pickrr_app/src/models/driver.dart';
import 'package:pickrr_app/src/services/repositories/business.dart';
import 'package:pickrr_app/src/widgets/image.dart';

import '../../driver_reviews.dart';

class DriverActivitiesDetails extends StatefulWidget {
  final int riderId;

  DriverActivitiesDetails(this.riderId);

  @override
  _DriverActivitiesDetailsState createState() =>
      _DriverActivitiesDetailsState();
}

class _DriverActivitiesDetailsState extends State<DriverActivitiesDetails> {
  final BusinessRepository _businessRepository = BusinessRepository();
  bool _driverStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        brightness: Brightness.light,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Your Driver',
          style: TextStyle(
              fontFamily: "Ubuntu",
              fontSize: 17.0,
              color: Colors.black,
              fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_outlined,
              color: Colors.black,
              size: 20,
            )),
      ),
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          physics: BouncingScrollPhysics(),
          headerSliverBuilder: (context, _) {
            return [
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    FutureBuilder(
                        builder: (BuildContext context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.none ||
                              snapshot.hasData == null ||
                              !snapshot.hasData) {
                            return Container();
                          }
                          final Driver driverDetails = snapshot.data;
                          _driverStatus = driverDetails.status == 'A'
                              ? true
                              : false;
                          return Column(
                            children: [
                              SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(right: 20,left: 20),
                                    child: ClipOval(
                                        child: Container(
                                      height: 85.0,
                                      width: 85.0,
                                      child: !driverDetails.details.noProfileImage
                                          ? CustomImage(
                                              imageUrl:
                                                  '${driverDetails.details.profileImageUrl}',
                                            )
                                          : Image.asset(
                                              'assets/images/placeholder.jpg',
                                              width: double.infinity,
                                              height: double.infinity),
                                    )),
                                  ),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 4),
                                        Text(
                                            '${driverDetails.bikeBrand} - ${driverDetails.plateNumber}',
                                            style: TextStyle(
                                                fontSize: 12.0,
                                                height: 1.3,
                                                fontFamily: "Ubuntu",
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w400)),
                                        Text(
                                          driverDetails.details.fullname,
                                          style: TextStyle(
                                              fontSize: 16.0,
                                              height: 1.3,
                                              fontFamily: "Ubuntu",
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                            'Ticket ID - ${driverDetails.ticketNumber}',
                                            style: TextStyle(
                                                fontSize: 12.0,
                                                fontFamily: "Ubuntu",
                                                color: Colors.grey,
                                                height: 1.4,
                                                fontWeight: FontWeight.w400)),
                                        Text(driverDetails.details.phone,
                                            style: TextStyle(
                                                fontSize: 13.0,
                                                height: 1.3,
                                                fontFamily: "Ubuntu",
                                                color: Colors.black,
                                                fontWeight: FontWeight.w400)),
                                        Text(driverDetails.details.email,
                                            style: TextStyle(
                                                fontSize: 13.0,
                                                fontFamily: "Ubuntu",
                                                color: Colors.black,
                                                height: 1.3,
                                                fontWeight: FontWeight.w400))
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                  height: 0.7,
                                  margin: EdgeInsets.only(
                                      top: 15, left: 20, right: 20),
                                  width: MediaQuery.of(context).size.width,
                                  color: Colors.grey[300]),
                              Card(
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0.0, horizontal: 15),
                                  child: ListTileSwitch(
                                    contentPadding: EdgeInsets.all(0),
                                    value: _driverStatus,
                                    onChanged: (value) {
                                      setState(() {
                                        _driverStatus = value;
                                      });
                                      _updateRiderStatus(
                                          value == true ? 'A' : 'NA');
                                    },
                                    toggleSelectedOnValueChange: true,
                                    subtitle: Text(
                                        'Toggle button to activate or deactivate your driver.',
                                        style: TextStyle(
                                            fontSize: 13.0,
                                            fontFamily: "Ubuntu",
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w400,
                                            height: 1.5)),
                                    switchActiveColor: Colors.green,
                                    switchType: SwitchType.material,
                                    title: Text(
                                        driverDetails.status == 'A'
                                            ? 'Driver Available'
                                            : 'Driver Unavailable',
                                        style: TextStyle(
                                            fontSize: 15.0,
                                            fontFamily: "Ubuntu",
                                            fontWeight: FontWeight.w400,
                                            height: 1.6)),
                                  ),
                                ),
                              ),
                              Container(
                                  height: 0.7,
                                  margin: EdgeInsets.only(top: 10),
                                  width: MediaQuery.of(context).size.width,
                                  color: Colors.grey[300]),
                            ],
                          );
                        },
                        future: _businessRepository
                            .getDriverFromStorage(widget.riderId)),
                  ],
                ),
              ),
            ];
          },
          body: Column(
            children: <Widget>[
              TabBar(
                unselectedLabelColor: Colors.grey,
                labelColor: Colors.black,
                indicatorPadding: EdgeInsets.only(left: 50, right: 50, top: 50),
                indicatorWeight: 3,
                unselectedLabelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Ubuntu'),
                labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Ubuntu'),
                physics: BouncingScrollPhysics(),
                tabs: [
                  Tab(text: 'Rides'),
                  Tab(text: 'Reviews'),
                  Tab(text: 'Transactions'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  physics: BouncingScrollPhysics(),
                  children: [
                    Center(child: Text('First here')),
                    DriverReviews(),
                    Center(child: Text('Third here'))
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _updateRiderStatus(String status) async {
    await _businessRepository.updateDriverStatus(
        status: status, riderId: widget.riderId);
  }
}