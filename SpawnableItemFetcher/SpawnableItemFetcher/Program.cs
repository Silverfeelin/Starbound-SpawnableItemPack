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
            if (file.Extension == ".codex")
            {
                AddCodex(file);
                return;
            }

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
            string name = ItemReader.GetItemName(item);
            newItem["name"] = name;

            if (string.IsNullOrEmpty(name))
                return;

            // Skip objects with no item variant.
            if (item.Value<bool?>("hasObjectItem") == false)
                return;

            // Set item description. Use item name if no description is set.
            string shortDescription = ItemReader.GetShortDescription(item);
            if (string.IsNullOrEmpty(shortDescription))
                shortDescription = name;
            newItem["shortdescription"] = shortDescription;

            // Set category
            string category = ItemReader.GetCategory(file.Extension, item);
            newItem["category"] = category;

            // Set icon
            newItem["icon"] = ItemReader.GetIcon(item, true);

            // Set rarity.
            string rarity = ItemReader.GetRarity(item);
            if (rarity != null)
                newItem["rarity"] = rarity;

            // Set race
            string race = ItemReader.GetRace(item);
            if (race != null)
                newItem["race"] = race;

            string directives = ItemReader.GetDirectives(item);
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

        static void AddCodex(FileInfo file)
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
            string name = ItemReader.GetCodexName(item);
            newItem["name"] = name;

            if (string.IsNullOrEmpty(name))
                return;

            // Set item description. Use item name if no description is set.
            string shortDescription = ItemReader.GetCodexTitle(item);
            if (string.IsNullOrEmpty(shortDescription))
                shortDescription = name;
            newItem["shortdescription"] = shortDescription;

            // Set category
            newItem["category"] = "codex";

            // Set icon
            newItem["icon"] = ItemReader.GetIcon(item, true);

            // Set rarity.
            string rarity = ItemReader.GetCodexRarity(item);
            if (rarity != null)
                newItem["rarity"] = rarity;

            // Set race
            string race = ItemReader.GetSpecies(item);
            if (race != null)
                newItem["race"] = race;
            
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
        
        /// <summary>
        /// Scans the directory and all subdirectories, running the callback for each found file.
        /// </summary>
        /// <param name="basePath">Base directory to scan for matching files.</param>
        /// <param name="extensions">Array of extension names to match.</param>
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
