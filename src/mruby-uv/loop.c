#ifndef MRB_UV_LOOP
#define MRB_UV_LOOP

#include "loop.h"
#include <uv.h>
#include <mruby/dump.h>
#include <mruby/proc.h>
#include <mruby/variable.h>
#include <ast.h>
#include <style.h>
#include <pocket.h>

typedef struct MRBUVWork
{
  int id;
  char* name;
  char* buf; 
  int len;
  struct MRBUVWork* next;
  uv_work_t req;
} mrb_uv_work;

typedef struct MRBUVWorker
{
   mrb_state* mrb; 
   int loaded; 
} mrb_uv_worker;

typedef struct MRBUVJobDefinition 
{ 
  char* name; 
  uint8_t* bin; 
  size_t size; 
} mrb_uv_job_def;

static mrb_state* main_mrb;
static uv_key_t mrb_uv_worker_key;
static int job_count = 0;

static mrb_uv_job_def* mrb_uv_job_defs = NULL;
static int mrb_uv_job_defs_len = 0;
static uv_mutex_t mrb_uv_job_defs_mm;


static void work_done(uv_work_t* req, int status)
{
  mrb_uv_work* job = req->data;
  mrb_state* mrb = main_mrb;
  int ai = mrb_gc_arena_save(mrb);

  mrb_value klass = mrb_obj_value(mrb_class_get_under(mrb, mrb_module_get(mrb, "Hokusai"), "Work"));
  mrb_value args[2] = {
    mrb_fixnum_value(job->id),
    (status == 0 && job->buf) ? mrb_str_new(mrb, job->buf, job->len) : mrb_nil_value()
  };
  mrb_funcall_argv(mrb, klass, mrb_intern_lit(mrb, "finish"), 2, args);
  if (mrb->exc) { mrb_print_error(mrb); mrb->exc = NULL; }
  mrb_gc_arena_restore(mrb, ai);

  free(job->name);
  free(job->buf);
  free(job);
}

static mrb_value mrb_uv_work_register(mrb_state* mrb, mrb_value self)
{
  char* name;
  mrb_value block;
  mrb_get_args(mrb, "zo", &name, &block);

  struct RProc* proc = mrb_proc_ptr(block);
  if (MRB_PROC_CFUNC_P(proc)) mrb_raise(mrb, E_ARGUMENT_ERROR, "Work#register needs a ruby block");

  uint8_t* bin; 
  size_t size;
  mrb_dump_irep(mrb, proc->body.irep, 0, &bin, &size);

  uint8_t* copy = malloc(size);
  memcpy(copy, bin, size);
  mrb_free(mrb, bin);

  uv_mutex_lock(&mrb_uv_job_defs_mm);
  mrb_uv_job_defs = realloc(mrb_uv_job_defs, sizeof(mrb_uv_job_def) * (mrb_uv_job_defs_len + 1));
  mrb_uv_job_defs[mrb_uv_job_defs_len++] = (mrb_uv_job_def){ strdup(name), copy, size };
  uv_mutex_unlock(&mrb_uv_job_defs_mm);

  return mrb_nil_value();
}

static mrb_value mrb_uv_backend_run(mrb_state* mrb, mrb_value self)
{
  return mrb_nil_value();
}

