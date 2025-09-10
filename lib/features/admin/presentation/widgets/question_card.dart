import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/question_models.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const QuestionCard({
    Key? key,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getTypeColor().withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlack.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Imagen de la pregunta
            if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  question.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    width: double.infinity,
                    color: AppTheme.greyDark,
                    child: const Icon(Icons.broken_image,
                        color: AppTheme.greyLight, size: 50),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Header con tipo y acciones
            Row(
              children: [
                // Chip del tipo
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getTypeColor().withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTypeIcon(),
                        size: 14,
                        color: _getTypeColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTypeLabel(),
                        style: TextStyle(
                          color: _getTypeColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Botones de acción
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppTheme.info,
                        size: 20,
                      ),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Pregunta
            Text(
              question.question,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Opciones (si aplica)
            if (question.options.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: question.options.take(3).map((option) {
                  final isCorrect = option == question.correctAnswer;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? AppTheme.success.withOpacity(0.2)
                          : AppTheme.greyDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCorrect
                            ? AppTheme.success.withOpacity(0.5)
                            : AppTheme.greyDark.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCorrect) ...[
                          const Icon(
                            Icons.check,
                            size: 12,
                            color: AppTheme.success,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          option,
                          style: TextStyle(
                            color: isCorrect
                                ? AppTheme.success
                                : AppTheme.greyLight,
                            fontSize: 12,
                            fontWeight:
                                isCorrect ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if (question.options.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${question.options.length - 3} opciones más',
                    style: const TextStyle(
                      color: AppTheme.greyMedium,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ] else if (question.type == QuestionType.freeText) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.success.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 12, color: AppTheme.success),
                    const SizedBox(width: 4),
                    Text(
                      'Respuesta: ${question.correctAnswer}',
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Footer con información adicional
            Row(
              children: [
                // Tiempo límite
                if (question.hasTimeLimit) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: AppTheme.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${question.timeLimit}s',
                          style: const TextStyle(
                            color: AppTheme.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Fecha de creación
                Text(
                  _getTimeAgo(question.createdAt),
                  style: const TextStyle(
                    color: AppTheme.greyMedium,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return AppTheme.info;
      case QuestionType.trueFalse:
        return AppTheme.warning;
      case QuestionType.freeText:
        return AppTheme.success;
    }
  }

  IconData _getTypeIcon() {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return Icons.radio_button_checked;
      case QuestionType.trueFalse:
        return Icons.check_box;
      case QuestionType.freeText:
        return Icons.text_fields;
    }
  }

  String _getTypeLabel() {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return 'Opción Múltiple';
      case QuestionType.trueFalse:
        return 'V/F';
      case QuestionType.freeText:
        return 'Texto Libre';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }
}
