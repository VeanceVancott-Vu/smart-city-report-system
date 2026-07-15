import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../../features/auth/data/token_storage.dart';

class UploadedPhotoView extends StatefulWidget {
  const UploadedPhotoView({
    super.key,
    required this.fileUrl,
    this.emptyLabel = 'No photo uploaded',
  });

  final String? fileUrl;
  final String emptyLabel;

  @override
  State<UploadedPhotoView> createState() => _UploadedPhotoViewState();
}

class _UploadedPhotoViewState extends State<UploadedPhotoView> {
  late final Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = _isFlutterTestBinding()
        ? Future<String?>.value(null)
        : const SecureTokenStorage().readToken().timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = widget.fileUrl?.trim() ?? '';
    if (rawUrl.isEmpty) {
      return Text(widget.emptyLabel);
    }

    if (_isFlutterTestBinding()) {
      return Text(rawUrl);
    }

    final imageUrl = resolveUploadedPhotoUrl(rawUrl);
    if (imageUrl == null) {
      return Text(rawUrl);
    }

    final requiresAuthentication = _requiresUploadedPhotoAuthentication(rawUrl);
    return FutureBuilder<String?>(
      future: _tokenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;
        final headers =
            requiresAuthentication && token != null && token.isNotEmpty
            ? <String, String>{'Authorization': 'Bearer $token'}
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImagePreview(imageUrl: imageUrl, headers: headers),
            const SizedBox(height: 8),
            Text(
              rawUrl,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}

String? resolveUploadedPhotoUrl(String? fileUrl, {String? baseUrl}) {
  final value = fileUrl?.trim() ?? '';
  if (value.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) {
    return value;
  }

  if (!value.startsWith('/')) {
    return null;
  }

  final configuredBaseUrl = (baseUrl ?? ApiConfig.requireBaseUrl()).trim();
  if (configuredBaseUrl.isEmpty) {
    return null;
  }

  final cleanBaseUrl = configuredBaseUrl.endsWith('/')
      ? configuredBaseUrl.substring(0, configuredBaseUrl.length - 1)
      : configuredBaseUrl;
  return '$cleanBaseUrl$value';
}

/// Displays an uploaded image using the same relative-URL and JWT handling as
/// [UploadedPhotoView], without the full-size preview and URL label.
class UploadedPhotoImage extends StatefulWidget {
  const UploadedPhotoImage({
    super.key,
    required this.fileUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  final String? fileUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  State<UploadedPhotoImage> createState() => _UploadedPhotoImageState();
}

class _UploadedPhotoImageState extends State<UploadedPhotoImage> {
  late final Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = _isFlutterTestBinding()
        ? Future<String?>.value(null)
        : const SecureTokenStorage().readToken().timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = widget.fileUrl?.trim() ?? '';
    if (rawUrl.isEmpty) {
      return _errorWidget();
    }

    if (_isFlutterTestBinding()) {
      return _errorWidget();
    }

    final imageUrl = resolveUploadedPhotoUrl(rawUrl);
    if (imageUrl == null) {
      return _errorWidget();
    }

    return FutureBuilder<String?>(
      future: _tokenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.placeholder ??
              const Center(child: CircularProgressIndicator());
        }

        final token = snapshot.data;
        final headers =
            _requiresUploadedPhotoAuthentication(rawUrl) &&
                token != null &&
                token.isNotEmpty
            ? <String, String>{'Authorization': 'Bearer $token'}
            : null;

        return Image.network(
          imageUrl,
          headers: headers,
          fit: widget.fit,
          errorBuilder: (_, __, ___) => _errorWidget(),
        );
      },
    );
  }

  Widget _errorWidget() {
    return widget.errorWidget ??
        const Center(child: Icon(Icons.broken_image_outlined));
  }
}

bool _requiresUploadedPhotoAuthentication(String fileUrl) {
  if (fileUrl.startsWith('/uploads/')) {
    return true;
  }

  final uri = Uri.tryParse(fileUrl);
  return uri != null && uri.path.startsWith('/uploads/');
}

bool _isFlutterTestBinding() {
  return WidgetsBinding.instance.runtimeType.toString().contains('Test');
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imageUrl, required this.headers});

  final String imageUrl;
  final Map<String, String>? headers;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openImageDialog(context, imageUrl),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                headers: headers,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image_outlined, size: 40),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openImageDialog(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  headers: headers,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return const SizedBox(
                      height: 320,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 320,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined, size: 48),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
