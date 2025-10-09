#ifndef HOKU_CORE_STYLE
#define HOKU_CORE_STYLE

#include <ast/style.h>

int hoku_style_attribute_init(hoku_style_attribute** attribute, char* name, char* value, enum HOKU_STYLE_TYPE type)
{
  hoku_style_attribute* init = malloc(sizeof(hoku_style_attribute));
  if (init == NULL) return -1;

  init->name = strdup(name);
  if (init->name == NULL) return -1;

  init->value = strdup(value);
  if (init->value == NULL) return -1;

  init->type = type;
  init->function_name = NULL;
  init->next = NULL;

  *attribute = init;

  return 0;
}

int hoku_style_init(hoku_style** style, char* name)
{
  hoku_style* init = malloc(sizeof(hoku_style));
  if (init == NULL) return -1;

  init->name = strdup(name);
  if (init->name == NULL) return -1;

  init->event_name = NULL;
  init->attributes = NULL;
  init->next = NULL;

  *style = init;

  return 0;
}


void hoku_style_append(hoku_style* style, hoku_style* next)
{
  hoku_style* head = style;

  while (head->next)
  {
    head = head->next;
  }

  head->next = next;
}

void hoku_style_attribute_append(hoku_style_attribute* attribute, hoku_style_attribute* next)
{
  hoku_style_attribute* head = attribute;

  while (head->next)
  {
    head = head->next;
  }

  head->next = next;
  head->next->next = NULL;
}

void hoku_style_attribute_free(hoku_style_attribute* attribute)
{
  hoku_style_attribute* head = attribute;
  hoku_style_attribute* current = NULL;

  while (head)
  {
    current = head;
    head = head->next;

    free(current->name);
    free(current->value);
    if (current->function_name) free(current->function_name);
    free(current);
  }
}

void hoku_style_free(hoku_style* style)
{
  hoku_style* head = style;
  hoku_style* current = NULL;

  while (head)
  {
    current = head;
    head = head->next;

    free(current->name);
    if (current->event_name) free(current->event_name);
    hoku_style_attribute_free(current->attributes);
    free(current);
  }
}

#endif