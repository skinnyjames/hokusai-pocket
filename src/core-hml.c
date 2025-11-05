#ifndef HOKU_CORE_HML
#define HOKU_CORE_HML

#include "core-hml.h"

char* hoku_get_substr(char* template, int idx, int len)
{
	char* init = malloc(sizeof(char) * (len + 1));
	if (init == NULL) return NULL;

	memcpy(init, template + idx, len);
	init[len] = '\0';
	return init;
}

char* hoku_get_tag(TSNode tag, char* template)
{
	uint32_t start =  ts_node_start_byte(tag);
	uint32_t end = ts_node_end_byte(tag);
	return hoku_get_substr(template, start, end - start);
}

void hoku_debug(TSNode node, char* template)
{
	char* ntype = ts_node_type(node);
	char* val = hoku_get_tag(node, template);

	printf("[type: %s] ->\n%s\n", ntype, val);
}

void hoku_dump(hoku_ast* c, int level)
{
	size_t count = hashmap_count(c->props);
	printf("%*s%s", (int)((level) * 2), "", c->type);
	if (c->id != NULL) printf("#%s", c->id);

	hoku_ast_class_list* head = c->class_list;
	while (head != NULL)
	{
		printf(".%s", head->name);
		head = head->next;
	}

	printf(" [%zu]", hashmap_count(c->props) + hashmap_count(c->events));
	if (c->loop != NULL)
	{
		printf(" (loop) ");
	}

	if (c->cond != NULL)
	{
		printf(" (condition) ");
	}	

	printf("\n");

	size_t iter = 0;
	size_t eiter = 0;
	void *item;

	while (hashmap_iter(c->props, &iter, &item)) {
		hoku_ast_prop* p = (hoku_ast_prop*) item;
		hoku_ast_func_call* c = p->call;
		char* cname = c->function;
		int alen = c->args_len;

		printf("%*s prop (%s = %s(%d))\n", (int)((level) * 2), "", p->name, cname, alen);
	}

	while (hashmap_iter(c->events, &eiter, &item)) {
		hoku_ast_event* p = (hoku_ast_event*) item;
		hoku_ast_func_call* c = p->call;
		char* cname = c->function;
		int alen = c->args_len;

		printf("%*s event (%s = %s(%d))\n", (int)((level) * 2), "", p->name, cname, alen);
	}

	hoku_ast* child = c->relations->next_child;
	if (child != NULL)
	{
		hoku_dump(child, level + 1);
	}

	hoku_ast* sibling = c->relations->next_sibling;
	if (sibling != NULL)
	{
		hoku_dump(sibling, level);
	}

	if (c->else_relations != NULL)
	{
		hoku_dump(c->else_relations->next_child, level);
	}
	return;
}

hoku_ast_func_call* hoku_ast_walk_func(TSNode node, char* template, int level)
{
	TSNode nname = ts_node_child(node, 0);
	char* name = hoku_get_tag(nname, template);
	hoku_ast_func_call* init;
	hoku_ast_func_call_init(&init, name);
	free(name);

	TSNode arguments = ts_node_next_sibling(nname);
	
	if (!ts_node_is_null(arguments))
	{
		TSNode arg = ts_node_child(arguments, 0);

		while (!ts_node_is_null(arg))
		{
			if (init->args_len >= 9)
			{
				// printf("maxed args!\n");
				break;
			}
			char* str = hoku_get_tag(arg, template);
			init->strargs[init->args_len] = str;
			init->args_len++;
			arg = ts_node_next_sibling(arg);
		}
	}
	return init;
}

hoku_ast_event* hoku_ast_walk_event(TSNode node, char* template, int level)
{
	char* type = ts_node_type(node);
	TSNode nname = ts_node_child(node, 0);

	char* name = hoku_get_tag(nname, template);
	hoku_ast_event* init;
	hoku_ast_event_init(&init, name);
	free(name);

	// get value
	TSNode nvalue = ts_node_next_sibling(nname);
	hoku_ast_func_call* call = hoku_ast_walk_func(nvalue, template, level + 1);

	init->call = call;
	return init;
}

