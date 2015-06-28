## hubot-timezone

Hubot script to convert time between timezones.

### Installation

`npm install hubot-timezone --save`

And add `hubot-timezone` to `external-scripts.coffee`.

### Commands

    hubot time in <location> - Ask hubot for a time in a location
    hubot <time> in <location> - Convert a given time to a given location, e.g. "1pm in Sydney"
    hubot <time> from <location> to <location> - Convert a given time between 2 locations
    hubot set timezone offset to <offset> - Set the default timezone offset, can be hours or minutes

### Sample usage

    user>> hubot time in Sydney
    hubot>> Time in Sydney NSW, Australia is Sunday, June 28th 2015, 6:15:39 pm
    user>> hubot set timezone offset to 8
    hubot>> Default timezone offset is set to 480
    user>> hubot 1pm in Singapore
    hubot>> Time in Singapore is Sunday, June 28th 2015, 1:00:00 pm
    user>> hubot 2015-7-4 9:30am from San Jose to Tokyo
    hubot>> Time in Tokyo, Japan is Sunday, July 5th 2015, 1:30:00 am
