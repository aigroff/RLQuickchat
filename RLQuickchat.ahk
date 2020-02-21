#NoEnv
#Warn  
SendMode Input  
SetWorkingDir %A_ScriptDir%  
#include xinput.ahk
#Persistent

global messages
global messageParams
global configParams
global chatEnabled 
global inputBuffer 
global inputLock
global noRumble

XInput_Init()
InitGlobals()
ReadChatFile()
SetTimer, InputLoop, 10

HandleInput(keyCode){
    if(!chatEnabled)
        return
	inputBuffer := inputBuffer . keyCode
	if(StrLen(inputBuffer) == 2){
        WriteFromInputCode(inputBuffer)
		inputBuffer := ""
		SetTimer, ClearInput, Off
		return
	} 
	else SetTimer, ClearInput, 500
}

ClearInput:
inputBuffer := ""
SetTimer, ClearInput, Off
return

WriteFromInputCode(inputCode){
    msgArr := messages[inputCode]
    msgParams := messageParams[inputCode]
    if(msgParams[1] == "r"){
        WriteRandom(msgArr, msgParams[2])
    } 
    else if(msgParams[1] == "m"){
        WriteMulti(msgArr, msgParams[2])
    }
    else if(msgParams[1] == "s"){
        WriteSequential(msgArr, msgParams[2],1)
    }
    else {
        WriteSequential(msgArr, msgParams[2])
    }
}

WriteRandom(msgArr, chatKey := "t"){
	Random, randIndex, 1,msgArr.Length()
	WriteMessage(msgArr[randIndex], chatKey)
	return 
}

WriteMulti(msgArr, chatKey := "t"){
    static atIndex := {}
    length := msgArr.MaxIndex()
    sleepTime := 24
    i := atIndex[msgArr]
    while(i <= length){
        i++
        if(ReadCommand(msgArr[i], key, value)){
            switch key{
                case "stop": 
                    atIndex[msgArr] := Mod(i + 1, length)
                    return
                case "multi_sleep": 
                    sleepTime := value
                    continue
            }
        } 
        WriteMessage(msgArr[i], chatKey)
        if(i != length)
            Sleep, sleepTime
        
    }
    atIndex[msgArr] := 0
}

WriteSequential(ByRef msgArr, chatKey := "t", shuffleOn := 0){
    static msgToIndex := {msgArr:1}
    index := msgToIndex[msgArr]
    if(index < 1){
        index := 1
        if(shuffleOn)
            Shuffle(msgArr)
    }
    WriteMessage(msgArr[index], chatKey)    
    msgToIndex[msgArr] := Mod(index + 1, msgArr.MaxIndex()+1)+1
    return
}

WriteMessage(msg, chatKey := "t"){  
    if(ReadCommand(msg, key, value)){
    	switch key {
                case "disable": 
                    inputLock := configParams["disableFor"]
                    DisableChat()
                case "sleep":
                    sleepTime := value
                    Sleep, sleepTime
        }
        return
    } 
    else if(msg !=""){
        Send, %chatKey%
        Sleep, 24
        ;Rocket League can't buffer more than 32 characters into the chat prompt per frame, 
        ;so split the message over frames
        i := 0
        msgLength := StrLen(msg)
        while(i < msgLength){
            subMsg := SubStr(msg,i + 1, 32)
            SendRaw, %subMsg%
            i+=32
            Sleep, 24
        }
        Send,{Enter}
    }
    return
}

ReadCommand(msg, byRef key, byRef value){
    if(SubStr(msg,1,1) == "<" && SubStr(msg, StrLen(msg),1) == ">"){
        command := StrSplit(msg, ":","< >")
        key := command[1]
        StringLower, key, key
        value := command[2]
        return 1
    } 
    return 0
}

