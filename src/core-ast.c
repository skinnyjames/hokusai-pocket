#ifndef HOKUSAI_CORE_AST
#define HOKUSAI_CORE_AST

#include "core-ast.h"

int hoku_ast_class_list_init(hoku_ast_class_list** out, char* name)
{
	hoku_ast_class_list* init = malloc(sizeof(hoku_ast_class_list));
	if (init == NULL) return -1;

	init->name = strdup(name);
	if (init->name == NULL)
	{
		free(init);
		return -1;
	}

	init->next = NULL;
	*out = init;
	return 0;
}

void hoku_ast_class_list_free(hoku_ast_class_list* list)
{
	hoku_ast_class_list* head = list;
	while (head != NULL)
	{
		hoku_ast_class_list* cpy = head->next;
		free(head->name);
		free(head);
		head = cpy;
	}
}

int hoku_ast_style_list_prepend(hoku_ast* ast, char* name)
{
	hoku_ast_class_list* init;
	if (hoku_ast_class_list_init(&init, name) == -1) return -1;

	if (ast->style_list == NULL)
	{
		ast->style_list = init;
	}
	else
	{
		init->next = ast->style_list;
		ast->style_list = init;
	}

	return 0;
}

int hoku_ast_class_list_prepend(hoku_ast* ast, char* name)
{
	hoku_ast_class_list* init;
	if (hoku_ast_class_list_init(&init, name) == -1) return -1;

	if (ast->class_list == NULL)
	{
		ast->class_list = init;
	}
	else
	{
		init->next = ast->class_list;
		ast->class_list = init;
	}

	return 0;
}

bool hoku_ast_class_list_includes(hoku_ast* ast, char* name)
{
	hoku_ast_class_list* head = ast->class_list;
	bool found = false;
	while (head != NULL)
	{
		if (strcmp(head->name, name) == 0)
		{
			found = true;
			break;
		}
		head = head->next;
	}

	return found;
}

int hoku_ast_func_call_init(hoku_ast_func_call** call, char* name)
{
	hoku_ast_func_call* init = malloc(sizeof(hoku_ast_func_call));
	if (init == NULL) return -1;

	// name should be null terminated.
	init->function = strdup(name);
	if (init->function == NULL)
	{
		free(init);
		return -1;
	}	

	init->args_len = 0;
	init->args = NULL;
	init->strargs = malloc(sizeof(char*) * 10);
	// 10 arg buffer.

	*call = init;
	return 0;
}

void hoku_ast_func_call_free(hoku_ast_func_call* init)
{
	for (int i=0; i<init->args_len; i++)
	{
		free(init->strargs[i]);
	}
  free(init->strargs);
	free(init->function);
	free(init);
}

int hoku_ast_event_init(hoku_ast_event** event, char* name)
{
	hoku_ast_event* init = malloc(sizeof(hoku_ast_event));
	if (init == NULL) return -1;

	init->call = NULL;
	init->name = strdup(name);
	if (init->name == NULL)
	{
		free(init);
		return -1;
	}

	*event = init;
	return 0;
}

void hoku_ast_event_free(void* payload)
{
	hoku_ast_event* event = (hoku_ast_event*)payload;
	hoku_ast_func_call_free(event->call);
	free(event->name);
}

int hoku_ast_prop_init(hoku_ast_prop** prop, char* name)
{
	hoku_ast_prop* init = malloc(sizeof(hoku_ast_prop));
	if (init == NULL) return -1;

	init->computed = false;
	init->call = NULL;
	init->name = strdup(name);
	if (init->name == NULL)
	{
		free(init);
		return -1;
	}

	*prop = init;
	return 0;
}

void hoku_ast_prop_free(void* payload)
{
	hoku_ast_prop* prop = (hoku_ast_prop*)payload;
	hoku_ast_func_call_free(prop->call);
	free(prop->name);
}

/** hashmap functions for props and events
*/

