REPORT zgg_gui_frontend_services.

TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.
TYPES ty_bin_line TYPE x LENGTH 255.
TYPES ty_bin_lines TYPE STANDARD TABLE OF ty_bin_line WITH EMPTY KEY.

DATA gt_log TYPE zcl_gg_gui_demo_helper=>ty_log_lines.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_log TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_target TYPE c LENGTH 100 VALUE 'https://help.sap.com'.
DATA gv_separator TYPE c LENGTH 2.
DATA gv_temp_dir TYPE string.
DATA gv_sample_dir TYPE string.
DATA gv_text_file TYPE string.
DATA gv_binary_file TYPE string.
DATA gv_copy_file TYPE string.
DATA gv_gui_available TYPE abap_bool.

START-OF-SELECTION.
  IF sy-batch = abap_true.
    WRITE: / 'ZGG_GUI_FRONTEND_SERVICES requires an interactive SAP GUI session.',
           / 'No frontend file, directory, clipboard, registry, or execute operation was attempted.'.
    RETURN.
  ENDIF.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_controls.
ENDMODULE.

MODULE exit_0100 INPUT.
  PERFORM free_controls.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'DIALOGS'.
      PERFORM run_dialogs.
    WHEN 'CREATE'.
      PERFORM create_sample_files.
    WHEN 'INSPECT'.
      PERFORM inspect_sample_files.
    WHEN 'CLIP'.
      PERFORM clipboard_roundtrip.
    WHEN 'CAPS'.
      PERFORM inspect_capabilities.
    WHEN 'DIRS'.
      PERFORM inspect_directories.
    WHEN 'REGISTRY'.
      PERFORM read_registry.
    WHEN 'OPEN'.
      PERFORM open_target.
    WHEN 'CLEANUP'.
      PERFORM cleanup_sample_files.
    WHEN 'RESET'.
      PERFORM reset_log.
  ENDCASE.
  PERFORM refresh_log.
ENDMODULE.

FORM create_controls.
  IF gv_sample_dir IS INITIAL.
    PERFORM initialize_paths.
  ENDIF.
  IF go_host IS NOT BOUND.
    TRY.
        CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
        CREATE OBJECT go_log EXPORTING parent = go_host.
        go_log->set_readonly_mode( 1 ).
      CATCH cx_root INTO DATA(lx_error).
        gv_status = |Event log control unavailable: { lx_error->get_text( ) }|.
    ENDTRY.
  ENDIF.
  IF gt_log IS INITIAL.
    PERFORM add_log USING 'Frontend Services sample started; no filesystem changes have been made'.
    PERFORM inspect_gui_available.
    PERFORM refresh_log.
  ENDIF.
ENDFORM.

FORM initialize_paths.
  DATA lv_length TYPE i.
  DATA lv_offset TYPE i.
  DATA lv_last TYPE c LENGTH 1.

  TRY.
      cl_gui_frontend_services=>get_temp_directory( CHANGING temp_dir = gv_temp_dir ).
      cl_gui_frontend_services=>get_file_separator( CHANGING file_separator = gv_separator ).
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Frontend path initialization failed: { lx_error->get_text( ) }|.
  ENDTRY.
  IF gv_separator IS INITIAL.
    gv_separator = '\'.
  ENDIF.
  IF gv_temp_dir IS INITIAL.
    gv_temp_dir = 'C:\TEMP'.
  ENDIF.
  lv_length = strlen( gv_temp_dir ).
  IF lv_length > 0.
    lv_offset = lv_length - 1.
    lv_last = gv_temp_dir+lv_offset(1).
  ENDIF.
  IF lv_last = gv_separator.
    gv_sample_dir = |{ gv_temp_dir }ZGG_GUI_{ sy-uname }|.
  ELSE.
    gv_sample_dir = |{ gv_temp_dir }{ gv_separator }ZGG_GUI_{ sy-uname }|.
  ENDIF.
  gv_text_file = |{ gv_sample_dir }{ gv_separator }sample.txt|.
  gv_binary_file = |{ gv_sample_dir }{ gv_separator }sample.bin|.
  gv_copy_file = |{ gv_sample_dir }{ gv_separator }sample-copy.txt|.
ENDFORM.

FORM inspect_gui_available.
  DATA lt_version TYPE filetable.
  DATA lv_rc TYPE i.

