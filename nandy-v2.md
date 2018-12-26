# Nandy Home Reliability Engineering v2

# Goal

Overall to make a Home run happier.  This is about establishing good habits and getting accurate feedback towards desired results.

# Design

Progress through Work Flows -> Data Models -> Library Methods -> API Endpoints -> GUI Views so that each piece is satsifying one or more specific needs. 

# Work Flows

These are the processes we want Nandy to implement.

## Routines

Repetitive list of tasks, some repeating, some every now and then. 

### Morning

Parents put a list of tasks, person and node in a Google calendar entry. These include get up, get dressed, brush teeth, etc. 

Need the ability to have certain tasks be paused and resumed when the time requires. 

Children are reminded to completet each tasks on the node at a different interval per task

Children indicate done by hhtting a button. 

Parents can view the list of tasks, and adjust when neeesary.

### Afternoon

Parents create a collection of tasks (not necessarily a list). These include do homework, practive instruments, etc. 

Children are reminded every fifteen minutes or so about all the tasks they need to complete.

Children indicate done by using a tablet or laptop. 

Parents can view the list of tasks, and adjust when neeesary.

### Nigthtime

Parents put a list of tasks, person and node in a Google calendar entry. These include get dressed for bed, brush teeth, etc. 

Children are reminded to completet each tasks on the node at a different interval per task

Children indicate done by hhtting a button. 

Parents can view the list of tasks, and adjust when neeesary.

### Preparation

Though not scheduled, sometimes we want to do something and that'll require a set of tasks, like swimming.  Each person needs to get their suit, towel, and any toys. 

Parent would select a sort of template for the routines, who needs to do it, and that create a chore / task list.

Children indicate done by hhtting a button or by using a tablet or laptop. 

## Maintenance

Single events we have to do over and over. 

### Owned

Children (and Parents) have to keep their bed made, room clean, clotes put away. 

Parent would set something like Bed = Unmade in a Child's room and then a chore for that child would be created like "make your bed" to put it into a desired state. 

This could also be litter box = dirty, hamper = full, etc. 

### General

Other aspects of the house need to be maintained, like the kitchen cleaned, laundry run.  These would also have statuses but no owners.  So a chore wouldn't be created automatically, just ready to do so if given a person.

Ie kitchen = dirty => create chore "clean kitchen" => person accepts it => chore star -> finish. 

### Location

Notice all of these are tied to a location of some sort and that someone (or something) could go to that location and determine the state.  This process could also be on a timer, like once a day check rooms.  Twice a day, check the kitchen. 

### Decay

Certain areas would naturally require work, like the litter box, the lawn.  

A Daemon would look at different areas and actions since and created a chore if nothing's been done in awhile. 

If area is still fine, Parent (or Child really) could push it back a day or so. 

### Status changed

If a chore is tied to an area and is completed, that area status should change automatically. 

## Behavior

We also want to encourage good behavior.  We should track when someone does a litlte extra or something they shouldn't. 

### Postive

Child would do something nice, like help out, or feed an animal.

Parent would record this happened. 

### Negative

Child would do something not nice, like be mean to someone or an animal.

Parent would record this happened. 

### Neglect

Child would do something like leave their coat on the stairs.

Parent would record this happened and where it happened.

Chore would be created for the Child to remedy the sitation, ie "go to the stairs and put your coat away". 

### Timely

We could also tied a chore back to an act. For example, if a Child gets their morning routine done in under 15 minutes, that's positive.  If over 20 minutes, that's a negative. 

## Reporting

Feedback is critical here.  v1 just stored the active chore.  In v2 we want a record of everything. 

### Duration

Parents should be able to see a history of how long Children took to do Chores and tasks. 

Every Chore and Tasks duration should be record in a time series DB. 

### Behavior

Parents should be able to see the overall positive and negative bejaviors.

Children should to, like how many times Parents yelled. Keep everyone honest here. 

### Location

Parents and children should be able to see how long a location was in a good or bad state. 

### Reward

Parents should be able to give feedback to the Children and reward them for positive behavior. 

## Planning

Parents should be able to sit down with the Children regularly and plan out chores through Google Calendar, how long steps should take etc. 

# Data Models

