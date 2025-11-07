; extends

; Show all the changes in decent colors
; Having them all be the same color makes it harder to spot deletes etc
(change
  kind: (modified) @diff.delta)

(change
  kind: (new) @diff.plus)

(change
  kind: (deleted) @diff.minus)