* CL_GUI_FRONTEND_SERVICES exposes no availability predicate. A frontend round
* trip that reports a return code is the supported probe.
  IF sy-batch = abap_true.
    gv_gui_available = abap_false.
  ELSE.
    cl_gui_frontend_services=>get_gui_version(
      CHANGING version_table = lt_version
               rc            = lv_rc ).
    gv_gui_available = xsdbool( lv_rc = 0 ).
  ENDIF.
  zcl_gg_gui_demo_helper=>add_log(
    EXPORTING event = |Frontend availability probe returned { gv_gui_available }|
    CHANGING log    = gt_log ).
  gv_status = COND #( WHEN gv_gui_available = abap_true
    THEN 'Interactive frontend detected; operations still require explicit buttons and may trigger security prompts'
    ELSE 'Frontend unavailable or capability check unsupported; operations will fail without terminating the report' ).
  gv_detail = |Sample-owned temporary directory: { gv_sample_dir }|.
ENDFORM.

FORM run_dialogs.
  DATA lt_files TYPE filetable.
  DATA lv_rc TYPE i.
  DATA lv_action TYPE i.
  DATA lv_filename TYPE string.
  DATA lv_path TYPE string.
  DATA lv_fullpath TYPE string.
  DATA lv_selected TYPE string.

  TRY.
      cl_gui_frontend_services=>file_open_dialog(
        EXPORTING window_title = 'Select a file for read-only inspection'
          multiselection = abap_false
                  initial_directory = gv_temp_dir
          file_filter = 'Text files (*.txt)|*.txt|All files (*.*)|*.*|'
        CHANGING file_table = lt_files rc = lv_rc user_action = lv_action ).
      zcl_gg_gui_demo_helper=>add_log(
        EXPORTING event = |Open dialog action { lv_action }, selected entries { lv_rc }|
        CHANGING log    = gt_log ).
      IF lv_rc > 0.
        READ TABLE lt_files INDEX 1 INTO DATA(ls_file).
        gv_target = ls_file-filename.
      ENDIF.

      cl_gui_frontend_services=>file_save_dialog(
        EXPORTING window_title = 'Choose a sample export path'
          default_extension = 'txt'
                  default_file_name = 'zgg-gui-sample.txt'
          initial_directory = gv_temp_dir
                  prompt_on_overwrite = abap_true
        CHANGING filename = lv_filename path = lv_path fullpath = lv_fullpath
          user_action = lv_action ).
      zcl_gg_gui_demo_helper=>add_log(
        EXPORTING event = |Save dialog action { lv_action }, path { lv_fullpath }|
        CHANGING log    = gt_log ).

      cl_gui_frontend_services=>directory_browse(
        EXPORTING window_title   = 'Select a directory without changing it'
          initial_folder         = gv_temp_dir
        CHANGING selected_folder = lv_selected ).
      zcl_gg_gui_demo_helper=>add_log(
        EXPORTING event = COND string( WHEN lv_selected IS INITIAL
          THEN 'Directory selection canceled' ELSE |Directory selected: { lv_selected }| )
        CHANGING log    = gt_log ).
      gv_status = 'Open, save, and directory-selection dialogs completed or were canceled consistently'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Frontend dialog unavailable or rejected: { lx_error->get_text( ) }|.
      PERFORM add_log USING gv_status.
  ENDTRY.
ENDFORM.