## Redis

### speech

Channel for converting text to speech

JSON object:
- timestamp - Time this message should be spoked
- node - The node on which to speak
  - If omitted, play on all
- text - The text to speak
- language - The language to speak it in
  - If ommitted, defaults to "en"

Example:

```json
{
    "timestamp": 1543074126,
    "node": "pi-k8s-node02",
    "text": "Hi",
    "language": "en"
}
```

### event

Channel for tracking pushed buttons

JSON object:
- timestamp - Time of the event
- node - The node on which the event happened
- type - Rising or falling
- gpio_port - The GPIO port that rose

Example:

```json
{
    "timestamp": 1543074126,
    "node": "pi-k8s-node02",
    "type": "rising",
    "gpio_port": 4
}
```

## MySQL

These models each have their own table. Many of these have data field, which is freeform JSON.

- Person - person able to perform Chores.
- Chore - work to perform, can have a task list
    - Task - individual steps in a chore, stored in Chore.data["tasks"]
- Area - place that can need work or simply where work can take place
- Act - Postive or negative action
- Template - Blueprint for Chores or Acts

Information might be in fields or might be in the data blob.  

Since we're using MySQL 5.5 without the JSON field the rule is if we need to search on it, field.  If not, data. 

### Person

Very simple.  Just a way to keep track of who did what, and tie back to Google via email. 

- id
- name (first only)
- email

### Chore

A lot of stuff and very flexible

- id
- person_id - Mustn't be null
- label - Human readbale
- status - "started", "ended"
- created - Timestamp
- updated - Timestamp
- data - General JSON blob
  - node - to speak on / press button
  - language - language to use
  - paused - If true, task is paused
  - skipped - If true, task is skipped
  - delay - Delay to start reminding (in secs)
  - interval - Interval in seconds to remind (in secs)
  - start - Time started
  - notified - Time last notified (start, reminder, complete)
  - end - Time it completed (non existement if incomplete)
  - tasks - list of tasks
    - id - The id to access the task (index for now)
    - text - The text of the task
    - paused - If true, task is paused
    - skipped - If true, task is skipped
    - delay - Delay to start reminding (in secs)
    - interval - Interval in seconds to remind (in secs)
    - start - Time started
      - If non existent, no reminder
    - notified - Time last notified (start, reminder, complete)
    - end - Time it completed (non existement if incomplete)
  - area:
    - id - area to update upon completion
    - status - status to set it too

### Area

Fairly complex as could have owner, chores to create, etc. 
- id
- label - Human readbale
- status - Varies by area (clean / dirty, full / empty)
- updated - Timestamp
- data - General JSON blob
  - statuses - Possible values
    - value - of status
    - chore - chore to create if that status is set
      - person_id would be here

### Act

- id
- person_id - Can't be null
- label - Human readbale
- value - "positive", "negative"
- created - Timestamp

Can't currently see a need for a JSON field

### Template

As complex as Chore or Act, just missing a little info.

- id
- label - Human readbale
- kind - "chore", "act"
- data - Containing what's needs for either, including field values (not just data)

## Graphite

Take names / labels and lowercase / replaces spaces with underscores. 

### Chore

- nandy.person.{person.name}.chore.{chore.label}.duration - Duration of overall chore at time started
- nandy.person.{person.name}.chore.{chore.label}.task.{task.label}.duration - Duration of task from time started

We can use these to determine how long tasks are taking and adjust reminders to a more reasonable level.

### Area

- nandy.area.{area.label}.status.{status.value} - 1 for active, at time of switch

We can use this to determine which areas are in which states longest and refocus efforts appropriately. 

### Act

- nandy.person.{person.name}.act.{act.label} - The act with the positive or negative value at the time it happened

We can use these are reward / punishment. 

# Architecture

![Architecture](/pi-k8s-fitches-nandy-v2.png)

## Storage

### Redis