hoku_ast_prop* hoku_ast_walk_prop(TSNode node, char* template, int level)
{
	char* type = ts_node_type(node);
	bool computed = false;
	TSNode nname = ts_node_child(node, 0);

	if (strcmp(ts_node_type(nname), "computed") == 0)
	{
		computed = true;
		nname = ts_node_next_sibling(nname);
	}

	char* name = hoku_get_tag(nname, template);

	hoku_ast_prop* init;
	hoku_ast_prop_init(&init, name);
  free(name);
	init->computed = computed;

	// get value
	TSNode nvalue = ts_node_next_sibling(nname);
	hoku_ast_func_call* call = hoku_ast_walk_func(nvalue, template, level + 1);

	init->call = call;
	return init;
}

/**
Rules for the tree:
type element = element | prop | event

element 1
	tag_name -> on 1
	prop -> on 1
	event -> on 1
	element 2 -> child to 1, sibling to 3
	element 3 -> child to 1, sibling to 2
*/
hoku_ast* hoku_ast_walk_tree(TSNode node, char* template, int level)
{
	char* ntype = ts_node_type(node);
	if (ntype == NULL)
	{
		f_log(F_LOG_ERROR, "Node type is null!\n %s", template);
		return NULL;
	}

	if (strcmp(ntype, "name") == 0)
	{
		char* name = hoku_get_tag(node, template);
		if (name == NULL)
		{
			f_log(F_LOG_ERROR, "Node name is null!\n%s", template);
			return NULL;
		}
		hoku_ast* init;
		if (hoku_ast_init(&init, name) == -1)
		{
			f_log(F_LOG_ERROR, "Could not init ast for %s", name);
			return NULL;
		}

		free(name);
		int i = 0;

		TSNode sibling = ts_node_next_named_sibling(node);

		// a lateral walk across siblings
		// can be "attributes OR children"
		while (!ts_node_is_null(sibling))
		{
			i++;
			char* stype = ts_node_type(sibling);
			if (stype == NULL)
			{
				f_log(F_LOG_ERROR, "Sibling node type is null");
				return NULL;
			}

			if (strcmp(stype, "attributes") == 0)
			{
				f_log(F_LOG_FINE, "Processing attributes for %s", init->type);
				// process attributes
				TSNode attribute = ts_node_named_child(sibling, 0);
				while (!ts_node_is_null(attribute))
				{
					char* atype = ts_node_type(attribute);
					if (atype == NULL)
					{
						f_log(F_LOG_ERROR, "attribute type is null");
						return NULL;
					}
					if (strcmp(atype, "prop") == 0)
					{
						f_log(F_LOG_FINE, "Walking props");
						hoku_ast_prop* prop = hoku_ast_walk_prop(attribute, template, level + 1);
						if (prop == NULL)
						{
							f_log(F_LOG_ERROR, "Prop is null for attribute %s", attribute);
							return NULL;
						}
						if (hoku_ast_add_prop(init, prop) == -1)
						{
							f_log(F_LOG_ERROR, "Couldn't add prop %s to %s", prop->name, init->type);
							return NULL;
						}
					}
					else if (strcmp(atype, "event") == 0)
					{
						f_log(F_LOG_FINE, "Walking events");
						hoku_ast_event* event = hoku_ast_walk_event(attribute, template, level + 1);
						if (event == NULL)
						{
							f_log(F_LOG_ERROR, "Event is null for attribute %s", attribute);
							return NULL;
						}

						f_log(F_LOG_FINE, "Adding event %s to ast", event->name);
						if (hoku_ast_add_event(init, event) == -1)
						{
							f_log(F_LOG_ERROR, "Couldn't add event to %s", init->type);
							return NULL;
						}
					}
					else if (strcmp(atype, "style") == 0)
					{
						char* style_name = hoku_get_tag(attribute, template);
						if (style_name == NULL)
						{
							f_log(F_LOG_ERROR, "Style tag name is NULL");
							return NULL;
						}
						f_log(F_LOG_FINE, "prepending style name %s to ast", style_name);
						if (hoku_ast_style_list_prepend(init, style_name) != 0) return NULL;
						free(style_name);
					}
					else
					{
						hoku_ast_set_error(init, "Expecting `event` or `prop`", attribute, hoku_get_tag(attribute, template));
					}
					attribute = ts_node_next_named_sibling(attribute);
				}
			}
			else if (strcmp(stype, "selectors") == 0)
			{
				f_log(F_LOG_FINE, "Walking selectors");
				TSNode sel = ts_node_named_child(sibling, 0);
				while (!ts_node_is_null(sel))
				{	
					char* seltype = ts_node_type(sel);
					char* seltag = hoku_get_tag(sel, template);
					if (seltag == NULL)
					{
						f_log(F_LOG_ERROR, "selector tag is null!");
						return NULL;
					}

					if (strcmp(seltype, "id") == 0)
					{
						init->id = strdup(seltag);
						free(seltag);
					}
					else if (strcmp(seltype, "class") == 0)
					{
						hoku_ast_class_list_prepend(init, seltag);
						free(seltag);
					}

					f_log(F_LOG_FINE, "Getting next selector sibling");
					sel = ts_node_next_named_sibling(sel);
				}
			}
			else if (strcmp(stype, "children") == 0)
			{
				TSNode child;
				uint32_t child_count = ts_node_named_child_count(sibling);
				f_log(F_LOG_DEBUG, "Walking %u children", child_count);

				init->child_len = (int) child_count;
				hoku_ast* sinit = NULL;
				for (uint32_t i=0; i<child_count; i++)
				{
					child = ts_node_named_child(sibling, i);
					char* ctype = ts_node_type(child);
					f_log(F_LOG_FINE, "Child: %s %d", ctype, i);
					f_log(F_LOG_DEBUG, "Walking ast tree for %s (%d)", ctype, level);

					if(strcmp(ctype, "else_macro") != 0)
					{

						hoku_ast* cchild = hoku_ast_walk_tree(child, template, level + 1);
						if (cchild == NULL)
						{
							f_log(F_LOG_ERROR, "Ast child is NULL");
							return NULL;
						}

						if (sinit == NULL)
						{
							sinit = cchild;
						}
						else
						{
							f_log(F_LOG_FINE, "Appending sibling %s to %s", cchild->type, sinit->type);
							hoku_ast_append_sibling(&sinit, cchild);
						}
					}
				}

				f_log(F_LOG_WARN, "Appending child %s to %s", sinit->type, init->type);
				hoku_ast_append_child(&init, sinit);
			}

			sibling = ts_node_next_sibling(sibling);
		}

		f_log(F_LOG_DEBUG, "Returning ast %s", init->type);
		return init;
	}
	else if (strcmp(ntype, "element") == 0)
	{
		f_log(F_LOG_FINE, "Walking element tree");
		TSNode child = ts_node_child(node, 0);
		return hoku_ast_walk_tree(child, template, level + 1);
	}
	else if (strcmp(ntype, "children") == 0)
	{
		f_log(F_LOG_FINE, "Walking children tree");
		TSNode child = ts_node_child(node, 0);
		return hoku_ast_walk_tree(child, template, level + 1);
	}
	else if (strcmp(ntype, "for_macro") == 0)
	{
		TSNode child = ts_node_named_child(node, 0);
		char* name = hoku_get_tag(child, template);
		if (name == NULL)
		{
			f_log(F_LOG_ERROR, "for macro name is null!");
			return NULL;
		}

		TSNode sibling = ts_node_next_named_sibling(child);
		char* list_name = hoku_get_tag(sibling, template);
		if (list_name == NULL)
		{
			f_log(F_LOG_ERROR, "for macro list name is null!");
			return NULL;
		}

		hoku_ast_loop* loop;
		if (hoku_ast_loop_init(&loop, name, list_name) == -1)
		{
			f_log(F_LOG_ERROR, "Failed to initialize loop %s %s", name, list_name);
			return NULL;
		}

		free(name);
		free(list_name);

		TSNode children = ts_node_next_named_sibling(sibling);
		f_log(F_LOG_DEBUG, "Walking loop children");
		hoku_ast* ast = hoku_ast_walk_tree(children, template, level + 1);
		if (ast == NULL)
		{
			f_log(F_LOG_ERROR, "Loop ast is null");
			return NULL;
		}

		ast->loop = loop;

		return ast;
	}
	else if (strcmp(ntype, "if_macro") == 0)
	{
		f_log(F_LOG_DEBUG, "Handling if macro");
		TSNode child = ts_node_named_child(node, 0);
		hoku_ast_func_call* call = hoku_ast_walk_func(child, template, level);
		if (call == NULL)
		{
			f_log(F_LOG_ERROR, "Func call for if macro is null");
			return NULL;
		}

		hoku_ast_condition* cond;
		if (hoku_ast_cond_init(&cond, call) == -1)
		{
			f_log(F_LOG_ERROR, "Condition for if macro is null");
			return NULL;
		}

		TSNode ichildren = ts_node_next_named_sibling(child);

		hoku_ast* iast = hoku_ast_walk_tree(ichildren, template, level + 1);
		if (iast == NULL)
		{
			f_log(F_LOG_ERROR, "If macro children ast is null");
			return NULL;
		}

		f_log(F_LOG_FINE, "Walked if macro children");
		iast->cond = cond;

		TSNode echild = ts_node_next_named_sibling(node);
		if (!ts_node_is_null(echild))
		{	
			char* etype = ts_node_type(echild);

			if (strcmp(etype, "else_macro") == 0)
			{
				f_log(F_LOG_FINE, "Walking next else child");

				TSNode eechildren = ts_node_named_child(echild, 0);
				if (!ts_node_is_null(eechildren))
				{
					hoku_ast* oast = hoku_ast_walk_tree(eechildren, template, level + 1);
					if (oast == NULL)
					{
						f_log(F_LOG_ERROR, "Else cond children ast is null");
						return NULL;
					}

					iast->else_relations = malloc(sizeof(hoku_ast_list));
					if (iast->else_relations == NULL) return NULL;

					oast->parent = iast;
					iast->else_relations->next_child = oast;
					iast->else_relations->next_sibling = NULL;
				}
			}	
		}
		else
		{
			f_log(F_LOG_WARN, "If macro has no else children");
		}
		return iast;
	}
	else if (strcmp(ntype, "for_if_macro") == 0)
	{
		f_log(F_LOG_DEBUG, "Handling for/if macro");
		TSNode child = ts_node_named_child(node, 0);
		char* name = hoku_get_tag(child, template);

		TSNode sibling = ts_node_next_named_sibling(child);
		char* list_name = hoku_get_tag(sibling, template);
		
		TSNode if_func = ts_node_next_named_sibling(sibling);
		hoku_ast_func_call* call = hoku_ast_walk_func(if_func, template, level);

		hoku_ast_condition* cond;
		if (hoku_ast_cond_init(&cond, call) == -1)
		{
			return NULL;
		}

		hoku_ast_loop* loop;
		if (hoku_ast_loop_init(&loop, name, list_name) == -1)
		{
			return NULL;
		}

    free(name);
    free(list_name);
		TSNode children = ts_node_next_named_sibling(if_func);
		hoku_ast* ast = hoku_ast_walk_tree(children, template, level + 1);
		ast->loop = loop;
		ast->cond = cond;

		TSNode echild = ts_node_next_named_sibling(node);

		if (!ts_node_is_null(echild))
		{	
			char* etype = ts_node_type(echild);

			if (strcmp(etype, "else_macro") == 0)
			{
				TSNode eechildren = ts_node_named_child(echild, 0);
				hoku_ast* oast = hoku_ast_walk_tree(eechildren, template, level + 1);
				ast->else_relations = malloc(sizeof(hoku_ast_list));
				if (ast->else_relations == NULL) return NULL;

				oast->parent = ast;
				ast->else_relations->next_child = oast;
				ast->else_relations->next_sibling = NULL;
			}
		}

		return ast;
	}
	else
	{
		f_log(F_LOG_WARN, "Unsupported type %s", ntype);
		return NULL;
	}
}

