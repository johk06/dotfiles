" Provide highlighting for git log with the --stat argument
syn match gitStatFile /^.\{-}|/ nextgroup=gitStatChanges skipwhite
syn match gitStatChanges /.*$/ contained

syn match gitStatSeparator /|/ contained containedin=gitStatFile
syn match gitStatAdded /+/ contained containedin=gitStatChanges
syn match gitStatDeleted /-/ contained containedin=gitStatChanges

syn match gitInlineHash /\x\{8,}/

hi def link gitStatFile Directory
hi def link gitStatAdded Added
hi def link gitStatDeleted Deleted
hi def link gitStatSeparator NonText
hi def link gitInlineHash gitHashAbbrev
