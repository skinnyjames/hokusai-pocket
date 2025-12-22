// adjusted from mruby-thread
#include <mruby.h>
#include <mruby/string.h>
#include <mruby/array.h>
#include <mruby/hash.h>
#include <mruby/range.h>
#include <mruby/proc.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/value.h>
#include <mruby/variable.h>
#include <mruby/dump.h>
#include <mruby/internal.h>
#include <time.h>

#ifdef mrb_range_ptr
#define MRB_RANGE_PTR(v) mrb_range_ptr(v)
#else
#define MRB_RANGE_PTR(v) mrb_range_ptr(mrb, v)
#endif

#ifdef MRB_PROC_ENV
# define _MRB_PROC_ENV(p) (p)->e.env
#else
# define _MRB_PROC_ENV(p) (p)->env
#endif

#ifndef MRB_PROC_SET_TARGET_CLASS
# define MRB_PROC_SET_TARGET_CLASS(p,tc) \
  p->target_class = tc
#endif

mrb_value mrb_thread_migrate_value(mrb_state *mrb, mrb_value v, mrb_state *mrb2);

static mrb_sym
migrate_sym(mrb_state *mrb, mrb_sym sym, mrb_state *mrb2)
{
  mrb_int len;
  const char *p = mrb_sym2name_len(mrb, sym, &len);
  return mrb_intern_static(mrb2, p, len);
}

static void
migrate_all_symbols(mrb_state *mrb, mrb_state *mrb2)
{
  mrb_sym i;
  for (i = 1; i < mrb->symidx + 1; i++) {
    migrate_sym(mrb, i, mrb2);
  }
}

static void
migrate_simple_iv(mrb_state *mrb, mrb_value v, mrb_state *mrb2, mrb_value v2)
{
  mrb_value ivars = mrb_obj_instance_variables(mrb, v);
  mrb_value iv;
  mrb_int i;

  for (i=0; i<RARRAY_LEN(ivars); i++) {
    mrb_sym sym = mrb_symbol(RARRAY_PTR(ivars)[i]);
    mrb_sym sym2 = migrate_sym(mrb, sym, mrb2);
    iv = mrb_iv_get(mrb, v, sym);
    mrb_iv_set(mrb2, v2, sym2, mrb_thread_migrate_value(mrb, iv, mrb2));
  }
}

static mrb_bool
is_safe_migratable_datatype(const mrb_data_type *type)
{
  static const char *known_type_names[] = {
    "mrb_thread_context",
    "mrb_mutex_context",
    "mrb_queue_context",
    "IO",
    "Time",
    NULL
  };
  int i;
  for (i = 0; known_type_names[i]; i++) {
    if (strcmp(type->struct_name, known_type_names[i]) == 0)
      return TRUE;
  }
  return FALSE;
}

static mrb_bool
is_safe_migratable_simple_value(mrb_state *mrb, mrb_value v, mrb_state *mrb2)
{
  switch (mrb_type(v)) {
  case MRB_TT_OBJECT:
  case MRB_TT_EXCEPTION:
    {
      struct RObject *o = mrb_obj_ptr(v);
      mrb_value path = mrb_class_path(mrb, o->c);

      if (mrb_nil_p(path) || !mrb_class_defined(mrb2, RSTRING_PTR(path))) {
        return FALSE;
      }
    }
    break;
  case MRB_TT_PROC:
  case MRB_TT_FALSE:
  case MRB_TT_TRUE:
  case MRB_TT_FIXNUM:
  case MRB_TT_SYMBOL:
#ifndef MRB_WITHOUT_FLOAT
  case MRB_TT_FLOAT:
#endif
  case MRB_TT_STRING:
    break;
  case MRB_TT_RANGE:
    {
      struct RRange *r = MRB_RANGE_PTR(v);
      if (!is_safe_migratable_simple_value(mrb, RANGE_BEG(r), mrb2) ||
          !is_safe_migratable_simple_value(mrb, RANGE_END(r), mrb2)) {
        return FALSE;
      }
    }
    break;
  case MRB_TT_ARRAY:
    {
      int i;
      for (i=0; i<RARRAY_LEN(v); i++) {
        if (!is_safe_migratable_simple_value(mrb, RARRAY_PTR(v)[i], mrb2)) {
          return FALSE;
        }
      }
    }
    break;
  case MRB_TT_HASH:
    {
      mrb_value ka;
      int i, l;
      ka = mrb_hash_keys(mrb, v);
      l = RARRAY_LEN(ka);
      for (i = 0; i < l; i++) {
        mrb_value k = mrb_ary_entry(ka, i);
        if (!is_safe_migratable_simple_value(mrb, k, mrb2) ||
            !is_safe_migratable_simple_value(mrb, mrb_hash_get(mrb, v, k), mrb2)) {
          return FALSE;
        }
      }
    }
    break;
  case MRB_TT_DATA:
    if (!is_safe_migratable_datatype(DATA_TYPE(v)))
      return FALSE;
    break;
  default:
    return FALSE;
    break;
  }
  return TRUE;
}