static mrb_uv_worker* worker_get()
{
  mrb_uv_worker* worker = uv_key_get(&mrb_uv_worker_key);
  if (!worker) 
  {
    worker = calloc(1, sizeof(mrb_uv_worker));
    worker->mrb = mrb_open();
    worker->loaded = 0;
    struct RClass* mod = mrb_define_module(worker->mrb, "Hokusai");
    mrb_define_hokusai_ast_class(worker->mrb);
    mrb_define_hokusai_style_class(worker->mrb);
    load_pocket(worker->mrb);
    struct RClass* hokusai_backend = mrb_class_get_under(worker->mrb, mod, "Backend");
    mrb_define_method(worker->mrb, hokusai_backend, "run", mrb_uv_backend_run, MRB_ARGS_NONE());
    uv_key_set(&mrb_uv_worker_key, worker);
  }

  /*
    if there are any jobs created at runtime from the application
    we want to load them all into the worker thread vm.
  */
  uv_mutex_lock(&mrb_uv_job_defs_mm);
  int from = worker->loaded;
  int to = mrb_uv_job_defs_len;
  int len = to - from;
  mrb_uv_job_def* defs = NULL;

  if (len > 0)
  {
    defs = malloc(sizeof(mrb_uv_job_def) * len);
    memcpy(defs, mrb_uv_job_defs + from, sizeof(mrb_uv_job_def) * len);
  }
  uv_mutex_unlock(&mrb_uv_job_defs_mm);

  if (len > 0)
  {
    mrb_state* wmrb = worker->mrb;
    mrb_value work = mrb_obj_value(mrb_class_get_under(wmrb, mrb_module_get(wmrb, "Hokusai"), "Work"));  

    for (int i = 0; i < len; i++)
    {
      int ai = mrb_gc_arena_save(wmrb);
      mrb_irep* irep = mrb_read_irep(wmrb, defs[i].bin);
      struct RProc* proc = mrb_proc_new(wmrb, irep);
      proc->e.target_class = wmrb->object_class;
      mrb_value args[2] = { mrb_str_new_cstr(wmrb, defs[i].name), mrb_obj_value(proc) };
      mrb_funcall_argv(wmrb, work, mrb_intern_lit(wmrb, "add"), 2, args);
      if (wmrb->exc) { mrb_print_error(wmrb); wmrb->exc = NULL; }
      mrb_gc_arena_restore(wmrb, ai);
    }

    free(defs);
    worker->loaded = to;
  }

  return worker;
}

static void work_execute(uv_work_t* req)
{
  mrb_uv_work* job = req->data;
  mrb_uv_worker* worker = worker_get();
  mrb_state* mrb = worker->mrb;
  int ai = mrb_gc_arena_save(mrb);

  mrb_value klass = mrb_obj_value(mrb_class_get_under(mrb, mrb_module_get(mrb, "Hokusai"), "Work"));
  mrb_value args[2] = {
    mrb_str_new_cstr(mrb, job->name),
    mrb_str_new(mrb, job->buf, job->len)
  };

  mrb_value out = mrb_funcall_argv(mrb, klass, mrb_intern_lit(mrb, "run"), 2, args);
  if (mrb->exc) { mrb_print_error(mrb); mrb->exc = NULL; out = mrb_nil_value(); }

  free(job->buf);
  if (mrb_string_p(out)) {
    job->len = RSTRING_LEN(out);
    job->buf = malloc(job->len);
    memcpy(job->buf, RSTRING_PTR(out), job->len);
  } else {
    job->buf = NULL;
    job->len = 0;
  }
  mrb_gc_arena_restore(mrb, ai);
}

static mrb_value mrb_uv_loop_queue(mrb_state* mrb, mrb_value self)
{
  char* name; 
  char* buf; 
  mrb_int len;

  mrb_get_args(mrb, "zs", &name, &buf, &len);
  mrb_uv_loop_wrapper* loop = mrb_uv_loop_get(mrb, self);

  mrb_uv_work* job = calloc(1, sizeof(mrb_uv_work));
  job->id = ++job_count;
  job->name = strdup(name);
  job->buf = malloc(len);
  memcpy(job->buf, buf, len);
  job->len = len;
  job->req.data = job;
  
  uv_queue_work((uv_loop_t*)loop->loop, &job->req, work_execute, work_done);
  return mrb_fixnum_value(job->id);
}

static void mrb_uv_loop_type_free(mrb_state* mrb, void* payload)
{
  mrb_uv_loop_wrapper* wrapper = (mrb_uv_loop_wrapper*) payload;
  uv_loop_close((uv_loop_t*)wrapper->loop);
  free(payload);
}

static struct mrb_data_type mrb_uv_loop_type = { "Loop", mrb_uv_loop_type_free };

mrb_uv_loop_wrapper* mrb_uv_loop_get(mrb_state* mrb, mrb_value self)
{
  mrb_uv_loop_wrapper* wrapper = (mrb_uv_loop_wrapper*)DATA_PTR(self);
  if (!wrapper) {
    mrb_raise(mrb, E_ARGUMENT_ERROR , "uninitialized loop data") ;
  }
  
  return wrapper;
}

mrb_value mrb_define_uv_sleep(mrb_state* mrb, mrb_value self)
{
  mrb_value ms;
  mrb_get_args(mrb, "o", &ms);
  uv_sleep(mrb_int(mrb, ms));

  return mrb_nil_value();
}

