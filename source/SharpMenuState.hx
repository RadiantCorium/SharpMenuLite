package;

import openfl.display.BitmapData;
import haxe.Json;
import haxe.Exception;
import lime.app.Application;
import sys.io.File;
import sys.FileSystem;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;

using StringTools;

class SharpMenuState extends FlxState
{
	// TO MODIFY THE OPTIONS GO TO LINE 62!!
	// WHEN COPYING THIS INTO YOUR OWN PROJECT, MAKE SURE TO COPY THE assets/data/SharpMenuConfig.json OVER ASWELL!
	// All paths in SharpMenuConfig.json are relative to the exe file!

	// don't change any of these vars!
	var optionGroups:Array<OptionGroup> = [];

	var curDisplayed:FlxTypedGroup<FlxText>;

	var curSelectedGroup:Int;
	var curSelectedOption:Int;

	var inGroup:Bool = false;
	var focusedOnRange:Bool = false;

	var descriptionText:FlxText;
	var headerText:FlxText;

	var categoryBG:FlxSprite;

	var selectorSprite:FlxSprite;

	var focusSprite1:FlxSprite;
	var focusSprite2:FlxSprite;

	var valueMap:Map<String, Dynamic>;

	var config:Config;

	function exit()
	{
		// put exit code here
		// triggered when hitting BACKSPACE or ESCAPE
	}