FORM create_sample_files.
  DATA lt_text TYPE ty_text_lines.
  DATA lt_binary TYPE ty_bin_lines.
  DATA lv_binary TYPE ty_bin_line.
  DATA lv_rc TYPE i.

  IF gv_gui_available = abap_false.
    PERFORM add_log USING 'Create requested while GUI_IS_AVAILABLE is false; attempting guarded calls for diagnostics'.
  ENDIF.
  lt_text = VALUE #(
    ( 'ZGG_GUI_FRONTEND_SERVICES deterministic sample' )
    ( |User: { sy-uname }| )
    ( |Date: { sy-datum DATE = ISO }| ) ).
  lv_binary = '00010203040506070809AABBCCDDEEFF'.
  APPEND lv_binary TO lt_binary.
  TRY.
      cl_gui_frontend_services=>directory_create(
        EXPORTING directory = gv_sample_dir CHANGING rc = lv_rc ).
      zcl_gg_gui_demo_helper=>add_log(
        EXPORTING event = |Create directory rc { lv_rc }: { gv_sample_dir }|
        CHANGING log    = gt_log ).
      cl_gui_frontend_services=>gui_download(
        EXPORTING filename          = gv_text_file
                  filetype          = 'ASC'
          write_lf                  = abap_true
                  confirm_overwrite = abap_true
        CHANGING data_tab           = lt_text ).
      cl_gui_frontend_services=>gui_download(
        EXPORTING filename     = gv_binary_file
                  filetype     = 'BIN'
                  bin_filesize = 16
          confirm_overwrite    = abap_true
        CHANGING data_tab      = lt_binary ).
      gv_status = 'Sample-owned text and binary files written after explicit action'.
      gv_detail = gv_sample_dir.
      zcl_gg_gui_demo_helper=>add_log(
        EXPORTING event = |Downloaded text { gv_text_file } and binary { gv_binary_file }|
        CHANGING log    = gt_log ).
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Directory creation or download unavailable/rejected: { lx_error->get_text( ) }|.
      PERFORM add_log USING gv_status.
  ENDTRY.
ENDFORM.

FORM inspect_sample_files.
  DATA lt_text TYPE ty_text_lines.
  DATA lt_binary TYPE ty_bin_lines.
  DATA lt_files TYPE filetable.
  DATA lv_count TYPE i.
  DATA lv_text_length TYPE i.
  DATA lv_binary_length TYPE i.
  DATA lv_header TYPE xstring.
  DATA lv_size TYPE i.
  DATA lv_exists TYPE abap_bool.
  DATA lv_dir_exists TYPE abap_bool.

  TRY.
      lv_dir_exists = cl_gui_frontend_services=>directory_exist( gv_sample_dir ).
      lv_exists = cl_gui_frontend_services=>file_exist( gv_text_file ).
      cl_gui_frontend_services=>file_get_size(
        EXPORTING file_name = gv_text_file IMPORTING file_size = lv_size ).
      cl_gui_frontend_services=>gui_upload(
        EXPORTING filename = gv_text_file
                  filetype = 'ASC'
                  read_by_line = abap_true
        IMPORTING filelength = lv_text_length header = lv_header
        CHANGING data_tab = lt_text ).
      cl_gui_frontend_services=>gui_upload(
        EXPORTING filename = gv_binary_file
                  filetype = 'BIN'
        IMPORTING filelength = lv_binary_length header = lv_header
        CHANGING data_tab = lt_binary ).
      cl_gui_frontend_services=>file_copy(
        source      = gv_text_file
        destination = gv_copy_file
        overwrite   = abap_true ).
      cl_gui_frontend_services=>directory_list_files(
        EXPORTING directory = gv_sample_dir
                  files_only = abap_true
                  filter = '*.*'
        CHANGING file_table = lt_files count = lv_count ).
      gv_status = |Directory exists { lv_dir_exists }; text exists { lv_exists }; size { lv_size }; listed files { lv_count }|.
      gv_detail = |Uploaded text bytes { lv_text_length }; binary bytes { lv_binary_length }; copied to sample-copy.txt|.
      PERFORM add_log USING gv_status.
      PERFORM add_log USING gv_detail.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Frontend upload, inspection, copy, or listing unavailable/rejected: { lx_error->get_text( ) }|.
      PERFORM add_log USING gv_status.
  ENDTRY.
ENDFORM.

FORM clipboard_roundtrip.
  DATA lt_export TYPE ty_text_lines.
  DATA lt_import TYPE ty_text_lines.
  DATA lv_rc TYPE i.
  DATA lv_length TYPE i.

  lt_export = VALUE #( ( 'ZGG_GUI clipboard sample' )
    ( |Generated for { sy-uname } at { sy-uzeit TIME = ISO }| ) ).
  TRY.
      cl_gui_frontend_services=>clipboard_export(
        IMPORTING data = lt_export
        CHANGING  rc   = lv_rc ).
      cl_gui_frontend_services=>clipboard_import(
        IMPORTING data   = lt_import
                  length = lv_length ).
      gv_status = |Clipboard export rc { lv_rc }; imported lines { lines( lt_import ) }; length { lv_length }|.
      gv_detail = 'Clipboard content is text only and contains no productive data'.
      PERFORM add_log USING gv_status.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Clipboard access unavailable or rejected: { lx_error->get_text( ) }|.
      PERFORM add_log USING gv_status.
  ENDTRY.
