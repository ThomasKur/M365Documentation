using M365Doc.UI.Common;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace M365Doc.UI
{
    /// <summary>
    /// Interaction logic for Translation.xaml
    /// </summary>
    public partial class Translation : Window
    {
        public Boolean UserChangedTranslation = false;
        public ObservableCollection<TranslationFile> TranslationFileCollection { get; set; }
        public ObservableCollection<TranslationElement> TranslationElementCollection { get; set; }

        public Translation()
        {
            TranslationFileCollection = new ObservableCollection<TranslationFile>();
            TranslationElementCollection = new ObservableCollection<TranslationElement>();
            InitializeComponent();
            this.DataContext = this;

            InitializeODataDropdown("C:\\Users\\ThomasKurth\\github\\M365Documentation\\M365Documentation\\PSModule\\M365Documentation\\Data\\LabelTranslation");
        }

        public Translation(string path)
        {
            TranslationFileCollection = new ObservableCollection<TranslationFile>();
            TranslationElementCollection = new ObservableCollection<TranslationElement>();
            InitializeComponent();
            this.DataContext = this;

            InitializeODataDropdown(path);
        }

        private void InitializeODataDropdown(string folderPath)
        {
            string[] files = { };
            try
            {
                files = Directory.GetFiles(folderPath);
            }
            catch
            {
                MessageBox.Show("Failed to load translation file list from '"+ folderPath + "'.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                this.Close();
            }

            if (files.Length == 0)
            {
                MessageBox.Show("No translation files found '" + folderPath + "'.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                this.Close();
            }
            foreach (string file in files)
            {
                string _className = System.IO.Path.GetFileName(file).Replace("#microsoft.graph.", "").Replace(".json", "");
                TranslationFileCollection.Add(new TranslationFile() { Path = file, ClassName = _className });
            }
        }

        private void OdataFileTypes_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            MessageBoxResult userSel = MessageBoxResult.OK;
            if (UserChangedTranslation)
            {
                userSel = MessageBox.Show("You have modified the translation but not yet saved. If you click on OK, the modifications will be lost. Otherwise click Cancel.", "Warning", MessageBoxButton.OKCancel, MessageBoxImage.Warning);
            }
            try
            {
                if (userSel == MessageBoxResult.OK)
                {
                    ComboBox c = (ComboBox)sender;
                    TranslationFile selection = (TranslationFile)c.SelectedItem;
                    string json = File.ReadAllText(selection.Path);
                    Dictionary<string, TranslationElement> elements = JsonConvert.DeserializeObject<Dictionary<string, TranslationElement>>(json);
                    TranslationElementCollection.Clear();
                    foreach (var element in elements)
                    {
                        element.Value.Id = element.Key;
                        TranslationElementCollection.Add(element.Value);
                    }
                    UserChangedTranslation = false;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Failed to load translation with error: " + ex.Message, "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void SaveLocal_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                Dictionary<string, TranslationElement> elements = new Dictionary<string, TranslationElement>();
                foreach (var element in TranslationElementCollection)
                {
                    elements.Add(element.Id, new TranslationElement(element));
                }

                JsonSerializerSettings set = new JsonSerializerSettings();
                set.NullValueHandling = NullValueHandling.Ignore;

                string json = JsonConvert.SerializeObject(elements, Formatting.Indented, set);
                File.WriteAllText(((TranslationFile)OdataFileTypes.SelectedItem).Path, json);

                UserChangedTranslation = false;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Failed to save translation with error: " + ex.Message, "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void SubmitToCommunity_Click(object sender, RoutedEventArgs e)
        {
            if (UserChangedTranslation)
            {
                MessageBox.Show("Please save and test the translation before submitting your contribution.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            else
            {
                try
                {
                    Dictionary<string, TranslationElement> elements = new Dictionary<string, TranslationElement>();
                    foreach (var element in TranslationElementCollection)
                    {
                        elements.Add(element.Id, new TranslationElement(element));
                    }

                    JsonSerializerSettings set = new JsonSerializerSettings();
                    set.NullValueHandling = NullValueHandling.Ignore;

                    string json = JsonConvert.SerializeObject(elements, Formatting.Indented, set);
                    using (HttpClient client = new HttpClient())
                    {
                        var x = new StringContent(json);
                        client.DefaultRequestHeaders.Add("twitter", TwitterHandle.Text);
                        client.DefaultRequestHeaders.Add("mail", MailHandle.Text);
                        client.DefaultRequestHeaders.Add("odatatype", ((TranslationFile)OdataFileTypes.SelectedItem).ClassName);
                        var r = client.PostAsync("https://prod-195.westeurope.logic.azure.com:443/workflows/575614730dd443a9acc6d451477781e8/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=Pf7_psSqpIZFd0XGIceBZak8tFCHtumefiAJw6Tl7zM", x);
                        r.Wait();
                        MessageBox.Show("Thanks for submitting your translation. We will check it and integrate it in the next version.", "Information", MessageBoxButton.OK, MessageBoxImage.Information);

                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show("The submission failed with error: " + ex.Message, "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                }

            }


        }

        private void Info_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                var psi = new ProcessStartInfo
                {
                    FileName = "https://github.com/ThomasKur/M365Documentation",
                    UseShellExecute = true
                };
                Process.Start(psi);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Failed to open Help with error: " + ex.Message, "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
        private void License_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                var psi = new ProcessStartInfo
                {
                    FileName = "https://github.com/ThomasKur/M365Documentation/blob/main/LICENSE",
                    UseShellExecute = true
                };
                Process.Start(psi);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Failed to open License with error: " + ex.Message, "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void Translation_CellEditEnding(object sender, DataGridCellEditEndingEventArgs e)
        {
            UserChangedTranslation = true;
        }

    }
}