static void
migrate_irep_child(mrb_state *mrb, mrb_irep *ret, mrb_state *mrb2)
{
  int i;
  mrb_code *old_iseq;

  // migrate pool
  // FIXME: broken with mruby3
  #ifndef IREP_TT_SFLAG
  for (i = 0; i < ret->plen; ++i) {
    mrb_value v = ret->pool[i];
    if (mrb_type(v) == MRB_TT_STRING) {
      struct RString *s = mrb_str_ptr(v);
      if (RSTR_NOFREE_P(s) && RSTRING_LEN(v) > 0) {
        char *old = RSTRING_PTR(v);
        s->as.heap.ptr = (char*)mrb_malloc(mrb2, RSTRING_LEN(v));
        memcpy(s->as.heap.ptr, old, RSTRING_LEN(v));
        RSTR_UNSET_NOFREE_FLAG(s);
      }
    }
  }
  #endif

  // migrate iseq
  if (ret->flags & MRB_ISEQ_NO_FREE) {
    old_iseq = ret->iseq;
    ret->iseq = (mrb_code*)mrb_malloc(mrb2, sizeof(mrb_code) * ret->ilen);
    memcpy(ret->iseq, old_iseq, sizeof(mrb_code) * ret->ilen);
    ret->flags &= ~MRB_ISEQ_NO_FREE;
  }

  // migrate sub ireps
  for (i = 0; i < ret->rlen; ++i) {
    migrate_irep_child(mrb, ret->reps[i], mrb2);
  }
}

static mrb_irep*
migrate_irep(mrb_state *mrb, mrb_irep *src, mrb_state *mrb2) {
  uint8_t *irep = NULL;
  size_t binsize = 0;
  mrb_irep *ret;
#ifdef DUMP_ENDIAN_NAT
  mrb_dump_irep(mrb, src, DUMP_ENDIAN_NAT, &irep, &binsize);
#else
  mrb_dump_irep(mrb, src, 0, &irep, &binsize);
#endif

  ret = mrb_read_irep(mrb2, irep);
  migrate_irep_child(mrb, ret, mrb2);
  mrb_free(mrb, irep);
  return ret;
}

