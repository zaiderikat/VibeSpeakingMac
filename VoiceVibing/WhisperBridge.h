#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef struct WhisperBridge WhisperBridge;

WhisperBridge* whisper_bridge_init(const char* model_path, int threads);
void whisper_bridge_free(WhisperBridge* bridge);

char* whisper_bridge_transcribe_wav(WhisperBridge* bridge,
                                    const char* wav_path,
                                    const char* language,
                                    const char* prompt);

void whisper_bridge_free_string(char* str);

#ifdef __cplusplus
}
#endif
