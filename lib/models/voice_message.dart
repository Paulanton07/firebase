class VoiceMessage {
  final String id;
  final String audioUrl;
  final String? transcription;
  final bool isTranscribing;

  VoiceMessage({
    required this.id,
    required this.audioUrl,
    this.transcription,
    this.isTranscribing = false,
  });

  VoiceMessage copyWith({
    String? id,
    String? audioUrl,
    String? transcription,
    bool? isTranscribing,
  }) {
    return VoiceMessage(
      id: id ?? this.id,
      audioUrl: audioUrl ?? this.audioUrl,
      transcription: transcription ?? this.transcription,
      isTranscribing: isTranscribing ?? this.isTranscribing,
    );
  }
}
