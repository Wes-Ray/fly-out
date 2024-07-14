using Godot;
using System;

public partial class throttle_test_script : Node
{
	private AnimationPlayer _animator;
	private float speedScale = 1.0f;
	private float maxSpeedScale = 10.0f;
	private float speed = 1.0f;
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		_animator = ((AnimationPlayer) GetNode("AnimationPlayer"));
		
		_animator.Play("shake_ship");
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		 if (Input.IsActionPressed("move_up") && speedScale < maxSpeedScale)
		{
			// Speed up shake on move up:
			speedScale += speed * (float)delta;
		}
		
		if (Input.IsActionPressed("move_down") && speedScale > 0)
		{
			// Slow down shake on move up:
			speedScale -= speed * (float)delta;
			
		}
		
		_animator.SpeedScale = speedScale;
	}
}