struct RProc*
migrate_rproc(mrb_state *mrb, struct RProc *rproc, mrb_state *mrb2) {
  struct RProc *newproc = mrb_proc_new(mrb2, migrate_irep(mrb, rproc->body.irep, mrb2));
  mrb_irep_decref(mrb2, newproc->body.irep);

#ifdef MRB_PROC_ENV_P
  if (_MRB_PROC_ENV(rproc) && MRB_PROC_ENV_P(rproc)) {
#else
  if (_MRB_PROC_ENV(rproc)) {
#endif
#ifdef MRB_ENV_LEN
    mrb_int i, len = MRB_ENV_LEN(_MRB_PROC_ENV(rproc));
#else
    mrb_int i, len = MRB_ENV_STACK_LEN(_MRB_PROC_ENV(rproc));
#endif
    struct REnv *newenv = (struct REnv*)mrb_obj_alloc(mrb2, MRB_TT_ENV, mrb2->object_class);

    newenv->stack = mrb_malloc(mrb, sizeof(mrb_value) * len);
#ifdef MRB_ENV_CLOSE
    MRB_ENV_CLOSE(newenv);
#else
    MRB_ENV_UNSHARE_STACK(newenv);
#endif
    int off = 0;
    for (i = 0; i < len; ++i) {
      mrb_value v = _MRB_PROC_ENV(rproc)->stack[i];
      if (mrb_obj_ptr(v) == ((struct RObject*)rproc)) {
        newenv->stack[i] = mrb_obj_value(newproc);
      } else {
        if (strcmp("Hokusai::Work", mrb_obj_classname(mrb, v)) != 0)
        {
          newenv->stack[i + off] = mrb_thread_migrate_value(mrb, v, mrb2);
        }
        else
        {
          off -= 1;
        }
      }
    }
#ifdef MRB_SET_ENV_STACK_LEN
    MRB_SET_ENV_STACK_LEN(newenv, len);
#elif defined MRB_ENV_SET_LEN
    MRB_ENV_SET_LEN(newenv, len);
#endif
    _MRB_PROC_ENV(newproc) = newenv;
#ifdef MRB_PROC_ENVSET
    newproc->flags |= MRB_PROC_ENVSET;
#endif
    if (rproc->upper) {
      newproc->upper = migrate_rproc(mrb, rproc->upper, mrb2);
    }
  }

  return newproc;
}

static struct RClass*
path2class(mrb_state *M, char const* path_begin, mrb_int len) {
  char const* begin = path_begin;
  char const* p = begin;
  char const* end = begin + len;
  struct RClass* ret = M->object_class;

  while(1) {
    mrb_sym cls;
    mrb_value cnst;

    while((p < end && p[0] != ':') ||
          ((p + 1) < end && p[1] != ':')) ++p;

    cls = mrb_intern(M, begin, p - begin);
    if (!mrb_mod_cv_defined(M, ret, cls)) {
      mrb_raisef(M, mrb_class_get(M, "ArgumentError"), "undefined class/module %S",
                 mrb_str_new(M, path_begin, p - path_begin));
    }

    cnst = mrb_mod_cv_get(M, ret, cls);
    if (mrb_type(cnst) != MRB_TT_CLASS &&  mrb_type(cnst) != MRB_TT_MODULE) {
      mrb_raisef(M, mrb_class_get(M, "TypeError"), "%S does not refer to class/module",
                 mrb_str_new(M, path_begin, p - path_begin));
    }
    ret = mrb_class_ptr(cnst);

    if(p >= end) { break; }

    p += 2;
    begin = p;
  }
  return ret;
}

enum mrb_timezone { TZ_NONE = 0 };

struct mrb_time {
  time_t              sec;
  time_t              usec;
  enum mrb_timezone   timezone;
  struct tm           datetime;
};

// based on https://gist.github.com/3066997
mrb_value
mrb_thread_migrate_value(mrb_state *mrb, mrb_value const v, mrb_state *mrb2) {
  if (mrb == mrb2) { return v; }

  switch (mrb_type(v)) {
  case MRB_TT_CLASS:
  case MRB_TT_MODULE: {
    mrb_value cls_path = mrb_class_path(mrb, mrb_class_ptr(v));
    struct RClass *c;
    if (mrb_nil_p(cls_path)) {
      return mrb_nil_value();
    }
    c = path2class(mrb2, RSTRING_PTR(cls_path), RSTRING_LEN(cls_path));
    return mrb_obj_value(c);
  }

  case MRB_TT_OBJECT:
  case MRB_TT_EXCEPTION:
    {
      mrb_value cls_path = mrb_class_path(mrb, mrb_class(mrb, v)), nv;
      struct RClass *c;
      if (mrb_nil_p(cls_path)) {
        return mrb_nil_value();
      }
      c = path2class(mrb2, RSTRING_PTR(cls_path), RSTRING_LEN(cls_path));
      nv = mrb_obj_value(mrb_obj_alloc(mrb2, mrb_type(v), c));
      migrate_simple_iv(mrb, v, mrb2, nv);
      if (mrb_type(v) == MRB_TT_EXCEPTION) {
        mrb_iv_set(mrb2, nv, mrb_intern_lit(mrb2, "mesg"),
                   mrb_thread_migrate_value(mrb, mrb_iv_get(mrb, v, mrb_intern_lit(mrb, "mesg")), mrb2));
      }
      return nv;
    }
    break;
  case MRB_TT_PROC:
    return mrb_obj_value(migrate_rproc(mrb, mrb_proc_ptr(v), mrb2));
  case MRB_TT_FALSE:
  case MRB_TT_TRUE:
  case MRB_TT_FIXNUM:
    return v;
  case MRB_TT_SYMBOL:
    return mrb_symbol_value(migrate_sym(mrb, mrb_symbol(v), mrb2));
#ifndef MRB_WITHOUT_FLOAT
  case MRB_TT_FLOAT:
    return mrb_float_value(mrb2, mrb_float(v));
#endif
  case MRB_TT_STRING:
    return mrb_str_new(mrb2, RSTRING_PTR(v), RSTRING_LEN(v));

  case MRB_TT_RANGE: {
    struct RRange *r = MRB_RANGE_PTR(v);
    return mrb_range_new(mrb2,
                         mrb_thread_migrate_value(mrb, RANGE_BEG(r), mrb2),
                         mrb_thread_migrate_value(mrb, RANGE_END(r), mrb2),
                         RANGE_EXCL(r));
  }

  case MRB_TT_ARRAY: {
    int i, ai;

    mrb_value nv = mrb_ary_new_capa(mrb2, RARRAY_LEN(v));
    ai = mrb_gc_arena_save(mrb2);
    for (i=0; i<RARRAY_LEN(v); i++) {
      mrb_ary_push(mrb2, nv, mrb_thread_migrate_value(mrb, RARRAY_PTR(v)[i], mrb2));
      mrb_gc_arena_restore(mrb2, ai);
    }
    return nv;
  }

  case MRB_TT_HASH: {
    mrb_value ka;
    int i, l;

    mrb_value nv = mrb_hash_new(mrb2);
    ka = mrb_hash_keys(mrb, v);
    l = RARRAY_LEN(ka);
    for (i = 0; i < l; i++) {
      int ai = mrb_gc_arena_save(mrb2);
      mrb_value k = mrb_thread_migrate_value(mrb, mrb_ary_entry(ka, i), mrb2);
      mrb_value o = mrb_thread_migrate_value(mrb, mrb_hash_get(mrb, v, k), mrb2);
      mrb_hash_set(mrb2, nv, k, o);
      mrb_gc_arena_restore(mrb2, ai);
    }
    migrate_simple_iv(mrb, v, mrb2, nv);
    return nv;
  }

  case MRB_TT_DATA: {
    mrb_value cls_path = mrb_class_path(mrb, mrb_class(mrb, v)), nv;
    struct RClass *c = path2class(mrb2, RSTRING_PTR(cls_path), RSTRING_LEN(cls_path));
    if (!is_safe_migratable_datatype(DATA_TYPE(v)))
      mrb_raisef(mrb, E_TYPE_ERROR, "cannot migrate object: %S(%S)",
                 mrb_str_new_cstr(mrb, DATA_TYPE(v)->struct_name), mrb_inspect(mrb, v));
    nv = mrb_obj_value(mrb_obj_alloc(mrb2, mrb_type(v), c));
    if (strcmp(DATA_TYPE(v)->struct_name, "Time") == 0) {
      DATA_PTR(nv) = mrb_malloc(mrb, sizeof(struct mrb_time));
      *((struct mrb_time*)DATA_PTR(nv)) = *((struct mrb_time*)DATA_PTR(v));
      DATA_TYPE(nv) = DATA_TYPE(v);
      return nv;
    } else {
      DATA_PTR(nv) = DATA_PTR(v);
      // Don't copy type information to avoid freeing in sub-thread.
      // DATA_TYPE(nv) = DATA_TYPE(v);
      migrate_simple_iv(mrb, v, mrb2, nv);
      return nv;
    }
  }

    // case MRB_TT_FREE: return mrb_nil_value();

  default: break;
  }

  // mrb_raisef(mrb, E_TYPE_ERROR, "cannot migrate object: %S", mrb_fixnum_value(mrb_type(v)));
  mrb_raisef(mrb, E_TYPE_ERROR, "cannot migrate object: %S(%S)", mrb_inspect(mrb, v), mrb_fixnum_value(mrb_type(v)));
  return mrb_nil_value();
}