using System;
using System.Linq;
using System.Windows.Forms;
using Ookii.Dialogs;
using System.IO;
using Newtonsoft.Json.Linq;
using System.Diagnostics;
using System.Drawing;
using System.Text.RegularExpressions;
using System.ComponentModel;
using System.Collections.Generic;

namespace SpawnableItemFetcherGUI
{
    public partial class MainForm : Form
    {
        /// <summary>
        /// File callback for <see cref="ScanDirectory(DirectoryInfo, bool, FileCallback)"/>
        /// </summary>
        /// <param name="file">File information for the found file.</param>
        delegate void FileCallback(FileInfo file);

        private BackgroundWorker worker;

        public MainForm()
        {
            InitializeComponent();

            worker = new BackgroundWorker();
            worker.WorkerReportsProgress = true;
            worker.WorkerSupportsCancellation = true;
            worker.DoWork += Worker_DoWork;
            worker.ProgressChanged += Worker_ProgressChanged;
            worker.RunWorkerCompleted += Worker_RunWorkerCompleted;
        }

        #region Select Folders

        private void BrowseModFolder_Click(object sender, EventArgs e)
        {
            VistaFolderBrowserDialog fbd = new VistaFolderBrowserDialog();
            fbd.Description = "Select the mod folder to fetch items from.";
            fbd.UseDescriptionForTitle = true;

            if (fbd.ShowDialog() == DialogResult.OK)
            {
                tbxModFolder.Text = fbd.SelectedPath;
                tbxModName.Text = Path.GetFileName(fbd.SelectedPath).Replace(' ', '_');

                if (string.IsNullOrWhiteSpace(tbxOutputFolder.Text))
                {
                    tbxOutputFolder.Text = tbxModFolder.Text;
                }
            }
        }

        private void BrowseOutputFolder_Click(object sender, EventArgs e)
        {
            VistaFolderBrowserDialog fbd = new VistaFolderBrowserDialog();
            fbd.Description = "Select the mod folder to save the patch files to.";
            fbd.UseDescriptionForTitle = true;

            if (fbd.ShowDialog() == DialogResult.OK)
            {
                tbxOutputFolder.Text = fbd.SelectedPath;
            }
        }

        #endregion

        #region Button Events

        private void Settings_Click(object sender, EventArgs e)
        {
            ConfigurationForm form = new ConfigurationForm();
            form.ShowDialog(this);
        }
        
        private void CreatePatch_Click(object sender, EventArgs e)
        {
            CreatePatch();
        }
        
        private void CancelPatch_Click(object sender, EventArgs e)
        {
            CancelPatch();
        }

        #endregion

        #region Input validation

        private void tbxModFolder_TextChanged(object sender, EventArgs e)
        {
            bool valid = Directory.Exists(tbxModFolder.Text);
            Color c = valid ? Color.LimeGreen : Color.Red;

            if (tbxModFolder.Valid != valid)
            {
                tbxModFolder.Valid = valid;
                tbxModFolder.BorderColor = c;
                toolTip.SetToolTip(tbxModFolder, valid ? null : "Please enter a valid mod folder path.");
            }
        }

        private void tbxModName_TextChanged(object sender, EventArgs e)
        {
            Match m = Regex.Match(tbxModName.Text, "[a-zA-z0-9_]+");
            bool valid = m.Success;
            Color c = valid ? Color.LimeGreen : Color.Red;

            if (tbxModName.Valid != valid)
            {
                tbxModName.Valid = valid;
                tbxModName.BorderColor = c;
                toolTip.SetToolTip(tbxModName, "Please enter an identifier for the mod. This will be used to name the item file.\nDo not use any special characters other than underscores.");
            }

        }

        private void tbxOutputFolder_TextChanged(object sender, EventArgs e)
        {
            bool valid = Directory.Exists(tbxOutputFolder.Text);
            Color c = valid ? Color.LimeGreen : Color.Red;

            if (tbxOutputFolder.Valid != valid)
            {
                tbxOutputFolder.Valid = valid;
                tbxOutputFolder.BorderColor = c;
                toolTip.SetToolTip(tbxOutputFolder, valid ? null : "Please enter a valid output folder path. The folder must exist, but can be empty.");
            }
        }

