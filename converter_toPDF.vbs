Option Explicit
'**********************************************************************************
' ■概要
'   実行ファイルと同じ階層以下の
'   Excel、Word ファイルを PDF に変換して指定したフォルダに出力します。
'
'   ※ Office 2007 以上、プリンタが使用できる環境でのみ動作します。
'**********************************************************************************

'==============================================================
' 変数の宣言、初期化
'==============================================================

'フォルダ操作用
Dim Fso
Dim objApl
Dim objFolder
Dim objFolderTo
Dim objFolderItems
Dim strCurrentPath
Dim obj
Dim crtFolderPath
Dim tmpFilePath

'Excel用
Dim ExcelApp
Dim WordApp
Dim PowerPointApp
Dim Doc
Dim Book
Dim Sheet
Dim Presentations

'コピーするかどうか（0：しない／1：する）
Dim copyFlg
copyFlg = 0

'コピー先
Dim copyTo
copyTo = "C:\work\temp\"

'アクティブシートのみとするかどうかのフラグ（0：オフ／1：オン）
Dim ActiveSheetFlg
ActiveSheetFlg = 1

'ページ指定
'From が 0 であれば指定しない
Dim PageFrom
Dim PageTo
PageFrom = 0
PageTo = 0

'変換元ファイルを削除するかどうか
Dim DeleteFlg
DeleteFlg = 0

'==============================================================
' 処理開始
'==============================================================

'１．ファイルオブジェクトを作成
Set Fso = CreateObject( "Scripting.FileSystemObject" )

'２．実行ファイルが格納されているパスを取得
strCurrentPath = WScript.ScriptFullName
Set obj = Fso.GetFile( strCurrentPath )
Set obj = obj.ParentFolder
strCurrentPath = obj.Path

'３．Excel, Word アプリケーションオブジェクトを作成します。
Set ExcelApp = CreateObject("Excel.Application")
Set WordApp = CreateObject("Word.Application")
Set PowerPointApp = CreateObject("PowerPoint.Application")

'４．シェルアプリケーションオブジェクトを作成します
Set objApl = WScript.CreateObject("Shell.Application")

'５．実行ファイルと同じ階層のフォルダオブジェクトを作成します
Set objFolder = objApl.NameSpace(strCurrentPath)

'６．実行ファイルの親フォルダがコピー先になければ作成する
If copyFlg = 1 Then
	crtFolderPath = copyTo & Fso.GetBaseName(strCurrentPath)
	If Fso.FolderExists(crtFolderPath) = false Then
			Fso.CreateFolder(crtFolderPath)
	End If
End If

'７．フォルダオブジェクトから格納されているファイル、フォルダを取得します。
Set objFolderItems = objFolder.Items()

'８．ファイル、フォルダ単位の処理
Call prcFolder (objFolder)

'９．終了処理
ExcelApp.Quit()
WordApp.Quit()
PowerPointApp.Quit()
Set ExcelApp = Nothing
Set WordApp = Nothing
Set PowerPointApp = Nothing
Set objFolderItems = Nothing
Set objFolder = Nothing
Set objApl = Nothing

If copyFlg = 1 Then
	Wscript.Echo crtFolderPath & " に変換したPDFを出力しました。"
Else
	Wscript.Echo "PDFの変換が完了しました。"
End If

