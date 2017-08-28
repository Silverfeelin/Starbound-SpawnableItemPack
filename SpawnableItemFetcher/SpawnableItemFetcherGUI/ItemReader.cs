using Newtonsoft.Json.Linq;
using System.Linq;

namespace SpawnableItemFetcherGUI
{
    /// <summary>
    /// Copy of SpawnableItemFetcher.ItemReader because I didn't want the dependency.
    /// </summary>
    public static class ItemReader
    {
        public static string GetItemName(JObject item)
        {
            JToken name = item["itemName"];

            if (name == null || name.Type != JTokenType.String)
                name = item["objectName"];

            if (name != null && name.Type != JTokenType.String)
                name = null;

            return name?.Value<string>();
        }

        public static string GetShortDescription(JObject item)
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
        public static string GetCategory(string extension, JObject item)
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
        public static JToken GetIcon(JObject obj, bool useAssetMissing = true)
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

        public static string GetDirectives(JObject item)
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

        public static string GetRarity(JObject item, string defaultRarity = "common")
        {
            JToken tkn = item["rarity"];
            if (tkn == null || tkn.Type != JTokenType.String)
                return defaultRarity;

            return tkn.Value<string>().ToLowerInvariant();
        }

        public static string GetRace(JObject item)
        {
            JToken tkn = item["race"];
            if (tkn == null || tkn.Type != JTokenType.String)
                return null;

            return tkn.Value<string>().ToLowerInvariant();
        }

        public static string GetSpecies(JObject item)
        {
            JToken tkn = item["species"];
            if (tkn == null || tkn.Type != JTokenType.String)
                return null;

            return tkn.Value<string>().ToLowerInvariant();
        }

        #region Codex Specific

        public static string GetCodexName(JObject item)
        {
            JToken name = item["id"];
            if (name != null && name.Type == JTokenType.String)
            {
                return name.Value<string>() + "-codex";
            }

            return null;
        }

        public static string GetCodexTitle(JObject item)
        {
            JToken tkn = item["title"];

            if (tkn != null && tkn.Type != JTokenType.String)
                return null;

            return tkn?.Value<string>();
        }

        public static string GetCodexRarity(JObject item, string defaultRarity = "common")
        {
            JToken tkn = item.SelectToken("itemConfig.rarity");
            if (tkn == null || tkn.Type != JTokenType.String)
                return defaultRarity;

            return tkn.Value<string>().ToLowerInvariant();
        }

        #endregion
    }
}