hoku_style_attribute* hoku_walk_style_attributes(TSNode node, char* template)
{
	f_log(F_LOG_DEBUG, "walking attrs\n");
	TSNode attribute_node = ts_node_named_child(node, 0);
	hoku_style_attribute* top = NULL;

	while (!ts_node_is_null(attribute_node))
	{
		TSNode attribute_name_node = ts_node_named_child(attribute_node, 0);
		char* attribute_name = hoku_get_tag(attribute_name_node, template);
		TSNode value_node;
		value_node = ts_node_next_named_sibling(attribute_name_node);
		char* value_node_type;
		value_node_type = ts_node_type(value_node);

		if (value_node_type == NULL || attribute_name == NULL)
		{
			return NULL;
		}

		enum HOKU_STYLE_TYPE type;
		char* value = NULL;
		char* function_name = NULL;

		if (strcmp(value_node_type, "style_int") == 0)
		{
			type = HOKU_STYLE_TYPE_INT;
			value = hoku_get_tag(value_node, template);
			
		}
		else if (strcmp(value_node_type, "style_float") == 0)
		{
			type = HOKU_STYLE_TYPE_FLOAT;
			value = hoku_get_tag(value_node, template);
		}
		else if (strcmp(value_node_type, "style_bool") == 0)
		{
			type = HOKU_STYLE_TYPE_BOOL;
			value = hoku_get_tag(value_node, template);

		}
		else if (strcmp(value_node_type, "style_string") == 0)
		{
			type = HOKU_STYLE_TYPE_STRING;
			value = hoku_get_tag(value_node, template);

		}
		else if (strcmp(value_node_type, "style_func") == 0)
		{
			type = HOKU_STYLE_TYPE_FUNC;
			TSNode func_name_node = ts_node_named_child(value_node, 0);

			function_name = hoku_get_tag(func_name_node, template);

			TSNode func_value_node = ts_node_next_named_sibling(func_name_node);
			value = hoku_get_tag(func_value_node, template);
		}

		hoku_style_attribute* attribute;
		hoku_style_attribute_init(&attribute, attribute_name, value, type);
		if (attribute == NULL) return NULL;

		if (function_name)
		{
			// printf("setting func name!\n");
			attribute->function_name = strdup(function_name);
			if (attribute->function_name == NULL) return NULL;
			free(function_name);
			// printf("fter set func name\n");
		}

		free(attribute_name);
		free(value);

		// printf("after free!\n");

		if (top == NULL)
		{
			top = attribute;
		}
		else
		{
			// printf("append!\n %p, %p\n", top, attribute);
			hoku_style_attribute_append(top, attribute);
			// printf("after append\n");
		}

		attribute_node = ts_node_next_named_sibling(attribute_node);
	}

	return top;
}

