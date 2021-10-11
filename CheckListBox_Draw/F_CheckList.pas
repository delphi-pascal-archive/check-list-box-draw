unit F_CheckList;

// Автор первоначального кода - Maksim V.
// Помощь в разработке и подсказки - ShIvADeSt.
// Версия модуля 1.0 ревизия 3

interface

uses
  Windows, Messages, F_Classes, F_UxTheme;

{ Получение текста с выделенного пункта списке }
function CheckListBox_GetItemTextW(hList : Thandle; nItem : Integer) : WideString;
{ Установка состояния выделенному элементу в списке }
procedure CheckListBox_SetCheckStateW(hList : Thandle; nItem : Integer; nFlag : Boolean);
{ Выделение и снятие выделения элементов списка }
procedure CheckListBox_SelAllItemsW(hList : Thandle; nFlag : Boolean);
{ Получение состояния выделенности элемента в списке }
function CheckListBox_GetItemStateW(hList : Thandle; nItem : Integer) : Boolean;
{ Функция сабклассирования списка для записи/чтения данных}
function NewLstProcW(hList : HWND; uMsg : UINT; wParam : WPARAM; lParam : LPARAM) : LRESULT; stdcall;
{ Добавление новой записи в пункты списка }
procedure CheckListBox_AddItemW(hList : THandle; lpstr : PWideChar; check : LPARAM);
{ Прорисовка элементов списка }
procedure CheckListBox_OnMeasureItemW(lpmis : PMEASUREITEMSTRUCT);
{ Прорисовка элементов списка }
procedure CheckListBox_OnDrawItemW(lpdis : PDRAWITEMSTRUCT);
{ Создание списка с чекбоксами }
procedure CreateCheckListBoxHandleW(hWnd, hList : Thandle);
{ Удаление списка с чекбоксами }
procedure DeleteCheckListBoxHandleW(hList : Thandle);
{ Уведомление о смене темы оформления списка }
procedure ThemeChangedCheckListBoxW(hWnd : Thandle);

var
  { Указатель на старую функцию }
  OldLstProcW : Pointer;
  { Хэндл открытой темы оформления }
  CheckThemeW : hTheme;

implementation

function CheckListBox_GetItemTextW(hList : Thandle; nItem : Integer) : WideString;
var
  nLength : Integer;
  nBuffer : PChar;
begin
  Result := '';
  nLength := SendMessageW(hList, LB_GETTEXTLEN, WPARAM(nItem), 0);
  GetMem(nBuffer, nLength + 1);
  SendMessage(hList, LB_GETTEXT, WPARAM(nItem), LPARAM(nBuffer));
  SetString(Result, nBuffer, nLength);
  FreeMem(nBuffer);
end;

procedure CheckListBox_SetCheckStateW(hList : Thandle; nItem : Integer; nFlag : Boolean);
var
  itemdata : LongInt;
begin
  if nItem > -1 then
    begin
      itemdata := Integer(nFlag);
      SendMessageW(hList, LB_SETITEMDATA, nItem, itemdata);
      InvalidateRect(hList, nil, FALSE);
    end;
end;

procedure CheckListBox_SelAllItemsW(hList : Thandle; nFlag : Boolean);
var 
  nItems   : Integer; 
  nItem    : Integer; 
  itemdata : LongInt; 
begin 
  nItems := SendMessageW(hList, LB_GETCOUNT, 0, 0); 
  if nItems > -1 then
    begin 
      itemdata := Integer(nFlag); 
      for nItem := 0 to nItems do 
        begin 
          SendMessageW(hList, LB_SETITEMDATA, nItem, itemdata); 
          InvalidateRect(hList, nil, FALSE); 
        end; 
    end; 
end;

function CheckListBox_GetItemStateW(hList : Thandle; nItem : Integer) : Boolean;
var
  itemdata : LongInt;
begin
  if nItem > -1 then
    begin
      //SendMessageW(hList, LB_SETCURSEL, nItem, 0);
      itemdata := SendMessageW(hList, LB_GETITEMDATA, nItem, 0);
      Result := BOOL(itemdata);
    end
  else
    Result := FALSE;
end;

function NewLstProcW(hList : HWND; uMsg : UINT; wParam : WPARAM; lParam : LPARAM) : LRESULT; stdcall;
var
  nItem    : Integer;
  itemdata : LongInt;
  nItemrc  : TRect;
  nItemcur : TPoint;
begin
  Result := 0;
  case uMsg of

    WM_GETDLGCODE :
      begin
        Result := DLGC_WANTALLKEYS;
        Exit;
      end;

    WM_LBUTTONDBLCLK :
      begin
        nItem := SendMessageW(hList, LB_GETTOPINDEX, 0, 0) + HiWord(lParam) div SendMessage(hList, LB_GETITEMHEIGHT, 0, 0);
        itemdata := SendMessageW(hList, LB_GETITEMDATA, nItem, 0);
        GetCursorPos(nItemcur);
        SendMessageW(hList, LB_GETITEMRECT, SendMessage(hList, LB_GETCURSEL, 0, 0), Integer(@nItemrc));
        ScreenToClient(hList, nItemcur);
        if ((nItemcur.X - nItemrc.Left) < 18) then
          begin
            if itemdata <> 0 then
              itemdata := 0
            else
              itemdata := 1;
          end;
        SendMessageW(hList, LB_SETITEMDATA, nItem, itemdata);
        GetClientRect(hList, nItemrc);
        InvalidateRect(hList, nil, FALSE);
      end;

    WM_RBUTTONDOWN :
      begin
        nItem := SendMessageW(hList, LB_GETTOPINDEX, 0, 0) + HiWord(lParam) div SendMessage(hList, LB_GETITEMHEIGHT, 0, 0);
        SendMessageW(hList, LB_SETCURSEL, nItem, 0);
      end;

  else
    Result := CallWindowProc(OldLstProcW, hList, uMsg, wParam, lParam);
  end;
