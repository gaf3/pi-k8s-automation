# Chore and Speech Service

# Goals

## Chore

  - Given a chore composed of multiple tasks from an interface (phone, desktop) 
  - Will remind the children of what the current task is at a specific interval via a speaker on Raspberry Pi k8s node in the room 
  - Move on to the next task once the button until all tasks are completed 
  - Record the time to complete each task as well as the overall chore.

## Speech 

- Provide a simple interface for broadcasting statements like "Dinner's ready!" or "Time to go!" or "Will the child who let a donkey into the house please come forward to receive your punishment."

# Architecture

![Architecture](/pi-k8s-fitches-chore-speech.png)

# Redis


## chore data

At the core is a basic key value store for the current chores, which is keyed node/<node>/chore/<chore> with a JSON object in the least containing and array of tasks. A little worried about race conditions here, but the JSON module in Redis should help with that.

## speech channel

Redis pubsub. A JSON object is pushed containing 
- text to speak
- timestamp (in case of restarts, won't repeat old messages)
- node to say on (optional, without will say on all nodes)
- language to speak (I'm trying tor Australian man to start).

## event channel

Redis pubsub. A JSON object is pushed containing
- button pushed
- timestamp
- node was pushed on.

# Daemon Sets:

## node speech daemon

[pi-k8s-fitches-speech-daemon](https://github.com/gaf3/pi-k8s-fitches-speech-daemon)


Runs on each k8s node with the label audio=enabled (one with speakers). Reads from the Redis speech channel. If
- the timestamp is after when the daemon first started up and
- the node matches or the message has no node 
Then 
- connects to Google text to speech API, saves the audio as a file
- plays the file out the speaker

## node event daemon

[pi-k8s-fitches-event-daemon](https://github.com/gaf3/pi-k8s-fitches-event-daemon)

Runs on each k8s node with the label buttons=enabled (one with speakers). Sets an interrupt call on the rising edge of the button. When pressed, pushes a JSON object onto the event channel recording:
- timestamp
- button pressed
- node pressed on.

# Kids' Rooms

# Node has a speakers attached 

Using regular old computer speakers attached to the built in audio jack. Will play sounds from the speech daemon. Nodes with speakers are label audio=enabled

## Node has a button attached. 

Can be down with a button and two wires and GPIO pin with a pull down resistor settings. It's dead simple: https://raspi.tv/2013/how-to-use-interrupts-with-python-on-the-raspberry-pi-and-rpi-gpio-part-3?fbclid=IwAR2KsG4eM3Slcw3_4s_CQJ2vrZVYQKIBW3z1gqVOCC0jqhBOriFNtd-8GIE

# Services

All API's will be Python connexion / Flask apps.
All Daemons will be Python do stuff and sleep loops.

[pi-k8s-api template](https://github.com/gaf3/pi-k8s-api)

## speech API

Dead simple. RESTful that akes in
- text to say
- language to say it in (optional) 
- node to say it on (optional, if none, says on all) and pushes a JSON object on the speech channel in Redis.

## chore speech daemon

Looks at any current chores on a node, determines
- current task
- last time spoken
- speaks if needed by pushing a JSON object onto the speech channel in Redis
- records that it spoke.

## chore event daemon

Listens to the event channel. If 
- an event comes in for button pressed on a node 
- that node has an active chore/task on it.
Then 
- push to the sppech channel the task is done
- will record that task as done and start the next.

## chore API

Reads any chore templates from chore storage able to
- initiate a chore on a node for a child 
- record that a task was done (or really wasn't done with these little bastards).

# Interfaces

Simple JavaScript GUI's from https://gaf3.github.io/dotroute/

## speech GUI

Just interfaces with the speech API. Single page with submission of text to speech.

## chore GUI
- able to build chore templates with tasks, how often to speak, default languages
- able to start a chore on a node for a child
- able to indicate individual tasks done / not done for an ongoing chore.