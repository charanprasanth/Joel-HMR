import 'dart:math';

import 'package:cafesio/models/cart_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:intl/intl.dart';

class Cart extends StatefulWidget {
  const Cart({Key? key}) : super(key: key);

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  List<CartItem> cartList = [];
  String uid = FirebaseAuth.instance.currentUser!.uid.toString();

  @override
  void initState() {
    super.initState();
    print('calling init state for cart');

    DatabaseReference reference =
        FirebaseDatabase.instance.ref().child("Cart");
    reference.child(uid).once().then((dataSnapshot) {
      cartList.clear();
      if (dataSnapshot.snapshot.exists) {
        var map = dataSnapshot.snapshot.value as Map;
        var keys = map.keys;
        var values = map.values;

        for (var key in keys) {
          CartItem cartItem = CartItem(
              map[key]["itemName"],
              map[key]["itemPrice"],
              map[key]["itemCount"],
              map[key]["totalPrice"],
              map[key]["itemID"]);
          cartList.add(cartItem);
        }
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    int sum = 0;
    for (int i = 0; i < cartList.length; i++) {
      sum += int.parse(cartList[i].totalPrice);
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: cartList.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xff0e9aa4)))
          : customizedCard(cartList),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        elevation: 3,
        onPressed: () {
          int balance = 0;
          DatabaseReference walletReference =
              FirebaseDatabase.instance.ref().child("Wallet");
          int balanceAmount;
          walletReference
              .child(uid)
              .child("balance")
              .once()
              .then((snapshot) => {
                    if (snapshot.snapshot.exists)
                      {
                        balance = int.parse(snapshot.snapshot.value.toString()),
                        if (balance > sum)
                          {
                            balanceAmount = balance - sum,
                            walletReference
                                .child(uid)
                                .child("balance")
                                .set(balanceAmount.toString())
                                .whenComplete(() => sendToFirebase(sum))
                                .onError((error, stackTrace) =>
                                    print(error.toString())),
                          }
                        else
                          {
                            showToast(
                              "You don't have enough balance",
                              context: context,
                              animation: StyledToastAnimation.fadeScale,
                              reverseAnimation: StyledToastAnimation.fade,
                              position: StyledToastPosition.bottom,
                              animDuration: Duration(seconds: 1),
                              duration: Duration(seconds: 3),
                              curve: Curves.elasticOut,
                              reverseCurve: Curves.linear,
                            )
                          }
                      }
                  });
        },
        label: Text(
          "Confirm Order of ₹" + sum.toString(),
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Color(0xff0e9aa4),
      ),
    );
  }

