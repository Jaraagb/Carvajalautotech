import 'package:equatable/equatable.dart';

enum QuestionType {
  multipleChoice,
  trueFalse,
  freeText,
}

class Category extends Equatable {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final String createdBy; // ID del admin que la creó

  const Category({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.createdBy,
  });

  Category copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
    );
  }

  @override
  List<Object> get props => [id, name, description, createdAt, createdBy];
}

class Question extends Equatable {
  final String id;
  final String categoryId;
  final QuestionType type;
  final String question;
  final List<String> options; // Para multiple choice
  final String correctAnswer;
  final int? timeLimit; // En segundos, null si no hay límite
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy; // ID del admin

  const Question({
    required this.id,
    required this.categoryId,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.timeLimit,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  bool get hasTimeLimit => timeLimit != null && timeLimit! > 0;

  Question copyWith({
    String? id,
    String? categoryId,
    QuestionType? type,
    String? question,
    List<String>? options,
    String? correctAnswer,
    int? timeLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Question(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      timeLimit: timeLimit ?? this.timeLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'type': type.name,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'timeLimit': timeLimit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      type: QuestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: json['correctAnswer'] as String,
      timeLimit: json['timeLimit'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] as String,
    );
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        type,
        question,
        options,
        correctAnswer,
        timeLimit,
        createdAt,
        updatedAt,
        createdBy,
      ];
}

// Modelo para crear/editar preguntas
class QuestionForm extends Equatable {
  final String? id;
  final String categoryId;
  final QuestionType type;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final int? timeLimit;

  const QuestionForm({
    this.id,
    required this.categoryId,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.timeLimit,
  });

  bool get isEditing => id != null;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'categoryId': categoryId,
      'type': type.name,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'timeLimit': timeLimit,
    };
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        type,
        question,
        options,
        correctAnswer,
        timeLimit,
      ];
}

// Modelo para respuestas de estudiantes
class StudentAnswer extends Equatable {
  final String id;
  final String questionId;
  final String studentId;
  final String answer;
  final bool isCorrect;
  final DateTime answeredAt;
  final int? timeSpent; // En segundos

  const StudentAnswer({
    required this.id,
    required this.questionId,
    required this.studentId,
    required this.answer,
    required this.isCorrect,
    required this.answeredAt,
    this.timeSpent,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionId': questionId,
      'studentId': studentId,
      'answer': answer,
      'isCorrect': isCorrect,
      'answeredAt': answeredAt.toIso8601String(),
      'timeSpent': timeSpent,
    };
  }

  factory StudentAnswer.fromJson(Map<String, dynamic> json) {
    return StudentAnswer(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      studentId: json['studentId'] as String,
      answer: json['answer'] as String,
      isCorrect: json['isCorrect'] as bool,
      answeredAt: DateTime.parse(json['answeredAt'] as String),
      timeSpent: json['timeSpent'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        questionId,
        studentId,
        answer,
        isCorrect,
        answeredAt,
        timeSpent,
      ];
}

// Modelo para estadísticas
class QuestionStatistics extends Equatable {
  final String questionId;
  final int totalAnswers;
  final int correctAnswers;
  final int incorrectAnswers;
  final double accuracyPercentage;
  final double averageTimeSpent;

  const QuestionStatistics({
    required this.questionId,
    required this.totalAnswers,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.accuracyPercentage,
    required this.averageTimeSpent,
  });

  factory QuestionStatistics.fromJson(Map<String, dynamic> json) {
    return QuestionStatistics(
      questionId: json['questionId'] as String,
      totalAnswers: json['totalAnswers'] as int,
      correctAnswers: json['correctAnswers'] as int,
      incorrectAnswers: json['incorrectAnswers'] as int,
      accuracyPercentage: (json['accuracyPercentage'] as num).toDouble(),
      averageTimeSpent: (json['averageTimeSpent'] as num).toDouble(),
    );
  }

  @override
  List<Object> get props => [
        questionId,
        totalAnswers,
        correctAnswers,
        incorrectAnswers,
        accuracyPercentage,
        averageTimeSpent,
      ];
}

class StudentStatistics extends Equatable {
  final String studentId;
  final String studentName;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final double accuracyPercentage;
  final Map<String, int> categoryStats; // categoryId -> correct answers

  const StudentStatistics({
    required this.studentId,
    required this.studentName,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.accuracyPercentage,
    required this.categoryStats,
  });

  factory StudentStatistics.fromJson(Map<String, dynamic> json) {
    return StudentStatistics(
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      incorrectAnswers: json['incorrectAnswers'] as int,
      accuracyPercentage: (json['accuracyPercentage'] as num).toDouble(),
      categoryStats: Map<String, int>.from(json['categoryStats'] as Map),
    );
  }

  @override
  List<Object> get props => [
        studentId,
        studentName,
        totalQuestions,
        correctAnswers,
        incorrectAnswers,
        accuracyPercentage,
        categoryStats,
      ];
}