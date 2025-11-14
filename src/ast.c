#ifndef HOKUSAI_POCKET_AST
#define HOKUSAI_POCKET_AST

#include "ast.h"
#include "error.h"
#include "./ast/loop.c"
#include "./ast/func.c"
#include "./ast/event.c"
#include "./ast/prop.c"

typedef struct HokuAstWrapper
{
  hoku_ast* ast;
  bool dirty;
  bool else_active;
} hoku_ast_wrapper;

static void hoku_ast_type_free(mrb_state* mrb, void* payload)
{
  hoku_ast_wrapper* wrapper = (hoku_ast_wrapper*)payload;
  if (wrapper->ast->is_root) 
  {
    f_log(F_LOG_FINE, "freeing root [id: %s] %p %s",  wrapper->ast->id, wrapper->ast, wrapper->ast->type);
    hoku_ast_free(wrapper->ast);
  
    f_log(F_LOG_FINE, "Done freeing root");
  }

  free(wrapper);
  f_log(F_LOG_DEBUG, "Done MRB free");
}

static struct mrb_data_type hoku_ast_type = { "Ast", hoku_ast_type_free };

hoku_ast* hp_create_ast(mrb_state* mrb, char* type, char* template)
{
  hoku_ast* ast;
  if (hoku_ast_from_template(&ast, type, template) != 0)
  {
    struct RClass* hokusai_class = mrb_class_get(mrb, "Hokusai");
    struct RClass* exp = mrb_class_get_under(mrb, hokusai_class, "Error");
    mrb_value templtype = mrb_str_new_cstr(mrb, type);
    mrb_raisef(mrb, exp, "Failed to parse template for %S", templtype);
  }

  f_log(F_LOG_DEBUG, "Checking errored ast");
  hoku_ast* errored = hoku_errored_ast(ast);
  if (errored)
  {
    f_log(F_LOG_ERROR, "AST HAS ERR\n");
    struct RClass* hokusai_class = mrb_module_get(mrb, "Hokusai");
    struct RClass* exp = mrb_class_get_under(mrb, hokusai_class, "Error");
    mrb_value errstr = mrb_str_new_cstr(mrb, errored->error);
    mrb_raisef(mrb, exp, "Failed to parse template for %S", errstr);
  }

  return ast;
}

mrb_value hp_ast_parse(mrb_state* mrb, mrb_value self)
{
  mrb_value templ;
  mrb_value templtype;

  mrb_get_args(mrb, "SS", &templ, &templtype);

  char* template = mrb_str_to_cstr(mrb, templ);
  char* type = mrb_str_to_cstr(mrb, templtype);
  
  hoku_ast* ast = hp_create_ast(mrb, type, template);

  mrb_value obj = mrb_funcall(mrb, self, "new", 0, NULL);
  hoku_ast_wrapper* wrapper = malloc(sizeof(hoku_ast_wrapper));
  *wrapper = (hoku_ast_wrapper){ast, false, false};
  mrb_data_init(obj, wrapper, &hoku_ast_type);

  return obj;
}

hoku_ast_wrapper* hp_ast_get(mrb_state* mrb, mrb_value self)
{
  hoku_ast_wrapper* wrapper;
  wrapper = DATA_GET_PTR(mrb, self, &hoku_ast_type, hoku_ast_wrapper);

  if (!wrapper) {
    mrb_raise(mrb, E_ARGUMENT_ERROR , "uninitialized ast data") ;
  }
  
  return wrapper;
}

mrb_value hp_ast_get_type(mrb_state* mrb, mrb_value self)
{
  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  if (wrapper->ast->type == NULL) return mrb_str_new_lit(mrb, "(null)");
  return mrb_str_new(mrb, (wrapper->ast->type), strlen(wrapper->ast->type));
}

mrb_value hp_ast_id(mrb_state* mrb, mrb_value self)
{
  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  if (wrapper->ast->id == NULL) return mrb_str_new_lit(mrb, "(null)");
  return mrb_str_new(mrb, (wrapper->ast->id), strlen(wrapper->ast->id));
}

mrb_value hp_ast_dump(mrb_state* mrb, mrb_value self)
{
  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  hoku_dump(wrapper->ast, 0);
  return mrb_nil_value();
}

mrb_value hp_ast_is_slot(mrb_state* mrb, mrb_value self)
{
  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  return mrb_bool_value(strcmp(wrapper->ast->type, "slot") == 0);
}

mrb_value hp_ast_is_virtual(mrb_state* mrb, mrb_value self)
{
  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  return mrb_bool_value(strcmp(wrapper->ast->type, "virtual") == 0);
}

