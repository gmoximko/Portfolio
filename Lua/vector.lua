--[[
		Класс вектор. Удобный класс, чтобы избавиться от кучи писанины с координатами вида x, y.
		
		Используем так:
			1) Сперва подключаем файл в ваш скрипт            local Vector = require("vector") --движок сам знает где искать этот файл и ничего более никуда писать не нужно.
			2) Затем можно создавать экземпляры, например так local MousePos = Vector(_experience_engine:get_cursor_position(scene)) или так local vector = Vector() -- vector.x == 0 and vector.y == 0.
			3) В конструктор можно передать либо два числа, либо две строки вида "10", "20", либо строку вида "10 20", либо два вектора lVector, rVector, либо не передавать ничего.
		
		Перегруженные операторы:
			(==)               --Сравнение векторов.
			(+)                --Сумма векторов.
			(-)                --Разность векторов.
			(..)               --Конкатенация со строкой, либо если применяется к двум векторам, то вычисляет расстояние между ними.
			(*)                --Умножение на число.
			(/)                --Деление на число.
			(tostring(vector)) --Приведение типа к строке.
			(-vector)          --Унарный минус.
		
		Методы:
			Module     = function (this)        --Длина вектора.
			Normalize  = function (this)        --Нормализованный вектор.
			Ort        = function (this)        --Перпендикуляр вектора.
			Get        = function (this)        --Вовращает x, y.
			Turn       = function (this, angle) --Повернуть вектор.
			Distance   = function (this, other) --Расстояние между векторами.
			DotProduct = function (this, other) --Скалярное произведение.
			GetAngle   = function (this, other) --Угол между векторами.
			Set        = function (this, x, y)  --Задать новые x, y, чтобы не создавать новый вектор.
]]

local global = _G

module("vector")

local print        = global.print
local setmetatable = global.setmetatable
local tostring     = global.tostring
local tonumber     = global.tonumber
local type         = global.type
local assert       = global.assert
--Для релиза
local debug  = global.debug or { traceback = function () return "RELEASE" end }
local math   = global.math
local string = global.string

local Vector = {}

setmetatable(_M, { __call = function (m, x, y) return Vector:New(x, y) end })

