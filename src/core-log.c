#ifndef FLASHLIGHT_LOG
#define FLASHLIGHT_LOG

#include "core-log.h"

void f_default_on_log_message(f_log_message msg)
{
  if (msg.level & f_logger_get_level())
  {
    switch(msg.level)
    {
      case F_LOG_FINE: {
        fprintf(stderr, ANSI_COLOR_YELLOW " [%s] " ANSI_COLOR_RESET "%s\n", msg.datetime, msg.message);
        break;
      }
      case F_LOG_DEBUG: {
        fprintf(stderr, ANSI_COLOR_CYAN " [%s] " ANSI_COLOR_RESET "%s\n", msg.datetime, msg.message);
        break;
      }
      case F_LOG_INFO: {
        fprintf(stderr, ANSI_COLOR_BLUE " [%s] " ANSI_COLOR_RESET "%s\n", msg.datetime, msg.message);
        break;
      }
      case F_LOG_WARN: {
        fprintf(stderr, ANSI_COLOR_YELLOW " [%s] " ANSI_COLOR_RESET "%s\n", msg.datetime, msg.message);
        break;
      }
      case F_LOG_ERROR: {
        fprintf(stderr, ANSI_COLOR_MAGENTA " [%s] " ANSI_COLOR_RESET "%s\n", msg.datetime, msg.message);
        break;
      }
    }
  }
}

void f_logger_set_level(enum F_LOG_LEVEL level)
{
  f_log_level = level;
}

void f_logger_set_cb(f_logger_cb cb, volatile void* payload)
{
  f_log_cb = cb;
  f_log_payload = payload;
}

f_logger_cb f_logger_get_cb()
{
  return f_log_cb;
}

volatile void* f_logger_get_payload()
{
  return f_log_payload;
}

enum F_LOG_LEVEL f_logger_get_level()
{
  return f_log_level;
}

void f_log(enum F_LOG_LEVEL level, char* fmt, ...)
{
  time_t t = time(NULL);
  struct tm* tm = localtime(&t);
  char datetime[64];
  strftime(datetime, sizeof(datetime), "%c", tm);
  char message[500];
  volatile void* payload = f_logger_get_payload();

  va_list args;
  va_start(args, fmt);
  vsprintf(message, fmt, args);
  va_end(args);

  f_log_message msg = {datetime, level, message};

  if (f_log_cb == NULL)
  {
    f_default_on_log_message(msg);
  }
  else
  {
    f_log_cb(msg, payload);
  }
}

#endif