hoku_style* hoku_walk_style_template(TSNode node, char* template)
{
	TSNode style_node = ts_node_named_child(node, 0);
	hoku_style* top = NULL;

	while (!ts_node_is_null(style_node))
	{
		TSNode style_name_node = ts_node_named_child(style_node, 0);
		char* style_name = hoku_get_tag(style_name_node, template);
		hoku_style* style;
		hoku_style_init(&style, style_name);
		free(style_name);

		if (style == NULL) return NULL;

		char* event_name;
		TSNode style_children_node = ts_node_next_named_sibling(style_name_node);
		if (strcmp(ts_node_type(style_children_node), "event_name") == 0)
		{
			event_name = hoku_get_tag(style_children_node, template);
			style_children_node = ts_node_next_named_sibling(style_children_node);
			style->event_name = strdup(event_name);
			free(event_name);
		}


		// printf("walking attributes!\n");
		hoku_style_attribute* attributes = hoku_walk_style_attributes(style_children_node, template);
		// printf("after walk attributes!\n");
		if (attributes == NULL) return NULL;
		style->attributes = attributes;

		if (top == NULL)
		{
			top = style;
		}
		else
		{
			hoku_style_append(top, style);
		}

		style_node = ts_node_next_named_sibling(style_node);
	}

	return top;
}

