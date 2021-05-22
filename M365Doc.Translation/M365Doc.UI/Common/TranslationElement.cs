using System;
using System.Collections.Generic;
using System.Text;

namespace M365Doc.UI.Common
{
    public class TranslationElement 
    {
        public string Id { get; set; }
        public string Section { get; set; }
        public string Name { get; set; }
        public string DataType { get; set; }
        public string ValueTrue { get; set; }
        public string ValueFalse { get; set; }

        public TranslationElement() { }
        public TranslationElement(TranslationElement ObjectToCopy)
        {
            this.Id = null;
            this.Section = ObjectToCopy.Section;
            this.Name = ObjectToCopy.Name;
            this.DataType = ObjectToCopy.DataType;
            if (this.DataType.Equals("System.Boolean"))
            {
                this.ValueFalse = ObjectToCopy.ValueFalse;
                this.ValueTrue = ObjectToCopy.ValueTrue;
            }
        }

    }
}
