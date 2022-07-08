import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nekoton_flutter_example/data/nekoton_repository.dart';
import 'package:nekoton_flutter_example/presentation/accounts/accounts_screen.dart';
import 'package:nekoton_flutter_example/presentation/keys/keys_screen.dart';
import 'package:nekoton_flutter_example/presentation/subscriptions/subscriptions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Center(
          child: FutureBuilder(
            future: context.read<NekotonRepository>().intialize(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    button(
                      text: 'Keys',
                      screen: const KeysScreen(),
                    ),
                    button(
                      text: 'Accounts',
                      screen: const AccountsScreen(),
                    ),
                    button(
                      text: 'Subscriptions',
                      screen: const SubscriptionsScreen(),
                    ),
                  ]
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: e,
                        ),
                      )
                      .toList(),
                );
              }
              if (snapshot.hasError) return const Icon(Icons.error);
              return const CircularProgressIndicator();
            },
          ),
        ),
      );

  Widget button({
    required String text,
    required Widget screen,
  }) =>
      ElevatedButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => screen,
          ),
        ),
        child: Text(text),
      );
}
