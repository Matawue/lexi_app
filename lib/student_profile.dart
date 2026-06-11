class StudentProfile {
  final String id;
  final String name;
  final bool allowAnimations;
  final String selectedColorPalette;

  StudentProfile({
    required this.id,
    required this.name,
    this.allowAnimations = true,
    this.selectedColorPalette = 'default',
  });

  // Permite crear copias inmutables, ideal para Riverpod y Clean Architecture
  StudentProfile copyWith({
    String? id,
    String? name,
    bool? allowAnimations,
    String? selectedColorPalette,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      allowAnimations: allowAnimations ?? this.allowAnimations,
      selectedColorPalette: selectedColorPalette ?? this.selectedColorPalette,
    );
  }
}