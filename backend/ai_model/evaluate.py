"""
AgriSmartAI - Model Evaluation Script
OBJECTIVE 4: Evaluate the system using 100 unseen rice leaf images.

Test dataset structure required:
  test_dataset/
    bacterial_leaf_blight/   <- unseen images
    rice_blast/
    tungro/
    healthy/

Usage:
  python evaluate.py
  python evaluate.py --test-dir path/to/test_dataset --model path/to/model.h5
"""

import os
import argparse
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from sklearn.metrics import (
    classification_report, confusion_matrix,
    accuracy_score, precision_score, recall_score, f1_score
)
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
import json

# ============================================================
# Arguments
# ============================================================
parser = argparse.ArgumentParser(description='Evaluate AgriSmartAI model')
parser.add_argument('--test-dir', default='test_dataset',
                    help='Path to test dataset directory')
parser.add_argument('--model', default='models/rice_disease_model.h5',
                    help='Path to trained Keras model')
parser.add_argument('--output-dir', default='evaluation_results',
                    help='Directory to save evaluation outputs')
args = parser.parse_args()

os.makedirs(args.output_dir, exist_ok=True)

IMG_SIZE = (224, 224)
BATCH_SIZE = 16

# ============================================================
# Load model
# ============================================================
print(f'Loading model: {args.model}')
model = load_model(args.model)
print('Model loaded.')

# ============================================================
# Load test dataset
# ============================================================
print(f'Loading test dataset: {args.test_dir}')
test_datagen = ImageDataGenerator(rescale=1.0 / 255)
test_gen = test_datagen.flow_from_directory(
    args.test_dir,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    shuffle=False,
)

CLASS_NAMES = list(test_gen.class_indices.keys())
NUM_CLASSES = len(CLASS_NAMES)
TOTAL_IMAGES = test_gen.samples

print(f'Total test images: {TOTAL_IMAGES}')
print(f'Classes: {CLASS_NAMES}')

# OBJECTIVE 4 requires 100 unseen images
if TOTAL_IMAGES < 100:
    print(f'WARNING: Only {TOTAL_IMAGES} test images found. '
          f'OBJECTIVE 4 requires at least 100 unseen images.')
else:
    print(f'✓ {TOTAL_IMAGES} test images available (minimum 100 required)')

# ============================================================
# Predict
# ============================================================
print('\nRunning predictions...')
test_gen.reset()
y_pred_probs = model.predict(test_gen, verbose=1)
y_pred = np.argmax(y_pred_probs, axis=1)
y_true = test_gen.classes

# ============================================================
# Metrics
# ============================================================
accuracy = accuracy_score(y_true, y_pred)
precision = precision_score(y_true, y_pred, average='weighted', zero_division=0)
recall = recall_score(y_true, y_pred, average='weighted', zero_division=0)
f1 = f1_score(y_true, y_pred, average='weighted', zero_division=0)

print('\n' + '='*50)
print('EVALUATION RESULTS (OBJECTIVE 4)')
print('='*50)
print(f'Test Images:  {TOTAL_IMAGES}')
print(f'Accuracy:     {accuracy * 100:.2f}%')
print(f'Precision:    {precision * 100:.2f}%')
print(f'Recall:       {recall * 100:.2f}%')
print(f'F1-Score:     {f1 * 100:.2f}%')
print('='*50)

if accuracy >= 0.85:
    print('✓ OBJECTIVE 2 CONFIRMED: Accuracy >= 85% on unseen test images')
else:
    print('✗ Accuracy below 85% target on test set')

# Per-class report
print('\nPer-class Classification Report:')
print(classification_report(y_true, y_pred, target_names=CLASS_NAMES))

# ============================================================
# Confusion matrix
# ============================================================
cm = confusion_matrix(y_true, y_pred)
plt.figure(figsize=(8, 6))
sns.heatmap(cm, annot=True, fmt='d', cmap='Greens',
            xticklabels=CLASS_NAMES, yticklabels=CLASS_NAMES)
plt.title(f'Confusion Matrix — Test Accuracy: {accuracy * 100:.2f}%')
plt.ylabel('True Label')
plt.xlabel('Predicted Label')
plt.tight_layout()
cm_path = os.path.join(args.output_dir, 'test_confusion_matrix.png')
plt.savefig(cm_path)
print(f'\nConfusion matrix saved: {cm_path}')

# ============================================================
# Save metrics to JSON (for thesis documentation)
# ============================================================
metrics = {
    'total_test_images': int(TOTAL_IMAGES),
    'classes': CLASS_NAMES,
    'accuracy': round(float(accuracy) * 100, 2),
    'precision_weighted': round(float(precision) * 100, 2),
    'recall_weighted': round(float(recall) * 100, 2),
    'f1_score_weighted': round(float(f1) * 100, 2),
    'objective_2_met': bool(accuracy >= 0.85),
    'objective_4_met': bool(TOTAL_IMAGES >= 100),
    'per_class': {},
}

# Per-class metrics
for i, cls in enumerate(CLASS_NAMES):
    mask = y_true == i
    if mask.sum() > 0:
        cls_acc = accuracy_score(y_true[mask], y_pred[mask])
        metrics['per_class'][cls] = round(float(cls_acc) * 100, 2)

metrics_path = os.path.join(args.output_dir, 'evaluation_metrics.json')
with open(metrics_path, 'w') as f:
    json.dump(metrics, f, indent=2)
print(f'Metrics saved: {metrics_path}')

# ============================================================
# Per-image prediction log (for thesis)
# ============================================================
filenames = test_gen.filenames
log_path = os.path.join(args.output_dir, 'prediction_log.csv')
with open(log_path, 'w') as f:
    f.write('image,true_label,predicted_label,confidence,correct\n')
    for i, (fname, true_idx, pred_idx) in enumerate(
            zip(filenames, y_true, y_pred)):
        confidence = float(y_pred_probs[i][pred_idx]) * 100
        correct = true_idx == pred_idx
        f.write(f'{fname},{CLASS_NAMES[true_idx]},'
                f'{CLASS_NAMES[pred_idx]},{confidence:.1f}%,{correct}\n')
print(f'Prediction log saved: {log_path}')

print('\n=== Evaluation Complete ===')
print(f'Results saved to: {args.output_dir}/')