        #endregion

        /// <summary>
        /// Returns a value indicating whether all input is valid.
        /// </summary
        private bool ValidInput()
        {
            return tbxModFolder.Valid && tbxModName.Valid && tbxOutputFolder.Valid;
        }

        /// <summary>
        /// Tells the BackgroundWorker to create a patch if it's not already busy.
        /// </summary>
        private void CreatePatch()
        {
            if (!ValidInput())
            {
                rtbxOutput.AppendTimestampText(Color.Red, "Please validate your input first!\n");
                return;
            }
            
            if (worker.IsBusy)
            {
                rtbxOutput.AppendTimestampText(Color.Red, "The worker is already busy!\n");
                return;
            }

            string modFolder = tbxModFolder.Text,
                outputFolder = tbxOutputFolder.Text,
                modName = tbxModName.Text;
            
            string filePath = Path.Combine(outputFolder, "sipMods\\" + modName + ".json");
            string filePathName = modName + ".json";
            
            // Set base path (used to create asset paths).
            string basePath = modFolder;

            if (basePath.LastIndexOf("\\") == basePath.Length - 1)
                basePath = basePath.Substring(0, basePath.Length - 1);

            rtbxOutput.AppendTimestampText("Starting to fetch items. This may take a while.\nPlease do not worry if the progress bar seems stuck near the beginning. This means the application is busy locating all your item and object files.\n");
            
            worker_modFolder = modFolder;
            worker_targetFolder = outputFolder;
            worker_modIdentifier = modName;
            worker_basePath = basePath;
            worker_extensions = Properties.Settings.Default.Extensions.Split(';');

            prgPatching.Value = 0;
            worker.RunWorkerAsync();
        }
        
        private void CancelPatch()
        {
            if (worker.IsBusy)
            {
                // Worker will say where it stopped.
                worker.CancelAsync();
            }
            else
            {
                rtbxOutput.AppendText("There's no task to cancel!\n");
            }
        }

        #region Worker

        string worker_modFolder;
        string worker_targetFolder;
        string worker_modIdentifier;
        string worker_basePath;
        string[] worker_extensions;
        JArray worker_items;

        private void Worker_DoWork(object sender, DoWorkEventArgs e)
        {
            worker_items = new JArray();
            
            // Create SIP folder.
            Directory.CreateDirectory(Path.Combine(worker_targetFolder, "sipMods"));

            // Index files
            // Because we don't know how many files there are, this step reports fake progress (0: 0%, 1000:  40%, >1000: 40%).
            List<FileInfo> files = new List<FileInfo>(100);

            foreach (FileInfo file in FindFiles(worker_modFolder, worker_extensions, true))
            {
                files.Add(file);
                
                // Update UI from worker? I don't see why not.
                if (files.Count % 100 == 0)
                {
                    Worker_AppendText("Indexed {0} files.\n", files.Count);
                    int progress = (int)Math.Floor((files.Count < 1000 ? files.Count : 1000) / 1000d * 40);
                    worker.ReportProgress(progress);
                }

                if (e.Cancel)
                {
                    Worker_AppendText("Cancelled after indexing {0} files.\n", files.Count);
                    return;
                }
            }

            Worker_AppendText("Indexed {0} files.\n", files.Count);
            worker.ReportProgress(40);

            // Scan files
            int beginProgress = 40, endProgress = 90;
            int diffProgress = endProgress - beginProgress;
            int fileCount = files.Count, filesAdded = 0;
            // Read files
            foreach (FileInfo file in files)
            {
                switch (file.Extension.ToLowerInvariant())
                {
                    default:
                        Worker_AddItem(file, worker_items);
                        break;
                    case ".codex":
                        Worker_AddCodex(file, worker_items);
                        break;
                }

                int progress = (int)Math.Floor(beginProgress + ++filesAdded / (double)fileCount * diffProgress);
                worker.ReportProgress(progress);

                if (e.Cancel)
                {
                    return;
                }
            }

            // Create item file
            Worker_SaveItems(worker_items, worker_targetFolder, worker_modIdentifier);

            // Patch load.json
            Worker_CreatePatch(worker_modFolder, worker_targetFolder, worker_modIdentifier + ".json");
            worker.ReportProgress(95);

            // include SIP in metadata
            Worker_PatchMetadata(worker_targetFolder);

            // Done
            worker.ReportProgress(100);
        }

