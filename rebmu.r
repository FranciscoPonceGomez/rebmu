REBOL [
	Title: "Rebmu Dialect"
	Description: {Rebol dialect designed for participating in "Code Golf" challenges}
	
	Author: "Hostile Fork"
	Home: http://hostilefork.com/rebmu/
	License: mit
	
	Date: 10-Jan-2010
	Version: 0.1.0
	
	; Header conventions: http://www.rebol.org/one-click-submission-help.r
	File: %rebmu.r
	Type: dialect
	Level: advanced
	
	Usage: { The Rebmu language is a dialect of Rebol which uses some unusual tricks to
	achieve smaller character counts in source code.  The goal is to make it easier to
	participate in programming challenges which attempt to achieve a given task in as few
	characters as possible.
	
	One of the main ways this is achieved is to use alternations of uppercase and lowercase
	letters to compress words in the source.  This is central to the Rebmu concept of
	"mushing" and "unmushing":

		>> unmush [abcDEFghi]
		== [abc def ghi]

	The choice to start a sequence of alternations with an uppercase letter is used as a special
	indicator of wishing the first element in the sequence to be interpreted as a set-word:
	
		>> unmush [ABCdefGHI]
		== [abc: def ghi]
	
	This applies to elements of paths as well.  Each path break presents an opportunity for
	a new alternation sequence, hence a set-word split:
	
		>> unmush [ABCdef/GHI]    
		== [abc: def/ghi:]

		>> unmush [ABCdef/ghi]
		== [abc: def/ghi]

	An exception to this rule are literal words, where since you cannot make a literal
	set-word in source the purpose is to allow you to indicate whether the *next* word
	should be a set-word.  Choosing lowercase for the lit word will mean the next word
	is a set-word, while uppercase means it will not be:
	
		>> unmush [abc'DEFghi]
		== [abc 'def ghi]

		>> unmush [abc'defGHI] 
		== [abc 'def ghi:]
		
	Despite being a little bit "silly" (as Code Golf is sort of silly), there is
	a serious side to the design.  Rebmu is a genuine dialect... meaning that it
	uses the Rebol data format and thus relegates most parsing--such as parentheses
	and block matches.  
	
	Also, Rebmu is a superset of Rebol, so any Rebol code should be able to be used
	safely.  That's because despite several shorthands defined for common Rebol operations 
	(even as far as I for IF) the functions are true to their Rebol bretheren across 
	all inputs that Rebol accepts.  [Current exceptions to this are q and ?]
	
	Rebmu programs get their own execution context.  They will unmush their input,
	set up the environment of abbreviated routines, and run the code:
	
		>> rebmu [w"Hello World"]
		Hello World
	    
	You can also pass in named arguments via a block:
	
		>> rebmu/args [wSwM] [s: "Hello" m: "World"]
		Hello
		World
		
	Or you can pass in a block which does not begin with a set-word and that block will
	appear in the execution context as the variable a:
	
		>> rebmu/args [wA] [1 2 3]
		1 2 3
	
	You can run your Rebmu program and let it set some values in its environment, such
	as defining functions you might want to call.  Using the /inject refinement you can
	run some code after the program has executed but before the environment is disposed.
	
	For instance, the following example uses a shorthand format for defining a function that 
	triples a number and saving it in t:
	
		>> rebmu [T|[z*3]]
	
	But defining the function isn't enough to call it, so if you had wanted to do that you
	could have said:
	
		>> rebmu/inject [T|[z*3]] [wT10]
		30
		
	The injected code is just shorthand for [w t 10], where w is writeout-mu, a variation of
	Rebol's print.
	}
	
    History: [
        0.1.0 [10-Jan-2010 {Sketchy prototype written to cover only the
        Roman Numeral example I worked through when coming up with the
        idea.  So very incomplete, more a proof of concept.} "Fork"]
    ]
]

; Load the library of xxx-mu functions
do %mulibrary.r

remap-datatype: func [type [word!] shorter [word!]] [
	bind reduce [
		to-set-word rejoin [to-string shorter "!"] to-word rejoin [to-string type "!"]
		to-set-word rejoin [to-string shorter "?"] get rejoin ["'" to-string type "?"]
	] bind? 'system
	[] ; above isn't working, why not?
]

rebmu-context: compose [
	;-------------------------------------------------------------------------------------
	; SINGLE CHARACTER DEFINITIONS
	; For the values (e.g. s the empty string) it is expected that you will overwrite them
	; during the course of your program.  It's a little less customary to redefine the
	; functions like I for IF, although you may do so if you feel the need.  They will
	; still be available in a two-character variation.
	;-------------------------------------------------------------------------------------
	
	~: :inversion-mu
	|: :z| ; a zfunc generator by default (not to be confused with a|, which is an afunct)		
	.: none ; what should dot be?

	?: none ; not help what should it be
	
	; ^ is copy because it breaks symbols; a^b becomes a^ b but A^b bcomes a: ^ b
	; This means that it is verbose to reset the a^ type symbols due to forcing a space
	^: :CY 
	
	a: copy [] ; "array"
	b: to-char 0 ; "byte"
	c: #"A" ; "char"
	d: #"0" ; "digit"
	e: :EI ; "either"
	f: :FN ; "function"
	g: copy [] ; "group"
	h: :helpful-mu ; "helpful" constant declaration tool
	i: :IF ; "if"
	j: 0
	k: 0
	l: :LO ; "loop"
	m: copy "" ; "message"
	n: 1
	o: :OR ; "or"
	p: :PO ; "poke"
	
	; Q is tricky.  I've tried not to violate the meanings of any existing Rebol functions,
	; but it seems like a waste to have an interpreter-only function like "quit" be taking
	; up such a short symbol by default.  I feel the same way about ? being help.  This
	; is an issue I have with Rebol's default definitions -Fork
	q: :quoth-mu ; "quoth" e.g. qAB => "AB" and qA => #"A"
	
	r: :RI ; "readin"
	s: copy "" ; "string"
	t: :TO ; note that to can use example types, e.g. t "foo" 10 is "10"!
	u: :UT ; "until"
	v: copy [] ; "vector"
	w: :WO ; "writeout"
	; decimal! values starting at 0.0 (common mathematical variables)
	x: 0.0
	y: 0.0 
	z: 0.0

	;-------------------------------------------------------------------------------------
	; WHAT REBOL DEFINES BY DEFAULT IN THE TWO-CHARACTER SPACE
	;-------------------------------------------------------------------------------------	
	
	; Very Reasonable Use of English Words
	
	; TO 	to conversion
	; OR	or operator
	; IN	word or block in the object's context
	; IF	conditional if
	; DO	evaluates a block, file, url, function word
	; AT	returns the series at the specified index

	; Reasonable use of Symbolic Operators

	; ++ 	increment and return previous value
	; -- 	decrement and return previous value
	; ??	Debug print a word, path, block or such
	; >=	true if the first value is greater than the second
	; <>	true if the values are not equal
	; <=	true if the first value is less than the second
	; =?	true if the values are identical
	; //	remainder of first value divided by second
	; **	first number raised to the power of the second
	; !=	true if the values are not equal

	; Questionable shorthands for terms defined elsewhere. Considering how many things do
	; not have shorthands by default...what metric proved that *these four* were the
	; ideal things to abbreviate? 
	
	; SP 	alias for SPACE
	; RM	alias for DELETE
	; DP	alias for DELTA-PROFILE
	; DT	alias for DELTA-TIME

	; These are shell commands and it seems like there would be many more.  Could there
	; be a shell dialect, in which for instance issue values (#foo) could be environment
	; variables, or something like that?  It seems many other things would be nice, like
	; pushing directories or popping them, moving files from one place to another, etc.	
	
	; LS	print contents of a directory
	; CD	change directory

	; Another abbreviation that seems better to leave out
	; DS	temporary stack debug
	
	;-------------------------------------------------------------------------------------
	; DATATYPE SHORTHANDS (2-3 CHARS)
	; I've tried to give the 26 most popular data types a two-character name with an
	; exclamation point.  This is up for debate.  We may say that if two types have the 
	; same starting letter then the less popular one in code golf gets a three-character
	; code, as these will probably occur infrequently in Code Golf.
	;-------------------------------------------------------------------------------------	

	(remap-datatype 'email 'a) ; "address"
	(remap-datatype 'block 'b)
	(remap-datatype 'char 'c)
	(remap-datatype 'decimal 'd)
	(remap-datatype 'error 'e)
	(remap-datatype 'function 'f)
	(remap-datatype 'get-word 'g)
	(remap-datatype 'paren 'h) ; "parentHeses" :)
	(remap-datatype 'integer 'i)
	(remap-datatype 'pair 'j) ; "joined"
	(remap-datatype 'closure 'k) ; "klosure"
	(remap-datatype 'logic 'l) 
	(remap-datatype 'map 'm)
	(remap-datatype 'none 'n)
	(remap-datatype 'object 'o)
	(remap-datatype 'path 'p)
	(remap-datatype 'lit-word 'q) ; "quoted-word"
	(remap-datatype 'refinement 'r)
	(remap-datatype 'string 's)
	(remap-datatype 'time 't)
	(remap-datatype 'tuple 'u) ; "tUple"
	(remap-datatype 'file 'v) ; "vile" (use a thick accent) :)
	(remap-datatype 'word 'w)
	(remap-datatype 'tag 'x) ; "Xml" 
	(remap-datatype 'money 'y) ; "moneY"
	(remap-datatype 'binary 'z) ; Z for... um... uh...

	;-------------------------------------------------------------------------------------	
	; TYPE CONVERSION
	;-------------------------------------------------------------------------------------	
	; TODO: make these automatically along with the datatype shorthands
	
	TW: :to-word-mu
	TS: :to-string-mu
	TB: :to-block

	;-------------------------------------------------------------------------------------
	; CONDITIONALS
	;-------------------------------------------------------------------------------------	
	
	IF: :if-mu
	EI: :either-mu
	EL: :either-lesser?-mu
	IL: :if-lesser?-mu
	IG: :if-greater?-mu

	;-------------------------------------------------------------------------------------	
	; LOOPING CONSTRUCTS
	;-------------------------------------------------------------------------------------	

	FE: :foreach
	LO: :loop
	WH: :while
	CN: :continue
	UT: :until
	RT: :repeat

	;-------------------------------------------------------------------------------------	
	; DEFINING FUNCTIONS
	;-------------------------------------------------------------------------------------	

	FN: :funct
	FC: :func
	a|: :afunct-mu
	b|: :bfunct-mu
	c|: :cfunct-mu
	d|: :dfunct-mu
	; TODO: Write generator? 
	w|: :wfunc-mu	
	x|: :xfunc-mu
	y|: :yfunc-mu
	z|: :zfunc-mu
	
	;-------------------------------------------------------------------------------------
	; SERIES OPERATIONS
	;-------------------------------------------------------------------------------------	

	PO: :poke
	AP: :append
	AO: rebmu-wrap 'append/only [] ; very useful
	IN: :insert
	TK: :take
	MN: :minimum-of
	MX: :maximum-of
	RP: :repend
	SE: :select
	FX: :index?-find-mu
	OX: :offset?
	IX: :index?
	RV: :reverse
	RA: rebmu-wrap 'replace/all []
	
	;-------------------------------------------------------------------------------------	
	; METAPROGRAMMING
	;-------------------------------------------------------------------------------------	

	CO: rebmu-wrap 'compose/deep [] ; default to deep composition	
	ML: :mold
	DR: :rebmu ; "Do Rebmu"

	;-------------------------------------------------------------------------------------	
	; MATH OPERATIONS
	;-------------------------------------------------------------------------------------	

	MP: :multiply
	DV: :divide

	;-------------------------------------------------------------------------------------	
	; INPUT/OUTPUT
	;-------------------------------------------------------------------------------------	
	
	RD: :read
	WR: :write
	PR: :print
	RI: :readin-mu
	WO: :writeout-mu
	
	;-------------------------------------------------------------------------------------	
	; CONSTRUCTION FUNCTIONS
	; Although a caret in isolation means "copy", a letter and a caret means "factory"
	;-------------------------------------------------------------------------------------	

	CY: rebmu-wrap 'copy/part/deep [] ; default to a deep copy
	CP: rebmu-wrap 'copy/part [] 
	a^: :array
	i^: :make-integer-mu
	m^: :make-matrix-mu
	s^: :make-string-mu

	;-------------------------------------------------------------------------------------		
	; MISC
	;-------------------------------------------------------------------------------------	
	
	AL: :also
]

upper: charset [#"A" - #"Z"]
lower: charset [#"a" - #"z"]
digit: charset [#"0" - #"9" #"."]
separatorsymbol: charset [#"/" #":"]
headsymbol: charset [#"'"]
tailsymbol: charset [#"!" #"?" #"^^" #"|"]
isolatedsymbol: charset [#"+" #"-" #"~"]

type-of-char: func [c [char!]] [
	if upper/(c) [
		return 'upper
	]
	if lower/(c) [
		return 'lower
	]
	if digit/(c) [
		return 'digit
	]
	if separatorsymbol/(c) [
		; no spacing but separates
		return 'separatorsymbol
	]
	if headsymbol/(c) [
		; space before if not at start
		return 'headsymbol
	]
	if tailsymbol/(c) [
		; space afterwards but not before (we use ~ for not)
		return 'tailsymbol
	]
	if isolatedsymbol/(c) [
		; space before and after unless there's a run of identical ones
		return 'isolatedsymbol
	]
	; caseless things are neither upper nor lowercase, they stay stuck
	; with whatever is going; so most unicode characters fall into this
	; category.
	return 'caseless
]

; Simplistic routine, open to improvements.  Use PARSE dialect instead?
; IF unmush returns a block! (and you didn't pass in a block!) then it is a sequence
; There may be a better convention
unmush: funct [value /deep] [
	case [
		(any-word? :value) or (any-path? :value) [
			pos: str: mold :value
			thisType: type-of-char first pos
		
			mergedSymbol: false
			thisIsSetWord: 'upper = thisType
			nextCanSetWord: found? find [headsymbol symbol tailsymbol] thisType
			while [not tail? next pos] [
				nextType: if not tail? next pos [type-of-char first next pos]
				
				comment [	
					print [
						"this:" first pos "next:" first next pos
						"thisType:" to-string thisType "nextType:" to-string nextType 
						"thisIsSetWord:" thisIsSetWord "nextCanSetWord:" nextCanSetWord
						"str:" str
					]
				]
		
				switch/default thisType [
					separatorsymbol [
						thisIsSetWord: 'upper = nextType
						nextCanSetWord: false
					]
					headsymbol [
						thisIsSetWord: false
						nextCanSetWord: 'upper <> nextType
					]
					tailsymbol [
						either thisIsSetWord [
							pos: insert pos ": "
						] [
							pos: back insert next pos space
						]
						thisIsSetWord: 'upper = nextType
						nextCanSetWord: true
					]
					isolatedsymbol [
						either (first pos) == (first next pos) [
							mergedSymbol: true
						] [
							if thisIsSetWord [
								pos: insert pos ":"
								either mergedSymbol [
									mergedSymbol: false
								] [
									pos: insert pos space
								]
							]
							pos: back insert next pos space
							thisIsSetWord: 'upper = nextType
							nextCanSetWord: false
						]
					]
				] [
					either ('digit = thisType) and found? find [#"x" #"X"] first next pos [
						; need special handling if it's an x because of pairs
						; want to support mushings like a10x20 as [a 10x20] not [a 10 x 20]
						; for the moment lie and say its a digit
						nextType: 'digit	
					] [
						if (thisType <> nextType) and none? find [separatorsymbol tailsymbol] nextType [
							if ('digit = thisType) or ('isolatedsymbol = thisType) [
								nextCanSetWord: true
							]
							if thisIsSetWord [
								pos: back insert next pos ":"
								thisIsSetWord: false
								nextCanSetWord: false
							]
							if nextCanSetWord [
								thisIsSetWord: 'upper = nextType
								nextCanSetWord: false
							]
							pos: back insert next pos space
						]
					]
				]
				pos: next pos
				thisType: nextType
			]
			if thisIsSetWord [
				either thisType = 'tailsymbol [
					pos: insert pos ": "
				] [
					pos: back insert next pos ":"
				]
			]
			load lowercase str
		] 
	
		any-block? :value [
			result: make type? :value copy []
			while [not tail? :value] [
				elem: first+ value
				unmushed: either deep [unmush/deep :elem] [unmush :elem]
				either (block? :unmushed) and (not block? :elem) [
					append result :unmushed
				] [
					append/only result :unmushed
				]
			]
			result
		]
		
		true: [
			:value
		]
	]
]

; The point of Rebmu is that programmers should be able to read and modify without using
; a compilation tool.  But for completeness, here is a mushing function.
; **UNDER CONSTRUCTION**
mush: funct [value /mixed /deep] [
	print "WARNING: Mushing is a work in progress, implementation incomplete."
	if any-block? value [
		result: make type? :value copy []
		isUppercase: none
		current: none
		foreach elem value [
			switch/default type?/word :elem [
				word! [
					either current [
						isUppercase: not isUppercase
						either isUppercase [
							append current uppercase to-string elem
						] [
							append current lowercase to-string elem
						]
					] [
						current: lowercase to-string elem
						isUppercase: false
					]
				]
				set-word! [
					either current [
						append result to-word current
						current: none
						append result elem
					] [
						current: uppercase to-string-mu elem ; spelling? behavior
						isUppercase: true
					]
				]
			] [
				if current [
					append result to-word current
					current: none
				]
				append/only result :elem
			]
		]
	]
	if current [
		append result to-word current
		current: none
	]
	result
]

; A rebmu wrapper lets you wrap a function or a refined version of a function
rebmu-wrap: funct [arg [word! path!] refinemap [block!]] [
	either word? arg [
		; need to use refinemap!
		:arg
	] [
		; need to write generalization of spec capture with reflect, e.g.
		; spec: reflect :arg 'spec 
		; just testing concept for the moment with a couple of cases though
		; so writing by hand
		switch arg [
			replace/all [
				func [target search value] [
					replace/all target search value
				]
			]
			compose/deep [
				func [value] [
					compose/deep value
				]
			] 
			copy/part/deep [
				func [value length] [
					copy/part/deep value length
				]
			]
			copy/part [
				func [value length] [
					copy/part value length
				]
			]
			append/only [
				func [series value] [
					append/only series value
				]
			]
		]
	]
]

rebmu: func [
	{Visit http://hostilefork.com/rebmu/}
	code [any-block! string!] "The Rebmu or Rebol code"
	/args arg [block! string!] {named Rebmu arguments [X10Y20] or implicit a: block [1"hello"2]}
	/stats "print out statistical information"
	/debug "output debug information"
	/env "return the runnable object plus environment, but don't execute main function"
	/inject injection [block! string!] "run some test code in the environment after main function"
	/local result elem obj
] [
	either string? code [
		if stats [
			print ["Original Rebmu string was:" length? code "characters."]
		]

		code: load code
	] [
		if stats [
			print ["NOTE: Pass in Rebmu as string, not a block, to get official character count."]
		]
	]
	
	if not block? code [
		code: to-block code
	]
	
	if stats [
		print ["Rebmu as mushed Rebol block molds to:" length? mold/only code "characters."]
	]

	code: unmush/deep code
	
	if stats [
		print ["Unmushed Rebmu molds to:" length? mold/only code "characters."]
	]

	if debug [
		print ["Executing: " mold code]
	]
	
	either inject [
		if string? injection [injection: load injection]
		if not block? injection [
			code: to-block injection
		]
		injection: unmush/deep injection
	] [
		injection: copy []
	]
	
	either args [
		if string? arg [args: load args]
		if not block? args [
			arg: to-block arg
		]
		arg: unmush/deep arg
		if not set-word? type? first arg [
			; implicitly assign to a if the block doesn't start with a set-word
			arg: compose/only [a: (arg)] 
		]
	] [
		arg: copy []
	]
	
	obj: object compose/deep [
		(rebmu-double-defaults) ; Generally, don't overwrite these in your Rebmu code
		(rebmu-single-defaults) ; Overwriting is okay here
		(arg) 
		main: func [] [(code)]
		injection: func [] [(injection)]
	] 
	either env [
		return obj 
	] [
		return also (do get in obj 'main) (do get in obj 'injection)
	]
]