Class JSONToken
	Const TOKEN_UNKNOWN:Int = -1
	Const TOKEN_COMMA:Int = 0
	Const TOKEN_OPEN_CURLY:Int = 1
	Const TOKEN_CLOSE_CURLY:Int = 2
	Const TOKEN_OPEN_SQUARE:Int = 3
	Const TOKEN_CLOSE_SQUARE:Int = 4
	Const TOKEN_COLON:Int = 6
	Const TOKEN_TRUE:Int = 7
	Const TOKEN_FALSE:Int = 8
	Const TOKEN_NULL:Int = 9
	Const TOKEN_STRING:Int = 10
	Const TOKEN_FLOAT:Int = 11
	Const TOKEN_INTEGER:Int = 11

	Field tokenType:Int
	Field value:Object

	Private

	Method New( tokenType:Int, value:Object )
		Self.tokenType = tokenType
		Self.value = value
	End

	Method ToString:String()
		Return "JSONToken - type: " + tokenType + ", value: " + GetValueString() 
	End

	Method GetValueString:String()
		Select tokenType 
			Case TOKEN_FLOAT
				Return "" + FloatObject(value)
			Case TOKEN_INTEGER
				Return "" + IntObject(value)
			Case TOKEN_NULL
				Return "NULL"
			Default
				Return StringObject(value) 
		End	
	End

	Global reusableToken:JSONToken = New JSONToken(-1,Null)
	Public

	Function CreateToken:JSONToken( tokenType:Int, value:Float )
		reusableToken.tokenType = tokenType
		reusableToken.value = New FloatObject(value)
		Return reusableToken
	End
	
	Function CreateToken:JSONToken( tokenType:Int, value:Int )
		reusableToken.tokenType = tokenType
		reusableToken.value = New IntObject(value)
		Return reusableToken
	End
	
	Function CreateToken:JSONToken( tokenType:Int, value:String )
		reusableToken.tokenType = tokenType
		reusableToken.value = New StringObject(value)
		Return reusableToken
	End
	
	Function CreateToken:JSONToken( tokenType:Int, value:Object )
		reusableToken.tokenType = tokenType
		reusableToken.value = value
		Return reusableToken
	End
End

