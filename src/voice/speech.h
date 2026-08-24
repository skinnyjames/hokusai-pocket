#ifndef HP_SPEECH_H
#define HP_SPEECH_H

#include <stdbool.h>
#include <string.h>
#include <pthread.h>

extern pthread_mutex_t hp_speech_mutex;

typedef struct HPSpeech {
  bool speaking;
  bool speaking_ready;
  bool speaking_done;
  float* samples;
  int sample_count;
  int sample_rate;
  bool outbox_populated;
  char* outbox;
} hp_speech;

typedef struct HPSpeechConfig {
  char* model_path;
  char* lexicon_path;
  char* tokens_path;
  char* espeak_data_dir;
  int threads;
} hp_speech_config;

hp_speech* hp_speech_init();
void hp_speech_done(hp_speech* speech);
void hp_speech_start(hp_speech* speech, char* words);
bool hp_speech_speaking(hp_speech* speech);
void hp_speech_free(hp_speech* speech);

#endif