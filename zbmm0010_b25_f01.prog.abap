*&---------------------------------------------------------------------*
*& Include          ZBMM0010F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form ZBMM_INIT_ALV
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM INIT_ALV .
  IF GO_CON IS INITIAL.
    CREATE OBJECT GO_CON
      EXPORTING
        CONTAINER_NAME              = 'AREA'
      EXCEPTIONS
        CNTL_ERROR                  = 1
        CNTL_SYSTEM_ERROR           = 2
        CREATE_ERROR                = 3
        LIFETIME_ERROR              = 4
        LIFETIME_DYNPRO_DYNPRO_LINK = 5
        OTHERS                      = 6.
    IF SY-SUBRC <> 0.
    ENDIF.

    CREATE OBJECT GO_ALV
      EXPORTING
        I_PARENT          = GO_CON
      EXCEPTIONS
        ERROR_CNTL_CREATE = 1
        ERROR_CNTL_INIT   = 2
        ERROR_CNTL_LINK   = 3
        ERROR_DP_CREATE   = 4
        OTHERS            = 5.
    IF SY-SUBRC <> 0.
    ENDIF.

    PERFORM SET_EVENT.
    PERFORM SET_LAYOUT.
    PERFORM SET_SORT.
    PERFORM SET_FCAT.

    " MATCODE HOTSPOT 클릭 시 EVENT 설정.
    SET HANDLER LCL_EVENT_HANDLER=>ON_HOTSPOT_CLICK FOR GO_ALV.


    CALL METHOD GO_ALV->SET_TABLE_FOR_FIRST_DISPLAY
      EXPORTING
        I_BYPASSING_BUFFER            = 'X'
        I_STRUCTURE_NAME              = 'ZSBMM1010_STR'
        IS_LAYOUT                     = GS_LAYO
      CHANGING
        IT_OUTTAB                     = GT_DATA100
        IT_FIELDCATALOG               = GT_FCAT
        IT_SORT                       = GT_SORT
      EXCEPTIONS
        INVALID_PARAMETER_COMBINATION = 1
        PROGRAM_ERROR                 = 2
        TOO_MANY_LINES                = 3
        OTHERS                        = 4.
    IF SY-SUBRC <> 0.
    ENDIF.

  ELSE.
    CALL METHOD GO_ALV->REFRESH_TABLE_DISPLAY
      EXCEPTIONS
        FINISHED = 1
        OTHERS   = 2.
    IF SY-SUBRC <> 0.
    ENDIF.

  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_SET_LAYOUT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_LAYOUT .
  GS_LAYO-ZEBRA = 'X'.
  GS_LAYO-CWIDTH_OPT = 'A'.
  GS_LAYO-GRID_TITLE = '자재 리스트'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_GET_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_DATA .
  DATA: LV_DEL     TYPE CHAR1,
        LV_MATNAME TYPE CHAR20.
  CLEAR: RT_MATCODE, RS_MATCODE, LV_DEL, LV_MATNAME.

  "라디오 버튼 SELECT에 따라 조건 부여.
  IF ZSBMM1010_STR-ALL = 'X'.
    LV_DEL = '%'.
  ELSEIF ZSBMM1010_STR-VAL = 'X'.
    LV_DEL = ''.
  ELSE.
    LV_DEL = 'X'.
  ENDIF.

  "SELECT-OPTION 조건 설정.
  IF ZSBMM1010_STR-MATCODE IS NOT INITIAL.
    RS_MATCODE-SIGN = 'I'.
    RS_MATCODE-OPTION = 'EQ'.
    RS_MATCODE-LOW = ZSBMM1010_STR-MATCODE.
    APPEND RS_MATCODE TO RT_MATCODE.
  ENDIF.

  " 조회 조건에 사용자가 입력한 TEXT를 포함한 변수.
  LV_MATNAME = '%' && ZSBMM1010_STR-MATNAME && '%'.

  "ALV DISPLAY DATA SQL.
  SELECT *
    FROM ZTBMM1010 AS A INNER JOIN ZTBMM1011 AS B
    ON A~MATCODE = B~MATCODE
    WHERE A~MATCODE IN @RT_MATCODE
      AND B~MATNAME LIKE @LV_MATNAME
      AND B~SPRAS = @SY-LANGU
      AND A~DELFLG LIKE @LV_DEL
    INTO CORRESPONDING FIELDS OF TABLE @GT_DATA100.

  IF SY-SUBRC <> 0.
    "입력한 조회 조건에 일치하는 데이터 없을 때 에러 메세지.
    MESSAGE S015 DISPLAY LIKE 'E'.
  ELSE.
    "입력한 조회 조건에 일치하는 MATNAME TEXT TABLE에서 가져오기.
    READ TABLE GT_DATA100 INTO GS_DATA100
    WITH KEY MATCODE = ZSBMM1010_STR-MATCODE.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_SAVE_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SAVE_DATA .
  DATA: LV_MATNAME TYPE ZSBMM1010_STR-MATNAME.
  CLEAR: LV_MATNAME.

  " 동일한 자재명이 DB에 존재하면 LV_MATNAME에 값 할당.
  SELECT SINGLE MATNAME
    FROM ZTBMM1011
    WHERE MATNAME = @ZSBMM1010_STR-MATNAME
    INTO @LV_MATNAME.

  " 동일한 자재명이 DB에 없을 때 CONFIRM POPUP.
  IF LV_MATNAME IS INITIAL.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        TITLEBAR              = '자재 MASTER 데이터 생성'
        TEXT_QUESTION         = '해당 데이터를 생성하시겠습니까?'
        TEXT_BUTTON_1         = 'YES'
        TEXT_BUTTON_2         = 'NO'
        DISPLAY_CANCEL_BUTTON = ''
      IMPORTING
        ANSWER                = GV_ANSWER
      EXCEPTIONS
        TEXT_NOT_FOUND        = 1
        OTHERS                = 2.
    IF SY-SUBRC <> 0.
      MESSAGE E016.
    ENDIF.
    " 동일한 자재명이 DB에 있을 때 CONFIRM POPUP.
  ELSE.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        TITLEBAR              = '자재 MASTER 데이터 생성'
        TEXT_QUESTION         = '이미 동일한 자재명을 가진 데이터가 존재합니다, 그래도 생성하시겠습니까?'
        TEXT_BUTTON_1         = 'YES'
        TEXT_BUTTON_2         = 'NO'
        DISPLAY_CANCEL_BUTTON = ''
      IMPORTING
        ANSWER                = GV_ANSWER
      EXCEPTIONS
        TEXT_NOT_FOUND        = 1
        OTHERS                = 2.
    IF SY-SUBRC <> 0.
      MESSAGE E016.
    ENDIF.
  ENDIF.

  "CONFIRM POPUP 에서 'YES' 선택 시.
  IF GV_ANSWER = 1.

    DATA: LV_NR TYPE NUM7.

    "DILAOG에 입력한 DATA를 변수에 할당.
    MOVE-CORRESPONDING ZSBMM1010_STR TO GS_DATA100.

    "DIALOG에 입력한 값이 모두 정상인지 확인 후 타임스탬프 생성.
    IF SY-SUBRC = 0.
      PERFORM CREATE_TIMESTAMP.
      GS_DATA100-SPRAS = SY-LANGU.
    ELSE.
      MESSAGE S002 DISPLAY LIKE 'E'.
    ENDIF.


    "NUMBER RANGE 호출.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        NR_RANGE_NR             = '01'
        OBJECT                  = 'ZBBMM1010'
      IMPORTING
        NUMBER                  = LV_NR
      EXCEPTIONS
        INTERVAL_NOT_FOUND      = 1
        NUMBER_RANGE_NOT_INTERN = 2
        OBJECT_NOT_FOUND        = 3
        QUANTITY_IS_0           = 4
        QUANTITY_IS_NOT_1       = 5
        INTERVAL_OVERFLOW       = 6
        BUFFER_OVERFLOW         = 7
        OTHERS                  = 8.
    IF SY-SUBRC <> 0.
    ENDIF.

    "NUMBER RANGE로 DATA 생성 시 MATCODE 번호 부여.
    CONCATENATE 'MAT' LV_NR INTO GS_DATA100-MATCODE.

    "각 Transparent Table type 변수에 값 할당.
    MOVE-CORRESPONDING GS_DATA100 TO GS_ZTBMM1010.
    MOVE-CORRESPONDING GS_DATA100 TO GS_ZTBMM1011.

    "각 Transparent Table에 DB UPDATE.
    INSERT ZTBMM1010 FROM GS_ZTBMM1010.
    INSERT ZTBMM1011 FROM GS_ZTBMM1011.

    "DATA 생성 확인 후 ALV DISPLAY INTERNAL TABLE에 DATA 추가.
    IF SY-SUBRC = 0.
      MESSAGE S001.
      APPEND GS_DATA100 TO GT_DATA100.
    ELSE.
      MESSAGE E010.
    ENDIF.

    "ALV RERESH.
    CALL METHOD GO_ALV->REFRESH_TABLE_DISPLAY
      EXCEPTIONS
        FINISHED = 1
        OTHERS   = 2.
    IF SY-SUBRC <> 0.
    ENDIF.
  ENDIF.

  "변수 값 CLEAR.
  CLEAR: GS_DATA100, GV_ANSWER, LV_NR, ZSBMM1010_STR.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_SET_UNIT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_UNIT .
  ZSBMM1010_STR-MSQUAN = 1.
  ZSBMM1010_STR-UNITCODE2 = 'KG'.
  ZSBMM1010_STR-UNITCODE3 = 'M3'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_SET_SORT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_SORT .
  GS_SORT-FIELDNAME = 'MATCODE'.
  GS_SORT-DOWN = 'X'.
  APPEND GS_SORT TO GT_SORT.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_TIMESTAMP
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_TIMESTAMP .
  SELECT SINGLE EMPID
    INTO GS_DATA100-STAMP_USER_F
    FROM ZTBSD1030
    WHERE LOGID = SY-UNAME.

  GS_DATA100-STAMP_DATE_F = SY-DATUM.
  GS_DATA100-STAMP_TIME_F = SY-UZEIT.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_SET_FCAT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_FCAT .
  GS_FCAT-FIELDNAME = 'SPRAS'.
  GS_FCAT-NO_OUT = 'X'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'PRODTYPE'.
  GS_FCAT-JUST = 'C'.
  GS_FCAT-COLTEXT = '완제품 유형'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'ALL' .
  GS_FCAT-NO_OUT = 'X'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'VAL' .
  GS_FCAT-NO_OUT = 'X'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'DEL'   .
  GS_FCAT-NO_OUT = 'X'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'MATCODE'.
  GS_FCAT-HOTSPOT = 'X'.
  GS_FCAT-JUST = 'C'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'STAMP_USER_F'.
  GS_FCAT-HOTSPOT = 'X'.
  GS_FCAT-JUST = 'C'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'STAMP_USER_L'.
  GS_FCAT-HOTSPOT = 'X'.
  GS_FCAT-JUST = 'C'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'STAMP_TIME_F'.
  GS_FCAT-JUST = 'C'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'STAMP_DATE_F'.
  GS_FCAT-JUST = 'C'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'STAMP_TIME_L'.
  GS_FCAT-JUST = 'C'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'STAMP_DATE_L'.
  GS_FCAT-JUST = 'C'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'MATNAME'.
  GS_FCAT-JUST = 'C'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'MATTYPE'.
  GS_FCAT-JUST = 'C'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'MSQUAN'.
  GS_FCAT-JUST = 'R'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'UNITCODE1'.
  GS_FCAT-JUST = 'L'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'WEIGHT'.
  GS_FCAT-JUST = 'R'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'UNITCODE2'.
  GS_FCAT-JUST = 'L'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'VOLUME'.
  GS_FCAT-JUST = 'R'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'UNITCODE3'.
  GS_FCAT-JUST = 'L'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.

  GS_FCAT-FIELDNAME = 'DELFLG'.
  GS_FCAT-CHECKBOX  = 'X'.
  GS_FCAT-JUST = 'C'.
  APPEND GS_FCAT TO GT_FCAT.
  CLEAR GS_FCAT.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_DATA_SELECTED_ROW
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM DATA_SELECTED_ROW .
  CLEAR: GT_ROWS, GS_ROW.

  "ALV에서 선택한 ROW 정보 취득.
  CALL METHOD GO_ALV->GET_SELECTED_ROWS
    IMPORTING
      ET_ROW_NO = GT_ROWS.

  "ALV에서 ROW를 선택하지 않았을 때.
  IF GT_ROWS IS INITIAL.
    MESSAGE S008 DISPLAY LIKE 'E'.

    "ALV에서 ROW를 선택했을 때.
  ELSE.
    "ALV에서 선택한 ROW의 ROW-ID, SUBROW-ID를 GS_ROW에 할당.
    READ TABLE GT_ROWS INTO GS_ROW INDEX 1.

    "ALV에 DISPLAY시키는 INTERNAL TABLE에서 해당 ROW-ID의 정보 취득.
    READ TABLE GT_DATA100 INTO GS_DATA100 INDEX GS_ROW-ROW_ID.

    "선택한 ROW의 데이터가 이미 삭제플래그에 체크된 데이터일 경우 메세지.
    IF GS_DATA100-DELFLG = 'X'.
      MESSAGE S014 DISPLAY LIKE 'E'.
    ELSE.

      CASE OK_CODE.
          "해당 데이터 선택 후 수정.
        WHEN 'CHANGE'.
          MOVE-CORRESPONDING GS_DATA100 TO ZSBMM1010_STR.
          CALL SCREEN 120
            STARTING AT 80 7.

          "해당 데이터 선택 후 삭제.
        WHEN 'DELETE'.
          PERFORM DELETE_DATA.
      ENDCASE.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_CHANGE_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CHANGE_DATA .
  DATA LV_MATNAME TYPE ZSBMM1010_STR-MATNAME.
  CLEAR LV_MATNAME.

  " 동일한 자재명이 DB에 존재하면 LV_MATNAME에 값 할당.
  SELECT SINGLE MATNAME
    FROM ZTBMM1011
    WHERE MATNAME = @ZSBMM1010_STR-MATNAME
    INTO @LV_MATNAME.

  " 동일한 자재명이 DB에 없을 때 CONFIRM POPUP.
  IF LV_MATNAME IS INITIAL.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        TITLEBAR              = '자재 MASTER 데이터 수정'
        TEXT_QUESTION         = '해당 데이터를 수정하시겠습니까?'
        TEXT_BUTTON_1         = 'YES'
        TEXT_BUTTON_2         = 'NO'
        DISPLAY_CANCEL_BUTTON = ''
      IMPORTING
        ANSWER                = GV_ANSWER
      EXCEPTIONS
        TEXT_NOT_FOUND        = 1
        OTHERS                = 2.
    IF SY-SUBRC <> 0.
      MESSAGE E016.
    ENDIF.
    " 동일한 자재명이 DB에 있을 때 CONFIRM POPUP.
  ELSE.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        TITLEBAR              = '자재 MASTER 데이터 수정'
        TEXT_QUESTION         = '이미 동일한 자재명을 가진 데이터가 존재합니다, 그래도 수정하시겠습니까?'
        TEXT_BUTTON_1         = 'YES'
        TEXT_BUTTON_2         = 'NO'
        DISPLAY_CANCEL_BUTTON = ''
      IMPORTING
        ANSWER                = GV_ANSWER
      EXCEPTIONS
        TEXT_NOT_FOUND        = 1
        OTHERS                = 2.
    IF SY-SUBRC <> 0.
      MESSAGE E016.
    ENDIF.
  ENDIF.

  "CONFIRM POPUP 에서 'YES' 선택 시.
  IF GV_ANSWER = 1.

    " DIALOG에 입력한 DATA를 WA에 할당.
    MOVE-CORRESPONDING ZSBMM1010_STR TO GS_DATA100.

    "타임스탬프 Update.
    PERFORM CHANGE_TIMESTAMP.

    "Trasnparent Table TYPE WA에 입력한 DATA 할당.
    MOVE-CORRESPONDING GS_DATA100 TO GS_ZTBMM1010.
    MOVE-CORRESPONDING GS_DATA100 TO GS_ZTBMM1011.

    "Transparent Table DB Update.
    UPDATE ZTBMM1010 FROM GS_ZTBMM1010.
    UPDATE ZTBMM1011 FROM GS_ZTBMM1011.

    IF SY-SUBRC = 0.
      "ALV에 데이터 DISPLAY 하는 INTERNAL TABLE의 해당 DATA Update.
      MODIFY GT_DATA100 FROM GS_DATA100 INDEX GS_ROW-ROW_ID.
      MESSAGE S011.
    ELSE.
      MESSAGE S012 DISPLAY LIKE 'E'.
    ENDIF.

    CLEAR: GS_DATA100.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_DELETE_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM DELETE_DATA .
  "CONFIRM POPUP.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR              = '자재 MASTER 데이터 삭제'
      TEXT_QUESTION         = '해당 데이터를 삭제하시겠습니까?'
      TEXT_BUTTON_1         = 'YES'
      TEXT_BUTTON_2         = 'NO'
      DISPLAY_CANCEL_BUTTON = ''
    IMPORTING
      ANSWER                = GV_ANSWER
    EXCEPTIONS
      TEXT_NOT_FOUND        = 1
      OTHERS                = 2.
  IF SY-SUBRC <> 0.
  ENDIF.

  "CONFIRM POPUP 에서 'YES' 선택 시.
  IF GV_ANSWER = 1.

    "타임스탬프 Update.
    PERFORM CHANGE_TIMESTAMP.

    "해당 데이터의 DELFLG 필드 값에 'X' 할당.
    GS_DATA100-DELFLG = 'X'.

    "Trasnparent Table TYPE WORK AREA에 입력한 DATA 할당.
    MOVE-CORRESPONDING GS_DATA100 TO GS_ZTBMM1010.
    MOVE-CORRESPONDING GS_DATA100 TO GS_ZTBMM1011.

    "Transparent Table DB Update.
    UPDATE ZTBMM1010 FROM GS_ZTBMM1010.
    UPDATE ZTBMM1011 FROM GS_ZTBMM1011.

    "ALV에 데이터 DISPLAY 하는 INTERNAL TABLE의 해당 DATA Update.
    IF SY-SUBRC = 0.
      MODIFY GT_DATA100 FROM GS_DATA100 INDEX GS_ROW-ROW_ID.
      MESSAGE S013.
    ELSE.
      MESSAGE S007 DISPLAY LIKE 'E'.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_CLEAR_ALL
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_REFRESH .
  CLEAR: GT_DATA100, GS_DATA100, ZSBMM1010_STR-MATCODE, ZSBMM1010_STR-MATNAME, ZSBMM1010_STR-ALL, ZSBMM1010_STR-DEL.
  ZSBMM1010_STR-VAL = 'X'.

