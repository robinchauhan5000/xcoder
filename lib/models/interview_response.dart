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
  considerations('considerations'),
  problemStatement('problem_statement'),
  functionalRequirements('functional_requirements'),
  nonFunctionalRequirements('non_functional_requirements'),
  highLevelArchitectureOverview('high_level_architecture_overview'),
  mainComponentsAndResponsibilities('main_components_and_responsibilities'),
  highLevelDataFlow('high_level_data_flow'),
  primaryWriteFlow('primary_write_flow'),
  primaryReadFlow('primary_read_flow'),
  backgroundOrAsynchronousFlow('background_or_asynchronous_flow'),
  cachingStrategy('caching_strategy'),
  loadBalancingStrategy('load_balancing_strategy'),
  dataModelOverview('data_model_overview'),
  databaseDesign('database_design'),
  indexingStrategyAndReason('indexing_strategy_and_reason'),
  dataGrowthAndStorageConsiderations(
    'data_growth_and_storage_considerations',
  ),
  failureScenarios('failure_scenarios'),
  failureHandling('failure_handling'),
  degradedBehaviorAndFallbacks('degraded_behavior_and_fallbacks'),
  scalingReadTraffic('scaling_read_traffic'),
  scalingWriteTraffic('scaling_write_traffic'),
  tradeOffsInDesignDecisions('trade_offs_in_design_decisions'),
  veryLargeScaleChanges('very_large_scale_changes'),
  coreBusinessLogic('core_business_logic');

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
  String get title {
    final words = value.split('_');
    final titled = words
        .map(
          (word) =>
              word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
    return titled;
  }

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
      this == SectionType.considerations ||
      this == SectionType.problemStatement ||
      this == SectionType.functionalRequirements ||
      this == SectionType.nonFunctionalRequirements ||
      this == SectionType.highLevelArchitectureOverview ||
      this == SectionType.mainComponentsAndResponsibilities ||
      this == SectionType.highLevelDataFlow ||
      this == SectionType.primaryWriteFlow ||
      this == SectionType.primaryReadFlow ||
      this == SectionType.backgroundOrAsynchronousFlow ||
      this == SectionType.cachingStrategy ||
      this == SectionType.loadBalancingStrategy ||
      this == SectionType.dataModelOverview ||
      this == SectionType.databaseDesign ||
      this == SectionType.indexingStrategyAndReason ||
      this == SectionType.dataGrowthAndStorageConsiderations ||
      this == SectionType.failureScenarios ||
      this == SectionType.failureHandling ||
      this == SectionType.degradedBehaviorAndFallbacks ||
      this == SectionType.scalingReadTraffic ||
      this == SectionType.scalingWriteTraffic ||
      this == SectionType.tradeOffsInDesignDecisions ||
      this == SectionType.veryLargeScaleChanges ||
      this == SectionType.coreBusinessLogic;
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
