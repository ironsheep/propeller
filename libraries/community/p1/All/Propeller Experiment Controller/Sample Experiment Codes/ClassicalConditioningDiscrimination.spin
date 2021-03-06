{{

┌────────────────────────────────────────────┐
│ Classical Conditioning Discrimination      │
│ Author: Christopher A Varnon               │
│ Created: 12-20-2012                        │
│ See end of file for terms of use.          │
└────────────────────────────────────────────┘

  The program will present an unconditioned stimulus and a conditioned stimulus for a specified number of trials.
  Two trial types may be used. In CS+ trials, a CS is presented with a US.
  In CS- trials, a different CS is presented, and the US is not presented.
  The program randomly determines the order of the trial types.
  The program can also ensure that only a user-specified number of trials of the same type can occur consecutively.
  For example, if 5 trials of each type are to be used, and a maximum of 3 consecutive trials of the same type are allowed, the order will initially be randomly determined.
  Then, if the first four trials are: Trial 1. CS+, Trial 2. CS-, Trial 3. CS-, Trial 4, CS-; then the next trial will always be a CS+ so that 4 consecutive CS- trials do not occur.
  Trial 6 would then be randomly selected as normal.

  A wide variety of CS/US conditioning procedures can be created by changing the start and stop times of each stimulus within a trial.
  For example, if the US starts at 2 seconds into a trial and stops at 3 seconds into the trial, The CS can come before or after the US.
  To make the CS come before the US, set it to start 0 seconds into the trial (immediately) and stop 2 seconds into the trial.
  To make the CS come after the US, set it to start 3 seconds into the trial and stop 4 seconds into the trial.

  The user will need to specify the pins used for the CS+, the CS-, the US, the response device, the house lights, and the SD card.
  The user will also need to specify the start and stop times of each stimulus, the trial length, and the number of trials of each type.

  Comments and descriptions of the code are provided within brackets and following quotation marks.

}}

CON
  '' This block of code is called the CONSTANT block. Here constants are defined that will never change during the program.
  '' The constant block is useful for defining constants that will be used often in the program. It can make the program much more readable.

  '' The following two lines set the clock mode.
  '' This enables the propeller to run quickly and accurately.
  '' Every experiment program will need to set the clock mode like this.
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  '' The following four constants are the SD card pins.
  '' Replace these values with the appropriate pin numbers for your device.
  DO  = 0
  CLK = 1
  DI  = 2
  CLS = 3                                                                       ' Note this pin is called CLS instead of CS so that CS can be used to refer to conditioned stimulus.

  '' Replace the following values with whatever is desired for your experiment.
  '' By adjusting the start and stop times of the CS and US, a wide variety of procedures can be created.
  '' Note that underscores are used in place of commas.
  '' The underscores are unnecessary and do not change the program, they only make the numbers easier to read.
  TrialLength        = 10_000                                                   ' The duration of the trial. Should be long enough to accommodate both stimulus presentations and an inter-trial interval.
  CS_Start           = 1_000                                                    ' The time during a trial the CS+ or CS- starts.
  CS_Stop            = 3_000                                                    ' The time during a trial the CS+ or CS- ends.
  US_Start           = 2_000                                                    ' The time during a trial the US starts.
  US_Stop            = 3_000                                                    ' The time during a trial the US ends.

  Trials             = 10                                                       ' The number of CS+ and CS- trials. The total number of trials will be double this number.
  ConsecutiveLimit   = 5                                                        ' The maximum number of trials of one type that can occur in a row.
                                                                                ' Until this number is reached, trial types will be determined randomly.
                                                                                ' After this number is reached, the next trial type will be intentionally selected to break the chain of single trial types.
                                                                                ' Increase ConsecutiveLimit so that it exceeds Trials for a completely random selection of trial type.

  '' Replace the following values with the pins connected to the devices.
  ResponsePin        = 6
  USPin              = 23
  CSPlusPin          = 22
  CSMinusPin         = 21
  HouseLightPin      = 16                                                       ' The house lights will activate only while the experiment is running. Leave the pin disconnected if house lights control is not needed.
  DiagnosticLEDPin   = 17                                                       ' The LED will turn on after the experiment is complete and it is safe to remove the SD card. Leave the pin disconnected if a diagnostic LED is not needed.

  '' Input Event States
  '' These states are named in the constant block to make the program more readable.
  Off     = 0                                                                   ' Off means that nothing is detected on an input.    Example: The rat is not pressing the lever.
  Onset   = 1                                                                   ' Onset means that the input was just activated.     Example: The rat just pressed the lever.
  On      = 2                                                                   ' On means that the input has been active a while.   Example: The rat pressed the lever recently and is still pressing it.
  Offset  = 3                                                                   ' Offset means that the input was just deactivated.  Example: The rat was pressing the lever, but it just stopped.

  '' Output Event States
  OutOn   = 1                                                                   ' The output is on.
  OutOff  = 3                                                                   ' The output is off.