* ALV REFRESH -> 변경 사항 적용해서 화면에 보여주기 위함
  CALL METHOD GO_ALV->REFRESH_TABLE_DISPLAY
    EXCEPTIONS
      FINISHED = 1
      OTHERS   = 2.
  IF SY-SUBRC <> 0.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_RADIO_BUTTON
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_RADIO_BUTTON .
  " 프로그램 실행 시 & '새로고침' 버튼 눌렀을 때 radio button default 설정.
  IF  ZSBMM1010_STR-ALL IS INITIAL
    AND ZSBMM1010_STR-VAL IS INITIAL
    AND ZSBMM1010_STR-DEL IS INITIAL.
    ZSBMM1010_STR-VAL = 'X'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_ACTIVETAB
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_ACTIVETAB .
  "TAB STRIP 에서 선택한 TAB에 따라 불러온 SUB SCREEN 설정.
  CASE TAB-ACTIVETAB.
    WHEN 'TAB1'.
      GV_DYNNR = '0130'.
    WHEN 'TAB2'.
      GV_DYNNR = '0140'.
    WHEN 'TAB3'.
      GV_DYNNR = '0150'.
    WHEN OTHERS.
      TAB-ACTIVETAB = 'TAB1'.
      GV_DYNNR = '0130'.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_GET_SALES
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_SALES .
  " 'KR', 'US', 'CH', 'DE' 국가마다 다른 완제품 가격 데이터를 불러옴.

  SELECT SINGLE A~CTRYCODE, A~PRICE, A~CURRENCY, B~CTRYNAME
  FROM ZTBSD0080 AS A JOIN ZTBSD1040 AS B
  ON A~CTRYCODE = B~CTRYCODE
  WHERE MATCODE = @GS_DATA100-MATCODE
  AND A~CTRYCODE = 'KR'
  INTO (@ZSBMM1010_SUB-CTRYCODE1, @ZSBMM1010_SUB-PRICE1, @ZSBMM1010_SUB-CURRENCY1, @ZSBMM1010_SUB-CTRYNAME1).

  SELECT SINGLE A~CTRYCODE, A~PRICE, A~CURRENCY, B~CTRYNAME
  FROM ZTBSD0080 AS A JOIN ZTBSD1040 AS B
  ON A~CTRYCODE = B~CTRYCODE
  WHERE MATCODE = @GS_DATA100-MATCODE
  AND A~CTRYCODE = 'US'
  INTO (@ZSBMM1010_SUB-CTRYCODE2, @ZSBMM1010_SUB-PRICE2, @ZSBMM1010_SUB-CURRENCY2, @ZSBMM1010_SUB-CTRYNAME2).

  SELECT SINGLE A~CTRYCODE, A~PRICE, A~CURRENCY, B~CTRYNAME
  FROM ZTBSD0080 AS A JOIN ZTBSD1040 AS B
  ON A~CTRYCODE = B~CTRYCODE
  WHERE MATCODE = @GS_DATA100-MATCODE
  AND A~CTRYCODE = 'CH'
  INTO (@ZSBMM1010_SUB-CTRYCODE3, @ZSBMM1010_SUB-PRICE3, @ZSBMM1010_SUB-CURRENCY3, @ZSBMM1010_SUB-CTRYNAME3).

  SELECT SINGLE A~CTRYCODE, A~PRICE, A~CURRENCY, B~CTRYNAME
  FROM ZTBSD0080 AS A JOIN ZTBSD1040 AS B
  ON A~CTRYCODE = B~CTRYCODE
  WHERE MATCODE = @GS_DATA100-MATCODE
  AND A~CTRYCODE = 'DE'
  INTO (@ZSBMM1010_SUB-CTRYCODE4, @ZSBMM1010_SUB-PRICE4, @ZSBMM1010_SUB-CURRENCY4, @ZSBMM1010_SUB-CTRYNAME4).

  ZSBMM1010_SUB-MATCODE = GS_DATA100-MATCODE.
  ZSBMM1010_SUB-MATNAME = GS_DATA100-MATNAME.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_GET_PRODUCTION
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_PRODUCTION .
  SELECT SINGLE B~ROUTID, B~PRCTIME, B~LABCOST, B~CURRENCY, B~PRDQUAN, B~UNITCODE
    FROM ZTBPP0061 AS A JOIN ZTBPP0060 AS B
    ON A~ROUTID = B~ROUTID
    WHERE A~MATCODE = @GS_DATA100-MATCODE
    INTO (@ZSBMM1010_SUB-ROUTID, @ZSBMM1010_SUB-PRCTIME,
          @ZSBMM1010_SUB-LABCOST, @ZSBMM1010_SUB-CURRENCY5, @ZSBMM1010_SUB-PRDQUAN,
          @ZSBMM1010_SUB-UNITCODE1).

  SELECT SINGLE BOMID
    FROM ZTBPP0070
    WHERE MATCODE = @GS_DATA100-MATCODE
    INTO @ZSBMM1010_SUB-BOMID.

  ZSBMM1010_SUB-MATCODE = GS_DATA100-MATCODE.
  ZSBMM1010_SUB-MATNAME = GS_DATA100-MATNAME.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_GET_PURCHASE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_PURCHASE .
  SELECT SINGLE *
    FROM ZTBMM0070 AS A JOIN ZTBSD1051 AS B
    ON A~BPCODE = B~BPCODE
    WHERE A~MATCODE = @GS_DATA100-MATCODE
    INTO CORRESPONDING FIELDS OF @ZSBMM1010_SUB.

  ZSBMM1010_SUB-MATCODE = GS_DATA100-MATCODE.
  ZSBMM1010_SUB-MATNAME = GS_DATA100-MATNAME.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form TIMESTAMP_CHANGE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CHANGE_TIMESTAMP.
  SELECT SINGLE EMPID
  INTO GS_DATA100-STAMP_USER_L
  FROM ZTBSD1030
  WHERE LOGID = SY-UNAME.

  GS_DATA100-STAMP_DATE_L = SY-DATUM.
  GS_DATA100-STAMP_TIME_L = SY-UZEIT.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_CRE_EMP
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_CRE_EMP .
  SELECT SINGLE *
    FROM ZTBSD1030 AS A JOIN ZTBSD1020 AS B
    ON A~DEPCODE = B~DEPCODE
    WHERE A~EMPID = @GS_DATA100-STAMP_USER_F
    INTO CORRESPONDING FIELDS OF @ZVBMM1010.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_CHA_EMP
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_CHA_EMP .
  SELECT SINGLE *
    FROM ZTBSD1030 AS A JOIN ZTBSD1020 AS B
    ON A~DEPCODE = B~DEPCODE
    WHERE A~EMPID = @GS_DATA100-STAMP_USER_L
    INTO CORRESPONDING FIELDS OF @ZVBMM1010.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form HANDLE_TOOLBAR
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_OBJECT
*&---------------------------------------------------------------------*
FORM HANDLE_TOOLBAR USING PO_OBJECT TYPE REF TO CL_ALV_EVENT_TOOLBAR_SET.

  DATA LS_BUTTON LIKE LINE OF PO_OBJECT->MT_TOOLBAR.