mrb_value hp_ast_is_loop(mrb_state* mrb, mrb_value self)
{
  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  return mrb_bool_value(wrapper->ast->loop != NULL);
}

mrb_value hp_ast_has_if_condition(mrb_state* mrb, mrb_value self)
{
  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  return mrb_bool_value(wrapper->ast->cond != NULL);
}

mrb_value hp_ast_has_else_condition(mrb_state* mrb, mrb_value self)
{
  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  return mrb_bool_value(wrapper->ast->else_relations != NULL);
}

mrb_value hp_ast_is_else_active(mrb_state* mrb, mrb_value self)
{
  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  return mrb_bool_value((wrapper->ast->else_relations != NULL) && wrapper->else_active == true);
}

mrb_value hp_ast_set_else_active(mrb_state* mrb, mrb_value self)
{
  mrb_bool active;
  mrb_get_args(mrb, "b", &active);
  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  wrapper->else_active = active;
  return mrb_nil_value();
}

/* TODO cache in ivar */
mrb_value hp_ast_else_ast(mrb_state* mrb, mrb_value self)
{
  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  if (wrapper->ast->else_relations == NULL) return mrb_nil_value();

  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* astklass = mrb_class_get_under(mrb, module, "Ast");
  
  mrb_value obj = mrb_funcall(mrb, mrb_obj_value(astklass), "new", 0, NULL);
  hoku_ast_wrapper* iwrapper = malloc(sizeof(hoku_ast_wrapper));
  *iwrapper = (hoku_ast_wrapper){wrapper->ast->else_relations->next_child, false, false};
  mrb_data_init(obj, iwrapper, &hoku_ast_type);

  return obj;
}

mrb_value hp_ast_siblings(mrb_state* mrb, mrb_value self)
{
  mrb_value esiblings = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@siblings"));
  if (!mrb_nil_p(esiblings)) return esiblings;

  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  mrb_value siblings = mrb_ary_new(mrb);
  hoku_ast* head = wrapper->ast->relations->next_sibling;

  while (head != NULL)
  {
    struct RClass* module = mrb_module_get(mrb, "Hokusai");
    struct RClass* astklass = mrb_class_get_under(mrb, module, "Ast");
    mrb_value astobjklass = mrb_obj_value(astklass);
    mrb_value obj = mrb_funcall(mrb, astobjklass, "new", 0, NULL);

    hoku_ast_wrapper* iwrapper = malloc(sizeof(hoku_ast_wrapper));
    *iwrapper = (hoku_ast_wrapper){head, false, false};
    mrb_data_init(obj, iwrapper, &hoku_ast_type);
    mrb_ary_push(mrb, siblings, obj);

    head = head->relations->next_sibling;
  }

  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@siblings"), siblings);
  return siblings;
}

mrb_value hp_ast_else_children(mrb_state* mrb, mrb_value self)
{
  mrb_value echildren = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@else_children"));
  if (!mrb_nil_p(echildren)) return echildren;

  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  mrb_value children = mrb_ary_new(mrb);
  hoku_ast* head = wrapper->ast->else_relations->next_child;

  while (head != NULL)
  {
    struct RClass* module = mrb_module_get(mrb, "Hokusai");
    struct RClass* astklass = mrb_class_get_under(mrb, module, "Ast");
    mrb_value astobjklass = mrb_obj_value(astklass);
    mrb_value obj = mrb_funcall(mrb, astobjklass, "new", 0, NULL);

    hoku_ast_wrapper* iwrapper = malloc(sizeof(hoku_ast_wrapper));
    *iwrapper = (hoku_ast_wrapper){head, false, false};
    mrb_data_init(obj, iwrapper, &hoku_ast_type);
    mrb_ary_push(mrb, children, obj);

    head = head->relations->next_sibling;
  }

  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@else_children"), children);
  return children;
}

mrb_value hp_ast_children(mrb_state* mrb, mrb_value self)
{
  mrb_value echildren = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@children"));
  if (!mrb_nil_p(echildren)) return echildren;

  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  mrb_value children = mrb_ary_new(mrb);
  hoku_ast* head = wrapper->ast->relations->next_child;

  while (head != NULL)
  {
    struct RClass* module = mrb_module_get(mrb, "Hokusai");
    struct RClass* astklass = mrb_class_get_under(mrb, module, "Ast");
    mrb_value astobjklass = mrb_obj_value(astklass);
    mrb_value obj = mrb_funcall(mrb, astobjklass, "new", 0, NULL);

    hoku_ast_wrapper* iwrapper = malloc(sizeof(hoku_ast_wrapper));
    *iwrapper = (hoku_ast_wrapper){head, false, false};
    mrb_data_init(obj, iwrapper, &hoku_ast_type);
    mrb_ary_push(mrb, children, obj);

    head = head->relations->next_sibling;
  }

  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@children"), children);
  return children;
}

