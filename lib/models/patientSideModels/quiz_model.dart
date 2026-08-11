class baseResp {
  List<Questions> questions;

  baseResp({required this.questions});

  baseResp.fromJson(Map<String, dynamic> json)
      : questions = (json['questions'] as List<dynamic>?)
                ?.map((e) => Questions.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['questions'] = questions.map((v) => v.toJson()).toList();
    return data;
  }
}

class Questions {
  Question? question;

  Questions({this.question});

  Questions.fromJson(Map<String, dynamic> json) {
    question = json['question'] != null
        ? Question.fromJson(json['question'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (question != null) {
      data['question'] = question!.toJson();
    }
    return data;
  }
}

class Question {
  String? sId;
  String? question;
  List<String>? options;
  String? type;
  int? iV;

  Question({this.sId, this.question, this.options, this.type, this.iV});

  Question.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    question = json['question'];
    options = json['options']?.cast<String>();
    type = json['type'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['question'] = question;
    data['options'] = options;
    data['type'] = type;
    data['__v'] = iV;
    return data;
  }
}