int hoku_style_from_template(hoku_style** out, char* template)
{
	TSParser* parser = ts_parser_new();
	if (parser == NULL) return -1;

	ts_parser_set_language(parser, tree_sitter_hml());
	TSTree* tree = ts_parser_parse_string(parser, NULL, template, strlen(template));

	f_log(F_LOG_DEBUG, "Done parsing style!");
	if (tree == NULL)
	{
		ts_parser_delete(parser);
		return -1;
	}

	TSNode document = ts_tree_root_node(tree);
	if (strcmp(ts_node_type(document), "document") != 0)
	{
		ts_tree_delete(tree);
		ts_parser_delete(parser);

		return -1;
	}

	TSNode templ = ts_node_named_child(document, 0);
	if (strcmp(ts_node_type(templ), "style_template") != 0)
	{
		ts_tree_delete(tree);
		ts_parser_delete(parser);

		return -1;
	}

	f_log(F_LOG_DEBUG, "Walking style!");
	hoku_style* style = hoku_walk_style_template(templ, template);
	f_log(F_LOG_DEBUG, "Done walking style!");
	// printf("after walk style!\n");
	if (style == NULL)
	{
		ts_tree_delete(tree);
		ts_parser_delete(parser);

		return -1;
	}

	ts_tree_delete(tree);
	ts_parser_delete(parser);
	*out = style;
	return 0;
}

