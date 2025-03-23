import 'package:cultureconnect/pages/marketplace/order_confirmation.dart';
import 'package:cultureconnect/pages/marketplace/dropoff_location.dart';
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

  bool _isFormValid() {
    return _formKey.currentState?.validate() ?? false;
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
          'state': _stateController.text,
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
      await _clearCart(user.uid);
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
      appBar: AppBar(title: Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                onSaved: (val) => phone = val!,
                onChanged: (value) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(r'^{10}$').hasMatch(value)) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
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
                          builder: (context) => DropoffLocationPage(
                            initialLatitude: _latitude,
                            initialLongitude: _longitude,
                          ),
                        ),
                      );

                      if (selectedLocation != null && selectedLocation is Map) {
                        setState(() {
                          _locationController.text =
                              selectedLocation['address'] ?? '';
                          _latitude = selectedLocation['latitude'];
                          _longitude = selectedLocation['longitude'];
                          selectedState = selectedLocation['state'];
                          selectedCity = selectedLocation['city'];
                          street =
                              selectedLocation['street'] ?? ''; // Get street
                          pincode =
                              selectedLocation['pincode'] ?? ''; // Get pincode

                          _streetController.text = street;
                          _stateController.text = selectedState ?? '';
                          _cityController.text = selectedCity ?? '';
                          _pincodeController.text =
                              pincode; // Update pincode controller
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
              SizedBox(height: 10),
              TextFormField(
                controller: _streetController,
                decoration: InputDecoration(
                  labelText: 'Street',
                  border: OutlineInputBorder(),
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
              SizedBox(height: 10),
              TextFormField(
                controller: _stateController,
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
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
              SizedBox(height: 10),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
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
              SizedBox(height: 10),
              TextFormField(
                controller: _pincodeController,
                decoration: InputDecoration(
                  labelText: 'Pincode',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSaved: (val) => pincode = val!,
                // No need for onChanged here as it's fetched
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your pincode';
                  }
                  if (!RegExp(r'^{6}$').hasMatch(value)) {
                    return 'Please enter a valid 6-digit pincode';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _additionalNotesController,
                decoration: InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  hintText: 'Any special delivery instructions...',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                minLines: 3,
                // No onSaved or onChanged as we are not saving this
              ),
              SizedBox(height: 20),
              StatefulBuilder(
                builder: (context, setState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total: ₹${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ElevatedButton(
                        onPressed: _isFormValid() ? _startPayment : null,
                        child: Text('Proceed to Pay'),
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