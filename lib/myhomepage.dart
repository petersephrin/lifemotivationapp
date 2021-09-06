import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import "package:velocity_x/velocity_x.dart";
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String quote = '';
  String author = '';
  String photoUrl = '';
  late Uint8List? _screenshot;
  String imagePath = '';
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    getQuote();
  }

  dynamic getQuote() async {
    try {
      var response = await Dio().get('https://api.quotable.io/random');

      var quoteResponse = jsonDecode('$response');
      var pResponse = await getPhoto(quoteResponse['tags'][0]);
      var photoResponse = jsonDecode('$pResponse');
      //get a random photo since pexel returns 15 results by default
      var random = new Random().nextInt(14);
      setState(() {
        quote = quoteResponse['content'];
        author = quoteResponse['author'];
        photoUrl = photoResponse['photos'][random]['src']['original'];
        print(quoteResponse);
      });
    } catch (e) {
      print(e);
    }
  }

  dynamic getPhoto(String tag) async {
    var dio = Dio();
    dio.options.headers["authorization"] =
        '563492ad6f91700001000001a73582a7af364dac9bc47c61f93322c7';
    try {
      var response =
          await dio.get('https://api.pexels.com/v1/search', queryParameters: {
        'query': tag,
      });
      return response;
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> showModal() {
    getScreenshot();
    return showMaterialModalBottomSheet(
        expand: false,
        context: context,
        isDismissible: true,
        builder: (context) => VStack([
              ListTile(
                leading: Icon(Icons.share),
                title: "Share".text.make(),
                onTap: shareScreenshot,
              ),
              ListTile(
                leading: Icon(Icons.wallpaper),
                title: "Set as wallpaper".text.make(),
                onTap: setWallPaper,
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: "Settings".text.make(),
              ),
            ]));
  }

  void getScreenshot() async {
    await screenshotController.capture().then((Uint8List? image) {
      //Capture Done
      setState(() {
        _screenshot = image;
      });
    }).catchError((onError) {
      print(onError);
    });
  }

  void shareScreenshot() async {
    //getScreenshot();
    if (await Permission.storage.request().isGranted) {
      // Either the permission was already granted before or the user just granted it.

      /*final result = await ImageGallerySaver.saveImage(_screenshot!,
          quality: 60,
          name:
              "screenshot" + DateTime.now().millisecondsSinceEpoch.toString());
      // print(Map.from(result)['filePath']);
      // Share.shareFiles([result['filePath']], text: quote);*/
      VxToast.show(context, msg: "Sharing");

      //from youtube tutorial
      final directory = await getApplicationDocumentsDirectory();
      final image = File('${directory.path}/screenshot' +
          DateTime.now().millisecondsSinceEpoch.toString() +
          '.jpg');
      setState(() {
        imagePath = image.path;
      });
      await image.writeAsBytes(_screenshot!);
      await Share.shareFiles([image.path]);
    }
  }

  void setWallPaper() async {
    if (imagePath == '') {
      final directory = await getApplicationDocumentsDirectory();
      final image = File('${directory.path}/screenshot' +
          DateTime.now().millisecondsSinceEpoch.toString() +
          '.jpg');
      setState(() {
        imagePath = image.path;
      });
    }
    // int location = WallpaperManager
    //     .HOME_SCREEN; // or location = WallpaperManager.LOCK_SCREEN;
    // await WallpaperManager.setWallpaperFromFile(imagePath, location);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Screenshot(
        controller: screenshotController,
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: photoUrl,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                      colorFilter:
                          ColorFilter.mode(Colors.black54, BlendMode.darken)),
                ),
              ),
              placeholder: (context, url) => Container(
                color: Colors.black,
              ),
              errorWidget: (context, url, error) => Container(
                  color: Colors.black,
                  child: Text("An error occured").text.makeCentered()),
            ).onTap(() => showModal()),
            VStack([
              Text('"' + quote + '"')
                  .text
                  .warmGray50
                  .light
                  .minFontSize(30)
                  .center
                  .makeCentered(),
              Text(author).text.warmGray50.xl3.italic.makeCentered()
            ]).p16().centered(),
          ],
        ),
      ),
    );
  }
}