ENDFORM.

FORM inspect_capabilities.
  DATA lv_platform TYPE i.
  DATA lv_computer TYPE string.
  DATA lv_drive TYPE string.
  DATA lv_drive_type TYPE string.
  DATA lt_version TYPE filetable.
  DATA lv_rc TYPE i.

  TRY.
      lv_platform = cl_gui_frontend_services=>get_platform( ).
      cl_gui_frontend_services=>get_computer_name( CHANGING computer_name = lv_computer ).
      cl_gui_frontend_services=>get_gui_version( CHANGING version_table = lt_version rc = lv_rc ).
      IF strlen( gv_temp_dir ) >= 3.
        lv_drive = gv_temp_dir(3).
        cl_gui_frontend_services=>get_drive_type(
          EXPORTING drive = lv_drive CHANGING drive_type = lv_drive_type ).
      ENDIF.
      gv_status = |Platform { lv_platform }; computer { lv_computer }; drive { lv_drive_type }|.
      gv_detail = |GUI version rows { lines( lt_version ) }, rc { lv_rc }, path separator { gv_separator }, GUI available { gv_gui_available }|.
      PERFORM add_log USING gv_status.
      PERFORM add_log USING gv_detail.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Frontend capability query unavailable/rejected: { lx_error->get_text( ) }|.
      PERFORM add_log USING gv_status.
  ENDTRY.
ENDFORM.

FORM inspect_directories.
  DATA lv_set_rc TYPE i.
  DATA lv_desktop TYPE string.
  DATA lv_system TYPE string.
  DATA lv_work TYPE string.
  DATA lv_upload TYPE string.
  DATA lv_download TYPE string.
  DATA lv_current TYPE string.
  DATA lv_sapgui TYPE string.

  TRY.
      cl_gui_frontend_services=>get_desktop_directory( CHANGING desktop_directory = lv_desktop ).
      cl_gui_frontend_services=>get_system_directory( CHANGING system_directory = lv_system ).
      cl_gui_frontend_services=>get_sapgui_workdir( CHANGING sapworkdir = lv_work ).
      cl_gui_frontend_services=>get_upload_download_path(
        CHANGING upload_path = lv_upload download_path = lv_download ).
      cl_gui_frontend_services=>directory_get_current( CHANGING current_directory = lv_current ).
      cl_gui_frontend_services=>get_sapgui_directory(
        CHANGING sapgui_directory = lv_sapgui ).
      zcl_gg_gui_demo_helper=>add_log(
        EXPORTING event = |Temp { gv_temp_dir }; Desktop { lv_desktop }|
        CHANGING log    = gt_log ).
      zcl_gg_gui_demo_helper=>add_log(
        EXPORTING event = |System { lv_system }; SAP GUI { lv_sapgui }; Work { lv_work }|
        CHANGING log    = gt_log ).
      zcl_gg_gui_demo_helper=>add_log(
        EXPORTING event = |Upload { lv_upload }; Download { lv_download }; Current { lv_current }|
        CHANGING log    = gt_log ).

      cl_gui_frontend_services=>directory_set_current(
        EXPORTING current_directory = gv_sample_dir
        CHANGING  rc                = lv_set_rc ).
      gv_status = 'Frontend directories queried; current directory change was limited to the sample-owned path'.
      gv_detail = 'Use Create files first if the sample-owned directory does not yet exist'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Frontend directory query/change unavailable or rejected: { lx_error->get_text( ) }|.
      PERFORM add_log USING gv_status.
  ENDTRY.
ENDFORM.

FORM read_registry.
  DATA lv_value TYPE string.

  TRY.
      cl_gui_frontend_services=>registry_get_value(
        EXPORTING root      = cl_gui_frontend_services=>hkey_current_user
          key               = 'Software\SAP\General'
                  value     = 'Theme'
        IMPORTING reg_value = lv_value ).
      gv_status = |Read-only registry lookup completed; value length { strlen( lv_value ) }|.
      gv_detail = 'HKCU\Software\SAP\General\Theme was read; no registry write API is used'.
      PERFORM add_log USING gv_status.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Windows registry lookup unavailable or rejected: { lx_error->get_text( ) }|.
      PERFORM add_log USING gv_status.
  ENDTRY.
