#ifndef HOKU_CORE_STYLE_H
#define HOKU_CORE_STYLE_H

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

enum HOKU_STYLE_TYPE
{
  HOKU_STYLE_TYPE_INT,
  HOKU_STYLE_TYPE_FLOAT,
  HOKU_STYLE_TYPE_BOOL,
  HOKU_STYLE_TYPE_STRING,
  HOKU_STYLE_TYPE_FUNC
};

typedef struct HmlStyleAttribute
{
  char* name;
  char* function_name;
  char* value;
  enum HOKU_STYLE_TYPE type;
  struct HmlStyleAttribute* next;

} hoku_style_attribute;

typedef struct HmlStyle
{
  char* name;
  char* event_name;
  struct HmlStyleAttribute* attributes;
  struct HmlStyle* next;
} hoku_style;

int hoku_style_init(hoku_style** style, char* name);
int hoku_style_attribute_init(hoku_style_attribute** attribute, char* name, char* value, enum HOKU_STYLE_TYPE type);
void hoku_style_append(hoku_style* style, hoku_style* next);
void hoku_style_attribute_append(hoku_style_attribute* attribute, hoku_style_attribute* next);
void hoku_style_attribute_free(hoku_style_attribute* attribute);
void hoku_style_free(hoku_style* style);

#endif