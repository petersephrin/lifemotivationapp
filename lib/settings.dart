import 'package:flutter/material.dart';
import "package:velocity_x/velocity_x.dart";

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VxAppBar(
        title: 'Settings'.text.make(),
      ),
      body: "Settings".text.makeCentered(),
    );
  }
}