int hoku_ast_from_template(hoku_ast** out, char* type, char* template)
{
	hoku_ast* init;
	if (hoku_ast_init(&init, type) == -1)
	{
		f_log(F_LOG_ERROR, "AST initialization failed.");
		return -1;
	}

	hoku_style* style = NULL;

	f_log(F_LOG_FINE, "Initializing parser.");
	TSParser* parser = ts_parser_new();
	if (parser == NULL)
	{
		f_log(F_LOG_ERROR, "Parser initialization failed.");
		free(init);
		return -1;
	}

	f_log(F_LOG_FINE, "Parsing document.");
	ts_parser_set_language(parser, tree_sitter_hml());
	TSTree* tree = ts_parser_parse_string(parser, NULL, template, strlen(template));
	if (tree == NULL)
	{
		f_log(F_LOG_ERROR, "TS Parser tree is NULL.");
		ts_parser_delete(parser);
		free(init);
		return -1;
	}

	f_log(F_LOG_FINE, "Getting tree root node.");
	TSNode document = ts_tree_root_node(tree);
	if (strcmp(ts_node_type(document), "document") != 0)
	{
		hoku_ast_set_error(init, "Expecting document (starts with [template])", document, hoku_get_tag(document, template));
		*out = init;
		return 0;
	}

	f_log(F_LOG_FINE, "Getting document template (first child)");
	TSNode templ = ts_node_named_child(document, 0);
	if (strcmp(ts_node_type(templ), "template") != 0 && strcmp(ts_node_type(templ), "style_template") != 0)
	{
		f_log(F_LOG_DEBUG, "Document not expected.");
		hoku_ast_set_error(init, "Expecting template", templ, hoku_get_tag(templ, template));
		*out = init;
		return 0;
	}

	f_log(F_LOG_FINE, "Checking style template");
	if (strcmp(ts_node_type(templ), "style_template") == 0)
	{
		f_log(F_LOG_DEBUG, "Walking style template.");
		style = hoku_walk_style_template(templ, template);
		templ = ts_node_next_named_sibling(templ);

		if (ts_node_is_null(templ) || strcmp(ts_node_type(templ), "template") != 0)
		{
			hoku_ast_set_error(init, "Expecting template, got only style template", templ, "ERROR");
			*out = init;
			return 0;
		}
	}
	
	TSNode child = ts_node_named_child(templ, 0);
	hoku_ast* roots = NULL;
	char* ntype = ts_node_type(child);
	f_log(F_LOG_FINE, "init vars, %p, %p", child, ntype);

	f_log(F_LOG_DEBUG, "Walking template tree for");
	while (!ts_node_is_null(child))
	{
		ntype = ts_node_type(child);

		if (strcmp(ntype, "else_macro") != 0)
		{
			hoku_ast* children;
			children = hoku_ast_walk_tree(child, template, 0);

			f_log(F_LOG_DEBUG, "Walked template children, %p", children);

			if (children == NULL) 
			{
				f_log(F_LOG_WARN, "Children are NULL");
				char* ntype = ts_node_type(child);
			}

			if (roots == NULL)
			{
				f_log(F_LOG_DEBUG, "Setting roots to children");
				roots = children;
			}
			else
			{
				f_log(F_LOG_FINE, "Appending children as siblings to root ast.");
				hoku_ast_append_sibling(&roots, children);
				f_log(F_LOG_FINE, "Setting parents of root children.");
				hoku_ast* rhead = roots;
				while (rhead != NULL)
				{
					rhead->parent = init;
					rhead = rhead->relations->next_sibling;
				}

			}
		}

		f_log(F_LOG_DEBUG, "Assigning next sibling.");
		child = ts_node_next_named_sibling(child);
	}

	f_log(F_LOG_DEBUG, "Appending root ast to init ast");
	hoku_ast_append_child(&init, roots);

	templ = ts_node_next_named_sibling(templ);
	if (!ts_node_is_null(templ) && strcmp(ts_node_type(templ), "style_template") == 0)
	{
		f_log(F_LOG_FINE, "walking style template\n");
		style = hoku_walk_style_template(templ, template);
	}

	init->styles = style;

	f_log(F_LOG_FINE, "delete tree");
	ts_tree_delete(tree);
	f_log(F_LOG_FINE, "delete parser");
	ts_parser_delete(parser);
	f_log(F_LOG_FINE, "All done, exporting %p", init);
	
	init->is_root = true;
	*out = init;
	return 0;
}
#endif
