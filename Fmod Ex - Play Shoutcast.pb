;Tutorial : Jouer un shoutcast
EnableExplicit

IncludeFile "fmodex.pbi"

Enumeration
  #Mainform
  #Pause
  #Volume
EndEnumeration

Define.l Event, GEvent, TiEvent

Global WindowStyle.i=#PB_Window_SystemMenu|#PB_Window_ScreenCentered

Global fmodsystem.i, Channel.i, Sound.i, Volume.f = 0.5, PauseStatus.b
Global Url.s

Procedure Open_MainForm()
  OpenWindow(#Mainform, 0, 0, 300, 100, "Play Shoutcast", WindowStyle)
  TextGadget(#PB_Any, 10, 50, 30, 20, "Vol")
  TrackBarGadget(#Volume, 45, 45, 200, 24, 0, 10)
  SetGadgetState(#Volume, 5)
  
  ButtonGadget(#Pause, 117, 70, 50, 22, "Pause")
  
EndProcedure

Procedure Start()
  Open_MainForm()
  
  ;Déclarer l'objet FMOD System
  FMOD_System_Create(@fmodsystem)
  
  ;Initialiser le system (32 canaux) un seul suffirait pour cet exemple
  FMOD_System_Init(fmodsystem, 32, #FMOD_INIT_NORMAL, 0)
  
  ;CreateStream permet de commencer la lecture avant le chargement complet de l'url
  Url ="http://server1.chilltrax.com:9000"
  FMOD_System_CreateStream(fmodsystem, @Url, #FMOD_CREATESTREAM, 0, @sound)
  
  ;On joue le son sur le canal 1
  FMOD_System_PlaySound(fmodsystem, 1, sound, 0, @channel)
  
  ;Et on ajuste le volume (le son est compris entre 0.0 et 1.0)
  FMOD_Channel_SetVolume(Channel, 0.5)
  
  
EndProcedure

start()

Repeat
  Event   = WaitWindowEvent(100)    
  GEvent  = EventGadget()
    
  Select Event
            
    Case #PB_Event_Gadget
      Select GEvent
          
        Case #Volume
          Volume = GetGadgetState(#Volume)/10
          FMOD_Channel_SetVolume(Channel, Volume)
          
        Case #Pause
          ;FMOD_Channel_GetPaused permet de savoir si le son sur le canal est en pause ou pas
          FMOD_Channel_GetPaused(Channel, @PauseStatus) 
          
          If PauseStatus = #False
            FMOD_Channel_SetPaused(Channel, #True) ;Pause
          Else
            FMOD_Channel_SetPaused(Channel, #False) ;Reprise de la lecture
          EndIf
                              
      EndSelect
        
    Case #PB_Event_CloseWindow
      FMOD_Channel_Stop(Channel)
      FMOD_System_Release(fmodsystem)
      End
      
  EndSelect
ForEver
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 32
; Folding = -
; EnableXP
; Compiler = PureBasic 5.42 LTS (Windows - x86)