* 구분자 추가
  CLEAR LS_BUTTON.
  LS_BUTTON-BUTN_TYPE = 3. " 구분자(SEPARATOR)
  APPEND LS_BUTTON TO PO_OBJECT->MT_TOOLBAR.

  DATA LV_COUNT   TYPE I. " 전체( TOTAL )
  DATA LV_COUNT_M TYPE I. " 구매자재( M )
  DATA LV_COUNT_S TYPE I. " 반제품( S )
  DATA LV_COUNT_C TYPE I. " 완제품( C )

  LOOP AT GT_DATA100 INTO GS_DATA100.

    ADD 1 TO LV_COUNT.

    CASE GS_DATA100-MATTYPE.
      WHEN 'M'.
        ADD 1 TO LV_COUNT_M.
      WHEN 'S'.
        ADD 1 TO LV_COUNT_S.
      WHEN 'C'.
        ADD 1 TO LV_COUNT_C.
    ENDCASE.
  ENDLOOP.


* 버튼 [전체: ##] 추가.
  LS_BUTTON-BUTN_TYPE = 0. " 일반 버튼(NORMAL BUTTON)
  LS_BUTTON-TEXT      = '전체: ' && LV_COUNT.
  LS_BUTTON-FUNCTION  = 'FILTER_TOTAL'.
  APPEND LS_BUTTON TO PO_OBJECT->MT_TOOLBAR.
  CLEAR LS_BUTTON.

* 버튼 [구매자재: ##] 추가.
  LS_BUTTON-BUTN_TYPE = 0.
  LS_BUTTON-TEXT      = '구매자재: ' && LV_COUNT_M.
  LS_BUTTON-FUNCTION  = 'FILTER_M'.
  APPEND LS_BUTTON TO PO_OBJECT->MT_TOOLBAR.
  CLEAR LS_BUTTON.

* 버튼 [반제품: ##] 추가.
  LS_BUTTON-BUTN_TYPE = 0.
  LS_BUTTON-TEXT      = '반제품: ' && LV_COUNT_S.
  LS_BUTTON-FUNCTION  = 'FILTER_S'.
  APPEND LS_BUTTON TO PO_OBJECT->MT_TOOLBAR.
  CLEAR LS_BUTTON.

* 버튼 [완제품: ##] 추가.
  LS_BUTTON-BUTN_TYPE = 0.
  LS_BUTTON-TEXT      = '완제품: ' && LV_COUNT_C.
  LS_BUTTON-FUNCTION  = 'FILTER_C'.
  APPEND LS_BUTTON TO PO_OBJECT->MT_TOOLBAR.
  CLEAR LS_BUTTON.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form HANDLE_USER_COMMAND
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_UCOMM
*&---------------------------------------------------------------------*
FORM HANDLE_USER_COMMAND  USING    PV_UCOMM LIKE SY-UCOMM.

  CASE PV_UCOMM.
    WHEN 'FILTER_TOTAL'.
      " '전체'버튼 FILTERING.
      PERFORM APPLY_FILTER USING SPACE.

    WHEN 'FILTER_M'.
*     " '구매자재'버튼 FILTERING.
      PERFORM APPLY_FILTER USING 'M'.

    WHEN 'FILTER_S'.
*     " '반제품'버튼 FILTERING.
      PERFORM APPLY_FILTER USING 'S'.

    WHEN 'FILTER_C'.
*     " '완제품'버튼 FILTERING.
      PERFORM APPLY_FILTER USING 'C'.

  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form APPLY_FILTER
*&---------------------------------------------------------------------*
*& '전체' 버튼 눌렀을 때 FILTERING
*&---------------------------------------------------------------------*
FORM APPLY_FILTER  USING    PA_VALUE.

  DATA: LT_FILTER TYPE LVC_T_FILT,
        LS_FILTER LIKE LINE OF LT_FILTER.


  IF PA_VALUE IS NOT INITIAL.
    CLEAR LS_FILTER.
    LS_FILTER-FIELDNAME = 'MATTYPE'.
    LS_FILTER-SIGN      = 'I'.
    LS_FILTER-OPTION    = 'EQ'.
    LS_FILTER-LOW       = PA_VALUE.
    APPEND LS_FILTER TO LT_FILTER.
  ENDIF.

  " 필터 기준 설정.
  CALL METHOD GO_ALV->SET_FILTER_CRITERIA
    EXPORTING
      IT_FILTER = LT_FILTER.         " FILTER CONDITIONS

  CALL METHOD GO_ALV->REFRESH_TABLE_DISPLAY.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form ZBMM_SET_EVENT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_EVENT .
  " ALV에 툴비 이벤트 핸들링을 위한 메소드를 등록
  SET HANDLER LCL_EVENT_HANDLER=>ON_TOOLBAR FOR GO_ALV.

  " ALV에 USER-COMMAND 이벤트 핸들링을 위한 메소드 등록
  SET HANDLER LCL_EVENT_HANDLER=>ON_USER_COMMAND FOR GO_ALV.
ENDFORM.
