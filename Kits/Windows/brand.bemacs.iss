;
; -- bemacs.iss --
;

[Code]
function InitializeSetup(): Boolean;
var
	uninstall_string : string;
	uninstall_image	: string;
	uninstall_params : string;
	Error: Integer;
	space_pos : Integer;
	rc : Integer;
	rcb : Boolean;
begin
	Error := 0;
	rcb := RegQueryStringValue( HKLM,
		'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Barry''s Emacs',
		'UninstallString', uninstall_string );
	if rcb then
	begin
		rc := MsgBox( 'An old version of Barry''s Emacs is installed.' #13 #13
				'It must be uninstalled before installing the this version' #13
				'Do you wish to uninstall it now?', mbConfirmation, MB_YESNO );
		if rc = idYes then
		begin
			space_pos := Pos( ' ', uninstall_string );
			uninstall_image := Copy( uninstall_string, 1, space_pos-1 );
			uninstall_params := Copy( uninstall_string, space_pos, 999 );
			rcb := InstExec(uninstall_image, uninstall_params, ExpandConstant('{src}'), True, True, SW_SHOWNORMAL, Error);
			if not rcb then
				MsgBox( 'Failed to run the uninstall procedure.' #13 #13
					'Please uninstall the old Barry''s Emacs' #13
					'and try this installation again.', mbError, MB_OK );
			if Error <> 0 then
				MsgBox( 'Failed to run the uninstall procedure.' #13 #13
					'Please uninstall the old Barry''s Emacs' #13
					'and try this installation again.', mbError, MB_OK );
		end;
	end;
	BringToFrontAndRestore;
	rcb := RegQueryStringValue( HKLM,
		'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Barry''s Emacs',
		'UninstallString', uninstall_string );
	Result := not rcb;
	if not Result then
		rc := MsgBox(	'Quitting installation.' #13 #13
				'An old version of Barry''s Emacs is still installed.' #13
				'Run this installation again after the old kit has' #13
				'been uninstalled', mbInformation, MB_OK );
end;

[Setup]
AppName=Barry's Emacs
AppVerName=Barry's Emacs %(maturity)s%(major)s.%(minor)s
AppCopyright=Copyright (C) 1991-%(year)s Barry A. Scott
DefaultDirName={pf}\Barry Scott\Barry's Emacs
DefaultGroupName=Barry's Emacs
UninstallDisplayIcon={app}\bemacs.exe
ChangesAssociations=yes
DisableStartupPrompt=yes
InfoBeforeFile=info_before.txt
Compression=bzip/9
; uncomment the following line if you want your installation to run on NT 3.51 too.
; MinVersion=4,3.51

[Tasks]
Name: "option_register_emacs_open_ml"; Description: "Barry's Emacs will open .ML and .MLP files"
Name: "option_register_emacs_open_c_dont"; Description: "No association"; GroupDescription: "How should Barry's Emacs be associated with Cand C++ Source Files"; Flags: exclusive
Name: "option_register_emacs_open_c_one_type"; Description: "Associate using one file type"; GroupDescription: "How should Barry's Emacs be associated with Cand C++ Source Files"; Flags: exclusive
Name: "option_register_emacs_open_c_many_types"; Description: "Associate using multiple file types"; GroupDescription: "How should Barry's Emacs be associated with Cand C++ Source Files"; Flags: exclusive
Name: "option_desktop_icon"; Description: "Place Barry's Emacs icon on the Desktop"
Name: "option_start_menu_icon"; Description: "Place Barry's Emacs on the Start menu"
Name: "option_edit_with_bemacs"; Description: "Place Edit with Barry's Emacs on the Context menu"

[Run]
Filename: "{app}\BEmacsServer.EXE"; Parameters: "/regserver"
Filename: "{app}\BEmacs.EXE"; Parameters: """{app}\readme.txt"""; Flags: nowait postinstall skipifsilent; Description: "View README.TXT"

[UninstallRun]
Filename: "{app}\BEmacsServer.EXE"; Parameters: "/unregserver"


[Files]