	override function create()
	{
		// modify this array with options
		// hover over the option types for an explenation
		optionGroups = [
			new OptionGroup("Group", [
				new RangeOption("RangeOption << %v >>", "Test of a range option", 0, 10, 1, "TEST_RO"),
				new CycleOption("CycleOption %v", "Test of a CycleOption", ["Option1", "Option2", "Option3"], "TEST_CO"),
				new FunctionOption("FunctionOption", "Test of a FunctionOption", () -> {
					trace("Hello World!");
				})
			]),
			new OptionGroup("Group 2", [
				new RangeOption("Other RangeOption << %v >>", "Test of a range option", 0, 10, 1, "TEST_ORO"),
				new CycleOption("Other CycleOption %v", "Test of a CycleOption", ["Option1", "Option2", "Option3"], "TEST_OCO"),
				new FunctionOption("Other FunctionOption", "Test of a FunctionOption", () ->
				{
					trace("Hello World!");
				})
			]),
		];

		
		// CUSTOMISATION ENDS HERE

		if (!FileSystem.exists("./assets/data/SharpMenuConfig.json"))
		{
			Application.current.window.alert("./assets/data/SharpMenuConfig.json is missing!", "Error");
			throw new Exception("./assets/data/SharpMenuConfig.json is missing!");
		}

		config = Json.parse(File.getContent("./assets/data/SharpMenuConfig.json"));

		if (config.hasBG)
		{
			var stateBG:FlxSprite = new FlxSprite().loadGraphic(BitmapData.fromFile(config.bgPath));
			stateBG.setGraphicSize(Std.int(stateBG.width * 1.1));
			stateBG.updateHitbox();
			stateBG.screenCenter();
			stateBG.antialiasing = false;
			add(stateBG);
		}
		

		var menuBG:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 0.9), Std.int(FlxG.height * 0.9), Std.parseInt(config.colorScheme.menuBG));
		menuBG.screenCenter();
		add(menuBG);

		categoryBG = new FlxSprite().makeGraphic(Std.int(FlxG.width * 0.1), Std.int(FlxG.height * 0.9), Std.parseInt(config.colorScheme.categoryBG));
		categoryBG.setPosition(menuBG.x, menuBG.y);
		add(categoryBG);

		var descriptionBG:FlxSprite = new FlxSprite().makeGraphic(Std.int(menuBG.width - categoryBG.width), Std.int(FlxG.height * 0.05),
			Std.parseInt(config.colorScheme.descriptionBG));
		descriptionBG.setPosition(categoryBG.x + categoryBG.width, menuBG.y + menuBG.height - descriptionBG.height);
		add(descriptionBG);

		descriptionText = new FlxText(0, 0, descriptionBG.width, "Please select an option to view its description.");
		descriptionText.setFormat(config.fontPath, Std.int(descriptionBG.height * 0.8), Std.parseInt(config.colorScheme.descriptionText), CENTER);
		descriptionText.setPosition(descriptionBG.x, descriptionBG.y + descriptionBG.height / 2 - descriptionText.height / 2);
		add(descriptionText);

		headerText = new FlxText(0, 0, descriptionBG.width, "Header text.");
		headerText.setFormat(config.fontPath, Std.int(descriptionBG.height * 0.8), Std.parseInt(config.colorScheme.headerText), CENTER);
		headerText.setPosition(descriptionBG.x, menuBG.y);
		add(headerText);

		for (i in 0...optionGroups.length)
		{
			var btnBg:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 0.1), Std.int(FlxG.height * 0.05), Std.parseInt(config.colorScheme.categoryButtonBG));
			btnBg.x = menuBG.x;
			btnBg.y = menuBG.y + (i * Std.int(FlxG.height * 0.05)) + i * 2;
			add(btnBg);

			var btnTxt:FlxText = new FlxText(0, 0, btnBg.width, optionGroups[i].name);
			btnTxt.setFormat(config.fontPath, 12, Std.parseInt(config.colorScheme.categoryButtonText), CENTER);
			btnTxt.x = btnBg.x;
			btnTxt.y = btnBg.y + btnBg.height / 2 - btnTxt.height / 2;
			add(btnTxt);
		}

		if (FlxG.save.data.optionValueMap != null)
			valueMap = FlxG.save.data.optionValueMap;
		else
			valueMap = new Map<String, Dynamic>();

		curDisplayed = new FlxTypedGroup<FlxText>();
		updateMenu();
		add(curDisplayed);

		headerText.text = optionGroups[0].name;

		selectorSprite = new FlxSprite(0, 0);
		selectorSprite.makeGraphic(Std.int(FlxG.width * 0.1), Std.int(FlxG.height * 0.05), Std.parseInt(config.colorScheme.categoryButtonSelector));
		selectorSprite.setPosition(menuBG.x, menuBG.y);
		add(selectorSprite);

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.save.data.UP == null)
			FlxG.save.data.UP = "W";
		if (FlxG.save.data.DOWN == null)
			FlxG.save.data.DOWN = "S";
		if (FlxG.save.data.LEFT == null)
			FlxG.save.data.LEFT = "A";
		if (FlxG.save.data.RIGHT == null)
			FlxG.save.data.RIGHT = "D";

		selectorSprite.y = categoryBG.y + (curSelectedGroup * Std.int(FlxG.height * 0.05)) + curSelectedGroup * 2;

		if (inGroup)
		{
			for (item in curDisplayed)
			{
				item.alpha = 1;
			}
		}
		else
		{
			for (item in curDisplayed)
			{
				item.alpha = 0.5;
			}
		}

		if (FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.ESCAPE)
		{
			exit();
		}

		if (FlxG.keys.justPressed.RIGHT)
		{
			if (!focusedOnRange)
			{
				inGroup = true;
				descriptionText.text = optionGroups[curSelectedGroup].options[curSelectedOption].description;
			}
			else
			{
				if (valueMap[(optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo]
					+ (optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption)
						.stepSize <= (optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).max)
				{
					valueMap.set((optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo,
						valueMap[(optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo] +
						(optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).stepSize);
					updateMenu();
				}
				else
				{
					valueMap.set((optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo,
						(optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).max);
					updateMenu();
				}
			}
		}
		if (FlxG.keys.justPressed.LEFT)
		{
			if (!focusedOnRange)
			{
				inGroup = false;
				descriptionText.text = "Please select an option to view its description.";
			}
			else
			{
				if (valueMap[(optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo]
					- (optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption)
						.stepSize >= (optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).min)
				{
					valueMap.set((optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo,
						valueMap[(optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption)
							.saveTo] - (optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).stepSize);
					updateMenu();
				}
				else
				{
					valueMap.set((optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo,
						(optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).min);
					updateMenu();
				}
			}
		}
		if (FlxG.keys.justPressed.UP && !focusedOnRange)
		{
			if (!inGroup)
			{
				if (curSelectedGroup > 0)
				{
					curSelectedGroup--;
					updateMenu();
					curSelectedOption = 0;
				}
				else
				{
					curSelectedGroup = optionGroups.length - 1;
					updateMenu();
					curSelectedOption = 0;
				}
			}
			else
			{
				if (curSelectedOption > 0)
				{
					curSelectedOption--;
					updateMenu();
				}
				else
				{
					curSelectedOption = optionGroups[curSelectedGroup].options.length - 1;
					updateMenu();
				}
			}
		}

		if (FlxG.keys.justPressed.DOWN && !focusedOnRange)
		{
			if (!inGroup)
			{
				if (curSelectedGroup < optionGroups.length - 1)
				{
					curSelectedGroup++;
					updateMenu();
					curSelectedOption = 0;
				}
				else
				{
					curSelectedGroup = 0;
					updateMenu();
					curSelectedOption = 0;
				}
			}
			else
			{
				if (curSelectedOption < optionGroups[curSelectedGroup].options.length - 1)
				{
					curSelectedOption++;
					updateMenu();
				}
				else
				{
					curSelectedOption = 0;
					updateMenu();
				}
			}
		}

		if (FlxG.keys.justPressed.ENTER && inGroup)
		{
			if (Std.isOfType(optionGroups[curSelectedGroup].options[curSelectedOption], CycleOption))
			{
				// bro what even is this code
				(optionGroups[curSelectedGroup].options[curSelectedOption] : CycleOption)
					.curValue = valueMap[(optionGroups[curSelectedGroup].options[curSelectedOption] : CycleOption).saveTo];
				if ((optionGroups[curSelectedGroup].options[curSelectedOption] : CycleOption)
					.curValue > (optionGroups[curSelectedGroup].options[curSelectedOption] : CycleOption).possibleValues.length - 2)
					(optionGroups[curSelectedGroup].options[curSelectedOption] : CycleOption).curValue = 0;
				else
					(optionGroups[curSelectedGroup].options[curSelectedOption] : CycleOption).curValue++;

				valueMap.set(optionGroups[curSelectedGroup].options[curSelectedOption].saveTo,
					(optionGroups[curSelectedGroup].options[curSelectedOption] : CycleOption).curValue);

				updateMenu();
			}
			else if (Std.isOfType(optionGroups[curSelectedGroup].options[curSelectedOption], RangeOption))
			{
				if (!focusedOnRange)
				{
					descriptionText.text = "Focused on option. Press ENTER again to apply.";
				}
				else
				{
					descriptionText.text = optionGroups[curSelectedGroup].options[curSelectedOption].description;
				}
				focusedOnRange = !focusedOnRange;
			}
			else if (Std.isOfType(optionGroups[curSelectedGroup].options[curSelectedOption], FunctionOption))
			{
				(optionGroups[curSelectedGroup].options[curSelectedOption] : FunctionOption).func();
			}
		}

		super.update(elapsed);
	}

	function updateMenu()
	{
		// not copied from sublim engine, at all.
		// updateFPS();

		if (optionGroups[curSelectedGroup] != null)
			headerText.text = optionGroups[curSelectedGroup].name;

		if (inGroup && !focusedOnRange)
			descriptionText.text = optionGroups[curSelectedGroup].options[curSelectedOption].description;
		else if (focusedOnRange)
			descriptionText.text = "Focused on option. Press ENTER again to apply.";
		else
			descriptionText.text = "Please select an option to view its description.";

		// idk how shit this math is, copilot made it. but it works :)
		if (selectorSprite != null)
			selectorSprite.y = categoryBG.y + (curSelectedGroup * Std.int(FlxG.height * 0.05)) + curSelectedGroup * 2;

		for (item in curDisplayed)
		{
			remove(item); // remove all the old ones
		}

		curDisplayed.clear();
		if (optionGroups[curSelectedGroup] != null)
		{
			for (i in 0...optionGroups[curSelectedGroup].options.length)
			{
				var value:Any = "";
				var text:FlxText = new FlxText(0, 0, FlxG.width, optionGroups[curSelectedGroup].options[i].label);
				text.setFormat(config.fontPath, config.optionFontSize, Std.parseInt(config.colorScheme.optionText), LEFT);
				text.x = categoryBG.x + categoryBG.width + 10;
				text.y = categoryBG.y + (i * text.height) + i * 4 + headerText.height;
				value = getOptionValue(optionGroups[curSelectedGroup].options[i], optionGroups[curSelectedGroup].options[i].saveTo,
					Std.isOfType(optionGroups[curSelectedGroup].options[i], CycleOption));
				text.text = text.text.replace("%v", Std.string(value));
				add(text);
				trace("Option");
				curDisplayed.add(text);
			}
		}
		if (curDisplayed.members[curSelectedOption] != null)
			curDisplayed.members[curSelectedOption].text += " <<";
		else
		{
			// if we fucked up, fix it and try again
			curSelectedOption = 0;
			updateMenu();
		}
	}

	function getOptionValue(option:Any, name:String, isCycle:Bool):Any
	{
		if (valueMap == null)
			return null;

		trace('getOptionValue: ${name}, ISCYCLE: ${isCycle}');

		if (isCycle)
		{
			try
			{
				if (valueMap[name] == null)
					valueMap[name] = 0;

				return (option : CycleOption).possibleValues[valueMap[name]];
			}
			catch (e)
			{
				trace('${(option : CycleOption) == null}');
				return 0;
			}
		}
		else
		{
			if (valueMap[name] == null && Std.isOfType(option, RangeOption))
				valueMap[name] = (option : RangeOption).min;

			return valueMap[name];
		}
	}
}

/**
 * An option type that cycles through a list of options. Used for things like true/false, on/off, etc.
 * @param label The text displayed in the options menu. Use `%v` to display the value; `%v` will be replaced with the current value.
 * @param description The description of the option.
 * @param defaultIndex The index of the default value in the array.
 * @param possibleValues An array of values to cycle through.
 * @param saveTo the name of the variable in the save file to save to.
 */
class CycleOption
{
	public var label:String;
	public var defaultIndex:Int;
	public var possibleValues:Array<Dynamic>;
	public var description:String;
	public var curValue:Int;
	public var saveTo:String;

	public function new(label:String, description:String, possibleValues:Array<Dynamic>, saveTo:String)
	{
		this.label = label;
		this.possibleValues = possibleValues;
		this.description = description;
		this.curValue = defaultIndex;
		this.saveTo = saveTo;
	}
}

/**
 * An option type that allows the user to pick a value between a min and max.
 * @param label The text displayed in the options menu. Use `%v` to display the value; `%v` will be replaced with the current value.
 * @param description The description of the option.
 * @param defaultValue The default value.
 * @param min The minimum value.
 * @param max The maximum value.
 * @param stepSize the size between steps
 * @param saveTo the name of the variable in the save file to save to.
 */
class RangeOption
{
	public var label:String;
	public var defaultValue:Float;
	public var min:Float;
	public var max:Float;
	public var description:String;
	public var curValue:Float;
	public var stepSize:Float;
	public var saveTo:String;

	public function new(label:String, description:String, min:Float, max:Float, stepSize:Float, saveTo:String)
	{
		this.label = label;
		this.min = min;
		this.max = max;
		this.description = description;
		this.curValue = defaultValue;
		this.stepSize = stepSize;
		this.saveTo = saveTo;
	}
}

/**
 * An option type that calls a function when interacted with.
 * @param label The text displayed in the options menu.
 * @param description The description of the option.
 * @param func The function to call.
 */
class FunctionOption
{
	public var label:String;
	public var description:String;
	public var func:Void->Void;

	public function new(label:String, description:String, func:Void->Void)
	{
		this.label = label;
		this.description = description;
		this.func = func;
	}
}

/**
 * OptionGroup is a container for a set of options. Otherwise known as a "page" in the options menu.
 * @param name The text displayed in the options menu.
 * @param options An array of options to display.
 */
class OptionGroup
{
	public var name:String;
	public var options:Array<Dynamic>;

	public function new(name:String, options:Array<Dynamic>)
	{
		this.name = name;
		this.options = options;
	}
}


// JSON SHIT
typedef Config =
{
	hasBG:Bool,
	bgPath:String,
	fontPath:String,
	optionFontSize:Int,
	colorScheme:ColorScheme
}

typedef ColorScheme =
{
	menuBG:String,
	headerText:String,
	categoryBG:String,
	categoryButtonBG:String,
	categoryButtonText:String,
	categoryButtonSelector:String,
	descriptionBG:String,
	descriptionText:String,
	optionText:String
}