end;

procedure CheckListBox_AddItemW(hList : THandle; lpstr : PWideChar; check : LPARAM);
var
  nItem : Integer;
begin
  nItem := SendMessageW(hList, LB_ADDSTRING, 0, LPARAM(lpstr));
  SendMessage(hList, LB_SETITEMDATA, nItem, LPARAM(check));
end;

procedure CheckListBox_OnMeasureItemW(lpmis : PMEASUREITEMSTRUCT);
begin
  lpmis.itemHeight := 17;
end;

procedure CheckListBox_OnDrawItemW(lpdis : PDRAWITEMSTRUCT);
var
  tchBuffer : Array [0..MAX_PATH] of WideChar;
  itemdata  : LongInt;
  newStyle  : Integer;
  oldStyle  : Integer;
  BrushNew  : hBrush;
  BrushOld  : hBrush;
begin
  if lpdis.ItemID < 4294967295 then // [lpdis.ItemID : LongInt] -> [if lpdis.ItemID > -1]
    begin

      if ((lpdis.itemState and ODS_SELECTED) <> 0) then
        begin
          FillRect(lpdis.hdc, lpdis.rcItem, GetSysColorBrush(COLOR_HIGHLIGHT));
          SetBkMode(lpdis.hDC, TRANSPARENT);
          SetBkColor(lpdis.hdc, GetSysColor(COLOR_HIGHLIGHT));
          SetTextColor(lpdis.hdc, GetSysColor(COLOR_HIGHLIGHTTEXT));
        end
      else
        begin
          FillRect(lpdis.hdc, lpdis.rcItem, GetSysColorBrush(COLOR_WINDOW));
          SetBkMode(lpdis.hDC, TRANSPARENT);
          SetBkColor(lpdis.hdc, GetSysColor(COLOR_WINDOW));
          SetTextColor(lpdis.hdc, GetSysColor(COLOR_WINDOWTEXT));
          if (lpdis.itemID mod 2) <> 0 then
            begin
              BrushNew := CreateSolidBrush(RGB(240, 240, 240));
              BrushOld := SelectObject(lpdis.hdc, BrushNew);
              FillRect(lpdis.hdc, lpdis.rcItem, BrushNew);
              SetBkMode(lpdis.hdc, TRANSPARENT);
              SetBkColor(lpdis.hdc, RGB(240, 240, 240));
              SelectObject(lpdis.hdc, BrushOld);
              DeleteObject(BrushNew);
            end;
        end;

      itemdata := SendMessageW(lpdis.hwndItem, LB_GETITEMDATA, lpdis.itemID, 0);
      if itemdata <> 0 then
        begin
          newStyle := CBS_CHECKEDNORMAL;
          oldStyle := DFCS_BUTTONCHECK or DFCS_CHECKED or DFCS_FLAT;
        end
      else
        begin
          newStyle := CBS_UNCHECKEDNORMAL;
          oldStyle := DFCS_BUTTONCHECK or DFCS_FLAT;
        end;

      if InitThemeLibrary and UseThemes then
        DrawThemeBackground(CheckThemeW, lpdis.hdc, BP_CHECKBOX, newStyle, Rect(lpdis.rcItem.Left + 2, lpdis.rcItem.Top + 2, lpdis.rcItem.Left + lpdis.rcItem.Bottom - lpdis.rcItem.Top - 1, lpdis.rcItem.Bottom - 2), nil)
      else
        DrawFrameControl(lpdis.hdc, Rect(lpdis.rcItem.Left + 2, lpdis.rcItem.Top + 2, lpdis.rcItem.Left + lpdis.rcItem.Bottom - lpdis.rcItem.Top - 1, lpdis.rcItem.Bottom - 2), DFC_BUTTON, oldStyle);

      SendMessageW(lpdis.hwndItem, LB_GETTEXT, lpdis.itemID, LPARAM(@tchBuffer));
      lpdis.rcItem.Left := lpdis.rcItem.Left + 19;
      DrawTextW(lpdis.hdc, @tchBuffer[0], -1, lpdis.rcItem, DT_SINGLELINE or DT_VCENTER);
      lpdis.rcItem.Left := lpdis.rcItem.Left - 19;

      if ((lpdis.itemState and ODS_FOCUS) <> 0) then
        DrawFocusRect(lpdis.hdc, lpdis.rcItem);

    end
  else
    begin
      FillRect(lpdis.hdc, lpdis.rcItem, GetSysColorBrush(COLOR_WINDOW));
      SetBkMode(lpdis.hdc, TRANSPARENT);
      SetBkColor(lpdis.hdc, TRANSPARENT);
      SetTextColor(lpdis.hdc, GetSysColor(COLOR_WINDOWTEXT));
    end;
end;

procedure CreateCheckListBoxHandleW(hWnd, hList : Thandle);
begin
  if InitThemeLibrary and UseThemes then
    CheckThemeW := OpenThemeData(hWnd, 'Button');
  OldLstProcW := Pointer(SetWindowLongW(hList, GWL_WNDPROC, LongInt(@NewLstProcW)));
end;

procedure DeleteCheckListBoxHandleW(hList : Thandle);
begin
  if InitThemeLibrary and UseThemes then
    CloseThemeData(CheckThemeW);
  SetWindowLongW(hList, GWL_WNDPROC, LongInt(OldLstProcW));
end;

procedure ThemeChangedCheckListBoxW(hWnd : Thandle);
begin
  if InitThemeLibrary and UseThemes then
    begin
      CloseThemeData(CheckThemeW);
      CheckThemeW := OpenThemeData(hWnd, 'Button');
    end;
end;

end.