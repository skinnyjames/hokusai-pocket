#ifndef MRB_UV_LOOP
#define MRB_UV_LOOP

#include "loop.h"
#include <uv.h>
#include <mruby/variable.h>
#include <mruby/array.h>
#include <mruby/hash.h>
#include "migrate.c"
#include <ast.h>
#include <style.h>
#include <pocket.h>

/**
 * @struct MrbUvWorkContext
 * @brief Baton context for UV worker thread 
 * @var MrbUvWorkContext::req
 * the parameter that is passed to uv_queue_work
 * @var MrbUvWorkContext::id
 * A unique and incrementing integer for every work request
 * @var MrbUvWorkContext::mrb
 * An MRuby VM specific to this work request
 * @var MrbUvWorkContext::work
 * The Hokusai::Work object that was passed to this request (migrated to this vm)
 * @var MrbUvWorkContext::execution_state
 * The state for the Hokusai::Work object, migrated to this vm, to pass to #execute
 **/
typedef struct MrbUvWorkContext {
  uv_work_t req;
  int id;
  mrb_state* mrb;
  mrb_value work;
  mrb_value execution_state;
} mrb_uv_work_context;

/**
 * @struct MrbUvQueue
 * @brief The result of the work execution, including context.
 * @var MrbUbQueue::id
 * The id of the mrb_uv_work_context
 * @var MrbUvQueue::mrb
 * The Mruby vm of the mrb_uv_work_context
 * @var MrbUvQueue::work
 * The Hokusai::Work object (owned by this vm)
 * @var MrbUvQueue::completed
 * The response from Hokusai::Work#execute (owned by this vm)
 * @var MrbUvQueue::next
 * The next item in the queue
 **/
typedef struct MrbUvQueue {
  int id;
  mrb_state* mrb;
  mrb_value work;
  mrb_value completed;
  struct MrbUvQueue* next;
} mrb_uv_queue;

typedef struct MrbUvAsyncWrapper {
  mrb_state* mrb;
  mrb_value receiver;
  mrb_uv_queue* queue;
} mrb_uv_async_wrapper;

static uv_async_t mrb_uv_async;
static uv_mutex_t mm;
static int uv_count = 0;

