import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gyalcuser_project/screens/delivery_form/delivery_form.dart';
import 'package:gyalcuser_project/screens/delivery_form/pickUp_form.dart';
import 'package:gyalcuser_project/services/fcm_services.dart';
import 'package:gyalcuser_project/utils/innerShahdow.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../constants/colors.dart';
import '../../constants/text_style.dart';
import '../../constants/toast_utils.dart';
import '../../models/delivery_model.dart';
import '../../providers/create_delivery_provider.dart';
import '../../providers/userProvider.dart';
import '../../utils/app_colors.dart';
import '../../utils/image.dart';
import '../../widgets/App_Menu.dart';
import '../../widgets/custom_radio.dart';
import '../pay/payment_screen.dart';
import 'date_time_piker/date_timer_piker.dart';
import 'package:get/get.dart';

class CreateDeliveryForm extends StatefulWidget {
  const CreateDeliveryForm({Key? key}) : super(key: key);

  @override
  _CreateDeliveryFormState createState() => _CreateDeliveryFormState();
}

class _CreateDeliveryFormState extends State<CreateDeliveryForm> {
  int selectedRadio = 1;
  int selectedRadioParcel = 1;
  int selectedRadio1 = 0;
  bool selectedCheck = true;

  late CreateDeliveryProvider deliveryProvider;
  DateTime now = DateTime.now();
  var currentDateTime;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _userProvider = Provider.of<UserProvider>(context, listen: false);
    deliveryProvider =
        Provider.of<CreateDeliveryProvider>(context, listen: false);
    currentDateTime = DateFormat('yyyy-MM-dd kk:mm:ss').format(now);
    deliveryProvider.vehicle = "CAR";
    deliveryProvider.parcel = "UP TO 10000 MNT";
  }

  var list = [
    {
      'title': 'CAR',
      'image': carimage,
    },
    {
      'title': 'MINI TRUCK',
      'image': miniTruckimage,
    },
    {
      'title': 'BIKE',
      'image': cycleimage,
    },
    {
      'title': 'SCOOTER',
      'image': scooterimage,
    },
    {
      'title': 'TRUCK',
      'image': truckimage,
    },
    {
      'title': 'VAN',
      'image': vanimage,
    },
  ];

  late UserProvider _userProvider;
  bool isLoading = false;

  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String orderId = const Uuid().v1();
  bool setLoading = false;

  //FOR ADDING DELIVERY PROVIDER
  Future createDelivery() async {
    var rnd = math.Random();
    var next = rnd.nextDouble() * 1000000;
    while (next < 100000) {
      next *= 10;
    }
    try {
      DeliveryModel addInfo = DeliveryModel(
          createdAt: DateTime.now(),
          trackStatus: "Pending",
          pickupAddress: deliveryProvider.pickAddress.text.toString(),
          pickupName: deliveryProvider.pickName.text.toString(),
          pickupEmail: deliveryProvider.pickEmail.text.toString(),
          pickupPhone: deliveryProvider.pickPhone.text.toString(),
          pickupParcelName: deliveryProvider.pickParcelName.text.toString(),
          pickupParcelWeight: deliveryProvider.pickParcelWeight.text,
          pickupParcelDesc: deliveryProvider.pickDescription.text.toString(),
          pickupDeliveryPrice: deliveryProvider.pickPrice.text,
          deliveryAddress: deliveryProvider.deliveryAddress.text.toString(),
          deliveryName: deliveryProvider.deliveryName.text.toString(),
          deliveryEmail: deliveryProvider.deliveryEmail.text.toString(),
          deliveryPhone: deliveryProvider.deliveryPhone.text.toString(),
          deliveryParcelDesc:
              deliveryProvider.deliveryDescription.text.toString(),
          parcel: deliveryProvider.parcel,
          checkIllegal: selectedCheck.toString(),
          vehicle: deliveryProvider.vehicle.toString(),
          orderDate: deliveryProvider.date.toString() == ""
              ? currentDateTime
              : deliveryProvider.date.toString(),
          orderTime: deliveryProvider.time.toString() == ""
              ? currentDateTime
              : deliveryProvider.time.toString(),
          pickupLat: deliveryProvider.pickupLat,
          pickupLong: deliveryProvider.pickupLong,
          distance: deliveryProvider.distance,
          driverId: "",
          userName: _userProvider.fullName,
          userid: _auth.currentUser!.uid,
          orderStatus: "Pending",
          orderType: deliveryProvider.scheduleOrder,
          deliveryLong: deliveryProvider.deliveryLong,
          deliveryLat: deliveryProvider.deliveryLat,
          tracking: "",
          orderID: next.toInt().toString(),
          rejectCount: 0,
          rejections: [],
          time: deliveryProvider.duration);
      firebaseFirestore
          .collection("orders")
          .doc(next.toInt().toString())
          .set(addInfo.toJson())
          .then((data) async {
        setState(() {
          deliveryProvider.orderId = next.toInt().toString();
          isLoading = false;
          setLoading = true;
          seconds = 60;
        });
        _countTimer(next.toInt().toString());
        addDataToUserDB(
            next.toInt().toString(),
            "Pending",
            deliveryProvider.pickAddress.text.toString(),
            deliveryProvider.deliveryAddress.text.toString(),
            deliveryProvider.distance,
            deliveryProvider.duration,
            "",
            deliveryProvider.vehicle,
            deliveryProvider.pickPrice.text);
        FCMServices.sendFCM(
            "driver", "all", "New Request", "User Create a new Request");
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  int seconds = 60;
  var rejectCount;
  Timer? _timer;

  addDataToUserDB(orderId, orderStatus, pAddress, dAddress, distance, time,
      driverId, vehicle, price) async {
    try {
      firebaseFirestore
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("orders")
          .doc(orderId)
          .set({
        "OrderStatus": orderStatus,
        "destinationAddress": dAddress,
        "orderPrice": price,
        "pickupAddress": pAddress,
        "distance": distance,
        "duration": time,
        "vehicleType": vehicle,
        "driverId": driverId,
        "driverImage": '',
        'driverName': '',
        'driverPhone': '',
      }).then((data) async {
        setState(() {
          isLoading = false;
        });
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
      firebaseFirestore
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("notifications")
          .doc(orderId)
          .set({
            "msg": "Order $orderId has been placed successfully",
            "status": "pending",
            "timestamp": FieldValue.serverTimestamp(),
            "title": "Order Placed",
          })
          .then((data) async {})
          .catchError((err) {
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: err.toString());
          });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void _countTimer(String id) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (seconds > 0) {
            seconds--;
            getUpdate(id);
          } else {
            _timer!.cancel();
            timer.cancel();
            setState(() {
              isLoading = false;
              seconds = 0;
              setLoading = false;
            });
            ToastUtils.showWarningToast(context, "Warning",
                "Please retry again, no driver accepted your request.");
            firebaseFirestore
                .collection("users")
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .collection("notifications")
                .doc(id)
                .set({
              "msg": "Order $id was not accepted.",
              "status": "failed",
              "timestamp": FieldValue.serverTimestamp(),
              "title": "Order Failed",
            });
            final collection = FirebaseFirestore.instance.collection('orders');
            collection
                .doc(id) // <-- Doc ID to be deleted.
                .delete() // <-- Delete
                .then((_) => log('Deleted'))
                .catchError((error) => log('Delete failed: $error'));
            final collection2 = FirebaseFirestore.instance.collection('users');
            collection2
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .collection("orders")
                .doc(id)
                .delete() // <-- Delete
                .then((_) => log('Deleted'))
                .catchError((error) => log('Delete failed: $error'));
          }
        });
      }
    });
  }

  getUpdate(String id) async {
    firebaseFirestore.collection("orders").doc(id).get().then((value) {
      if (mounted) {
        setState(() {
          deliveryProvider.driverId = value.data()!["driverId"].toString();
          deliveryProvider.rejectionCount = value.data()!["rejectCount"];
        });
      }
    });

    if (deliveryProvider.driverId != "") {
      firebaseFirestore
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("notifications")
          .doc(id)
          .set({
        "msg": "Order $id accepted by driver ${deliveryProvider.driverId}",
        "status": "accepted",
        "timestamp": FieldValue.serverTimestamp(),
        "title": "Order Accepted",
      }).then((data) async {
        firebaseFirestore
            .collection("orders")
            .doc(id)
            .update({"trackStatus": "Accepted"});
        setState(() {
          isLoading = false;
          seconds = 0;
          setLoading = false;
        });
        _timer!.cancel();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PaymentScreen(orderId: id.toString())));
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    } else if (deliveryProvider.rejectionCount ==
        deliveryProvider.driverLength) {
      firebaseFirestore
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("notifications")
          .doc(id)
          .set({
        "msg":
            "Order $id rejected by all drivers. Increase your price so you get more attention of drivers.",
        "status": "rejected",
        "timestamp": FieldValue.serverTimestamp(),
        "title": "Order Rejected",
      }).then((data) async {
        setState(() {
          isLoading = false;
          seconds = 0;
          setLoading = false;
        });
        _timer!.cancel();
        Fluttertoast.showToast(
            msg:
                "Delivery got rejected by all drivers, increase price and again add order.",
            textColor: Colors.white,
            backgroundColor: Colors.red);
        final collection = FirebaseFirestore.instance.collection('orders');
        collection
            .doc(id) // <-- Doc ID to be deleted.
            .delete() // <-- Delete
            .then((_) {
          final collection2 = FirebaseFirestore.instance.collection('users');
          collection2
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection("orders")
              .doc(id)
              .delete() // <-- Delete
              .then((_) => log('Deleted'))
              .catchError((error) => log('Delete failed: $error'));
          Future.delayed(Duration(seconds: 2), () {
            Navigator.of(context).pop(true);
          });
        }).catchError((error) => log('Delete failed: $error'));
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    } else {}
  }

  bool isPick = false;
  bool isDeliver = false;

  @override
  void dispose() {
    super.dispose();
    _timer!.cancel();
    deliveryProvider.scheduleOrder = "";
    deliveryProvider.parcel = "";
    deliveryProvider.date = "";
    deliveryProvider.time = "";
    deliveryProvider.vehicle = "";
    deliveryProvider.pickupLat = "";
    deliveryProvider.pickupLong = "";
    deliveryProvider.deliveryLat = "";
    deliveryProvider.deliveryLong = "";
    deliveryProvider.distance = "";
    deliveryProvider.duration = "";
    deliveryProvider.rejectionCount = 0;
    deliveryProvider.pickEmail.text = "";
    deliveryProvider.pickAddress.text = "";
    deliveryProvider.pickName.text = "";
    deliveryProvider.pickPhone.text = "";
    deliveryProvider.pickParcelName.text = "";
    deliveryProvider.pickParcelWeight.text = "";
    deliveryProvider.pickDescription.text = "";
    deliveryProvider.pickPrice.text = "";
    deliveryProvider.deliveryEmail.text = "";
    deliveryProvider.deliveryAddress.text = "";
    deliveryProvider.deliveryName.text = "";
    deliveryProvider.deliveryPhone.text = "";
    deliveryProvider.deliveryDescription.text = "";
  }

  int selectedIndex = 0;
  var scaffoldState = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    bool pickShow = Provider.of<CreateDeliveryProvider>(context).pickUpVisible;
    bool deliveryShow =
        Provider.of<CreateDeliveryProvider>(context).deliveryVisible;

    return Scaffold(
      key: scaffoldState,
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset(
              menuimage,
              width: 30,
              height: 30,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: orange,
        elevation: 5,
        shadowColor: blackLight,
        title: Text('CREATE A DELIVERY TASK'.tr,
            style: TextStyle(
                color: white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'Poppins')),
        centerTitle: true,
      ),
      drawer: AppMenu(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    child: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                deliveryProvider.pickUpVisible =
                                    !deliveryProvider.pickUpVisible;
                                deliveryProvider.deliveryVisible = false;
                                isPick = !isPick;
                                isDeliver = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color:
                                        deliveryProvider.pickUpVisible == false
                                            ? orange
                                            : redOrange,
                                    width:
                                        deliveryProvider.pickUpVisible == false
                                            ? 1
                                            : 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 5,
                                    offset: const Offset(
                                        0, 4), // changes position of shadow
                                  ),
                                ],
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(20.0)),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        pickPhoneimage,
                                        height: 40,
                                        width: 60,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        'PICK-UP DETAILS'.tr,
                                        style: TextStyle(
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.add,
                                    color: AppColors.primaryColor,
                                    size: 30,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                deliveryProvider.deliveryVisible =
                                    !deliveryProvider.deliveryVisible;
                                deliveryProvider.pickUpVisible = false;
                                isDeliver = !isDeliver;
                                isPick = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: deliveryProvider.deliveryVisible ==
                                            false
                                        ? orange
                                        : redOrange,
                                    width: deliveryProvider.deliveryVisible ==
                                            false
                                        ? 1
                                        : 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 5,
                                    offset: const Offset(
                                        0, 4), // changes position of shadow
                                  ),
                                ],
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(20.0)),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        yvanimage,
                                        height: 40,
                                        width: 60,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        'DELIVERY DETAILS'.tr,
                                        style: TextStyle(
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.add,
                                    color: AppColors.primaryColor,
                                    size: 30,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InnerShadow(
                            blur: 5,
                            color: brownDark.withOpacity(0.5),
                            offset: Offset(0, 4),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(20.0)),
                                  border: Border.all(color: orange)),
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "SCHEDULE ORDER".tr,
                                    style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  const Divider(
                                    color: Color(0xfffbb03b),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Row(
                                        children: [
                                          CustomRadioWidget(
                                            value: 1,
                                            groupValue: selectedRadio,
                                            onChanged: (val) {
                                              setState(() {
                                                deliveryProvider.scheduleOrder =
                                                    "rightAway";
                                              });
                                              setSelectedRadio(
                                                  // val
                                                  1);
                                            },
                                          ),
                                          Text(
                                            'RIGHT AWAY'.tr,
                                            style: TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                          )
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          CustomRadioWidget(
                                            value: 2,
                                            groupValue: selectedRadio,
                                            onChanged: (val) {
                                              setState(() {
                                                deliveryProvider.scheduleOrder =
                                                    "scheduleForLater";
                                              });
                                              setSelectedRadio(
                                                  // val
                                                  2);
                                            },
                                          ),
                                          Text(
                                            'SCHEDULE FOR LATER'.tr,
                                            style: TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                          )
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        selectedRadio == 2
                            ? GestureDetector(
                                onTap: () {
                                  showDialog(
                                      barrierColor: orange.withOpacity(0.5),
                                      context: context,
                                      builder: (context) => DateTimeForm());
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                          begin: Alignment.bottomLeft,
                                          end: Alignment.topRight,
                                          colors: [
                                        Color(0xfffe6726),
                                        Color(0xfffbb03b)
                                      ])),
                                  height: 60,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('SELECT TIME & DATE'.tr,
                                            style:
                                                TextStyle(color: Colors.white)),
                                        Image.asset(
                                            'assets/images/calendar.png'),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                        begin: Alignment.bottomLeft,
                                        end: Alignment.topRight,
                                        colors: [
                                      Color(0xfffe6726),
                                      Color(0xfffbb03b)
                                    ])),
                                height: 60,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        children: [
                                          Text("Current Date/Time".tr,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w300)),
                                          Text(currentDateTime.toString(),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      Image.asset('assets/images/calendar.png'),
                                    ],
                                  ),
                                ),
                              ),
                        const SizedBox(
                          height: 20,
                        ),
                        InnerShadow(
                          blur: 5,
                          color: brownDark.withOpacity(0.5),
                          offset: Offset(0, 3),
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.03,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: orange, width: 1),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      'SELECT VEHICLE'.tr,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                                const Divider(
                                  thickness: 2,
                                  color: orange,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 0.0,
                                    runSpacing: 5,
                                    runAlignment: WrapAlignment.center,
                                    children: list.map((e) {
                                      int index = list.indexOf(e);
                                      // return vehicle(
                                      //     index, e['title'], e['image'], () {
                                      //   setState(() {
                                      //     selectedIndex = index;
                                      //     deliveryProvider.vehicle =
                                      //         e['title'].toString();
                                      //   });
                                      // });
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedIndex = index;
                                            deliveryProvider.vehicle =
                                                e['title'].toString();
                                          });
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(bottom: 10),
                                          child: Column(
                                            children: [
                                              Image.asset(e['image'].toString(),
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      .25),
                                              SizedBox(
                                                width: 100,
                                                child: Text(
                                                  "${e['title'].toString()}",
                                                  style: TextStyle(
                                                    fontSize:
                                                        selectedIndex == index
                                                            ? 16
                                                            : 14,
                                                    fontWeight:
                                                        selectedIndex == index
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                    color:
                                                        selectedIndex == index
                                                            ? orange
                                                            : black,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        setLoading == false
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(left: 12.0),
                                    child: Text(
                                      'CHOOSE PARCEL VALUE'.tr,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            CustomRadioWidget(
                                              value: 1,
                                              groupValue: selectedRadioParcel,
                                              onChanged: (val) {
                                                setSelectedRadioParcel(1);
                                              },
                                            ),
                                            Text(
                                              'UP TO 100000 MNT'.tr,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            )
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            CustomRadioWidget(
                                              value: 2,
                                              groupValue: selectedRadioParcel,
                                              onChanged: (val) {
                                                setSelectedRadioParcel(2);
                                              },
                                            ),
                                            Text(
                                              'BETWEEN 100k & 500k MNT'.tr,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            CustomRadioWidget(
                                              value: 3,
                                              groupValue: selectedRadioParcel,
                                              onChanged: (val) {
                                                setSelectedRadioParcel(3);
                                              },
                                            ),
                                            Text(
                                              'BETWEEN 500k & 1 MILLION MNT'.tr,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                            value: selectedCheck,
                                            checkColor: Colors.green,
                                            activeColor: white,
                                            // fillColor: Colors.red,
                                            onChanged: (bool? val) {
                                              setState(() {
                                                selectedCheck = val!;
                                              });
                                            }),
                                        SizedBox(
                                          width: 280,
                                          child: Text(
                                            "Prohibited & illegal item does not \ninclude in this parcel"
                                                .tr
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  isLoading == true
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                          color: brownDark,
                                        ))
                                      : Center(
                                          child: Container(
                                            decoration: BoxDecoration(
                                                boxShadow: [
                                                  BoxShadow(
                                                      offset:
                                                          const Offset(1, 3),
                                                      blurRadius: 5,
                                                      color: black
                                                          .withOpacity(0.45))
                                                ],
                                                border: Border.all(
                                                    color: brownDark),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                color: orange),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 30,
                                            ),
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.5,
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (deliveryProvider
                                                      .pickAddress
                                                      .text
                                                      .isEmpty) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Required".tr,
                                                        "Pickup Address is required"
                                                            .tr);
                                                  } else if (deliveryProvider
                                                      .pickName.text.isEmpty) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Required".tr,
                                                        "Pickup Name is required"
                                                            .tr);
                                                  } else if (deliveryProvider
                                                      .pickPhone.text.isEmpty) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Required".tr,
                                                        "Pickup Phone is required"
                                                            .tr);
                                                  } else if (deliveryProvider
                                                      .pickEmail.text.isEmpty) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Required".tr,
                                                        "Pickup Email is required"
                                                            .tr);
                                                  } else if (RegExp(
                                                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                                          .hasMatch(
                                                              deliveryProvider
                                                                  .pickEmail
                                                                  .text) ==
                                                      false) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Error".tr,
                                                        "Enter a valid email!"
                                                            .tr);
                                                  } else if (deliveryProvider
                                                      .pickParcelName
                                                      .text
                                                      .isEmpty) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Required".tr,
                                                        "Pickup Parcel Name is required"
                                                            .tr);
                                                  } else if (deliveryProvider
                                                      .pickParcelWeight
                                                      .text
                                                      .isEmpty) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Required".tr,
                                                        "Pickup Parcel Weight is required"
                                                            .tr);
                                                  } else if (deliveryProvider
                                                      .pickDescription
                                                      .text
                                                      .isEmpty) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Required".tr,
                                                        "Pickup Parcel Description is required"
                                                            .tr);
                                                  } else if (deliveryProvider
                                                      .pickPrice.text.isEmpty) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Required".tr,
                                                        "Pickup Delivery Price Offer is required"
                                                            .tr);
                                                  } else if (deliveryProvider
                                                      .deliveryAddress
                                                      .text
                                                      .isEmpty) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Required".tr,
                                                        "Delivery Address is required"
                                                            .tr);
                                                  } else if (deliveryProvider
                                                      .deliveryName
                                                      .text
                                                      .isEmpty) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Required".tr,
                                                        "Delivery Name is required"
                                                            .tr);
                                                  } else if (deliveryProvider
                                                      .deliveryPhone
                                                      .text
                                                      .isEmpty) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Required".tr,
                                                        "Delivery Phone is required"
                                                            .tr);
                                                  } else if (deliveryProvider
                                                      .deliveryEmail
                                                      .text
                                                      .isEmpty) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Required".tr,
                                                        "Delivery Email is required"
                                                            .tr);
                                                  } else if (RegExp(
                                                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                                          .hasMatch(
                                                              deliveryProvider
                                                                  .deliveryEmail
                                                                  .text) ==
                                                      false) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Error".tr,
                                                        "Enter a valid email!"
                                                            .tr);
                                                  } else if (deliveryProvider
                                                      .deliveryDescription
                                                      .text
                                                      .isEmpty) {
                                                    ToastUtils.showWarningToast(
                                                        context,
                                                        "Required".tr,
                                                        "Delivery Description is required"
                                                            .tr);
                                                  } else if (deliveryProvider
                                                              .distance ==
                                                          "" &&
                                                      deliveryProvider
                                                              .duration ==
                                                          "") {
                                                    Fluttertoast.showToast(
                                                        msg:
                                                            "Please save delivery details"
                                                                .tr);
                                                  } else {
                                                    log(deliveryProvider
                                                        .distance
                                                        .toString());
                                                    log(deliveryProvider
                                                        .duration
                                                        .toString());
                                                    setState(() {
                                                      isLoading = true;
                                                    });
                                                    createDelivery();
                                                  }
                                                },
                                                child: SizedBox(
                                                  height: 60.0,
                                                  child: Center(
                                                      child: Text(
                                                    "CONFIRM BOOKING".tr,
                                                    style: MyTextStyle
                                                            .poppinsBold()
                                                        .copyWith(
                                                            fontSize: 14.0,
                                                            color:
                                                                Colors.white),
                                                  )),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              )
                            : Container(
                                margin: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(45),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFBB03B),
                                        Color(0xFFFF5922)
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    color: white,
                                    border:
                                        Border.all(color: orange, width: 10)),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Image.asset(
                                        "assets/images/Component 16.png"),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    const SpinKitCircle(
                                      color: white,
                                      size: 120.0,
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Text(
                                      "LOOKING FOR DRIVER".tr,
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: white),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                  ],
                                ),
                              ),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                  pickShow == true || deliveryShow == true
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              deliveryProvider.pickVisibleFalse();
                              deliveryProvider.deliveryVisibleFalse();
                            });
                          },
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.91,
                            // color: AppColors.primaryColor.withOpacity(0.4),
                          ),
                        )
                      : const SizedBox(),
                  Visibility(visible: pickShow, child: PickUpForm()),
                  Visibility(visible: deliveryShow, child: DeliveryForm()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  setSelectedRadio(int val) {
    setState(() {
      selectedRadio = val;
    });

    if (val == 1) {
      setState(() {
        deliveryProvider.scheduleOrder = "rightAway";
      });
    } else if (val == 2) {
      setState(() {
        deliveryProvider.scheduleOrder = "later";
      });
    }
  }

  setSelectedRadioParcel(int val) {
    setState(() {
      selectedRadioParcel = val;

      if (val == 1) {
        deliveryProvider.parcel = "UP TO 10000 MNT".tr;
      } else if (val == 2) {
        deliveryProvider.parcel = "BETWEEN 100K & 500K MNT".tr;
      }
      if (val == 3) {
        deliveryProvider.parcel = "BETWEEN 500K & 1M MNT".tr;
      }
    });
  }

  Widget vehicle(i, title, image, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        child: Column(
          children: [
            Image.asset(image, width: MediaQuery.of(context).size.width * .25),
            SizedBox(
              width: 100,
              child: Text(
                "${title}".tr,
                style: TextStyle(
                  fontSize: selectedIndex == i ? 16 : 14,
                  fontWeight:
                      selectedIndex == i ? FontWeight.bold : FontWeight.normal,
                  color: selectedIndex == i ? orange : black,
                ),
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }
}
