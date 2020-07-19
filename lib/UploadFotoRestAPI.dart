import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sweetalert/sweetalert.dart';
import 'dart:io';
import 'Utility.dart';
import 'DBHelper.dart';
import 'Photo.dart';
import 'dart:async';
import 'cekKoneksi.dart';
import 'koneksi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  cekKoneksi statusKoneksi = cekKoneksi.getInstance();
  statusKoneksi.initialize();
  runApp(App());
}
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
//      title: 'Title',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SaveImageDemoSQLite(),
    );
  }
}

class SaveImageDemoSQLite extends StatefulWidget {
  //
  SaveImageDemoSQLite() : super();

  final String title = "Flutter Save Image";

  @override
  _SaveImageDemoSQLiteState createState() => _SaveImageDemoSQLiteState();
}

class _SaveImageDemoSQLiteState extends State<SaveImageDemoSQLite> {
  //
  Future<File> imageFile;
  Image image;
  DBHelper dbHelper;
  List<Photo> images;

  @override
  void initState() {
    super.initState();
    images = [];
    dbHelper = DBHelper();
    refreshImages();
  }

  refreshImages() {
    dbHelper.getPhotos().then((imgs) {
      setState(() {
        images.clear();
        images.addAll(imgs);
      });
    });
  }

  pickImageFromGallery() {
    ImagePicker.pickImage(source: ImageSource.gallery).then((imgFile) {
      String imgString = Utility.base64String(imgFile.readAsBytesSync());
      Photo photo = Photo(0, imgString);
      dbHelper.save(photo);
      refreshImages();
    });
  }

  gridView() {
    return Padding(
      padding: EdgeInsets.all(5.0),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
        children: images.map((photo) {
          return Utility.imageFromBase64String(photo.photoName);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              SweetAlert.show(context,
                  title: "Peringatan !",
                  subtitle: "Apakah yakin ingin mengupload gambar ?",
                  style: SweetAlertStyle.confirm,
                  // ignore: missing_return
                  showCancelButton: true, onPress: (bool isConfirm) {
                    if (isConfirm) {
                      pickImageFromGallery();
                      SweetAlert.show(context,style: SweetAlertStyle.success,title: "Success");
                      // return false to keep dialog
                      return false;
                    }
                  });
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            koneksi(),
            Flexible(
              child: gridView(),
            )
          ],
        ),
      ),
    );
  }
}