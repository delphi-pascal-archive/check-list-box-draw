{******************************************************************************}
{                                                                              }
{                              Check List Box Demo                             }
{                                                                              }
{                         Copyright (c) 2008 Maksim V.                         }
{                           Email: maks1509@inbox.ru                           }
{                               Thanks ShIvADeSt                               }
{                                                                              }
{******************************************************************************}
{                                                                              }
{ Реализация VCL контрола ChecklistBox на WinApi:                              }
{ Текущая версия примера: 1.0 ревизия 3                                        }
{ Внимание: Этот исходный код несовершенен и в нем могут содержаться ошибки!   }
{                                                                              }
{******************************************************************************}
{                                                                              }
{ Пример показывает следующие возможности:                                     }
{ - Установка и снятие галочки в чекбоксе одного или всех пунктов              }
{ - Получение информации о состоянии выделенности чекбокса в пункте            }
{ - Отображение строк всех выделенных пунктов списка в сообщении               }
{ - Работа с кодировкой Юникод для загрузки и отображения строк                }
{ - Самостоятельная прорисовка строк в списке с некоторыми особенностями       }
{                                                                              }
{******************************************************************************}

program sample;

{$R sample.res}

uses
  Windows, Messages, CommCtrl, F_Classes, F_SysUtils, F_CheckList;

const
  {}
  RC_DIALOG   = 101;
  {}
  IDS_LBITEMS = 1600;
  IDS_LBCHECK = 1601;
  IDS_LBUNCHE = 1602;
  {}
  IDC_LISTBOX = 101;
  IDC_SELALL  = 102;
  IDC_UNSALL  = 103;
  IDC_ISCHECK = 104;
  IDC_ITEMCHK = 105;
  IDC_ITEMUNC = 106;
  IDC_GETTEXT = 107;

var
  hApp : Thandle;

{}
function CheckListBox_GetTextItemsW(hList : Thandle) : WideString;
var
  nItems  : Integer;
  nString : WideString;
begin
  Result := '';
  nItems := SendMessageW(hList, LB_GETCOUNT, 0, 0);
  for nItems := 0 to nItems do
    begin
      if CheckListBox_GetItemStateW(GetDlgItem(hApp, IDC_LISTBOX), nItems) then
        begin
          nString := CheckListBox_GetItemTextW(GetDlgItem(hApp, IDC_LISTBOX), nItems);
          Result := Result + nString + #13#10;
        end;
    end;
  Delete(Result, Length(Result) - 1, 2);
end;

{}
function MainDlgProc(hWnd : HWND; uMsg : UINT; wParam : WPARAM; lParam : LPARAM) : BOOL; stdcall;
var
  I : Integer;
  nItem : Integer;
begin
  Result := FALSE;
  case uMsg of

    {}
    WM_INITDIALOG :
      begin
        hApp := hWnd;
        {}
        CreateCheckListBoxHandleW(hApp, GetDlgItem(hApp, IDC_LISTBOX));
        {}
        for I := 1 to 15 do
          CheckListBox_AddItemW(GetDlgItem(hApp, IDC_LISTBOX), PWideChar(Format(LoadStringW_GetResource(IDS_LBITEMS), [IntToStr(I)])), 0);
        {}
        Exit;
      end;

    {}
    WM_COMMAND :
      case HiWord(wParam) of
        BN_CLICKED :
          case LoWord(wParam) of

            IDC_SELALL :
              CheckListBox_SelAllItemsW(GetDlgItem(hApp, IDC_LISTBOX), TRUE);

            IDC_UNSALL :
              CheckListBox_SelAllItemsW(GetDlgItem(hApp, IDC_LISTBOX), FALSE);

            IDC_ISCHECK :
              begin
                nItem := SendMessageW(GetDlgItem(hApp, IDC_LISTBOX), LB_GETCURSEL, 0, 0);
                if CheckListBox_GetItemStateW(GetDlgItem(hApp, IDC_LISTBOX), nItem) then
                  MessageBoxW(hApp, PWideChar(LoadStringW_GetResource(IDS_LBCHECK)), nil, MB_ICONINFORMATION)
                else
                  MessageBoxW(hApp, PWideChar(LoadStringW_GetResource(IDS_LBUNCHE)), nil, MB_ICONINFORMATION);
              end;

            IDC_ITEMCHK :
              begin
                nItem := SendMessageW(GetDlgItem(hApp, IDC_LISTBOX), LB_GETCURSEL, 0, 0);
                CheckListBox_SetCheckStateW(GetDlgItem(hApp, IDC_LISTBOX), nItem, TRUE);
              end;

            IDC_ITEMUNC :
              begin
                nItem := SendMessageW(GetDlgItem(hApp, IDC_LISTBOX), LB_GETCURSEL, 0, 0);
                CheckListBox_SetCheckStateW(GetDlgItem(hApp, IDC_LISTBOX), nItem, FALSE);
              end;

            IDC_GETTEXT :
              MessageBoxW(hApp, PWideChar(CheckListBox_GetTextItemsW(GetDlgItem(hApp, IDC_LISTBOX))), nil, MB_ICONINFORMATION);

          end;
      end;

    {}
    WM_THEMECHANGED :
      ThemeChangedCheckListBoxW(hApp);
      
    {}
    WM_MEASUREITEM :
      begin
        case wParam of
          IDC_LISTBOX :
            CheckListBox_OnMeasureItemW(PMEASUREITEMSTRUCT(lParam));
        end;
      end;

    {}
    WM_DRAWITEM :
      begin
        case LoWord(wParam) of
          IDC_LISTBOX :
            CheckListBox_OnDrawItemW(PDRAWITEMSTRUCT(lParam));
        end;
      end;

    {}
    WM_LBUTTONDOWN :
      begin
        SetCursor(LoadCursorW(0, IDC_SIZEALL));
        SendMessageW(hApp, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
      end;

    {}
    WM_DESTROY, WM_CLOSE :
      begin
        DeleteCheckListBoxHandleW(hApp);
        {}
        PostQuitMessage(0);
      end;

  end;
end;

begin
  {}
  InitCommonControls;
  {}
  DialogBoxW(hInstance, PWideChar(RC_DIALOG), 0, @MainDlgProc);
end.