import 'package:ai_yu/data/state_models/aws_model.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import "package:flutter/material.dart";

class WalletModel extends ChangeNotifier {
  late final AWSModel? _aws;
  bool _disposed = false;

  // Measured in 100ths of a cent.
  late int _microcentBalance;

  int get microcentBalance => _microcentBalance;
  double get centBalance => _microcentBalance / 100.0;
  double get dollarBalance => _microcentBalance / 10000.0;

  String text = "";

  WalletModel(this._aws, WalletModel? previousWallet) {
    _microcentBalance = previousWallet?._microcentBalance ?? 0;
    if (_aws?.isSignedIn ?? false) _fetchWalletBalance();
  }

  // Since this model is a proxy provider, it will be recreated whenever the
  // AWSModel changes, so we need to protect against calling notifyListeners()
  // on a disposed object.
  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  Future<void> _fetchWalletBalance() async {
    if (_aws == null) return;
    await _aws?.initialization;

    final userIdentity = await _aws!.getUserIdentity();

    final restOperation = Amplify.API.get(
      '/wallet',
      apiName: 'restapi',
    );
    final response = await restOperation.response;
    safePrint('GET call succeeded');
    safePrint(response.decodeBody());
    text = "${response.decodeBody()} | $userIdentity";
    notifyListeners();

    /* final userIdentity = await _aws!.getUserIdentity();
    final awsWallet = (await Amplify.DataStore.query(
      Wallet.classType,
      where: Wallet.IDENTITY_ID.eq(userIdentity),
    ))
        .firstOrNull;
    if (awsWallet != null) {
      _microcentBalance = awsWallet.balance_microcents;
      notifyListeners();
    } */
  }

  Future<bool> add50Cent() async {
    final result = await _aws?.initializeTemporaryAccount() ?? false;
    if (result == true) {
      safePrint("Signed in as temporary account.");
    } else {
      safePrint("Failed to sign in as temporary account.");
    }
    return result;
    /* if (_aws == null) return;

    final userIdentity = await _aws!.getUserIdentity();

    final oldWallet = (await Amplify.DataStore.query(
          Wallet.classType,
          where: Wallet.IDENTITY_ID.eq(userIdentity),
        ))
            .firstOrNull ??
        Wallet(balance_microcents: 0, identity_id: userIdentity);

    final newWallet = oldWallet.copyWith(
        balance_microcents: oldWallet.balance_microcents + 5000);

    await Amplify.DataStore.save(newWallet);

    notifyListeners(); */
  }

  int _calculateQueryCost() {
    return 2;
  }

  double calculateQueryCostInCents() {
    return _calculateQueryCost() / 100.0;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
