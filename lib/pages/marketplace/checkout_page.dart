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
  double totalAmount = 0;
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchCartItems();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchCartItems() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return;
    }

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

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    await userRef.collection('previous_orders').add({
      'items': cartItems,
      'total_price': totalAmount,
      'payment_id': response.paymentId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _clearCart(user.uid);

    setState(() {
      totalAmount = 0;
      cartItems.clear();
    });

    print("Payment Successful: ${response.paymentId}");
    _showSnackbar("Payment successful! ID: ${response.paymentId}");
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
    print("Payment failed: ${response.message}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment failed: ${response.message}"),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet Selected: ${response.walletName}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Using external wallet: ${response.walletName}")),
    );
  }

  void _startPayment() {
    var options = {
      'key': 'rzp_test_sja0vT32ZZHP1F',
      'amount': (totalAmount * 100).toInt(),
      'name': 'CultureConnect',
      'description': 'Payment for items in the marketplace',
      'prefill': {'contact': '9999999999', 'email': 'test@example.com'},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print("Error: $e");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Amount: $totalAmount'),
            ElevatedButton(
              onPressed: _startPayment,
              child: Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }
}