import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lifemotivation/settings.dart';
import 'package:provider/provider.dart';
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
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';

import 'ad_state.dart';

const int maxFailedLoadAttempts = 3;

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
  String? wikiProffession = '';
  String wikiImageUrl = '';
  String wikiExtract = '';
  ScreenshotController screenshotController = ScreenshotController();

  //interstitial ad
  InterstitialAd? interstitialAd;
  int _numInterstitialLoadAttempts = 0;

  @override
  void initState() {
    super.initState();
    getQuote();
    _createInterstitialAd();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'iosadid',
      request: AdRequest(),
      adLoadCallback:
          InterstitialAdLoadCallback(onAdLoaded: (InterstitialAd ad) {
        print('$ad loaded');
        interstitialAd = ad;
        _numInterstitialLoadAttempts = 0;
        interstitialAd!.setImmersiveMode(true);
      }, onAdFailedToLoad: (LoadAdError error) {
        print('InterstitialAd failed to load: $error.');
        _numInterstitialLoadAttempts += 1;
        //interstitialAd = null;
        if (_numInterstitialLoadAttempts <= maxFailedLoadAttempts) {
          _createInterstitialAd();
        }
      }),
    );
  }

  void _showInterstitialAd() {
    if (interstitialAd == null) {
      print('Warning: attempt to show interstitial before loaded.');
      return;
    }
    interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        interstitialAd = null;
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createInterstitialAd();
      },
    );
    interstitialAd!.show();
    interstitialAd = null;
  }

  @override
  void dispose() {
    super.dispose();
    interstitialAd?.dispose();
  }

  dynamic getQuote() async {
    try {
      var response = await Dio().get('https://api.quotable.io/random');

      var quoteResponse = jsonDecode('$response');

      var pResponse = await getPhoto(quoteResponse['tags'][0]);
      var photoResponse = jsonDecode('$pResponse');
      //get a random photo since pexel returns 15 results by default
      var random = new Random().nextInt(29);
      setState(() {
        quote = quoteResponse['content'];
        author = quoteResponse['author'];
        photoUrl = photoResponse['photos'][random]['src']['original'];
        print(quoteResponse);
      });
      getPageTitle();
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
        'per_page': 30,
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
        enableDrag: true,
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
                leading: Icon(Icons.save),
                title: "Save to Gallery".text.make(),
                onTap: saveScreenshot,
              )
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
    if (interstitialAd != null) {
      _showInterstitialAd();
    } else {
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
        final image = File('${directory.path}/screenshot.jpg');
        setState(() {
          imagePath = image.path;
        });
        await image.writeAsBytes(_screenshot!);

        await Share.shareFiles([image.path]);
      }
      _createInterstitialAd();
    }
  }

  void setWallPaper() async {
    if (interstitialAd != null) {
      _showInterstitialAd();
    } else {
      getScreenshot();
      final directory = await getApplicationDocumentsDirectory();
      final image = File('${directory.path}/screenshot.jpg');
      setState(() {
        imagePath = image.path;
      });

      await image.writeAsBytes(_screenshot!);

      // int location = WallpaperManager
      //     .HOME_SCREEN; // or location = WallpaperManager.LOCK_SCREEN;
      // await WallpaperManager.setWallpaperFromFile(imagePath, location);
      int location = WallpaperManager.HOME_SCREEN; //can be Home/Lock Screen
      bool result =
          await WallpaperManager.setWallpaperFromFile(imagePath, location);
      if (result == true) {
        VxToast.show(context, msg: "Wallpaper set");
      } else {
        VxToast.show(context, msg: "An error occured try again");
      }
      _createInterstitialAd();
    }
  }

  void saveScreenshot() async {
    if (interstitialAd != null) {
      _showInterstitialAd();
    } else {
      if (await Permission.storage.request().isGranted) {
        await ImageGallerySaver.saveImage(_screenshot!,
            quality: 60,
            name: "screenshot" +
                DateTime.now().millisecondsSinceEpoch.toString());
        VxToast.show(context, msg: "Saved to gallery");
      }
      _createInterstitialAd();
    }
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
              Text(author)
                  .text
                  .warmGray50
                  .xl3
                  .italic
                  .makeCentered()
                  .onTap(() => showWikipediaInfo(author))
            ]).p16().centered(),
          ],
        ),
      ),
    );
  }

  Future<dynamic> showWikipediaInfo(String author) {
    return showMaterialModalBottomSheet(
        expand: false,
        context: context,
        shape: Vx.rounded,
        enableDrag: true,
        isDismissible: true,
        builder: (context) => VStack([
              SizedBox().h4(context),
              SingleChildScrollView(
                child: VStack([
                  VxAnimatedBox()
                      .alignTopCenter
                      .width(double.infinity)
                      .height(320)
                      .bgImage(DecorationImage(
                          image: CachedNetworkImageProvider(
                              'https://commons.wikimedia.org/wiki/Special:FilePath/' +
                                  wikiImageUrl),
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter))
                      .make(),

                  author.text.xl2.make().p(8),

                  wikiProffession!.text.xl.warmGray400.make().p(8),
                  //Article text first 3 sentences
                  wikiExtract.richText.xl.make().p(8),
                  SizedBox().h4(context),
                ]),
              ).h64(context),
            ]));
  }

  dynamic getPageTitle() async {
    String searchUrl =
        'https://en.wikipedia.org/w/api.php?action=opensearch&format=json&search=';
    String contentUrl =
        'https://en.wikipedia.org/w/api.php?action=query&prop=revisions&rvprop=content&rvslots=*&format=json&titles=';
    String extractUrl =
        'https://en.wikipedia.org/w/api.php?action=query&prop=extracts&exsentences=4&explaintext=1&formatversion=2&format=json&titles=';
    String imagesUrl =
        'https://en.wikipedia.org/w/api.php?action=parse&format=json&prop=images&pageid=';
    var dio = Dio();
    try {
      var response = await dio.get(searchUrl + author);
      //apparently wikipedia doesn't need json decode

      var title = response.data[1][0];
      print(title);

      var contentResponse = await dio.get(contentUrl + title);
      //check for redirections
      //check if contentResponse['query']['pages']['*pageid']['revisions'][0]['slots']['main']['*'] has
      //#Redirect if so "#Redirect [[Gautama Buddha]]..." get the string in [[]]
      //regex to check if we have #redirect (?<=\#).+?(?=\b) or (\#Redirect)
      //regex to get string in [[]] = (?<=\[\[).+?(?=\])
      //set that string as the new title and fetch contentResponse again
      var dcontentResponse = jsonDecode(contentResponse.toString());
      var pageId = jsonDecode(contentResponse.toString())['query']['pages']
          .keys
          .toList()[0];
      var content = dcontentResponse['query']['pages'][pageId]['revisions'][0]
              ['slots']['main']['*']
          .toString();
      var regex = RegExp("(\#Redirect)", multiLine: true, caseSensitive: false);
      if (regex.hasMatch(content)) {
        //print(content);
        var exp = RegExp(r"(?<=\[\[).+?(?=\]\])", multiLine: true);
        final matches = exp.firstMatch(content);
        print(matches?.group(0));
        title = matches?.group(0);
        contentResponse = await dio.get(contentUrl + title);
        pageId = jsonDecode(contentResponse.toString())['query']['pages']
            .keys
            .toList()[0];
        dcontentResponse = jsonDecode(contentResponse.toString());
      }
      //var parsedResponse = await dio.get(parsingUrl + pageId);
      // print(pageId);

      // content = dcontentResponse['query']['pages'][pageId]['revisions'][0]
      //         ['slots']['main']['*']
      //     .toString();

      //get image url
      var imagesResponse = await dio.get(imagesUrl + pageId);
      var images = jsonDecode(imagesResponse.toString())['parse']['images'];
      var index = 0;
      setState(() {
        wikiImageUrl = images[index];
      });
      while (!wikiImageUrl.endsWith(".jpg") && index < images.toList().length) {
        if (wikiImageUrl.endsWith(".JPG") || wikiImageUrl.endsWith(".png")) {
          break;
        }
        setState(() {
          wikiImageUrl = images[index++];
        });
      }

      //get sentences from wiki

      var extractResponse = await dio.get(extractUrl + title);
      var extract = jsonDecode(extractResponse.toString())['query']['pages'][0]
          ['extract'];
      setState(() {
        wikiExtract = extract;
      });
      //get proffession
      var profRegex = RegExp(
          r"(?<=\{\{short description\||is an |is a |was an |was a ).+?(?=\.|\,|\||\}\})",
          multiLine: true);
      var wikiProf = profRegex.firstMatch(extract);

      setState(() {
        wikiProffession = wikiProf?.group(0);
      });
      return response;
    } catch (e) {
      print("Wikipedia exception:");
      setState(() {
        String? wikiProffession = 'Unknown';
        String wikiImageUrl = '';
      });
      print(e);
    }
  }
}
