#ifndef HP_SPEECH
#define HP_SPEECH
#include "speech.h"
#include <flite.h>
#include <stdlib.h>
#include <stdio.h>

cst_voice *register_cmu_us_slt(const char *voxdir);
pthread_t hp_speech_thread_id;
pthread_cond_t hp_speech_cond = PTHREAD_COND_INITIALIZER;
static bool hp_speech_thread_running = true;
static cst_voice* flite_voice = NULL;
pthread_mutex_t hp_speech_mutex = PTHREAD_MUTEX_INITIALIZER;
#define PCM2FLOAT 32768.0f

void* hp_speech_thread(void* payload)
{
  hp_speech* speech = (hp_speech*)payload;
  while (true)
  {
    pthread_mutex_lock(&hp_speech_mutex);
    while (!speech->outbox_populated && hp_speech_thread_running)
    {
      pthread_cond_wait(&hp_speech_cond, &hp_speech_mutex);
    }

    if (!hp_speech_thread_running)
    {
      pthread_mutex_unlock(&hp_speech_mutex);
      break;
    }

    speech->outbox_populated = false;
    cst_wave *wave = flite_text_to_wave(speech->outbox, flite_voice);
    if (speech->samples != NULL)
    {
      free(speech->samples);
    }
    
    speech->samples = malloc(sizeof(float) * wave->num_samples);
    for (int i=0; i<wave->num_samples;i++)
    {
      speech->samples[i] = wave->samples[i] / PCM2FLOAT;
    }

    speech->sample_count = wave->num_samples;
    speech->sample_rate = wave->sample_rate;
    speech->speaking = true;
    
    delete_wave(wave);
    free(speech->outbox);
    speech->outbox = NULL;

    pthread_mutex_unlock(&hp_speech_mutex);
  }

  return NULL;
}

void hp_speech_start(hp_speech* speech, char* words)
{
  pthread_mutex_lock(&hp_speech_mutex);
  if (speech->speaking)
  {
    pthread_mutex_unlock(&hp_speech_mutex);
    return;
  }

  char *outbox = malloc(strlen(words) + 1);
  memcpy(outbox, words, strlen(words));

  outbox[strlen(words)] = '\0';
  speech->outbox = outbox;
  speech->outbox_populated = true;
  pthread_cond_signal(&hp_speech_cond);
  pthread_mutex_unlock(&hp_speech_mutex);
}

void hp_speech_done(hp_speech* speech)
{
  pthread_mutex_lock(&hp_speech_mutex);
  speech->speaking = false;
  free(speech->samples);
  speech->samples = NULL;
  speech->sample_count = 0;
  speech->sample_rate = 0;
  pthread_mutex_unlock(&hp_speech_mutex);
}

bool hp_speech_speaking(hp_speech* speech)
{
  bool speaking = false;
  pthread_mutex_lock(&hp_speech_mutex);
  speaking = speech->speaking;
  pthread_mutex_unlock(&hp_speech_mutex);
  return speaking;
}

hp_speech* hp_speech_init()
{ 
  flite_init();
  flite_voice = register_cmu_us_slt(NULL);
  if (!flite_voice) return NULL;

  hp_speech* speech = malloc(sizeof(hp_speech));
  speech->samples = NULL;
  speech->sample_count = 0;
  speech->sample_rate = 0;
  speech->outbox = NULL;
  speech->outbox_populated = false;
  speech->speaking = false;
  speech->speaking_ready = false;
  speech->speaking_done = true;

  pthread_create(&hp_speech_thread_id, NULL, hp_speech_thread, speech);

  return speech;
}

void hp_speech_free(hp_speech* speech)
{
  if (!speech) return;
  pthread_mutex_lock(&hp_speech_mutex);
  hp_speech_thread_running = false;
  pthread_cond_signal(&hp_speech_cond);
  pthread_mutex_unlock(&hp_speech_mutex);

  pthread_mutex_destroy(&hp_speech_mutex);
  pthread_cond_destroy(&hp_speech_cond);
  if (speech->samples) free(speech->samples);
  free(speech);
}

#endif