/**
 * Constructors
 */
mrb_value mrb_uv_loop_init(mrb_state* mrb, mrb_value self)
{
  mrb_value obj = mrb_funcall(mrb, self, "new", 0, NULL);

  uv_loop_t* loop = malloc(sizeof(uv_loop_t));
  if (!loop) mrb_raise(mrb, E_STANDARD_ERROR, "Could not allocate uv loop");
  if (uv_loop_init(loop) != 0) mrb_raise(mrb, E_STANDARD_ERROR, "Error initializing uv loop");

  mrb_uv_loop_wrapper* wrapper = malloc(sizeof(mrb_uv_loop_wrapper));
  *wrapper = (mrb_uv_loop_wrapper){(void*)loop};
  mrb_data_init(obj, wrapper, &mrb_uv_loop_type);
  return obj;
}

mrb_value mrb_uv_loop_default(mrb_state* mrb, mrb_value self)
{
  mrb_value obj = mrb_funcall(mrb, self, "new", 0, NULL);

  uv_loop_t* loop = uv_default_loop();

  if (!loop)
  {
    mrb_raise(mrb, E_STANDARD_ERROR, "Could not allocate uv loop");
  }
  
  mrb_uv_loop_wrapper* wrapper = malloc(sizeof(mrb_uv_loop_wrapper));
  *wrapper = (mrb_uv_loop_wrapper){(void*)loop};

  mrb_data_init(obj, wrapper, &mrb_uv_loop_type);
  return obj;
}

mrb_value mrb_uv_loop_run(mrb_state* mrb, mrb_value self)
{
  mrb_value flags;
  mrb_get_args(mrb, "o", &flags);
  uv_run_mode mode = (uv_run_mode) mrb_fixnum(flags);
  mrb_uv_loop_wrapper* wrapper = mrb_uv_loop_get(mrb, self);
  int ret = uv_run((uv_loop_t*)wrapper->loop, mode);

  return mrb_fixnum_value(ret);
}

mrb_value mrb_uv_loop_is_alive(mrb_state* mrb, mrb_value self)
{
  mrb_uv_loop_wrapper* wrapper = mrb_uv_loop_get(mrb, self);
  int alive = uv_loop_alive((uv_loop_t*)wrapper->loop);
  
  return alive == 0 ? mrb_false_value() : mrb_true_value();
}

mrb_value mrb_uv_loop_stop(mrb_state* mrb, mrb_value self)
{
  mrb_uv_loop_wrapper* wrapper = mrb_uv_loop_get(mrb, self);
  uv_stop((uv_loop_t*)wrapper->loop);

  return mrb_nil_value();
}

void mrb_define_uv_loop_class(mrb_state* mrb)
{
  main_mrb = mrb;
  uv_key_create(&mrb_uv_worker_key);
  uv_mutex_init(&mrb_uv_job_defs_mm);
  
  struct RClass* hokusai = mrb_module_get(mrb, "Hokusai");
  struct RClass* work_klass = mrb_define_class_under(mrb, hokusai, "Work", mrb->object_class);
  struct RClass* loop_klass = mrb_define_class_under(mrb, hokusai, "Loop", mrb->object_class);

  MRB_SET_INSTANCE_TT(loop_klass, MRB_TT_DATA);
  mrb_define_class_method(mrb, hokusai, "sleep", mrb_define_uv_sleep, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb, work_klass, "register", mrb_uv_work_register, MRB_ARGS_REQ(2));
  mrb_define_class_method(mrb, loop_klass, "init", mrb_uv_loop_init, MRB_ARGS_NONE());
  mrb_define_class_method(mrb, loop_klass, "default", mrb_uv_loop_default, MRB_ARGS_NONE());

  mrb_define_method(mrb, loop_klass, "run", mrb_uv_loop_run, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, loop_klass, "alive?", mrb_uv_loop_is_alive, MRB_ARGS_NONE());
  mrb_define_method(mrb, loop_klass, "stop", mrb_uv_loop_stop, MRB_ARGS_NONE());

  mrb_define_method(mrb, loop_klass, "queue", mrb_uv_loop_queue, MRB_ARGS_REQ(2));
}
#endif