#include "msvc_system_files.iss"

Source: "Readme.txt"; DestDir: "{app}";
Source: "win32\BEmacs.exe"; DestDir: "{app}"
Source: "win32\BEmacsWait.exe"; DestDir: "{app}"
Source: "win32\Vss-View.exe"; DestDir: "{app}"
Source: "win32\BEmacsServer.exe"; DestDir: "{app}"
Source: "win32\BEmacsClassMoniker.dll"; DestDir: "{app}"; Flags: regserver

Source: "win32\dbadd.exe"; DestDir: "{app}"
Source: "win32\dbcreate.exe"; DestDir: "{app}"
Source: "win32\dbdel.exe"; DestDir: "{app}"
Source: "win32\dblist.exe"; DestDir: "{app}"
Source: "win32\dbprint.exe"; DestDir: "{app}"
Source: "win32\mll-2-db.exe"; DestDir: "{app}"

Source: "..\Editor\BEmacsComClient\make_bemacs_cmd.py"; DestDir: "{app}\Contrib"

Source: "..\Editor\Include\Windows\ExternalInclude\BarrysEmacs.h"; DestDir: "{app}\Library"
Source: "..\Editor\Include\Windows\ExternalInclude\BarrysEmacs.tlb"; DestDir: "{app}\Library"

Source: "..\MLisp\Library\Python\bemacs_stdio.py"; DestDir: "{app}\Library"

Source: "win32\EmacsDesc.dat"; DestDir: "{app}\Library"
Source: "win32\EmacsDesc.dir"; DestDir: "{app}\Library"
Source: "win32\EmacsDesc.pag"; DestDir: "{app}\Library"

Source: "..\mlisp\emacsinit.ml"; DestDir: "{app}\Library"
Source: "..\mlisp\emacs_profile.ml"; DestDir: "{app}\Library"

Source: "win32\EmacsLang.dat"; DestDir: "{app}\Library"
Source: "win32\EmacsLang.dir"; DestDir: "{app}\Library"
Source: "win32\EmacsLang.pag"; DestDir: "{app}\Library"

Source: "win32\emacslib.dat"; DestDir: "{app}\Library"
Source: "win32\emacslib.dir"; DestDir: "{app}\Library"
Source: "win32\emacslib.pag"; DestDir: "{app}\Library"

Source: "win32\emacs_qinfo_c.dat"; DestDir: "{app}\Library"
Source: "win32\emacs_qinfo_c.dir"; DestDir: "{app}\Library"
Source: "win32\emacs_qinfo_c.pag"; DestDir: "{app}\Library"

Source: "..\HTML\*.css"; DestDir: "{app}\Documentation";
Source: "..\HTML\*.htm"; DestDir: "{app}\Documentation";
Source: "..\HTML\*.gif"; DestDir: "{app}\Documentation";
Source: "..\HTML\*.js"; DestDir: "{app}\Documentation";

[Icons]
Name: "{group}\Barry's Emacs"; Filename: "{app}\bemacs.exe"
Name: "{group}\Barry's Emacs Server"; Filename: "{app}\BEmacsServer.exe"
Name: "{group}\Barry's Emacs without Restore"; Filename: "{app}\BEmacsServer.exe"; Parameters: "/norestore"
Name: "{group}\Documentation"; Filename: "{app}\Documentation\emacs-documentation.htm"
Name: "{group}\FAQ"; Filename: "{app}\documentation\bemacs-faq.htm"
Name: "{group}\Readme"; Filename: "{app}\bemacs.exe"; Parameters: """{app}\readme.txt"""
Name: "{group}\Barry's Emacs Web Site"; Filename: "http://www.barrys-emacs.org";
;
;	Add an Emacs icon to the Desktop
;
Name: "{commondesktop}\Barry's Emacs"; Filename: "{app}\bemacs.exe"; Tasks: "option_desktop_icon"

;
;	Add an Emacs icon to the Start menu
;
Name: "{commonstartmenu}\Barry's Emacs"; Filename: "{app}\bemacs.exe"; Tasks: "option_start_menu_icon"

