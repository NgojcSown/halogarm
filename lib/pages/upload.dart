import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:halogram/models/user.dart';
import 'package:image/image.dart' as Im;
import 'package:halogram/pages/home.dart';
import 'package:halogram/widgets/progress.dart';
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;
  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> with AutomaticKeepAliveClientMixin{
  TextEditingController locationController =TextEditingController();
  TextEditingController captionController =TextEditingController();
  bool isUploading = false;
  File file;
  String postId = Uuid().v4();
  handleTakePhoto() async{
    Navigator.pop(context);
    File file =await ImagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      this.file =file;
    });
  }
  handleGallaryPhoto() async{
    Navigator.pop(context);
    File file =await ImagePicker.pickImage(source: ImageSource.gallery,);
    setState(() {
      this.file =file;
    });
  }
  selectImage(parentContext)
  {
    return showDialog(
      context: parentContext,
      builder: (context){
        return SimpleDialog(
          title: Text('Tạo bài viết'),
          children: <Widget>[
            SimpleDialogOption(
              child: Text(
                'Chụp một bức ảnh'
              ),
              onPressed: handleTakePhoto,
            ),
            SimpleDialogOption(
              child: Text(
                  'Lấy ảnh từ thư viện'
              ),
              onPressed: handleGallaryPhoto,
            ),
            SimpleDialogOption(
              child: Text(
                  'Hủy bỏ'
              ),
              onPressed: (){
                Navigator.pop(context);
              },
            ),
          ],
        );
      }
    );
  }
  Scaffold buildSplashScreen() {
    return Scaffold(
        body: Container(
      child: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset('assets/images/upload.svg'),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              onPressed: ()=>selectImage(context),
              child: Text(
                'Tạo bài viết',
                style: TextStyle(
                  fontSize: 22.0,
                ),
              ),
            ),
          )
        ],
      ),
              ),
        ),
    );
  }
  clearImage(){
    setState(() {
      file=null;
    });
  }
  compressImage() async{
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')..writeAsBytesSync(Im.encodeJpg(imageFile,quality: 85));
    setState(() {
      file=compressedImageFile;
    });
  }
  Future<String>uploadImage(imageFile)async
  {
    StorageUploadTask uploadTask=storageRef.child('post_$postId.jpg').putFile(imageFile);
    StorageTaskSnapshot storageSnap =await uploadTask.onComplete;
    return await storageSnap.ref.getDownloadURL();
  }
  createPostInFireStore({String mediaUrl,String location,String caption})
  {
   postsRef.document((widget.currentUser.id)).collection('usersPosts').document(postId)
   .setData({
     'postId':postId,
     'ownerId':widget.currentUser.id,
     'username':widget.currentUser.username,
     'mediaUrl':mediaUrl,
     'caption':caption,
     "location":location,
     'timeStamp':timeStamp,
     'likes':{}

   });
  }
  handleSubmit() async
  {
    setState(() {
      isUploading =true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    await createPostInFireStore(mediaUrl: mediaUrl,location: locationController.text,caption: captionController.text);
    locationController.clear();
    captionController.clear();
    setState(() {
      isUploading =false;
      file=null;
    });
    SnackBar snackBar =SnackBar(content: Text('Tải lên thành công!'),);
    Scaffold.of(context).showSnackBar(snackBar);
  }
  Scaffold buildUploadForm(){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: clearImage,
        ),
        title: Center(child: Text('Nội dung')),
        actions: <Widget>[
          FlatButton(
            child:Icon(Icons.file_upload),
            onPressed: isUploading?null:()=>handleSubmit(),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading?linearProgress():Text(""),
          Container(
            height: 220,
            width: MediaQuery.of(context).size.width*.8,
            child: Center(
              child: AspectRatio(aspectRatio: 9/16,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: FileImage(file),
                    )
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 30,
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Nhập nội dung....',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.pin_drop,size: 35.0,),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: 'Nơi chụp.....',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              label: Text('Vị trí hiện tại'),
              icon: Icon(Icons.my_location,),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
              color: Theme.of(context).accentColor,
              onPressed: getUserLocation,
            ),
          )
        ],
      ),
    );
  }
  getUserLocation() async{
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy : LocationAccuracy.medium);
    List<Placemark> placeMarks = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);

    Placemark placeMark = placeMarks[0];
    String adress= '${placeMark.locality}, ${placeMark.country}';
    locationController.text =adress;
  }
  bool get wantKeepAlive=>true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file ==null ?buildSplashScreen():buildUploadForm();
  }
}
