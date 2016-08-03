using Newtonsoft.Json.Linq;
using System;
using System.IO;
using System.Linq;

namespace SpawnableItemFetcher
{
    class Program
    {
        /// <summary>
        /// File callback for <see cref="ScanDirectory(DirectoryInfo, bool, FileCallback)"/>
        /// </summary>
        /// <param name="file">File information for the found file.</param>
        delegate void FileCallback(FileInfo file);

        static JArray result;
        static string basePath;

        /// <summary>
        /// File extensions for all items.
        /// </summary>
        static string[] extensions = ".activeitem,.object,.codex,.head,.chest,.legs,.back,.augment,.coinitem,.item,.consumable,.unlock,.instrument,.liqitem,.matitem,.thrownitem,.harvestingtool,.flashlight,.grapplinghook,.painttool,.wiretool,.beamaxe,.tillingtool,.miningtool,.techitem".Split(',');

        // Item names to exclude from the list.
        static string[] ignoredItems = new string[]
        {
            "filledcapturepod",
            "npcpetcapturepod"
        };

        static void Main(string[] args)
        {
            if (args.Length != 2)
                WaitAndClose("Improper usage. Expected:" +
                    "\nSpawnableItemFetcher.exe <asset_path> <output_file>" +
                    "\n<asset_path>: Absolute path to unpacked assets." +
                    "\n<output_file>: Absolute path to file to write results to." +
                    "\nOutput file should be /yourMod/sipCustomItems.json.patch");

            basePath = args[0];
            string outputFile = args[1];

            if (basePath.LastIndexOf("\\") == basePath.Length - 1)
                basePath = basePath.Substring(0, basePath.Length - 1);

            // Confirm asset path
            if (!Directory.Exists(basePath))
                WaitAndClose("Asset directory '" + basePath + "' not found. Invalid directory given.");

            // Confirm overwriting
            if (File.Exists(outputFile))
            {
                Console.WriteLine("Output file '" + outputFile + "' already exists!\n1. Overwrite file\n2. Cancel");

                ConsoleKeyInfo cki = Console.ReadKey(true);
                switch (cki.Key)
                {
                    default:
                        WaitAndClose("Cancelling task.");
                        break;
                    case ConsoleKey.D1:
                    case ConsoleKey.NumPad1:
                        Console.WriteLine("Output file will be overwritten.");
                        break;
                }
            }

            result = new JArray();
            FileCallback fc = new FileCallback(AddItem);

            // Scan all folders and subfolders. Adds all found items to result.
            ScanDirectories(basePath, extensions, fc);

            // Write results to selected file.
            File.WriteAllText(outputFile, result.ToString(Newtonsoft.Json.Formatting.Indented));

            Console.WriteLine("Done fetching items!\nPress any key to exit...");
            Console.ReadKey();
        }

