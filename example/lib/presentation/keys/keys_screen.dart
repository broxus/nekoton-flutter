import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';
import 'package:nekoton_flutter_example/data/nekoton_repository.dart';
import 'package:nekoton_flutter_example/presentation/keys/keys_cubit.dart';

class KeysScreen extends StatefulWidget {
  const KeysScreen({Key? key}) : super(key: key);

  @override
  State<KeysScreen> createState() => _KeysScreenState();
}

class _KeysScreenState extends State<KeysScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Keys'),
        ),
        body: BlocProvider(
          create: (context) => KeysCubit(context.read<NekotonRepository>()),
          child: Builder(
            builder: (context) => BlocBuilder<KeysCubit, List<KeyStoreEntry>>(
              bloc: context.watch<KeysCubit>(),
              builder: (context, state) => ListView(
                shrinkWrap: true,
                children: state
                    .map(
                      (element) => ListTile(
                        title: Text(element.name),
                        subtitle: Text(element.publicKey),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      );
}
