# RLQuickchat
An ahk script for creating custom quick chat messages in Rocket League. Only for Xinput controllers at the moment.

The first time you run the script, a config file will be generated that you can modify to create custom chat messages.





## CONFIG HEADER


Some variables can be specified on the header of this file to customize. They are listed below.
* **-triggerIdle:*ticks***

How many ticks while not using a trigger before the chat disables
* **-triggerActive:*ticks***

How many ticks a trigger must be held to enable chat
* **-disableFor:*ticks***

After using the <DISABLE> chat command, how many ticks before chat can be enabled again
* **-norumble**
  
Disables rumble when chat is enabled or disabled





## QUICK CHAT INPUT GROUPS

Quick Chat messages are seperated into groups by their input combinations. The following syntax is used:

*::DIRECTION:DIRECTION::*

For example, 
`::up:left::`

In addition, a hold command is also used to signify holding a direction.
For example, 
`::hold:down::`

Each chat input group can have variables attached to them that change how they behave. They are listed here:

* **-team**
Messages in this group will be sent using team chat (y), otherwise they are sent to general chat (t)

* **-random**
Messages will be selected randomly each time the command is issued from the controller

* **-shuffle**
Messages will be shuffled once upon starting the script and the issued in that order

* **-multi**
Multiple messagess will be issued sequentially. They can be broken up with <STOP> commands

* *`-random`, `-shuffle` and `-multi` cannot be combined, only one of these can be active at one time


Messages can then be populated on new lines after the input group line. These can be seperated by semi-colons or new lines.
For example,
```
This is a message; This is another message
This is yet another message
```




In addition, commands can be used to tell the script to behave a certain way. Angle brackets are used to distiguish them from regular messages.

`<DISABLE>`

disables the chat. It cannot be re-enabled for a period of time specified by `-disableFor`.  

`<SLEEP:time_in_milliseconds>` 

When using multi mode chat, this tells the chat to wait before continuing to the next message  

`<MULTI_SLEEP:time_in_milliseconds> `

When using the multi mode chat, this tells the chat how long to wait after all subsequent messages. Resets after a `<STOP>`.

`<STOP> `

When using the multi mode chat, this tells the script to stop sending new messages. When the command is issued again, it will continue from the message after this command.