static void mrb_uv_handle_async(uv_async_t* handle)
{
  uv_mutex_lock(&mm);
  mrb_uv_async_wrapper* uv_async_data = (mrb_uv_async_wrapper*)mrb_uv_async.data;
  mrb_uv_queue* head = uv_async_data->queue;

  /**
   * 1. Iterate the queue
   * 2. Migrate the execution results
   * 3. Call the finish callback on the work.
   */
  while (uv_async_data->queue)
  {
    // Bring the execution result to this vm.
    mrb_value completed = mrb_thread_migrate_value(uv_async_data->queue->mrb, uv_async_data->queue->completed, uv_async_data->mrb);
    mrb_value work = mrb_thread_migrate_value(uv_async_data->queue->mrb, uv_async_data->queue->work, uv_async_data->mrb);

    // a bit hacky, somehow the Hokusai::Work object lost the reciever variable, so we need to pass it as an argument.
    mrb_funcall(uv_async_data->mrb, work, "finish", 2, uv_async_data->receiver, completed);
    if (uv_async_data->mrb->exc) mrb_print_error(uv_async_data->mrb);

    /**
     * we are done with this work's ruby vm
     * and this queue item.
     * 
     * Cleanup
     */
    mrb_close(uv_async_data->queue->mrb);

    mrb_uv_queue* head = uv_async_data->queue;
    uv_async_data->queue = uv_async_data->queue->next;
    free(head);
  }

  head = NULL;
  uv_async_data->queue = NULL;

  uv_mutex_unlock(&mm);
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

/**
 * Constructors
 */
mrb_value mrb_uv_loop_init(mrb_state* mrb, mrb_value self)
{
  mrb_value obj = mrb_funcall(mrb, self, "new", 0, NULL);

  uv_loop_t* loop = malloc(sizeof(uv_loop_t));
  if (!loop) mrb_raise(mrb, E_STANDARD_ERROR, "Could not allocate uv loop");
  if (uv_loop_init(loop) != 0) mrb_raise(mrb, E_STANDARD_ERROR, "Error initializing uv loop");
  uv_async_init(loop, &mrb_uv_async, mrb_uv_handle_async);


  mrb_uv_loop_wrapper* wrapper = malloc(sizeof(mrb_uv_loop_wrapper));
  *wrapper = (mrb_uv_loop_wrapper){(void*)loop};
  mrb_data_init(obj, wrapper, &mrb_uv_loop_type);
  return obj;
}

mrb_value mrb_uv_loop_default(mrb_state* mrb, mrb_value self)
{
  mrb_value obj = mrb_funcall(mrb, self, "new", 0, NULL);

  uv_loop_t* loop = uv_default_loop();
  uv_async_init(loop, &mrb_uv_async, mrb_uv_handle_async);

  if (!loop)
  {
    mrb_raise(mrb, E_STANDARD_ERROR, "Could not allocate uv loop");
  }
  
  mrb_uv_loop_wrapper* wrapper = malloc(sizeof(mrb_uv_loop_wrapper));
  *wrapper = (mrb_uv_loop_wrapper){(void*)loop};

  mrb_data_init(obj, wrapper, &mrb_uv_loop_type);
  return obj;
}

/*
  Instance methods
*/
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

static void mrb_uv_loop_queue_execute(uv_work_t* req)
{  
  /**
   * This may be running in separate thread.
   */
  mrb_uv_work_context* context = (mrb_uv_work_context*)((uv_work_t*)req)->data;
  mrb_uv_async_wrapper* uv_async = (mrb_uv_async_wrapper*)mrb_uv_async.data;

  /*
  * We are going to pass the state directly to #execute
  * it already belongs this vm.
  * 
  * Note: the execution_result also belongs to this vm, but we will need to migrate
  * it back in the future.
  */
  mrb_value state = mrb_iv_get(context->mrb, context->work, mrb_intern_lit(context->mrb, "@state"));
  mrb_value execution_result = mrb_funcall_argv(context->mrb, context->work, mrb_intern_lit(context->mrb, "execute"), 1, &state);

  if (context->mrb->exc) mrb_print_error(context->mrb);

  if (!mrb_nil_p(execution_result))
  {
    /**
     * Lock the mutex while we modify shared state.
     */
    uv_mutex_lock(&mm);

    if (uv_async->queue == NULL)
    {
      uv_async->queue = malloc(sizeof(mrb_uv_queue));
      uv_async->queue->id = context->id;
      uv_async->queue->mrb = context->mrb;
      uv_async->queue->work = context->work;
      uv_async->queue->next = NULL;
      uv_async->queue->completed = execution_result;
    }
    else
    {
      mrb_uv_queue* queue = malloc(sizeof(mrb_uv_queue));
      queue->id = context->id;
      queue->mrb = context->mrb;
      queue->work = context->work;
      queue->completed = execution_result;

      // put on the front of the list.
      queue->next = uv_async->queue;
      uv_async->queue = queue;
    }

    uv_mutex_unlock(&mm);

    uv_async_send(&mrb_uv_async);
  }
}

void mrb_uv_loop_queue_finished(uv_work_t* req, int status)
{
  mrb_uv_work_context* context = (mrb_uv_work_context*)((uv_work_t*)req)->data;
  free(context);
}

/*
  Puts a Hokusai::Work into the uv threaded work queue
  
  Spins up a new MRB VM and exports Hokusai objects to it.
  passes the work context and callbacks to `uv_queue_work`
*/
mrb_value mrb_uv_loop_queue(mrb_state* mrb, mrb_value self)
{
  mrb_value work;
  mrb_get_args(mrb, "o", &work);
  mrb_uv_loop_wrapper* loop = mrb_uv_loop_get(mrb, self);

  /**
   * create a new context for this work.
   */
  mrb_uv_work_context* context = malloc(sizeof(mrb_uv_work_context));
  context->req.data = (void*)context;

  /**
   * open a new mruby vm and init it with Hokusai
   */
  mrb_state* mrb2 = mrb_open();
  struct RClass* mod = mrb_define_module(mrb2, "Hokusai");
  mrb_define_hokusai_ast_class(mrb2);
  mrb_define_hokusai_style_class(mrb2);
  load_pocket(mrb2);
  migrate_all_symbols(mrb, mrb2);

  /**
   * We will be calling Hokusai::Work.finish from the calling vm
   * But we will be calling execute from the new vm
   * so we will migrate the work object.
   */
  mrb_value work2 = mrb_thread_migrate_value(mrb, work, mrb2);
  if (mrb2->exc) mrb_print_error(mrb2);

  /*
  *  Increment the global count and use it as the id
  */
  uv_count = uv_count + 1;
  context->id = uv_count;
  context->mrb = mrb2;
  context->work = work2;

  /*
    Finish populating the uv_async_data
  */
  if (mrb_nil_p(((mrb_uv_async_wrapper*)(mrb_uv_async.data))->receiver))
  {
    mrb_value reciever = mrb_iv_get(mrb, work, mrb_intern_lit(mrb, "@receiver"));
    ((mrb_uv_async_wrapper*)(mrb_uv_async.data))->receiver = reciever;
  }

  /**
   * Queue the async work
   */
  uv_queue_work((uv_loop_t*)loop->loop, &context->req, mrb_uv_loop_queue_execute, mrb_uv_loop_queue_finished);
  
  return mrb_nil_value();
}

void mrb_define_uv_loop_class(mrb_state* mrb)
{
  /*
    initialize the uv_async_t payload.
    this will be passed to `uv_async_send` calls
    It contains the calling MRuby VM and a queue of results from the executions.
  */
  mrb_uv_async_wrapper* uv_async = malloc(sizeof(mrb_uv_async_wrapper));
  uv_async->mrb = mrb;
  uv_async->receiver = mrb_nil_value();
  uv_async->queue = NULL;
  mrb_uv_async.data = (void*)uv_async;

  /*
    initialize the mutex
  */
  uv_mutex_init(&mm);

  struct RClass* module = mrb_module_get(mrb, "UV");
  struct RClass* klass = mrb_define_class_under(mrb, module, "Loop", mrb->object_class);

  MRB_SET_INSTANCE_TT(klass, MRB_TT_DATA);

  mrb_define_class_method(mrb, klass, "init", mrb_uv_loop_init, MRB_ARGS_NONE());
  mrb_define_class_method(mrb, klass, "default", mrb_uv_loop_default, MRB_ARGS_NONE());

  mrb_define_method(mrb, klass, "run", mrb_uv_loop_run, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, klass, "alive?", mrb_uv_loop_is_alive, MRB_ARGS_NONE());
  mrb_define_method(mrb, klass, "stop", mrb_uv_loop_stop, MRB_ARGS_NONE());

  mrb_define_method(mrb, klass, "queue", mrb_uv_loop_queue, MRB_ARGS_REQ(1));
}

#endif