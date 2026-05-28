from PIL import Image
import os

INPUT = "assets/images/strength/strength_exercises_collage.png"
OUTPUT = "assets/images/strength/cuts"

img = Image.open(INPUT)

# Coordenadas manuales aproximadas
# (left, top, right, bottom)

exercises = {
    "back_squat": (0, 0, 420, 420),
    "front_squat": (360, 0, 760, 420),
    "dumbbell_lunge": (700, 0, 1080, 420),
    "deadlift": (980, 0, 1400, 420),
    "farmer_carry": (1300, 0, 1536, 420),

    "sumo_deadlift": (0, 350, 420, 820),
    "trap_bar_deadlift": (380, 350, 780, 820),
    "step_up": (720, 350, 1080, 820),
    "hip_thrust": (930, 350, 1360, 820),

    "reverse_lunge": (280, 760, 760, 1152),
    "pistol_squat": (1100, 700, 1536, 1152),
}

os.makedirs(OUTPUT, exist_ok=True)

for name, coords in exercises.items():
    crop = img.crop(coords)
    output_path = os.path.join(OUTPUT, f"{name}.png")
    crop.save(output_path)
    print(f"Saved: {output_path}")

print("DONE")