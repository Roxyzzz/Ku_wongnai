import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Widget สำหรับโหลดและแสดงรูปจาก Firebase Storage โดยใช้ storage path
/// เช่น 'restaurants/artofcoffee/cover.jpg'
class StorageImageWidget extends StatefulWidget {
  final String? storagePath; // path ใน Firebase Storage
  final BoxFit fit;
  final Widget? placeholder;
  final double? width;
  final double? height;

  const StorageImageWidget({
    super.key,
    required this.storagePath,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.width,
    this.height,
  });

  @override
  State<StorageImageWidget> createState() => _StorageImageWidgetState();
}

class _StorageImageWidgetState extends State<StorageImageWidget> {
  String? _downloadUrl;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetchUrl();
  }

  @override
  void didUpdateWidget(StorageImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath) {
      _fetchUrl();
    }
  }

  Future<void> _fetchUrl() async {
    final path = widget.storagePath;
    if (path == null || path.isEmpty) {
      if (mounted) setState(() { _loading = false; _error = true; });
      return;
    }
    try {
      setState(() { _loading = true; _error = false; });
      final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
      if (mounted) setState(() { _downloadUrl = url; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPlaceholder = widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[200],
          child: const Icon(Icons.image, color: Colors.grey),
        );

    if (_loading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[100],
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
          ),
        ),
      );
    }

    if (_error || _downloadUrl == null) return defaultPlaceholder;

    return Image.network(
      _downloadUrl!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (_, __, ___) => defaultPlaceholder,
    );
  }
}

/// Widget สำหรับใช้เป็น DecorationImage ไม่ได้ แต่ wrap Container ได้ง่ายๆ
/// ใช้สำหรับการแสดงรูปแบบ BoxDecoration (ที่ต้องใช้ Stack)
class StorageImageBox extends StatefulWidget {
  final String? storagePath;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? child;
  final double? width;
  final double? height;
  final Color? backgroundColor;

  const StorageImageBox({
    super.key,
    required this.storagePath,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.child,
    this.width,
    this.height,
    this.backgroundColor,
  });

  @override
  State<StorageImageBox> createState() => _StorageImageBoxState();
}

class _StorageImageBoxState extends State<StorageImageBox> {
  String? _downloadUrl;

  @override
  void initState() {
    super.initState();
    _fetchUrl();
  }

  @override
  void didUpdateWidget(StorageImageBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath) {
      _fetchUrl();
    }
  }

  Future<void> _fetchUrl() async {
    final path = widget.storagePath;
    if (path == null || path.isEmpty) return;
    try {
      final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
      if (mounted) setState(() => _downloadUrl = url);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[200],
        borderRadius: widget.borderRadius,
        image: _downloadUrl != null
            ? DecorationImage(
                image: NetworkImage(_downloadUrl!),
                fit: widget.fit,
              )
            : null,
      ),
      child: widget.child,
    );
  }
}
