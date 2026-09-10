using SFE.Core.Models;
using System.Text.Json;

namespace SFE.Services;

public class ScenarioService
{
    private static readonly string ScenariosPath =
        Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "scenarios.json");

    private List<Scenario> _scenarios = new();

    public ScenarioService()
    {
        Load();
    }

    public List<Scenario> GetAll() => _scenarios.ToList();

    public Scenario? GetById(string id) =>
        _scenarios.FirstOrDefault(s => s.Id == id);

    public void Save(Scenario scenario)
    {
        var existing = _scenarios.FirstOrDefault(s => s.Id == scenario.Id);
        if (existing != null)
            _scenarios.Remove(existing);
        _scenarios.Add(scenario);
        Persist();
    }

    public void Delete(string id)
    {
        var scenario = _scenarios.FirstOrDefault(s => s.Id == id);
        if (scenario != null)
        {
            _scenarios.Remove(scenario);
            Persist();
        }
    }

    public void UpdateLastRun(string id)
    {
        var scenario = _scenarios.FirstOrDefault(s => s.Id == id);
        if (scenario != null)
        {
            scenario.LastRunAt = DateTime.Now;
            Persist();
        }
    }

    private void Load()
    {
        try
        {
            if (File.Exists(ScenariosPath))
            {
                var json = File.ReadAllText(ScenariosPath);
                _scenarios = JsonSerializer.Deserialize<List<Scenario>>(json)
                             ?? new List<Scenario>();
            }
        }
        catch { _scenarios = new List<Scenario>(); }
    }

    private void Persist()
    {
        try
        {
            var json = JsonSerializer.Serialize(_scenarios,
                new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(ScenariosPath, json);
        }
        catch { }
    }
}