;Fmod Ex : Jouer un titre musical
EnableExplicit

IncludeFile "fmodex.pbi"

Enumeration
  #Mainform
  #File
  #OpenFile
  #Play
  #Pause
  #Stop
  #Volume
EndEnumeration

Define.l Event, GEvent, TiEvent

Global WindowStyle.i=#PB_Window_SystemMenu|#PB_Window_ScreenCentered

Global fmodsystem.i, Channel.i, Sound.i, Volume.f = 0.5, PauseStatus.b
Global File.s

Procedure Open_MainForm()
  OpenWindow(#Mainform, 0, 0, 300, 100, "Play Mp3", WindowStyle)
  StringGadget(#File, 10, 20, 230, 22, "", #PB_String_ReadOnly)
  ButtonGadget(#OpenFile, 245, 20, 50, 22, "Select")
  TextGadget(#PB_Any, 10, 50, 30, 20, "Vol")
  TrackBarGadget(#Volume, 45, 45, 200, 24, 0, 100)
  SetGadgetState(#Volume, 50)
  
  ButtonGadget(#Play, 55, 70, 60, 22, "Start")
  ButtonGadget(#Pause, 117, 70, 60, 22, "Pause")
  ButtonGadget(#Stop, 183, 70, 60, 22, "Stop")
  
EndProcedure

Open_MainForm()
  
;Déclarer l'objet FMOD System
FMOD_System_Create(@fmodsystem)
  
;Initialiser le system (32 canaux) un seul suffirait pour cet exemple
FMOD_System_Init(fmodsystem, 32, #FMOD_INIT_NORMAL, 0)


Repeat
  Event   = WaitWindowEvent(100)    
  GEvent  = EventGadget()
    
  Select Event
            
    Case #PB_Event_Gadget
      Select GEvent
        Case #OpenFile
          
          ;Décharge le son précédent
          If Sound <> 0
            FMOD_Sound_Release(Sound)
          EndIf
          
          File = OpenFileRequester("Sélectionner un fichier mp3","","Musique|*.mp3;*.wav;*.ogg;*.flac",0)
          If File <> ""
            SetGadgetText(#File, GetFilePart(File))
            FMOD_System_CreateStream(fmodsystem, @File, #FMOD_SOFTWARE, 0, @sound)
          EndIf
          
        Case #Volume
          Volume = GetGadgetState(#Volume)/100
          FMOD_Channel_SetVolume(Channel, Volume)
                  
        Case #Play  
          ;PlaySound va jouer le son sur un des canaux libre
          ;la variable Channel contiendra le handle du canal utilisé par le son.
          FMOD_System_PlaySound(fmodsystem, #FMOD_CHANNEL_FREE, sound, 0, @channel)
          
          ;Et on ajuste le volume (le son est compris entre 0.0 et 1.0)
          FMOD_Channel_SetVolume(Channel, Volume)
          
        Case #Pause
          ;FMOD_Channel_GetPaused permet de savoir si le son sur le canal est en pause ou pas
          FMOD_Channel_GetPaused(Channel, @PauseStatus) 
          
          If PauseStatus = #False
            FMOD_Channel_SetPaused(Channel, #True) ;Pause
            SetGadgetText(#Pause, "Reprendre")
          Else
            FMOD_Channel_SetPaused(Channel, #False) ;Reprise de la lecture
            SetGadgetText(#Pause, "Pause")
          EndIf
          
        Case #Stop
          FMOD_Channel_Stop(Channel)
          
      EndSelect
        
    Case #PB_Event_CloseWindow
      FMOD_Channel_Stop(Channel)
      FMOD_System_Release(fmodsystem)
      End
      
  EndSelect
ForEver
; IDE Options = PureBasic 5.20 LTS (Windows - x86)
; CursorPosition = 101
; FirstLine = 49
; Folding = --
; EnableXP
