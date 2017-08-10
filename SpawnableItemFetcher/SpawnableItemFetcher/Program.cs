using Newtonsoft.Json.Linq;
using System;
using System.IO;
using System.Linq;

namespace SpawnableItemFetcher
{
    class Program
    {
        static readonly string LINK_HELP = "https://github.com/Silverfeelin/Starbound-SpawnableItemPack/wiki/Adding-Items";

        /// <summary>
        /// File callback for <see cref="ScanDirectory(DirectoryInfo, bool, FileCallback)"/>
        /// </summary>
        /// <param name="file">File information for the found file.</param>
        delegate void FileCallback(FileInfo file);

        enum ResultType
        {
            Normal,
            Patch
        };

        static JArray result;
        static string basePath;

        static ResultType resultType = ResultType.Patch;

        /// <summary>
        /// File extensions for all items.
        /// </summary>
        static string[] extensions = ".activeitem,.object,.codex,.head,.chest,.legs,.back,.augment,.currency,.coinitem,.item,.consumable,.unlock,.instrument,.liqitem,.matitem,.thrownitem,.harvestingtool,.flashlight,.grapplinghook,.painttool,.wiretool,.beamaxe,.tillingtool,.miningtool,.techitem,.mechitem".Split(',');

        // Item names to exclude from the list.
        static string[] ignoredItems = new string[]
        {
            "filledcapturepod",
            "npcpetcapturepod"
        };

        static void Main(string[] args)
        {
            WriteColoredLine(ConsoleColor.White, "= Spawnable Item Fetcher");

            if (args.Length == 0)
            {
                args = PromptArgs();
            }

            if (args.Length != 2)
                WaitAndClose("Improper usage. Expected:" +
                    "\nSpawnableItemFetcher.exe <asset_path> <output_file>" +
                    "\n<asset_path>: Absolute path to unpacked assets." +
                    "\n<output_file>: Absolute path to file to write results to.");

            basePath = args[0];
            string outputFile = args[1];

            if (basePath.LastIndexOf("\\") == basePath.Length - 1)
                basePath = basePath.Substring(0, basePath.Length - 1);

            // Show paths
            Console.Write("Asset Path:  ");
            WriteColoredLine(ConsoleColor.Cyan, basePath);
            Console.Write("Output File: ");
            WriteColoredLine(ConsoleColor.Cyan, outputFile);
            Console.WriteLine();

            // Confirm asset path
            if (!Directory.Exists(basePath))
                WaitAndClose("Asset directory '" + basePath + "' not found.");

            // Confirm overwriting
            if (File.Exists(outputFile))
            {
                Console.WriteLine("Overwrite existing output file?");
                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine("[1] Overwrite file. [2] Cancel.");
                Console.ResetColor();

                ConsoleKeyInfo cki = Console.ReadKey(true);
                switch (cki.Key)
                {
                    default:
                        WaitAndClose("Cancelled.");
                        break;
                    case ConsoleKey.D1:
                    case ConsoleKey.NumPad1:
                        Console.WriteLine("The file will be overwritten.");
                        break;
                }
                Console.WriteLine();
            }

            // Get result type.
            resultType = PromptResultType();

            if (resultType == ResultType.Patch && !outputFile.EndsWith(".patch"))
            {
                Console.WriteLine("You're trying to make a patch file, but the output file does not end with '.patch'!");
            }
            Console.WriteLine();

            // Start scan
            Console.WriteLine("Starting to scan assets. This can take a while...");

            result = new JArray();
            FileCallback fc = new FileCallback(AddItem);

            // Scan all folders and subfolders. Adds all found items to result.
            ScanDirectories(basePath, extensions, fc);

            // Write results to selected file.
            Newtonsoft.Json.Formatting format = Newtonsoft.Json.Formatting.None;

            Directory.CreateDirectory(Path.GetDirectoryName(outputFile));
            File.WriteAllText(outputFile, result.ToString(format));

            WaitAndClose("Done fetching items!");
        }

        static string[] PromptArgs()
        {
            string[] args = new string[2];

            WriteColoredLine(ConsoleColor.Cyan, "What asset directory would you like to scan?");
            while (true)
            {
                string path = Console.ReadLine();

                if (Directory.Exists(path))
                {
                    args[0] = path;
                    break;
                }
                else
                {
                    Console.WriteLine("That directory does not exist. Please enter a valid directory.");
                }

            }

            WriteColoredLine(ConsoleColor.Cyan, "Where would you like to save the result to?");
            args[1] = Console.ReadLine();

            Console.WriteLine();

            return args;
        }

