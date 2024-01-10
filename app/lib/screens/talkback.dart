import 'package:flutter/material.dart';

abstract class TalkbackScreen extends StatefulWidget {
  const TalkbackScreen({super.key});

  String getTalkback(BuildContext context);
}
