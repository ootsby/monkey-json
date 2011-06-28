#rem
'/*
'* Copyright (c) 2011, Damian Sinclair
'*
'* All rights reserved.
'* Redistribution and use in source and binary forms, with or without
'* modification, are permitted provided that the following conditions are met:
'*
'*   - Redistributions of source code must retain the above copyright
'*     notice, this list of conditions and the following disclaimer.
'*   - Redistributions in binary form must reproduce the above copyright
'*     notice, this list of conditions and the following disclaimer in the
'*     documentation and/or other materials provided with the distribution.
'*
'* THIS SOFTWARE IS PROVIDED BY THE MONKEY-JSON PROJECT CONTRIBUTORS "AS IS" AND
'* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
'* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
'* DISCLAIMED. IN NO EVENT SHALL THE MONKEY-JSON PROJECT CONTRIBUTORS BE LIABLE
'* FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
'* DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
'* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
'* CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
'* LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
'* OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
'* DAMAGE.
'*/
#end

Import json

Class JSONData

	Function WriteJSON:String(jsonDataItem:JSONDataItem)
		Return jsonDataItem.ToJSONString()
	End

	Function ReadJSON:JSONDataItem(jsonString:String)
		Local tokeniser:JSONTokeniser = New JSONTokeniser(jsonString)
		
		Local data:JSONDataItem = GetJSONDataItem(tokeniser)
			
		If Not data
			Return New JSONDataError("Unknown JSON error.", tokeniser.GetCurrentSectionString())
		ElseIf data.dataType <> JSONDataType.JSON_ERROR And data.dataType <> JSONDataItem.JSONDataType.JSON_OBJECT And data.dataType <> JSONDataItem.JSONDataType.JSON_ARRAY
			Return New JSONDataError("JSON Document malformed. Root node is not an object or an array", tokeniser.GetCurrentSectionString())
		End

		Return data
	End


	Function CreateJSONDataItem:JSONDataItem(value:Float)
		Return New JSONFloat(value)
	End

	Function CreateJSONDataItem:JSONDataItem(value:Int)
		Return New JSONInteger(value)
	End

	Function CreateJSONDataItem:JSONDataItem(value:String)
		Return New JSONString(value)
	End
	
	Function CreateJSONDataItem:JSONDataItem(value:Bool)
		Return New JSONBool(value)
	End

	Function GetJSONDataItem:JSONDataItem(tokeniser:JSONTokeniser)
		Local token:JSONToken = tokeniser.NextToken()
	
		Select token.tokenType
			Case JSONToken.TOKEN_OPEN_CURLY
				Return GetJSONObject(tokeniser)
			Case JSONToken.TOKEN_OPEN_SQUARE
				Return GetJSONArray(tokeniser)
			Case JSONToken.TOKEN_STRING
				Return New JSONString(StringObject(token.value))
			Case JSONToken.TOKEN_FLOAT
				Return New JSONFloat(FloatObject(token.value))
			Case JSONToken.TOKEN_INTEGER
				Return New JSONInteger(IntObject(token.value))
			Case JSONToken.TOKEN_TRUE
				Return New JSONBool(True)
			Case JSONToken.TOKEN_FALSE
				Return New JSONBool(False)
			Case JSONToken.TOKEN_NULL
				Return New JSONNull()			
			Default
				Return New JSONNonData(token)
		End
	End

	Function GetJSONObject:JSONDataItem(tokeniser:JSONTokeniser)
		Local jsonObject:JSONObject = New JSONObject()
		Local data1:JSONDataItem
		Local data2:JSONDataItem
		
		'Check if this is an empty definition'
		data1 = JSONData.GetJSONDataItem(tokeniser)
		If data1.dataType = JSONDataType.JSON_NON_DATA And JSONNonData(data1).value.tokenType = JSONToken.TOKEN_CLOSE_CURLY
			'End of object'
			Return jsonObject
		End

		Repeat
			If data1.dataType <> JSONDataType.JSON_STRING
				Return New JSONDataError("Expected item name, got " + data1, tokeniser.GetCurrentSectionString())
			End
			data2 = JSONData.GetJSONDataItem(tokeniser)
			If data2.dataType <> JSONDataType.JSON_NON_DATA
				Return New JSONDataError("Expected ':', got " + data2, tokeniser.GetCurrentSectionString())
				'tokeniser.PrintErrorMessage("Expected ':', got " + data2 )
				'Exit
			Else
				If JSONNonData(data2).value.tokenType <> JSONToken.TOKEN_COLON
					Return New JSONDataError("Expected ':', got " + JSONNonData(data2).value, tokeniser.GetCurrentSectionString())
					'tokeniser.PrintErrorMessage("Expected ':', got " + JSONNonData(data2).value )
					'Exit
				End
			End
			data2 = JSONData.GetJSONDataItem(tokeniser)
			If data2.dataType = JSONDataType.JSON_ERROR
				Return data2
			ElseIf data2.dataType = JSONDataType.JSON_NON_DATA
				Return New JSONDataError("Expected item value, got " + JSONNonData(data2).value, tokeniser.GetCurrentSectionString())
				'tokeniser.PrintErrorMessage("Expected item value, got " + JSONNonData(data2).value )
				'Exit
			End
			jsonObject.AddItem(JSONString(data1).value,data2)
			data2 = JSONData.GetJSONDataItem(tokeniser)
			If data2.dataType <> JSONDataType.JSON_NON_DATA
				Return New JSONDataError("Expected ',' or '}', got " + data2, tokeniser.GetCurrentSectionString())
				'tokeniser.PrintErrorMessage("Expected ',' or '}', got " + data2 )
				'Exit
			Else
				If JSONNonData(data2).value.tokenType = JSONToken.TOKEN_CLOSE_CURLY
					Exit 'End of Object'
				ElseIf JSONNonData(data2).value.tokenType <> JSONToken.TOKEN_COMMA
					Return New JSONDataError("Expected ',' or '}', got " + JSONNonData(data2).value, tokeniser.GetCurrentSectionString())
					'tokeniser.PrintErrorMessage("Expected ',' or '}', got " + JSONNonData(data2).value )
				End
			End
			data1 = JSONData.GetJSONDataItem(tokeniser)
			
		Forever

		Return jsonObject
	End
	
	Function GetJSONArray:JSONDataItem(tokeniser:JSONTokeniser)
		Local jsonArray:JSONArray = New JSONArray()
		Local data:JSONDataItem
		
		'Check for empty array'
		data = JSONData.GetJSONDataItem(tokeniser)
		If data.dataType = JSONDataType.JSON_NON_DATA And JSONNonData(data).value.tokenType = JSONToken.TOKEN_CLOSE_SQUARE
			Return jsonArray
		End
	
		Repeat
			If data.dataType = JSONDataType.JSON_NON_DATA
				Return New JSONDataError("Expected data value, got " + data, tokeniser.GetCurrentSectionString())
			ElseIf data.dataType = JSONDataType.JSON_ERROR
				return data
			End
			jsonArray.AddItem(data)
			
			data = JSONData.GetJSONDataItem(tokeniser)
			
			If data.dataType = JSONDataType.JSON_NON_DATA
				Local token:JSONToken = JSONNonData(data).value
				If token.tokenType = JSONToken.TOKEN_COMMA
					data = JSONData.GetJSONDataItem(tokeniser)
					Continue
				ElseIf token.tokenType = JSONToken.TOKEN_CLOSE_SQUARE
					Exit 'End of Array'
				Else
					Return New JSONDataError("Expected ',' or '], got " + token, tokeniser.GetCurrentSectionString())
				End
			Else
				Return New JSONDataError("Expected ',' or '], got " + data, tokeniser.GetCurrentSectionString())
			End
		Forever

		Return jsonArray
	End	

	Function ConvertMonkeyEscapes:String( input:String )
    	Return input.Replace( "\", "\\" ).Replace( "/", "\/" ).Replace( "~q", "\~q" ).Replace( "~n", "\n" ).Replace( "~r", "\r" ).Replace( "~t", "\t" ).Replace("{ff}","\f").Replace("{un}","\u").Replace("{bs}","\b")
    End

	Function ConvertJSONEscapes:String(input:String)
		Local escIndex:Int = input.Find("\")
		Local copyStartIndex:Int = 0
		Local retString:String = ""

		While escIndex <> -1
			retString += input[copyStartIndex..escIndex]
			Select input[escIndex+1]
				Case 110 'n - newline
					retString += "~n"
				Case 34 'quote
					retString += "~q"
				Case 116 'tab
					retString += "~t"
				Case 92 '\
					retString += "\"
				Case 47 '/
					retString += "/"
				Case 114 'r return
					retString += "~r"			
				Case 102 'f formfeed
					retString += "{ff}"			
				Case 98 'b backspace
					retString += "{bs}"			
				Case 117 'u unicode
					retString += "{un}"			
			End
			copyStartIndex = escIndex+2
			escIndex = input.Find("\",copyStartIndex)
		End

		retString += input[copyStartIndex..]

		return retString
	End
End


Class JSONDataType
	'TODO: Change to typesafe enum pattern? Performance issues, maybe?'
	Const JSON_ERROR:Int = -1
	Const JSON_OBJECT:Int = 1
	Const JSON_ARRAY:Int = 2
	Const JSON_FLOAT:Int = 3
	Const JSON_INTEGER:Int = 4
	Const JSON_STRING:Int = 5
	Const JSON_BOOL:Int = 6
	Const JSON_NULL:Int = 7
	Const JSON_NON_DATA:Int = 8
End

Class JSONDataItem Abstract

	Field dataType:Int = JSONDataType.JSON_NULL

	'Method ToPrettyString() Abstract
	Method ToString:String() Abstract
	Method ToJSONString:String() 
		Return ToString()
	End
End

Class JSONDataError Extends JSONDataItem
	Field value:String
	
	Method New(errorDescription:String, location:String) 
		dataType = JSONDataType.JSON_ERROR 
		value = errorDescription + "~nJSON Location: " + location
	End

	Method ToString:String()
		Return value 
	End
End

Class JSONNonData Extends JSONDataItem
	Field value:JSONToken
	
	Method New(token:JSONToken) 
		dataType = JSONDataType.JSON_NON_DATA 
		value = token
	End

	Method ToString:String()
		Return "Non Data"
	End
End

Class JSONFloat Extends JSONDataItem
	Field value:Float
	
	Method New(value:Float) 
		dataType = JSONDataType.JSON_FLOAT 
		Self.value = value
	End

	Method ToString:String()
		Return "" + value
	End
End

Class JSONInteger Extends JSONDataItem
	Field value:Int
	
	Method New(value:Int) 
		dataType = JSONDataType.JSON_INTEGER 
		Self.value = value
	End

	Method ToString:String()
		Return "" + value
	End
End

Class JSONString Extends JSONDataItem
	Field value:String
	Field monkeyString:String 

	Method New(value:String, isMonkeyString:Bool = False) 
		dataType = JSONDataType.JSON_STRING
		If isMonkeyString
			Self.monkeyString = value
			Self.value = JSONData.ConvertMonkeyEscapes(value)
		Else
			Self.value = value
			Self.monkeyString = JSONData.ConvertJSONEscapes(value)
		End
	End

	Method ToJSONString:String()
		Return "~q"+value+"~q"
	End

	Method ToString:String()
		Return "~q"+monkeyString+"~q"
	End

End

Class JSONBool Extends JSONDataItem
	Field value:Bool 
		
	Method New(value:Bool) 
		dataType = JSONDataType.JSON_BOOL
		Self.value = value
	End

	Method ToString:String()
		If value
			Return "true"
		Else
			Return "false"
		End
	End

End

Class JSONNull Extends JSONDataItem
	Field value:Object = Null 'Necessary?
	
	Method ToString:String()
		dataType = JSONDataType.JSON_NULL 
		Return "NULL"
	End
End

Class JSONArray Extends JSONDataItem
	Field values:List<JSONDataItem> = New List<JSONDataItem>
	
	Method New()
		dataType = JSONDataType.JSON_ARRAY 
	End

	Method AddItem( dataItem:JSONDataItem )
		values.AddLast(dataItem)
	End
	
	Method RemoveItem( dataItem:JSONDataItem )
		values.RemoveEach(dataItem)
	End
	
	Method ToJSONString:String()
		Local retString:String = "["
		Local first:Bool = True
		For Local v:= Eachin values
			If first
				first = False
			Else
				retString += ","
			End
			retString += v.ToJSONString()
		End
		Return retString + "]"
	End
	
	Method ToString:String()
		Local retString:String = "["
		Local first:Bool = True
		For Local v:= Eachin values
			If first
				first = False
			Else
				retString += ","
			End
			retString += v
		End
		Return retString + "]"
	End

	Method ObjectEnumerator:Object()
		Return values.ObjectEnumerator()
	End
End

Class JSONObject Extends JSONDataItem
	Field values:StringMap<JSONDataItem> = New StringMap<JSONDataItem>()
	
	Method New()
		dataType = JSONDataType.JSON_OBJECT 
	End

	Method AddItem( name:String, dataItem:JSONDataItem )
		values.Set(JSONData.ConvertJSONEscapes(name),dataItem)
	End
	
	Method RemoveItem( name:String )
		values.Remove(name)
	End
	
	Method GetItem:JSONDataItem( name:String )
		Return values.Get(name)
	End
	
	Method ToJSONString:String()
		Local retString:String = "{"
		Local first:Bool = True
		For Local v:= Eachin values
			If first
				first = False
			Else
				retString += ","
			End
			retString += "~q" + JSONData.ConvertMonkeyEscapes(v.Key.ToString()) + "~q:" + v.Value.ToJSONString()
		End
		Return retString + "}"
	End

	Method ToString:String()
		Local retString:String = "{"
		Local first:Bool = True
		For Local v:= Eachin values
			If first
				first = False
			Else
				retString += ","
			End
			retString += "~q" + v.Key + "~q:" + v.Value
		End
		Return retString + "}"
	End
End