[Registry]
Root: HKCR; Subkey: "BarrysEmacsCommand"; ValueType: string; ValueData: "BEmacs Command"; Flags: uninsdeletekey
Root: HKCR; Subkey: "BarrysEmacsCommand\Shell\open\command"; ValueType: string; ValueData: "{app}\bemacs.exe /package=""%%1"""
Root: HKCR; Subkey: "BarrysEmacsCommand\DefaultIcon"; ValueType: string; ValueData: "{app}\bemacs.exe,2"

Root: HKCR; Subkey: "BarrysEmacsMLisp"; ValueType: string; ValueData: "BEmacs MLisp"; Flags: uninsdeletekey
Root: HKCR; Subkey: "BarrysEmacsMLisp\Shell\open\command"; ValueType: string; ValueData: "{app}\bemacs.exe ""%%1"""
Root: HKCR; Subkey: "BarrysEmacsMLisp\DefaultIcon"; ValueType: string; ValueData: "{app}\bemacs.exe,2"

Root: HKCR; Subkey: "BarrysEmacsDocument"; ValueType: string; ValueData: "BEmacs"; Flags: uninsdeletekey
Root: HKCR; Subkey: "BarrysEmacsDocument\Shell\open\command"; ValueType: string; ValueData: "{app}\bemacs.exe ""%%1"""
Root: HKCR; Subkey: "BarrysEmacsDocument\DefaultIcon"; ValueType: string; ValueData: "{app}\bemacs.exe,3"

Root: HKCR; Subkey: "BarrysEmacsDocumentII"; ValueType: string; ValueData: "BEmacs II"; Flags: uninsdeletekey
Root: HKCR; Subkey: "BarrysEmacsDocumentII\Shell\open\command"; ValueType: string; ValueData: "{app}\bemacs.exe ""%%1"""
Root: HKCR; Subkey: "BarrysEmacsDocumentII\DefaultIcon"; ValueType: string; ValueData: "{app}\bemacs.exe,4"

Root: HKCR; Subkey: "BarrysEmacsDocumentIII"; ValueType: string; ValueData: "BEmacs III"; Flags: uninsdeletekey
Root: HKCR; Subkey: "BarrysEmacsDocumentIII\Shell\open\command"; ValueType: string; ValueData: "{app}\bemacs.exe ""%%1"""
Root: HKCR; Subkey: "BarrysEmacsDocumentIII\DefaultIcon"; ValueType: string; ValueData: "{app}\bemacs.exe,5"

Root: HKCR; Subkey: "BarrysEmacsDocumentIV"; ValueType: string; ValueData: "BEmacs IV"; Flags: uninsdeletekey
Root: HKCR; Subkey: "BarrysEmacsDocumentIV\Shell\open\command"; ValueType: string; ValueData: "{app}\bemacs.exe ""%%1"""
Root: HKCR; Subkey: "BarrysEmacsDocumentIV\DefaultIcon"; ValueType: string; ValueData: "{app}\bemacs.exe,6"

Root: HKCR; Subkey: "BarrysEmacsDocumentV"; ValueType: string; ValueData: "BEmacs V"; Flags: uninsdeletekey
Root: HKCR; Subkey: "BarrysEmacsDocumentV\Shell\open\command"; ValueType: string; ValueData: "{app}\bemacs.exe ""%%1"""
Root: HKCR; Subkey: "BarrysEmacsDocumentV\DefaultIcon"; ValueType: string; ValueData: "{app}\bemacs.exe,7"

;
;	Add the Edit with Barry's Emacs to the context menu
;

; option_edit_with_bemacs
Root: HKCR; Subkey: "*\shell\Edit with Barry's Emacs"; ValueType: string; ValueData: "Edit with &Barry's Emacs"; Flags: uninsdeletekey
Root: HKCR; Subkey: "*\shell\Edit with Barry's Emacs\command"; ValueType: string; ValueData: "{app}\bemacs.exe ""%%1"""

