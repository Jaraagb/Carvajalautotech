// create_question_screen.dart
import 'dart:io';
import 'package:carvajal_autotech/services/category_service.dart';
import 'package:carvajal_autotech/services/questions_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/question_models.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';

class CreateQuestionScreen extends StatefulWidget {
  final String? questionId;

  const CreateQuestionScreen({Key? key, this.questionId}) : super(key: key);

  @override
  State<CreateQuestionScreen> createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends State<CreateQuestionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _explanationController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];

  QuestionType _selectedType = QuestionType.multipleChoice;
  String? _selectedCategory;
  bool _hasTimeLimit = false;
  bool _isLoading = false;
  String _correctAnswer = '';

  String? _imageUrl;
  File? _imageFile;

  final QuestionsService _questionsService = QuestionsService();
  final CategoryService _categoriesService = CategoryService();

  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeOptions();
    _loadCategories();
    if (widget.questionId != null) {
      _loadQuestionData();
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _initializeOptions() {
    _optionControllers.clear();
    for (int i = 0; i < 2; i++) {
      _optionControllers.add(TextEditingController());
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _categoriesService.getAllCategories();
      setState(() {
        _categories = cats;
        if (_categories.isNotEmpty && _selectedCategory == null) {
          _selectedCategory = _categories.first.id;
        }
      });
    } catch (e) {
      debugPrint('❌ Error cargando categorías: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error cargando categorías'),
              backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _loadQuestionData() async {
    try {
      final question =
          await _questionsService.getQuestionById(widget.questionId!);

      setState(() {
        _questionController.text = question.question;
        _explanationController.text = question.explanation ?? '';
        _selectedType = question.type;
        _selectedCategory = question.categoryId;
        _hasTimeLimit = question.timeLimit != null;
        if (_hasTimeLimit) {
          _timeLimitController.text = question.timeLimit.toString();
        }

        _imageUrl = question.imageUrl;

        // Opciones
        _optionControllers.clear();
        if (question.type == QuestionType.multipleChoice) {
          for (var opt in question.options) {
            _optionControllers.add(TextEditingController(text: opt));
          }

          // Buscar índice de la respuesta correcta
          final idx = question.options.indexOf(question.correctAnswer);
          if (idx != -1) {
            _correctAnswer = 'option_$idx';
          }
        } else if (question.type == QuestionType.trueFalse) {
          _optionControllers.add(TextEditingController(text: 'Verdadero'));
          _optionControllers.add(TextEditingController(text: 'Falso'));
          _correctAnswer = question.correctAnswer;
        } else if (question.type == QuestionType.freeText) {
          _correctAnswer = question.correctAnswer;
        }
      });
    } catch (e) {
      debugPrint('❌ Error cargando pregunta: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error cargando pregunta'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _questionController.dispose();
    _explanationController.dispose();
    _timeLimitController.dispose();
    for (var c in _optionControllers) c.dispose();
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= AppConstants.maxOptionsCount) return;
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int idx) {
    if (_optionControllers.length <= AppConstants.minOptionsCount) return;
    setState(() {
      final removedKey = 'option_$idx';
      if (_correctAnswer == removedKey) {
        _correctAnswer = '';
      } else if (_correctAnswer.startsWith('option_')) {
        final i = int.tryParse(_correctAnswer.replaceFirst('option_', ''));
        if (i != null && i > idx) _correctAnswer = 'option_${i - 1}';
      }
      _optionControllers[idx].dispose();
      _optionControllers.removeAt(idx);
    });
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;

      setState(() => _isLoading = true);

      final file = File(picked.path);
      _imageFile = file;

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';

      final bucket = Supabase.instance.client.storage.from('question_images');

      // Subir en bytes
      await bucket.uploadBinary(fileName, await file.readAsBytes());

      // URL pública
      final publicUrl = bucket.getPublicUrl(fileName);

      setState(() {
        _imageUrl = publicUrl;
      });
    } on PostgrestException catch (e) {
      debugPrint('❌ Error Supabase upload: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error subiendo imagen: ${e.message}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error subir imagen: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error subiendo imagen'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecciona una categoría'),
          backgroundColor: AppTheme.error));
      return;
    }
    if (_selectedType != QuestionType.freeText && _correctAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecciona respuesta correcta'),
          backgroundColor: AppTheme.error));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // definir correctAnswer real
      String finalCorrect;
      if (_selectedType == QuestionType.multipleChoice) {
        final idx = int.tryParse(_correctAnswer.replaceAll('option_', ''));
        if (idx == null || idx < 0 || idx >= _optionControllers.length) {
          throw Exception('Índice de respuesta correcto inválido');
        }
        finalCorrect = _optionControllers[idx].text.trim();
      } else if (_selectedType == QuestionType.trueFalse) {
        finalCorrect = _correctAnswer;
      } else {
        finalCorrect = _correctAnswer.trim();
      }

      final form = QuestionForm(
        id: widget.questionId,
        categoryId: _selectedCategory!,
        type: _selectedType,
        question: _questionController.text.trim(),
        options: _selectedType == QuestionType.multipleChoice
            ? _optionControllers.map((c) => c.text.trim()).toList()
            : (_selectedType == QuestionType.trueFalse
                ? ['Verdadero', 'Falso']
                : []),
        correctAnswer: finalCorrect,
        timeLimit: _hasTimeLimit
            ? int.tryParse(_timeLimitController.text.trim())
            : null,
        imageUrl: _imageUrl,
        explanation: _explanationController.text.trim().isNotEmpty
            ? _explanationController.text.trim()
            : null,
      );

      if (widget.questionId == null) {
        await _questionsService.createQuestion(form);
      } else {
        await _questionsService.updateQuestion(form);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.questionId == null
            ? 'Pregunta creada'
            : 'Pregunta actualizada'),
        backgroundColor: AppTheme.success,
      ));
      Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      debugPrint('PG error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: AppTheme.error));
    } catch (e) {
      debugPrint('Error guardando pregunta: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error guardando pregunta'),
          backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI builders below (completo) ---

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.questionId != null;
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: Text(isEditing ? 'Editar Pregunta' : 'Crear Pregunta',
            style: const TextStyle(color: AppTheme.white)),
        leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white)),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (_, __) => FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildTypeSelector(),
                    const SizedBox(height: 20),
                    _buildCategorySelector(),
                    const SizedBox(height: 20),
                    _buildQuestionField(),
                    const SizedBox(height: 20),
                    _buildExplanationField(),
                    const SizedBox(height: 20),
                    _buildImageSection(),
                    const SizedBox(height: 20),
                    _buildOptionsSection(),
                    const SizedBox(height: 20),
                    _buildTimeLimitSection(),
                    const SizedBox(height: 28),
                    _buildActionButtons(),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.quiz_outlined, color: AppTheme.white)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(
                  widget.questionId == null
                      ? 'Crear pregunta'
                      : 'Editar pregunta',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppTheme.white))),
        ]),
      );

  Widget _buildTypeSelector() {
    return Row(
      children: QuestionType.values.map((t) {
        final selected = _selectedType == t;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = t;
                _correctAnswer = '';
                if (t == QuestionType.multipleChoice &&
                    _optionControllers.isEmpty) _initializeOptions();
                if (t == QuestionType.trueFalse) {
                  for (var c in _optionControllers) c.dispose();
                  _optionControllers.clear();
                  _optionControllers
                      .add(TextEditingController()..text = 'Verdadero');
                  _optionControllers
                      .add(TextEditingController()..text = 'Falso');
                }
                if (t == QuestionType.freeText) {
                  for (var c in _optionControllers) c.dispose();
                  _optionControllers.clear();
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primaryRed.withOpacity(0.2)
                    : AppTheme.lightBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selected
                        ? AppTheme.primaryRed
                        : AppTheme.greyDark.withOpacity(0.5),
                    width: selected ? 2 : 1),
              ),
              child: Column(children: [
                Icon(_getTypeIcon(t),
                    color: selected ? AppTheme.primaryRed : AppTheme.greyLight),
                const SizedBox(height: 6),
                Text(_getTypeLabel(t),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: selected
                            ? AppTheme.primaryRed
                            : AppTheme.greyLight))
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Categoría',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppTheme.white)),
      const SizedBox(height: 8),
      _categories.isEmpty
          ? const Text('Cargando categorías...',
              style: TextStyle(color: AppTheme.greyLight))
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                dropdownColor: AppTheme.lightBlack,
                style: const TextStyle(color: AppTheme.white),
                onChanged: (v) => setState(() => _selectedCategory = v),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
              ),
            ),
    ]);
  }

  Widget _buildQuestionField() => CustomTextField(
        controller: _questionController,
        label: 'Pregunta',
        hint: 'Escribe la pregunta...',
        maxLines: 3,
        maxLength: AppConstants.maxQuestionLength,
        validator: (v) {
          if (v?.isEmpty ?? true) return 'La pregunta es obligatoria';
          if (v!.length < 10) return 'Mínimo 10 caracteres';
          return null;
        },
      );

  Widget _buildExplanationField() => CustomTextField(
        controller: _explanationController,
        label: 'Explicación (opcional)',
        hint: 'Explica por qué la respuesta es correcta...',
        maxLines: 4,
        maxLength: 500,
        validator: null, // Campo opcional
      );

  Widget _buildImageSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Imagen (opcional)',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppTheme.white)),
      const SizedBox(height: 8),
      if (_imageUrl != null)
        Column(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(_imageUrl!,
                  height: 180, width: double.infinity, fit: BoxFit.cover)),
          const SizedBox(height: 8),
          Row(children: [
            ElevatedButton.icon(
                onPressed: _pickAndUploadImage,
                icon: const Icon(Icons.edit),
                label: const Text('Reemplazar'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed)),
            const SizedBox(width: 12),
            OutlinedButton.icon(
                onPressed: () => setState(() {
                      _imageUrl = null;
                      _imageFile = null;
                    }),
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar')),
          ])
        ])
      else
        ElevatedButton.icon(
            onPressed: _pickAndUploadImage,
            icon: const Icon(Icons.upload),
            label: const Text('Subir imagen'),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed)),
    ]);
  }

  Widget _buildOptionsSection() {
    switch (_selectedType) {
      case QuestionType.multipleChoice:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Opciones',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppTheme.white)),
            if (_optionControllers.length < AppConstants.maxOptionsCount)
              IconButton(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppTheme.primaryRed))
          ]),
          const SizedBox(height: 8),
          ...List.generate(_optionControllers.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Radio<String>(
                    value: 'option_$i',
                    groupValue: _correctAnswer,
                    onChanged: (v) => setState(() => _correctAnswer = v ?? ''),
                    activeColor: AppTheme.success),
                Expanded(
                    child: CustomTextField(
                        controller: _optionControllers[i],
                        label: 'Opción ${i + 1}',
                        hint: 'Texto de la opción',
                        validator: (v) =>
                            (v?.isEmpty ?? true) ? 'Obligatoria' : null)),
                if (_optionControllers.length > AppConstants.minOptionsCount)
                  IconButton(
                      onPressed: () => _removeOption(i),
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppTheme.error)),
              ]),
            );
          }),
        ]);
      case QuestionType.trueFalse:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Respuesta correcta',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.white)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _optionToggle('Verdadero', AppTheme.success)),
            const SizedBox(width: 12),
            Expanded(child: _optionToggle('Falso', AppTheme.error)),
          ]),
        ]);
      case QuestionType.freeText:
        return CustomTextField(
            controller: TextEditingController(text: _correctAnswer),
            label: 'Respuesta esperada',
            hint: 'Texto esperado',
            onChanged: (v) => _correctAnswer = v,
            validator: (v) => (v?.isEmpty ?? true) ? 'Obligatoria' : null);
    }
  }

  Widget _optionToggle(String label, Color color) {
    final selected = _correctAnswer == label;
    return GestureDetector(
      onTap: () => setState(() => _correctAnswer = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : AppTheme.lightBlack,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? color : AppTheme.greyDark.withOpacity(0.5))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? color : AppTheme.greyLight),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(color: selected ? color : AppTheme.greyLight))
        ]),
      ),
    );
  }

  Widget _buildTimeLimitSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Checkbox(
            value: _hasTimeLimit,
            onChanged: (v) => setState(() {
                  _hasTimeLimit = v ?? false;
                  if (!_hasTimeLimit) _timeLimitController.clear();
                }),
            activeColor: AppTheme.warning),
        const SizedBox(width: 8),
        Text('Limite de tiempo (segundos)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppTheme.white)),
      ]),
      if (_hasTimeLimit)
        CustomTextField(
          controller: _timeLimitController,
          label: 'Segundos',
          keyboardType: TextInputType.number,
          validator: (v) {
            if (_hasTimeLimit && (v?.isEmpty ?? true)) return 'Obligatorio';
            if (_hasTimeLimit) {
              final t = int.tryParse(v ?? '');
              if (t == null || t < AppConstants.minTimeLimitSeconds)
                return 'Mínimo ${AppConstants.minTimeLimitSeconds}s';
              if (t > AppConstants.maxTimeLimitSeconds)
                return 'Máximo ${AppConstants.maxTimeLimitSeconds}s';
            }
            return null;
          },
          hint: '',
        ),
    ]);
  }

  Widget _buildActionButtons() {
    return Column(children: [
      CustomButton(
          text: widget.questionId == null
              ? 'Crear Pregunta'
              : 'Actualizar Pregunta',
          onPressed: _saveQuestion,
          isLoading: _isLoading,
          gradient: AppTheme.primaryGradient,
          icon: widget.questionId == null ? Icons.add : Icons.save),
      const SizedBox(height: 12),
      CustomButton(
          text: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
          isOutlined: true),
    ]);
  }

  IconData _getTypeIcon(QuestionType t) {
    switch (t) {
      case QuestionType.multipleChoice:
        return Icons.radio_button_checked;
      case QuestionType.trueFalse:
        return Icons.check_box;
      case QuestionType.freeText:
        return Icons.text_fields;
    }
  }

  String _getTypeLabel(QuestionType t) {
    switch (t) {
      case QuestionType.multipleChoice:
        return 'Opción múltiple';
      case QuestionType.trueFalse:
        return 'Verdadero/Falso';
      case QuestionType.freeText:
        return 'Texto libre';
    }
  }
}