Shuffle(byRef msgArr){
    maxIndex := msgArr.MaxIndex() - 1
    while(maxIndex > 1){
        Random, rand, 1, maxIndex
        temp := msgArr[maxIndex + 1]
        msgArr[maxIndex + 1] := msgArr[rand]
        msgArr[rand] := temp
        maxIndex--
    }
}

InputLoop:
InputTick()
return

InputTick(){   
    static activeController := -1
    static lastDPad := 0
    static triggerHoldTickCount := 0
    static dpadHoldTickCount := 0
    static idleAt, activeAt
    static init := 0
    if(init == 0){
        idleAt := configParams["triggerIdle"] * -1
        activeAt := configParams["triggerActive"]
        init = 1
    }

    if(inputLock > 0){
        inputLock--
        return
    }

    if(activeController == -1){
        i = 0
        Loop, 4{
            if(state := XInput_GetState(i)){
                activeController := i
            }
            i++
        }
    }

    if(state := XInput_GetState(activeController)){
        startButton := state.wButtons&16 
        if(startButton)
            DisableChat()

        currentDPad := state.wButtons&15
        if(currentDPad != lastDPad){
            switch currentDPad{
                case 1: HandleInput("u")
                case 2: HandleInput("d")
                case 4: HandleInput("l")
                case 8: HandleInput("r")
            }
            dpadHoldTickCount := 0
        } else {
            if(currentDPad != 0){
                dpadHoldTickCount++
            }
            if(dpadHoldTickCount == 45 && chatEnabled){
                inputBuffer := ""
                switch currentDPad {
                    case 1: HandleInput("hu")
                    case 2: HandleInput("hd")
                    case 4: HandleInput("hl")
                    case 8: HandleInput("hr")
                }
            }
        }
        if(state.bRightTrigger > 180 || state.bLeftTrigger > 180){
            if(triggerHoldTickCount < 0)
                triggerHoldTickCount := 0
            
            triggerHoldTickCount++
        } else{
            if(triggerHoldTickCount > 0)
                triggerHoldTickCount := 0
            else {
                triggerHoldTickCount--
                if(triggerHoldTickCount == idleAt)
                    DisableChat()
            }
        }
        if(triggerHoldTickCount == activeAt){
            EnableChat()
        }

        lastDPad := currentDPad
        return
    }
    return
}

EnableChat(){
    if(!chatEnabled){
        Rumble(3,4)
        chatEnabled := 1
    }
}

DisableChat(){
    if(chatEnabled){
        Rumble(1,2)
        chatEnabled := 0
    }
}

Rumble(count := 2, intensity := 1){
    if(noRumble)
        return
    initialCount := count
        while(count > 0){
            XInput_SetState(0,25600 * intensity,25600 * intensity)
            Sleep 350 / initialCount 
            XInput_SetState(0,0,0)
            Sleep 100 / initialCount
            count--
        }
    return
}

InitGlobals(){
    chatEnabled := 0
    inputBuffer := ""
    noRumble    := 0
    inputLock   := 0
    messages        := []
    messageParams   := []
    configParams     := {triggerIdle:800,triggerActive:30,disableFor:1000}
}

ReadChatFile(){
    if !FileExist("RLChatConfig.txt")
        CreateChatFile()
    
    inputCode:="xx"
    Loop, read, RLChatConfig.txt
    {
        LineNumber := A_Index
        Line := StrSplit(A_LoopReadLine, "//")[1]
        detectParameterLine := InStr(Line, "::")
        if(detectParameterLine != 0 ) {
            pattern := "s" , chatCode := "t"
            Loop, parse, Line, "-", %A_Space%":"
            {
                StringLower, field, A_LoopField
                if(field == "random")
                    pattern := "r"
                else if(field == "multi")
                    pattern := "m"
                else if(field == "shuffle")
                    pattern := "s"   
                else if(field == "team")
                    chatCode := "y"
                else {
                    directions := StrSplit(field, ":", A_Space)
                    inputCode := SubStr(directions[1],1,1) . SubStr(directions[2],1,1)               
                } 
            }
            messageParams[inputCode] := [pattern, chatCode]
            messages[inputCode] := []
        }   
        else if(inputCode=="xx") {
            Loop, parse, Line, "-", %A_Space% 
            {               
                params := StrSplit(A_LoopField, ":", A_Space)
                key := params[1]
                StringLower, key, key
                switch key{
                    case "triggeridle": configParams["triggerIdle"] := params[2]               
                    case "triggeractive": configParams["triggerActive"] := params[2]
                    case "disablefor": configParams["disableFor"] := params[2]
                    case "norumble": noRumble := 1
                    
                }           
            }
        }
        else { 
            Loop, parse, Line, ";",%A_Space% 
            {
                field := A_Loopfield
                if(field != "")
                    messages[inputCode].Push(field)
            }
        }
    }
    return
}

