import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';
import 'package:nekoton_flutter_example/data/nekoton_repository.dart';
import 'package:nekoton_flutter_example/presentation/subscriptions/subscriptions_cubit.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionsScreen> createState() => SubscriptionsScreenState();
}

class SubscriptionsScreenState extends State<SubscriptionsScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Subscriptions'),
        ),
        body: BlocProvider(
          create: (context) => SubscriptionsCubit(context.read<NekotonRepository>()),
          child: Builder(
            builder: (context) => BlocBuilder<SubscriptionsCubit, List<TonWallet>>(
              bloc: context.watch<SubscriptionsCubit>(),
              builder: (context, state) => ListView(
                shrinkWrap: true,
                children: state
                    .map(
                      (element) => ListTile(
                        title: Text(
                          '${element.transport.type.toString()} ${element.address}',
                        ),
                        subtitle: asyncText(element.contractState.then((v) => v.balance)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      );

  Widget asyncText(Future<String> future) => FutureBuilder<String>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) return Text(snapshot.data!);
          if (snapshot.hasError) return const Icon(Icons.error);
          return const Center(child: CircularProgressIndicator());
        },
      );
}
