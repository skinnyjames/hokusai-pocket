#ifndef TREE_SITTER_SCANNER_H_
#define TREE_SITTER_SCANNER_H_
#include "parser.h"

extern const TSLanguage *tree_sitter_hml(void);
void *tree_sitter_hml_external_scanner_create(void);
void tree_sitter_hml_external_scanner_destroy(void *);
bool tree_sitter_hml_external_scanner_scan(void *, TSLexer *, const bool *);
unsigned tree_sitter_hml_external_scanner_serialize(void *, char *);
void tree_sitter_hml_external_scanner_deserialize(void *, const char *, unsigned);

#endif
