*&---------------------------------------------------------------------*
*& Include ZBMM0010TOP                              - Module Pool      SAPMZBMM0010
*&---------------------------------------------------------------------*
PROGRAM SAPMZBMM0010 MESSAGE-ID ZCOMMON_MSG.

"SCREEN PAINTER TABLES 변수.
TABLES: ZSBMM1010_STR,
        ZSBMM1010_SUB,
        ZTBSD1020,
        ZTBSD1030,
        ZVBMM1010.

"ZTBMM1010 & ZTBMM1011 TYPE 변수.
DATA: GS_ZTBMM1010 TYPE ZTBMM1010,
      GS_ZTBMM1011 TYPE ZTBMM1011.

"OK_CODE & ALV 변수.
DATA: OK_CODE TYPE SY-UCOMM,
      GO_CON TYPE REF TO CL_GUI_CUSTOM_CONTAINER,
      GO_ALV  TYPE REF TO CL_GUI_ALV_GRID,
      GS_LAYO TYPE LVC_S_LAYO,
      GT_SORT TYPE LVC_T_SORT,
      GS_SORT TYPE LVC_S_SORT,
      GT_FCAT TYPE LVC_T_FCAT,
      GS_FCAT TYPE LVC_S_FCAT.

"ALV DISPLAY 변수.
DATA: GT_DATA100 TYPE TABLE OF ZSBMM1010_STR,
      GS_DATA100 LIKE LINE OF GT_DATA100.

"SELECT-OPTION 변수.
DATA: RT_MATCODE TYPE RANGE OF ZSBMM1010_STR-MATCODE,
      RS_MATCODE LIKE LINE OF RT_MATCODE,
      RT_MATNAME TYPE RANGE OF ZSBMM1010_STR-MATNAME,
      RS_MATNAME LIKE LINE OF RT_MATNAME.

"CONFIRM POPUP RETURN 값 받는 변수.
DATA: GV_ANSWER TYPE C.

"ALV에서 선택한 ROW 변수.
DATA: GT_ROWS TYPE LVC_T_ROID,
      GS_ROW  TYPE LVC_S_ROID.

"TAB STRIP 변수.
DATA: GV_DYNNR TYPE SY-DYNNR.
CONTROLS: TAB TYPE TABSTRIP.