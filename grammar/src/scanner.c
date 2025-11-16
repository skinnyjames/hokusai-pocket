#include <stdio.h>
#include <stdlib.h>
#include "tree_sitter/parser.h"
#include <unistd.h>
#include <string.h>
enum TokenType
{
  INDENT,
  DEDENT,
  NEWLINE,
  ERROR_SENTINEL,
};

struct HmlScanList
{
  long int col;
  struct HmlScanList* next;
};

struct HmlScanner
{
  struct HmlScanList* list;
};

/**
  prepends an item to the stack
*/
static void scanner_push(struct HmlScanList** scanner, long int col)
{
  struct HmlScanList* first = malloc(sizeof(struct HmlScanList));
  first->col = col;
  first->next = *scanner;
  *scanner = first;
}

/**
  removes a item from the stack
*/
static bool scanner_pop(struct HmlScanList** scanner)
{
  if ((*scanner)->next == NULL)
  {
    return false;
  }
  else
  {
    struct HmlScanList* head = *scanner;
    struct HmlScanList* next = head->next;
    free(head);
    *scanner = next;
    return true;
    
  }
}

/**
  serialize the stack
  8 -> 6 -> 4 -> 2 -> 0

  "0:2:4:6:8"
*/
static void scanner_serialize(struct HmlScanList** scanner, char* buffer)
{
  // int i = 0; 
  struct HmlScanList* head = *scanner;
  sprintf(buffer, "%ld", head->col);
  head = head->next;
  while (head != NULL && head->col != 0)
  {
    char tmp[200];
    sprintf(tmp, "%ld:%s", head->col, buffer);
    strcpy(buffer, tmp);
    head = head->next;
  }
  // printf("buffer is %s (%d) it(%d)\n", buffer, strlen(buffer), i);
}

/**
  deserialize the stack
*/
static void scanner_deserialize(struct HmlScanner* scanner, const char* buffer, unsigned len)
{
  // printf("stack serial: %s, len: %u\n", buffer,len);
  if (len <= 0)
  {
    return;
  }
  while (scanner_pop(&scanner->list));

  char* scan_ep;
  char scan_buffer[32];
  // bool scanned_indent = false;
  int track = 0;
  int done = 0;

  for (int i = 0; i < len; i++)
  {
    char letter = buffer[i];
    if (buffer[i] == ':')
    {
      // parse indents and clear buffer
      scan_buffer[i] = '\0';
      long int col = strtol(scan_buffer, &scan_ep, 0);
      scanner_push(&scanner->list, col);

      for (int ii=0;ii<i;ii++)
      {
        scan_buffer[ii] = '\0';
      }

      track = i;
    }
    else
    {
      scan_buffer[done] = letter;
    }
    done = i - track;
  }

  scan_buffer[done + 1] = '\0';
  long int col = strtol(scan_buffer, &scan_ep, 0);
  scanner_push(&scanner->list, col);
}

void* tree_sitter_hml_external_scanner_create()
{
  // printf("create scanner\n");
  struct HmlScanner* scanner = malloc(sizeof(struct HmlScanner));
  scanner->list = malloc(sizeof(struct HmlScanList));
  scanner->list->col = 0;
  scanner->list->next = NULL;
  return scanner;
}

void tree_sitter_hml_external_scanner_destroy(void* payload)
{
  // printf("destroy scanner\n");
  struct HmlScanner* scanner = (struct HmlScanner*) payload;
  while(scanner_pop(&scanner->list));
  free(scanner->list);
  free(scanner);
}

unsigned tree_sitter_hml_external_scanner_serialize(void* payload, char* buffer)
{
  struct HmlScanner* scanner = (struct HmlScanner*) payload;
  // printf("serizliae %ld\n", scanner->list->col);
  scanner_serialize(&scanner->list, buffer);
  return (unsigned) strlen(buffer);
}

void tree_sitter_hml_external_scanner_deserialize(void* payload, const char* buffer, unsigned len)
{
  struct HmlScanner* scanner = (struct HmlScanner*) payload;
  scanner_deserialize(scanner, buffer, len);
  // printf("deserialized, %ld\n", scanner->list->col);
}

bool tree_sitter_hml_external_scanner_scan(void* payload, TSLexer* lexer, const bool* valid_symbols)
{
  struct HmlScanner* scanner = (struct HmlScanner*) payload;

  if (valid_symbols[ERROR_SENTINEL]) {
    return false;
  }

  uint32_t current_column;

  if (lexer->eof(lexer) || (lexer->lookahead == '[' && lexer->get_column(lexer) == 0))
  {
    // printf("COLUMN: %ld\n", scanner->list->col);
    if (scanner->list->col != 0)
    {
      scanner_pop(&scanner->list);
      lexer->result_symbol = DEDENT;
      return true;
    }
  }

  // find column position of next non whitespace char.
  if (valid_symbols[INDENT] || valid_symbols[NEWLINE] || valid_symbols[DEDENT])
  {    
    // {

    //   return false;
    // }

    while (true)
    {
      if (lexer->lookahead != ' ' && lexer->lookahead != '\f' && lexer->lookahead != '\n' && lexer->lookahead != '\t' && lexer->lookahead != '\0')
      {
        if (lexer->lookahead == '#' || lexer->lookahead == '{' || lexer->lookahead == '.') return false;
        
        current_column = (long int) lexer->get_column(lexer) + 1;
        // long int a = -1;
        // if (scanner->list->next) a = scanner->list->next->col;
        // printf("'%c' CURRENT %ld | SCANNED %ld | NEXT %ld\n", lexer->lookahead, current_column, scanner->list->col, a);

        if (current_column == scanner->list->col)
        {
          lexer->result_symbol = NEWLINE;
          return true;
        }
        else if (valid_symbols[INDENT] && current_column > scanner->list->col)
        {
          scanner_push(&scanner->list, current_column);
          lexer->result_symbol = INDENT;
          return true;
        }
        else if (scanner->list->next && scanner->list->next->col >= current_column)
        {
          // printf("Scanner pop\n");
          scanner_pop(&scanner->list);
          lexer->result_symbol = DEDENT;
          return true;
        }
        else if (scanner->list->next && current_column < scanner->list->next->col)
        {
          // unreachable
          // printf("POPPING '%c' CURRENT %ld | SCANNED %ld | NEXT %ld\n", lexer->lookahead, current_column, scanner->list->col, a);

          while (scanner_pop(&scanner->list))
          {
            if (current_column > scanner->list->next->col)
            {
              return false;
            }

            if (current_column == scanner->list->next->col)
            {
              break;
            }
          }
          lexer->result_symbol = DEDENT;
          return true;
        }
        else
        {
          // printf("ERROR '%c' CURRENT %ld | SCANNED %ld | NEXT %ld\n", lexer->lookahead, current_column, scanner->list->col, a);
          return false;
        }
      }
      else if (lexer->lookahead == '\0')
      {
        if (scanner->list->col != 0)
        {
          return false;
        }
        return true;
      }
      else {
        lexer->advance(lexer, false);
      }
    }
  }

  return false;
}
