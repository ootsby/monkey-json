# Quick Start #

Monkey-JSON provides a straight-forward interface for reading and writing JSON strings. The following is a simple example of reading from a JSON file and

```
Import json
Import mojo


Function Main()
	Local a:App = New App
	Local test:String = a.LoadString("jsontest.json")
	
	Local data:JSONDataItem = JSONData.ReadJSON(test)
	Print "Monkey representation:"
	Print data 'ToString writes out Monkey strings
	
	Print "Writing back out:"
	Print JSONData.WriteJSON(data)
End
```

JSONDataItems are wrapper classes for JSON data. JSONObjects provide access to data items by name and both JSONObject and JSONArray provide enumerators for traversing their contents.

Writing to JSON is a matter of constructing JSONDataItems as desired and then passing the root object to the WriteJSON function as above.