ENDFORM.

FORM open_target.
  DATA lv_answer TYPE c LENGTH 1.
  DATA lv_target TYPE string.

  lv_target = gv_target.
  IF lv_target IS INITIAL.
    gv_status = 'Enter a local file path or URL before using Open target'.
    RETURN.
  ENDIF.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING titlebar = 'Open frontend target'
      text_question = |Open { lv_target } with the configured frontend application?|
      text_button_1 = 'Open' text_button_2 = 'Cancel' default_button = '2'
    IMPORTING answer = lv_answer.
  IF lv_answer <> '1'.
    gv_status = 'Opening the local file or URL was canceled'.
    PERFORM add_log USING gv_status.
    RETURN.
  ENDIF.
  TRY.
      cl_gui_frontend_services=>execute( document  = lv_target
                                         operation = 'OPEN' ).
      gv_status = |Frontend open requested for { lv_target }|.
      gv_detail = 'The SAP GUI security policy and local application association control execution'.
      PERFORM add_log USING gv_status.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Frontend execute unavailable or rejected: { lx_error->get_text( ) }|.
      PERFORM add_log USING gv_status.
  ENDTRY.
ENDFORM.

FORM cleanup_sample_files.
  DATA lv_rc TYPE i.

  IF gv_sample_dir IS INITIAL OR gv_sample_dir NS 'ZGG_GUI_'.
    gv_status = 'Cleanup refused because the path is not the sample-owned temporary directory'.
    RETURN.
  ENDIF.
  TRY.
      IF cl_gui_frontend_services=>file_exist( gv_copy_file ) = abap_true.
        cl_gui_frontend_services=>file_delete(
          EXPORTING filename = gv_copy_file CHANGING rc = lv_rc ).
      ENDIF.
      IF cl_gui_frontend_services=>file_exist( gv_text_file ) = abap_true.
        cl_gui_frontend_services=>file_delete(
          EXPORTING filename = gv_text_file CHANGING rc = lv_rc ).
      ENDIF.
      IF cl_gui_frontend_services=>file_exist( gv_binary_file ) = abap_true.
        cl_gui_frontend_services=>file_delete(
          EXPORTING filename = gv_binary_file CHANGING rc = lv_rc ).
      ENDIF.
      IF cl_gui_frontend_services=>directory_exist( gv_sample_dir ) = abap_true.
        cl_gui_frontend_services=>directory_delete(
          EXPORTING directory = gv_sample_dir CHANGING rc = lv_rc ).
      ENDIF.
      gv_status = |Sample-owned files and directory cleanup completed; final rc { lv_rc }|.
      gv_detail = gv_sample_dir.
      PERFORM add_log USING gv_status.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Sample cleanup unavailable or rejected: { lx_error->get_text( ) }|.
      PERFORM add_log USING gv_status.
  ENDTRY.
ENDFORM.

FORM reset_log.
  gv_target = 'https://help.sap.com'.
  zcl_gg_gui_demo_helper=>reset_log(
    EXPORTING initial_event = 'Event log and target reset; existing sample-owned files were not deleted'
    CHANGING log            = gt_log ).
  gv_status = 'Log reset; use Cleanup explicitly to remove sample-owned frontend files'.
  gv_detail = gv_sample_dir.
ENDFORM.

FORM add_log USING iv_text TYPE c.
  zcl_gg_gui_demo_helper=>add_log(
    EXPORTING event = CONV string( iv_text )
    CHANGING  log   = gt_log ).
ENDFORM.

FORM refresh_log.
  IF go_log IS BOUND.
    DATA lt_text TYPE ty_text_lines.

    LOOP AT gt_log INTO DATA(lv_log_line).
      APPEND lv_log_line TO lt_text.
    ENDLOOP.
    TRY.
      go_log->set_text_as_r3table( lt_text ).
      cl_gui_cfw=>flush( ).
      go_log->go_to_line( lines( gt_log ) ).
      cl_gui_cfw=>flush( ).
      CATCH cx_root.
    ENDTRY.
  ENDIF.
ENDFORM.

FORM free_controls.
  IF go_log IS BOUND. go_log->free( ). FREE go_log. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
