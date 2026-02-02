/// Response model for interview assistant
class InterviewResponse {
  final String title;
  final List<ResponseSection> sections;

  const InterviewResponse({required this.title, required this.sections});

  factory InterviewResponse.fromJson(Map<String, dynamic> json) {
    return InterviewResponse(
      title: json['title'] as String,
      sections: (json['sections'] as List)
          .map(
            (section) =>
                ResponseSection.fromJson(section as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'sections': sections.map((section) => section.toJson()).toList(),
    };
  }
}

/// Section types for interview response
enum SectionType {
  shortAnswer('short_answer'),
  details('details'),
  code('code'),
  diagramFlow('diagram_flow'),
  highLevelDesign('high_level_design'),
  detailedDesign('detailed_design'),
  technologyChoices('technology_choices'),
  apiContracts('api_contracts'),
  dataModels('data_models'),
  algorithms('algorithms'),
  bottlenecksAndMitigations('bottlenecks_and_mitigations'),
  alternativeApproaches('alternative_approaches'),
  tradeOffs('trade_offs'),
  scalability('scalability'),
  considerations('considerations');

  final String value;
  const SectionType(this.value);

  static SectionType fromString(String value) {
    return SectionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SectionType.shortAnswer,
    );
  }
}

extension SectionTypeDisplay on SectionType {
  String get title => value;

  bool get isCode => this == SectionType.code;

  bool get isSystemDesign =>
      this == SectionType.diagramFlow ||
      this == SectionType.highLevelDesign ||
      this == SectionType.detailedDesign ||
      this == SectionType.technologyChoices ||
      this == SectionType.apiContracts ||
      this == SectionType.dataModels ||
      this == SectionType.algorithms ||
      this == SectionType.bottlenecksAndMitigations ||
      this == SectionType.alternativeApproaches ||
      this == SectionType.tradeOffs ||
      this == SectionType.scalability ||
      this == SectionType.considerations;
}

/// Individual section in the response
class ResponseSection {
  final SectionType type;
  final dynamic content;
  final String? language;

  const ResponseSection({
    required this.type,
    required this.content,
    this.language,
  });

  factory ResponseSection.fromJson(Map<String, dynamic> json) {
    final type = SectionType.fromString(json['type'] as String);

    return ResponseSection(
      type: type,
      content: json['content'],
      language: json['language'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'type': type.value, 'content': content};

    if (language != null) {
      map['language'] = language;
    }

    return map;
  }
}
