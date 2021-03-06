import 'package:flutter/material.dart';
import 'package:pickrr_app/src/helpers/constants.dart';
import 'package:pickrr_app/src/utils/show_up_animation.dart';

class Onboard extends StatelessWidget {
  final int delayAmount = 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(right: 20, left: 20, top: 30),
              child: Image.asset(
                'assets/images/courier_onboard.png',
                width: MediaQuery.of(context).size.width,
              ),
            ),
            Expanded(
              child: Container(
                  height: MediaQuery.of(context).size.height / 2,
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.only(left: 30, bottom: 30, right: 30),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        ShowUp(
                          child: Hero(
                            tag: 'input_phon_auth_title',
                            flightShuttleBuilder: _flightShuttleBuilder,
                            child: Text(
                              'Welcome to CourierAsap',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 25,
                                  fontFamily: 'Ubuntu',
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                          delay: delayAmount + 1000,
                        ),
                        SizedBox(height: 12),
                        ShowUp(
                          child: Hero(
                            tag: 'body_text_splash',
                            child: Text(
                              'Your No. 1 plug for all deliveries within Portharcourt and environs.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: 'Ubuntu',
                                  fontWeight: FontWeight.w500,
                                  height: 1.3),
                            ),
                          ),
                          delay: delayAmount + 1500,
                        ),
                        SizedBox(height: 25),
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
                                  'Get started',
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
                              Navigator.pushNamed(context, '/Login');
                            },
                          ),
                          delay: delayAmount + 2300,
                        ),
                      ])),
            ),
          ],
        ));
  }
}

Widget _flightShuttleBuilder(
    BuildContext context,
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
