import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/nekoton_repository.dart';
import 'home_screen.dart';

class Application extends StatefulWidget {
  const Application({Key? key}) : super(key: key);

  @override
  State<Application> createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> {
  final nekotonRepository = NekotonRepository();

  @override
  void dispose() {
    nekotonRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
        value: nekotonRepository,
        child: const MaterialApp(
          title: 'NekotonFlutter',
          home: HomeScreen(),
        ),
      );
}
