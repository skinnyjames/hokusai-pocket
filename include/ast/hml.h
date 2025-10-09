#ifndef HOKU_CORE_HML_H
#define HOKU_CORE_HML_H

#include "style.h"
#include "ast.h"
#include "log.h"

int hoku_style_from_template(hoku_style** out, char* template);
int hoku_ast_from_template(hoku_ast** out, char* type, char* template);
void hoku_dump(hoku_ast* c, int level);

#endif
