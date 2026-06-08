import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutricam_proyect/core/app_colors.dart';
import 'package:nutricam_proyect/core/user_session.dart';
import 'package:nutricam_proyect/models/meal_image_analysis.dart';
import 'package:nutricam_proyect/services/meal_image_service.dart';

class ScanPlateScreen extends StatefulWidget {
  final String userName;

  const ScanPlateScreen({
    super.key,
    required this.userName,
  });

  @override
  State<ScanPlateScreen> createState() =>
      _ScanPlateScreenState();
}

class _ScanPlateScreenState extends State<ScanPlateScreen> {
  static const List<String> _mealTypes = [
    'DESAYUNO',
    'ALMUERZO',
    'MERIENDA',
    'CENA',
    'COLACION',
  ];

  static const List<String> _availableFoodGroups = [
    'FRUTAS',
    'VERDURAS',
    'LEGUMBRES',
    'CEREALES_Y_DERIVADOS',
    'PAPA_BATATA_MANDIOCA',
    'LECHE_YOGUR_Y_QUESO',
    'CARNES',
    'PESCADOS',
    'HUEVOS',
    'FRUTOS_SECOS_Y_SEMILLAS',
    'ACEITES_Y_GRASAS',
    'AZUCARES_Y_DULCES',
  ];

  final ImagePicker _imagePicker = ImagePicker();

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _mealNameController =
      TextEditingController();

  final TextEditingController _quantityController =
      TextEditingController();

  File? _selectedImage;
  MealImageAnalysis? _analysis;

  bool _isAnalyzing = false;
  bool _isConfirming = false;

  String? _analysisErrorMessage;
  String _selectedMealType = 'ALMUERZO';

  Set<String> _selectedFoodGroups = <String>{};