uint64_t hoku_ast_prop_hash(const void* item, uint64_t seed0, uint64_t seed1)
{
	hoku_ast_prop* prop = (hoku_ast_prop*) item;
	return hashmap_sip(prop->name, strlen(prop->name), seed0, seed1);
}

uint64_t hoku_ast_event_hash(const void* item, uint64_t seed0, uint64_t seed1)
{
	hoku_ast_event* event = (hoku_ast_event*) item;
	return hashmap_sip(event->name, strlen(event->name), seed0, seed1);
}

int hoku_ast_prop_compare(const void* a, const void* b, void* udata)
{
	const hoku_ast_prop* prop_a = (hoku_ast_prop*) a;
	const hoku_ast_prop* prop_b = (hoku_ast_prop*) b;
	return strcmp(prop_a->name, prop_b->name);
}

int hoku_ast_event_compare(const void* a, const void* b, void* udata)
{
	const hoku_ast_event* ea = (hoku_ast_event*) a;
	const hoku_ast_event* eb = (hoku_ast_event*) b;
	return strcmp(ea->name, eb->name);
}

int hoku_ast_add_prop(hoku_ast* component, hoku_ast_prop* prop)
{
	hashmap_set(component->props, prop);
	free(prop);
	return 0;
}

hoku_ast_prop* hoku_ast_get_prop(hoku_ast* component, hoku_ast_prop* prop)
{
	return (hoku_ast_prop*)hashmap_get(component->props, prop);
}

int hoku_ast_add_event(hoku_ast* component, hoku_ast_event* event)
{
	hashmap_set(component->events, event);
	free(event);
	return 0;
}

hoku_ast_event* hoku_ast_get_event(hoku_ast* component, hoku_ast_event* event)
{
	return (hoku_ast_event*) hashmap_get(component->events, event);
}

int hoku_ast_props_init(struct hashmap** props)
{
	struct hashmap* init = hashmap_new(sizeof(hoku_ast_prop), 0, 0, 0, hoku_ast_prop_hash, hoku_ast_prop_compare, hoku_ast_prop_free, NULL);
	if (init == NULL) return -1;

	*props = init;
	return 0;
}

int hoku_ast_events_init(struct hashmap** events)
{
	struct hashmap* init = hashmap_new(sizeof(hoku_ast_event), 0, 0, 0, hoku_ast_event_hash, hoku_ast_event_compare, hoku_ast_event_free, NULL);
	if (init == NULL) return -1;

	*events = init;
	return 0;
}

int hoku_ast_events_count(hoku_ast* component)
{
	return hashmap_count(component->events);
}

int hoku_ast_props_count(hoku_ast* component)
{
	return hashmap_count(component->props);
}

int hoku_ast_prepend_sibling(hoku_ast** first, hoku_ast* second)
{
	if ((*first)->relations->next_sibling == NULL)
	{
		second->parent = (*first)->parent;
		(*first)->relations->next_sibling = second;
	}
	else
	{
		hoku_ast* head = *first;
		second->relations->next_sibling = head;
		(*first)->relations->next_sibling = second;
	}
	return 0;
}
int hoku_ast_prepend_child(hoku_ast** parent, hoku_ast* child)
{
	if ((*parent)->relations->next_child == NULL)
	{
		(*parent)->relations->next_child = child;
	}
	else
	{
		hoku_ast* head = (*parent)->relations->next_child;
		head->parent = child;
		child->relations->next_child = head;
		(*parent)->relations->next_child = child;
	}
	return 0;
}

int hoku_ast_append_sibling(hoku_ast** first, hoku_ast* second)
{
	hoku_ast* head = *first;
	second->parent = head->parent;
	while (head->relations->next_sibling != NULL)
	{
		head = head->relations->next_sibling;
	}
	
	second->parent = (*first)->parent;
	head->relations->next_sibling = second;
	return 0;
}

int hoku_ast_append_child(hoku_ast** parent, hoku_ast* child)
{
	hoku_ast* head = *parent;
	child->parent = *parent;
	
	while (head->relations->next_child != NULL)
	{
		head = head->relations->next_child;
	}
	head->relations->next_child = child;

	// hoku_ast* shead = child->relations->next_sibling;
	// while (shead != NULL)
	// {
	// 	shead->parent = (*parent);
	// 	shead = shead->relations->next_sibling;
	// }

	return 0;
}

