;Fmodex : Jouer un flux internet radio

EnableExplicit

IncludeFile "fmodex.pbi"

Enumeration Font
  #FontGlobal
  #FontAuthor
  #FontTitle
EndEnumeration

Enumeration Window
  #Mainform
EndEnumeration

Enumeration Gadget
  #WebRadio
  #Pause
  #Volume
  
  #Spectrum
  
  #TagICYName
  #TagICYUrl
  #TagAuthor
  #TagTitle
  
EndEnumeration

Define.l Event, GEvent, TiEvent

Global WindowStyle.i=#PB_Window_SystemMenu|#PB_Window_ScreenCentered

Global fmodsystem.i, Channel.i, Sound.i, Volume.f = 0.5, PauseStatus.b, N.i

Structure Radio
  Url.s
  Name.s
EndStructure
Global NewList WebRadio.Radio(), Url.s

Procedure WebRadioLoad()
  Protected Buffer.s, i.i
  
  Restore WebRadio
  For i=1 To 8
    AddElement(WebRadio())
    
    Read.s Buffer     
    WebRadio()\Url = Buffer
    
    Read.s Buffer     
    WebRadio()\Name = Buffer
    
    AddGadgetItem(#WebRadio, -1, WebRadio()\Name)
    SetGadgetItemData(#WebRadio, i-1, i-1)
  Next 
  
  SetGadgetState(#WebRadio, 0)
  
EndProcedure

Procedure ShowSpectrum()
  Protected Dim SpectrumArray.f(128), i.i, j.i, Max, Position.i
  
  ;FMOD_Channel_GetSpectrum(() Récupère le spectre du signal de sortie en cours de lecture.
  ;SpectrumArray est un tableau représente les amplitudes de chaque bande de fréquence.
  ;Le nombre d'amplitudes doit etre une puissance de 2 (Min 64 Max 8192) 
  FMOD_Channel_GetSpectrum(Channel, SpectrumArray(), 64, 0, 0 )
  
  StartDrawing(CanvasOutput(#Spectrum))
  
  ;Clear de l'histogramme
  Box(0, 0, 290, 100, RGB(245, 245, 245)) 
  
  ;Cadre autour de l'histogramme
  DrawingMode(#PB_2DDrawing_Outlined) 
  Box(0, 0, 290, 100, RGB(0, 0, 0)) 
  
  ;Dessin des points
  DrawingMode(#PB_2DDrawing_Default)
  For i=0 To 50
    Max= SpectrumArray(i)*300 
    
    Box(i*6, 100-max, 4, max-2, RGB(0, 191, 255)) 
    Box(i*6, 95-max, 4, 3, RGB(255, 0, 0)) ;Points rouges
  Next 
  
  StopDrawing()
  
EndProcedure


Procedure TagUpdate(Sound)
  Protected TagCount, Tag.FMOD_TAG, i, Title.s, Artist.s, ICYName.s, ICYUrl.s
  
  ;La fonction FMOD_Sound_GetNumTags() récupère le nombre de mots-clés appartenant à un son.
  FMOD_Sound_GetNumTags(Sound, @TagCount, #Null) 
  
  For i=0 To TagCount-1      
    FMOD_Sound_GetTag(Sound, 0, i, @Tag) 
    Select UCase(PeekS(Tag\name))
      Case "ARTIST", "TPE1", "TPE2", "TP1"
        If Artist=""
          Artist = PeekS(Tag\_data, Tag\datalen, #PB_UTF8)
        EndIf
        
      Case "TITLE", "TIT1", "TIT2", "TT2"
        If Title=""
          Title = PeekS(Tag\_data, Tag\datalen, #PB_UTF8)
        EndIf
        
      Case "ICY-NAME"
        ICYName = PeekS(Tag\_data, Tag\datalen, #PB_UTF8)
        
      Case "ICY-URL"
        ICYUrl =   PeekS(Tag\_data, Tag\datalen, #PB_UTF8)
        
    EndSelect
  Next
  
  If Artist <> GetGadgetText(#TagAuthor)
    SetGadgetText(#TagAuthor, Artist)
  EndIf
  
  If Title <> GetGadgetText(#TagTitle)
    SetGadgetText(#TagTitle, Title)
  EndIf
  
  If ICYName <> GetGadgetText(#TagICYName) Or N<>0
    If Len(ICYName) > 47
      N+1
      If N > Len(ICYName)-47
        N = 0
      EndIf
    Else
      N=0
    EndIf
    
    SetGadgetText(#TagICYName, Mid(ICYName, N, 47))
  EndIf
  
  If ICYUrl <> GetGadgetText(#TagICYUrl)
    SetGadgetText(#TagICYUrl, ICYUrl)
  EndIf
  
EndProcedure

Procedure Open_MainForm()    
  LoadFont(#FontGlobal, "Tahoma", 10)
  SetGadgetFont(#PB_Default, FontID(#FontGlobal)) 
  
  LoadFont(#FontAuthor, "Tahoma", 15)
  LoadFont(#FontTitle, "Tahoma", 12)
  
  OpenWindow(#Mainform, 0, 0, 300, 315, "Play Shoutcast", WindowStyle)
  ComboBoxGadget(#WebRadio, 10, 10, 280, 24)
  
  TextGadget(#PB_Any, 5, 45, 30, 20, "Vol")
  TrackBarGadget(#Volume, 45, 45, 251, 24, 0, 100)
  SetGadgetState(#Volume, 50)
  
  ;Auteur & Titre
  TextGadget(#TagAuthor, 5, 72, 290, 22, "?")
  SetGadgetFont(#TagAuthor, FontID(#FontAuthor)) 
  TextGadget(#TagTitle, 5, 95, 290, 22, "?")
  SetGadgetFont(#TagTitle, FontID(#FontTitle))
  
  ;Nom de la radio et site
  TextGadget(#TagICYName, 5, 120, 290, 22, "?")
  TextGadget(#TagICYUrl, 5, 150, 280, 22, "?")
  
  ;Spectrum
  CanvasGadget(#Spectrum, 5, 175, 290, 100)
  ButtonGadget(#Pause, 117, 285, 50, 24, "Pause")
  
  AddWindowTimer(#Mainform, 100, 100)
  AddWindowTimer(#Mainform, 101, 500)
EndProcedure

Procedure Start()
  Open_MainForm()
  WebRadioLoad()
  
  ;Déclarer l'objet FMOD System
  FMOD_System_Create(@fmodsystem)
  
  ;Initialiser le system (32 canaux) 
  ;Un seul canal suffirait pour cet exemple.
  ;Le maximum est de 4093 canaux.
  FMOD_System_Init(fmodsystem, 32, #FMOD_INIT_NORMAL, 0)
  
  ;CreateStream permet de commencer la lecture avant le chargement complet de l'url
  FirstElement(WebRadio())
  Url = WebRadio()\Url
  FMOD_System_CreateStream(fmodsystem, @Url, #FMOD_CREATESTREAM, 0, @sound)
  
  TagUpdate(Sound)
  
  ;On joue le son sur le canal 1 (@Channel contiendra le handle du cannal 1)
  FMOD_System_PlaySound(fmodsystem, 1, sound, 0, @channel)
  
  ;Et on ajuste le volume (le son est compris entre 0.0 et 1.0)
  FMOD_Channel_SetVolume(Channel, 0.5)
  
  ;le son (@Sound) et intimement lié à son canal (@Channel)
  
EndProcedure

start()

Repeat
  Event   = WaitWindowEvent(100)    
  GEvent  = EventGadget()
  TiEvent = EventTimer()
  
  Select Event
      
    Case #PB_Event_Timer
      Select TIEvent
        Case 100
          ShowSpectrum() 
          
        Case 101
          TagUpdate(Sound)
          
      EndSelect
      
    Case #PB_Event_Gadget
      
      Select GEvent
        Case #WebRadio
          SelectElement(Webradio(), GetGadgetState(#WebRadio))
          FMOD_System_CreateStream(fmodsystem, @Webradio()\Url, #FMOD_CREATESTREAM, 0, @sound)
          TagUpdate(Sound)
          FMOD_System_PlaySound(fmodsystem, 1, sound, 0, @channel)
          FMOD_Channel_SetVolume(Channel, GetGadgetState(#Volume)/100)
          
        Case #Volume
          Volume = GetGadgetState(#Volume)/100
          FMOD_Channel_SetVolume(Channel, Volume)
          
        Case #Pause
          ;FMOD_Channel_GetPaused permet de savoir si le son sur le canal est en pause ou pas
          TagUpdate(Sound)
          FMOD_Channel_GetPaused(Channel, @PauseStatus) 
          
          If PauseStatus = #False
            FMOD_Channel_SetPaused(Channel, #True) ;Pause
            SetGadgetText(#Pause, "Play")
          Else
            FMOD_Channel_SetPaused(Channel, #False) ;Reprise de la lecture
            SetGadgetText(#Pause, "Pause")
          EndIf
          
      EndSelect
      
    Case #PB_Event_CloseWindow
      FMOD_Channel_Stop(Channel)
      FMOD_System_Release(fmodsystem)
      End
      
  EndSelect
ForEver

DataSection
  Webradio:
  
  Data.s "http://server1.chilltrax.com:9000", "Chilltrax"
  Data.s "http://broadcast.infomaniak.ch/frequencejazz-high.mp3","Jazz Radio"
  Data.s "http://stream.pulsradio.com:5000", "Pulse Radio"
  Data.s "http://stream1.chantefrance.com/Chante_France", "Chante France"
  Data.s "http://streaming202.radionomy.com:80/70s-80s-90s-riw-vintage-channel","RIWVintage Channel"
  Data.s "http://mfm.ice.infomaniak.ch/mfm-128.mp3", "MFM Radio"
  Data.s "http://broadcast.infomaniak.net/tsfjazz-high.mp3", "TSF Jazz"
  Data.s "http://199.101.51.168:8004", "Blues Connection"
EndDataSection

; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 21
; Folding = -
; EnableXP
; Compiler = PureBasic 5.42 Beta 1 LTS (Windows - x64)
