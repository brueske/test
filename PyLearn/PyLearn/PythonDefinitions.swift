import Foundation

/// A human-readable explanation of a Python term, shown in the upper-right box.
struct Definition: Equatable {
    let term: String
    let category: String
    let summary: String
    let example: String
}

/// Offline dictionary of Python term definitions (no network required).
///
/// The online setting (see `AppSettings`) is wired through
/// `DefinitionProvider`, which falls back to this dictionary when an online
/// source is disabled or unreachable.
enum PythonDefinitions {

    static func lookup(_ key: String, displayText: String) -> Definition {
        if let d = table[key] { return d }
        return fallback(for: key, displayText: displayText)
    }

    private static func fallback(for key: String, displayText: String) -> Definition {
        switch key {
        case "__number__":
            return Definition(term: displayText, category: "Numeric literal",
                summary: "A number value. Whole numbers are integers (int); numbers with a decimal point are floats.",
                example: "count = 42\npi = 3.14")
        case "__string__":
            return Definition(term: displayText, category: "String literal",
                summary: "Text wrapped in quotes. Prefix with f for an f-string to insert values with {}.",
                example: "name = \"Ada\"\ngreeting = f\"Hi {name}\"")
        case "__comment__":
            return Definition(term: displayText, category: "Comment",
                summary: "Anything after # on a line is ignored by Python. Use comments to explain your code.",
                example: "# add the two numbers\ntotal = a + b")
        case "__call__":
            return Definition(term: displayText, category: "Function call",
                summary: "Runs a function with the arguments inside the parentheses and produces a result.",
                example: "result = my_function(1, 2)")
        case "__attribute__":
            return Definition(term: displayText, category: "Attribute access",
                summary: "Uses a dot to reach a value or function that belongs to an object or module.",
                example: "import math\narea = math.pi * r ** 2")
        case "__identifier__":
            return Definition(term: displayText, category: "Name / variable",
                summary: "A name you choose to label a value. Assign with = and reuse the name later.",
                example: "score = 10\nscore = score + 5")
        default:
            return Definition(term: displayText, category: "Python token",
                summary: "Part of the Python syntax. Select neighboring terms and use Analyze to ask the model about it in context.",
                example: displayText)
        }
    }

    // MARK: - The dictionary

    private static func d(_ term: String, _ cat: String, _ sum: String, _ ex: String) -> Definition {
        Definition(term: term, category: cat, summary: sum, example: ex)
    }

