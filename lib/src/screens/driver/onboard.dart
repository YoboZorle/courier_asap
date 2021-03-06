import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pickrr_app/src/utils/show_up_animation.dart';
import 'package:pickrr_app/src/helpers/constants.dart';

class DriverOnboard extends StatelessWidget {
  final int delayAmount = 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.white,
          brightness: Brightness.light,
          actions: [
            GestureDetector(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(left: 0.0),
                height: 40,
                width: 100,
                child: Text(
                  'Go back',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Ubuntu',
                    color: AppColor.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: 20, left: 20, top: 30),
                child: Image.asset(
                  'assets/images/driver_onboard.png',
                  width: MediaQuery.of(context).size.width,
                ),
              ),
              flex: 1,
            ),
            Expanded(
              child: Container(
                  height: MediaQuery.of(context).size.height / 2.4,
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.only(left: 30, bottom: 30, right: 30),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ShowUp(
                          child: Hero(
                            tag: 'input_phon_auth_title',
                            flightShuttleBuilder: _flightShuttleBuilder,
                            child: Text(
                              'Become A Driver On\nCourierAsap?',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 27,
                                  fontFamily: 'Ubuntu',
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                          delay: delayAmount + 800,
                        ),
                        SizedBox(height: 12),
                        ShowUp(
                          child: Hero(
                              tag: 'body_text_splash',
                              child: Text(
                                'CourierAsap helps you earn by managing your rides and providing you ride requests. ',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontFamily: 'Ubuntu',
                                    fontWeight: FontWeight.w500,
                                    height: 1.3),
                              )),
                          delay: delayAmount + 1500,
                        ),
                        SizedBox(height: 30),
                        ShowUp(
                          child: GestureDetector(
                            child: Container(
                              height: 47,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColor.primaryPepper,
                                    AppColor.primaryPepper,
                                    AppColor.primaryPepper,
                                    AppColor.primaryPepper,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Start Now',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontFamily: "Ubuntu",
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                    letterSpacing: 0.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {
                              _settingModalBottomSheet(context);
                            },
                          ),
                          delay: delayAmount + 2400,
                        ),
                      ])),
              flex: 2,
            ),
          ],
        ));
  }

  void _settingModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: new Wrap(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(bottom: 0, top: 12),
                  child: ListTile(
                    leading: new Text('Select Your Plan',
                        style: TextStyle(
                            fontFamily: 'Ubuntu',
                            fontSize: 17,
                            color: AppColor.primaryText,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                Card(
                  elevation: 0,
                  child: new ListTile(
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 2, right: 3),
                        child: SvgPicture.asset('assets/svg/personal.svg',
                            height: 37, semanticsLabel: 'search icon'),
                      ),
                      title: new Text('Personal account',
                          style: TextStyle(
                              fontFamily: 'Ubuntu',
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w500)),
                      subtitle: Text('Manage your bike and earnings',
                          style: TextStyle(
                              fontFamily: 'Ubuntu',
                              fontSize: 15,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400)),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/DriverApplication');
                      }),
                ),
                Card(
                  elevation: 0,
                  child: new ListTile(
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 2, right: 3),
                        child: SvgPicture.asset('assets/svg/business.svg',
                            height: 37, semanticsLabel: 'search icon'),
                      ),
                      title: new Text('Business account',
                          style: TextStyle(
                              fontFamily: 'Ubuntu',
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w500)),
                      subtitle: Text('Register and manage all your bikes.',
                          style: TextStyle(
                              fontFamily: 'Ubuntu',
                              fontSize: 15,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400)),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                      onTap: () =>
                          Navigator.pushNamed(context, '/BusinessApplication')),
                ),
              ],
            ),
          );
        });
  }
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