        /// <summary>
        /// Prompts the user to select a <see cref="ResultType"/>.
        /// This can not be interrupted, unless closing the application.
        /// </summary>
        /// <returns>Selected result type.</returns>
        static ResultType PromptResultType()
        {
            Console.WriteLine("Make a mod item file or patch file?");
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("[1] Mod File. [2] Patch File. [3] Unsure.");
            Console.ResetColor();

            ResultType resultType = ResultType.Normal;

            bool breakModeLoop;
            do
            {
                breakModeLoop = true;
                var cki = Console.ReadKey(true);
                switch (cki.Key)
                {
                    default:
                        breakModeLoop = false;
                        break;
                    case ConsoleKey.D1:
                    case ConsoleKey.NumPad1:
                        Console.WriteLine("Mod file it is.");
                        resultType = ResultType.Normal;
                        break;
                    case ConsoleKey.D2:
                    case ConsoleKey.NumPad2:
                        Console.WriteLine("Patch file it is.");
                        resultType = ResultType.Patch;
                        break;
                    case ConsoleKey.D3:
                    case ConsoleKey.NumPad3:
                        WriteColoredLine(ConsoleColor.DarkCyan, "Info: " + LINK_HELP);
                        System.Diagnostics.Process.Start(LINK_HELP);
                        breakModeLoop = false;
                        break;

                }
            } while (!breakModeLoop);

            return resultType;
        }

        /// <summary>
        /// Callback that scans the item file and adds the information needed for the Wardrobe mod to <see cref="result"/>.
        /// </summary>
        /// <param name="file">File to scan. Expected to be a JSON formatted item file.</param>
        static void AddItem(FileInfo file)
        {
            // Read file
            string content = File.ReadAllText(file.FullName);

            // Parse file
            JObject item = null;
            try
            {
                item = JObject.Parse(content);
            }
            catch
            {
                Console.WriteLine("Skipped '" + file.FullName + "', as it could not be parsed as a valid JSON file.");
                return;
            }

            JObject newItem = new JObject();

            newItem["path"] = AssetPath(file.FullName, basePath);
            newItem["fileName"] = file.Name;

            // Set item name
            string name = GetItemName(item);
            newItem["name"] = name;

            if (string.IsNullOrEmpty(name))
                return;

            // Set item description. Use item name if no description is set.
            string shortDescription = GetItemShortDescription(item);
            if (string.IsNullOrEmpty(shortDescription))
                shortDescription = name;
            newItem["shortdescription"] = shortDescription;

            // Set category
            string category = GetCategory(file.Extension, item);
            newItem["category"] = category;

            // Set icon
            newItem["icon"] = GetIcon(item, true);

            // Set rarity.
            string rarity = GetRarity(item);
            if (rarity != null)
                newItem["rarity"] = rarity;

            // Set race
            string race = GetRace(item);
            if (race != null)
                newItem["race"] = race;

            string directives = GetDirectives(item);
            if (!string.IsNullOrEmpty(directives))
                newItem["directives"] = directives;

            
            // Add the item.
            switch (resultType)
            {
                case ResultType.Patch:
                    JObject patch = JObject.Parse("{'op':'add','path':'/-','value':{}}");
                    patch["value"] = newItem;
                    result.Add(patch);
                    break;
                case ResultType.Normal:
                    result.Add(newItem);
                    break;
            }

        }

        static string GetItemName(JObject item)
        {
            JToken name = item["itemName"];

            if (name == null || name.Type != JTokenType.String)
                name = item["objectName"];

            if (name != null && name.Type != JTokenType.String)
                name = null;

            return name?.Value<string>();
        }

        static string GetItemShortDescription(JObject item)
        {
            JToken tkn = item["shortdescription"];

            if (tkn != null && tkn.Type != JTokenType.String)
                return null;

            return tkn?.Value<string>();
        }

        /// <summary>
        /// Returns the category of the item.
        /// Uses the item extension if no category could be found, and has a couple of overrides.
        /// </summary>
        /// <param name="extension">File extension</param>
        /// <param name="item">Item configuration</param>
        /// <returns>Category name</returns>
        static string GetCategory(string extension, JObject item)
        {
            string category = extension == ".unlock" ? "upgrade" : null;
            if (category == null && item["category"] != null)
                category = item["category"].Value<string>();

            if (category == null)
            {
                if (extension == ".coinitem")
                    category = "currency";
                else
                    category = extension.Substring(1);
            }

            // Overrides
            string[] toolReplaces = new string[] { "Tool ^green;[Y]", "Tool ^green;[T]", "Tool ^green;[R]" };
            if (toolReplaces.Contains(category))
                category = "Tool";

            if (category == "Upgrade Component")
                category = "upgradeComponent";

            if (category.ToLower() == "uniqueweapon" || category.ToLower() == "activeitem")
            {
                JArray tags = (JArray)item.SelectToken("itemTags");
                if (tags != null && tags.Values().Contains("ranged"))
                    category = "ranged";
                else if (tags != null && tags.Values().Contains("melee"))
                    category = "melee";
                else if (tags != null && tags.Values().Contains("shield"))
                    category = "shield";
                else
                    Console.WriteLine("Category for " + item["shortdescription"].Value<string>() + " could not be determined. Using '" + category + "' instead.");
            }

            // Hardcoded categorization.
            if (category == "uniqueWeapon")
            {
                switch (item["shortdescription"].Value<string>())
                {
                    default:
                        break;
                    case "Pollen Pump":
                    case "Magnorbs":
                        category = "ranged";
                        break;
                }
            }

            return category;
        }

