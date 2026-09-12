/// Represents a single UI node extracted from the Android screen.
class ScreenNode {
  final int id;
  final String? text;
  final String? description;
  final String? className;
  final Rect bounds;
  final int centerX;
  final int centerY;
  final bool isClickable;
  final bool isEditable;
  final bool isCheckable;
  final bool isChecked;
  final bool isEnabled;
  final int depth;

  ScreenNode({
    required this.id,
    this.text,
    this.description,
    this.className,
    required this.bounds,
    required this.centerX,
    required this.centerY,
    required this.isClickable,
    required this.isEditable,
    required this.isCheckable,
    required this.isChecked,
    required this.isEnabled,
    required this.depth,
  });

  factory ScreenNode.fromJson(Map<String, dynamic> json) {
    final boundsJson = json['bounds'] as Map<String, dynamic>? ?? {};
    
    return ScreenNode(
      id: json['id'] as int? ?? 0,
      text: json['text'] as String?,
      description: json['description'] as String?,
      className: json['className'] as String?,
      bounds: Rect(
        left: boundsJson['left'] as int? ?? 0,
        top: boundsJson['top'] as int? ?? 0,
        right: boundsJson['right'] as int? ?? 0,
        bottom: boundsJson['bottom'] as int? ?? 0,
      ),
      centerX: json['centerX'] as int? ?? 0,
      centerY: json['centerY'] as int? ?? 0,
      isClickable: json['isClickable'] as bool? ?? false,
      isEditable: json['isEditable'] as bool? ?? false,
      isCheckable: json['isCheckable'] as bool? ?? false,
      isChecked: json['isChecked'] as bool? ?? false,
      isEnabled: json['isEnabled'] as bool? ?? false,
      depth: json['depth'] as int? ?? 0,
    );
  }

  /// Returns a concise summary for AI prompt context
  String toPromptString() {
    final buffer = StringBuffer();
    buffer.write('[$id] ');
    
    if (text != null && text!.isNotEmpty) {
      buffer.write('"$text"');
    } else if (description != null && description!.isNotEmpty) {
      buffer.write('desc:"$description"');
    }
    
    buffer.write(' @(${bounds.left},${bounds.top})');
    buffer.write(' ${className?.split('.').last ?? "View"}');
    
    if (isEditable) buffer.write(' [EDITABLE]');
    if (isCheckable) buffer.write(' [CHECKABLE:${isChecked ? "ON" : "OFF"}]');
    if (!isEnabled) buffer.write(' [DISABLED]');
    
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'description': description,
        'className': className,
        'bounds': bounds.toJson(),
        'centerX': centerX,
        'centerY': centerY,
        'isClickable': isClickable,
        'isEditable': isEditable,
        'isCheckable': isCheckable,
        'isChecked': isChecked,
        'isEnabled': isEnabled,
        'depth': depth,
      };
}

class Rect {
  final int left;
  final int top;
  final int right;
  final int bottom;

  Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  int get width => right - left;
  int get height => bottom - top;

  Map<String, dynamic> toJson() => {
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
      };
}
