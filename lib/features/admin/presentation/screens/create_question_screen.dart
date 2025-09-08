import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/question_models.dart';
import '../../auth/presentation/widgets/custom_text_field.dart';
import '../../auth/presentation/widgets/custom_button.dart';

class CreateQuestionScreen extends StatefulWidget {
  final String? questionId;

  const CreateQuestionScreen({
    Key? key,
    this.questionId,
  }) : super(key: key);

  @override
  State<CreateQuestionScreen> createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends State<CreateQuestionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];

  QuestionType _selectedType = QuestionType.multipleChoice;
  String _selectedCategory = 'math';
  bool _hasTimeLimit = false;
  bool _isLoading = false;
  String _correctAnswer = '';

  // Datos simulados para categorías
  final List<Map<String, String>> _categories = [
    {'id': 'math', 'name': 'Matemáticas'},
    {'id': 'science', 'name': 'Ciencias'},
    {'id': 'history', 'name': 'Historia'},
    {'id': 'literature', 'name': 'Literatura'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeOptions();
    if (widget.questionId != null) {
      _loadQuestionData();
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  void _initializeOptions() {
    // Inicializar con 2 opciones para múltiple opción
    for (int i = 0; i < 2; i++) {
      _optionControllers.add(TextEditingController());
    }
  }

  void _loadQuestionData() {
    // TODO: Cargar datos de la pregunta existente para edición
    // Simulación de carga
    setState(() {
      _questionController.text = '¿Cuál es el resultado de 2 + 2?';
      _selectedType = QuestionType.multipleChoice;
      _selectedCategory = 'math';
      _hasTimeLimit = true;
      _timeLimitController.text = '30';
      _optionControllers[0].text = '3';
      _optionControllers[1].text = '4';
      _correctAnswer = '4';
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _questionController.dispose();
    _timeLimitController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < AppConstants.maxOptionsCount) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > AppConstants.minOptionsCount) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
        // Si se eliminó la respuesta correcta, reset
        if (_correctAnswer == 'option_$index') {
          _correctAnswer = '';
        }
      });
    }
  }

  void _changeQuestionType(QuestionType type) {
    setState(() {
      _selectedType = type;
      _correctAnswer = '';

      // Ajustar opciones según el tipo
      switch (type) {
        case QuestionType.multipleChoice:
          while (_optionControllers.length < 2) {
            _optionControllers.add(TextEditingController());
          }
          break;
        case QuestionType.trueFalse:
          _optionControllers.clear();
          _optionControllers.add(TextEditingController()..text = 'Verdadero');
          _optionControllers.add(TextEditingController()..text = 'Falso');
          break;
        case QuestionType.freeText:
          _optionControllers.clear();
          break;
      }
    });
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType != QuestionType.freeText && _correctAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la respuesta correcta'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simular guardado
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.questionId == null 
              ? 'Pregunta creada exitosamente'
              : 'Pregunta actualizada exitosamente'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.questionId != null;

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: Text(
          isEditing ? 'Editar Pregunta' : 'Crear Pregunta',
          style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AnimationLimiter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      AnimationConfiguration.staggeredList(
                        position: 0,
                        duration: const Duration(milliseconds: 600),
                        child: SlideAnimation(
                          verticalOffset: -30.0,
                          child: FadeInAnimation(
                            child: _buildHeaderSection(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Selector de tipo
                      AnimationConfiguration.staggeredList(
                        position: 1,
                        duration: const Duration(milliseconds: 700),
                        child: SlideAnimation(
                          horizontalOffset: -30.0,
                          child: FadeInAnimation(
                            child: _buildTypeSelector(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Categoría
                      AnimationConfiguration.staggeredList(
                        position: 2,
                        duration: const Duration(milliseconds: 800),
                        child: SlideAnimation(
                          horizontalOffset: 30.0,
                          child: FadeInAnimation(
                            child: _buildCategorySelector(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Pregunta
                      AnimationConfiguration.staggeredList(
                        position: 3,
                        duration: const Duration(milliseconds: 900),
                        child: SlideAnimation(
                          verticalOffset: 30.0,
                          child: FadeInAnimation(
                            child: _buildQuestionField(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Opciones (según el tipo)
                      AnimationConfiguration.staggeredList(
                        position: 4,
                        duration: const Duration(milliseconds: 1000),
                        child: SlideAnimation(
                          verticalOffset: 30.0,
                          child: FadeInAnimation(
                            child: _buildOptionsSection(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tiempo límite
                      AnimationConfiguration.staggeredList(
                        position: 5,
                        duration: const Duration(milliseconds: 1100),
                        child: SlideAnimation(
                          horizontalOffset: -30.0,
                          child: FadeInAnimation(
                            child: _buildTimeLimitSection(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Botones
                      AnimationConfiguration.staggeredList(
                        position: 6,
                        duration: const Duration(milliseconds: 1200),
                        child: SlideAnimation(
                          verticalOffset: 30.0,
                          child: FadeInAnimation(
                            child: _buildActionButtons(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.primaryShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  color: AppTheme.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.questionId == null ? 'Nueva Pregunta' : 'Editar Pregunta',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completa todos los campos requeridos',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.white.withOpacity(0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Pregunta',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: QuestionType.values.map((type) {
            final isSelected = _selectedType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => _changeQuestionType(type),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryRed.withOpacity(0.2) : AppTheme.lightBlack,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryRed : AppTheme.greyDark.withOpacity(0.5),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getTypeIcon(type),
                        color: isSelected ? AppTheme.primaryRed : AppTheme.greyLight,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getTypeLabel(type),
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryRed : AppTheme.greyLight,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoría',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.lightBlack,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.greyDark.withOpacity(0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              dropdownColor: AppTheme.lightBlack,
              icon: const Icon(Icons.expand_more, color: AppTheme.greyLight),
              style: const TextStyle(color: AppTheme.white),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category['id'],
                  child: Text(category['name']!),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionField() {
    return CustomTextField(
      controller: _questionController,
      label: 'Pregunta',
      hint: 'Escribe aquí tu pregunta...',
      maxLines: 3,
      maxLength: AppConstants.maxQuestionLength,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'La pregunta es obligatoria';
        }
        if (value!.length < 10) {
          return 'La pregunta debe tener al menos 10 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildOptionsSection() {
    switch (_selectedType) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceOptions();
      case QuestionType.trueFalse:
        return _buildTrueFalseOptions();
      case QuestionType.freeText:
        return _buildFreeTextAnswer();
    }
  }

  Widget _buildMultipleChoiceOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Opciones de Respuesta',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (_optionControllers.length < AppConstants.maxOptionsCount)
              IconButton(
                onPressed: _addOption,
                icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryRed),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_optionControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                // Radio button para respuesta correcta
                Radio<String>(
                  value: 'option_$index',
                  groupValue: _correctAnswer,
                  onChanged: (value) {
                    setState(() {
                      _correctAnswer = value!;
                    });
                  },
                  activeColor: AppTheme.success,
                ),
                // Campo de texto para la opción
                Expanded(
                  child: CustomTextField(
                    controller: _optionControllers[index],
                    label: 'Opción ${index + 1}',
                    hint: 'Escribe la opción...',
                    maxLength: AppConstants.maxOptionLength,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'La opción es obligatoria';
                      }
                      return null;
                    },
                  ),
                ),
                // Botón para eliminar opción
                if (_optionControllers.length > AppConstants.minOptionsCount)
                  IconButton(
                    onPressed: () => _removeOption(index),
                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.error),
                  ),
              ],
            ),
          );
        }),
        if (_correctAnswer.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selecciona la respuesta correcta marcando el círculo',
                    style: TextStyle(color: AppTheme.warning, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTrueFalseOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Respuesta Correcta',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _correctAnswer = 'Verdadero';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _correctAnswer == 'Verdadero' 
                        ? AppTheme.success.withOpacity(0.2)
                        : AppTheme.lightBlack,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _correctAnswer == 'Verdadero' 
                          ? AppTheme.success
                          : AppTheme.greyDark.withOpacity(0.5),
                      width: _correctAnswer == 'Verdadero' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: _correctAnswer == 'Verdadero' 
                            ? AppTheme.success
                            : AppTheme.greyLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Verdadero',
                        style: TextStyle(
                          color: _correctAnswer == 'Verdadero' 
                              ? AppTheme.success
                              : AppTheme.greyLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _correctAnswer = 'Falso';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _correctAnswer == 'Falso' 
                        ? AppTheme.error.withOpacity(0.2)
                        : AppTheme.lightBlack,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _correctAnswer == 'Falso' 
                          ? AppTheme.error
                          : AppTheme.greyDark.withOpacity(0.5),
                      width: _correctAnswer == 'Falso' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel,
                        color: _correctAnswer == 'Falso' 
                            ? AppTheme.error
                            : AppTheme.greyLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Falso',
                        style: TextStyle(
                          color: _correctAnswer == 'Falso' 
                              ? AppTheme.error
                              : AppTheme.greyLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFreeTextAnswer() {
    return CustomTextField(
      controller: TextEditingController(text: _correctAnswer),
      label: 'Respuesta Correcta',
      hint: 'Escribe la respuesta esperada...',
      onChanged: (value) {
        _correctAnswer = value;
      },
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'La respuesta es obligatoria';
        }
        return null;
      },
    );
  }

  Widget _buildTimeLimitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _hasTimeLimit,
              onChanged: (value) {
                setState(() {
                  _hasTimeLimit = value!;
                  if (!_hasTimeLimit) {
                    _timeLimitController.clear();
                  }
                });
              },
              activeColor: AppTheme.warning,
            ),
            Text(
              'Establecer límite de tiempo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        if (_hasTimeLimit) ...[
          const SizedBox(height: 12),
          CustomTextField(
            controller: _timeLimitController,
            label: 'Tiempo en segundos',
            hint: 'Ej: 30',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_hasTimeLimit && (value?.isEmpty ?? true)) {
                return 'El tiempo límite es obligatorio';
              }
              if (_hasTimeLimit) {
                final time = int.tryParse(value!);
                if (time == null || time < AppConstants.minTimeLimitSeconds) {
                  return 'Mínimo ${AppConstants.minTimeLimitSeconds} segundos';
                }
                if (time > AppConstants.maxTimeLimitSeconds) {
                  return 'Máximo ${AppConstants.maxTimeLimitSeconds} segundos';
                }
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: widget.questionId == null ? 'Crear Pregunta' : 'Actualizar Pregunta',
          onPressed: _saveQuestion,
          isLoading: _isLoading,
          gradient: AppTheme.primaryGradient,
          icon: widget.questionId == null ? Icons.add : Icons.save,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
          isOutlined: true,
        ),
      ],
    );
  }

  IconData _getTypeIcon(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return Icons.radio_button_checked;
      case QuestionType.trueFalse:
        return Icons.check_box;
      case QuestionType.freeText:
        return Icons.text_fields;
    }
  }

  String _getTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Opción\nMúltiple';
      case QuestionType.trueFalse:
        return 'Verdadero/\nFalso';
      case QuestionType.freeText:
        return 'Texto\nLibre';
    }
  }
}