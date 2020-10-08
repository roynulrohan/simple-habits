import 'package:flutter/material.dart';
import 'package:launch_review/launch_review.dart';
import 'package:share/share.dart';
import 'package:simple_habits/globals.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key key}) : super(key: key);

  // function to create card's, avoiding unnecessary repitition of code
  Widget _makeCard(Widget child) {
    return Container(
      padding: EdgeInsets.only(top: 5),
      alignment: Alignment.topCenter,
      child: Card(
          elevation: 10,
          child:
              Container(alignment: Alignment.center, height: 80, child: child)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('About'),
        ),
        body: Container(
          padding: EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
          child: Column(children: [
            _makeCard(ListTile(
              leading: Column(
                children: [Icon(Icons.share, color: themeColor)],
                mainAxisAlignment: MainAxisAlignment.center,
              ),
              title: Text('Share this app', style: TextStyle(fontSize: 14)),
              subtitle: Text(
                'Send or copy the link',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Share.share(
                    'https://play.google.com/store/apps/details?id=com.roynulrohan.simple_habits');
              },
            )),
            _makeCard(ListTile(
              leading: Column(
                children: [
                  Icon(
                    Icons.star,
                    color: themeColor,
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.center,
              ),
              title: Text('Rate the App', style: TextStyle(fontSize: 14)),
              subtitle: Text(
                'If you like it, consider giving it a rating!',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                LaunchReview.launch();
              },
            )),
            _makeCard(ListTile(
              leading: Column(
                children: [Icon(Icons.mail, color: themeColor)],
                mainAxisAlignment: MainAxisAlignment.center,
              ),
              title: Text('Contact', style: TextStyle(fontSize: 14)),
              subtitle: Text(
                'For feedback, support, or enquiries',
                style: TextStyle(fontSize: 12),
              ),
              onTap: launchURL,
            )),
            _makeCard(ListTile(
              leading: Column(
                children: [Icon(Icons.info, color: themeColor)],
                mainAxisAlignment: MainAxisAlignment.center,
              ),
              title: Text('App Version', style: TextStyle(fontSize: 14)),
              subtitle: Text('1.0.0', style: TextStyle(fontSize: 12)),
            ))
          ]),
        ));
  }
}