Root: HKCR; Subkey: "Drive\shell\Barry's Emacs Here"; ValueType: string; ValueData: "Barry's Emacs &Here"; Flags: uninsdeletekey
Root: HKCR; Subkey: "Drive\shell\Barry's Emacs Here\command"; ValueType: string; ValueData: "{app}\bemacs.exe /package=shell-chdir-here ""%%1\.."""

Root: HKCR; Subkey: "Directory\shell\Barry's Emacs Here"; ValueType: string; ValueData: "Barry's Emacs &Here"; Flags: uninsdeletekey
Root: HKCR; Subkey: "Directory\shell\Barry's Emacs Here\command"; ValueType: string; ValueData: "{app}\bemacs.exe /package=shell-chdir-here ""%%1"""

;
; have emacs open .ML files and .MLP files
;
Root: HKCR; SubKey: ".ml"; ValueType: string; ValueData: "BarrysEmacsMLisp"; Tasks: "option_register_emacs_open_ml"; Flags: uninsdeletekey
Root: HKCR; SubKey: ".mlp"; ValueType: string; ValueData: "BarrysEmacsCommand"; Tasks: "option_register_emacs_open_ml"; Flags: uninsdeletekey

;
; register all the C and C++ file types for emacs to open
; either using one type or multiple
;
Root: HKCR; Subkey: ".h"; ValueType: string; ValueData: "BarrysEmacsDocument"; Tasks: "option_register_emacs_open_c_one_type"
Root: HKCR; Subkey: ".hh"; ValueType: string; ValueData: "BarrysEmacsDocument"; Tasks: "option_register_emacs_open_c_one_type"
Root: HKCR; Subkey: ".hpp"; ValueType: string; ValueData: "BarrysEmacsDocument"; Tasks: "option_register_emacs_open_c_one_type"
Root: HKCR; Subkey: ".hxx"; ValueType: string; ValueData: "BarrysEmacsDocument"; Tasks: "option_register_emacs_open_c_one_type"
Root: HKCR; Subkey: ".c"; ValueType: string; ValueData: "BarrysEmacsDocument"; Tasks: "option_register_emacs_open_c_one_type"
Root: HKCR; Subkey: ".cc"; ValueType: string; ValueData: "BarrysEmacsDocument"; Tasks: "option_register_emacs_open_c_one_type"
Root: HKCR; Subkey: ".cpp"; ValueType: string; ValueData: "BarrysEmacsDocument"; Tasks: "option_register_emacs_open_c_one_type"
Root: HKCR; Subkey: ".cxx"; ValueType: string; ValueData: "BarrysEmacsDocument"; Tasks: "option_register_emacs_open_c_one_type"

Root: HKCR; Subkey: ".h"; ValueType: string; ValueData: "BarrysEmacsDocumentII"; Tasks: "option_register_emacs_open_c_many_types"
Root: HKCR; Subkey: ".hh"; ValueType: string; ValueData: "BarrysEmacsDocumentII"; Tasks: "option_register_emacs_open_c_many_types"
Root: HKCR; Subkey: ".hpp"; ValueType: string; ValueData: "BarrysEmacsDocumentII"; Tasks: "option_register_emacs_open_c_many_types"
Root: HKCR; Subkey: ".hxx"; ValueType: string; ValueData: "BarrysEmacsDocumentII"; Tasks: "option_register_emacs_open_c_many_types"
Root: HKCR; Subkey: ".c"; ValueType: string; ValueData: "BarrysEmacsDocumentIII"; Tasks: "option_register_emacs_open_c_many_types"
Root: HKCR; Subkey: ".cc"; ValueType: string; ValueData: "BarrysEmacsDocumentIII"; Tasks: "option_register_emacs_open_c_many_types"
Root: HKCR; Subkey: ".cpp"; ValueType: string; ValueData: "BarrysEmacsDocumentIII"; Tasks: "option_register_emacs_open_c_many_types"
Root: HKCR; Subkey: ".cxx"; ValueType: string; ValueData: "BarrysEmacsDocumentIII"; Tasks: "option_register_emacs_open_c_many_types"