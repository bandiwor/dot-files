; === Литералы ===
(string) @string
(number) @number

; === Переменные и типы ===
; Подсвечиваем 'name' в объявлении $name: type
(variable_declaration name: (identifier) @variable)
(variable_declaration type: (type) @type)

; Подсвечиваем левую часть в присваивании name = value
(assignment_statement left: (identifier) @variable)

; === Функции ===
; Имя в определении: $foo()
(function_definition name: (identifier) @function)
; Имя при вызове: $foo()
(function_call name: (identifier) @function.call)
; Параметры
(parameter name: (identifier) @variable.parameter)
(parameter type: (type) @type)

; === Ключевые слова и Управляющие конструкции ===
"#" @keyword.conditional     ; if
"!#" @keyword.conditional    ; elif
"!" @keyword.conditional     ; else
"@" @keyword.repeat          ; while

; === Операторы и Пунктуация ===
; ["+" "-" "*" "/" "**" "==" "<" ">"] @operator
"=" @operator
"->" @operator

"$" @punctuation.special     ; Твой спецсимвол для переменных/функций
":" @punctuation.delimiter
"," @punctuation.delimiter
["(" ")" "{" "}"] @punctuation.bracket

