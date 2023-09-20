package;

import haxe.ds.WeakMap;
import kha.graphics2.Graphics;
import kha.input.Gamepad;
import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import kha.Scheduler;
import kha.System;

import kha.input.Keyboard;

class Main {
	static var currentGamepadID(default, set) = 0;
	static var initializedIndices = new Map<Int, Bool>();

	static var leftStickX = 0.0;
	static var leftStickY = 0.0;
	static var rightStickX = 0.0;
	static var rightStickY = 0.0;

	static var pressedButtons = new Map<Int, Float>();

	static function set_currentGamepadID(value: Int): Int {
		leftStickX = leftStickY = rightStickX = rightStickY = 0.0;
		pressedButtons.clear();
		return currentGamepadID = value;
	}

	static function update(): Void {
	}

	static function render(frames: Array<Framebuffer>): Void {
		final fb = frames[0];
		final g = fb.g2;

		g.begin(true, Color.fromBytes(18, 18, 18));
		g.pushTranslation(24, 24);

		g.font = kha.Assets.fonts.Jupiteroid_Regular;
		g.fontSize = 22;
		g.color = Color.Cyan;

		g.drawString("Choose Gamepad ID with keyboard (0-9):", 0, 0);
		for (i in 0...10) {
			g.color = i == currentGamepadID ? Color.Red : Color.White;
			g.drawString(Std.string(i), 330 + i * 30, 0);
		}

		g.color = Color.White;
		g.drawLine(0, 30, 680, 30, 2);

		final currentGamepad = Gamepad.get(currentGamepadID);
		if (currentGamepad == null) {
			g.color = Color.Red;
			g.drawString("Could not fetch gamepad from Kha, get() returned null!", 0, 42);
		}
		else {
			if (!initializedIndices.exists(currentGamepadID)) {
				initializedIndices.set(currentGamepadID, true);

				currentGamepad.notify((axis, value) -> {
					switch (axis) {
						case 0: leftStickX = value;
						case 1: leftStickY = value;
						case 2: rightStickX = value;
						case 3: rightStickY = value;
						default:
					}
				}, (button, value) -> {
					pressedButtons[button] = value;
				});
			}

			g.drawString("Connected: " + currentGamepad.connected + (currentGamepad.connected ? "" : " (you might need to press a button on the controller to connect)"), 0, 42);
			g.drawString("ID: " + currentGamepad.id, 0, 62);
			g.drawString("Vendor: " + currentGamepad.vendor, 0, 82);

			g.drawString("Left Stick", 0, 120);
			drawCircle(g, 30, 190, 30, 1);
			var posX = 30 + leftStickX * 30;
			var posY = 190 + leftStickY * 30;
			g.drawLine(posX, posY - 5, posX, posY + 5);
			g.drawLine(posX - 5, posY, posX + 5, posY);
			g.drawString("X: " + Std.string(leftStickX), 0, 230);
			g.drawString("Y: " + Std.string(leftStickY), 0, 250);

			g.drawString("Right Stick", 200, 120);
			drawCircle(g, 230, 190, 30, 1);
			posX = 230 + rightStickX * 30;
			posY = 190 + rightStickY * 30;
			g.drawLine(posX, posY - 5, posX, posY + 5);
			g.drawLine(posX - 5, posY, posX + 5, posY);
			g.drawString("X: " + Std.string(rightStickX), 200, 230);
			g.drawString("Y: " + Std.string(rightStickY), 200, 250);

			var y = 290;
			g.drawString("Pressed Buttons (display order undefined)", 0, y);
			for (button => value in pressedButtons.keyValueIterator()) {
				y += 20;
				g.drawString('Index: $button | Last Value: $value', 0, y);
			}
		}

		g.popTransformation();
		g.end();
	}

	public static function main() {
		System.start({title: "Kha Gamepad Tester", width: 680 + 48, height: 720}, (_) -> {

			Keyboard.get().notify((keycode: kha.input.KeyCode) -> {
				switch (keycode) {
					case Zero: currentGamepadID = 0;
					case One: currentGamepadID = 1;
					case Two: currentGamepadID = 2;
					case Three: currentGamepadID = 3;
					case Four: currentGamepadID = 4;
					case Five: currentGamepadID = 5;
					case Six: currentGamepadID = 6;
					case Seven: currentGamepadID = 7;
					case Eight: currentGamepadID = 8;
					case Nine: currentGamepadID = 9;
					default:
				}
			});

			Assets.loadEverything(function () {
				Scheduler.addTimeTask(update, 0, 1 / 60);
				System.notifyOnFrames(render);
			});
		});
	}

	// Copied from Kha's deprecated GraphicsExtension class
	static function drawCircle(g2: Graphics, cx: Float, cy: Float, radius: Float, strength: Float = 1, segments: Int = 0): Void {
		#if kha_html5
		if (kha.SystemImpl.gl == null) {
			var g: kha.js.CanvasGraphics = cast g2;
			radius -= strength / 2; // reduce radius to fit the line thickness within image width/height
			g.drawCircle(cx, cy, radius, strength);
			return;
		}
		#end
		radius += strength / 2;

		if (segments <= 0)
			segments = Math.floor(10 * Math.sqrt(radius));

		var theta = 2 * Math.PI / segments;
		var c = Math.cos(theta);
		var s = Math.sin(theta);

		var x = radius;
		var y = 0.0;

		for (n in 0...segments) {
			var px = x + cx;
			var py = y + cy;

			var t = x;
			x = c * x - s * y;
			y = c * y + s * t;
			drawInnerLine(g2, x + cx, y + cy, px, py, strength);
		}
	}

	static function drawInnerLine(g2: Graphics, x1: Float, y1: Float, x2: Float, y2: Float, strength: Float): Void {
		var side = y2 > y1 ? 1 : 0;
		if (y2 == y1)
			side = x2 - x1 > 0 ? 1 : 0;

		var vec = new kha.math.FastVector2();
		if (y2 == y1)
			vec.setFrom(new kha.math.FastVector2(0, -1));
		else
			vec.setFrom(new kha.math.FastVector2(1, -(x2 - x1) / (y2 - y1)));
		vec.length = strength;
		var p1 = new kha.math.FastVector2(x1 + side * vec.x, y1 + side * vec.y);
		var p2 = new kha.math.FastVector2(x2 + side * vec.x, y2 + side * vec.y);
		var p3 = p1.sub(vec);
		var p4 = p2.sub(vec);
		g2.fillTriangle(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
		g2.fillTriangle(p3.x, p3.y, p2.x, p2.y, p4.x, p4.y);
	}
}
