*&---------------------------------------------------------------------*
*& Include          ZBMM0010I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0100 INPUT.
  CASE OK_CODE.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.

      " '조회' 버튼 클릭 시.
    WHEN 'BTN1'.
      PERFORM GET_DATA.

      " '생성' 버튼 클릭 시.
    WHEN 'CREATE'.
      CALL SCREEN 110
        STARTING AT 80 7.

      " '수정' 버튼 클릭 시.
    WHEN 'CHANGE' OR 'DELETE'.
      PERFORM DATA_SELECTED_ROW.
      CLEAR GS_DATA100.

      " '새로고침' 버튼 클릭 시.
    WHEN 'REFRESH'.
      PERFORM SET_REFRESH.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE EXIT INPUT.
  CASE OK_CODE.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'CANCEL'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0110  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0110 INPUT.
  CASE OK_CODE.
    WHEN 'SAVEE'.
      PERFORM SAVE_DATA.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0120  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0120 INPUT.
  CASE OK_CODE.
    WHEN 'SAVEE'.
      PERFORM CHANGE_DATA.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0170  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0170 INPUT.
  CASE OK_CODE.
    "TAB STRIP 버튼 클릭 시 활성화.
    WHEN 'TAB1' OR 'TAB2' OR 'TAB3'.
      TAB-ACTIVETAB = OK_CODE.
  ENDCASE.
ENDMODULE.