        private void Worker_CreatePatch(string modFolder, string targetFolder, string itemFileName)
        {
            string patchFile = Path.Combine(targetFolder, "sipMods\\load.config.patch");
            
            JArray patch;
            // Create, update or leave alone the patch file.
            if (File.Exists(patchFile))
            {
                patch = JArray.Parse(File.ReadAllText(patchFile));
                foreach (var item in patch)
                {
                    if (item["value"].Type == JTokenType.String && item["value"].Value<string>() == itemFileName)
                    {
                        // No patching needed; the file name is already in there.
                        return;
                    }
                }
            }
            else
            {
                // Create new patch
                patch = new JArray();
            }

            // Add the file to the patch
            JObject patchObject = new JObject();
            patchObject["op"] = "add";
            patchObject["path"] = "/-";
            patchObject["value"] = itemFileName;
            patch.Add(patchObject);

            File.WriteAllText(patchFile, patch.ToString(Newtonsoft.Json.Formatting.Indented));
            Worker_AppendText("Patched the SpawnableItemPack load.json to include {0}.json.\n", worker_modIdentifier);
        }

        private void Worker_PatchMetadata(string targetFolder)
        {
            // Add metadata dependency if necessary
            // Creates a new placeholder metadata if none exists.
            JObject metadata;
            string metadataFile = GetMetadataPath(targetFolder, true);
            
            metadata = JObject.Parse(File.ReadAllText(metadataFile));

            // Create includes.
            JToken t = metadata.SelectToken("includes");
            if (t == null || t.Type != JTokenType.Array)
            {
                metadata["includes"] = new JArray();
            }

            // Check if SIP is present.
            JArray includes = (JArray)metadata["includes"];
            bool containsSIP = false;
            foreach (JToken include in includes)
            {
                if (include.Value<string>() == "SpawnableItemPack")
                {
                    containsSIP = true;
                    break;
                }
            }

            // Add SIP and save file.
            if (!containsSIP)
            {
                includes.Add("SpawnableItemPack");
                File.WriteAllText(metadataFile, metadata.ToString(Newtonsoft.Json.Formatting.Indented));
                Worker_AppendText("Added SpawnableItemPack to the metadata.\n");
            }
        }

        private void Worker_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            prgPatching.Value = e.ProgressPercentage;
        }

        private void Worker_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            rtbxOutput.AppendTimestampText(Color.Green, "A total of {0} items have been fetched! The mod folder has been opened for you.\n", worker_items.Count);
            Process.Start(worker_targetFolder);

