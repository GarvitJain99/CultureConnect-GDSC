import 'package:cultureconnect/pages/marketplace/home.dart';
import 'package:flutter/material.dart';

class OrderConfirmationPage extends StatelessWidget {
  final String paymentId;

  const OrderConfirmationPage({Key? key, required this.paymentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Confirmed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
              SizedBox(height: 20),
              Text(
                'Your order has been placed successfully!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text('Payment ID: $paymentId', style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MarketplaceHome())
                  );
                },
                child: Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}