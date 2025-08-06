using Godot;
using System;
using System.IO;

public partial class directory_handler : Node
{
    private Node3D building;

    public override void _EnterTree()
    {
        building = GetNode<Node3D>("../Building");
    }

    public void CreateSaveDataFolders()
    {
        bool firstTimeStartup = false;

        string saveDataPath = ProjectSettings.GlobalizePath("user://save_data");

        if (!Directory.Exists(saveDataPath))
        {
            Directory.CreateDirectory(saveDataPath);
            firstTimeStartup = true;
        }

        var paths = new[]
        {
            new[] { "building_data", "building_floors", "backup" },
            new[] { "building_data", "building_walls", "backup" },
            new[] { "building_data", "building_appliances", "backup" },
            new[] { "mm_data", "mm_walls", "backup" },
            new[] { "mm_data", "mm_floors", "backup" }
        };

        foreach (var path in paths)
        {
            GenerateFolders(path);
        }

        var SQLHandler = GD.Load<Script>("res://scripts/sql_handler.gd");
        var sqlHandler = new Node();
        sqlHandler.SetScript(SQLHandler);

        if (!Directory.Exists(sqlHandler.Get("DB_PATH").As<String>()))
        {
            sqlHandler.Call("create_database");
        }

        if (firstTimeStartup)
        {
            GenerateDefault();
            var config = GetNode("/root/config");
            config.Call("save_loading_settings", "max_stories", 2);
            building.Call("load_segments");
            building.Call("combine_meshes");
            CallDeferred("ReloadCurrentScene");
        }

    }

    public void ReloadCurrentScene()
    {
        GetTree().ReloadCurrentScene();
    }

    public void GenerateDefault()
    {
        CopyDefaultFiles("res://default_building_data/building_floors/", "user://save_data/building_data/building_floors/");
        CopyDefaultFiles("res://default_building_data/building_walls/", "user://save_data/building_data/building_walls/");
        CopyDefaultFiles("res://default_building_data/building_appliances/", "user://save_data/building_data/building_appliances/");
    }


    public void GenerateFolders(string[] folders)
    {

        String absSaveDataPath = ProjectSettings.GlobalizePath("user://save_data/");

        if (!Directory.Exists(absSaveDataPath))
        {
            GD.PushError("Failed to open user directory.");
            return;
        }

        string fullFolderPath = absSaveDataPath;

        foreach (var folder in folders)
        {
            fullFolderPath = Path.Combine(fullFolderPath, folder);

            if (!Directory.Exists(fullFolderPath))
            {
                try
                {
                    Directory.CreateDirectory(fullFolderPath);
                    GD.Print("Created folder:", fullFolderPath);
                }
                catch (Exception ex)
                {
                    GD.PushError($"Failed to create folder: {fullFolderPath}. Error: {ex.Message}");
                }
            }
        }
    }

    public void CopyDefaultFiles(string sourcePath, string destinationPath)
    {

        sourcePath = ProjectSettings.GlobalizePath(sourcePath);
        destinationPath = ProjectSettings.GlobalizePath(destinationPath);

        if (!Directory.Exists(sourcePath))
        {
            GD.PushError("Default folder not found!");
            return;
        }


        if (!Directory.Exists(destinationPath))
        {
            Directory.CreateDirectory(destinationPath);
        }

        string[] files = Directory.GetFiles(sourcePath);

        foreach (string sourceFilePath in files)
        {
            string fileName = Path.GetFileName(sourceFilePath);
            string destinationFilePath = Path.Combine(destinationPath, fileName);

            try
            {

                File.Copy(sourceFilePath, destinationFilePath, overwrite: true);
                GD.Print($"Copied JSON file: {fileName} to {destinationFilePath}");
            }
            catch (Exception ex)
            {
                GD.PushError($"Failed to copy over file: {fileName}. Error: {ex.Message}");
            }
        }
    }

    //Below is for use in the building.gd script

    public void ClearDirectory(string path, bool willBackup)
    {

        if (!path.StartsWith("user://save_data/"))
        {
            GD.PushError("DANGER, don't attempt to delete anything other than save data!");
            return;
        }

        path = ProjectSettings.GlobalizePath(path);

        if (!Directory.Exists(path))
        {
            GD.PushError($"Directory not found: {path}");
            return;
        }

        string backupDir = Path.Combine(path, "backup");

        if (willBackup && !Directory.Exists(backupDir))
        {
            Directory.CreateDirectory(backupDir);
        }

        string[] files = Directory.GetFiles(path);
        foreach (var filePath in files)
        {

            if (willBackup)
            {
                string backupFilePath = Path.Combine(backupDir, Path.GetFileName(filePath));
                BackupFile(filePath, backupFilePath);
            }

            File.Delete(filePath);
        }
    }

    public void MoveBackupFilesUp(string backupDir)
    {

        backupDir = ProjectSettings.GlobalizePath(backupDir);

        if (!Directory.Exists(backupDir))
        {
            GD.PushError($"Backup directory does not exist: {backupDir}");
            return;
        }

        string parentDir = Directory.GetParent(backupDir).FullName;
        string[] files = Directory.GetFiles(backupDir);

        foreach (string filePath in files)
        {
            try
            {
                string fileName = Path.GetFileName(filePath);
                string destinationPath = Path.Combine(parentDir, fileName);

                File.Copy(filePath, destinationPath, true);
            }
            catch (Exception ex)
            {
                GD.PushError($"Failed during file move: {filePath}. Error: {ex.Message}");
            }
        }
    }

    public void BackupFile(string path, string backupPath)
    {
        try
        {
            File.Copy(path, backupPath, true);

            GD.Print($"Successfully backed up file: {path} to {backupPath}");
        }
        catch (Exception ex)
        {
            GD.PushError($"Failed to back up file: {path}. Error: {ex.Message}");
        }
    }


}
