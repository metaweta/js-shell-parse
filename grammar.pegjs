script "one or more statements separated by control operators"
 = first:statement
   rest:(controlOperator statement)*
   last:controlOperator?
   spaceNL*

statement
 = statement:( command
             / conditionalLoop
             / ifBlock
             )
   space* next:chainedStatement?

chainedStatement
 = operator:('&&' / '||') spaceNL* statement:statement

controlOperator
 = op:('&' / ';' / '\n')

command "a single command"
 = spaceNL*
   pre:((variableAssignment / redirect) space+)*
   name:commandName
   post:(space+ (redirect / argument))*

conditionalLoop
 = kind:("while" / "until") spaceNL+ test:script spaceNL*
   "do" spaceNL*
   body:script spaceNL*
   "done" spaceNL*

ifBlock
 = "if" spaceNL+ test:script spaceNL*
   "then" spaceNL* body:script spaceNL*
   elifBlocks:elifBlock*
   elseBody:("else" script)?
   "fi" spaceNL*

elifBlock
 = "elif" spaceNL+ test:script "then" spaceNL+ body:script

condition
 = '[' test:script ']'

variableAssignment
 = writableVariableName '=' argument

commandName "command name"
 = !redirect !keyword name:(concatenation / '[')

argument "command argument"
 = commandName
 / commandSubstitution

concatenation
 = pieces:( glob
          / bareword
          / environmentVariable
          / variableSubstitution
          / subshell
          / backticks
          / singleQuote
          / doubleQuote
          )+

bareword = cs:barewordChar+

barewordChar
 = '\\' chr:barewordMeta { return chr }
 / !barewordMeta chr:.   { return chr }

barewordMeta = [$"';&<>\n()\[\]*?|` ]

glob = (barewordChar* ('*' / '?' / characterRange / braceExpansion)+ barewordChar*)+

characterRange =
 $('[' !'-' . '-' !'-' . ']')

braceExpansion =
 (.? !'$') '{' barewordChar+ '}'

singleQuote = "'" inner:$([^']*) "'"

doubleQuote = '"' contents:(expandsInQuotes / doubleQuoteChar+)* '"'

doubleQuoteChar
 = '\\' chr:doubleQuoteMeta { return chr }
 / '\\\\'                   { return '\\' }
 / !doubleQuoteMeta chr:.   { return chr }

doubleQuoteMeta = '"' / '$' / '`'

expandsInQuotes
 = backticks
 / environmentVariable
 / variableSubstitution
 / subshell

environmentVariable = '$' name:readableVariableName

writableVariableName = [a-zA-Z0-9_]+
readableVariableName = writableVariableName / '?'  /* todo, other special vars */

variableSubstitution = '${' expr:[^}]* '}'

backticks
 = '`' commands:(!backticks command)+ '`'

subshell
 = '$(' commands:script ')'

commandSubstitution
 = rw:[<>] '(' commands:script ')'

redirect
 = moveFd / duplicateFd / redirectFd / pipe

pipe =
 "|" spaceNL* command:command

moveFd
 = fd:fd? op:('<&' / '>&') dest:fd '-'

duplicateFd
 = fd:fd? op:('<&' / '>&') space* filename:argument

redirectFd
 = fd:fd? op:redirectionOperator space* filename:argument

redirectionOperator
 = '<' / '>' / '>|' / '&>' / '>>' / '&>>'

fd
 = digits:[0-9]+ { return parseInt(join(digits), 10) }

space
 = " " / "\t"

spaceNL
 = space / "\n"

keyword
 = ( "while"
   / "until"
   / "for"
   / "done" // "done" must come before "do"
   / "do"
   / "case"
   / "esac"
   / "if"
   / "then"
   / "else"
   / "elif"
   / "fi" )
   ( spaceNL+ / EOF )

continuationStart
 = &( keyword / '"' / "'" / '`' / "$(" / "${" / "(" ) .*

EOF
 = !.