  customizedCard(List<CartItem> cartList) {
    return Container(
      margin: EdgeInsets.only(left: 15, right: 15),
      child: ListView.separated(
        itemCount: cartList.length,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Container(
              child: Column(
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 75,
                    child: Center(
                      child: Text(
                        "Cart",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text(cartList[index].itemName,
                        style:
                            TextStyle(color: Color(0xff0e9aa4), fontSize: 20)),
                    subtitle: Text("x" + cartList[index].itemCount + " nos"),
                    trailing: Container(
                      width: 120,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            Text(
                              "₹" + cartList[index].totalPrice,
                              style: TextStyle(
                                  color: Colors.green, fontSize: 16.5),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  DatabaseReference reference = FirebaseDatabase
                                      .instance
                                      .reference()
                                      .child("Cart")
                                      .child(FirebaseAuth
                                          .instance.currentUser!.uid);

                                  reference
                                      .child(cartList[index].itemID)
                                      .remove()
                                      .whenComplete(() => {
                                            showToast(
                                              'Item removed from cart',
                                              context: context,
                                              animation: StyledToastAnimation
                                                  .fadeScale,
                                              reverseAnimation:
                                                  StyledToastAnimation.fade,
                                              position:
                                                  StyledToastPosition.bottom,
                                              animDuration:
                                                  Duration(seconds: 1),
                                              duration: Duration(seconds: 3),
                                              curve: Curves.elasticOut,
                                              reverseCurve: Curves.linear,
                                            ),
                                            setState(() {
                                              cartList.removeAt(index);
                                            }),
                                          })
                                      .onError((error, stackTrace) =>
                                          print(error.toString()));
                                }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return ListTile(
              title: Text(cartList[index].itemName,
                  style: TextStyle(color: Color(0xff0e9aa4), fontSize: 20)),
              subtitle: Text("x" + cartList[index].itemCount + " nos"),
              trailing: Container(
                width: 120,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Text(
                        "₹" + cartList[index].totalPrice,
                        style: TextStyle(color: Colors.green, fontSize: 16.5),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            //commit
                            DatabaseReference reference = FirebaseDatabase
                                .instance
                                .reference()
                                .child("Cart")
                                .child(FirebaseAuth.instance.currentUser!.uid);

                            reference
                                .child(cartList[index].itemID)
                                .remove()
                                .whenComplete(() => {
                                      showToast(
                                        'Item removed from cart',
                                        context: context,
                                        animation:
                                            StyledToastAnimation.fadeScale,
                                        reverseAnimation:
                                            StyledToastAnimation.fade,
                                        position: StyledToastPosition.bottom,
                                        animDuration: Duration(seconds: 1),
                                        duration: Duration(seconds: 3),
                                        curve: Curves.elasticOut,
                                        reverseCurve: Curves.linear,
                                      ),
                                      setState(() {
                                        cartList.removeAt(index);
                                      }),
                                    })
                                .onError((error, stackTrace) =>
                                    print(error.toString()));
                          }),
                    ],
                  ),
                ),
              ),
            );
          }
        },
        separatorBuilder: (context, index) {
          return Divider();
        },
      ),
    );
  }

  String generateRandomString() {
    var r = Random.secure();
    const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    return List.generate(10, (index) => _chars[r.nextInt(_chars.length)])
        .join();
  }

  sendToFirebase(int sum) {
    int i;
    String orderID = generateRandomString();
    String today = DateFormat('ddMMyyyy').format(DateTime.now());

    DatabaseReference reference =
        FirebaseDatabase.instance.reference().child("Orders");

    FirebaseFirestore db = FirebaseFirestore.instance;

    reference
        .child(today)
        .child(orderID)
        .set({
          "orderID": orderID,
          "orderStatus": "Active",
          "deliveryStatus": "Pending",
          "uid": FirebaseAuth.instance.currentUser!.uid.toString(),
          "uidNumber":
              FirebaseAuth.instance.currentUser!.phoneNumber.toString(),
        })
        .whenComplete(() => {
              for (i = 1; i <= cartList.length; i++)
                {
                  reference
                      .child(today)
                      .child(orderID)
                      .child(i.toString())
                      .set({
                        "itemName": cartList[i - 1].itemName,
                        "itemCount": cartList[i - 1].itemCount,
                        "itemPrice": cartList[i - 1].itemPrice,
                        "totalPrice": cartList[i - 1].totalPrice
                      })
                      .whenComplete(
                          () => print(i.toString() + " : 1 : " + "Complete"))
                      .onError((error, stackTrace) =>
                          print(i.toString() + " : 1 : " + error.toString()))
                },
              if (i > cartList.length)
                {
                  db
                      .collection("Orders")
                      .doc(orderID)
                      .set({
                        "orderID": orderID,
                        "uid":
                            FirebaseAuth.instance.currentUser!.uid.toString(),
                        "uidNumber": FirebaseAuth
                            .instance.currentUser!.phoneNumber
                            .toString(),
                        "timeStamp": Timestamp.now(),
                        "dateStamp": today,
                        "orderStatus": "Active",
                        "deliveryStatus": "Pending",
                        "orderPrice": sum.toString(),
                        "numberOfItems": cartList.length.toString()
                      }, SetOptions(merge: true))
                      .whenComplete(() => {
                            showToast(
                              'Order Placed Successfully',
                              context: context,
                              animation: StyledToastAnimation.fadeScale,
                              reverseAnimation: StyledToastAnimation.fade,
                              position: StyledToastPosition.bottom,
                              animDuration: Duration(seconds: 1),
                              duration: Duration(seconds: 3),
                              curve: Curves.elasticOut,
                              reverseCurve: Curves.linear,
                            )
                          })
                      .onError((error, stackTrace) =>
                          print("1 : " + error.toString()))
                }
            })
        .onError((error, stackTrace) => print("2 : " + error.toString()));
  }
}
