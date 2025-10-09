#ifndef HOKUSAI_CORE_AST_H
#define HOKUSAI_CORE_AST_H

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <tree_sitter/api.h>
#include "hashmap.h"
#include "style.h"

extern TSLanguage* tree_sitter_hml();

/** @struct HmlFuncCall
* @brief represents a function call, used in events or props
* @var function
* the name of the function to call
* @var args_len
* the number of args to pass to the function
* @var args
* an opaque array of pointers to arguments.
*/
typedef struct HmlAstFuncCall
{
  char* function;
  int args_len;
  void** args;
  char** strargs;
} hoku_ast_func_call;

/** @struct HmlProp
* @brief a prop on the component ex (:size="get_size")
* @var name
* the name of the prop
* @var call
* the function call for this prop
*/
typedef struct HmlAstProp
{
  char* name;
  bool computed;
  hoku_ast_func_call* call;
} hoku_ast_prop;

/** @struct HmlEvent
* @brief an event triggered by input ex (@click="submit")
* @var name
* the name of the event
* @var call
* the function to handle this event
*/
typedef struct HmlAstEvent
{
  char* name;
  hoku_ast_func_call* call;
} hoku_ast_event;

/** @struct HmlCondition
* @brief an condition on which to render the component
* @var not
* inverses the function result
* @var call
* a call which should return a boolean for the render
*/
typedef struct HmlAstCondition
{
  bool not;
  hoku_ast_func_call* call;
} hoku_ast_condition;

/** @struct HmlLoop
 * @brief render the child in a loop
 * @var name
 * the property to pass down
 * @var list_name
 * the method to return an iterable
*/
typedef struct HmlAstLoop
{
  char* name;
  char* list_name;
} hoku_ast_loop;

/** @struct HmlList
* @brief a linked list for siblings and children of a component.
* @var component
* the comonent with siblings or children
* @var next_sibling
* the next sibling of <component>
* @var next_child
* the next child of <component>
*/
typedef struct HmlAstList
{
  struct HmlAst* next_sibling;
  struct HmlAst* next_child;
} hoku_ast_list;

typedef struct HmlAstClassList
{
  char* name;
  struct HmlAstClassList* next;
} hoku_ast_class_list;

/** @struct HmlAst
* @brief a component tree
* @var type
* the type name of the component
* @var has_slot
* boolean representing if the component has open slots
* @var cond
* a HmlCondition that decides if the component should be rendered
* @var props
* a hashmap of properties
* @var events
* a hashmap of events
* @var parent
* the parent of this component
* @var next_sibling
* the next sibling of this component
* @var next_child
* the next child of this component
*/
typedef struct HmlAst
{
  char* type;
  char* id;
  char* error;
  bool has_slot;
  int child_len;
  struct HmlStyle* styles;
  struct HmlAstClassList* style_list;
  struct HmlAstClassList* class_list;
  struct HmlAstCondition* cond;
  struct HmlAstLoop* loop;
  struct hashmap* props;
  struct hashmap* events;
  struct HmlAst* parent;
  struct HmlAstList* relations;
  struct HmlAstList* else_relations;
  bool else_active;
  bool is_root;
} hoku_ast;

/**
  Marks this ast as errored
  @param ast the ast to error
  @param error the description of the error
  @return 0 for success, -1 for error
*/
int hoku_ast_set_error(hoku_ast* ast, char* error, TSNode node, char* template);

/**
  Returns the first errored ast if one exists
  @param ast the ast to search
  @return NULL for no errored asts, the errored ast otherwise
*/
hoku_ast* hoku_errored_ast(hoku_ast* ast);

/**
  Prepends an style name to the ast's style list
  @param ast the ast to prepend to
  @param name the style name to prepend
  @return 0 for success, -1 for error
*/
int hoku_ast_style_list_prepend(hoku_ast* ast, char* name);

/**
  Prepends an class name to the ast's class list
  @param ast the ast to prepend to
  @param name the class name to prepend
  @return 0 for success, -1 for error
*/
int hoku_ast_class_list_prepend(hoku_ast* ast, char* name);

/**
  Does the ast include this class name?
  @param ast the ast to check
  @param name the class name to check for
  @return false if ast does not include the class name, true otherwise
*/
bool hoku_ast_class_list_includes(hoku_ast* ast, char* name);

/**
  Append a sibling to the ast node
  @param first the source node
  @param second the sibling to the append
  @return 0 for success, -1 for error
*/
int hoku_ast_append_sibling(hoku_ast** first, hoku_ast* second);

/**
  Append a child to the ast node
  @param parent the source node
  @param child the child to append
  @return 0 for success, -1 for error
*/
int hoku_ast_append_child(hoku_ast** parent, hoku_ast* child);

/**
  Prepend sibling to the ast node
  @param first the source node
  @param second the sibling to prepend
  @return 0 for success, -1 for error
*/
int hoku_ast_prepend_sibling(hoku_ast** first, hoku_ast* second);

/**
  Prepend child to the ast node
  @param parent the source node
  @param child the child to prepend
  @return 0 for success, -1 for error
*/
int hoku_ast_prepend_child(hoku_ast** parent, hoku_ast* child);

/**
  Counts the number of props on this ast
  @param component the ast to check
  @return the number of props
*/
int hoku_ast_props_count(hoku_ast* component);

/**
  Adds a prop to this ast node
  @param component the target ast
  @param prop the prop to add
  @return 0 for success, -1 for error
*/
int hoku_ast_add_prop(hoku_ast* component, hoku_ast_prop* prop);

/**
  Fetches a prop from this ast node

  @param component the target ast
  @param prop the prop to fetch
  @return a pointer to the prop or NULL

  Example usage

  hoku_ast_prop* prop = hoku_ast_get_prop(ast_node, &(hoku_ast_prop){.name="prop"});
*/
hoku_ast_prop* hoku_ast_get_prop(hoku_ast* component, hoku_ast_prop* prop);
int hoku_ast_cond_init(hoku_ast_condition** cond, hoku_ast_func_call* call);
int hoku_ast_loop_init(hoku_ast_loop** loop, char* name, char* list_name);
int hoku_ast_events_count(hoku_ast* component);
int hoku_ast_add_event(hoku_ast* component, hoku_ast_event* event);
hoku_ast_event* hoku_ast_get_event(hoku_ast* component, hoku_ast_event* event);

int hoku_ast_init(hoku_ast** component, char* type);
void hoku_ast_free(hoku_ast* component);

int hoku_ast_func_call_init(hoku_ast_func_call** call, char* name);
void hoku_ast_func_call_free(hoku_ast_func_call* init);

int hoku_ast_event_init(hoku_ast_event** event, char* name);
void hoku_ast_event_free(void* event);

int hoku_ast_prop_init(hoku_ast_prop** prop, char* name);
void hoku_ast_prop_free(void* prop);

#endif