mrb_value hp_ast_get_classes(mrb_state* mrb, mrb_value self)
{
  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  mrb_value class_array = mrb_ary_new(mrb);
  hoku_ast_class_list* list = wrapper->ast->class_list;
  while (list != NULL)
  {
    mrb_ary_unshift(mrb, class_array, mrb_str_new_cstr(mrb, list->name));
    list = list->next;
  }

  return class_array;
}

mrb_value hp_ast_if(mrb_state* mrb, mrb_value self)
{  
  if (mrb_iv_defined(mrb, self, mrb_intern_lit(mrb, "@if"))) return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@if"));;
  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* ast_klass = mrb_class_get_under(mrb, module, "Ast");
  struct RClass* func_klass = mrb_class_get_under(mrb, ast_klass, "Func");

  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  if (wrapper->ast->cond != NULL)
  {
    mrb_value func_method = mrb_str_new_cstr(mrb, wrapper->ast->cond->call->function);
    mrb_value func_args = mrb_ary_new(mrb);

    for (int i=0; i<wrapper->ast->cond->call->args_len; i++)
    {
      mrb_ary_push(mrb, func_args, mrb_str_new_cstr(mrb, wrapper->ast->cond->call->strargs[i]));
    }

    mrb_value fargs [2] = {func_method, func_args};
    mrb_value iffunc = mrb_obj_new(mrb, func_klass, 2, fargs);
    mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@if"), iffunc);
    return iffunc;
  }
  else
  {
    mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@if"), mrb_nil_value());
    return mrb_nil_value();
  }
}

mrb_value hp_ast_props(mrb_state* mrb, mrb_value self)
{
  mrb_value eprops = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@props"));
  if (!mrb_nil_p(eprops)) return eprops;

  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* ast_klass = mrb_class_get_under(mrb, module, "Ast");
  struct RClass* func_klass = mrb_class_get_under(mrb, ast_klass, "Func");
  struct RClass* prop_klass = mrb_class_get_under(mrb, ast_klass, "Prop");

  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  mrb_value hash = mrb_hash_new(mrb);
  size_t iter = 0;
  void* item;
  while (hashmap_iter(wrapper->ast->props, &iter, &item))
  {
    mrb_value call = mrb_nil_value();
    hoku_ast_prop* prop = (hoku_ast_prop*)item;
    if (prop->call != NULL)
    {
      mrb_value func_method = mrb_str_new_cstr(mrb, prop->call->function);
      mrb_value func_args = mrb_ary_new(mrb);

      for (int i=0; i<prop->call->args_len; i++)
      {
        mrb_ary_push(mrb, func_args, mrb_str_new_cstr(mrb, prop->call->strargs[i]));
      }

      mrb_value fargs [2] = {func_method, func_args };
      call = mrb_obj_new(mrb, func_klass, 2, fargs);
    }
    else
    {
      call = mrb_nil_value();
    }

    mrb_value pname =  mrb_str_new_cstr(mrb, prop->name);
    mrb_value args[3] = {{prop->computed}, pname, call };
    mrb_value hpprop = mrb_obj_new(mrb, prop_klass, 3, args);
    mrb_hash_set(mrb, hash, pname, hpprop);
  }

  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@props"), hash);

  return hash;
}

mrb_value hp_ast_events(mrb_state* mrb, mrb_value self)
{
  mrb_value eprops = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@events"));
  if (!mrb_nil_p(eprops)) return eprops;

  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* ast_klass = mrb_class_get_under(mrb, module, "Ast");
  struct RClass* func_klass = mrb_class_get_under(mrb, ast_klass, "Func");
  struct RClass* event_klass = mrb_class_get_under(mrb, ast_klass, "Event");

  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  mrb_value hash = mrb_hash_new(mrb);
  size_t iter = 0;
  void* item;
  while (hashmap_iter(wrapper->ast->events, &iter, &item))
  {
    mrb_value call = mrb_nil_value();
    hoku_ast_event* event = (hoku_ast_event*)item;
    if (event->call != NULL)
    {
      mrb_value func_method = mrb_str_new_cstr(mrb, event->call->function);
      mrb_value func_args = mrb_ary_new(mrb);

      for (int i=0; i<event->call->args_len; i++)
      {
        mrb_ary_push(mrb, func_args, mrb_str_new_cstr(mrb, event->call->strargs[i]));
      }

      mrb_value fargs [2] = {func_method, func_args };
      call = mrb_obj_new(mrb, func_klass, 2, fargs);
    }
    else
    {
      call = mrb_nil_value();
    }

    mrb_value pname =  mrb_str_new_cstr(mrb, event->name);
    mrb_value args[2] = {pname, call };
    mrb_value hpevent = mrb_obj_new(mrb, event_klass, 2, args);
    mrb_hash_set(mrb, hash, pname, hpevent);
  }

  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@events"), hash);

  return hash;
}

