import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gyalcuser_project/screens/authentication/Login/login.dart';
import 'package:gyalcuser_project/screens/orderHistory/orderHistory_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../providers/userProvider.dart';
import '../screens/HelpAndSupport.dart';
import '../screens/home/home_page.dart';
import '../screens/myOrders.dart';
import '../screens/notifications.dart';
import '../screens/profile/profileScreen.dart';
import 'custom_text.dart';

class AppMenu extends StatefulWidget{

  @override
  State<AppMenu> createState() => _AppMenuState();
}

class _AppMenuState extends State<AppMenu> {
  Future<void> handleSignOut() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString("userId", "null");
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => Login()),
          (Route<dynamic> route) => false,
    );
    Fluttertoast.showToast(msg: "Logged Out Successfully");
  }

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    return Container(
      color: Colors.white,
      width: MediaQuery.of(context).size.width*0.75,
      child: ListView(
            children: [
              Container(
                  color: orange,
                  child: Padding(
                    padding: EdgeInsets.only(top: 20.0, left: 10,bottom: 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap:()=>  Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>ProfileScreen()),),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child:Container(
                              width: 100,
                              height: 100,
                              padding: const EdgeInsets.only(
                                top: 20.0,
                                bottom: 16.0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: white,width: 2),
                              ),
                              child: userProvider.image.isNotEmpty
                                  ? Image.network(
                                    userProvider.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, object, stackTrace) {
                                      return const Icon(
                                        Icons.account_circle,
                                        size: 90,
                                        color: white,
                                      );
                                    },
                                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return SizedBox(
                                        width: 90,
                                        height: 90,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: white,
                                            value: loadingProgress.expectedTotalBytes != null &&
                                                loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                  :const Icon(
                                Icons.account_circle,
                                size: 90,
                                color: white,
                              )

                            ),


                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userProvider.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle( fontSize: 15, fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                              ),
                              Text(
                                userProvider.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  )),

              ListTile(
                leading: Icon(
                  Icons.home,
                  color: Color.fromRGBO(251, 176, 59, 1),
                ),
                title: CustomText(text: "Home"),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => HomePage()));
                },
              ),
              ListTile(
                leading: Icon(
                  FontAwesomeIcons.clipboardList,
                  color: Color.fromRGBO(251, 176, 59, 1),
                ),
                title: CustomText(text:  "My Orders"),
                onTap: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => MyOrders()));
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.account_balance_wallet,
                  color: Color.fromRGBO(251, 176, 59, 1),
                ),
                title: CustomText(text:  "My Wallet"),
                onTap: () {
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.history,
                  color: Color.fromRGBO(251, 176, 59, 1),
                ),
                title: CustomText(text: "Order History"),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => orderHistory()));
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: Color.fromRGBO(251, 176, 59, 1),
                ),
                title: CustomText(text: "Notifications"),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Notifications()));
                },
              ),
              ListTile(
                leading: Icon(
                  FontAwesomeIcons.gear,
                  color: Color.fromRGBO(251, 176, 59, 1),
                ),
                title: CustomText(text:"Help & Support"),
                onTap: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => HelpAndSupport()));
                },
              ),
              ListTile(
                leading: Icon(
                  FontAwesomeIcons.globe,
                  color: Color.fromRGBO(251, 176, 59, 1),
                ),
                title: CustomText(text:"Language"),
                onTap: () {

                },
              ),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Color.fromRGBO(251, 176, 59, 1),
                ),
                title: CustomText(text: "Logout"),
                onTap: () {
                  showAlertDialog(context);

                },
              )
            ],
          ),
    );
  }

  showAlertDialog(BuildContext context) {

    Widget okButton = FlatButton(
      child: Text("Ok"),
      onPressed: () {
        handleSignOut();
      },
    );

    Widget noButton = FlatButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();

      },
    );

    // Create AlertDialog
    AlertDialog alert = AlertDialog(
      //title: Text("Simple Alert"),
      content: Text("Do you want to Logout ?"),
      actions: [okButton, noButton],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}