            worker_items = null;
            worker_basePath = null;
            worker_extensions = null;
            worker_modIdentifier = null;
            worker_targetFolder = null;
            worker_modFolder = null;
        }

        private void Worker_AddItem(FileInfo file, JArray items)
        {
            try
            {
                JObject item = JObject.Parse(File.ReadAllText(file.FullName));
                JObject newItem = new JObject();

                newItem["path"] = GetAssetPath(file.FullName, worker_basePath);
                newItem["fileName"] = file.Name;

                // Set item name
                string name = ItemReader.GetItemName(item);
                newItem["name"] = name;

                if (string.IsNullOrEmpty(name))
                {
                    Console.WriteLine("File {0} has no item name.", file.FullName);
                    return;
                }

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

                items.Add(newItem);
            }
            catch
            {
                // Skip file.
                Console.WriteLine("Couldn't parse file {0}.", file.FullName);
            }
        }

        private void Worker_AddCodex(FileInfo file, JArray items)
        {
            try
            {
                JObject item = JObject.Parse(File.ReadAllText(file.FullName));
                JObject newItem = new JObject();

                newItem["path"] = GetAssetPath(file.FullName, worker_basePath);
                newItem["fileName"] = file.Name;

                // Set item name
                string name = ItemReader.GetCodexName(item);
                newItem["name"] = name;
                if (string.IsNullOrEmpty(name))
                {
                    Console.WriteLine("Codex file {0} has no IDw.", file.FullName);
                    return;
                }

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
                items.Add(newItem);
            }
            catch
            {
                // Skip file.
                Console.WriteLine("Couldn't parse file {0}.", file.FullName);
            }
        }

        private void Worker_SaveItems(JArray items, string modFolder, string modIdentifier)
        {
            string path = Path.Combine(modFolder, "sipMods\\" + modIdentifier + ".json");
            File.WriteAllText(path, items.ToString(Newtonsoft.Json.Formatting.None));
        }

        private void Worker_AppendText(string text, params object[] args)
        {
            rtbxOutput.Invoke((MethodInvoker)delegate {
                rtbxOutput.AppendTimestampText(text, args);
                rtbxOutput.ScrollToCaret();
            });
        }

        private void Worker_AppendText(Color color, string text, params object[] args)
        {
            rtbxOutput.Invoke((MethodInvoker)delegate {
                rtbxOutput.AppendTimestampText(color, text, args);
                rtbxOutput.ScrollToCaret();
            });
        }

        #endregion
        
        private IEnumerable<FileInfo> FindFiles(string path, string[] extensions, bool recursive = true)
        {
            string[] files = Directory.GetFiles(path);
            foreach (string file in files)
            {
                FileInfo fileInfo = new FileInfo(file);
                if (extensions.Contains(fileInfo.Extension))
                    yield return fileInfo;
            }

            // Recursive
            if (recursive)
            {
                foreach (string folder in Directory.GetDirectories(path))
                {
                    foreach (FileInfo file in FindFiles(folder, extensions, true))
                    {
                        yield return file;
                    }
                }
            }
        }

        /// <summary>
        /// Scans the directory and all subdirectories, running the callback for each found file.
        /// </summary>
        /// <param name="basePath">Base directory to scan for matching files.</param>
        /// <param name="extensions">Array of extension names to match. Do not include dots.</param>
        /// <param name="callback">Callback for each found file.</param>
        private static void ScanDirectories(string basePath, string[] extensions, FileCallback callback)
        {
            foreach (var file in Directory.EnumerateFiles(basePath, "*", SearchOption.AllDirectories))
            {
                FileInfo fi = new FileInfo(file);

                string extension = fi.Extension.ToLowerInvariant();
                if (extension.StartsWith("."))
                    extension = extension.Substring(1);

                if (extensions.Contains(extension))
                    callback(fi);
            }
        }

        private static string GetAssetPath(string filePath, string basePath)
        {
            return (Path.GetDirectoryName(filePath) + "/").Replace(basePath, "").Replace("\\", "/");
        }

        private string GetMetadataPath(string modPath, bool createIfNeeded = false)
        {
            string a = Path.Combine(modPath, ".metadata"),
                b = Path.Combine(modPath, "_metadata");

            if (File.Exists(a))
            {
                return b;
            }
            else if (File.Exists(b))
            {
                return b;
            }
            else if (createIfNeeded)
            {
                Worker_AppendText(Color.Red, "Created a placeholder metadata file to include SpawnableItemPack. Please update the file manually.\n");
                File.WriteAllText(b, @"{""name"":""CHANGE_ME"",""includes"":[""SpawnableItemPack""]}");
                return b;
            }
            else
            {
                return null;
            }
        }
    }
}
