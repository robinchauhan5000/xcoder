/// Interview category - affects system prompt and preferred section types
enum InterviewCategory {
  normal('Normal'),
  systemDesign('System Design'),
  codingRound('Coding Round'),
  shortAnswers('Short Answers');

  final String label;
  const InterviewCategory(this.label);
}
