namespace SpawnableItemFetcherGUI
{
    partial class ConfigurationForm
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
            this.dgvExtensions = new System.Windows.Forms.DataGridView();
            this.ColumnExtension = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.btnSave = new System.Windows.Forms.Button();
            this.btnReset = new System.Windows.Forms.Button();
            this.dgvBlacklist = new System.Windows.Forms.DataGridView();
            this.dataGridViewTextBoxColumn1 = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.splitGridViews = new System.Windows.Forms.SplitContainer();
            ((System.ComponentModel.ISupportInitialize)(this.dgvExtensions)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dgvBlacklist)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.splitGridViews)).BeginInit();
            this.splitGridViews.Panel1.SuspendLayout();
            this.splitGridViews.Panel2.SuspendLayout();
            this.splitGridViews.SuspendLayout();
            this.SuspendLayout();
            // 
            // dgvExtensions
            // 
            this.dgvExtensions.AllowUserToResizeColumns = false;
            this.dgvExtensions.AllowUserToResizeRows = false;
            this.dgvExtensions.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.dgvExtensions.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvExtensions.Columns.AddRange(new System.Windows.Forms.DataGridViewColumn[] {
            this.ColumnExtension});
            this.dgvExtensions.Location = new System.Drawing.Point(0, 0);
            this.dgvExtensions.MultiSelect = false;
            this.dgvExtensions.Name = "dgvExtensions";
            this.dgvExtensions.Size = new System.Drawing.Size(227, 252);
            this.dgvExtensions.TabIndex = 0;
            this.dgvExtensions.CellBeginEdit += new System.Windows.Forms.DataGridViewCellCancelEventHandler(this.CellBeginEdit_MarkChanged);
            // 
            // ColumnExtension
            // 
            this.ColumnExtension.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.ColumnExtension.HeaderText = "File extensions";
            this.ColumnExtension.Name = "ColumnExtension";
            this.ColumnExtension.ToolTipText = "Files with matching extensions will be checked for items and objects.";
            // 
            // btnSave
            // 
            this.btnSave.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.btnSave.Location = new System.Drawing.Point(12, 529);
            this.btnSave.Name = "btnSave";
            this.btnSave.Size = new System.Drawing.Size(75, 23);
            this.btnSave.TabIndex = 2;
            this.btnSave.Text = "Save";
            this.btnSave.UseVisualStyleBackColor = true;
            this.btnSave.Click += new System.EventHandler(this.Save_Click);
            // 
            // btnReset
            // 
            this.btnReset.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.btnReset.Location = new System.Drawing.Point(164, 529);
            this.btnReset.Name = "btnReset";
            this.btnReset.Size = new System.Drawing.Size(75, 23);
            this.btnReset.TabIndex = 3;
            this.btnReset.Text = "Reset";
            this.btnReset.UseVisualStyleBackColor = true;
            this.btnReset.Click += new System.EventHandler(this.Reset_Click);
            // 
            // dgvBlacklist
            // 
            this.dgvBlacklist.AllowUserToResizeColumns = false;
            this.dgvBlacklist.AllowUserToResizeRows = false;
            this.dgvBlacklist.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.dgvBlacklist.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvBlacklist.Columns.AddRange(new System.Windows.Forms.DataGridViewColumn[] {
            this.dataGridViewTextBoxColumn1});
            this.dgvBlacklist.Location = new System.Drawing.Point(0, 2);
            this.dgvBlacklist.MultiSelect = false;
            this.dgvBlacklist.Name = "dgvBlacklist";
            this.dgvBlacklist.Size = new System.Drawing.Size(227, 250);
            this.dgvBlacklist.TabIndex = 1;
            this.dgvBlacklist.CellBeginEdit += new System.Windows.Forms.DataGridViewCellCancelEventHandler(this.CellBeginEdit_MarkChanged);
            // 
            // dataGridViewTextBoxColumn1
            // 
            this.dataGridViewTextBoxColumn1.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.dataGridViewTextBoxColumn1.HeaderText = "Blacklisted items";
            this.dataGridViewTextBoxColumn1.Name = "dataGridViewTextBoxColumn1";
            this.dataGridViewTextBoxColumn1.ToolTipText = "Item identifiers in this list will be ignored.";
            // 
            // splitGridViews
            // 
            this.splitGridViews.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.splitGridViews.Location = new System.Drawing.Point(12, 12);
            this.splitGridViews.Name = "splitGridViews";
            this.splitGridViews.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitGridViews.Panel1
            // 
            this.splitGridViews.Panel1.Controls.Add(this.dgvExtensions);
            // 
            // splitGridViews.Panel2
            // 
            this.splitGridViews.Panel2.Controls.Add(this.dgvBlacklist);
            this.splitGridViews.Size = new System.Drawing.Size(227, 511);
            this.splitGridViews.SplitterDistance = 255;
            this.splitGridViews.TabIndex = 4;
            // 
            // ConfigurationForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(251, 564);
            this.Controls.Add(this.splitGridViews);
            this.Controls.Add(this.btnReset);
            this.Controls.Add(this.btnSave);
            this.Name = "ConfigurationForm";
            this.Text = "Configuration";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.ConfigurationForm_FormClosing);
            ((System.ComponentModel.ISupportInitialize)(this.dgvExtensions)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dgvBlacklist)).EndInit();
            this.splitGridViews.Panel1.ResumeLayout(false);
            this.splitGridViews.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitGridViews)).EndInit();
            this.splitGridViews.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.DataGridView dgvExtensions;
        private System.Windows.Forms.Button btnSave;
        private System.Windows.Forms.Button btnReset;
        private System.Windows.Forms.DataGridView dgvBlacklist;
        private System.Windows.Forms.SplitContainer splitGridViews;
        private System.Windows.Forms.DataGridViewTextBoxColumn ColumnExtension;
        private System.Windows.Forms.DataGridViewTextBoxColumn dataGridViewTextBoxColumn1;
    }
}