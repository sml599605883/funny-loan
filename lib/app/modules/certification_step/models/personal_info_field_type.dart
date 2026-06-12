enum PersonalInfoFieldType {
  text,
  enumeration,
  citySelect,
  unknown;

  static PersonalInfoFieldType fromRaw(String rawType) {
    switch (rawType.trim()) {
      case 'Craniosacral':
        return PersonalInfoFieldType.text;
      case 'Ataractics':
        return PersonalInfoFieldType.enumeration;
      case 'RestroomInefficacies':
        return PersonalInfoFieldType.citySelect;
      default:
        return PersonalInfoFieldType.unknown;
    }
  }
}