CreateChatFile(){
    text := GetDefaultFileText() 
    FileAppend, %text%, RLChatConfig.txt
    return
}

GetDefaultFileText(){
text = 
(
//////////////////////////////////////////////////
////El Groffo's Rocket League Chat Tool Config////
//////////////////////////////////////////////////
//You can place config variables (not case sensitive) before the start of your chat messages
//A tick is roughly 10ms. 100 ticks is roughly a second... (I did the math)
//triggerIdle: how many ticks while not using a trigger before the chat disables
//triggerActive: how many ticks a trigger must be held to enable chat
//disableFor: After using the <DISABLE> chat command, how many ticks before chat can be enabled again
//norumble: disables rumble when chat is enabled or disabled
-triggerIdle:800 -triggerActive:30 -disableFor:1000 //-norumble


//Information
::up:up:: -team
I got it homie!; I got this one.; Let me get this.; Going for it.; Going for the kill.
::up:right::  -team
Go for it; Take the shot; You can do it
::up:down::
Prophecized?; Foretold;
::up:left:: -random -team
Refuelling; Going for some of that boosty boost; Going to top off my boost; Low on boost, probably need some
Need some of that sweet sweet boost; Running low of fuel; Running low on boost

//Reactions
::right:up::
Shooter McGavin!; What a shot!; Nice shot bruh!; Now that's what I call a nice shot!
::right:right:: -random
Wowzers!; Waawaaweewaa!; Whoa dude!; Wow, wow, woooow; omg wow!; Sweet baby Jezuz!
::right:down::
Close, very close.; Close one.; Supa close.; Damn that was close.; Barely missed.
::right:left::
That was a nice block; Nice block.; Good block.; Nice defense.

//Apologies
::down:up:: -shuffle
Oh jeez!; Gosh dang it; Fudgecicles; Mother Frickin Fracker; Son of a Biscuit Eater; Fudge nuggets!
God bless America!; Banana shenanigans!; Barbara Streisand!; Dagnabbit!; Oh no!; Ay caramba!; By Odin's beard!;
I have failed you Senpai!
::down:right::
Whoopsie daisy.; I made a doopsie.; Whoops, my bad.; Yikes.;
::down:down::
Sorry.
::down:left::
All good homie.; No worries.; It's all good in the hood.; Don't sweat it.

//Compliments
::left:up::
On a scale of one to nice, that was nice!
I haven't seen something that nice in a long time!
Nice one!; Nice one bro!; Nice! nice... very nice.; Supa nice!; That was nice!; Damn, that was nice!
::left:right::
Thanks.
::left:down::
Now that's what I call a save!; Saved by the bell.; Epic save-uuuu!
::left:left::
Sweet pass!; Nice pass!; Great pass; Sweet ass... I mean pass!

//Post Game
::hold:up:: -multi
gg;<DISABLE>
::hold:right:: -multi
gg;<SLEEP:500>; Well played.;<DISABLE>
::hold:down::
<DISABLE>
::hold:left:: -multi
<MULTI_SLEEP:500>;gg;Well played.;That was fun.;<DISABLE> 
)
return text
}