VAR
  '' The VAR or Variable block is used to define variables that will change during the program.
  '' Variables are different from constants because variables can change, while constants cannot.
  '' The variables only be named in the variable space. They will be assigned values later.
  '' The size of a variable is also assigned in the VAR block.
  '' Byte variables can range from 0-255 and are best for values you know will be very small.
  '' Word variables are larger. They range from 0-65,535. Word variables can also be used to save the location of string (text) values in memory.
  '' Long variables are the largest and range from -2,147,483,648 to +2,147,483,647. Most variables experiments use will be longs.
  '' As there is limited space on the propeller chip, it is beneficial to use smaller sized variables when possible.
  '' It is unlikely that most experiments will use the entire memory of the propeller chip.

  word ResponseName                                                             ' This variable will refer to the text description of the response event that will be saved to the data file.
  word CSPlusName                                                               ' This variable will refer to the text description of the CS event that will be saved to the data file.
  word CSMinusName                                                              ' This variable will refer to the text description of the CS event that will be saved to the data file.
  word USName                                                                   ' This variable will refer to the text description of the US event that will be saved to the data file.

  long Start                                                                    ' This variable will contain the starting time of the experiment. All other times will be compared to this time.

  word Trial                                                                    ' This variable will be used note the current trial.
  byte TrialType                                                                ' This variable will refer to the type of trial; 1 for CS+ trials, 0 for CS- trials.
  word CSPlusTrials                                                             ' Notes how many CS+ trials have occurred.
  word CSMinusTrials                                                            ' Notes how many CS- trials have occurred.

OBJ
  '' The OBJ or Object block is used to declare objects that will be used by the program.
  '' These objects allow the current program to use code from other files.
  '' This keeps programs organized and makes it easier to share common code between multiple programs.
  '' Additionally, using objects written by others saves time and allows access to complicated functions that may be difficult to create.
  '' The objects are given short reference names. These abbreviations will be used to refer to code in the objects.

  '' The Experimental Functions object is the master object for experiments. It is responsible for keeping precise time, as well as saving data.
  exp : "Experimental_Functions"                                                ' Loads experimental functions.

  '' The Experimental Event object works in tandem with Experimental Functions.
  '' Each Experimental Event object is dedicated to keeping track of a specific event, and passing this information along to Experimental Functions.
  '' Each event in an experiment such as key pecks, stimulus lights, tones, and reinforcement uses its own experimental event object.
  Response      : "Experimental_Event"                                          ' Loads response as an experimental event.
  CSPlus        : "Experimental_Event"                                          ' Loads the CS+ as an experimental event.
  CSMinus       : "Experimental_Event"                                          ' Loads the CS- as an experimental event.
  US            : "Experimental_Event"                                          ' Loads the US as an experimental event.
  HouseLight    : "Experimental_Event"                                          ' Loads houselight as an experimental event.

