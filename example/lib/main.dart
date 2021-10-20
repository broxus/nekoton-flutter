import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String connectionData = 'ConnectionData will be here';
  String transactionId = 'TransactionId will be here';
  String error = 'If an error occur there will be text';

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      connectionData,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      transactionId,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      child: const Text('PRESS ME'),
                      onPressed: () async {
                        try {
                          try {
                            final instance = await Nekoton.getInstance();

                            setState(() {
                              connectionData = instance.connectionController.transport.connectionData.toString();
                            });

                            final wallet = await instance.subscriptionsController.subscribeToGenericContract(
                              origin: "origin",
                              address: "0:f35f602c47bf42c3e292262023aa7e71a53e604fdf6bf42be4bf6dd9ab8e04c3",
                            );

                            wallet.onTransactionsFoundStream.listen((event) {
                              try {
                                setState(() {
                                  transactionId = event.last.id.toString();
                                });

                                if (event.lastOrNull?.prevTransactionId != null) {
                                  wallet.preloadTransactions(event.lastOrNull!.prevTransactionId!);
                                }
                              } catch (err) {
                                setState(() {
                                  error = err.toString();
                                });
                              }
                            });
                          } catch (err) {
                            setState(() {
                              error = err.toString();
                            });
                          }
                        } catch (err) {
                          setState(() {
                            error = err.toString();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