  @override
  void dispose() {
    _mealNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_isAnalyzing || _isConfirming) {
      return;
    }

    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedImage == null) {
      return;
    }

    _setSelectedImage(
      File(pickedImage.path),
    );
  }

  Future<void> _selectFromGallery() async {
    if (_isAnalyzing || _isConfirming) {
      return;
    }

    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedImage == null) {
      return;
    }

    _setSelectedImage(
      File(pickedImage.path),
    );
  }

  void _setSelectedImage(File image) {
    setState(() {
      _selectedImage = image;
      _analysis = null;
      _analysisErrorMessage = null;
      _selectedFoodGroups = <String>{};
      _selectedMealType = 'ALMUERZO';
    });

    _mealNameController.clear();
    _quantityController.clear();
  }

  void _removeImage() {
    if (_isAnalyzing || _isConfirming) {
      return;
    }

    setState(() {
      _selectedImage = null;
      _analysis = null;
      _analysisErrorMessage = null;
      _selectedFoodGroups = <String>{};
      _selectedMealType = 'ALMUERZO';
    });

    _mealNameController.clear();
    _quantityController.clear();
  }

  Future<void> _analyzeImage() async {
    final image = _selectedImage;
    final userId = UserSession.currentUser?.id;

    if (image == null) {
      _showMessage(
        'Primero seleccioná una imagen del plato.',
      );
      return;
    }

    if (userId == null) {
      _showMessage(
        'No se encontró el usuario de la sesión.',
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisErrorMessage = null;
      _analysis = null;
    });

    final result = await MealImageService.analyzeImage(
      userId: userId,
      image: image,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isAnalyzing = false;
    });

    if (result.isSuccess && result.analysis != null) {
      final analysis = result.analysis!;

      setState(() {
        _analysis = analysis;
        _analysisErrorMessage = null;
        _selectedFoodGroups =
            Set<String>.from(analysis.foodGroups);
      });

      _mealNameController.text =
          analysis.suggestedMealName;

      return;
    }

    setState(() {
      _analysisErrorMessage =
          result.message ??
          'No se pudo analizar la imagen.';
    });
  }

  Future<void> _confirmMeal() async {
    final analysis = _analysis;
    final userId = UserSession.currentUser?.id;

    if (analysis == null || userId == null) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedFoodGroups.isEmpty) {
      _showMessage(
        'Seleccioná al menos un grupo alimentario.',
      );
      return;
    }

    setState(() {
      _isConfirming = true;
    });

    final result = await MealImageService.confirmAnalysis(
      analysisId: analysis.id,
      userId: userId,
      mealName: _mealNameController.text,
      mealType: _selectedMealType,
      quantity: _quantityController.text,
      mealDate: DateTime.now(),
      foodGroups: _selectedFoodGroups,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isConfirming = false;
    });

    if (result.isSuccess &&
        result.analysis?.isConfirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La comida fue registrada correctamente.',
          ),
        ),
      );

      Navigator.pop(context, true);
      return;
    }

    _showMessage(
      result.message ??
          'No se pudo registrar la comida.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _toggleFoodGroup(
    String foodGroup,
    bool selected,
  ) {
    setState(() {
      if (selected) {
        _selectedFoodGroups.add(foodGroup);
      } else {
        _selectedFoodGroups.remove(foodGroup);
      }
    });
  }

  String? _validateMealName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresá el nombre de la comida.';
    }

    if (value.trim().length > 200) {
      return 'El nombre no puede superar los 200 caracteres.';
    }

    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresá una cantidad.';
    }

    if (value.trim().length > 100) {
      return 'La cantidad no puede superar los 100 caracteres.';
    }

    return null;
  }

  String _formatMealType(String value) {
    switch (value) {
      case 'DESAYUNO':
        return 'Desayuno';
      case 'ALMUERZO':
        return 'Almuerzo';
      case 'MERIENDA':
        return 'Merienda';
      case 'CENA':
        return 'Cena';
      case 'COLACION':
        return 'Colación';
      default:
        return _formatEnumValue(value);
    }
  }

  String _formatFoodGroup(String value) {
    switch (value) {
      case 'FRUTAS':
        return 'Frutas';
      case 'VERDURAS':
        return 'Verduras';
      case 'LEGUMBRES':
        return 'Legumbres';
      case 'CEREALES_Y_DERIVADOS':
        return 'Cereales y derivados';
      case 'PAPA_BATATA_MANDIOCA':
        return 'Papa, batata y mandioca';
      case 'LECHE_YOGUR_Y_QUESO':
        return 'Leche, yogur y queso';
      case 'CARNES':
        return 'Carnes';
      case 'PESCADOS':
        return 'Pescados';
      case 'HUEVOS':
        return 'Huevos';
      case 'FRUTOS_SECOS_Y_SEMILLAS':
        return 'Frutos secos y semillas';
      case 'ACEITES_Y_GRASAS':
        return 'Aceites y grasas';
      case 'AZUCARES_Y_DULCES':
        return 'Azúcares y dulces';
      default:
        return _formatEnumValue(value);
    }
  }

  String _formatEnumValue(String value) {
    if (value.isEmpty) {
      return value;
    }

    final formatted =
        value.toLowerCase().split('_').join(' ');

    return '${formatted[0].toUpperCase()}'
        '${formatted.substring(1)}';
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.7,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Escanear plato'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Registrá tu comida con una imagen',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tomá una fotografía clara del plato o '
              'seleccioná una imagen desde la galería.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            _buildImagePreview(),
            const SizedBox(height: 20),
            _buildImageButtons(),
            const SizedBox(height: 20),
            _buildAnalyzeButton(),
            if (_analysisErrorMessage != null) ...[
              const SizedBox(height: 16),
              _buildAnalysisError(),
            ],
            if (_analysis != null) ...[
              const SizedBox(height: 24),
              _buildAnalysisResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _selectedImage == null
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 70,
                  color: Colors.grey,
                ),
                SizedBox(height: 14),
                Text(
                  'Todavía no seleccionaste una imagen',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    onPressed:
                        _isAnalyzing || _isConfirming
                            ? null
                            : _removeImage,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildImageButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                _isAnalyzing || _isConfirming
                    ? null
                    : _takePhoto,
            icon: Icon(
              Icons.camera_alt_outlined,
              color: AppColors.backgroundComponent,
            ),
            label: Text(
              'Cámara',
              style: TextStyle(
                color: AppColors.backgroundComponent,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                _isAnalyzing || _isConfirming
                    ? null
                    : _selectFromGallery,
            icon: const Icon(
              Icons.photo_library_outlined,
            ),
            label: const Text('Galería'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _selectedImage == null ||
                _isAnalyzing ||
                _isConfirming
            ? null
            : _analyzeImage,
        icon: _isAnalyzing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                Icons.auto_awesome,
                color: AppColors.backgroundComponent,
              ),
        label: Text(
          _isAnalyzing
              ? 'Analizando imagen...'
              : _analysis == null
                  ? 'Analizar imagen'
                  : 'Analizar nuevamente',
          style: TextStyle(
            color: AppColors.backgroundComponent,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _analysisErrorMessage!,
              style: TextStyle(
                color: Colors.red.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    final analysis = _analysis!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Resultado del análisis',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (analysis.detectedFoods.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Alimentos detectados',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        analysis.detectedFoods.map((food) {
                      return Chip(
                        label: Text(food),
                        backgroundColor: Colors.white,
                      );
                    }).toList(),
                  ),
                ],
                if (analysis.warning.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          analysis.warning,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Revisá y corregí los datos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _mealNameController,
            enabled: !_isConfirming,
            textCapitalization:
                TextCapitalization.sentences,
            decoration: _inputDecoration(
              label: 'Nombre de la comida',
              icon: Icons.restaurant_menu,
              hint: 'Ej.: Pasta con jamón',
            ),
            validator: _validateMealName,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedMealType,
            decoration: _inputDecoration(
              label: 'Tipo de comida',
              icon: Icons.schedule_outlined,
            ),
            items: _mealTypes.map((mealType) {
              return DropdownMenuItem<String>(
                value: mealType,
                child: Text(
                  _formatMealType(mealType),
                ),
              );
            }).toList(),
            onChanged: _isConfirming
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedMealType = value;
                    });
                  },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _quantityController,
            enabled: !_isConfirming,
            decoration: _inputDecoration(
              label: 'Cantidad',
              icon: Icons.scale_outlined,
              hint: 'Ej.: 1 plato',
            ),
            validator: _validateQuantity,
          ),
          const SizedBox(height: 20),
          const Text(
            'Grupos alimentarios',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Corregí la selección si el análisis no fue exacto.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableFoodGroups.map((group) {
              final selected =
                  _selectedFoodGroups.contains(group);

              return FilterChip(
                label: Text(
                  _formatFoodGroup(group),
                ),
                selected: selected,
                onSelected: _isConfirming
                    ? null
                    : (value) {
                        _toggleFoodGroup(
                          group,
                          value,
                        );
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _isConfirming ? null : _confirmMeal,
              icon: _isConfirming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(
                _isConfirming
                    ? 'Registrando comida...'
                    : 'Confirmar y registrar',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'NutriCam no estima automáticamente la porción. '
            'Revisá siempre el resultado antes de confirmarlo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}