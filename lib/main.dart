import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internet_speed_test/callbacks_enum.dart';
import 'package:internet_speed_test/internet_speed_test.dart';
import 'package:mime/mime.dart';
import 'package:sweetalert/sweetalert.dart';
import 'package:toast/toast.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Demo Upload Gambar',
        theme: ThemeData(primarySwatch: Colors.pink),
        home: ImageInput());
  }
}

class ImageInput extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ImageInput();
  }
}

class _ImageInput extends State<ImageInput> {
  final internetSpeedTest = InternetSpeedTest();
  double downloadRate = 0;
  double uploadRate = 0;
  String downloadProgress = '0';
  String uploadProgress = '0';

  String unitText = 'Mb/s';

  // To store the file provided by the image_picker
  File _imageFile;

  // To track the file uploading state
  bool _isUploading = false;

  String baseUrl = 'https://buat-testing-ajah.000webhostapp.com/DemoflutterAPI/api.php';

  void _getImage(BuildContext context, ImageSource source) async {
    File image = await ImagePicker.pickImage(source: source);

    setState(() {
      _imageFile = image;
    });

    // Closes the bottom sheet
    Navigator.pop(context);
  }

  Future<Map<String, dynamic>> _uploadImage(File image) async {
    setState(() {
      _isUploading = true;
    });

    // Find the mime type of the selected file by looking at the header bytes of the file
    final mimeTypeData =
    lookupMimeType(image.path, headerBytes: [0xFF, 0xD8]).split('/');

    // Intilize the multipart request
    final imageUploadRequest =
    http.MultipartRequest(
        'POST',
        Uri.parse(baseUrl)
    );


    // Attach the file in the request
    final file = await http.MultipartFile.fromPath(
      'image',
      image.path,
      contentType: MediaType(mimeTypeData[0],
          mimeTypeData[1]),
//        encoding: Encoding.getByName("utf-8")
    );

    // Explicitly pass the extension of the image with request body
    // Since image_picker has some bugs due which it mixes up
    // image extension with file name like this filenamejpge
    // Which creates some problem at the server side to manage
    // or verify the file extension
    imageUploadRequest.fields['ext'] = mimeTypeData[1];
//    imageUploadRequest.fields['name_en'] = 'fd';
//    imageUploadRequest.fields['name_ar'] = 'fd';
//    imageUploadRequest.fields['currency_code'] = 'dfv';
//    imageUploadRequest.fields['mobile_digit_count'] = '4';
//    imageUploadRequest.fields['mobile_code'] = 'sdf';
    imageUploadRequest.files.add(file);

    try {
      final streamedResponse = await imageUploadRequest.send();

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
         print('Gagal');
         return null;
      }

      final Map<String, dynamic> responseData = json.decode(response.body);

      _resetState();

      return responseData;
    } catch (e) {
      print(e);
      return null;
    }
  }

  void _startUploading() async {
    final Map<String, dynamic> response = await _uploadImage(_imageFile);
    print(response);
    if ( response != null && internetSpeedTest.uploadRate < 0.01) {
      Toast.show("Image Upload Failed!!!", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    } else {
      Toast.show("Image Uploaded Successfully!!!", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    }
  }

  void _resetState() {
    setState(() {
      _isUploading = false;
      _imageFile = null;
    });
  }

  void _openImagePickerModal(BuildContext context) {
    final flatButtonColor = Theme.of(context).primaryColor;
    print('Panggil Modal Picker Image');
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 150.0,
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: <Widget>[
                Text(
                  'Ambil Gambar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 10.0,
                ),
                FlatButton(
                  textColor: flatButtonColor,
                  child: Text('Kamera'),
                  onPressed: () {
                    _getImage(context, ImageSource.camera);
                  },
                ),
                FlatButton(
                  textColor: flatButtonColor,
                  child: Text('Gallery'),
                  onPressed: () {
                    _getImage(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          );
        });
  }

  Widget _buildUploadBtn() {
    Widget btnWidget = Container();

    if (_isUploading) {
      // File is being uploaded then show a progress indicator
      btnWidget = Container(
        margin: EdgeInsets.only(top: 10.0),
        child: CircularProgressIndicator(),
      );
    } else if (!_isUploading && _imageFile != null) {
      // If image is picked by the user then show a upload btn

      btnWidget = Container(
        margin: EdgeInsets.only(top: 10.0),
        child: RaisedButton(
          child: Text('Upload'),
          onPressed: () {
            _startUploading();
            internetSpeedTest.startUploadTesting(
                onDone: (double transferRate, SpeedUnit unit) {
                  print('the transfer rate $transferRate');
                  setState(() {
                    uploadRate = transferRate;
                    unitText = unit == SpeedUnit.Kbps ? 'Kb/s' : 'Mb/s';
                    uploadProgress = '100';
                    if (uploadProgress == '100'){
                      SweetAlert.show(context,
                          title: "Berhasil !",
                          subtitle: "Gambar selesai di upload ke server",
                          style: SweetAlertStyle.success);
                    }
                  });
                },
                onProgress:
                    (double percent, double transferRate, SpeedUnit unit) {
                  print('the transfer rate $transferRate, the percent $percent');
                  setState(() {
                    uploadRate = transferRate;
                    unitText = unit == SpeedUnit.Kbps ? 'Kb/s' : 'Mb/s';
                    uploadProgress = percent.toStringAsFixed(2);
                    print(transferRate*1000);
                    if (transferRate*1000 < 5 ){
                      SweetAlert.show(context,
                          title: "Peringatan !",
                          subtitle: "Pastikan koneksi internet anda stabil ",
                          style: SweetAlertStyle.confirm,
                          // ignore: missing_return
                          showCancelButton: true, onPress: (bool isConfirm) {
                            if (isConfirm) {
                              SweetAlert.show(context,style: SweetAlertStyle.success,title: "Success");
                              // return false to keep dialog
                            return false;
                            }
                          });
                    }
                  });
                },
                onError: (String errorMessage, String speedTestError) {
                  print('the errorMessage $errorMessage, the speedTestError $speedTestError');
                  SweetAlert.show(context,
                      title: "Oops !",
                      subtitle: "Sepertinya terjadi kesalahan",
                      style: SweetAlertStyle.error);
                }
                );
          },
          color: Colors.pinkAccent,
          textColor: Colors.white,
        ),
      );
    }

    return btnWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demo Upload Gambar'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 40.0, left: 10.0, right: 10.0),
            child: OutlineButton(
              onPressed: () => _openImagePickerModal(context),
              borderSide:
              BorderSide(color: Theme.of(context).accentColor, width: 1.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.camera_alt),
                  SizedBox(
                    width: 5.0,
                  ),
                  Text('Tambah Gambar'),
                ],
              ),
            ),
          ),
          _imageFile == null
              ? Text('Silakan Pilih Gambar')
              : Image.file(
            _imageFile,
            fit: BoxFit.cover,
            height: 300.0,
            alignment: Alignment.topCenter,
            width: MediaQuery.of(context).size.width,
          ),
          Text('Progress Upload $uploadProgress%'),
          Text('Upload rate  $uploadRate Kb/s'),
          _buildUploadBtn(),
        ],
      ),
    );
  }
}