        /// <summary>
        /// Callback that scans the item file and adds the information needed for the Wardrobe mod to <see cref="result"/>.
        /// </summary>
        /// <param name="file">File to scan. Expected to be a JSON formatted item file.</param>
        static void AddItem(FileInfo file)
        {
            string content = File.ReadAllText(file.FullName);
            JObject item = null;
            try
            {
                item = JObject.Parse(content);
            }
            catch (Exception exc)
            {
                Console.WriteLine("Skipped '" + file.FullName + "', as it could not be parsed as a valid JSON file.");
            }

            JObject newItem = new JObject();

            // Set item name
            newItem["name"] = item["itemName"];
            if (newItem["name"] == null || newItem["name"].Type != JTokenType.String)
                newItem["name"] = item["objectName"];
            if (newItem["name"] == null || newItem["name"].Type != JTokenType.String || ignoredItems.Contains(newItem["name"].Value<string>().ToLower()))
                return;

            // Set item description. Use item name if no description is set.
            newItem["shortdescription"] = item["shortdescription"];
            if (newItem["shortdescription"] == null || newItem["shortdescription"].Type != JTokenType.String)
                newItem["shortdescription"] = newItem["name"];

            // Set category
            string category = GetCategory(file.Extension, item);
            newItem["category"] = category;

            // Base path removed to get an asset path. Slash added to the end and backslashes converted to regular slashes.
            newItem["path"] = (Path.GetDirectoryName(file.FullName) + "/").Replace(basePath, "").Replace("\\", "/");

            // Set icon
            newItem["icon"] = GetIcon(item);
            if (newItem["icon"] == null || newItem["icon"].Type != JTokenType.String)
                newItem["icon"] = "/assetMissing.png";

            // Set filename
            newItem["fileName"] = file.Name;

            // Set rarity. Use common if no rarity is set.
            if (item["rarity"] != null || item["rarity"].Type != JTokenType.String)
                newItem["rarity"] = item["rarity"].Value<String>().ToLower();
            else
                newItem["rarity"] = "common";

            // Attempt to use first frame as the preview image, for objects.
            // Really messy and doesn't work most of the time.
            if (file.Extension == ".object")
            {
                string n = Path.GetFileNameWithoutExtension(file.FullName);
                string t = null;
                if (File.Exists(file.DirectoryName + @"\" + n + ".frames"))
                {
                    t = File.ReadAllText(file.DirectoryName + @"\" + n + ".frames");
                }
                else if (File.Exists(file.DirectoryName + @"\" + n + "left.frames"))
                {
                    t = File.ReadAllText(file.DirectoryName + @"\" + n + "left.frames");
                }
                else if (File.Exists(file.DirectoryName + @"\" + "default.frames"))
                {
                    t = File.ReadAllText(file.DirectoryName + @"\" + "default.frames");
                }
                if (t != null)
                {
                    JObject b = JObject.Parse(t);
                    JToken tk = b["frameGrid"]["names"];
                    if (tk != null && tk.Count() > 0)
                    {
                        foreach (var frame in tk[0])
                        {
                            string value = frame.Value<String>();
                            if (!string.IsNullOrEmpty(value))
                            {
                                newItem["frame"] = value;
                                break;
                            }
                        }
                    }
                }
            }

            // Use the first color option, if color options are present.
            // Generally used for clothes.
            JToken colors = item.SelectToken("colorOptions");

            if (colors is JArray)
            {
                JArray cs = (JArray)colors;
                if (cs.Count() > 0)
                {
                    JObject color = (JObject)colors[0];
                    string dir = "?replace";
                    foreach (var c in color)
                    {
                        dir += ";" + c.Key + "=" + c.Value;
                    }

                    newItem["directives"] = dir;
                }
            }

            // Add the item.
            JObject patch = JObject.Parse("{'op':'add','path':'/-','value':{}}");
            patch["value"] = newItem;
            result.Add(patch);
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

            if (category == "uniqueWeapon")
            {
                JArray tags = (JArray)item.SelectToken("itemTags");
                if (tags.Values().Contains("ranged"))
                    category = "ranged";
                else if (tags.Values().Contains("melee"))
                    category = "melee";
                else
                    Console.WriteLine("Specific category for " + item["shortdescription"].Value<string>() + " could not be found. Using 'uniqueWeapon' instead.");
            }
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
        static JToken GetIcon(JObject obj)
        {
            JToken token = obj.SelectToken("inventoryIcon");
            if (token != null) return token;
            token = obj.SelectToken("icon");
            if (token != null) return token;
            token = obj.SelectToken("renderParameters");
            if (token != null)
            {
                JToken token2 = token.SelectToken("texture");
                if (token2 != null) return token2;
            }

            return null;
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

        /// <summary>
        /// Displays the given message, and closes the application after any key press.
        /// </summary>
        /// <param name="message">Message to display</param>
        static void WaitAndClose(string message)
        {
            Console.WriteLine(message);
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
            Environment.Exit(0);
        }
    }
}
