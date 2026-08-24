#ifndef HP_VOICE_H
#define HP_VOICE_H

#include <stdbool.h>
#include <string.h>
#include "../core-log.h"

typedef struct HPVoice {
  bool recording;
  bool recording_done;
  bool inbox_populated;
  char* inbox;
} hp_voice;


hp_voice* hp_voice_init();
char* hp_voice_inbox_data(hp_voice* voice);
void hp_voice_start_recording(hp_voice* voice);
void hp_voice_stop_recording(hp_voice* voice);
void hp_voice_free(hp_voice* voice);
void hp_voice_toggle_recording(hp_voice* voice);

#endif