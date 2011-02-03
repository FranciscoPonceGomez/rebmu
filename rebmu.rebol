REBOL [
	Title: "Rebmu Dialect"
	Description: {Rebol dialect designed for participating in "Code Golf" 
	challenges}
	
	Author: "Hostile Fork"
	Home: http://hostilefork.com/rebmu/
	License: mit
	
	Date: 10-Jan-2010
	Version: 0.2.0
	
	; Header conventions: http://www.rebol.org/one-click-submission-help.r
	File: %rebmu.rebol
	Type: dialect
	Level: advanced
	
	Usage: { The Rebmu language is a dialect of Rebol which uses some 
	unusual tricks to achieve smaller character counts in source code.  
	The goal is to make it easier to participate in programming challenges 
	where the goal is to achieve a given task in as few characters as 
	possible.
	
	There is the obvious need to come up with abbreviations for long words 
	like WH instead of WHILE.  Rebol is particularly good at allowing one 
	to do this kind of thing within the language and without a 
	preprocessor.  But a more novel piece of trickery that Rebmu uses
	is the alternations of uppercase and lowercase letters to compress 
	words in the source.  This central to the Rebmu concept of "mushing" 
	and "unmushing":

		>> unmush [abcDEFghi]
		== [abc def ghi]

	The choice to start a sequence of alternations with an uppercase letter 
	is used as a special indicator of wishing the first element in the 
	sequence to be interpreted as a set-word:
	
		>> unmush [ABCdefGHI]
		== [abc: def ghi]
	
	This applies to elements of paths as well.  Each path break presents 
	an opportunity for a new alternation sequence, hence a set-word split:
	
		>> unmush [ABCdef/GHI]	  
		== [abc: def/ghi:]

		>> unmush [ABCdef/ghi]
		== [abc: def/ghi]

	An exception to this rule are literal words, where since you cannot 
	make a literal set-word in source the purpose is to allow you to 
	indicate whether the *next* word should be a set-word.  Choosing 
	lowercase for the lit word will mean the next word is a set-word, 
	while uppercase means it will not be:
	
		>> unmush [abc'DEFghi]
		== [abc 'def ghi]

		>> unmush [abc'defGHI] 
		== [abc 'def ghi:]
	
	Because symbols do not have a "case" they are handled specially.  
	Since Rebmu tries to be compatible with Rebol code (as long as it's
	all lowercase!) they generally act like lowercase letters, with a few 
	caveats:
	
		; lowercase run to another lowercase, will act lowercase
		[a+b] => [a+b]	

		; implied lowercase
		[+b] => [+b] 		

		; uppercase run to another uppercase, will act uppercase!
		[A+B] => [a+b:] 	

		; switching lower to upper, plus binds to the tail of first
		[a+B] => [a+ b] 	

		; switching upper to lower, plus lives on its own!
		[A+b] => [a: + b] 	
		
		; all one token
		[a++b] => [a++b] 	

		; as expected
		[A++B] => [a++b:] 	

		; surprise!  multiple symbols bind into their own token
		[a++B] => [a ++ b] 	

		; as above
		[A++b] => [A: ++ b] 
	
	The number of spaces and colons this can save on in Rebol code is 
	significant, and it is easy to read and write once the rules are 
	understood.  If you know Rebol, that is :)
	
	Despite being a little bit "silly" (as Code Golf is sort of silly), 
	there is a serious side to the design.  Rebmu is a genuine dialect... 
	meaning that it uses the Rebol data format and thus relegates most 
	parsing--such as parentheses and block matches.	This means that 
	there's no string-oriented trickery taking advantage of illegal 
	source token sequences in Rebol (like 1FOO, A:B, A$B...)
	
	Also, Rebmu is a superset of Rebol, so any Rebol code should be able 
	to be used safely.  That's because despite several shorthands defined 
	for common Rebol operations (even as far as I for IF) the functions 
	are true to their Rebol bretheren across all inputs that Rebol 
	accepts.  [Current exceptions to this are q and ?]
	
	Rebmu programs get their own execution context.	 They will unmush 
	their input, set up the environment of abbreviated routines, and run 
	the code:
	
		>> rebmu [w"Hello World"]
		Hello World
		
	You can also pass in named arguments via a block:
	
		>> rebmu/args [wSwM] [s: "Hello" m: "World"]
		Hello
		World
	
	The argument block can even use Rebmu code and conventions:

		>> rebmu/args [wSwM] [S"Hello"M"World"]
		Hello
		World	
	
	Or you can pass in a block which does not begin with a SET-WORD! and 
	that block will appear in the execution context as the variable A
	
		>> rebmu/args [wA] [1 2 3]
		1 2 3
	
	You can run your Rebmu program and let it set some values in its 
	environment, such as defining functions you might want to call.  Using 
	the /INJECT refinement you can run some code after the program has 
	executed but before the environment is disposed.
	
	For instance, the following example uses a shorthand format for 
	defining a function that triples a number and saving it in t:
	
		>> rebmu [Ta|[a*3]]
	
	But defining the function isn't enough to call it, so if you had 
	wanted to do that you could have said:
	
		>> rebmu/inject [Ta|[a*3]] [wT10]
		30
		
	The injected code is just shorthand for [w t 10], where w is 
	WRITEOUT-MU, a variation of Rebol's PRINT.
	}
	
	History: [
		0.1.0 [10-Jan-2010 {Sketchy prototype written to cover only the
		Roman Numeral example I worked through when coming up with the
		idea.  So very incomplete, more a proof of concept.} "Fork"]
		
		0.2.0 [22-Jun-2010 {Language more complete, includes examples.
		Ditched concept of mushing symbols like + and - into single
		character operators is removed due to realization that A+
		B+ C+ etc. are more valuable in the symbol space than one
		character for AD.}]
		
		0.3.0 [24-Jun-2010 {Made backwards compatible with Rebol 2.  
		Note that things like CN for continue or PERCENTAGE! datatype 
		were added in Rebol 3.  You can use these in your Rebmu programs
		but they will only work if using Rebmu with an r3 interpreter.
		Also did several name tweaks like instead of AA for AND~ it's 
		now A~ along with other consistencies (IT -> if-true, 
		WT -> while-true, UT -> unless true).}]
	]
]

; Load the library of xxx-mu functions
do %mulibrary.rebol

; Load the library implementing mush/unmush
do %mushing.rebol

rebmu-context: [
	;----------------------------------------------------------------------
	; WHAT REBOL DEFINES BY DEFAULT IN THE TWO-CHARACTER SPACE
	;----------------------------------------------------------------------	
	
	; Very Reasonable Use of English Words
	
	; TO	to conversion
	; OR	or operator
	; IN	word or block in the object's context
	; IF	conditional if
	; DO	evaluates a block, file, url, function word
	; AT	returns the series at the specified index
	; NO	logic false
	; ON	logic true

	; Reasonable use of Symbolic Operators

	; ++	increment and return previous value
	; --	decrement and return previous value
	; ??	Debug print a word, path, block or such
	; >=	true if the first value is greater than the second
	; <>	true if the values are not equal
	; <=	true if the first value is less than the second
	; =?	true if the values are identical
	; **	first number raised to the power of the second
	; !=	true if the values are not equal

	; The choice to take this prominent comment-to-end-of-line
	; marker and make it mean the same thing as MOD seems unwise.
	; There's nothing abstractly wrong with semicolon... it is one
	; fewer character for a to-end-of-line comment.  But semicolons
	; for comments is very "old-school" assembly and it gives the
	; language a dated look just how capitalizing REBOL looks like
	; COBOL.  I feel like if Rebol offered "//" as an alternative
	; comment choice to ";" it would be more amicable, considering
	; the rarity of modulus.  Rebol could be more popular if these
	; issues were taken seriously!

	; //	remainder of first value divided by second

	; Maybe reasonable use of abbreviation in the default.  Could be 
	; carriage-return and line-feed and leave it to the user to 
	; abbreviate.
	
	; CR	carraige return character
	; LF	line feed character

	; Questionable shorthands for terms defined elsewhere. Considering how 
	; many things do not have shorthands by default...what metric proved 
	; that *these four* were the ideal things to abbreviate?  They are 
	; only in Rebol 3.
	
	; SP	alias for SPACE
	; RM	alias for DELETE
	; DP	alias for DELTA-PROFILE
	; DT	alias for DELTA-TIME

	; These are shell commands and it seems like there would be many more.
	; Could there be a shell dialect, in which for instance issue values 
	; (#foo) could be environment variables, or something like that?  It 
	; seems many other things would be nice, like pushing directories or 
	; popping them, moving files from one place to another, etc. 
	
	; LS	print contents of a directory
	; CD	change directory

	; Another abbreviation that seems better to leave out
	; DS	temporary stack debug
	
	;----------------------------------------------------------------------
	; DATATYPE SHORTHANDS (3 CHARS)
	; Though I considered giving the datatypes 2-character names, I decided
	; on 3 and saving the one-characters for things like INDEX? and OFFSET?
	; and LENGTH?.   Literal words for types will probably not be showing 
	; up too often in Code Golf.
	;----------------------------------------------------------------------	

; Shorcuts for datatypes.  Establishes both the type and the query functions.
; (so remapping "em" for EMAIL! makes EM! => EMAIL! and EM? => EMAIL?)

	(remap-datatype email! "em")
	(remap-datatype block! "bl")
	(remap-datatype char! "ch")
	(remap-datatype decimal! "dc")
	(remap-datatype error! "er")
	(remap-datatype function! "fn")
	(remap-datatype get-word! "gw")
	(remap-datatype paren! "pn")
	(remap-datatype integer! "in")
	(remap-datatype pair! "pr")
	; no percent! type in Rebol2
	(unless unset? get/any 'percent! [remap-datatype percent! "pc"])
	(remap-datatype closure! "cl")
	(remap-datatype logic! "lg") 
	(remap-datatype map! "mp")
	(remap-datatype none! "nn")
	; no object or to-object in Rebol2... so we skip based on missing 
	; "object" keyword even thought the object! type exists
	(unless unset? get/any 'object [remap-datatype object! "ob"]) 
	(remap-datatype path! "pa")
	(remap-datatype lit-word! "lw")
	(remap-datatype refinement! "rf")
	(remap-datatype string! "st")
	(remap-datatype time! "tm")
	(remap-datatype tuple! "tu")
	(remap-datatype file! "fi") 
	(remap-datatype word! "wd")
	(remap-datatype tag! "tg") 
	(remap-datatype money! "mn")
	(remap-datatype binary! "bi")

	;----------------------------------------------------------------------	
	; TYPE CONVERSION SHORTHANDS
	; These are particularly common and there aren't many commands starting
	; with T so aliasing them is useful.  May reconsider this later.  Also,
	; these are special variations that add behaviors for types unsupported
	; by Rebol's operators.
	;----------------------------------------------------------------------	
	
	TW: :to-word-mu
	TS: :to-string-mu
	TB: :to-block
	TI: :to-integer

	;----------------------------------------------------------------------
	; CONDITIONALS
	;----------------------------------------------------------------------	
	
	IT: :if-true?-mu   ; IF is taken by Rebol, don't overwrite
	IL: :if-lesser?-mu
	IG: :if-greater?-mu
	IE: :if-equal?-mu
	INE: :if-not-equal?-mu
	IZ: :if-zero?-mu

	ET: :either-true?-mu   ; EI isn't taken by Rebol, but consistent with IT
	EL: :either-lesser?-mu
	EG: :either-greater?-mu
	EE: :either-equal?-mu
	EZ: :either-zero?-mu
	SW: :switch
	
	UT: :unless-true?-mu
	UZ: :unless-zero?-mu

	;----------------------------------------------------------------------	
	; LOOPING CONSTRUCTS
	;----------------------------------------------------------------------	

	FO: :for
	FE: :foreach
	FA: :forall
	LO: :loop
	WT: :while-true?-mu
	WG: :while-greater?-mu
	WL: :while-lesser?-mu
	WGE: :while-greater-or-equal?-mu
	WLE: :while-lesser-or-equal?-mu
	WE: :while-equal?-mu
	CN: missing-in-r2 'continue "CN"
	BR: :break
	UN: :until
	RT: :repeat
	FV: :forever

	;----------------------------------------------------------------------	
	; DEFINING FUNCTIONS
	;----------------------------------------------------------------------	

	FN: :funct
	FC: :func
	DZ: :does
	DF: :does-funct-mu
	a|: :funct-a-mu
	b|: :funct-ab-mu
	c|: :funct-abc-mu
	d|: :funct-abcd-mu
	z|: :funct-z-mu
	y|: :funct-zy-mu
	x|: :funct-zyx-mu
	w|: :funct-zyxw-mu
	; TODO: Write generator? 
	a&: :func-a-mu
	b&: :func-ab-mu
	c&: :func-abc-mu
	d&: :func-abcd-mu
	z&: :func-z-mu
	y&: :func-zy-mu
	x&: :func-zyx-mu
	w&: :func-zyxw-mu
	RN: :return
	
	;----------------------------------------------------------------------
	; OBJECTS AND CONTEXTS
	;----------------------------------------------------------------------		
	US: :use
	CX: :context	
	OB: missing-in-r2/substitute 'object "OB" func [
    		"Defines a unique object."
    		blk [block!] "Object words and values."
		][
    		make object! append blk none
		]
	
	;----------------------------------------------------------------------
	; SERIES OPERATIONS
	;----------------------------------------------------------------------	

	PO: :poke
	PC: :pick
	AP: :append
	AO: rebmu-wrap 'append/only [series value] ; very useful
	IS: :insert ; IN is a keyword
	IO: rebmu-wrap 'insert/only [series value]
	IP: rebmu-wrap 'insert/part [series value length]
	IPO: rebmu-wrap 'insert/part/only [series value length]
	TK: :take
	MNO: :minimum-of
	MXO: :maximum-of
	RP: :repend
	SE: :select
	RV: :reverse
	
	RA: rebmu-wrap 'replace/all [target search rep] ; replace as param name causes problem
	RAC: rebmu-wrap 'replace/all/case [target search rep]
	RAT: rebmu-wrap 'replace/all/tail [target search rep]
	RACT: rebmu-wrap 'replace/all/case/tail [target search rep]
	
	HD: :head
	TL: :tail
	BK: :back-mu
	NT: :next-mu
	CH: :change
	SK: :skip
	FI: :find
	UQ: :unique

	L?: :length?	
	F?: :index?-find-mu
	O?: :offset?
	I?: :index?
	T?: :tail?
	H?: :head?
	M?: :empty?
	
	FS: :first ; FR might be confused with fourth
	SC: :second
	TH: :third
	FH: :fourth ; FR might be confused with first
	FF: :fifth
	SX: :sixth
	SV: :seventh
	EH: :eighth ; EI is either, and EG is either-greater
	NH: :ninth
	TT: :tenth
	
	;----------------------------------------------------------------------	
	; METAPROGRAMMING
	;----------------------------------------------------------------------	

	CO: :compose
	COD: rebmu-wrap 'compose/deep [value]
	ML: :mold
	DR: :rebmu ; "Do Rebmu"
	RE: :reduce
	RJ: :rejoin
	RO: rebmu-wrap 'repend/only [series value]

	;----------------------------------------------------------------------	
	; MATH AND LOGIC OPERATIONS
	;----------------------------------------------------------------------	

	AD: :add-mu
	SB: :subtract-mu
	MP: :multiply
	DV: :div-mu
	DD: :divide
	NG: :negate-mu
	Z?: :zero?
	MO: :mod
	=~: :equal?
	
	; I'm not entirely sure about the fate of tokens ending in a single 
	; tilde.  Rebol's default AND/OR/XOR are infix, and the prefix versions
	; end in tildes.  That precedent guided my decision to create A~, O~, 
	; etc. but Rebol's infix OR is special and unlikely to be used in code 
	; golf
	
	A~: :prefix-and-mu
	O~: :prefix-or-mu
	X~: :prefix-xor-mu
	N~: :not-mu
	
	; Question: What other functions seem to fit in the theme of ending in 
	; tildes?  These are just ideas
	F~: :only-first-true-mu
	S~: :only-second-true-mu
	
	EV?: :even?
	OD?: :odd?
	++: :increment-mu
	--: :decrement-mu
	G~: :greater?			; >~ is not a valid symbol in Rebol
	GE~: :greater-or-equal?		; >=~ is not a valid symbol in Rebol
	L~: :lesser?			; <~ is not a valid symbol in Rebol
	LE~: :lesser-or-equal?		; <=~ is not a valid symbol in Rebol
	==~: :strict-equal?
	NG?: :negative?
	SG?: :sign?
	Y?: :true?
	N?: func [val] [not true? val] ; can be useful
	MN: :min
	MX: :max
	AN: :any
	AL: :all
	
	; to-integer (TI) always rounds down.  A "CEIL" operator is useful, 
	; though it's a bit verbose in Rebol as TO-INTEGER ROUND/CEILING VALUE.
	; May be common enough in Code Golf math to warrant inclusion.
	CE: :ceiling-mu
	
	;----------------------------------------------------------------------
	; MODIFIERS
	;----------------------------------------------------------------------
	
	; These modify their arguments to save you from situations where you 
	; might otherwise have to make things the target of an assignment, 
	; like [M: ADD M 2].  Shorter code with a+M2 than Ma+M2, and you also 
	; are less likely to cause a mushing break.  Note that the plus doesn't
	; mean "advance" or "add" in this context, LAST+ is actually an 
	; operator which traverses the series backwards.  Perhaps this should 
	; be revisited but it seems a waste to use up the minus space too...
	
	A+: :add-modify-mu
	F+: :first+
	S+: :subtract-modify-mu
	
	; How strange could we get?  Is it useful to do [Z: EQUALS? Z 3] on any
	; kind of regular basis?  Maybe if you do that test often after but 
	; don't need the value
	=+: :equal-modify-mu

	; what about two character functions?  can they return different 
	; things than their non-modifier counterparts?
	CH+: :change-modify-mu
	HD+: :head-modify-mu
	TL+: :tail-modify-mu 
	
	;----------------------------------------------------------------------
	; CONVERTERS
	;----------------------------------------------------------------------

	; Converters end in "-", so for instance "em-" is equivalent to 
	; TO-EMAIL.  I decided that minus signs on the end would indicate 
	; conversions because this is one place where default Rebol functions 
	; use a lot of hyphens.  The general goal of these functions is
	; unlike modifiers, to not change their inputs.  It might be nice
	; to have some 

	;----------------------------------------------------------------------	
	; INPUT/OUTPUT
	;----------------------------------------------------------------------	
	
	RD: :read
	WR: :write
	PR: :print
	PN: :prin
	RI: :readin-mu
	WO: :writeout-mu
	RL: rebmu-wrap 'read/lines [source]
	NL: :newline

	;----------------------------------------------------------------------	
	; STRINGS
	;----------------------------------------------------------------------	
	TR: :trim ; for true, use ON and for false use NO, test with Y? and N?
	TRT: rebmu-wrap 'trim/tail [series]
	TRH: rebmu-wrap 'trim/head [series]
	TRA: rebmu-wrap 'trim/all [series]
	
	;----------------------------------------------------------------------	
	; CONSTRUCTION FUNCTIONS
	; Letter and a caret means "factory".  This convention is not in Rebol 
	; but I thought that even if AR and AI were available for ARRAY and 
	; ARRAY/INITIAL the use of the caret would allow the pattern to 
	; continue for some other things which *would* collide.
	;----------------------------------------------------------------------	

	CY: :copy
	MK: :make
	CYD: rebmu-wrap 'copy/deep [value]
	CP: rebmu-wrap 'copy/part [value] 
	CPD: rebmu-wrap 'copy/part/deep [value] 

	A^: :array
	AI^: rebmu-wrap 'array/initial [size value]
	B^: does [copy []] ; two chars cheaper than cp[]
	I^: :make-integer-mu
	M^: :make-matrix-mu
	S^: does [copy ""] ; two chars cheaper than cp""
	SI^: :make-string-initial-mu
	
	;----------------------------------------------------------------------		; MISC
	;----------------------------------------------------------------------	
	
	AS: :also
	NN: :none
	HM: :helpful-mu
	NN: :none
	ST: :set
	GT: :get
	RF: :redefine-mu
	EN: missing-in-r2 'encode "en"
	SWP: :swap-exchange-mu
	FR: missing-in-r2 'format "fr"
	OS: :onesigned-mu
	SP: missing-in-r2/substitute 'space "sp" #" "

	;----------------------------------------------------------------------
	; SINGLE CHARACTER DEFINITIONS
	;
	; For the values (e.g. S the empty string) it is expected that you 
	; will overwrite them during the course of your program.  It's a 
	; little less customary to redefine the functions like I for IF,
	; although you may do so if you feel the need.	 They will still be 
	; available in a two-character variation.
	;----------------------------------------------------------------------

	; The dot operator is helpful for quickly redefining symbols used 
	; repeatedly .aBC.dEF will unmush into [. a bc . d ef] so you can 
	; always use it without the dot sticking to another symbol that isn't 
	; a digit

	.: :RF
	
	; This set needs to have thought given to them.
	; they breaks symbols; a^b becomes a^ b but A^b bcomes a: ^b
	; ^foo is therefore good for construction functions which are going
	; to target an assignment but little else.	getting a ^ in isolation
	; requires situations like coming in front of a block or a string
	; literal so it might make sense to define it as something that is 
	; frequently applied to series literals.  decoding base-64 strings
	; might be an option as they are used a lot in code golf.
	^: :caret-mu
	&: :DZ  ; "does" generator, can write context variables
	|: :DF	; funct generator w/no parameters, block always follows		
	~: none ; don't know yet

	; TODO: there is an issue where if an argument a is put into the block 
	; you can't overwrite its context if you're inside something like a 
	; while block.	How to resolve this?

	a: copy [] ; "array"
	b: to-char 0 ; "byte"
	c: #"A" ; "char"
	d: #"0" ; "digit"
	e: :ET ; "either-true?-mu"
	f: :FR ; "first"
	g: copy [] ; "group"
	h: :HM ; "helpful" constant declaration tool
	i: :IT ; "if-true?-mu"
	j: 0
	k: 0
	l: :LO ; "loop"
	m: copy "" ; "message"
	n: 1
	o: :OR ; "or"
	p: :PO ; "poke"
	
	; Q is tricky.	I've tried not to violate the meanings of any existing 
	; Rebol functions, but it seems like a waste to have an 
	; interpreter-only function like "quit" be taking up such a short 
	; symbol by default.  I feel the same way about ? being help.  This
	; is an issue I have with Rebol's default definitions -Fork

	q: :quoth-mu ; "quoth" e.g. qABC => "ABC" and qA => #"A"
	?: none 
	
	r: :RI ; "readin"
	s: copy "" ; "string"
	t: :TO ; note that to can use example types, e.g. t "foo" 10 is "10"!
	u: :UN ; "until"
	v: copy [] ; "vector"
	w: :WT ; "while-true?-mu"
	; decimal! values starting at 0.0 (common mathematical variables)
	x: 0.0
	y: 0.0 
	z: 0.0
]

remap-datatype: func [type [datatype!] shorter [string!]] [
	stem: head remove back tail to-string to-word type
	do load rejoin [
		shorter "!: :" stem "! "
		shorter "?: :" stem "? "
		shorter "-: :to-" stem
	]
	none ; don't return do result
]

; A rebmu wrapper lets you wrap a refinement
; need to write generalization of spec capture with reflect, e.g.
; spec: reflect :arg 'spec 
rebmu-wrap: funct [refined [path!] args [block!]] [
	func args compose [
		(refined) (args)
	]
]

missing-in-r2: funct [keyword [word!] shorthand [string!] /substitute other] [
	either unset? get/any keyword [
		either substitute [
			:other
		] [
			does [to-error reform ["no" shorthand "in Rebol 2"]]
		]
	] [get keyword]
]

rebmu: func [
	{Visit http://hostilefork.com/rebmu/}
	code [file! any-block! string!] "The Rebmu or Rebol code"
	/args arg {named Rebmu arguments [X10Y20] or implicit a: block [1"hello"2]}
	/nocopy "Default is to copy/deep the arguments for safety but you can not do that"
	/stats "print out statistical information"
	/debug "output debug information"
	/env "return the runnable object plus environment, but don't execute main function"
	/inject injection [block! string!] "run some test code in the environment after main function"
	/local result elem obj
] [
	either (file? code) or (string? code) [
		if stats [
			if string? code [
				print ["Original Rebmu string was:" length? code "characters."]
			]
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
		arg: unmush/deep either nocopy [arg] [copy/deep arg]
		if not set-word? first arg [
			; implicitly assign to a if the block doesn't start with a set-word
			arg: compose/only [a: (arg)] 
		]
	] [
		arg: copy []
	]
	
	; if we were only targeting Rebol3 this could be "obj: object ..."
	obj: make object! compose/deep [
		(compose rebmu-context)
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
