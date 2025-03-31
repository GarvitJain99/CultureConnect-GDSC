import 'package:cultureconnect/pages/marketplace/order_confirmation.dart';
import 'package:cultureconnect/pages/marketplace/dropoff_location.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutPage extends StatefulWidget {
  final String? buyNowItemId;
  final String? buyNowItemName;
  final String? buyNowItemImageUrl;
  final double? buyNowItemPrice;
  final int? buyNowItemQuantity;

  const CheckoutPage({
    super.key,
    this.buyNowItemId,
    this.buyNowItemName,
    this.buyNowItemImageUrl,
    this.buyNowItemPrice,
    this.buyNowItemQuantity,
  });

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Razorpay _razorpay = Razorpay();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();
  double totalAmount = 0;
  List<Map<String, dynamic>> cartItems = [];

  final _formKey = GlobalKey<FormState>();
  String phone = '';
  String street = '';
  String? selectedCity;
  String? selectedState;
  String pincode = '';
  double? _latitude;
  double? _longitude;

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
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _additionalNotesController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchCartItems() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    double total = 0;
    List<Map<String, dynamic>> items = [];

    if (widget.buyNowItemId != null &&
        widget.buyNowItemName != null &&
        widget.buyNowItemImageUrl != null &&
        widget.buyNowItemPrice != null &&
        widget.buyNowItemQuantity != null) {
      total = widget.buyNowItemPrice! * widget.buyNowItemQuantity!;
      items.add({
        'id': widget.buyNowItemId,
        'name': widget.buyNowItemName,
        'imageUrl': widget.buyNowItemImageUrl,
        'price': widget.buyNowItemPrice,
        'quantity': widget.buyNowItemQuantity,
      });
    } else {
      // Regular cart checkout flow: fetch all items from the cart
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final cartRef = userRef.collection('cart');
      final snapshot = await cartRef.get();

      for (var doc in snapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id;
        total += (data['price'] as num) * (data['quantity'] as int);
        items.add(data);
      }
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
        selectedCity = address['city'];
        selectedState = address['state'];
        pincode = address['pincode'] ?? '';
        _latitude = address['latitude'];
        _longitude = address['longitude'];
        _locationController.text = address['full_address'] ?? '';

        _phoneController.text = phone;
        _streetController.text = street;
        _cityController.text = selectedCity ?? '';
        _stateController.text = selectedState ?? '';
        _pincodeController.text = pincode;
      });
    }
  }

  Future<void> _saveUserAddress() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      await userRef.set({
        'phone': _phoneController.text,
        'address': {
          'street': _streetController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'pincode': _pincodeController.text,
          'full_address': _locationController.text,
          'latitude': _latitude,
          'longitude': _longitude,
        },
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving address with location data: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
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
          'phone': _phoneController.text,
          'street': _streetController.text,
          'city': _cityController.text,
          'state': _cityController.text,
          'pincode': _pincodeController.text,
          'full_address': _locationController.text,
          'latitude': _latitude,
          'longitude': _longitude,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding to ongoing_orders: $e");
    }

    try {
      await _clearCart(user.uid); // Clear the cart after any purchase
    } catch (e) {
      print("Error clearing cart: $e");
    }

    setState(() {
      totalAmount = 0;
      cartItems.clear();
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              OrderConfirmationPage(paymentId: response.paymentId!)),
    );
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
          'contact': _phoneController.text,
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
      appBar: AppBar(
        title: Text('Checkout', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFFC7C79),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(  
  colors: [Color(0xFFFC7C79), Color(0xFFEDC0F9)],  
  begin: Alignment.topCenter,  
  end: Alignment.bottomCenter, 
),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 2),
              TextFormField(
                controller: _phoneController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38 ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                keyboardType: TextInputType.phone,
                onSaved: (val) => phone = val!,
                onChanged: (value) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length != 10) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _locationController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Selected Location',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.location_on, color: Colors.white70),
                    onPressed: () async {
                      final selectedLocation = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DropoffLocationPage(
                            initialLatitude: _latitude,
                            initialLongitude: _longitude,
                          ),
                        ),
                      );

                      if (selectedLocation != null &&
                          selectedLocation is Map) {
                        setState(() {
                          _locationController.text =
                              selectedLocation['address'] ?? '';
                          _latitude = selectedLocation['latitude'];
                          _longitude = selectedLocation['longitude'];
                          selectedState = selectedLocation['state'];
                          selectedCity = selectedLocation['city'];
                          street = selectedLocation['street'] ?? '';
                          pincode = selectedLocation['pincode'] ?? '';

                          _streetController.text = street;
                          _stateController.text = selectedState ?? '';
                          _cityController.text = selectedCity ?? '';
                          _pincodeController.text = pincode;
                        });
                      }
                    },
                  ),
                ),
                readOnly: true,
                onChanged: (value) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your location';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _streetController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Street',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                onSaved: (val) => street = val!,
                onChanged: (value) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your street address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _stateController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'State',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                onSaved: (val) => selectedState = val,
                onChanged: (value) => setState(() {
                  selectedState = value;
                }),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your state';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _cityController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'City',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                onSaved: (val) => selectedCity = val,
                onChanged: (value) => setState(() {
                  selectedCity = value;
                }),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _pincodeController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Pincode',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                keyboardType: TextInputType.number,
                onSaved: (val) => pincode = val!,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your pincode';
                  }
                  if (value.length != 6) {
                    return 'Please enter a valid 6-digit pincode';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _additionalNotesController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Any special delivery instructions...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                minLines: 3,
              ),
              SizedBox(height: 30),
              StatefulBuilder(
                builder: (context, setState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total: ₹${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      ElevatedButton(
                        onPressed: _startPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFFFC7C79),
                          padding: EdgeInsets.symmetric(
                              horizontal: 25, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        child: Text('Proceed to Pay',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ],
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