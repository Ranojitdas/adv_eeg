// To parse this JSON data, do
//
//     final brainScoreModel = brainScoreModelFromJson(jsonString);

import 'dart:convert';

List<BrainScoreModel> brainScoreModelFromJson(String str) => List<BrainScoreModel>.from(json.decode(str).map((x) => BrainScoreModel.fromJson(x)));

String brainScoreModelToJson(List<BrainScoreModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class BrainScoreModel {
    final String? uid;
    final DateTime? createdAt;
    final String? timestamp;
    final String? deviceId;
    final String? score;
    final String? user;

    BrainScoreModel({
        this.uid,
        this.createdAt,
        this.timestamp,
        this.deviceId,
        this.score,
        this.user,
    });

    factory BrainScoreModel.fromJson(Map<String, dynamic> json) => BrainScoreModel(
        uid: json["_id"] ?? json["uid"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        timestamp: json["timestamp"],
        deviceId: json["device_id"],
        score: _parseScore(json["score"]),
        user: json["user"] is Map ? json["user"]["_id"] : json["user"],
    );

    static String? _parseScore(dynamic scoreValue) {
      if (scoreValue == null) return null;
      
      // Handle MongoDB Decimal128 format: {"$numberDecimal": "50.696"}
      if (scoreValue is Map<String, dynamic> && scoreValue.containsKey('\$numberDecimal')) {
        return scoreValue['\$numberDecimal']?.toString();
      }
      
      // Handle regular string or number
      return scoreValue.toString();
    }

    Map<String, dynamic> toJson() => {
        "uid": uid,
        "created_at": createdAt?.toIso8601String(),
        "timestamp": timestamp,
        "device_id": deviceId,
        "score": score,
        "user": user,
    };
}