PUB Main
  '' The PUB or Public block is used to define code that can be used in a program or by other programs.
  '' The name listed after PUB is the name of the method.
  '' The program always starts with the first public method. Commonly this method is named "Main."
  '' The program will only run code in the first method unless it is explicitly told to go to another method.

  '' The statement "SetVariables" sets all the variables using a separate method. Scroll down to the SetVariables method to read the code.
  '' A separate method is not needed to set the variables, it can be done in the main method.
  '' However, dividing a program into sections can make it much easier to read.
  exp.startexperiment(DO,CLK,DI,CLS)                                            ' Launches all the code in experimental functions related to timing and saving data. Also provides the SD card pins for saving data.
  SetVariables                                                                  ' Implements the setvariables method. Scroll down to read the code.
  houselight.turnon                                                             ' Turns on the house lights.
  start:=exp.time(0)                                                            ' Sets the variable 'start' to time(0) or the time since 0 - the present.
                                                                                ' In other words, the experiment started now.

  repeat until exp.time(start)>(trials*2)*(triallength)                         ' Repeats the indented code until time(start), or time since the experiment started, is greater than the total duration of all trials.
                                                                                ' In other words, repeat until the all trials are complete.

    '' The next line of code is the basis for conducting experiments using experimental functions.
    '' When in a repeat loop, this code constantly checks the state of an input device.
    '' If anything has changed since the last time it checked, data is automatically recorded.
    '' In this way, the time of the onset and of the offset of every event can be recorded easily.
    exp.record(response.detect, response.ID, exp.time(start))                   ' Detect the state of the response device and record the state if it has changed.

    Contingencies                                                               ' Implements the contingencies method. Scroll down to read the code.

    '' This ends the main program loop. The loop will repeat until the session length is over, then drop down to the next line of code.

  '' The session has ended.
  if CSPlus.state==OutOn                                                        ' If the CS+ is still occurring after the session ended.
    StopCSPlus                                                                  ' Stop the CS+.
  if CSMinus.state==OutOn                                                       ' If the CS- is still occurring after the session ended.
    StopCSMinus                                                                 ' Stop the CS-.
  if US.state==OutOn                                                            ' If the US is still occurring after the session ended.
    StopUS                                                                      ' Stop the US.
  houselight.turnoff                                                            ' Turns off the house lights.
  exp.stopexperiment                                                            ' Stop the experiment. This line is needed before saving data.

  exp.preparedataoutput                                                         ' Prepares a data.cvs file.
  exp.savedata(response.ID,responsename)                                        ' Sorts through memory for all occurrences of the response event and saves them to the data file.
  exp.savedata(CSPlus.ID,CSPlusname)                                            ' Sorts through memory for all occurrences of the CS+ event and saves them to the data file.
  exp.savedata(CSMinus.ID,CSMinusname)                                          ' Sorts through memory for all occurrences of the CS- event and saves them to the data file.
  exp.savedata(US.ID,USname)                                                    ' Sorts through memory for all occurrences of the US event and saves them to the data file.

  exp.shutdown                                                                  ' Closes all the experiment code.

  dira[DiagnosticLEDPin]:=1                                                     ' Makes the diagnostic LED an output.
  repeat                                                                        ' The program enters an infinite repeat loop to flash the LED.
    !outa[DiagnosticLEDPin]                                                     ' Changes the state of the LED.
    waitcnt(clkfreq/10*5+cnt)                                                   ' Waits .5 seconds.
  ' When the LED starts flashing, it is safe to remove the SD card.

PUB SetVariables
  '' Sets up the experiment variables and events.

  responsename:=string("Response")                                              ' This sets the variable responsename to a string. Think of string as a "string of letters."
  CSPlusname:=string("CS+")                                                     ' The name of the CS+.
  CSMinusname:=string("CS-")                                                    ' The name of the CS-.
  USname:=string("US")                                                          ' The name of the US.
  trial:=1                                                                      ' Note that the experiment starts with trial 1.
  exp.startrealrandom                                                           ' Activates the realrandom number generator to generate better random numbers.
  trialtype:=exp.pseudorandom(ConsecutiveLimit)                                 ' Randomly determines the first trial type.

  '' The next lines use experimental event code to prepare the events.
  Response.declareinput(responsepin,exp.clockID)                                ' This declares that the experimental event 'response' described in the OBJ section is an input on the response pin.
  CSplus.declareoutput(CSpluspin,exp.clockID)                                   ' This declares that the experimental event 'CSPlus' described in the OBJ section is an output on the CS pin.
  CSminus.declareoutput(CSminuspin,exp.clockID)                                 ' This declares that the experimental event 'CSMinus' described in the OBJ section is an output on the CS pin.
  US.declareoutput(USpin,exp.clockID)                                           ' This declares that the experimental event 'US' described in the OBJ section is an output on the US pin.
  HouseLight.declareoutput(houselightpin,exp.clockID)                           ' This declares that the experimental event 'houselight' described in the OBJ section is an output on the light pin.

