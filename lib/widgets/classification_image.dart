import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/offline_mobile.dart';

Widget classificationImage(String url, {
  double? width, double? height, BoxFit? fit,
  Map<String, String>? headers, ImageErrorWidgetBuilder? errorBuilder,
  ImageLoadingBuilder? loadingBuilder, bool full = false,
}) {
  if (url.startsWith('abakascan-local:')) {
    return _LocalImage(id: url.substring('abakascan-local:'.length), width: width,
      height: height, fit: fit, full: full, errorBuilder: errorBuilder);
  }
  return Image.network(url, width: width, height: height, fit: fit, headers: headers,
      errorBuilder: errorBuilder, loadingBuilder: loadingBuilder);
}

class _LocalImage extends StatefulWidget {
  const _LocalImage({required this.id, required this.full, this.width, this.height, this.fit, this.errorBuilder});
  final String id;
  final bool full;
  final double? width, height;
  final BoxFit? fit;
  final ImageErrorWidgetBuilder? errorBuilder;
  @override
  State<_LocalImage> createState() => _LocalImageState();
}
class _LocalImageState extends State<_LocalImage> {
  late Future<Uint8List> _bytes;
  void _load() { _bytes = OfflineMobile.instance.image(widget.id, full: widget.full); }
  @override
  void initState() { super.initState(); _load(); }
  @override
  void didUpdateWidget(covariant _LocalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || oldWidget.full != widget.full) _load();
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(future: _bytes, builder: (context, snapshot) {
    if (snapshot.hasError) return widget.errorBuilder?.call(context, snapshot.error!, snapshot.stackTrace) ?? const Icon(Icons.broken_image_outlined);
    if (!snapshot.hasData) return SizedBox(width: widget.width, height: widget.height, child: const Center(child: CircularProgressIndicator()));
    return Image.memory(snapshot.data!, width: widget.width, height: widget.height, fit: widget.fit, errorBuilder: widget.errorBuilder);
  });
}