        /// <summary>
        /// Returns the most viable texture for the inventory icon.
        /// Does not return a specific frame; instead only returns the image.
        /// </summary>
        /// <param name="obj">Item</param>
        /// <returns>Absolute or relative asset path, or null.</returns>
        static JToken GetIcon(JObject obj, bool useAssetMissing = true)
        {
            JToken token = obj.SelectToken("inventoryIcon");
            if (token == null)
                token = obj.SelectToken("icon");

            if (token == null)
            {
                token = obj.SelectToken("renderParameters");

                if (token != null)
                {
                    token = token.SelectToken("texture");
                }
            }

            if (token?.Type == JTokenType.Array)
            {
                token = token[0];
            }

            return token != null ? token : useAssetMissing ? "/assetMissing.png" : null;
        }

        static string GetDirectives(JObject item)
        {
            // Use the first color option, if color options are present.
            // Generally used for clothes.
            JToken colors = item.SelectToken("colorOptions");

            if (colors is JArray)
            {
                JArray cs = (JArray)colors;
                if (cs.Count() > 0)
                {
                    try
                    {
                        JObject color = (JObject)colors[0];
                        string dir = "?replace";
                        foreach (var c in color)
                        {
                            dir += ";" + c.Key + "=" + c.Value;
                        }

                        return dir;
                    }
                    catch
                    {
                        return null;
                    }
                }
            }

            return null;
        }

        static string GetRarity(JObject item, string defaultRarity = "common")
        {
            JToken tkn = item["rarity"];
            if (tkn == null || tkn.Type != JTokenType.String)
                return defaultRarity;

            return tkn.Value<string>().ToLowerInvariant();
        }
        
        static string GetRace(JObject item)
        {
            JToken tkn = item["race"];
            if (tkn == null || tkn.Type != JTokenType.String)
                return null;

            return tkn.Value<string>().ToLowerInvariant();
        }

        /// <summary>
        /// Scans the directory and all subdirectories, running the callback for each found file.
        /// </summary>
        /// <param name="basePath">Base directory to scan for matching files.</param>
        /// <param name="extensions">Array of extension names to match. Do not include dots.</param>
        /// <param name="callback">Callback for each found file.</param>
        static void ScanDirectories(string basePath, string[] extensions, FileCallback callback)
        {
            foreach (var file in Directory.EnumerateFiles(basePath, "*", SearchOption.AllDirectories))
            {
                FileInfo fi = new FileInfo(file);
                if (extensions.Contains(fi.Extension.ToLower()))
                    callback(fi);
            }
        }

        static string AssetPath(string filePath, string basePath)
        {
            return (Path.GetDirectoryName(filePath) + "/").Replace(basePath, "").Replace("\\", "/");
        }

        /// <summary>
        /// Displays the given message, and closes the application after any key press.
        /// </summary>
        /// <param name="message">Message to display</param>
        static void WaitAndClose(string message)
        {
            Console.WriteLine(message);
            WriteColoredLine(ConsoleColor.Cyan, "Press any key to exit...");
            Console.ReadKey(true);
            Environment.Exit(0);
        }

        static void WriteColored(ConsoleColor color, string str, params object[] args)
        {
            Console.ForegroundColor = color;
            Console.Write(str, args);
            Console.ResetColor();
        }

        static void WriteColored(ConsoleColor color, ConsoleColor backColor, string str, params object[] args)
        {
            Console.ForegroundColor = color;
            Console.BackgroundColor = backColor;
            Console.Write(str, args);
            Console.ResetColor();
        }

        static void WriteColoredLine(ConsoleColor color, string str, params object[] args)
        {
            Console.ForegroundColor = color;
            Console.WriteLine(str, args);
            Console.ResetColor();
        }

        static void WriteColoredLine(ConsoleColor color, ConsoleColor backColor, string str, params object[] args)
        {
            Console.ForegroundColor = color;
            Console.BackgroundColor = backColor;
            Console.WriteLine(str, args);
            Console.ResetColor();
        }
    }
}