function Vector.New(class, x, y) --Конструктор, вызываем так vector = Vector(10, 20), либо Vector("10", "20"), либо Vector("10 20"), либо передаём две точки Vector(lVector, rVector), либо Vector().
	local this = setmetatable({}, class)
	class.__index = class
	
	class.__eq = function (this, other) --Сравнение векторов (==)
		if (type(this) ~= "table" or type(other) ~= "table") then return false end
		
		return this.x == other.x and this.y == other.y 
	end
	
	class.__add = function (this, other) --Сумма векторов (+)
		return Vector:New(this.x + other.x, this.y + other.y)
	end
	
	class.__sub = function (this, other) --Разность векторов (-)
		return Vector:New(this.x - other.x, this.y - other.y)
	end
	
	class.__concat = function (this, other) --Конкатенация со строкой, либо если применяется к двум векторам, то вычисляет расстояние между ними (..)
		if type(this)  == "string" then return this .. tostring(other) end
		if type(other) == "string" then return tostring(this) .. other end
		
		return math.sqrt((other.x - this.x) ^ 2 + (other.y - this.y) ^ 2)
	end
	
	class.__mul = function (this, number) --Умножение на число (*)
		assert(type(number) == "number", "BAD ARGUMENT IN MULTIPLICATION OPERATOR (*): " .. tostring(number) .. "! SHOULD BE A NUMBER! " .. debug.traceback())
		return Vector:New(this.x * number, this.y * number)
	end
	
	class.__div = function (this, number) --Деление на число (/)
		assert(type(number) == "number", "BAD ARGUMENT IN DIVISION OPERATOR (/): " .. tostring(number) .. "! SHOULD BE A NUMBER! " .. debug.traceback())
		assert(     number ~= 0,         "BAD ARGUMENT IN DIVISION OPERATOR (/): " .. tostring(number) .. "! CAN NOT BE ZERO! " .. debug.traceback())
		return Vector:New(this.x / number, this.y / number)
	end
	
	class.__tostring = function (this) --Приведение типа к строке (tostring(vector))
		return this.x .. " " .. this.y
	end
	
	class.__unm = function (this) --Унарный минус (-vector)
		return Vector:New(-this.x, -this.y)
	end
	
	class.Module = function (this) --Длина вектора.
		return (this.x ^ 2 + this.y ^ 2) ^ 0.5
	end
	
	class.Normalize = function (this) --Нормализованный вектор.
		local divider = this:Module()
		
		return this / (divider == 0 and 1 or divider)
	end
	
	class.Distance = function (this, other) --Расстояние между векторами.
		return this .. other
	end
	
	class.Turn = function (this, angle) --Повернуть вектор.
		angle = math.rad(angle)
		
		local turnX = this.x * math.cos(angle) - this.y * math.sin(angle)
		local turnY = this.x * math.sin(angle) - this.y * math.cos(angle)
		
		return Vector:New(turnX, turnY)
	end
	
	class.Ort = function (this) --Перпендикуляр вектора.
		return this:Turn(90):Normalize()
	end
	
	class.DotProduct = function (this, other) --Скалярное произведение.
		return this.x * other.x + this.y * other.y
	end
	
	class.GetAngle = function (this, other) --Угол между векторами.
		local product    = this:Module() * other:Module()
		local dotProduct = this:DotProduct(other)
		
		return math.deg(math.acos(dotProduct / product))
	end
	
	class.Get = function (this) --Возвращает x, y.
		return this.x, this.y
	end
	
	class.Set = function (this, x, y) --Задать x, y (10, 20), либо ("10", "20"), либо ("10 20"), либо (lVector, rVector), либо (vector).
		--На случай, если передаём два вектора.
		if (type(x) == "table" and type(y) == "table") then
			if (x.x and x.y and y.x and y.y) then
				local tempX = y.x - x.x
				local tempY = y.y - x.y
				x = tempX
				y = tempY
			end
		elseif (type(x) == "string" and y == nil) then
			local str   = x
			local space = string.find(str, " ")
			
			x = string.sub(str, 1, space - 1)
			y = string.sub(str, space + 1, #str)
		elseif (type(x) == "table" and y == nil) then
			local temp = x
			x = temp.x
			y = temp.y
		end
		
		--В векторе всего два поля
		this.x = (type(x) == "string" and tonumber(x) or x) 
		this.y = (type(y) == "string" and tonumber(y) or y)
		
		--Проверка, что обе координаты- числа
		assert(type(this.x) == "number" and type(this.y) == "number", 
		"PARAMETERS IN Vector (Vector:New / :Set) SHOULD BE A TWO DIGITS (10, 20) OR TWO DIGITS AS STRING (\"10\", \"20\") OR STRING WITH TWO DIGITS (\"10 20\") OR TWO Vectors (lVector, rVector)! OR ONE Vector (vector)! " .. debug.traceback())
	end
	
	if (x == nil and y == nil) then x = 0; y = 0 end
	
	this:Set(x, y)
	
	return this
end

function Vector.GetInfo()
	local description = [[
		Google translate:
		Grade Vector. Convenience class to get rid of the heaps of scribbling with the coordinates of the form x, y.
		
		The constructor can be before 
		or two numbers, 
		or two strings like "10", "20", 
		or a string like "10 20" 
		or two Vectors lVector, rVector.
	]]
	
	local example = [[
		Vector.New (class, x, y) --Constructor, so call 
		vector =       Vector: New (10, 20) 
		or             Vector: New ("10", "20") 
		or             Vector: New ("10 20" ) 
		or two Vectors Vector: New (lVector, rVector).
	]]
	
	local operators = [[
		Overloaded operators:
			(==)                --Compare Vectors.
			(+)                 --Sum of Vectors.
			(-)                 --Difference Vectors.
			(..)                --With string concatenation, or when applied to two Vectors, then calculates the distance between them.
			(*)                 --Multiply the number.
			(/)                 --Divided by the number.
			(tostring (vector)) --Typecast to a string.
			(-vector)           --Unary minus.
	]]
	
	local methods = [[
		Methods:
			Module     = function (this)        --The length of the vector.
			Normalize  = function (this)        --A normalized vector.
			Ort        = function (this)        --The perpendicular vector.
			Get        = function (this)        --Returns x, y.
			Turn       = function (this, angle) --Rotate the vector.
			Distance   = function (this, other) --The distance between the Vectors.
			DotProduct = function (this, other) --The scalar product.
			GetAngle   = function (this, other) --The angle between the vectors.
			Set        = function (this, x, y)  --Set new x, y.
	]]
	
	print(description)
	print(example)
	print(operators)
	print(methods)
end
