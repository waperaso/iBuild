-- A draw the developer cancels, or that its own site inspector turns down,
-- closes its bank tranche too. Without this the bank could still approve money
-- for a draw that no longer exists on the developer's side.
ALTER TABLE bank_tranches DROP CONSTRAINT IF EXISTS bank_tranches_outcome_check;
ALTER TABLE bank_tranches
  ADD CONSTRAINT bank_tranches_outcome_check CHECK (outcome IN ('rejected', 'withdrawn'));

-- Suspensions and control measures now also reach the developer as a letter.
-- Decisions taken before this change are history and are not sent again.
UPDATE bank_decisions SET written_back = true
WHERE kind IN ('suspend', 'control_measure') AND NOT written_back;
