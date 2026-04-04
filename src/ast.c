#ifndef HOKUSAI_POCKET_AST
#define HOKUSAI_POCKET_AST

#include "ast.h"
#include "error.h"

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

/* returns head */
mrb_value hp_ast_walk(hoku_ast* ast, mrb_state* mrb)
{
  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* ast_klass = mrb_class_get_under(mrb, module, "Ast");
  struct RClass* func_klass = mrb_class_get_under(mrb, ast_klass, "Func");
  struct RClass* loop_klass = mrb_class_get_under(mrb, ast_klass, "Loop");
  struct RClass* prop_klass = mrb_class_get_under(mrb, ast_klass, "Prop");
  struct RClass* event_klass = mrb_class_get_under(mrb, ast_klass, "Event");

  mrb_value rast = mrb_obj_new(mrb, ast_klass, 0, NULL);

  /* get id */
  if (ast->id) mrb_funcall(mrb, rast, "id=", 1, mrb_str_new(mrb, ast->id, strlen(ast->id)));

  /* get ast type */
  if (ast->type != NULL) mrb_funcall(mrb, rast, "type=", 1, mrb_str_new(mrb, ast->type, strlen(ast->type)));

  /* get class list */
  mrb_value class_array = mrb_funcall(mrb, rast, "classes", 0, NULL);
  hoku_ast_class_list* class_list = ast->class_list;
  while (class_list != NULL)
  {
    mrb_ary_unshift(mrb, class_array, mrb_str_new_cstr(mrb, class_list->name));
    class_list = class_list->next;
  }

  /* get style list */
  mrb_value style_array = mrb_funcall(mrb, rast, "style_list", 0, NULL);
  hoku_ast_class_list* style_list = ast->style_list;
  while (style_list != NULL)
  {
    mrb_ary_unshift(mrb, style_array, mrb_str_new_cstr(mrb, style_list->name));
    style_list = style_list->next;
  }

  /* get if function */
  if (ast->cond)
  {
    mrb_value if_func_method = mrb_str_new_cstr(mrb, ast->cond->call->function);
    mrb_value if_func_args = mrb_ary_new(mrb);

    for (int i=0; i<ast->cond->call->args_len; i++)
    {
      mrb_ary_push(mrb, if_func_args, mrb_str_new_cstr(mrb, ast->cond->call->strargs[i]));
    }

    mrb_value ifargs [2] = {if_func_method, if_func_args};
    mrb_value iffunc = mrb_obj_new(mrb, func_klass, 2, ifargs);
    mrb_funcall(mrb, rast, "if=", 1, iffunc);
  }

  /* get loop function */
  if (ast->loop != NULL)
  {
    mrb_value loopargs[2] = {
      mrb_str_new_cstr(mrb, ast->loop->name),
      mrb_str_new_cstr(mrb, ast->loop->list_name)
    };
    mrb_value loopobj = mrb_obj_new(mrb, loop_klass, 2, loopargs);
    mrb_funcall(mrb, rast, "loop=", 1, loopobj);
  }

  /* get props */
  mrb_value prop_hash = mrb_funcall(mrb, rast, "props", 0, NULL);
  size_t prop_iter = 0;
  void* prop_item;
  while (hashmap_iter(ast->props, &prop_iter, &prop_item))
  {
    mrb_value call = mrb_nil_value();
    hoku_ast_prop* prop = (hoku_ast_prop*)prop_item;
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
    mrb_value args[3] = {mrb_bool_value(prop->computed), pname, call};
    mrb_value hpprop = mrb_obj_new(mrb, prop_klass, 3, args);
    mrb_hash_set(mrb, prop_hash, pname, hpprop);
  }

  /* get events */
  mrb_value event_hash = mrb_funcall(mrb, rast, "events", 0, NULL);
  size_t event_iter = 0;
  void* event_item;
  while (hashmap_iter(ast->events, &event_iter, &event_item))
  {
    mrb_value call = mrb_nil_value();
    hoku_ast_event* event = (hoku_ast_event*)event_item;
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
    mrb_value args[2] = {pname, call};
    mrb_value hpevent = mrb_obj_new(mrb, event_klass, 2, args);
    mrb_hash_set(mrb, event_hash, pname, hpevent);
  }

  /* get siblings */
  mrb_value siblings = mrb_funcall(mrb, rast, "siblings", 0, NULL);
  hoku_ast* sibling_head = ast->relations->next_sibling;
  while (sibling_head != NULL)
  {
    mrb_value rsibling = hp_ast_walk(sibling_head, mrb);
    mrb_ary_push(mrb, siblings, rsibling);

    sibling_head = sibling_head->relations->next_sibling;
  }

  /* get children */
  mrb_value children = mrb_funcall(mrb, rast, "children", 0, NULL);
  hoku_ast* child_head = ast->relations->next_child;
  while (child_head != NULL)
  {
    mrb_value rchild = hp_ast_walk(child_head, mrb);
    mrb_ary_push(mrb, children, rchild);

    child_head = child_head->relations->next_sibling;
  }

  /* get else ast */
  if (ast->else_relations)
  {
    mrb_value relse = hp_ast_walk(ast->else_relations->next_child, mrb);
    mrb_funcall(mrb, rast, "else_ast=", 1, relse);

  }

  return rast;
}

/* mega parse */
mrb_value hp_ast_megaparse(mrb_state* mrb, mrb_value self)
{
  mrb_value templ;
  mrb_value templtype;

  mrb_get_args(mrb, "SS", &templ, &templtype);

  char* template = mrb_str_to_cstr(mrb, templ);
  char* type = mrb_str_to_cstr(mrb, templtype);
  hoku_ast* ast = hp_create_ast(mrb, type, template);
  return hp_ast_walk(ast, mrb);
}

void mrb_define_hokusai_ast_class(mrb_state* mrb)
{
  struct RClass* module = mrb_module_get(mrb, "Hokusai");
  struct RClass* ast_class = mrb_define_class_under(mrb, module, "Ast", mrb->object_class);
  mrb_define_class_method(mrb, ast_class, "parse", hp_ast_megaparse, MRB_ARGS_REQ(2));
  /* remove all this crap */
}

#endif