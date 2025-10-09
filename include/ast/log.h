#ifndef FLASHLIGHT_LOG_H
#define FLASHLIGHT_LOG_H
#include <time.h>
#include <stdio.h>
#include <stdarg.h>

#define ANSI_COLOR_YELLOW  "\x1b[33m"
#define ANSI_COLOR_BLUE    "\x1b[34m"
#define ANSI_COLOR_MAGENTA "\x1b[35m"
#define ANSI_COLOR_CYAN    "\x1b[36m"
#define ANSI_COLOR_RESET   "\x1b[0m"

enum F_LOG_LEVEL
{
  F_LOG_ERROR = 1 << 0,
  F_LOG_WARN = 1 << 1,
  F_LOG_INFO = 1 << 2,
  F_LOG_DEBUG = 1 << 3,
  F_LOG_FINE = 1 << 4
};

typedef struct FLogMessage
{
  char* datetime;
  enum F_LOG_LEVEL level;
  char* message;
} f_log_message;

typedef void (*f_logger_cb)(f_log_message message, volatile void* payload);
static volatile f_logger_cb f_log_cb = NULL;
static volatile enum F_LOG_LEVEL f_log_level = F_LOG_ERROR;
static volatile void* f_log_payload = NULL;

void f_logger_set_level(enum F_LOG_LEVEL level);
void f_logger_set_cb(f_logger_cb cb, volatile void* payload);
f_logger_cb f_logger_get_cb();
enum F_LOG_LEVEL f_logger_get_level();
volatile void* f_logger_get_payload();
void f_log(enum F_LOG_LEVEL level, char* fmt, ...);

#endif