PUB Contingencies
  '' The contingencies are implemented in a separate method to increase readability.
  '' Note that the contingencies method is run every program cycle, immediately after the response device is checked.

  if trialtype==1                                                               ' If it is a CS+ trial.
    CSPlusPresentation                                                          ' Present the CS+.
    USPresentation                                                              ' Present the US.

  else                                                                          ' If it is not a CS+ trial.
    CSMinusPresentation                                                         ' Present the CS-.

  if exp.time(start)=>triallength*trial                                         ' If the current time is greater than the trial length times the current number of trials.
    trial:=trial+1                                                              ' Then it must be a new trial. Increment trial.
    if trialtype==1                                                             ' If last the trial was a CS+ trial.
      CSPlusTrials+=1                                                           ' Increment plustrials.
    else                                                                        ' If last the trial was a CS- trial.
      CSMinusTrials+=1                                                          ' Increment minustrials.
    if CSPlusTrials==Trials                                                     ' If all the CS+ trials occurred.
      trialtype:=0                                                              ' The next trial must be a CS- trial.
    elseif CSMinusTrials==Trials                                                ' If all the CS- trials occurred.
      trialtype:=1                                                              ' The next trial must be a CS+ trial.
    else                                                                        ' If there are more trials of each type.
      SelectTrialType                                                           ' Selects the trial type. Scroll down to read the method.

PUB SelectTrialType
  '' This method randomly selects a new trial type.
  '' If one trial type has already reached the maximum number of presentations, the opposite type will be selected.

  if CSPlus.count==Trials                                                       ' If the CS+ has already been selected the maximum amount of times.
    trialtype:=0                                                                ' The next stimulus presentation is a CS-.
  elseif CSMinus.count==Trials                                                  ' If the CS- has already been selected the maximum amount of times.
    trialtype:=1                                                                ' The next stimulus presentation is a CS+.
  else                                                                          ' In any other case.
    trialtype:=exp.pseudorandom(ConsecutiveLimit)                               ' Randomly determine the next stimulus presentation.

PUB CSPlusPresentation
  '' Presents and removes the CS+.

  if CSplus.state==OutOff and exp.time(start)=>CS_start+(triallength*(trial-1)) and exp.time(start)=<CS_stop+(triallength*(trial-1))    ' If the CS+ is off and the time is between the start and stop time.
    StartCSPlus
  if CSplus.state==OutOn and exp.time(start)=>CS_stop+(triallength*(trial-1))                                                           ' If the CS+ is off and the time is between the start and stop time.
    StopCSPlus

PUB CSMinusPresentation
  '' Presents and removes the CS-.

  if CSminus.state==OutOff and exp.time(start)=>CS_start+(triallength*(trial-1)) and exp.time(start)=<CS_stop+(triallength*(trial-1))   ' If the CS+ is off and the time is between the start and stop time.
    StartCSMinus
  if CSminus.state==OutOn and exp.time(start)=>CS_stop+(triallength*(trial-1))                                                          ' If the CS+ is off and the time is between the start and stop time.
    StopCSMinus

PUB USPresentation
  '' Presents and removes the US.

  if US.state==OutOff and exp.time(start)=>US_start+(triallength*(trial-1)) and exp.time(start)=<US_stop+(triallength*(trial-1))       ' If the US is off and the time is between the start and stop time.
    StartUS
  if US.state==OutOn and exp.time(start)=>US_stop+(triallength*(trial-1))                                                              ' If the US is off and the time is between the start and stop time.
    StopUS

PUB StartCSPlus
  '' Turns on the CS+, and records that the CS+ started.
  exp.record(CSPlus.turnon, CSplus.ID, exp.time(start))

PUB StopCSPlus
  '' Turns off the CS+, and records that the CS+ stopped.
  exp.record(CSPlus.turnoff, CSplus.ID, exp.time(start))

PUB StartCSMinus
  '' Turns on the CS-, and records that the CS- started.
  exp.record(CSMinus.turnon, CSMinus.ID, exp.time(start))

PUB StopCSMinus
  '' Turns off the CS-, and records that the CS- stopped.
  exp.record(CSMinus.turnoff, CSMinus.ID, exp.time(start))

PUB StartUS
  '' Turns on the US, and records that the CS started.
  exp.record(US.turnon, US.ID, exp.time(start))

PUB StopUS
  '' Turns off the US, and records that the CS stopped.
  exp.record(US.turnoff, US.ID, exp.time(start))

DAT
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
