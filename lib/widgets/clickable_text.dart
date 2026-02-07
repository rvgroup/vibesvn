import 'package:flutter/material.dart';
import '../helpers/link_helper.dart';

class ClickableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final VoidCallback? onTap;
  final bool enableLinkDetection;
  final int? maxLines;
  final TextOverflow? overflow;

  const ClickableText({
    Key? key,
    required this.text,
    this.style,
    this.onTap,
    this.enableLinkDetection = true,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isClickable = enableLinkDetection && 
                        (LinkHelper.isUrl(text) || LinkHelper.isFilePath(text));
    
    final displayText = enableLinkDetection ? LinkHelper.getDisplayText(text) : text;
    
    return GestureDetector(
      onTap: isClickable ? () async {
        if (onTap != null) {
          onTap!();
        } else {
          await LinkHelper.openLink(text);
        }
      } : onTap,
      child: MouseRegion(
        cursor: isClickable ? SystemMouseCursors.click : MouseCursor.defer,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: isClickable ? BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.transparent,
          ) : null,
          child: Text(
            displayText,
            maxLines: maxLines,
            overflow: overflow,
            style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
              color: isClickable ? Colors.blue : null,
              decoration: TextDecoration.none,
              fontWeight: isClickable ? FontWeight.bold : null,
            ),
          ),
        ),
      ),
    );
  }
}