int hoku_ast_cond_init(hoku_ast_condition** cond, hoku_ast_func_call* call)
{
	hoku_ast_condition* init = malloc(sizeof(hoku_ast_condition));
	if (init == NULL) return -1;

	init->not = false;
	init->call = call;
	*cond = init;
	return 0;
}

int hoku_ast_loop_init(hoku_ast_loop** loop, char* name, char* list_name)
{
	hoku_ast_loop* init = malloc(sizeof(hoku_ast_loop));
	if (init == NULL) return -1;
	init->name = strdup(name);
	if (init->name == NULL)
	{
		free(init);
		return -1;
	}

	init->list_name = strdup(list_name);
	if (init->list_name == NULL)
	{
		free(init);
		return -1;
	}

	*loop = init;
	return 0;
}

int hoku_ast_init(hoku_ast** component, char* type)
{
	hoku_ast* init = malloc(sizeof(hoku_ast));
	if (init == NULL) return -1;

	init->type = strdup(type);
	if (init->type == NULL)
	{
		free(init);
		return -1;
	}

	if (hoku_ast_props_init(&init->props) == -1)
	{
		free(init->type);
		free(init);
		return -1;
	}

	if (hoku_ast_events_init(&init->events) == -1)
	{
		hashmap_free(init->props);
		free(init->type);
		free(init);
		return -1;
	}

	init->child_len = 0;
	init->id = NULL;
	init->error = NULL;
	init->styles = NULL;
	init->style_list = NULL;
	init->class_list = NULL;
	init->has_slot = false;
	init->cond = NULL;
	init->loop = NULL;
	init->parent = NULL;
	init->relations = malloc(sizeof(hoku_ast_list));
	init->relations->next_child = NULL;
	init->relations->next_sibling = NULL;
	init->else_relations = NULL;
	init->else_active = false;
	init->is_root = false;
	*component = init;

	return 0;
}

int hoku_ast_set_error(hoku_ast* ast, char* error,  TSNode node, char* tag)
{
	char copy[600];
	TSPoint start = ts_node_start_point(node);
	sprintf(copy, "Error at row: %d col: %d - %s, got: \"%s\"\n", start.row, start.column, error, tag);
	ast->error = strdup(copy);
	if (ast->error == NULL) return -1;
	return 0;
}

hoku_ast* hoku_errored_ast(hoku_ast* ast)
{
	if (ast->error != NULL) return ast;
	
	hoku_ast* child = ast->relations->next_child;
	if (child != NULL)
	{
		hoku_ast* errored = hoku_errored_ast(child);
		if (errored != NULL) return errored;
	}

	hoku_ast* sibling = ast->relations->next_sibling;
	if (sibling != NULL)
	{		
		hoku_ast* errored = hoku_errored_ast(sibling);
		if (errored != NULL) return errored;
	}

	return NULL;
}

void hoku_ast_list_free(hoku_ast_list* list)
{
  if (list->next_sibling)
  {
    hoku_ast_free(list->next_sibling);
  }

  if (list->next_child)
  {
    hoku_ast_free(list->next_child);
  }

  free(list);
}

void hoku_ast_free(hoku_ast* component)
{
	if (component->styles) hoku_style_free(component->styles);
	hoku_ast_class_list_free(component->style_list);
  hoku_ast_class_list_free(component->class_list);
	hashmap_free(component->props);
	hashmap_free(component->events);
	free(component->type);
	free(component->id);

	if (component->cond) 
	{
		hoku_ast_func_call_free(component->cond->call);
		free(component->cond);
	}

	if (component->loop)
	{
		free(component->loop->list_name);
		free(component->loop->name);
		free(component->loop);		
	}

	hoku_ast_list_free(component->relations);
	if (component->else_relations) hoku_ast_list_free(component->else_relations);
	free(component);
}
#endif
