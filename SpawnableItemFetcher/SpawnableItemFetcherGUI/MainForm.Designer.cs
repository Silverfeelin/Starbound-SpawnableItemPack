namespace SpawnableItemFetcherGUI
{
    partial class MainForm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            this.lblModFolder = new System.Windows.Forms.Label();
            this.tbxModFolder = new SpawnableItemFetcherGUI.ColorableTextBox();
            this.btnBrowseModFolder = new System.Windows.Forms.Button();
            this.lblOutputFolder = new System.Windows.Forms.Label();
            this.tbxOutputFolder = new SpawnableItemFetcherGUI.ColorableTextBox();
            this.btnBrowseOutputFolder = new System.Windows.Forms.Button();
            this.btnCreatePatch = new System.Windows.Forms.Button();
            this.tbxModName = new SpawnableItemFetcherGUI.ColorableTextBox();
            this.lblModName = new System.Windows.Forms.Label();
            this.btnSettings = new System.Windows.Forms.Button();
            this.rtbxOutput = new System.Windows.Forms.RichTextBox();
            this.toolTip = new System.Windows.Forms.ToolTip(this.components);
            this.prgPatching = new System.Windows.Forms.ProgressBar();
            this.SuspendLayout();
            // 
            // lblModFolder
            // 
            this.lblModFolder.AutoSize = true;
            this.lblModFolder.Location = new System.Drawing.Point(12, 9);
            this.lblModFolder.Name = "lblModFolder";
            this.lblModFolder.Size = new System.Drawing.Size(60, 13);
            this.lblModFolder.TabIndex = 0;
            this.lblModFolder.Text = "Mod folder:";
            // 
            // tbxModFolder
            // 
            this.tbxModFolder.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.tbxModFolder.BorderColor = System.Drawing.Color.Red;
            this.tbxModFolder.Location = new System.Drawing.Point(78, 6);
            this.tbxModFolder.Name = "tbxModFolder";
            this.tbxModFolder.Size = new System.Drawing.Size(375, 20);
            this.tbxModFolder.TabIndex = 1;
            this.toolTip.SetToolTip(this.tbxModFolder, "Please enter a valid mod folder path.");
            this.tbxModFolder.TextChanged += new System.EventHandler(this.tbxModFolder_TextChanged);
            // 
            // btnBrowseModFolder
            // 
            this.btnBrowseModFolder.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnBrowseModFolder.Location = new System.Drawing.Point(459, 6);
            this.btnBrowseModFolder.Name = "btnBrowseModFolder";
            this.btnBrowseModFolder.Size = new System.Drawing.Size(29, 20);
            this.btnBrowseModFolder.TabIndex = 2;
            this.btnBrowseModFolder.Text = "...";
            this.btnBrowseModFolder.UseVisualStyleBackColor = true;
            this.btnBrowseModFolder.Click += new System.EventHandler(this.BrowseModFolder_Click);
            // 
            // lblOutputFolder
            // 
            this.lblOutputFolder.AutoSize = true;
            this.lblOutputFolder.Location = new System.Drawing.Point(12, 61);
            this.lblOutputFolder.Name = "lblOutputFolder";
            this.lblOutputFolder.Size = new System.Drawing.Size(71, 13);
            this.lblOutputFolder.TabIndex = 3;
            this.lblOutputFolder.Text = "Output folder:";
            // 
            // tbxOutputFolder
            // 
            this.tbxOutputFolder.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.tbxOutputFolder.BorderColor = System.Drawing.Color.Red;
            this.tbxOutputFolder.Location = new System.Drawing.Point(89, 58);
            this.tbxOutputFolder.Name = "tbxOutputFolder";
            this.tbxOutputFolder.Size = new System.Drawing.Size(364, 20);
            this.tbxOutputFolder.TabIndex = 4;
            this.toolTip.SetToolTip(this.tbxOutputFolder, "Please enter a valid output folder path. The folder must exist, but can be empty." +
        "");
            this.tbxOutputFolder.TextChanged += new System.EventHandler(this.tbxOutputFolder_TextChanged);
            // 
            // btnBrowseOutputFolder
            // 
            this.btnBrowseOutputFolder.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnBrowseOutputFolder.Location = new System.Drawing.Point(459, 58);
            this.btnBrowseOutputFolder.Name = "btnBrowseOutputFolder";
            this.btnBrowseOutputFolder.Size = new System.Drawing.Size(29, 20);
            this.btnBrowseOutputFolder.TabIndex = 5;
            this.btnBrowseOutputFolder.Text = "...";
            this.btnBrowseOutputFolder.UseVisualStyleBackColor = true;
            this.btnBrowseOutputFolder.Click += new System.EventHandler(this.BrowseOutputFolder_Click);
            // 
            // btnCreatePatch
            // 
            this.btnCreatePatch.Location = new System.Drawing.Point(12, 114);
            this.btnCreatePatch.Name = "btnCreatePatch";
            this.btnCreatePatch.Size = new System.Drawing.Size(476, 24);
            this.btnCreatePatch.TabIndex = 6;
            this.btnCreatePatch.Text = "Create patch";
            this.btnCreatePatch.UseVisualStyleBackColor = true;
            this.btnCreatePatch.Click += new System.EventHandler(this.CreatePatch_Click);
            // 
            // tbxModName
            // 
            this.tbxModName.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.tbxModName.BorderColor = System.Drawing.Color.Red;
            this.tbxModName.Location = new System.Drawing.Point(91, 32);
            this.tbxModName.Name = "tbxModName";
            this.tbxModName.Size = new System.Drawing.Size(397, 20);
            this.tbxModName.TabIndex = 7;
            this.toolTip.SetToolTip(this.tbxModName, "Please enter an identifier for the mod. This will be used to name the item file.\r" +
        "\nDo not use any special characters other than underscores.");
            this.tbxModName.TextChanged += new System.EventHandler(this.tbxModName_TextChanged);
            // 
            // lblModName
            // 
            this.lblModName.AutoSize = true;
            this.lblModName.Location = new System.Drawing.Point(12, 35);
            this.lblModName.Name = "lblModName";
            this.lblModName.Size = new System.Drawing.Size(73, 13);
            this.lblModName.TabIndex = 8;
            this.lblModName.Text = "Mod identifier:";
            // 
            // btnSettings
            // 
            this.btnSettings.Location = new System.Drawing.Point(12, 84);
            this.btnSettings.Name = "btnSettings";
            this.btnSettings.Size = new System.Drawing.Size(476, 24);
            this.btnSettings.TabIndex = 10;
            this.btnSettings.Text = "Settings";
            this.btnSettings.UseVisualStyleBackColor = true;
            this.btnSettings.Click += new System.EventHandler(this.Settings_Click);
            // 
            // rtbxOutput
            // 
            this.rtbxOutput.Location = new System.Drawing.Point(12, 173);
            this.rtbxOutput.Name = "rtbxOutput";
            this.rtbxOutput.ReadOnly = true;
            this.rtbxOutput.Size = new System.Drawing.Size(476, 96);
            this.rtbxOutput.TabIndex = 11;
            this.rtbxOutput.Text = "";
            // 
            // prgPatching
            // 
            this.prgPatching.Location = new System.Drawing.Point(12, 144);
            this.prgPatching.Name = "prgPatching";
            this.prgPatching.Size = new System.Drawing.Size(476, 23);
            this.prgPatching.TabIndex = 12;
            // 
            // MainForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(500, 281);
            this.Controls.Add(this.prgPatching);
            this.Controls.Add(this.rtbxOutput);
            this.Controls.Add(this.btnSettings);
            this.Controls.Add(this.lblModName);
            this.Controls.Add(this.tbxModName);
            this.Controls.Add(this.btnCreatePatch);
            this.Controls.Add(this.btnBrowseOutputFolder);
            this.Controls.Add(this.tbxOutputFolder);
            this.Controls.Add(this.lblOutputFolder);
            this.Controls.Add(this.btnBrowseModFolder);
            this.Controls.Add(this.tbxModFolder);
            this.Controls.Add(this.lblModFolder);
            this.Name = "MainForm";
            this.Text = "Spawnable Item Fetcher";
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label lblModFolder;
        private ColorableTextBox tbxModFolder;
        private System.Windows.Forms.Button btnBrowseModFolder;
        private System.Windows.Forms.Label lblOutputFolder;
        private ColorableTextBox tbxOutputFolder;
        private System.Windows.Forms.Button btnBrowseOutputFolder;
        private System.Windows.Forms.Button btnCreatePatch;
        private ColorableTextBox tbxModName;
        private System.Windows.Forms.Label lblModName;
        private System.Windows.Forms.Button btnSettings;
        private System.Windows.Forms.RichTextBox rtbxOutput;
        private System.Windows.Forms.ToolTip toolTip;
        private System.Windows.Forms.ProgressBar prgPatching;
    }
}

