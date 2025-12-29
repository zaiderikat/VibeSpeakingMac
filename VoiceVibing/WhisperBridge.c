#include "WhisperBridge.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "whisper.h"

struct WhisperBridge {
    struct whisper_context* ctx;
    int threads;
};

static int read_wav_mono_16k(const char* path, float** out_samples, int* out_count) {
    FILE* f = fopen(path, "rb");
    if (!f) {
        return -1;
    }

    char riff[4];
    if (fread(riff, 1, 4, f) != 4 || memcmp(riff, "RIFF", 4) != 0) {
        fclose(f);
        return -1;
    }
    (void)fseek(f, 4, SEEK_CUR);
    char wave[4];
    if (fread(wave, 1, 4, f) != 4 || memcmp(wave, "WAVE", 4) != 0) {
        fclose(f);
        return -1;
    }

    int fmt_found = 0;
    int data_found = 0;
    unsigned short audio_format = 0;
    unsigned short channels = 0;
    unsigned int sample_rate = 0;
    unsigned short bits_per_sample = 0;
    unsigned int data_size = 0;

    while (!fmt_found || !data_found) {
        char chunk_id[4];
        if (fread(chunk_id, 1, 4, f) != 4) {
            break;
        }
        unsigned int chunk_size = 0;
        if (fread(&chunk_size, 4, 1, f) != 1) {
            break;
        }

        if (memcmp(chunk_id, "fmt ", 4) == 0) {
            fread(&audio_format, sizeof(audio_format), 1, f);
            fread(&channels, sizeof(channels), 1, f);
            fread(&sample_rate, sizeof(sample_rate), 1, f);
            fseek(f, 6, SEEK_CUR);
            fread(&bits_per_sample, sizeof(bits_per_sample), 1, f);
            if (chunk_size > 16) {
                fseek(f, chunk_size - 16, SEEK_CUR);
            }
            fmt_found = 1;
        } else if (memcmp(chunk_id, "data", 4) == 0) {
            data_size = chunk_size;
            data_found = 1;
            break;
        } else {
            fseek(f, chunk_size, SEEK_CUR);
        }
    }

    if (!fmt_found || !data_found) {
        fclose(f);
        return -1;
    }
    if (audio_format != 1 || bits_per_sample != 16 || channels != 1 || sample_rate != 16000) {
        fclose(f);
        return -1;
    }

    int sample_count = data_size / 2;
    short* pcm = (short*)malloc(data_size);
    if (!pcm) {
        fclose(f);
        return -1;
    }
    if (fread(pcm, 1, data_size, f) != data_size) {
        free(pcm);
        fclose(f);
        return -1;
    }
    fclose(f);

    float* samples = (float*)malloc(sizeof(float) * sample_count);
    if (!samples) {
        free(pcm);
        return -1;
    }
    for (int i = 0; i < sample_count; ++i) {
        samples[i] = (float)pcm[i] / 32768.0f;
    }
    free(pcm);

    *out_samples = samples;
    *out_count = sample_count;
    return 0;
}

WhisperBridge* whisper_bridge_init(const char* model_path, int threads) {
    if (!model_path) {
        return NULL;
    }
    struct whisper_context_params cparams = whisper_context_default_params();
    struct whisper_context* ctx = whisper_init_from_file_with_params(model_path, cparams);
    if (!ctx) {
        return NULL;
    }
    WhisperBridge* bridge = (WhisperBridge*)calloc(1, sizeof(WhisperBridge));
    if (!bridge) {
        whisper_free(ctx);
        return NULL;
    }
    bridge->ctx = ctx;
    bridge->threads = threads > 0 ? threads : 4;
    return bridge;
}

void whisper_bridge_free(WhisperBridge* bridge) {
    if (!bridge) {
        return;
    }
    if (bridge->ctx) {
        whisper_free(bridge->ctx);
    }
    free(bridge);
}

char* whisper_bridge_transcribe_wav(WhisperBridge* bridge,
                                    const char* wav_path,
                                    const char* language,
                                    const char* prompt) {
    if (!bridge || !bridge->ctx || !wav_path) {
        return NULL;
    }

    float* samples = NULL;
    int sample_count = 0;
    if (read_wav_mono_16k(wav_path, &samples, &sample_count) != 0) {
        return NULL;
    }

    struct whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    params.print_progress = false;
    params.print_realtime = false;
    params.print_timestamps = false;
    params.print_special = false;
    params.translate = false;
    params.n_threads = bridge->threads;
    params.no_context = false;
    params.single_segment = false;
    if (language && language[0] != '\0') {
        params.language = language;
    }
    if (prompt && prompt[0] != '\0') {
        params.initial_prompt = prompt;
    }

    int result = whisper_full(bridge->ctx, params, samples, sample_count);
    free(samples);
    if (result != 0) {
        return NULL;
    }

    int n_segments = whisper_full_n_segments(bridge->ctx);
    size_t total = 0;
    for (int i = 0; i < n_segments; ++i) {
        const char* text = whisper_full_get_segment_text(bridge->ctx, i);
        if (text) {
            total += strlen(text);
        }
    }

    char* out = (char*)calloc(total + 1, 1);
    if (!out) {
        return NULL;
    }
    for (int i = 0; i < n_segments; ++i) {
        const char* text = whisper_full_get_segment_text(bridge->ctx, i);
        if (text) {
            strcat(out, text);
        }
    }

    return out;
}

void whisper_bridge_free_string(char* str) {
    free(str);
}