mrb_value hp_ast_get_event(mrb_state* mrb, mrb_value self)
{
  mrb_value name;
  mrb_get_args(mrb, "S", &name);
  mrb_value events = mrb_funcall(mrb, self, "events", 0, NULL);
  return mrb_funcall(mrb, events, "[]", 1, name);
}

mrb_value hp_ast_get_prop(mrb_state* mrb, mrb_value self)
{
  mrb_value name;
  mrb_get_args(mrb, "S", &name);
  mrb_value props = mrb_funcall(mrb, self, "props", 0, NULL);
  return mrb_funcall(mrb, props, "[]", 1, name);
}

mrb_value hp_ast_loop(mrb_state* mrb, mrb_value self)
{  
  mrb_value eloop = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@loop"));
  if (!mrb_nil_p(eloop)) return eloop;
  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);

  if (wrapper->ast->loop != NULL)
  {
    struct RClass* module = mrb_module_get(mrb, "Hokusai");
    struct RClass* ast_klass = mrb_class_get_under(mrb, module, "Ast");
    struct RClass* loop_klass = mrb_class_get_under(mrb, ast_klass, "Loop");
    mrb_value args[2] = {
      mrb_str_new_cstr(mrb, wrapper->ast->loop->name),
      mrb_str_new_cstr(mrb, wrapper->ast->loop->list_name)
    };
    mrb_value obj = mrb_obj_new(mrb, loop_klass, 2, args);
    mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@loop"), obj);
    return obj;
  }
  else
  {
    mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "@loop"), mrb_nil_value());
    return mrb_nil_value();
  }
}

mrb_value hp_ast_style_list(mrb_state* mrb, mrb_value self)
{
  hoku_ast_wrapper* wrapper = hp_ast_get(mrb, self);
  mrb_value arry = mrb_ary_new(mrb);
  hoku_ast_class_list* head = wrapper->ast->style_list;
  while (head != NULL)
  {
    mrb_ary_unshift(mrb, arry, mrb_str_new_cstr(mrb, head->name));
    head = head->next;
  }

  return arry;
}

mrb_value hp_ast_reset(mrb_state* mrb, mrb_value self)
{
  mrb_funcall(mrb, self, "else_active=", 1, mrb_false_value());
  return mrb_nil_value();
}

void mrb_define_hokusai_ast_class(mrb_state* mrb)
{
  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* ast_class = mrb_define_class_under(mrb, module, "Ast", mrb->object_class);

  mrb_define_hokusai_loop_class(mrb, ast_class);
  mrb_define_hokusai_func_class(mrb, ast_class);
  mrb_define_hokusai_event_class(mrb, ast_class);
  mrb_define_hokusai_prop_class(mrb, ast_class);

  MRB_SET_INSTANCE_TT(ast_class, MRB_TT_DATA);

  mrb_define_class_method(mrb, ast_class, "parse", hp_ast_parse, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, ast_class, "type", hp_ast_get_type, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "id", hp_ast_id, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "dump", hp_ast_dump, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "has_if_condition?", hp_ast_has_if_condition, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "has_else_condition?", hp_ast_has_else_condition, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "else_condition_active?", hp_ast_is_else_active, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "else_active=", hp_ast_set_else_active, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, ast_class, "slot?", hp_ast_is_slot, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "virtual?", hp_ast_is_virtual, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "else_ast", hp_ast_else_ast, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "children", hp_ast_children, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "classes", hp_ast_get_classes, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "siblings", hp_ast_siblings, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "if", hp_ast_if, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "loop?", hp_ast_is_loop, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "loop", hp_ast_loop, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "props", hp_ast_props, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "events", hp_ast_events, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "prop", hp_ast_get_prop, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, ast_class, "event", hp_ast_get_event, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, ast_class, "style_list", hp_ast_style_list, MRB_ARGS_NONE());
  mrb_define_method(mrb, ast_class, "reset", hp_ast_reset, MRB_ARGS_NONE());
}

#endif