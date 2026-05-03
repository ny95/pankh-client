import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pankh/widgets/web_pointer_interceptor.dart';

class CustomDialog {
  static Future<void> show({
    required BuildContext context,
    required Widget child,
    bool isFullScreenCloseButton = true,
    ValueListenable<bool>? isFullScreenCloseButtonListenable,
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        final width = size.width;
        final height = size.height;
        final isSmallScreen = width < 900;
        Widget buildDialog(bool showFullScreenCloseButton) {
          final closeButton = IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                Theme.of(context).cardColor,
              ),
            ),
          );

          return WebPointerInterceptor(
            child:
                isSmallScreen
                    ? Dialog.fullscreen(
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 10.0,
                              right: 10.0,
                              bottom: 10.0,
                            ),
                            child: child,
                          ),
                          if (showFullScreenCloseButton)
                            Positioned(top: 6, right: 6, child: closeButton),
                        ],
                      ),
                    )
                    : AlertDialog(
                      contentPadding: EdgeInsets.zero,
                      insetPadding: const EdgeInsets.all(0),
                      backgroundColor: Theme.of(context).cardColor,
                      content: SizedBox(
                        width: width * 0.7,
                        height: height * 0.8,
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: child,
                            ),
                            Positioned(top: 10, right: 10, child: closeButton),
                          ],
                        ),
                      ),
                    ),
          );
        }

        if (isFullScreenCloseButtonListenable == null) {
          return buildDialog(isFullScreenCloseButton);
        }

        return ValueListenableBuilder<bool>(
          valueListenable: isFullScreenCloseButtonListenable,
          builder: (context, showFullScreenCloseButton, _) {
            return buildDialog(showFullScreenCloseButton);
          },
        );
      },
    );
  }
}
