// These two lines are required to initialize Express in Cloud Code.
express = require('express');
app = express();

// Global app configuration section
app.set('views', 'cloud/views'); // Specify the folder to find templates
app.set('view engine', 'ejs'); // Set the template engine
app.use(express.bodyParser()); // Middleware for reading request body

// This is an example of hooking up a request handler with a specific request
// path and HTTP verb using the Express routing API.
app.get('/hello', function(req, res) {
    res.render('hello', {
        message: 'Custom elements from User table'
    });
});


app.get('/getUser', function(req, res) {
    
    
   // Parse.Cloud.useMasterKey();
    
        var userCount = 1;
        var drinklessUserQuery = new Parse.Query("_User");
        var resultsArray = [];
        drinklessUserQuery.limit(1000) ;

        drinklessUserQuery.find({

            success: function(results) {
                alert("Successfully retrieved " + results.length + " scores.");
                // Do something with the returned Parse.Object values
                for (var i = 0; i < results.length; i++) {
                    var object = results[i];
                    var item = [];
                    item.push(object.id);
                    item.push(object.get('auditScore'));
                    item.push(object.get('demographicsAnswers'));
                    resultsArray.push(object.createdAt);
                    resultsArray.push(item);
                }
       //         response.success(resultsArray);
       
       // res.render('getUser', {
       //     message: "Successfully retrieved: " + results.length
       // });
       
       res.render("getUser", { resultsArray : resultsArray });

            },
            error: function(error) {
                alert("Error: " + error.code + " " + error.message);
            }

        });
        

    
    
    });



        // // Example reading from the request query string of an HTTP get request.
        // app.get('/test', function(req, res) {
        //   // GET http://example.parseapp.com/test?message=hello
        //   res.send(req.query.message);
        // });

        // // Example reading from the request body of an HTTP post request.
        // app.post('/test', function(req, res) {
        //   // POST http://example.parseapp.com/test (with request body "message=hello")
        //   res.send(req.body.message);
        // });

        // Attach the Express app to Cloud Code.
        app.listen();
