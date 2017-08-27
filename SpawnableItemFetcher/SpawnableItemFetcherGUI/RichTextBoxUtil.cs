using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace SpawnableItemFetcherGUI
{
    public static class RichTextBoxUtil
    {
        private static string GetTimestamp()
        {
            return string.Format("[{0}]", DateTime.Now.ToString("hh:mm:ss"));
        }

        public static void AppendTimestampText(this RichTextBox box, string text, params object[] args)
        {
            box.AppendText(GetTimestamp() + " " + string.Format(text, args));
        }

        public static void AppendTimestampText(this RichTextBox box, Color color, string text, params object[] args)
        {
            box.AppendText(color, GetTimestamp() + " " + text, args);
        }

        public static void AppendText(this RichTextBox box, string text, params object[] args)
        {
            box.AppendText(string.Format(text, args));
        }

        public static void AppendText(this RichTextBox box, Color color, string text, params object[] args)
        {
            box.SelectionStart = box.TextLength;
            box.SelectionLength = 0;

            box.SelectionColor = color;
            box.AppendText(string.Format(text, args));
            box.SelectionColor = box.ForeColor;
        }
    }
}