Class JSONTokeniser

	Private

	Field jsonString:String = ""
	Field stringIndex:Int = 0
	Field char:Int = 0
	Field charStr:String = ""
	Field silent:Bool = False

	Public

	Method New( jsonString:String, silent:Bool = False )
		Self.silent = silent
		Self.jsonString = jsonString
		NextChar()
	End

	Method GetCurrentSectionString:String(backwards:Int = 20,forwards:Int = 20)
		Return "Section: " + jsonString[Max(stringIndex-backwards,0)..Min(stringIndex+forwards,jsonString.Length-1)]
	End

	Method NextToken:JSONToken()
		Local retToken:JSONToken
		SkipIgnored()

		Select charStr

			Case "{"
				retToken = JSONToken.CreateToken(JSONToken.TOKEN_OPEN_CURLY,charStr)
			Case "}"
				retToken = JSONToken.CreateToken(JSONToken.TOKEN_CLOSE_CURLY,charStr)
			Case "["
				retToken = JSONToken.CreateToken(JSONToken.TOKEN_OPEN_SQUARE,charStr)
			Case "]"
				retToken = JSONToken.CreateToken(JSONToken.TOKEN_CLOSE_SQUARE,charStr)
			Case ","
				retToken = JSONToken.CreateToken(JSONToken.TOKEN_COMMA,charStr)
			Case ":"
				retToken = JSONToken.CreateToken(JSONToken.TOKEN_COLON,charStr)
			Case "t"
				If jsonString[stringIndex..stringIndex+2] = "rue"
					stringIndex += 2
					retToken = JSONToken.CreateToken(JSONToken.TOKEN_TRUE,"true")
				End
			Case "f"
				If jsonString[stringIndex..stringIndex+3] = "alse"
					stringIndex += 3
					retToken = JSONToken.CreateToken(JSONToken.TOKEN_FALSE,"false")
				End
			Case "n"
				If jsonString[stringIndex..stringIndex+2] = "ull"
					stringIndex += 2
					retToken = JSONToken.CreateToken(JSONToken.TOKEN_NULL,"null")
				End
			Case "~q"
				Local startIndex:Int = stringIndex
				Repeat
					Local endIndex:Int = jsonString.Find("~q",stringIndex)
					If endIndex = -1
						ParseFailure("Unterminated string")
						Exit
					End
					If jsonString[endIndex-1] <> 92
						retToken = JSONToken.CreateToken(JSONToken.TOKEN_STRING,jsonString[startIndex..endIndex])
						stringIndex = endIndex+1
						Exit
					End
					stringIndex = endIndex+1
						
				Forever
			Default
				'Is it a Number?
				If charStr = "-" Or IsDigit(char)
					Return ParseNumberToken(charStr)
				Else If charStr = ""
					Return Null 'End of string so just leave'
				End
								
		End
		If Not retToken
			ParseFailure("Unknown token")
			retToken = JSONToken.CreateToken(JSONToken.TOKEN_UNKNOWN,Null)
		Else
			NextChar()
		End
		Return retToken

	End

	Private
	
	Method NextChar:String()
		If stringIndex = jsonString.Length
			Return ""
		End
		char = jsonString[stringIndex]
		charStr = String.FromChar(char)
		stringIndex += 1
		return charStr
	End

	Method ParseNumberToken:JSONToken(firstChar:String)
		Local index:Int = stringIndex-1
		'First just get the full string
		While charStr <> " " And charStr <> "," And charStr <> "}" And charStr <> "]"
			NextChar()
		End
		If charStr = ""
			ParseFailure("Unterminated Number")
			Return JSONToken.CreateToken(JSONToken.TOKEN_UNKNOWN,Null)
		End

		Local numberString:String = jsonString[index..stringIndex-1].ToLower()
		Local exponent:String
		index = numberString.Find("e")
		If index <> -1
			exponent = numberString[index+1..]
			numberString = numberString[..index]
		End
		If exponent Or numberString.Find(".") <> -1
			Local value:Float = ParseFloat(numberString)
			If exponent
				value *= Pow(10,ParseFloat(exponent))
			End
			Return JSONToken.CreateToken(JSONToken.TOKEN_FLOAT,value)
		Else
			Local value:Int = ParseInteger(numberString)
			Return JSONToken.CreateToken(JSONToken.TOKEN_INTEGER,value)
		End 
	End

	'No error trapping or anything like that
	'A monkey wrapper for the native standard libraries for this stuff would be nice
	Method ParseInteger:Int(str:String)
		Local neg:Bool = False
		Local result:Int = 0
		Local index:Int = 0

		If str[0] = 45 ' - char
			neg = True
			index = 1
		End
		For index = index Until str.Length
			result *= 10
			result += (str[index]-48)
		End
		If neg
			Return -result
		Else
			Return result
		End
	End

	'No error trapping or anything like that
	'A monkey wrapper for the native standard libraries for this stuff would be nice
	Method ParseFloat:Float(str:String)
		Local neg:Bool = False
		Local index:Int = 0
		Local result:Float = 0.0
		
		If str[0] = 45 ' - char
			neg = True
			index = 1
		End
		Local decimal:Float = 0.0
		For index = index Until str.Length
			If str[index] = 46 ' . char
				decimal = 0.1
				Continue
			End
			If decimal > 0.0
				result += (str[index]-48)*decimal
				decimal *= 0.1
			Else
				result *= 10
				result += (str[index]-48)
			End
		End
		If neg
			Return -result
		Else
			Return result
		End	
	End

	Method IsDigit:Bool(char:Int)
		Return( char >= 48 And char <= 58 )
	End

	Method SkipIgnored()
		Local ignoredCount:Int
		Repeat
			ignoredCount = 0
			ignoredCount += SkipWhitespace()
			ignoredCount += SkipComments()
		Until ignoredCount = 0
	End

	Method SkipWhitespace()
		Local index:Int = stringIndex
		While charStr = "~t" Or charStr = " " Or charStr = "~n" Or charStr = "~r"
			NextChar()
		End
		Return stringIndex-index
	End

	Method SkipComments()
		Local index:Int = stringIndex
		If charStr = "/"
			NextChar()
			If charStr = "/"
				While charStr <> "~n" And charStr <> ""
					NextChar()
				End
				'While char = "~n" Or char = "~r"
				''	NextChar()
				'End
			ElseIf charStr = "*"
				Repeat
					If NextChar() = "*"
						If NextChar() = "/"
							Exit
						End
					End
					If char = ""
						ParseFailure("Unterminated comment")
						Exit
					End
				Forever
			Else
				ParseFailure("Unrecognised comment opening")
			End
			NextChar()
		End
		Return stringIndex-index
	End

	Method ParseFailure(description:String)
		If silent
			Return
		End
		Print "JSON parse error at index: " + stringIndex
		Print description
		Print GetCurrentSectionString()
		stringIndex = jsonString.Length
	End
End