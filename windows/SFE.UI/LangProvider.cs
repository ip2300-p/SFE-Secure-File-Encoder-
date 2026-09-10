using SFE.Core.Models;
using System.ComponentModel;
using System.Windows.Data;

namespace SFE.UI;

public class LangProvider : INotifyPropertyChanged
{
    private static LangProvider? _instance;
    public static LangProvider Instance => _instance ??= new LangProvider();

    // indexer — XAML با {Binding [KeyName]} استفاده میکنه
    public string this[string key] => LocalizationService.Get(key);

    // وقتی زبان عوض میشه همه binding ها رفرش میشن
    public void Refresh()
    {
        PropertyChanged?.Invoke(this,
            new PropertyChangedEventArgs(Binding.IndexerName));
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    
}