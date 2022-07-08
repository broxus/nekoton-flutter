import 'package:bloc/bloc.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';
import 'package:nekoton_flutter_example/data/nekoton_repository.dart';

class SubscriptionsCubit extends Cubit<List<TonWallet>> {
  final NekotonRepository _nekotonRepository;

  SubscriptionsCubit(this._nekotonRepository) : super([]) {
    subscribe();
  }

  @override
  Future<void> close() async {
    for (final element in state) {
      element.dispose();
    }
    super.close();
  }

  Future<void> subscribe() async {
    final list = [
      '0:d89ca0b16386272815c54728162784388f44213119616a5a85f431062c500c76',
      '0:c91ae4e7d395f41d156e520d0b86a449a2cd8a65f0391bfc84f347f55dcfc97b',
    ];

    final futures = [
      TonWallet.subscribeByAddress(
        transport: await _nekotonRepository.gqlTransport,
        address: list.first,
      ),
      TonWallet.subscribeByAddress(
        transport: await _nekotonRepository.jrpcTransport,
        address: list.last,
      )
    ];

    for (final e in futures) {
      e.then((v) {
        emit([...state, v]);
      });
    }
  }
}
