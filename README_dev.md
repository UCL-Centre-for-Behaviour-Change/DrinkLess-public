DrinkLess
=========


Terminology
--------------


__Questionnaire__: The thing that showed an alert on suspension for qualified new users to gather additional information. Used only temporarily for research. See the section in `AppDelegate::finishedIntro`

__Survey__: The thing that pops up after they've been using the app a while asking them about their experience



Funny Things
----------------

_Alcohol Free Day_ is different than a day with no records. No records is considered that the user didn't record it that day, i.e. to record "0 drinks" they need to actively record an "Alcohol Free Day".




Time Zone
------------

### The Issue ###

_From email:_
Say that it's 8pm Saturday (assume GMT time for now), 12 August in London and you have a few drinks and log them. It shows up correctly. Then you fly to Dehli, India which is 5.5 hours ahead. Later you check the app calendar and it's wrong now. Why?  Since India is GMT+5.5, Sunday 13th in India actually began at 6:30pm 12 Aug in England. Since the app's logged times take time zone into account, it thinks that drink you had in London was actually on Sunday, at least until you fly back to London!  

Put another way, the actual GMT start and end times of say "Tuesday Aug 15", varies with the time zone. Hence why drinks move around the calendar. What the user wants is for the drink to remain on whatever day it was when he/she drank it, regardless of the timezone. Technically, the app needs to ignore the time zone. 

There may be another nuance to this as drinks don't just log on the wrong day, they seem to go missing other than in the totals. However, I suspect this will resolve once the core problem is fixed. 

### NSDate vs. Calendar Date ###

`NSDate` is like a timestamp. It's TZ & calendar agnostic. It's an absolute measure of a moment in time. __Calendar Date__ is like _1 Nov 2017_. It's potentially a different timestamp/`NSDate` depending where you are in the world. 

For the Calendar we want to tally drinks based on their __Calendar Date__. This has several implications. 

1. We need to extend the range of the `NSDate`s we query when looking up records for a given calendar date range. The range is extended by the difference from the current calendar's timezone to the extremes of timezones in the world
2. We need to normalise all drink records NSDate's to the calendar date before can know which "day" to tally it under. 


### In the Code ###

Well first we've added timezone to the drink and AlcoholFree records.

As for handling the range extension and calculations. We'll aim for the middle tier of helper methods. Specifically...

* `PXDrinkRecord` class methods we won't touch. Those date ranges will query based on the NSDate's stored in the DB
* 
`PXCalendarStats` and `AllStats` will have the bulk of this logic, if not all of it.

### The Calendar Dates ###

To get the drink totals for a given day we need to:

1. Get the drinks entered in absolute times ±25 hrs. (TZ's run from -11 to +14). 
2. Go through them adding the timezone offset and figure out the date as it was to the user when s/he entered it. 
3. If it's not on the date being considered then exclude it from the total


### Date Swizzle Debug Panel ###

Enable in `PXDebug.h`. Swizzles `NSDate.date`. Also sets the defaultTimeZone but this doesn't have an effect on localTimeZone used so we'll need to do a swizzle in the future.




