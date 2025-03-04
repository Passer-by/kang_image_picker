import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kang_image_picker/kang_image_picker.dart';
import 'package:video_player/video_player.dart';

class PickerScreen extends StatefulWidget {
  const PickerScreen({super.key});

  @override
  State<PickerScreen> createState() => _PickerScreenState();
}

class _PickerScreenState extends State<PickerScreen> {
  String? _version;

  final List<FileImage> _selectedImageList = [];
  final List<String> _selectedImagePathList = [];
  VideoPlayerController? _playerController;

  @override
  void initState() {
    super.initState();
    getPlatformVersion();
  }

  void getPlatformVersion() async {
    _version = await KangImagePicker.getPlatformVersion();
    if (_version != null) {
      setState(() {});
    }
  }

  Future<void> _callPicker() async {}

  void showMsg(String title, String? content) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      // false = user must tap button, true = tap outside dialog
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content ?? ''),
          actions: <Widget>[
            TextButton(
              child: const Text('好的'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss alert dialog
              },
            ),
          ],
        );
      },
    );
  }

  void selectOne() async {
    try {
      final path = await KangImagePicker.selectSinglePhoto();
      if (path == null) {
        print('结果为空');
        return;
      }
      _selectedImagePathList.add(path);
      _selectedImageList.add(FileImage(File(path)));
      setState(() {});
    } on PlatformException catch (e) {
      print('出错了，${e}');
    }
  }

  void selectMulti() async {
    try {
      final res = await KangImagePicker.selectMultiPhotos();
      if (res == null) {
        print('结果为空');
        return;
      }
      for (final String path in res) {
        _selectedImagePathList.add(path);
        _selectedImageList.add(FileImage(File(path)));
      }
      setState(() {});
    } on PlatformException catch (e) {
      print('出错了，${e}');
    }
  }

  void selectVideo() async {
    try {
      await _playerController?.dispose();
      _playerController = null;
      final path = await KangImagePicker.selectVideo();
      if (path == null) {
        print('结果为空');
        return;
      }
      _selectedImagePathList.add(path);
      _playerController = VideoPlayerController.file(File(path));
      await _playerController!.initialize();
      setState(() {});
    } on PlatformException catch (e) {
      print('出错了，${e}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kang Picker ${_version ?? ''}'),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedImagePathList.clear();
                _selectedImageList.clear();
              });
            },
            icon: const Icon(Icons.clear),
            label: Text('清除图片'),
            style: const ButtonStyle(
              foregroundColor: MaterialStatePropertyAll(Colors.white),
            ),
          ),
        ],
      ),
      body: Flex(
        direction: Axis.vertical,
        children: [
          Flexible(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: [
                        _button('选择单个图片', selectOne, color: Colors.pinkAccent),
                        _button(
                          '选择多个图片',
                          selectMulti,
                          color: Colors.indigoAccent,
                        ),
                        _button('选择视频', selectVideo, color: Colors.greenAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedImageList.isNotEmpty) _buildSelectedAssetsListView(),
          if (_playerController != null) _buildVideoPlayView(),
          if (_selectedImagePathList.isNotEmpty) _buildSuccessPathListView(),
        ],
      ),
    );
  }

  Widget _button(String label, VoidCallback onTap, {Color? color}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ButtonStyle(
        backgroundColor: MaterialStatePropertyAll(
          color ?? Colors.deepPurpleAccent,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildSuccessPathListView() {
    return Flexible(
      child: ListView.separated(
        shrinkWrap: true,
        itemBuilder: (_, int index) {
          final path = _selectedImagePathList.elementAt(index);
          return ListTile(
            title: SelectableText(
              '${index + 1} - $path',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          );
        },
        itemCount: _selectedImagePathList.length,
        separatorBuilder: (BuildContext context, int index) {
          return const Divider();
        },
      ),
    );
  }

  Widget _buildVideoPlayView() {
    return Flexible(
      child: AspectRatio(
        aspectRatio: _playerController!.value.aspectRatio,
        child: VideoPlayer(_playerController!),
      ),
    );
  }

  //
  Widget _buildSelectedAssetsListView() {
    return Flexible(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemCount: _selectedImageList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemBuilder: (BuildContext _, int index) {
          final FileImage asset = _selectedImageList.elementAt(index);
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                RepaintBoundary(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image(
                      image: asset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: -8.0,
                  top: -8.0,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedImageList.removeAt(index);
                      });
                    },
                    icon: Icon(Icons.cancel),
                    iconSize: 18,
                    color: Colors.pinkAccent,
                    padding: EdgeInsets.all(0.0),
                    alignment: Alignment.topRight,
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  String strToBase64(String str) {
    //base64编码 - 转utf8
    return base64.encode(utf8.encode(str));
  }
}
