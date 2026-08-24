#ifndef HP_VOICE
#define HP_VOICE

#include <whisper.h>
#define MA_API static
#define MINIAUDIO_IMPLEMENTATION
#include <external/miniaudio.h>
#include "voice.h"
#include <stdlib.h>
#include <pthread.h>

#define HP_INBOX_SIZE 256
#define HP_MAX_AUDIO_SAMPLES (16000 * 10)

float hp_audio_input_buffer[HP_MAX_AUDIO_SAMPLES];
size_t hp_audio_input_buffer_count = 0;

ma_device audio_capture_device;
struct whisper_context* hp_whisper_ctx = NULL;

pthread_t hp_voice_whisper_thread_id;
pthread_mutex_t hp_voice_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t hp_voice_cond = PTHREAD_COND_INITIALIZER;
static bool hp_voice_thread_running = true;

/*
  Flushes any currently recorded data from the inbox.
*/
char* hp_voice_inbox_data(hp_voice* voice)
{
  if (!voice->inbox_populated) return NULL;

  char* data = malloc(HP_INBOX_SIZE);
  if (!data) return NULL;
  data[0] = '\0';

  pthread_mutex_lock(&hp_voice_mutex);
  strncpy(data, voice->inbox, HP_INBOX_SIZE - 1);
  data[HP_INBOX_SIZE - 1] = '\0';
  voice->inbox[0] = '\0';
  voice->inbox_populated = false;
  pthread_mutex_unlock(&hp_voice_mutex);
  if (strlen(data) > 0)
  {
    return data;
  }
  else
  {
    free(data);
    return NULL;
  }
}

void hp_voice_start_recording(hp_voice* voice)
{
  pthread_mutex_lock(&hp_voice_mutex);
  voice->recording = true;
  pthread_mutex_unlock(&hp_voice_mutex);
}

void hp_voice_toggle_recording(hp_voice* voice)
{
  pthread_mutex_lock(&hp_voice_mutex);
  if (voice->recording)
  {  
    voice->recording = false;
    voice->recording_done = true;
    pthread_cond_signal(&hp_voice_cond);
  }
  else
  {
    hp_audio_input_buffer_count = 0;
    voice->recording = true;
  }
  
  pthread_mutex_unlock(&hp_voice_mutex);
}

void hp_voice_stop_recording(hp_voice* voice)
{
  pthread_mutex_lock(&hp_voice_mutex);
  voice->recording = false;
  voice->recording_done = true;
  hp_audio_input_buffer_count = 0;
  pthread_cond_signal(&hp_voice_cond);
  pthread_mutex_unlock(&hp_voice_mutex);
}

void hp_ma_capture_callback(ma_device* device, void* output, const void* input, ma_uint32 frames)
{
  hp_voice* voice = (hp_voice*)device->pUserData;
  if (input == NULL || frames == 0) return;

  pthread_mutex_lock(&hp_voice_mutex);
  if (!voice->recording)
  {
    pthread_mutex_unlock(&hp_voice_mutex);
    return;
  }
  
  const float* fInput = (const float*)input;
  for (ma_uint32 i = 0; i < frames; ++i) {
    if (hp_audio_input_buffer_count < HP_MAX_AUDIO_SAMPLES) {
      hp_audio_input_buffer[hp_audio_input_buffer_count++] = fInput[i];
    }
  }

  pthread_mutex_unlock(&hp_voice_mutex);
}

void* hp_voice_whisper_thread(void* payload)
{
  hp_voice* voice = (hp_voice*)payload;
  float* local_buffer = malloc(HP_MAX_AUDIO_SAMPLES * sizeof(float));
  
  size_t sample_count = 0;
  while (true)
  {
    pthread_mutex_lock(&hp_voice_mutex);
    while (!voice->recording_done && hp_voice_thread_running)
    {
      pthread_cond_wait(&hp_voice_cond, &hp_voice_mutex);
    }

    if (!hp_voice_thread_running)
    {
      pthread_mutex_unlock(&hp_voice_mutex);
      break;
    }

    sample_count = hp_audio_input_buffer_count;
    memcpy(local_buffer, hp_audio_input_buffer, sample_count * sizeof(float));
    voice->recording_done = false;
    pthread_mutex_unlock(&hp_voice_mutex);

    if (sample_count < 8000) continue;

    struct whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    params.print_progress   = false;
    params.print_timestamps = false;
    params.single_segment   = true;

    if (whisper_full(hp_whisper_ctx, params, local_buffer, sample_count) == 0)
    {
      int segments = whisper_full_n_segments(hp_whisper_ctx);
      if (segments > 0)
      {
        const char* text = whisper_full_get_segment_text(hp_whisper_ctx, 0);
        pthread_mutex_lock(&hp_voice_mutex);
        strncpy(voice->inbox, text, HP_INBOX_SIZE - 1);
        voice->inbox[HP_INBOX_SIZE - 1] = '\0';
        voice->inbox_populated = true;
        pthread_mutex_unlock(&hp_voice_mutex);
      }
    }
  }

  free(local_buffer);
  return NULL;
}


hp_voice* hp_voice_init()
{
  hp_voice* voice = malloc(sizeof(hp_voice));
  voice->recording = false;
  voice->recording_done = false;
  voice->inbox_populated = false;
  voice->inbox = malloc(sizeof(char) * 256);
  if (!voice->inbox)
  {
    free(voice);
    return NULL;
  }

  voice->inbox[0] = '\0';
  hp_voice_thread_running = true;

  // hp_audio_input_buffer ;
  hp_audio_input_buffer_count = 0;

  // init miniaudio
  ma_device_config audioconfig = ma_device_config_init(ma_device_type_capture);
  audioconfig.capture.format   = ma_format_f32;    
  audioconfig.capture.channels = 1;                
  audioconfig.sampleRate       = 16000;            
  audioconfig.dataCallback     = hp_ma_capture_callback;
  audioconfig.pUserData        = voice;
  if (ma_device_init(NULL, &audioconfig, &audio_capture_device) != MA_SUCCESS)
  {
    f_log(F_LOG_ERROR, "Couldn't initialize miniaudio device");
    free(voice->inbox);
    free(voice);
    return NULL;
  }
  ma_device_start(&audio_capture_device);

  // init whisper try gpu first.
  const char* model_path = "./assets/models/ggml-tiny.bin";
  struct whisper_context_params params = whisper_context_default_params();
  params.use_gpu = true;

  hp_whisper_ctx = whisper_init_from_file_with_params(model_path, params);
  if (hp_whisper_ctx == NULL) {
    params.use_gpu = false;
    hp_whisper_ctx = whisper_init_from_file_with_params(model_path, params);

    if (hp_whisper_ctx == NULL)
    {
      printf("ERROR: Failed to load Whisper model at %s\n", model_path);
      ma_device_uninit(&audio_capture_device);
      free(voice->inbox);
      free(voice);
      return NULL;
    }
  }
  
  pthread_create(&hp_voice_whisper_thread_id, NULL, hp_voice_whisper_thread, voice);

  return voice;
}

void hp_voice_free(hp_voice* voice)
{
  if (!voice) return;
  pthread_mutex_lock(&hp_voice_mutex);
  hp_voice_thread_running = false;
  pthread_cond_signal(&hp_voice_cond);
  pthread_mutex_unlock(&hp_voice_mutex);

  ma_device_uninit(&audio_capture_device);
  whisper_free(hp_whisper_ctx);
  pthread_mutex_destroy(&hp_voice_mutex);
  pthread_cond_destroy(&hp_voice_cond);
  free(voice->inbox);
  free(voice);
}



#endif