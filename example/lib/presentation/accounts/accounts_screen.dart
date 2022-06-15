import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';

import '../../data/nekoton_repository.dart';
import 'accounts_cubit.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({Key? key}) : super(key: key);

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Accounts'),
        ),
        body: BlocProvider(
          create: (context) => AccountsCubit(context.read<NekotonRepository>()),
          child: Builder(
            builder: (context) => BlocBuilder<AccountsCubit, List<AssetsList>>(
              bloc: context.watch<AccountsCubit>(),
              builder: (context, state) => ListView(
                shrinkWrap: true,
                children: state
                    .map(
                      (element) => ListTile(
                        title: Text(element.name),
                        subtitle: Text(element.address),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      );
}