'------------------------------------------------------------------------------------------
' ■サブプログラム
'   フォルダ内に含まれるファイルやフォルダを検索し、
'   Excel、Word ファイルを PDF ファイルに変換する。
'------------------------------------------------------------------------------------------
Sub prcFolder(objFolder)

		Dim tmpFolderPath
		Dim tmpFolderItems
		Dim crtFolderPathB
		Dim objFolderItemsB
		Dim objItem
		Dim i
		Dim flg
		Set tmpFolderItems = objFolder.Items()

		' フォルダ内アイテムの走査
		For i=0 To tmpFolderItems.Count-1

				'ファイルおよびフォルダオブジェクトを取得
				Set objItem = tmpFolderItems.Item(i)
				'Wscript.Echo "パス：" & objItem.Name

				'ファイル、フォルダの判定
				If objItem.IsFolder Then

						'パスを退避
						tmpFolderPath = crtFolderPath

						'処理中のディレクトリをパスに含める
						crtFolderPath = crtFolderPath & "\" & objItem.Name
						' 親ディレクトリがなければ作成
						If Fso.FolderExists(crtFolderPath) = false Then
								Fso.CreateFolder(crtFolderPath)
						End If

						'フォルダであれば再起処理を実施
						Set objFolderItemsB = objItem.GetFolder
						Call prcFolder (objFolderItemsB)

						'パスを戻る
						crtFolderPath = tmpFolderPath

				Else

						flg = 0
						
						' 親ディレクトリがなければ作成
						If copyFlg = 1 Then
							If Fso.FolderExists(crtFolderPath) = false Then
									Fso.CreateFolder(crtFolderPath)
							End If
						End If
						
						Select Case LCase(fso.GetExtensionName(objItem.Name))

							' Excelの場合
							Case "xls", "xlsx"

								' 出力パス
								tmpFilePath = Fso.GetParentFolderName(objItem.Path) & "\" & Fso.GetBaseName(objItem.Name) & ".pdf"

								Set Book = ExcelApp.Workbooks.Open( objItem.Path )
								If Err.Number <> 0 Then
										' 終了( 開放 )
										ExcelApp.Quit()
										Wscript.Echo Err.Description & vbCrLf & strCurrentPath
										' スクリプト終了
										Wscript.Quit()
								End If
								on error goto 0

								if ActiveSheetFlg = 1 Then
									' アクティブシート指定
									Set Sheet = Book.ActiveSheet
									If Err.Number <> 0 Then
											' 終了( 開放 )
											ExcelApp.Quit()
											Wscript.Echo Err.Description & vbCrLf & strCurrentPath
											' スクリプト終了
											Wscript.Quit()
									End If
									on error goto 0
									Call Sheet.ExportAsFixedFormat(0, tmpFilePath)
								Else
									if PageFrom = 0 Then
										' ブック全体
										Call Book.ExportAsFixedFormat(0, tmpFilePath, 0)
									Else
										' ページ指定
										Call Book.ExportAsFixedFormat(0, tmpFilePath, 0, False, False, PageFrom, PageTo, False)
									End if
								End if

								' 終了( 開放 )
								ExcelApp.DisplayAlerts = False
								Book.Close
								ExcelApp.DisplayAlerts = True
								flg = 1

							' Wordの場合
							Case "doc", "docx"

								' 出力パス
								tmpFilePath = Fso.GetParentFolderName(objItem.Path) & "\" & Fso.GetBaseName(objItem.Name) & ".pdf"

								Set Doc = WordApp.Documents.Open( objItem.Path, true)

								If Err.Number <> 0 Then
										' 終了( 開放 )
										WordApp.Quit()
										Wscript.Echo Err.Description & vbCrLf & strCurrentPath
										' スクリプト終了
										Wscript.Quit()
								End If
								on error goto 0

								Call WordApp.ActiveDocument.ExportAsFixedFormat( tmpFilePath,17,False)

								' 終了( 開放 )
								WordApp.DisplayAlerts = False
								Doc.Close
								WordApp.DisplayAlerts = True
								flg = 1


							' PowerPointの場合
							Case "ppt", "pptx"

								' 出力パス
								tmpFilePath = Fso.GetParentFolderName(objItem.Path) & "\" & Fso.GetBaseName(objItem.Name) & ".pdf"

								Set Presentations = PowerPointApp.Presentations.Open( objItem.Path, True, False, False)

								If Err.Number <> 0 Then
										' 終了( 開放 )
										WordApp.Quit()
										Wscript.Echo Err.Description & vbCrLf & strCurrentPath
										' スクリプト終了
										Wscript.Quit()
								End If
								on error goto 0

								Call Presentations.SaveAs( tmpFilePath, 32, False)

								' 終了( 開放 )
								PowerPointApp.DisplayAlerts = False
								Presentations.Close
								PowerPointApp.DisplayAlerts = True
								flg = 1

						End Select
						
						' 変換したファイルを移動
						
						If copyFlg = 1 And flg = 1 Then
							' PDFのみコピー
							Fso.CopyFile tmpFilePath, crtFolderPath & "\", true
							' コピー後に削除
							Fso.DeleteFile tmpFilePath
						End If

				End If

		Next

		' 終了( 開放 )
		Set objItem = Nothing
		Set objFolderItemsB = Nothing

End Sub