module.exports = grammar({
	name: 'hml',
  extras: $ => [$.comment, /\s+/],
	externals: $ => [$._indent, $._dedent, $._newline, $.error_sentinel],
	
	rules: {
		document: $ => choice(
			seq($.template, $.style_template),
			seq($.style_template, $.template),
			$.template,
			$.style_template
		),
		
		comment: $ => seq(
			'#!',
			/.*/,
			'!#'
		),

		template: $ => seq(
			$._template_macro,
			$._element_body,
		),

		style_template: $ => seq(
			$._style_macro,
			repeat1(alias($._style_body, $.style))
		),

		_body: $ => choice(
			$._element_body,
			// $._macro_body,
		),

		element: $ => seq(
			alias($._word, $.name),
			optional($.selectors),
			optional(alias($._element_attributes, $.attributes)),
			optional(alias($._element_body, $.children)),
		),
		
		selectors: $ => choice(
			seq(
				$._element_id_selctor,
				repeat($._element_class_selector),
			),
			repeat1($._element_class_selector),
		),

		_element_body: $ => choice(
			seq(
				$._indent,
				repeat(
					prec.right(2, choice(
						seq(
							$.element,
							$._newline,
						),
						seq(
							$.for_if_macro,
							optional(seq($._newline, $.else_macro)),
							$._newline,
						),
						seq(
							$.for_macro,
							$._newline
						),
						seq(
							$.if_macro,
							optional(seq($._newline, $.else_macro)),
							$._newline
						),
					),
				)),
				prec.right(3, choice(
					$.element,
					seq($.if_macro, optional(seq($._newline, $.else_macro))),
					seq($.for_if_macro, optional(seq($._newline, $.else_macro))),
					$.for_macro
				)),
				optional(/ *\n\s*/),
				$._dedent,
			),
		),

		// _macro_body: $ => choice(
		// 	choice(
		// 		seq(
		// 			$._indent,
		// 			$.for_macro,
		// 			repeat(seq($._newline, choice($.if_macro, $.for_macro, $.element))),
		// 			optional(/ *\n\s*/),
		// 			$._dedent,
		// 		),
		// 		seq(
		// 			$._indent,
		// 			$.if_macro,
		// 			optional(seq($._newline, $.else_macro)),
		// 			repeat(seq($._newline, choice($.if_macro, $.for_macro, $.element))),
		// 			optional(/ *\n\s*/),
		// 			$._dedent,
		// 		),
		// 	)
		// ),

		_element_attributes: $ => seq(
			$._attributes_start,
			repeat(seq(choice($.prop, $.event, seq($._spread_punctuation, alias($._spread, $.style))), optional($._comma))),
			$._attributes_end,
		),

		event: $ => seq(
			$._at,
			alias($._method, $.name),
			$._equal,
			$._quote,
			$.function,
			$._quote
		),

		prop: $ => seq(
			optional(alias($._colon, $.computed)),
			alias($._method, $.name),
			$._equal,
			$._quote,
			$.function,
			$._quote
		),

		function: $ => seq(
			alias(choice($._float, $._static_string), $.name),
			optional(alias($.function_args, $.args))
		),

		function_args: $ => seq(
			$._lparen,
			repeat(seq(alias($._word, $.arg), $._comma, /\s*/)),
			alias($._word, $.arg),
			$._rparen,
		),

		_element_id_selctor: $ => seq($._pound, alias($._word, $.id)),
		_element_class_selector: $ => seq($._dot, alias($._word, $.class)),

		_template_macro: $ => seq(
			$._macro_start,
			$._template_key,
			$._macro_end
		),

		_spread: $ => seq(
			alias($._method, $.name)
		),

		_style_macro: $ => seq(
			$._macro_start,
			$._style_key,
			$._macro_end
		),

		_style_body: $ => seq(
			alias($._word, $.name),
			optional(seq($._at, alias($._method, $.event_name))),
			$._attributes_start,
			alias(repeat(alias($._style_element, $.element)), $.children),
			$._attributes_end
		),

		_style_element: $ => seq(
			optional(/\s+/),
			alias($._method, $.name),
			$._colon,
			optional(/\s+/),
			choice(
				$.style_float,
				$.style_int,
				$.style_bool,
				$.style_func,
				seq($._quote, alias($._any, $.style_string), $._quote),
			),
			$._semi,
			optional(/\s*/)
		),

		// style_string: $ => seq($._quote, alias($._method, $.value), $._quote),
		style_float: $ => $._float,
		style_int: $ => /[0-9]+/,
		style_bool: $ => /true|false/,
		style_func: $ => seq(
			alias($._method, $.function),
			$._lparen,
			alias($._any, $.value),
			$._rparen
		),

		for_macro: $ => seq(
			$._macro_start,
			$._for_key,
			$._equal,
			$._quote,
			alias($._method, $.name),
			"in",
			alias($._method, $.list_name),
			$._quote,
			$._macro_end,
			alias($._element_body, $.children)
		),

		for_if_macro: $ => seq(
			$._macro_start,
			$._for_key,
			$._equal,
			$._quote,
			alias($._method, $.name),
			"in",
			alias($._method, $.list_name),
			$._quote,
			$._macro_end,
			$._newline,
			$._macro_start,
			$._if_key,
			$._equal,
			$._quote,
			alias($.function, $.if_function),
			$._quote,
			$._macro_end,
			alias($._element_body, $.children)
		),

		if_macro: $ => seq(
			$._macro_start,
			$._if_key,
			$._equal,
			$._quote,
			$.function,
			$._quote,
			$._macro_end,
			alias($._element_body, $.children),
		),

		else_macro: $ => seq(
			$._macro_start,
			$._else_key,
			$._macro_end,
			alias($._element_body, $.children),
		),

		_spread_punctuation: $ => "...",
		_for_key: $ => "for",
		_if_key: $ => "if",
		_else_key: $ => "else",
		_template_key: $ => "template",
		_style_key: $ => "style",
		_any: $ => /[^\"\n\;\(\)]+/,
		_method: $ => /[A-Za-z][A-Za-z0-9\_]*/,
		_word: $ => /[A-Za-z][A-Za-z0-9_-]*/,
		_float: $ => /\d+\.\d+/,
		_static_string: $ => /[A-Za-z0-9_\-,\.]*/,
		_attributes_start: $ => / *\{/,
		_attributes_end: $ => /\} */,
		_macro_start: $ => "[",
		_macro_end: $ => "]",
		_lparen: $ => "(",
		_rparen: $ => ")",
		_lbrack: $ => "[",
		_rbrack: $ => "]",
		_comma: $ => ",",
		_semi: $ => /\;/,
		_colon: $ => /\:/,
		_equal: $ => "=",
		_pound: $ => "#",
		_quote: $ => "\"",
		_dot: $ => ".",
		_at: $ => "@",
	},
})