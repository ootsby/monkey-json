This module provides support for reading and writing data in the JSON interchange format.

The module is intended for use as a save/load format for game data and the interface is designed for ease of use in that scenario. In particular, it takes advantage of Monkey's auto-unboxing to enable simple extraction of data at the cost of potentially allowing assignment errors (for example, reading an Integer into a String).

Example usage:

```
    'Read JSON file'
    Local test:String = LoadString("jsontest.json")
    Local data:JSONDataItem = JSONData.ReadJSON(test)

    'In this case we know that the root is a JSON object'
    'If we didn't, the type can be discovered through the'
    'dataType Field or through direct type testing.'

    Local jsonObject:JSONObject = JSONObject(data)

    'Extract primitive values by name. The values are automatically'
    'unboxed to the primitive types. Be aware that all values will'
    'unbox to all primitive types, although an error will be printed'
    'if the type isn't actually supported'
    
    name = jsonObject.GetItem("name") 'This is a String
    width = jsonObject.GetItem("width")  'width and height are Floats
    height = jsonObject.GetItem("height")  
    isBounded = jsonObject.GetItem("isBounded")  'isBounded is a Bool

    'Constructing a JSON object for writing'

    Local root:JSONObject = New JSONObject()
    root.AddPrim("name",name)
    root.AddPrim("width",width)
    root.AddPrim("height",height)
    root.AddPrim("isBounded",isBounded)
	
    'JSON objects and arrays can contain objects and arrays'	
    Local playerJSON:JSONObject = New JSONObject()
    playerJSON.AddPrim("posX",player.position.x)
    playerJSON.AddPrim("posY",player.position.y)
    root.AddItem("player",playerJSON)

    'Writing the JSON'
    Local JSONString:String = JSONData.WriteJSON(root)
```