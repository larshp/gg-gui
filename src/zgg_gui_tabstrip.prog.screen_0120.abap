PROCESS BEFORE OUTPUT.

PROCESS AFTER INPUT.
  CHAIN.
    FIELD gv_notify.
    FIELD gv_start_date.
    MODULE validate_settings ON CHAIN-REQUEST.
  ENDCHAIN.