[pi-k8s-fitches/redis](https://github.com/pi-k8s-fitches/redis)

- speech channel
- event channel

### MySQL

[pi-k8s-fitches/mysql](https://github.com/pi-k8s-fitches/mysql)

- nandy database

### Graphite

[pi-k8s-fitches/graphite](https://github.com/pi-k8s-fitches/graphite)

- nandy folder

## nandy data

[pi-k8s-fitches/nandy-data](https://github.com/pi-k8s-fitches/nandy-data)

Core lib for dealing with the three data stores

- speak - Says a phrase based on chore, task, act
- person CRUD operations - just use model
- template CRUD operations - just use model
- area CRUD operations - just use model
- area_status - Updates and fires off chores if necessary
- chore RUD operations - just use model
- chore_check - Checks a chore to see if there's tasks remaining
- chore_create - Creates a chore from template
- chore_remind - Looks through a chore and sees if there's an reminders to go out
- chore_next - Completes current tasks and starts next task or finishes chore
- chore_pause - Pauses a chore
- chore_unpause - Unpauses a chore
- chore_skip - Skips a chore
- chore_unskip - Unskips a chore
- chore_complete - Completes a chore
- chore_incomplete - Incompletes a chore
- task_pause - Pauses a specific chore task
- task_unpause - Unpauses a specific chore task
- task_skip - Skips a specific chore task
- task_unskip - Unskips a specific chore task
- task_complete - Completes a specific chore task
- task_incomplete - Incompletes a specific chore task
- act RUD operations - just use model
- act_create - Creates and fires off chores if necessary

We're not going to get fancy here. Just use big editable data structures. 

## Daemons

### node speech daemon

[pi-k8s-fitches/node-speech-daemon](https://github.com/pi-k8s-fitches/node-speech-daemon)

Runs on each k8s node with the label audio=enabled (one with speakers). Reads from the Redis speech channel. If
- the timestamp is after when the daemon first started up and
- the node matches or the message has no node 
Then 
- connects to Google text to speech API, saves the audio as a file
- plays the file out the speaker

### chore speech daemon

[pi-k8s-fitches/chore-speech-daemon](https://github.com/pi-k8s-fitches/chore-speech-daemon)

Looks at any current chores on a node, determines
- current task
- last time spoken
- speaks if needed by pushing a JSON object onto the speech channel in Redis
- records that it spoke.

## chore calendar daemon

[pi-k8s-fitches/chore-calendar-daemon](https://github.com/pi-k8s-fitches/chore-calednar-daemon)

Connects to the Goggle Calendar API.
- Looks for events five muntes before and after current time on the pi-k8s-fitches/chores Calendar
- If found, Parse the description as a YAML blob
- Checks to see if the current chore matches
- If not creates a chore using the YAML blob as a template

### chore event daemon

[pi-k8s-fitches/chore-event-daemon](https://github.com/pi-k8s-fitches/chore-event-daemon)

Listens to the event channel. If 
- an event comes in for button pressed on a node 
- that node has an active chore/task on it.
Then 
- push to the sppech channel the task is done
- will record that task as done and start the next.

### node event daemon

[pi-k8s-fitches/node-event-daemon](https://github.com/pi-k8s-fitches/node-event-daemon)

Runs on each k8s node with the label buttons=enabled (one with speakers). Sets an interrupt call on the rising edge of the button. When pressed, pushes a JSON object onto the event channel recording:
- timestamp
- button pressed
- node pressed on.

## Services

It looks like for this interaction, I'll have to go through with the OpenGUI project. 

### speech api

[pi-k8s-fitches/speech-api](https://github.com/pi-k8s-fitches/speech-api)

- GET /health - Health check
- POST /speak - Speech to Text on a node
- GET /speak
- POST/PATCH */opengui - Dynamic settings for all endpoints

### nandy api

- GET /health - Health check
- POST /person - Create person
- GET /person - List persons
- GET /person/{person_id} - Retrieve a person
- PATCH /person/{person_id} - Update a person
- DELETE /person/{person_id} - Delete a person
- POST /template - Create template
- GET /template - List templates
- GET /template/{template_id} - Retrieve a template
- PATCH /template/{template_id} - Update a template
- DELETE /template/{template_id} - Delete a template
- POST /area - Create area
- GET /area - List areas on 
  - status
  - updated
- GET /area/{area_id} - Retrieve a area
- PATCH /area/{area_id} - Update a area (should avoid, bypasses hooks)
- POST /area/{area_id}/status - Changes the status of an area, using hooks
- POST /chore - Create chore from template
- GET /chore - List chores on 
  - person
  - status
  - created
  - updated
- GET /chore/{chore_id} - Retrieve a chore
- PATCH /chore/{chore_id} - Update a chore (should avoid, bypasses hooks)
- POST /chore/{chore_id}/{action} - Person one of the following actions on a chore
  - next - Completes current tasks and starts next task or finishes chore
  - pause - Pauses a chore
  - unpause - Unpauses a chore
  - skip - Skips a chore
  - unskip - Unskips a chore
  - complete - Completes a chore
  - incomplete - Incompletes a chore
- POST /chore/{chore_id}/task/{task_id}/{action} - Person one of the following actions on a task
  - pause - Pauses a task
  - unpause - Unpauses a task
  - skip - Skips a task
  - unskip - Unskips a task
  - complete - Completes a task
  - incomplete - Incompletes a task
- DELETE /chore/{chore_id} - Delete a chote
- POST /act - Create act from template
- GET /act - List acts on 
  - person
  - created
- GET /act/{act_id} - Retrieve an act
- PATCH /act/{act_id} - Update an act
- DELETE /act/{act_id} - Delete an act
- POST/PATCH */opengui - Dynamic settings for all endpoints

### graphite

[pi-k8s-fitches/graphite](https://github.com/pi-k8s-fitches/graphite)

Probably won't interface directly with, jsut through grafana. 

## Interfaces

Simple JavaScript GUI's from https://gaf3.github.io/dotroute/

### speech GUI

[pi-k8s-fitches/speech-gui](https://github.com/pi-k8s-fitches/speech-gui)

Just interfaces with the speech API. Single page with submission of text to speech.

[pi-k8s-fitches/chore-gui](https://github.com/pi-k8s-fitches/chore-gui)

### nandy GUI

- #/ - home like a status page
  - Lists active chores
    - Click to drill down
- #/person - List
- #/person/create - Create
- #/person/{person_id} - Retrieve (can Delete)
  - Will show current chores
  - Will perform reminders
- #/person/{person_id}/update - Update
- #/template - List
  - kind
- #/template/create - Create
- #/template/{template_id} - Retrieve (can Delete)
- #/template/{template_id}/update - Update
- #/area - List
- #/area/create - Create
- #/area/{area_id} - Retrieve (can Delete)
  - Can status update for hooks here
- #/area/{area_id}/update - Update (avoids hooks)
- #/chore - List
  - person
  - status
  - created
  - updated
- #/chore/create - Create from template
- #/chore/{chore_id} - Retrieve (can Delete)
  - For chore
    - next - Completes current tasks and starts next task or finishes chore
    - pause - Pauses a chore
    - unpause - Unpauses a chore
    - skip - Skips a chore
    - unskip - Unskips a chore
    - complete - Completes a chore
    - incomplete - Incompletes a chore
  - For any task
    - pause - Pauses a task
    - unpause - Unpauses a task
    - skip - Skips a task
    - unskip - Unskips a task
    - complete - Completes a task
    - incomplete - Incompletes a task
- #/chore/{chore_id}/update - Update (avoid hooks)
- #/act - List
  - person
  - value
  - created
- #/act/create - Create from template
- #/act/{act_id} - Retrieve (can Delete)
- #/act/{act_id}/update - Update

### grafana

[pi-k8s-fitches/grafana](https://github.com/pi-k8s-fitches/grafana)

- Report by person for chore length
- Report by person for task length
- Report by area for statuses
- Report by person for acts. positive / negative

## Hardware

### Node has a speakers attached 

Using regular old computer speakers attached to the built in audio jack. Will play sounds from the speech daemon. Nodes with speakers are label audio=enabled

### Node has a button attached. 

Can be down with a button and two wires and GPIO pin with a pull down resistor settings. It's dead simple: https://raspi.tv/2013/how-to-use-interrupts-with-python-on-the-raspberry-pi-and-rpi-gpio-part-3?fbclid=IwAR2KsG4eM3Slcw3_4s_CQJ2vrZVYQKIBW3z1gqVOCC0jqhBOriFNtd-8GIE
