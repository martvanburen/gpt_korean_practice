import 'package:ai_yu/data/state_models/aws_model.dart';
import 'package:ai_yu/data/state_models/wallet_model.dart';
import 'package:ai_yu/widgets/shared/authentication_dialog.dart';
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import 'package:ai_yu/data/state_models/deeplinks_model.dart';

class WalletInfoDialog extends StatelessWidget {
  const WalletInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeeplinksModel>(
      builder: (context, deeplinks, child) {
        return AlertDialog(
          title: const Text("Wallet Information"),
          content: const SingleChildScrollView(
            child: Text(
              """
TODO(Mart): Add wallet information here.
""",
            ),
          ),
          actions: <Widget>[
            Consumer2<AWSModel, WalletModel>(
              builder: (context, aws, wallet, child) {
                String text = "";
                AuthenticationMode? mode;
                Function action = () {};

                if (!aws.isSignedIn || aws.isTemporaryAccount) {
                  if (!aws.isSignedIn) {
                    text = "Restore Wallet";
                    mode = AuthenticationMode.restoreWallet;
                  } else {
                    text = "Backup Wallet";
                    mode = AuthenticationMode.backupWallet;
                  }
                  action = () {
                    Navigator.of(context).pop();
                    showDialog(
                        context: context,
                        // Since user needs to switch to email and back for
                        // their verification code, prevent accidental dismissal
                        // of dialog.
                        barrierDismissible: false,
                        builder: (context) =>
                            AuthenticationDialog(mode: mode!));
                  };
                } else {
                  text = "Sign Out";
                  action = () {
                    aws.signOut();
                  };
                }

                return TextButton(
                  onPressed: () => action(),
                  child: Text(text),
                );
              },
            ),
            FilledButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
