class A2UIWidget {
  final String type;
  final Map<String, dynamic> data;

  A2UIWidget({required this.type, required this.data});

  factory A2UIWidget.fromJson(Map<String, dynamic> json) {
    return A2UIWidget(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }
}

class A2UIResponse {
  final List<A2UIWidget> widgets;

  A2UIResponse({required this.widgets});

  factory A2UIResponse.fromJson(Map<String, dynamic> json) {
    var list = json['widgets'] as List;
    return A2UIResponse(
      widgets: list.map((i) => A2UIWidget.fromJson(i)).toList(),
    );
  }
}
