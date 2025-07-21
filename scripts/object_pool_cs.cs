using Godot;
using System;

public partial class object_pool_cs : Node
{
	
	private const int MAX_INSTANCES = 100;
	private bool use_fixed_size = true;
	private static bool preload_instances = false;
	
	private Godot.Collections.Array<Godot.Collections.Array<Variant>> pool = new Godot.Collections.Array<Godot.Collections.Array<Variant>>();
	
	private partial class SceneData : Godot.GodotObject{
		public PackedScene scene;
		public Godot.Collections.Array<Node> instances = new Godot.Collections.Array<Node>();
		public Godot.Collections.Array<Node> in_use = new Godot.Collections.Array<Node>();
		public int max;
		public bool use_fixed_size;
		
		public SceneData(PackedScene scene, int max, bool use_fixed_size){
			this.scene = scene;
			this.max = max;
			this.use_fixed_size = use_fixed_size;
		}
	}
		
	public int preload_scenes(PackedScene[] scenes, int cat_index = -1){
		if (cat_index == -1){
			cat_index = pool.Count;
			pool.Add(new Godot.Collections.Array<Variant>());
		}
		
		var category = pool[cat_index];
		category.Clear();
		
		foreach (var scene in scenes){
			var instances = new Godot.Collections.Array<Node>();
			int preload_count = preload_instances && MAX_INSTANCES > 0 ? MAX_INSTANCES : 0;
			
			for (int i = 0; i < preload_count; i++){
				var inst = scene.Instantiate<Node>();
				//inst.hide(); //Not sure if neccessary
				inst.SetMeta("cat_index", cat_index);
				inst.GetChild(0).SetMeta("color", new Color(1, 1, 1));
				instances.Add(inst);
			}
			
			var new_scene_data = new SceneData(scene, MAX_INSTANCES, use_fixed_size);
			new_scene_data.instances = instances;
			Variant v = Variant.From(new_scene_data);
			category.Add(v);
			}
			
		return cat_index;
	}
		
	public void append_new_category(){
		pool.Add(new Godot.Collections.Array<Variant>());
	}
		
	public int preload_unlimited_scene(PackedScene scene, int cat_index){
		var instances = new Godot.Collections.Array<Node>();
		var category = pool[cat_index];
		
		var inst = scene.Instantiate<Node>();
		//inst.hide()
		inst.SetMeta("cat_index", cat_index);
		inst.SetMeta("index", category.Count);
		inst.GetChild(0).SetMeta("color", new Color(1,1,1));
		
		var new_scene_data = new SceneData(scene, MAX_INSTANCES, false);
		new_scene_data.instances = instances;
		Variant v = Variant.From(new_scene_data);
		category.Add(v);
		
		return category.Count;
	}
	
	public Node GetInstance(int index, int cat_index){
		if (cat_index < pool.Count && index < pool[cat_index].Count){
			Variant variant = Variant.From(pool[cat_index][index]);
			SceneData scene_data = variant.As<SceneData>();
			
			if (scene_data.instances.Count > 0){
				var inst = scene_data.instances[scene_data.instances.Count - 1];
				scene_data.instances.RemoveAt(scene_data.instances.Count - 1);
				scene_data.in_use.Add(inst);
				//inst.show();
				return inst;
			}
			else if (!scene_data.use_fixed_size || 
					(scene_data.use_fixed_size && 
					!preload_instances && 
					scene_data.in_use.Count < MAX_INSTANCES))
					{
						var inst = scene_data.scene.Instantiate<Node>();
						inst.SetMeta("cat_index", cat_index);
						inst.SetMeta("index", index);
						inst.GetChild(0).SetMeta("color", new Color(1, 1, 1)); // White color
						scene_data.in_use.Add(inst);
						return inst;
					}
			else{
				GD.Print("All instances in use and fixed-size is enabled for index:", index);
				return null;
			}
		}
		else {
			GD.Print("Index out of bounds: ", index);
			return null;
		}
	}
}
