; Change system cursor 
SetSystemCursor()
{
   Cursor = %A_ScriptDir%\GPT3-AHK.ani
   CursorHandle := DllCall( "LoadCursorFromFile", Str,Cursor )

   Cursors = 32512,32513,32514,32515,32516,32640,32641,32642,32643,32644,32645,32646,32648,32649,32650,32651
   Loop, Parse, Cursors, `,
   {
      DllCall( "SetSystemCursor", Uint,CursorHandle, Int,A_Loopfield )
   }
}

RestoreCursors() 
{
   DllCall( "SystemParametersInfo", UInt, 0x57, UInt,0, UInt,0, UInt,0 )
}

IfNotExist, settings.ini     
{
   InputBox, OPENAI_API_KEY, Please insert your OpenAI API key, Open AI API key, , 270, 145
   IniWrite, %OPENAI_API_KEY%, settings.ini, OpenAI, API_KEY
} 
else
{
   IniRead, OPENAI_API_KEY, settings.ini, OpenAI, API_KEY  
}
global API_KEY := OPENAI_API_KEY

SetTitleMatchMode, 2     

#persistent
#SingleInstance  

global MODEL_ENDPOINT := "https://api.openai.com/v1/chat/completions"
global n8n_Endpoint := "https://api.twarog.eu/webhook/3d20e321-771b-4d7b-9fd3-861a86700380"
global DefaultHeaders := {"Content-Type": "application/json"}
global MODEL_AUTOCOMPLETE_ID := "gpt-4o"
MODEL_AUTOCOMPLETE_MAX_TOKENS := 800
MODEL_AUTOCOMPLETE_TEMP := 0.8

http := WinHttpRequest()
API_KEY := OPENAI_API_KEY  

Menu, MyMenu, Add, Fix spelling, FixSpelling
Menu, MyMenu, Add, Translate, Translate
Menu, MyMenu, Add, GenerateCode, GenerateCode
Menu, MyMenu, Add, To_Snake_Case, To_Snake_Case
Menu, MyMenu, Add, To_Unit_Test_Name, To_Unit_Test_Name
Menu, MyMenu, Add, Add_emoji, Add_emoji

!d::
    MouseGetPos, MouseX, MouseY
    Menu, MyMenu, Show, % MouseX, % MouseY
return

FixSpelling:
   SetSystemCursor()  ; Set the cursor
   GetText(CopiedText, "Cut")

bodyJson := "{"
    . """type"": ""fix_spelling"","
    . """content"": """ . StrReplace(StrReplace(StrReplace(CopiedText, """", "\"""), "`r`n", "\n"), "`n", "\n") . """"
    . "}"

response := http.POST(n8n_Endpoint, bodyJson, DefaultHeaders, {Object:true, Encoding:"UTF-8"})
PutText(response.Text, "Cut")
   TrayTip
   RestoreCursors() ; Restore the cursor
return

Translate:
   SetSystemCursor()  ; Set the cursor
   GetText(CopiedText, "Cut")

bodyJson := "{"
    . """type"": ""translate"","
    . """content"": """ . StrReplace(StrReplace(StrReplace(CopiedText, """", "\"""), "`r`n", "\n"), "`n", "\n") . """"
    . "}"

response := http.POST(n8n_Endpoint, bodyJson, DefaultHeaders, {Object:true, Encoding:"UTF-8"})
PutText(response.Text, "Cut")
   TrayTip
   RestoreCursors() ; Restore the cursor
return

GenerateCode:
    SetSystemCursor()  ; Set the cursor
   GetText(CopiedText, "Cut")

bodyJson := "{"
    . """type"": ""ask_gpt"","
    . """content"": """ . StrReplace(StrReplace(StrReplace(CopiedText, """", "\"""), "`r`n", "\n"), "`n", "\n") . """"
    . "}"

response := http.POST(n8n_Endpoint, bodyJson, DefaultHeaders, {Object:true, Encoding:"UTF-8"})
PutText(response.Text, "Cut")
   TrayTip
   RestoreCursors() ; Restore the cursor
return

To_Snake_Case:
   SetSystemCursor()  ; Set the cursor
   GetText(CopiedText, "Cut")
   PromptText := "Please fotmat the text im providing to be a Snake_Case. Keep the original intent of the text intact, with no additional comments or markings. \r\n ###Text to correct: \r\n "
   CombinedText := PromptText . CopiedText
   url := MODEL_ENDPOINT
   bodyJson := "{"
    . """model"": """ . MODEL_AUTOCOMPLETE_ID . """"
    . ", ""messages"": [{""role"": ""user"", ""content"": """ . StrReplace(StrReplace(StrReplace(CombinedText, """", "\"""), "`r`n", "\n"), "`n", "\n") . """}]"
    . ", ""max_tokens"": " . MODEL_AUTOCOMPLETE_MAX_TOKENS
    . ", ""temperature"": " . MODEL_AUTOCOMPLETE_TEMP
    . "}"

   headers := {"Content-Type": "application/json", "Authorization": "Bearer " . API_KEY}
   response := http.POST(url, bodyJson, headers, {Object:true, Encoding:"UTF-8"})
   obj :=json_toobj( response.Text)
   PutText(obj.choices[1].message.content, "Cut")  
   TrayTip
   RestoreCursors() ; Restore the cursor
return

To_Unit_Test_Name:
   SetSystemCursor()  ; Set the cursor
   GetText(CopiedText, "Cut")
   PromptText := "Convert the following text into a properly formatted C# unit test name. The format should be: Feature_UnderTest_Condition_ExpectedOutcome. \r\n Example: Input: 'All prices endpoints called with regular product by customer with club discount' \r\n Output: AllPricesEndpoints_Called_With_Regular_Product_By_CustomerWithClubDiscount_ReturnsLoyaltyDiscountedProduct ###Use the same format for the following text: \r\n "
   CombinedText := PromptText . CopiedText
   url := MODEL_ENDPOINT
   bodyJson := "{"
    . """model"": """ . MODEL_AUTOCOMPLETE_ID . """"
    . ", ""messages"": [{""role"": ""user"", ""content"": """ . StrReplace(StrReplace(StrReplace(CombinedText, """", "\"""), "`r`n", "\n"), "`n", "\n") . """}]"
    . ", ""max_tokens"": " . MODEL_AUTOCOMPLETE_MAX_TOKENS
    . ", ""temperature"": " . MODEL_AUTOCOMPLETE_TEMP
    . "}"

   headers := {"Content-Type": "application/json", "Authorization": "Bearer " . API_KEY}
   response := http.POST(url, bodyJson, headers, {Object:true, Encoding:"UTF-8"})
   obj :=json_toobj( response.Text)
   PutText(obj.choices[1].message.content, "Cut")  
   TrayTip
   RestoreCursors() ; Restore the cursor
return

Add_emoji:
   SetSystemCursor()  ; Set the cursor
   GetText(CopiedText, "Cut")
   PromptText := "Your only task is to write exact same text starting with related emoji. \r\n ###Example: \r\n Turn lights on \r\n\💡 Turn lights on\r\n\r\n\r\n"
   CombinedText := PromptText . CopiedText
   url := MODEL_ENDPOINT
   bodyJson := "{"
    . """model"": """ . MODEL_AUTOCOMPLETE_ID . """"
    . ", ""messages"": [{""role"": ""user"", ""content"": """ . StrReplace(StrReplace(StrReplace(CombinedText, """", "\"""), "`r`n", "\n"), "`n", "\n") . """}]"
    . ", ""max_tokens"": " . MODEL_AUTOCOMPLETE_MAX_TOKENS
    . ", ""temperature"": " . MODEL_AUTOCOMPLETE_TEMP
    . "}"

   headers := {"Content-Type": "application/json", "Authorization": "Bearer " . API_KEY}
   response := http.POST(url, bodyJson, headers, {Object:true, Encoding:"UTF-8"})
   obj :=json_toobj( response.Text)
   PutText(obj.choices[1].message.content, "Cut")  
   TrayTip
   RestoreCursors() ; Restore the cursor
return

PerformAction(actionType) {
    SetSystemCursor()  ; Set the cursor
    GetText(CopiedText, "Cut")
    
    bodyJson := "{"
        . """type"": """ . actionType . ""","
        . """content"": """ . StrReplace(StrReplace(StrReplace(CopiedText, """", "\"""), "`r`n", "\n"), "`n", "\n") . """"
        . "}"
    
    response := http.POST(n8n_Endpoint, bodyJson, DefaultHeaders, {Object: true, Encoding: "UTF-8"})
    PutText(response.Text, "Cut")
    TrayTip
    RestoreCursors()  ; Restore the cursor
    return response.Text
}

GetText(ByRef MyText = "", Option = "Copy")
{
   SavedClip := ClipboardAll
   Clipboard =
   if (Option == "Copy")
   {
      Send ^c
   }
   else if (Option == "Cut")
   {
      Send ^x
   }
   ClipWait 0.5
   if ERRORLEVEL
   {
      Clipboard := SavedClip
      MyText =
      return
   }
   MyText := Clipboard
   Clipboard := SavedClip
   return MyText
}

PutText(MyText, Option = "")
{
   SavedClip := ClipboardAll 
   Clipboard = 
   Sleep 20
   Clipboard := MyText
   if (Option == "AddSpace")
   {
      Send {Right}
      Send {Space}
   }
   Send ^v
   Sleep 100
   Clipboard := SavedClip
   return
}


json_toobj( str ) {

	quot := """" ; firmcoded specifically for readability. Hardcode for (minor) performance gain
	ws := "`t`n`r " Chr(160) ; whitespace plus NBSP. This gets trimmed from the markup
	obj := {} ; dummy object
	objs := [] ; stack
	keys := [] ; stack
	isarrays := [] ; stack
	literals := [] ; queue
	y := nest := 0

; First pass swaps out literal strings so we can parse the markup easily
	StringGetPos, z, str, %quot% ; initial seek
	while !ErrorLevel
	{
		; Look for the non-literal quote that ends this string. Encode literal backslashes as '\u005C' because the
		; '\u..' entities are decoded last and that prevents literal backslashes from borking normal characters
		StringGetPos, x, str, %quot%,, % z + 1
		while !ErrorLevel
		{
			StringMid, key, str, z + 2, x - z - 1
			StringReplace, key, key, \\, \u005C, A
			If SubStr( key, 0 ) != "\"
				Break
			StringGetPos, x, str, %quot%,, % x + 1
		}
	;	StringReplace, str, str, %quot%%t%%quot%, %quot% ; this might corrupt the string
		str := ( z ? SubStr( str, 1, z ) : "" ) quot SubStr( str, x + 2 ) ; this won't

	; Decode entities
		StringReplace, key, key, \%quot%, %quot%, A
		StringReplace, key, key, \b, % Chr(08), A
		StringReplace, key, key, \t, % A_Tab, A
		StringReplace, key, key, \n, `n, A
		StringReplace, key, key, \f, % Chr(12), A
		StringReplace, key, key, \r, `r, A
		StringReplace, key, key, \/, /, A
		while y := InStr( key, "\u", 0, y + 1 )
			if ( A_IsUnicode || Abs( "0x" SubStr( key, y + 2, 4 ) ) < 0x100 )
				key := ( y = 1 ? "" : SubStr( key, 1, y - 1 ) ) Chr( "0x" SubStr( key, y + 2, 4 ) ) SubStr( key, y + 6 )

		literals.insert(key)

		StringGetPos, z, str, %quot%,, % z + 1 ; seek
	}

; Second pass parses the markup and builds the object iteratively, swapping placeholders as they are encountered
	key := isarray := 1

	; The outer loop splits the blob into paths at markers where nest level decreases
	Loop Parse, str, % "]}"
	{
		StringReplace, str, A_LoopField, [, [], A ; mark any array open-brackets

		; This inner loop splits the path into segments at markers that signal nest level increases
		Loop Parse, str, % "[{"
		{
			; The first segment might contain members that belong to the previous object
			; Otherwise, push the previous object and key to their stacks and start a new object
			if ( A_Index != 1 )
			{
				objs.insert( obj )
				isarrays.insert( isarray )
				keys.insert( key )
				obj := {}
				isarray := key := Asc( A_LoopField ) = 93
			}

			; arrrrays are made by pirates and they have index keys
			if ( isarray )
			{
				Loop Parse, A_LoopField, `,, % ws "]"
					if ( A_LoopField != "" )
						obj[key++] := A_LoopField = quot ? literals.remove(1) : A_LoopField
			}
			; otherwise, parse the segment as key/value pairs
			else
			{
				Loop Parse, A_LoopField, `,
					Loop Parse, A_LoopField, :, % ws
						if ( A_Index = 1 )
							key := A_LoopField = quot ? literals.remove(1) : A_LoopField
						else if ( A_Index = 2 && A_LoopField != "" )
							obj[key] := A_LoopField = quot ? literals.remove(1) : A_LoopField
			}
			nest += A_Index > 1
		} ; Loop Parse, str, % "[{"

		If !--nest
			Break

		; Insert the newly closed object into the one on top of the stack, then pop the stack
		pbj := obj
		obj := objs.remove()
		obj[key := keys.remove()] := pbj
		If ( isarray := isarrays.remove() )
			key++

	} ; Loop Parse, str, % "]}"

	Return obj
}

