DrinkLess
=========


Functionality Overview
======================================

Terminology
----------------------------------------

[]()
__Questionnaire__: The thing that showed an alert on suspension for qualified new users to gather additional information. Used only temporarily for research. See the section in `AppDelegate::finishedIntro`

__Survey__: The thing that pops up after they've been using the app a while asking them about their experience



Onboarding
----------------------------------------





Dashboard
----------------------------------------


Notifications
----------------------------------------

* Activities > MakePlan
* Drink Input Reminders (Help > Reminders)
* 
* (MRT Trial - ended 01-May-2020)
* (MemoManager - removed in v1.5(?))







Custom Serving Sizes
--------------------------------------------

* Custom Serving sizes are stored in the DB and have identifiers beginning with 10001 (see `kPXDrinkServingCustomIdentifier`).
* The 10000 id serves as a placeholder until the record is saved. Each drink type has it's own set of custom serving sizes. The latest 3 are shown when the user adds a drink (including the current custom one if doing an edit).
* The icon which will be used will be the the `..._s2` serving size (it's a bigger icon than s1). See `DrinkRecord+Extras::iconName`.  


Time Zone
----------------------------------

See the equivalent section in Code Overview...



Funny Things
------------------------------------------

_Alcohol Free Day_ is different than a day with no records. No records is considered that the user didn't record it that day, i.e. to record "0 drinks" they need to actively record an "Alcohol Free Day".

Parse _saveInBg_ vs _saveEventually_: The later caches and saves even between app runs. But the callback isnt guaranteed. The former is used when we need to delete objects from parse as we need the save callback to set the parse `objectId` for new entries. I suspect this strategy has not been used consistently throughout the code by the original dev. 












Code Overview
======================================

Storyboards
------------

| Storyboard | Description |
| ------------- | ------- |
| Main          | Not really main. More "Onboarding" i.e. First run sequence. Loaded overtop of the . presented overtop of Tabs which is the Info.plist one |
| Tabs          | Dashboard and other top level VCs |
| Activities    | (Formerly Progress)  Screens for things listed on Activities tab
| ... | tbc |




The Dashboard
------------------


### Daily Tasks

desc.....

Players:
* DailyTasks.plist
* 
completeTaskWithID




Onboarding (First Run)
--------------------------------------
* Players 
    * `Main.storyboard`
    * `PXIntroManager`
    
* First screen is  `PXWebViewController` set to `privacy-policy` see `resource` IBDesignable.

* Notification `PXFinishIntro` is posted at the end. `AppD` dismisses the onboarding modal 



Time Zone
----------------------------------


### v2.0 Swift new paradigm ##
Starting with the MyPlan area we're doing two things. The first is that dates for CoreData objects will be converted to the date in GMT with equivalent components. This will make it possible to still use predicates to do filtering and selective loading. See below for more details but for old objects (eg. `PXDrinkRecord`) we can't as the dates there are wrt to the time zone they were entered in and we need to convert them to the calendar date in the present time zone before they can be compared. Fixing this greatly complicated CD loads. So for now on we convert to the cal date equivalent in GMT and also store the TZ in case we need to convert back to the "real" Date object again (and also for reference). See `CalendarDate`,  `FoundationExt > Date`  and read below to get the whole story.

Note, Swift `AuditData` stuff was (re)written still using the old paradigm. It's only `MyPlanRecord` that begins the new system


### The Issue ##

_From email:_
Say that it's 8pm Saturday (assume GMT time for now), 12 August in London and you have a few drinks and log them. It shows up correctly. Then you fly to Dehli, India which is 5.5 hours ahead. Later you check the app calendar and it's wrong now. Why?  Since India is GMT+5.5, Sunday 13th in India actually began at 6:30pm 12 Aug in England. Since the app's logged times take time zone into account, it thinks that drink you had in London was actually on Sunday, at least until you fly back to London!  

Put another way, the actual GMT start and end times of say "Tuesday Aug 15", varies with the time zone. Hence why drinks move around the calendar. What the user wants is for the drink to remain on whatever day it was when he/she drank it, regardless of the timezone. Technically, the app needs to ignore the time zone. 

There may be another nuance to this as drinks don't just log on the wrong day, they seem to go missing other than in the totals. However, I suspect this will resolve once the core problem is fixed. 

### NSDate vs. Calendar Date ##

`NSDate` is like a timestamp. It's TZ & calendar agnostic. It's an absolute measure of a moment in time. __Calendar Date__ is like _1 Nov 2017_. It's potentially a different timestamp/`NSDate` depending where you are in the world. 

For the Calendar we want to tally drinks based on their __Calendar Date__. This has several implications. 

1. We need to extend the range of the `NSDate`s we query when looking up records for a given calendar date range. The range is extended by the difference from the current calendar's timezone to the extremes of timezones in the world
2. We need to normalise all drink records NSDate's to the calendar date before can know which "day" to tally it under. 


### In the Code ##

Well first we've added timezone to the drink and AlcoholFree records.

As for handling the range extension and calculations. We'll aim for the middle tier of helper methods. Specifically...

* `PXDrinkRecord` class methods we won't touch. Those date ranges will query based on the NSDate's stored in the DB
* 
`PXCalendarStats` and `AllStats` will have the bulk of this logic, if not all of it.

### The Calendar Dates ##

To get the drink totals for a given day we need to:

1. Get the drinks entered in absolute times ±25 hrs. (TZ's run from -11 to +14). 
2. Go through them adding the timezone offset and figure out the date as it was to the user when s/he entered it. 
3. If it's not on the date being considered then exclude it from the total


### Date Swizzle Debug Panel ##

Enable in `PXDebug.h`. Swizzles `NSDate.date`. Also sets the defaultTimeZone but this doesn't have an effect on localTimeZone used so we'll need to do a swizzle in the future.


### Remaining Known Issues

* I believe if the user sets the Reminder Date (See Help > Reminders and `PXDiaryReminderViewController`) from in a timezone and then changes, `PXLocalNotifManager::updateConsumptionReminder` may schedule it for the wrong time. Need to say the Hour/Min in Userdefs not an `NSDate`


### Moving Forward with Swift

New CalendarDate class.  

Best practices..eg. `MyPlanRecord.fetch...`






Code Housecleaning
========================

General
-----------------------------------
* ReminderTypes.plist is just about obsolete. We're only using consumption reminders so I think we can hard code this now



DataServer
-------------

* Cleanup the `...inBackground` versus `...eventually` business. Delete doesnt check for local sync and some of the saveInBackgrounds dont have manually cleanup code in `PXCoreDataManager`

* In the refactor I didnt change any of the model properties named `*parse*` as this might mess up persistence (wasnt worth the risk for the task). Maybe clean this up if another data sever is ever used




(Local) Notifications
---------------------

This used to be a more complex system but the ID thing has altered with `UNNotifications` and it isn't worth a rewrite as the multi-notif functionality isnt so prolific. Really in it needs a re-think and swiftification if more notif types and handlers are added.


