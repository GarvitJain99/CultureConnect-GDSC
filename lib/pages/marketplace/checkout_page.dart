import 'package:cultureconnect/pages/marketplace/select_location.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Razorpay _razorpay = Razorpay();
  final TextEditingController _locationController = TextEditingController();
  double totalAmount = 0;
  List<Map<String, dynamic>> cartItems = [];

  final _formKey = GlobalKey<FormState>();
  String phone = '';
  String street = '';
  String city = '';
  String state = '';
  String pincode = '';
  String additionalNotes = '';

  bool _isFormValid() {
    return phone.isNotEmpty && street.isNotEmpty; // Modified this line
  }

  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchCartItems();
    _fetchUserAddress();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchCartItems() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final cartRef = userRef.collection('cart');
    final snapshot = await cartRef.get();

    double total = 0;
    List<Map<String, dynamic>> items = [];

    for (var doc in snapshot.docs) {
      var data = doc.data();
      data['id'] = doc.id;
      total += (data['price'] as num) * (data['quantity'] as int);
      items.add(data);
    }

    setState(() {
      totalAmount = total;
      cartItems = items;
    });
  }

  Future<void> _fetchUserAddress() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final snapshot = await userRef.get();

    if (snapshot.exists && snapshot.data()?['address'] != null) {
      var address = snapshot.data()!['address'];
      setState(() {
        phone = snapshot.data()?['phone'] ?? '';
        street = address['street'] ?? '';
        city = address['city'] ?? '';
        state = address['state'] ?? '';
        pincode = address['pincode'] ?? '';
        additionalNotes = address['additional notes'] ?? '';
      });
    }
  }

  Future<void> _saveUserAddress() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    await userRef.set({
      'phone': phone,
      'address': {
        'street': street,
        'city': city,
        'state': state,
        'pincode': pincode,
        'additional notes': additionalNotes,
      },
    }, SetOptions(merge: true));
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("Payment Success Callback triggered!"); 
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User is null in Payment Success Callback!"); 
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      await userRef.collection('ongoing_orders').add({
        'items': cartItems,
        'total_price': totalAmount,
        'payment_id': response.paymentId,
        'address': {
          'phone': phone,
          'street': street,
          'city': city,
          'state': state,
          'pincode': pincode,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Order added to ongoing_orders successfully!"); 
    } catch (e) {
      print("Error adding to ongoing_orders: $e"); 
    }

    try {
      await _clearCart(user.uid);
      print("Cart cleared successfully!"); 
    } catch (e) {
      print("Error clearing cart: $e"); 
    }

    setState(() {
      totalAmount = 0;
      cartItems.clear();
      print("UI updated - cart cleared and total reset."); 
    });

    _showSnackbar("Payment successful! ID: ${response.paymentId}");
    print("Snackbar shown."); 
  }

  Future<void> _clearCart(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final cartRef = userRef.collection('cart');
    final snapshot = await cartRef.get();

    for (var doc in snapshot.docs) {
      await cartRef.doc(doc.id).delete();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showSnackbar("Payment failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showSnackbar("Using external wallet: ${response.walletName}");
  }

  void _startPayment() {
    if (_formKey.currentState!.validate()) {
      if (totalAmount <= 0) {
        _showSnackbar("Total amount must be greater than 0");
        return;
      }

      _formKey.currentState!.save();
      _saveUserAddress();

      var options = {
        'key': 'rzp_test_sja0vT32ZZHP1F',
        'amount': (totalAmount * 100).toInt(),
        'name': 'CultureConnect',
        'description': 'Payment for items in the marketplace',
        'prefill': {
          'contact': phone,
          'email': FirebaseAuth.instance.currentUser?.email
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        _showSnackbar("Error: $e");
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                onSaved: (val) => phone = val!,
                onChanged: (value) => setState(() {}),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Selected Location',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.location_on),
                    onPressed: () async {
                      final selectedLocation = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectLocationPage(),
                        ),
                      );

                      if (selectedLocation != null && selectedLocation is Map) {
                        setState(() {
                          street = selectedLocation['address'] ?? '';
                          _locationController.text =
                              selectedLocation['address'] ?? '';
                        });
                      }
                    },
                  ),
                ),
                readOnly: true,
                onChanged: (value) => setState(() {}),
              ),
              SizedBox(height: 10),
              TextFormField(
                initialValue: street,
                decoration: InputDecoration(
                  labelText: 'Street',
                  border: OutlineInputBorder(),
                ),
                onSaved: (val) => street = val!,
                onChanged: (value) => setState(() {}),
              ),
              SizedBox(height: 10),
              TextFormField(
                initialValue: city,
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                onSaved: (val) => city = val!,
                onChanged: (value) => setState(() {}),
              ),
              SizedBox(height: 10),
              TextFormField(
                initialValue: state,
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
                onSaved: (val) => state = val!,
                onChanged: (value) => setState(() {}),
              ),
              SizedBox(height: 10),
              TextFormField(
                initialValue: pincode,
                decoration: InputDecoration(
                  labelText: 'Pincode',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSaved: (val) => pincode = val!,
                onChanged: (value) => setState(() {}),
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  hintText: 'Any special delivery instructions...',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                minLines: 3,
                onSaved: (val) => additionalNotes = val ?? '',
              ),
              SizedBox(height: 20),
              StatefulBuilder(
                builder: (context, setState) {
                  return ElevatedButton(
                    onPressed: _isFormValid() ? _startPayment : null,
                    child: Text('Proceed to Pay'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