    static let table: [String: Definition] = [
        // Keywords
        "def": d("def", "Keyword — function", "Defines a reusable function. The body is indented underneath.", "def square(n):\n    return n * n"),
        "return": d("return", "Keyword — function", "Sends a value back from a function and ends it.", "def add(a, b):\n    return a + b"),
        "lambda": d("lambda", "Keyword — function", "Creates a tiny anonymous (unnamed) function in one line.", "double = lambda x: x * 2"),
        "class": d("class", "Keyword — class", "Defines a blueprint for objects that bundle data and behavior.", "class Dog:\n    def bark(self):\n        print(\"Woof\")"),
        "if": d("if", "Keyword — control flow", "Runs the indented block only when the condition is True.", "if score > 90:\n    print(\"A\")"),
        "elif": d("elif", "Keyword — control flow", "\"Else if\": checks another condition when the previous if was False.", "if x > 0:\n    print(\"pos\")\nelif x == 0:\n    print(\"zero\")"),
        "else": d("else", "Keyword — control flow", "Runs when none of the preceding if/elif conditions were True.", "if ok:\n    go()\nelse:\n    stop()"),
        "for": d("for", "Keyword — loop", "Repeats a block once for each item in a sequence.", "for item in [1, 2, 3]:\n    print(item)"),
        "while": d("while", "Keyword — loop", "Repeats a block as long as a condition stays True.", "n = 3\nwhile n > 0:\n    n = n - 1"),
        "in": d("in", "Keyword / operator", "Iterates over items in a for loop, or tests membership.", "if \"a\" in \"cat\":\n    print(\"found\")"),
        "break": d("break", "Keyword — loop", "Immediately exits the nearest enclosing loop.", "for n in range(10):\n    if n == 5:\n        break"),
        "continue": d("continue", "Keyword — loop", "Skips to the next iteration of the loop.", "for n in range(5):\n    if n % 2 == 0:\n        continue\n    print(n)"),
        "pass": d("pass", "Keyword", "A placeholder that does nothing — useful where code is required but not ready.", "def todo():\n    pass"),
        "import": d("import", "Keyword — modules", "Loads another module so you can use its functions.", "import math\nprint(math.sqrt(9))"),
        "from": d("from", "Keyword — modules", "Imports specific names directly from a module.", "from math import pi"),
        "as": d("as", "Keyword", "Gives an imported module or context manager a shorter alias.", "import numpy as np"),
        "with": d("with", "Keyword — context", "Manages a resource and cleans it up automatically when done.", "with open(\"f.txt\") as file:\n    data = file.read()"),
        "try": d("try", "Keyword — errors", "Wraps code that might raise an error so you can handle it.", "try:\n    risky()\nexcept ValueError:\n    print(\"bad value\")"),
        "except": d("except", "Keyword — errors", "Catches and handles an error raised inside a try block.", "try:\n    int(\"x\")\nexcept ValueError:\n    print(\"not a number\")"),
        "finally": d("finally", "Keyword — errors", "Runs cleanup code whether or not an error happened.", "try:\n    work()\nfinally:\n    cleanup()"),
        "raise": d("raise", "Keyword — errors", "Triggers an error on purpose.", "if n < 0:\n    raise ValueError(\"negative\")"),
        "assert": d("assert", "Keyword", "Checks that a condition is True; raises an error if not.", "assert total == 100"),
        "and": d("and", "Boolean operator", "True only when both sides are True.", "if hungry and have_food:\n    eat()"),
        "or": d("or", "Boolean operator", "True when at least one side is True.", "if tired or bored:\n    rest()"),
        "not": d("not", "Boolean operator", "Flips a truth value: not True is False.", "if not done:\n    keep_going()"),
        "is": d("is", "Identity operator", "Tests whether two names point to the exact same object.", "if x is None:\n    x = []"),
        "None": d("None", "Constant", "Represents \"no value\" or \"nothing here yet\".", "result = None"),
        "True": d("True", "Boolean constant", "The boolean value for yes/on.", "is_ready = True"),
        "False": d("False", "Boolean constant", "The boolean value for no/off.", "is_ready = False"),
        "global": d("global", "Keyword — scope", "Lets a function reassign a variable defined at module level.", "count = 0\ndef bump():\n    global count\n    count += 1"),
        "nonlocal": d("nonlocal", "Keyword — scope", "Lets a nested function reassign a variable from the enclosing function.", "def outer():\n    x = 1\n    def inner():\n        nonlocal x\n        x = 2"),
        "yield": d("yield", "Keyword — generators", "Produces a value from a generator and pauses until the next request.", "def counter():\n    yield 1\n    yield 2"),
        "del": d("del", "Keyword", "Removes a name, list item, or dictionary entry.", "del my_list[0]"),
        "async": d("async", "Keyword — async", "Marks a function as asynchronous so it can use await.", "async def fetch():\n    ..."),
        "await": d("await", "Keyword — async", "Waits for an async operation to finish inside an async function.", "data = await fetch()"),

        // Builtins
        "print": d("print", "Built-in function", "Displays values to the screen (standard output).", "print(\"Hello\", 42)"),
        "len": d("len", "Built-in function", "Returns how many items are in a sequence or collection.", "len(\"cat\")  # 3"),
        "range": d("range", "Built-in function", "Produces a sequence of numbers, often used to count in for loops.", "for i in range(3):\n    print(i)  # 0 1 2"),
        "int": d("int", "Built-in type", "Converts a value to a whole number (integer).", "int(\"42\")  # 42"),
        "float": d("float", "Built-in type", "Converts a value to a decimal number (float).", "float(\"3.14\")  # 3.14"),
        "str": d("str", "Built-in type", "Converts a value to a text string.", "str(42)  # \"42\""),
        "bool": d("bool", "Built-in type", "Converts a value to True or False.", "bool(0)  # False"),
        "list": d("list", "Built-in type", "Creates a list — an ordered, changeable collection.", "list(range(3))  # [0, 1, 2]"),
        "dict": d("dict", "Built-in type", "Creates a dictionary — a set of key → value pairs.", "dict(a=1, b=2)"),
        "set": d("set", "Built-in type", "Creates a set — an unordered collection of unique items.", "set([1, 1, 2])  # {1, 2}"),
        "tuple": d("tuple", "Built-in type", "Creates a tuple — an ordered, unchangeable collection.", "tuple([1, 2])  # (1, 2)"),
        "input": d("input", "Built-in function", "Reads a line of text typed by the user.", "name = input(\"Name? \")"),
        "type": d("type", "Built-in function", "Tells you the type (class) of a value.", "type(3)  # <class 'int'>"),
        "open": d("open", "Built-in function", "Opens a file for reading or writing.", "with open(\"f.txt\") as f:\n    text = f.read()"),
        "enumerate": d("enumerate", "Built-in function", "Loops over items together with their index numbers.", "for i, ch in enumerate(\"ab\"):\n    print(i, ch)"),
        "zip": d("zip", "Built-in function", "Pairs up items from several sequences position by position.", "for a, b in zip([1, 2], [\"x\", \"y\"]):\n    print(a, b)"),
        "map": d("map", "Built-in function", "Applies a function to every item in a sequence.", "list(map(str, [1, 2]))  # ['1', '2']"),
        "filter": d("filter", "Built-in function", "Keeps only the items for which a function returns True.", "list(filter(lambda n: n > 0, [-1, 2]))"),
        "sum": d("sum", "Built-in function", "Adds up all the numbers in a sequence.", "sum([1, 2, 3])  # 6"),
        "min": d("min", "Built-in function", "Returns the smallest value.", "min([4, 1, 7])  # 1"),
        "max": d("max", "Built-in function", "Returns the largest value.", "max([4, 1, 7])  # 7"),
        "sorted": d("sorted", "Built-in function", "Returns a new sorted list from any sequence.", "sorted([3, 1, 2])  # [1, 2, 3]"),
        "abs": d("abs", "Built-in function", "Returns the absolute (non-negative) value of a number.", "abs(-5)  # 5"),
        "round": d("round", "Built-in function", "Rounds a number to a given number of decimal places.", "round(3.14159, 2)  # 3.14"),
        "isinstance": d("isinstance", "Built-in function", "Checks whether a value is of a given type.", "isinstance(3, int)  # True"),

        // Operators / punctuation
        "=": d("=", "Assignment operator", "Stores the value on the right into the name on the left.", "x = 10"),
        "==": d("==", "Comparison operator", "Tests whether two values are equal. Returns True or False.", "if a == b:\n    print(\"same\")"),
        "!=": d("!=", "Comparison operator", "Tests whether two values are NOT equal.", "if a != b:\n    print(\"different\")"),
        "<": d("<", "Comparison operator", "True when the left value is less than the right.", "3 < 5  # True"),
        ">": d(">", "Comparison operator", "True when the left value is greater than the right.", "5 > 3  # True"),
        "<=": d("<=", "Comparison operator", "True when the left value is less than or equal to the right.", "3 <= 3  # True"),
        ">=": d(">=", "Comparison operator", "True when the left value is greater than or equal to the right.", "4 >= 5  # False"),
        "+": d("+", "Arithmetic operator", "Adds numbers, or joins strings and lists together.", "2 + 3  # 5\n\"a\" + \"b\"  # \"ab\""),
        "-": d("-", "Arithmetic operator", "Subtracts the right value from the left.", "10 - 4  # 6"),
        "*": d("*", "Arithmetic operator", "Multiplies numbers, or repeats a string/list.", "3 * 4  # 12\n\"ab\" * 2  # \"abab\""),
        "/": d("/", "Arithmetic operator", "Divides and gives a float result.", "7 / 2  # 3.5"),
        "//": d("//", "Arithmetic operator", "Floor division: divides and drops the remainder.", "7 // 2  # 3"),
        "%": d("%", "Arithmetic operator", "Modulo: the remainder after division.", "7 % 2  # 1"),
        "**": d("**", "Arithmetic operator", "Raises a number to a power (exponent).", "2 ** 3  # 8"),
        "+=": d("+=", "Augmented assignment", "Adds to a variable in place: x += 1 means x = x + 1.", "total += 5"),
        "-=": d("-=", "Augmented assignment", "Subtracts from a variable in place.", "count -= 1"),
        "->": d("->", "Annotation arrow", "Declares the return type of a function.", "def f(x: int) -> int:\n    return x"),
        ":=": d(":=", "Walrus operator", "Assigns a value and uses it in the same expression.", "if (n := len(data)) > 0:\n    print(n)"),
    ]
}
