"""
AgriSmartAI :: MobileNetV2 Training Pipeline (Rice Disease Classifier)
================================================================================
OBJECTIVE 1: Collect images from New Bataan  (expects dataset/<class>/*.jpg)
OBJECTIVE 2: 85%+ accuracy model             (transfer learning + fine-tuning)
OBJECTIVE 3: App + fertilizer + DA referral  (exports class labels for app)
OBJECTIVE 4: Farmer evaluation + admin board (saves metrics report)
--------------------------------------------------------------------------------
This is the REAL training script used to produce the model that the simulator
(simulate_detection.py) stands in for during the outline defense. It uses
transfer learning on MobileNetV2 and is ready to run once the New Bataan image
dataset is collected.

Dataset layout expected:
    dataset/
        bacterial_leaf_blight/ *.jpg
        rice_blast/            *.jpg
        tungro/                *.jpg
        healthy/               *.jpg

Run:
    python train_model.py --data_dir dataset --epochs 25
"""

from __future__ import annotations

import argparse
import json
import os
from datetime import datetime

CLASS_NAMES = ["bacterial_leaf_blight", "rice_blast", "tungro", "healthy"]
IMG_SIZE = (224, 224)          # MobileNetV2 default input
TARGET_ACCURACY = 0.85         # OBJECTIVE 2


def build_model(num_classes: int):
    """Build a MobileNetV2 transfer-learning classifier."""
    import tensorflow as tf  # imported lazily so the file is importable w/o TF

    base = tf.keras.applications.MobileNetV2(
        input_shape=IMG_SIZE + (3,),
        include_top=False,
        weights="imagenet",
    )
    base.trainable = False  # freeze backbone for the first training phase

    model = tf.keras.Sequential(
        [
            tf.keras.layers.Input(shape=IMG_SIZE + (3,)),
            tf.keras.layers.Rescaling(1.0 / 255),
            tf.keras.layers.RandomFlip("horizontal"),
            tf.keras.layers.RandomRotation(0.1),
            tf.keras.layers.RandomZoom(0.1),
            base,
            tf.keras.layers.GlobalAveragePooling2D(),
            tf.keras.layers.Dropout(0.3),
            tf.keras.layers.Dense(128, activation="relu"),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.Dense(num_classes, activation="softmax"),
        ]
    )
    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model, base


def load_datasets(data_dir: str, batch_size: int):
    import tensorflow as tf

    train_ds = tf.keras.utils.image_dataset_from_directory(
        data_dir,
        validation_split=0.2,
        subset="training",
        seed=42,
        image_size=IMG_SIZE,
        batch_size=batch_size,
        label_mode="int",
        class_names=CLASS_NAMES,
    )
    val_ds = tf.keras.utils.image_dataset_from_directory(
        data_dir,
        validation_split=0.2,
        subset="validation",
        seed=42,
        image_size=IMG_SIZE,
        batch_size=batch_size,
        label_mode="int",
        class_names=CLASS_NAMES,
    )
    autotune = tf.data.AUTOTUNE
    return train_ds.prefetch(autotune), val_ds.prefetch(autotune)


def train(data_dir: str, epochs: int, batch_size: int, out_dir: str) -> dict:
    import tensorflow as tf

    os.makedirs(out_dir, exist_ok=True)
    train_ds, val_ds = load_datasets(data_dir, batch_size)
    model, base = build_model(len(CLASS_NAMES))

    # Phase 1: train classifier head only.
    print("[AgriSmartAI] Phase 1 - training classifier head...")
    history = model.fit(train_ds, validation_data=val_ds, epochs=epochs)

    # Phase 2: fine-tune the top layers of MobileNetV2 to push past 85%.
    print("[AgriSmartAI] Phase 2 - fine-tuning backbone...")
    base.trainable = True
    for layer in base.layers[:-30]:
        layer.trainable = False
    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-5),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    fine = model.fit(train_ds, validation_data=val_ds, epochs=max(5, epochs // 3))

    val_acc = float(fine.history["val_accuracy"][-1])

    # Export Keras model + TFLite (for the Flutter app) + label/metrics files.
    keras_path = os.path.join(out_dir, "rice_disease_mobilenetv2.keras")
    model.save(keras_path)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    with open(os.path.join(out_dir, "rice_disease_mobilenetv2.tflite"), "wb") as f:
        f.write(tflite_model)

    with open(os.path.join(out_dir, "labels.json"), "w", encoding="utf-8") as f:
        json.dump(CLASS_NAMES, f, indent=2)

    report = {
        "model": "MobileNetV2",
        "trained_at": datetime.utcnow().isoformat() + "Z",
        "classes": CLASS_NAMES,
        "epochs": epochs,
        "val_accuracy": round(val_acc, 4),
        "target_accuracy": TARGET_ACCURACY,
        "meets_objective_2": val_acc >= TARGET_ACCURACY,
        "combined_history": {
            "phase1": {k: [float(x) for x in v] for k, v in history.history.items()},
            "phase2": {k: [float(x) for x in v] for k, v in fine.history.items()},
        },
    }
    with open(os.path.join(out_dir, "metrics.json"), "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)

    status = "PASSED" if val_acc >= TARGET_ACCURACY else "BELOW TARGET"
    print(f"[AgriSmartAI] Validation accuracy: {val_acc:.2%} ({status} 85% goal)")
    print(f"[AgriSmartAI] Artifacts saved to: {out_dir}")

    # Copy into inference folder for backend API auto-load.
    weights_dir = os.path.join(os.path.dirname(__file__), "weights")
    os.makedirs(weights_dir, exist_ok=True)
    import shutil
    shutil.copy2(keras_path, os.path.join(weights_dir, "mobilenetv2_rice.keras"))
    shutil.copy2(
        os.path.join(out_dir, "labels.json"),
        os.path.join(weights_dir, "class_labels.json"),
    )
    print(f"[AgriSmartAI] Inference weights copied to: {weights_dir}")

    return report


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Train AgriSmartAI rice disease model")
    parser.add_argument("--data_dir", default="dataset", help="Path to dataset root")
    parser.add_argument("--epochs", type=int, default=25)
    parser.add_argument("--batch_size", type=int, default=32)
    parser.add_argument("--out_dir", default="artifacts")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    if not os.path.isdir(args.data_dir):
        raise SystemExit(
            f"Dataset directory '{args.data_dir}' not found. "
            "Collect New Bataan rice-leaf images first (OBJECTIVE 1)."
        )
    train(args.data_dir, args.epochs, args.batch_size, args.out_dir)
