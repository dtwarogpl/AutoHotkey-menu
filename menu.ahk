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
global MODEL_AUTOCOMPLETE_ID := "gpt-3.5-turbo"
MODEL_AUTOCOMPLETE_MAX_TOKENS := 200
MODEL_AUTOCOMPLETE_TEMP := 0.8

http := WinHttpRequest()
API_KEY := OPENAI_API_KEY  

Menu, MyMenu, Add, Fix spelling, FixSpelling
Menu, MyMenu, Add, Translate, Translate

!d::
    MouseGetPos, MouseX, MouseY
    Menu, MyMenu, Show, % MouseX, % MouseY
return

FixSpelling:
   SetSystemCursor()  ; Set the cursor
   GetText(CopiedText, "Cut")
   PromptText := "Please correct the text I'm providing. Your job is to identify and amend any typos, misspellings, missing words, etc., regardless of the language it's in. It's important that the language of the original text be maintained in the corrected version. You're allowed to change the word order where necessary for coherence, but remember to keep the original intent of the text intact. The output should be just the corrected text, with no additional comments or markings. \r\n ###Text to correct: \r\n "
   CombinedText := PromptText . CopiedText
   url := MODEL_ENDPOINT
   body := {}
   body.model := MODEL_AUTOCOMPLETE_ID 
   body.messages := [{"role": "user", "content": CombinedText}] 
   body.max_tokens := MODEL_AUTOCOMPLETE_MAX_TOKENS
   body.temperature := MODEL_AUTOCOMPLETE_TEMP + 0 
   headers := {"Content-Type": "application/json", "Authorization": "Bearer " . API_KEY}
   response := http.POST(url, JSON.Dump(body), headers, {Object:true, Encoding:"UTF-8"})
   obj := JSON.Load(response.Text)
   PutText(obj.choices[1].message.content, "Cut")  
   TrayTip
   RestoreCursors() ; Restore the cursor
return

Translate:
   SetSystemCursor()  ; Set the cursor
   GetText(CopiedText, "Cut")
   PromptText := "Please translate this text to Polish Or English (you shoud decide the direction by reckognizing the source text). You're allowed to change the word order where necessary for coherence, but remember to keep the original intent of the text intact. The output should be just the corrected text, with no additional comments or markings. \r\n ###Text to translate: \r\n "
   CombinedText := PromptText . CopiedText
   url := MODEL_ENDPOINT
   body := {}
   body.model := MODEL_AUTOCOMPLETE_ID 
   body.messages := [{"role": "user", "content": CombinedText}] 
   body.max_tokens := MODEL_AUTOCOMPLETE_MAX_TOKENS
   body.temperature := MODEL_AUTOCOMPLETE_TEMP + 0 
   headers := {"Content-Type": "application/json", "Authorization": "Bearer " . API_KEY}
   response := http.POST(url, JSON.Dump(body), headers, {Object:true, Encoding:"UTF-8"})
   obj := JSON.Load(response.Text)
   PutText(obj.choices[1].message.content, "Cut")  
   TrayTip
   RestoreCursors() ; Restore the cursor
return

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
