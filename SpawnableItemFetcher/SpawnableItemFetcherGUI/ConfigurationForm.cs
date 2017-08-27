using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace SpawnableItemFetcherGUI
{
    public partial class ConfigurationForm : Form
    {
        private bool unsavedChanges = false;

        public ConfigurationForm()
        {
            InitializeComponent();

            LoadExtensions();
            LoadBlacklist();
        }

        /// <summary>
        /// Loads all extensions.
        /// </summary>
        private void LoadExtensions()
        {
            dgvExtensions.Rows.Clear();

            foreach (string extension in Properties.Settings.Default.Extensions.Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries))
            {
                dgvExtensions.Rows.Add(extension);
            }
        }

        /// <summary>
        /// Loads all blacklisted items.
        /// </summary>
        private void LoadBlacklist()
        {
            dgvBlacklist.Rows.Clear();

            foreach (string item in Properties.Settings.Default.Blacklist.Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries))
            {
                dgvBlacklist.Rows.Add(item);
            }
        }

        /// <summary>
        /// Resets the settings, then refreshes the form.
        /// </summary>
        private void ResetSettings()
        {
            Properties.Settings.Default.Reset();
            Properties.Settings.Default.Save();

            LoadExtensions();
            LoadBlacklist();

            unsavedChanges = true;
        }

        /// <summary>
        /// Gets a set of unique non-blank file extensions.
        /// The extensions are not prefixed with a dot, even when entered as such in the data grid.
        /// </summary>
        /// <returns></returns>
        private HashSet<string> GetExtensions()
        {
            HashSet<string> exts = new HashSet<string>();
            foreach (DataGridViewRow item in dgvExtensions.Rows)
            {
                string extension = item.Cells[0].Value?.ToString();

                // Remove dot
                if (extension != null && !extension.StartsWith("."))
                {
                    extension = "." + extension;
                }

                // Add non-blank
                if (!string.IsNullOrWhiteSpace(extension))
                {
                    exts.Add(extension.ToLowerInvariant());
                }
            }
            return exts;
        }

        private HashSet<string> GetBlacklist()
        {
            HashSet<string> items = new HashSet<string>();
            foreach (DataGridViewRow row in dgvBlacklist.Rows)
            {
                string item = row.Cells[0].Value?.ToString();
                
                // Add non-blank
                if (!string.IsNullOrWhiteSpace(item))
                {
                    items.Add(item.ToLowerInvariant());
                }
            }
            return items;
        }

        private void SaveSettings()
        {
            Properties.Settings.Default.Extensions = string.Join(";", GetExtensions());
            Properties.Settings.Default.Blacklist = string.Join(";", GetBlacklist());
            Properties.Settings.Default.Save();

            unsavedChanges = false;
        }

        #region Events
        private void ConfigurationForm_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (unsavedChanges)
            {
                // If a value was changed but the dialog wasn't marked OK (Save), warn the user.
                DialogResult dr = MessageBox.Show("The settings have not been saved. Are you sure you want to close this window?", "Warning", MessageBoxButtons.YesNo);
                if (dr != DialogResult.Yes)
                {
                    e.Cancel = true;
                }
            }
        }

        private void Save_Click(object sender, EventArgs e)
        {
            SaveSettings();
        }
        
        private void Reset_Click(object sender, EventArgs e)
        {
            ResetSettings();
        }

        private void CellBeginEdit_MarkChanged(object sender, DataGridViewCellCancelEventArgs e)
        {
            unsavedChanges = true;
        }

        #endregion
    }
}
