require('cloud/app.js');
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:

// Dave's first request: Get objectId, auditScore, createdAt and demographicAnswers from _User table and export to CSV
Parse.Cloud.define("getUserDemographics", function(request, response) {
    var userCount;
    var drinklessUserQuery = new Parse.Query("_User");
    var resultsArray = [];
    
    drinklessUserQuery.find({
        success: function(results) {
            alert("Successfully retrieved " + results.length + " u");

            for (var i = 0; i < results.length; i++) {
              var object = results[i];
              var item = [];
                  item.push(object.id);
                  item.push(object.get('auditScore'));
                  item.push(object.get('demographicsAnswers'));
                  item.push(object.createdAt);
                  resultsArray.push(item);
            }
            response.success(resultsArray);
        },
        error: function(error) {
          alert("Error: " + error.code + " " + error.message);
        }
    })       
 
});

Parse.Cloud.define("getGroup", function(request, response) {
    
  function incrementGroup(results) {
        console.log("Starting increment Group");
          var updateGroupIDQuery = new Parse.Query("PXGroup");
          var objectID = "RZ2ICV69Hy";
      
          updateGroupIDQuery.first({
               success: function(object) {
                  
                  var groupArray = results.get("groupArray");
                  
                  //select a random item from the array
                  var selectedItem = groupArray[Math.floor(Math.random()*groupArray.length)];
                  
                  //remove that item from the array
                  var index = groupArray.indexOf(selectedItem);
                  groupArray.splice(index, 1);

                  //Update the array in the db with the new smaller array unless the array has no items in which case create a new one.
                  if (groupArray.length > 0) {
                      object.set("groupArray", groupArray);
                      object.save();
                  } else {

                      var newGroupArray = [];

                      for (var i = 1; i <= 32; i++) {
                         newGroupArray.push(i);
                      }
                      
                      object.set("groupArray", newGroupArray);
                      object.save();  
                  }
                  response.success(selectedItem);  
               },
               error: function(error) {
                  response.error(error.message);
               }
         });  
  }
  
  var query = new Parse.Query("PXGroup");
  var objectID = "RZ2ICV69Hy";
  
  query.get(objectID, {
      success: function(results) {
          incrementGroup(results);
        
    },
      error: function() {
        response.error("group lookup failed");
      }
    });  
});

Parse.Cloud.define("getGroupFromArray", function(request, response) {
  
  console.log("Starting getGroup");
  
    
  
  var query = new Parse.Query("PXGroup");
  var objectID = "RZ2ICV69Hy";
  
  query.get(objectID, {
      success: function(results) {
          incrementGroup(results);
        
    },
      error: function() {
        response.error("group lookup failed");
      }
    });  
});


        






